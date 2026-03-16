volatile int sink; 
int main() {
   int i =0;
    do {
        sink = i;
        i++; 
        if (i > 100000)                 // loop run for 100001 iterations, then exit
        {
           i = 10000001;  
        }
    } while (i <= 1000000 );
     
    return 0;
}


