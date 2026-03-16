volatile int sink_if;
volatile int sink_else;

int main() {
    int i = 1000000;
    
    unsigned int random_val = 12345; 
    random_val = (random_val * 1103515245 + 12345) & 0x7fffffff;
        
        // Get a number between 0 and 99
        int coin_toss = 51;
        
        
    do { 
        if (coin_toss < 50) {
            sink_if = i; 
            i -= 2;
        } else {
            sink_else = i; 
            i -= 100;
        }
        i--;
    } while (i >= 1);

    return 0;
}