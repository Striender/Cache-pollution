#include <iostream>
#include <vector>
using namespace std;

int main() {

    const size_t N = 50 * 1024 * 1024;   // 50 million integers (~200 MB array)
    vector<int> arr(N);

    // initialize array
    for(size_t i = 0; i < N; i++)
        arr[i] = i;

    long long sum = 0;

    // heavy memory access loop
    for(int round = 0; round < 5000; round++) {
        for(size_t i = 0; i < N; i++) {
            sum += arr[i];
            arr[i] = arr[i] + 1;
        }
    }

    cout << sum << endl;

    return 0;
}