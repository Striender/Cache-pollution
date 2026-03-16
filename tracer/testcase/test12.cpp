volatile int sink; 
void foo(int i){
    do {
        sink = i;
        i--; 
    } while (i >= 1  );
}

int main() {
    
    
    foo(600000);
    foo(400000);
    return 0;
}

