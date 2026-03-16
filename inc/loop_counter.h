#ifndef LOOP_COUNTER_H
#define LOOP_COUNTER_H

#include <cstdint>
#include <unordered_map>

struct LoopInfo {
    uint64_t current_iter = 0;
    uint64_t distance = 0;  // difference between target and pc, can be used to filter out non-loop branches
    uint64_t final_it = 0; 
    uint64_t occurences = 0;
};

class LoopCounter {
public:
    void update(uint64_t pc, uint64_t target, uint8_t taken, uint8_t branch_type);
    void print() const;

private:
    std::unordered_map<uint64_t, LoopInfo> table;
};

#endif
