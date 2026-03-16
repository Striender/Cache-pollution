volatile int sink;
volatile int sink2;
int main() {
    int i = 1000;
   
    do {
        sink = i;
        i--; 
        int j = 1000;
        do{
            sink2 = j;
            j--;
        }while (j >= 1);
    } while (i >= 1);
    
    return 0;
}

