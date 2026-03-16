volatile int sink; 
int main() {
   int i = 1000000;
    do {
        sink = i;
        i--; 
        if (i == 800000)                                    // loop run for 69999 iterations, then exit
        {
           i = 300000;
        }
    } while (i >= 1  );
     
    return 0;
}

