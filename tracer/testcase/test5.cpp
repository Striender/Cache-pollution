volatile int sink; 
int main() {
   int i =0;
    do {
        sink = i;
        i++; 
        if (i > 300000) // loop run for 300000 iterations, then exit
        {
           break;
        }
    } while (i <= 1000000 );
     
    return 0;
}

