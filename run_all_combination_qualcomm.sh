#!/bin/bash
set -euo pipefail

###############################################################################
# USAGE
#
#   All replacement policies
#     ./run_all_combination_qualcomm.sh 200
#
#   Single RP
#     ./run_all_combination_qualcomm.sh 200 14
#
#   Multiple RPs
#     ./run_all_combination_qualcomm.sh 200 rp:1,3,7,14
###############################################################################

###############################################################################
# INPUTS
###############################################################################
TOTAL_CORES=${1:? "TOTAL_CORES missing"}
RP_SELECTOR=${2:-}

###############################################################################
# PATHS & CONSTANTS
###############################################################################
TRACE_DIR=/home1/sweta/traces/qualcomm_traces
RESULT_ROOT=./results/results_qualcomm
BIN_DIR=./bin

WARMUP=200000000
SIM=200000000
MAX_CORES_PER_COMBO=64

###############################################################################
# PREFETCHER COMBINATIONS (QUALCOMM)
###############################################################################
PREFETCHER_COMBINATIONS=(
  "ipcp_isca2020:ppf" "ipcp_isca2020:bingo_dpc3" "ipcp_isca2020:spp" "ipcp_isca2020:ip_stride"
  "vberti:ppf" "vberti:spp" "vberti:bingo_dpc3" "vberti:ip_stride"
  "mlop_dpc3:ip_stride" "mlop_dpc3:ppf" "mlop_dpc3:spp" "mlop_dpc3:bingo_dpc3"
  "ip_stride:ppf" "ip_stride:bingo_dpc3" "ip_stride:spp"
  "ipcp_isca2020:no" "mlop_dpc3:no" "vberti:no" "ip_stride:no"
  "no:spp" "no:bingo_dpc3" "no:ppf" "no:ip_stride"
)

###############################################################################
# REPLACEMENT POLICIES (1–14)
###############################################################################
repl_policies=(
  lru srrip drrip hawkeye ship ship++ mockingjay
  lru srrip drrip hawkeye ship ship++ mockingjay
)

###############################################################################
# BUILD RP LIST
###############################################################################
RP_LIST=()

if [ -z "$RP_SELECTOR" ]; then
    RP_LIST=($(seq 1 14))
elif [[ "$RP_SELECTOR" =~ ^[0-9]+$ ]]; then
    RP_LIST=("$RP_SELECTOR")
elif [[ "$RP_SELECTOR" == rp:* ]]; then
    IFS=',' read -ra RP_LIST <<< "${RP_SELECTOR#rp:}"
else
    echo "❌ Invalid RP selector"
    exit 1
fi

###############################################################################
# TRACE COUNT & CORE LOGIC
###############################################################################
TRACE_COUNT=$(ls "$TRACE_DIR"/*.champsimtrace.xz 2>/dev/null | wc -l)
[ "$TRACE_COUNT" -eq 0 ] && { echo "❌ No Qualcomm traces found"; exit 1; }

CORES_PER_COMBO=$TRACE_COUNT
[ "$CORES_PER_COMBO" -gt "$MAX_CORES_PER_COMBO" ] && CORES_PER_COMBO=$MAX_CORES_PER_COMBO

MAX_PARALLEL_COMBOS=$(( TOTAL_CORES / CORES_PER_COMBO ))
[ "$MAX_PARALLEL_COMBOS" -lt 1 ] && MAX_PARALLEL_COMBOS=1

echo "=============================================================="
echo "TOTAL CORES           : $TOTAL_CORES"
echo "QUALCOMM TRACE COUNT  : $TRACE_COUNT"
echo "CORES PER COMBO       : $CORES_PER_COMBO"
echo "PARALLEL COMBINATIONS : $MAX_PARALLEL_COMBOS"
echo "=============================================================="

###############################################################################
# PREFETCHER → BINARY TOKEN MAPPING
###############################################################################
binary_name() {
    case "$1" in
        mlop_dpc3) echo "mlop" ;;
        ip_stride) echo "ipstride" ;;
        *)         echo "$1" ;;
    esac
}

###############################################################################
# RUN QUALCOMM TRACES
###############################################################################
run_qualcomm_traces() {
    local BINARY=$1
    local OUT_DIR=$2
    local CORES=$3

    mkdir -p "$OUT_DIR"
    TMP=$(mktemp)

    for TRACE in "$TRACE_DIR"/*.champsimtrace.xz; do
        TRACE_NAME=$(basename "$TRACE" .champsimtrace.xz)

        # Qualcomm-specific filter
        if [[ ! "$TRACE_NAME" =~ ^(server|srv) ]]; then
            continue
        fi

        echo "\"$BINARY\" \
            -warmup_instructions $WARMUP \
            -simulation_instructions $SIM \
            -traces \"$TRACE\" \
            > \"$OUT_DIR/$TRACE_NAME.out\"" >> "$TMP"
    done

    JOBS=$(wc -l < "$TMP")
    echo "🚀 Launching $JOBS Qualcomm traces using $CORES cores"

    xargs -P "$CORES" -I CMD bash -c "CMD" < "$TMP"
    rm -f "$TMP"
}

###############################################################################
# RUN ONE PREFETCHER COMBINATION
###############################################################################
run_one_combo() {
    local L1=$1
    local L2=$2

    # Directory logic
    if [[ "$L1" != "no" && "$L2" != "no" ]]; then
        REL_PATH="pref_l1_l2/${L1}_${L2}"
    elif [[ "$L1" != "no" && "$L2" == "no" ]]; then
        REL_PATH="pref_l1/${L1}"
    elif [[ "$L1" == "no" && "$L2" != "no" ]]; then
        REL_PATH="pref_l2/${L2}"
    else
        REL_PATH="baseline"
    fi

    BASE_OUT="$RESULT_ROOT/$REL_PATH"

    echo "--------------------------------------------------------------"
    echo "STARTING COMBINATION: $REL_PATH"
    echo "--------------------------------------------------------------"

    L1_BIN=$(binary_name "$L1")
    L2_BIN=$(binary_name "$L2")

    for j in "${RP_LIST[@]}"; do
        base=$([[ $j -le 7 ]] && echo "lru" || echo "srrip")
        pol=${repl_policies[$((j-1))]}

        binary="$BIN_DIR/hashed_perceptron-no-${L1_BIN}-${L2_BIN}-no-no-no-no-lru-lru-lru-${base}-${pol}-lru-lru-lru-1core-no"

        if [ ! -x "$binary" ]; then
            echo "❌ Binary NOT FOUND:"
            echo "   $(basename "$binary")"
            continue
        fi

        EXP_DIR="$BASE_OUT/exp${j}_${base}_${pol}"

        echo "[RUNNING] $REL_PATH | RP=$j"
        run_qualcomm_traces "$binary" "$EXP_DIR" "$CORES_PER_COMBO"
        echo "[DONE]    $REL_PATH | RP=$j"
    done
}

export -f run_one_combo
export -f run_qualcomm_traces
export -f binary_name

###############################################################################
# PARALLEL EXECUTION OF PREFETCHER COMBINATIONS
###############################################################################
printf "%s\n" "${PREFETCHER_COMBINATIONS[@]}" | \
xargs -P "$MAX_PARALLEL_COMBOS" -I {} bash -c '
    IFS=":" read -r L1 L2 <<< "{}"
    run_one_combo "$L1" "$L2"
'

echo "=============================================================="
echo "✅ ALL QUALCOMM TRACES COMPLETED SUCCESSFULLY"
echo "=============================================================="
