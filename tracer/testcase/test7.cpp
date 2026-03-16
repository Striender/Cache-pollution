volatile int sink; 
int main() {
   int i = 1000000;
    do {
        sink = i;
        i--; 
        if (i == 300000) // loop run for 69999 iterations, then exit
        {
           for(int j = 0; j < 2000; j++) 
           {
               sink = j;
           }
           break;
        }
    } while (i >= 1  );
     
    return 0;
}

