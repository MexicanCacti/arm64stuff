    .equ    NUM_FLAKES,     5
    .equ    BUFFER_SIZE,    2 * 4 * NUM_FLAKES //  2 Ints * 4 Byte * NUM_FLAKES

    .global     main
    .align      4
    .data

    print_addr:         .asciz  "Address: %u\n"
    print_int:          .asciz  "%d\n"
    snow_buffer:        .skip   BUFFER_SIZE 

    .text

main:
    stp     x29,x30,[sp,-16]!
    stp     x19,x20,[sp,-16]!
    str     x21,[sp, -16]!

    ldr     x19, =snow_buffer   
    ldr     x20, =snow_buffer      // Holds base address
    

    mov     x0, BUFFER_SIZE
    add     x19, x19, x0          // Holds address right after buffer

    mov     x21, x19        // store final address

    loop:
            cmp     x19,x20
            beq     done
            mov     w0, 65
            mov     w1, 63
            str    w0, [x19, -4]!
            str    w1, [x19, -4]!

            b       loop
    
done:

    print_loop:
        cmp     x19, x21
        beq     finish_print

        ldr     x1, [x19], 4
        ldr     x0, =print_int
        bl      printf

        b       print_loop


finish_print:
    ldr     x21,[sp],16
    ldp     x19,x20, [sp], 16
    ldp     x29,x30, [sp], 16
    ret
.end