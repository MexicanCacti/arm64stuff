/*
    To run:
    aarch64-linux-gnu-gcc fizzbuzz.S -o fizzbuzz
    qemu-aarch64 -L /usr/aarch64-linux-gnu ./fizzbuzz
*/

    .global main
    .align  4 

    .data
    fizz: .asciz "Fizz"
    buzz: .asciz "Buzz"
    fizzbuzz: .asciz "FizzBuzz"
    neither: .asciz "Neither"

    .text
/*
    x0 -> Holds string for puts, also scratch for division
    x1 -> Current integer val
    x2 -> Scratch for arithmetic on integer val
    x3 -> Stores quotient
    x4 -> stores remainder
    x5 -> Flag to indicate fizz
    x6 -> Flag to indicate buzz
    x7 -> Stores integer value to go up to
*/

FizzBuzz:
    mov x7, x0
    mov x1, 0 // Init loop ptr
    b 10f // enter loop

    1:
    mov x5, 0 // Zero out Fizz & Buzz flags
    mov x6, 0

    mov x2, x1 // n
    mov x0, 3 // divisior

    udiv x3, x2, x0 // Quotient into x3
    msub x4, x3, x0, x2 // x4 = remainder, x3 = quotient, x4 = x2 - (x3 * x0) ... n - (quotient * divisor)
    cbnz x4, 2f // There is a remainder, not divisble by 3, time to check 5
    mov x5, 1 // Multiple of 3, Fizz

    2:
    mov x2, x1 // n
    mov x0, 5 // divisior

    udiv x3, x2, x0 // Quotient into x3
    msub x4, x3, x0, x2 // x4 = remainder, x3 = quotient, x4 = x2 - (x3 * x0) ... n - (quotient * divisor)
    cbnz x4, 3f // There is a remainder, Time to check results!
    mov x6, 1 // Multiple of 5, Buzz

    3:
    cbnz x5, 4f // Fizz is possible
    cbnz x6, 5f // Buzz is possible
    // Otherwise neither fizz nor buzz.. time to print integer
    ldr x0, =neither
    b print

    4:
    // If in this loop, then 3 is possible
    cbnz x6, 6f // So check 5, if not zero, then fizzbuzz
    ldr x0, =fizz

    b print

    5:
    ldr x0, =buzz
    b print

    6:
    ldr x0, =fizzbuzz

    print:
    // Puts is a function call & x1/x7 are scratch, need to keep state so store in stack
    stp x1, x7, [sp, -16]! // Function call, scratch registers need to be saved
    str x30, [sp, -16]! // Rememeber function call, need to save x30
    bl puts
    ldr x30, [sp], 16
    ldp x1, x7, [sp], 16

    10: cmp x1, x7
    bgt done
    add x1, x1, 1
    b 1b

    done: 
    ret

main:
    str x30, [sp, -16]!
    mov x0, 5
    bl FizzBuzz
    mov x0, 0
    ldr x30, [sp], 16
    ret

    .end