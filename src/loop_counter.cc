#include "loop_counter.h"
#include <iostream>

using namespace std;

void LoopCounter::update(uint64_t pc, uint64_t target, uint8_t taken, uint8_t branch_type)
{
    const uint8_t BRANCH_CONDITIONAL = 3;

    if (branch_type != BRANCH_CONDITIONAL || target == 0)
        return;

    auto it = table.find(pc);
    if(it == table.end())
    {
        // First time seeing this branch, insert it into the table
        LoopInfo loop;
        loop.distance = target > pc ? target - pc : pc - target; // calculate distance
        table[pc] = loop;
        loop.occurences = 1;
    }
  
    if(it != table.end())
    {
        // Update the loop information
        LoopInfo& loop = it->second;
        if (taken) {
            loop.current_iter++;
        } else if (loop.current_iter > 0) {
            loop.final_it = loop.current_iter;
            loop.occurences++;
            loop.current_iter = 0;
        }
    }

}

void LoopCounter::print() const
{
    for (const auto& kv : table) {
        
    }
}
