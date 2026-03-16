volatile int sink; 
void foo(int i){
    do {
        sink = i;
        i--; 
    } while (i >= 1  );
}

int main() {
   int i = 1000000;
    
    foo(i);
    return 0;
}

