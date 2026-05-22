    .global main
    .text
    .align 2


/*
    x20     (19 - 29 are persistent across func call)   counter
    w21     bool that says if I have printed anything

*/

/*
    mod(a, b) - implements a % b
    integer divide a by b - ex: 5 % 3 would need 5 // 3 yields -> 1
    multiply result by b - 1 * 3 is 3
    subtract result from a - 5 - 3 yields -> 2, thats the return val

    
*/
mod:
    sdiv    x2, x0, x1          // x2 gets a // b
    msub    x0, x2, x1, x0      // x0 gets  a - a // b * b
    ret

main:   
    stp     x20, x30, [sp, -16]!
    str     x21, [sp, -16]!
    
    mov     x20, xzr

1:  
    cmp     x20, 100 // x20 - 100
    bge     99f
    mov     w21, wzr
    // Test for divisble by 3
    mov     x0, x20
    mov     x1, 3

    bl      mod // No need to store/load sp, already did at top of main
    cbnz    x0, 5f

    // Counter divisible by 3
    ldr     x0, =fizz

    bl      printf
    mov w21, 1

5:  
    mov     x0, x20
    mov     x1, 5

    bl      mod
    cbnz    x0, 10f

    // Counter divisible by 5
    ldr     x0, =buzz

    bl      printf
    mov     w21, 1

10: // Tested the numbers, interrogate boolean
    cbz     w21, 20f
    // If we get here, we have printed something
    ldr     x0, =nl

    bl      printf
    b       80f

20: // If we get here, haven't printed a thing!
    ldr     x0, =fmt
    mov     x1, x20

    bl      printf

80: add     x20, x20, 1
    b       1b

99: ldr     x21, [sp], 16
    ldp     x20, x30, [sp], 16

    ret


    .data
fizz:   .asciz "Fizz"
buzz:   .asciz "Buzz"
nl:     .asciz "\n"
fmt:    .asciz "%ld\n"

    .end