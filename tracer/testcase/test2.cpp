volatile int sink;

int main() {
    int i = 1000000;
    do {
        sink = i;
        i--;
    } while (i >= 1);
    
    return 0;
}

