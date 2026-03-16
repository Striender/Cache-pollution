#!/bin/bash
set -u
set -o pipefail
# intentionally NOT using set -e

###############################################################################
# USAGE
# ./run_all_combination_google.sh 200
# ./run_all_combination_google.sh 200 14
# ./run_all_combination_google.sh 200 rp:1,3,7,14
###############################################################################

TOTAL_CORES=${1:? "TOTAL_CORES missing"}
RP_SELECTOR=${2:-}

TRACE_DIR=./workloads/Google_Traces_v2
RESULT_ROOT=./results/results_google
BIN_DIR=./bin

WARMUP=200000000
SIM=200000000
MAX_CORES_PER_COMBO=64

###############################################################################
# Prefetcher combinations
###############################################################################
PREFETCHER_COMBINATIONS=(
  #"ipcp_isca2020:ppf"
  #"ipcp_isca2020:bingo_dpc3"
  #"ipcp_isca2020:spp"
  #"ipcp_isca2020:ip_stride"
#
  #"vberti:ppf"
  #"vberti:spp"
  #"vberti:bingo_dpc3"
  #"vberti:ip_stride"
#
  #"mlop_dpc3:ip_stride"
  #"mlop_dpc3:ppf"
  #"mlop_dpc3:spp"
  #"mlop_dpc3:bingo_dpc3"
#
  #"ip_stride:ppf"
  #"ip_stride:bingo_dpc3"
  #"ip_stride:spp"

  "ipcp_isca2020:no"
  "mlop_dpc3:no"
  "vberti:no"
  "ip_stride:no"

  "no:spp"
  "no:bingo_dpc3"
  "no:ppf"
  "no:ip_stride"
)

###############################################################################
# Replacement policies
###############################################################################
repl_policies=(lru srrip drrip hawkeye ship ship++ mockingjay
               lru srrip drrip hawkeye ship ship++ mockingjay)

###############################################################################
# RP selection
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
# Core calculation
###############################################################################
TRACE_COUNT=$(find "$TRACE_DIR" -type f -name "*.champsim.gz" | wc -l)
[ "$TRACE_COUNT" -eq 0 ] && { echo "❌ No Google traces found"; exit 1; }

CORES_PER_COMBO=$TRACE_COUNT
[ "$CORES_PER_COMBO" -gt "$MAX_CORES_PER_COMBO" ] && CORES_PER_COMBO=$MAX_CORES_PER_COMBO

MAX_PARALLEL_COMBOS=$(( TOTAL_CORES / CORES_PER_COMBO ))
[ "$MAX_PARALLEL_COMBOS" -lt 1 ] && MAX_PARALLEL_COMBOS=1

echo "=============================================================="
echo "TOTAL CORES           : $TOTAL_CORES"
echo "GOOGLE TRACE COUNT    : $TRACE_COUNT"
echo "CORES PER COMBO       : $CORES_PER_COMBO"
echo "PARALLEL COMBINATIONS : $MAX_PARALLEL_COMBOS"
echo "=============================================================="

###############################################################################
# Binary name mapping
###############################################################################
binary_name() {
    case "$1" in
        mlop_dpc3) echo "mlop" ;;
        ip_stride) echo "ipstride" ;;
        *) echo "$1" ;;
    esac
}

###############################################################################
# Run Google traces
###############################################################################
run_google_traces() {
    local BINARY=$1
    local OUT_DIR=$2
    local CORES=$3

    mkdir -p "$OUT_DIR"
    local TMP
    TMP=$(mktemp)

    for WDIR in "$TRACE_DIR"/*/; do
        local W
        W=$(basename "$WDIR")

        for T in "$WDIR"/*.champsim.gz; do
            [ -f "$T" ] || continue
            local N
            N=$(basename "$T" .champsim.gz)

            echo "\"$BINARY\" \
              -warmup_instructions $WARMUP \
              -simulation_instructions $SIM \
              -traces \"$T\" \
              > \"$OUT_DIR/${W}_${N}.out\"" >> "$TMP"
        done
    done

    local JOBS
    JOBS=$(wc -l < "$TMP")

    if [ "$JOBS" -eq 0 ]; then
        echo "⚠️ No traces queued"
        rm -f "$TMP"
        return
    fi

    echo "🚀 Launching $JOBS traces using $CORES cores"

    xargs -P "$CORES" -I {} bash -c "{}" < "$TMP"

    rm -f "$TMP"
}

###############################################################################
# Run one prefetcher combo
###############################################################################
run_one_combo() {
    local L1=$1
    local L2=$2

    local REL
    if [[ "$L1" != "no" && "$L2" != "no" ]]; then
        REL="pref_l1_l2/${L1}_${L2}"
    elif [[ "$L1" != "no" ]]; then
        REL="pref_l1/${L1}"
    elif [[ "$L2" != "no" ]]; then
        REL="pref_l2/${L2}"
    else
        REL="baseline"
    fi

    echo "--------------------------------------------------------------"
    echo "STARTING COMBINATION: $REL"
    echo "--------------------------------------------------------------"

    local L1B
    local L2B
    L1B=$(binary_name "$L1")
    L2B=$(binary_name "$L2")

    for j in "${RP_LIST[@]}"; do
        local base
        local pol

        base=$([[ $j -le 7 ]] && echo lru || echo srrip)
        pol=${repl_policies[$((j-1))]}

        local BIN
        BIN="$BIN_DIR/hashed_perceptron-no-${L1B}-${L2B}-no-no-no-no-lru-lru-lru-${base}-${pol}-lru-lru-lru-1core-no"

        if [ ! -x "$BIN" ]; then
            echo "❌ Missing binary: $(basename "$BIN")"
            continue
        fi

        local OUT
        OUT="$RESULT_ROOT/$REL/exp${j}_${base}_${pol}"

        run_google_traces "$BIN" "$OUT" "$CORES_PER_COMBO"
    done
}

export -f run_one_combo
export -f run_google_traces
export -f binary_name

###############################################################################
# Parallel combination scheduling
###############################################################################
printf "%s\n" "${PREFETCHER_COMBINATIONS[@]}" | \
xargs -P "$MAX_PARALLEL_COMBOS" -I {} bash -c '
    IFS=":" read -r L1 L2 <<< "{}"
    run_one_combo "$L1" "$L2"
'

echo "=============================================================="
echo "✅ ALL GOOGLE TRACES COMPLETED SUCCESSFULLY"
echo "=============================================================="
