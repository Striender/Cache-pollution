volatile int sink; 
int main() {
   int i = 1000000;
    do {
        sink = i;
        i--; 
        if (i < 300000) // loop run for 700000 iterations, then exit
        {
           break;
        }
    } while (i >= 1  );
     
    return 0;
}

