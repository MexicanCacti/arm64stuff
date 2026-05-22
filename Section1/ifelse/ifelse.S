/*
    To run:
    aarch64-linux-gnu-gcc main.S -o main
    qemu-aarch64 -L /usr/aarch64-linux-gnu ./main
*/

    .global main                                                        // 1 
    .text                                                               // 2 
                                                                        // 3 
main:                                                                   // 4 
    stp     x29, x30, [sp, -16]!                                        // 5 
    mov     x1, 10                                                      // 6 
    mov     x0, 15                                                       // 7 
                                                                        // 8 
    cmp     x0, x1                                                      // 9 
    ble     1f                                                          // 10 
    ldr     x0, =T                                                      // 11 
    bl      puts                                                        // 12 
    b       2f                                                          // 13 
                                                                        // 14 
1:  ldr     x0, =F                                                      // 15 
    bl      puts                                                        // 16 
                                                                        // 17 
2:  ldp     x29, x30, [sp], 16                                          // 18 
    mov     x0, xzr                                                     // 19 
    ret                                                                 // 20 
                                                                        // 21 
    .data                                                               // 22 
F:  .asciz  "FALSE"                                                     // 23 .asciz assembly directive to create C String
T:  .asciz  "TRUE"                                                      // 24 
                                                                        // 25 
    .end                                                                // 26 