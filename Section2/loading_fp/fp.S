/*
    All AARCH64 instruct 4 bytes long, so all literals must be encoded into the 4 byte instruct
    FP values are always at least 4 bytes long, use FP literals is extremely constrained

    EX:
        fmov    d0, 1
        fmov    d0, 1.1
    The first example works but the 2nd causes an error.

    So to load a float, you could translate the value to binary and do as the following:

    main:   
        str     x30, [sp, -16]!
        ldr     s0, =0x3fc00000     // Puts translated value of 1.5 into s0 (float goes in s register)
        fcvt    d0, s0              // Converts single precision number to double precision number for printing. printf() only knows how to print dbl
                                        precision values, so specifying a float converts to double before emission
        ldr     x0, =fmt        
        bl      printf 
        ldr     x30, [sp], 16
        mov     w0, wzr
        ret
    
    fmt:    .asciz  "f\n"

    Assembler provides .float and .double directives for specifying float & double values putting them into RAM

    Prints array of floats and doubles:

    // .req gives symbolic names
    counter .req    x20
    dptr    .req    x21
    fptr    .req    x22
    // .equ encodes a small int literal val & give symbolic name (removes "magic number")
            .equ    max,4

    main:
        stp     all the .req registers + x30
        ldr     dptr, =d
        ldr     fptr, =f
        mov     counter, xzr

    1:
        cmp     counter, max
        beq     2f

        // Just as w/x0 -> w/x7 scratch, s/d0 -> s/d7 are scratch as well
        // Doubles, (8 bytes each)
        ldr     d0, [dptr, counter, lsl 3] // Counter x 8 then added to dptr, equiv to d0 = dptr[counter]
        // Floats   (4 bytes each)
        ldr     s1, [fptr, counter, lsl 2] // Counter x 4 then added to fptr, equiv to s1 = fptr[counter]
        fcvt    d1, s1
        ldr     x0, =fmt
        add     counter, counter, 1
        mov     x1, counter
        bl      printf
        b       1b

    2:
        ldp    all the registers that were stp
        mov    w0, wzr
        ret

    .data
    fmt:    .asciz  "%d %f %f\n"
    d:      .double 1.11111, 2.22222, 3.33333, 4.44444
    f:      .float 1.11111, 2.22222, 3.33333, 4.44444
    .end


    fitting 32 bits into 32 bit bag

    AARCH64 instructs 32 bits in width yet ....
    ldr     s0, =0x3fc00000         
        Appears to show a 32 bit constant being held in an instruction that is 32 bits wide.
        ... 32 bits wide b/c there are 8 characters (bytes)... 8 x 4 = 32

        Assembler does some magic to make this possible....

        In gdb you would find:
        b+ 0x784 <main+4>          ldr     s0, 0x7a0 <main+32>
        0x7a0 <main+32>         .inst   0x3fc00000 ; undefined  

        .inst is an ARM specific GNU assmebler directive that says ¯\_(-)_/¯

        Compile emitted a make believe instruction that happens to have the value of our literal
        Reaches ahead a short distance to load the value of another location in memory where our constant is really found

*/