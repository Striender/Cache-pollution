volatile int sink; 
int main() {
   int i =0;
    do {
        sink = i;
        i++; 
        
    } while (i <= 1000000 );
     
    return 0;
}

