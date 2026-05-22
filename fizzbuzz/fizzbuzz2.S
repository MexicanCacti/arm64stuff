


    .global main
    .data
    fizz: .asciz  "fizz"
    buzz: .asciz  "buzz"
    fizzbuzz: .asciz  "fizzbuzz"
    itoa_buf: .skip 16  // Static buffer of 16 bytes for ascii array storage
    .text

/*
    ITOA -> Basically get every digit of number by dividing by 10
*/

/*
    x1 -> Number
    x2 -> Divisor (10)

    x4 -> Quotient
    x5 -> Remainder
    Return: 
    x0 -> ptr to first digit (mem address)
*/

itoascii:
    ldr x6, =itoa_buf
    add x6, x6, 15  // x6 points to just past buffer end
    strb wzr, [x6] // Null Term

    mov x1, x0  
    mov x2, 10

    cbz x1, zero

    loopscii:
    udiv x4, x1, x2 // Quotient, Divisor, n
    msub x5, x4, x2, x1 // x5 = n - quotient * 10... x5: Remainder, x4: Quotient, x2: Divisor, x1: n
    mov x1, x4

    add x5, x5, '0' // Add '0' to convert to ASCII representation
    strb w5, [x6, -1]! // --x6; *x6 = digit

    cbnz x1, loopscii

    mov x0, x6 // ptr to first digit
    ret

    zero:
    mov w1, '0'
    strb w1, [x6, -1]!
    mov x0, x6
    ret

/*
    Note for numbers: 48 = ascii '0'
    x0 -> Store String for puts
    x1 -> Number to go up to
    x2 -> Loop register (current integer)
    x3 -> Fizz flag
    x4 -> Buzz flag
    x5 -> Quotient
    x6 -> Remainder
    x7 -> Divisor

*/
FizzBuzz:
    str x30, [sp, -16]!
    mov x1, x0 // Store n in x1
    mov x2, 0  // start @ 0

    loop:
    mov x3, 0 // reset flags, 0 = non div, 1 = div
    mov x4, 0

    mov x5, x2
    mov x7, 3
    sdiv x5, x2, x7 // Quotient, Divisor, n
    msub x6, x5, x7, x2 // x6: Remainder, x5: Quotient, x7: divisor, x2: n

    cbnz x6, BuzzCheck
    mov x3, 1

    BuzzCheck:
    mov x5, x2
    mov x7, 5
    sdiv x5, x2, x7 // Quotient, Divisor, n
    msub x6, x5, x7, x2 // x6: Remainder, x5: Quotient, x7: divisor, x2: n
    cbnz x6, FizzFlag
    mov x4, 1

    FizzFlag:
    cbz x3, BuzzFlag // No Fizz, only option would be buzz
    ldr x0, =fizz
    cbz x4, print
    ldr x0, =fizzbuzz
    b print

    BuzzFlag:
    cbz x4, NoFlag // No Fizz, no Buzz, so print integer
    ldr x0, =buzz
    b print

    NoFlag:
    stp x1, x2, [sp, -16]!
    mov x0, x2
    bl itoascii
    // Now x0 should contain byte array ptr, perfect for puts
    ldp x1, x2, [sp], 16

    print:
    // Remember, make func call: store any scratch you wanna keep
    stp x1, x2, [sp, -16]!
    bl puts
    ldp x1, x2, [sp], 16
    
    add x2, x2, 1
    cmp x1, x2
    bge loop
    ldr x30, [sp], 16
    ret

main:
    str x30, [sp, -16]!
    mov x0, 100
    bl FizzBuzz
    mov x0, 0
    ldr x30, [sp], 16
    ret
.end