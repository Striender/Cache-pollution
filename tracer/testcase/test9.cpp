volatile int sink_if;
volatile int sink_else;

int main() {
    int i = 1000000;
    
    unsigned int random_val = 12345; 
    random_val = (random_val * 1103515245 + 12345) & 0x7fffffff;
        
        // Get a number between 0 and 99
        int coin_toss = random_val % 100;
        if (coin_toss < 50) {
            sink_if = i; 
            i = 500000;  
        } else {
            sink_else = i; 
            i = 200000;
        }
        
    do { 
        i--;
    } while (i >= 1);

    return 0;
}