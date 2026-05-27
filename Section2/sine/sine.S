/*
    To run:
    aarch64-linux-gnu-gcc sine.S -o sine
    qemu-aarch64 -L /usr/aarch64-linux-gnu ./sine
*/


/*
    Compute sine of an angle given in degrees in argv

    Sine of angle (in radians) can be found with Taylor Series:
        sin x = x - x^3/3! + x^5/5! - x^7/7! ...
    
        Note:
            Each term flips from add -> sub
            Each term based on odd integers, starting at 1

    Input args:
        - Angle in degrees whose sine to calculate (data type: double)
        - # of terms to evaluate. # of terms must lie btwn [1 -> 10] ... inclusive

    Components needed:
        Register : 0/1 Flag for Pos/Neg
        Register : Hold the taylor sum so far

        Function : Convert Degrees to radians

        Function : Takes in x & Power to calculate
        Function : Takes in the factorial to calculate
*/

    .global main
    .align 4
    .data
        bad_args_string:    .asciz "Less than two arguments given.\n"
        bad_terms_string:   .asciz "Number of terms is out of range.\n"
        output_string:      .asciz "The sine of %f degrees is %f\n"
        term_check:         .asciz "Current Term: %d\n"
        power_check:        .asciz "Power: %f\n"


        pi:                 .double 3.14159265358979323846
        d180:                .double 180.0
    .text

/*
    Registers:
        x -> Odd/Even Flag          x19
        x -> Total Loop Count       x20
        x -> Loop Counter           x21
        x -> Current Term           x22

        d -> Angle Value (radians)  d19
        d -> Taylor Sum             d20
        d -> Angle Value (degrees)  d21
*/
main:
    stp     x29, x30, [sp, -16]!
    stp     x19, x20, [sp, -16]!
    stp     x21, x22, [sp, -16]!
    stp     d19, d20, [sp, -16]!
    str     d21, [sp, -16]!

    // Check that two args were given
    cmp     x0, 2
    blt     input_error

    // temp save argv into x19
    mov     x19, x1

    // Extract angle & save to d19
    ldr     x0, [x1, 8]
    bl      atof
    fmov    d19, d0

    // Save the angle in degrees for future output
    fmov    d21, d19
    
    // Extract # of terms to eval
    mov     x1, x19
    ldr     x0, [x1, 16]
    bl      atoi

    // Check for term count out of bounds
    cmp     x0, 10
    bgt     terms_error
    cmp     x0, 0
    blt     terms_error

    // save # of terms to eval in x20
    mov     x20, x0

    // Convert angle to radians
    bl      D_To_R

    // Init Loop
    // Current term
    mov     x22, 3 
    // Counter
    mov     x21, 1
    // Pos/Neg flag, 0 = pos, 1 = neg
    mov     x19, 1
    
    // Taylor Series Sum, start w/ x
    fmov    d20, d19

    loop:
        cmp     x21, x20
        beq     output_results

        // Both branches need factorial, so do & save in d2
        bl      factorial
        scvtf   d2, x0

        // both branches need x ^ current term, so do & save in d1
        bl      term_power
        fmov     d1, d0

        //both branches need to calc x^current term / factorial of term, so do & save in d0
        fdiv    d0, d1, d2

        cmp     x19, 0
        beq     pos

        neg:
            // Next in series is subtraction, so make taylor negative & add
            fmov    d1, -1.0
            fmul    d0, d0, d1
            mov     x19, 0
            b       post
        pos:
            mov     x19, 1

        post:
            fadd    d20, d20, d0
            add     x22, x22, 2
            add     x21, x21, 1

            b       loop

    terms_error:
        ldr     x0, =bad_terms_string
        bl      printf
        b       done

    input_error:
        ldr     x0, =bad_args_string
        bl      printf 
        b       done

    output_results:
        ldr     x0, =output_string
        fmov    d0, d21
        fmov    d1, d20
        bl      printf
    done:

        ldr     d21, [sp], 16
        ldp     d19, d20, [sp], 16
        ldp     x21, x22, [sp], 16
        ldp     x19, x20, [sp], 16
        ldp     x29,x30, [sp], 16
        mov     x0, xzr
        ret


/*
Input:  d19 -> Angle in Radians
        x22 -> Current Term

Output: d0  -> Angle ^ term
*/
term_power:
    // Loop init
    mov     x1, x22
    mov     x0, 1
    fmov    d0, d19

    do_power:
        cmp     x0, x1
        beq     done_power

        fmul    d0, d0, d19
        add     x0, x0, 1
        b       do_power
    done_power:
        ret

/*
Input:  x22 -> Factorial term
Output: x0 -> Factorial product
*/
factorial:
    mov     x0, x22
    mov     x1, x0
    sub     x1, x1, 1

    do_fact:
        // Do factorial until x1 is 0... x1 is fact -> fact - 1 -> fact - 2...
        cmp     x1, 0
        beq     done_fact

        mul     x0, x0, x1
        sub     x1, x1, 1
        b       do_fact

    done_fact:
        ret

/*
Input:  d19 -> Angle in Degree
Output: d19 -> Angle in Radians

Formula: d19 * pi / 180.0
*/
D_To_R:
    ldr     x0, =pi
    ldr     d1, [x0]
    ldr     x0, =d180
    ldr     d0, [x0]

    fdiv    d1, d1, d0
    fmul    d19, d19, d1
    ret

.end

