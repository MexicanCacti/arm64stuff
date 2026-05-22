// V1


#include <iostream>

using namespace std;

/*
int main(int argc, char* argv[]) {
    // Could also be for (; argv; argv++). Doesn't increment argv pointer, which is benefit
    // for(int i = 0 ; ...), causes more assembly to be needed
    while(*argv){
        cout << *(argv++) << endl;
        // Note incremeneting like this is bad form, should use another line
    }
    return 0;
}
*/

// V2

/*
int main(int argc, char* argv[]) {
    top:
        if (*argv) {
            cout << *(argv++) << endl;
            goto top;
        }
    return 0;
}
*/

// V3

/*
#include <stdio.h>
int main(int argc, char* argv[]){
    top:
        if(*argv){
            puts(*(argv++));
            goto top;
        }
    return 0;
}
*/

// V4
// Apparently results in fewer lines of assembly language?
/*
#include <stdio.h>
int main(int argc, char* argv[]){
    top:
        if(*argv == NULL)
            goto bottom;
        
        puts(*(argv++));
        goto top;
    bottom:
        return 0;
}
*/

// V5
// Compile Process:
// aarch64-linux-gnu-as -o hello.o hello_world.S
// aarch64-linux-gnu-ld -o hello hello.o