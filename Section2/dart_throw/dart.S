/*
    To run:
    aarch64-linux-gnu-gcc dart.S -o dart
    qemu-aarch64 -L /usr/aarch64-linux-gnu ./dart
*/


/*
    Throws darts at a square with sides of two units
    ... Turns out the fraction of darts that fall within the unit circle is PI

    Choose two random numbers from zero to 1, treat them as a x, y
    Calc the distance to the origin
    Distance:
        sqrt( (x2 - x1)^2 + (y2 - y1)^2)
    If the distance puts the point inside the unit circle, record the trial as a hit

    Finally, Divide the # of bits by the # of trials and multiply by 4. Result will be ~ PI

    For the # of trails to run, this will come as a cmd line arg:
    ./dart #_of_trials

    Default to: 100000
    Don't worry about vetting cmd arg

    Note:
    AARCH instructs are 32 bits long so can't just do...
    mov     x0, 100000
        since the constant can fit along w/ op codes into 4 bytes. So put the constant in RAM and ldr to register
    
    Seeding random number...
        C/C++: srand((unsigned int) time(nullptr));
    
        Assembly:
        rand() returns an integer btwn 0 -> RAND_MAX
            In C/C++ would do: float v = float(rand()) / float(RAND_MAX);
        So convert that into assembly format.
        To get val of RAND_MAX, can write a C++ program & print the value
        To get the random number, put it into a subroutine called randf

    Remember to convert int to doubles... scvtf

    For FP ops use...
        fmul, fdiv, fsqrt, fmov, fcmp
    
    Also remember to use aliases... helpful for readability

    Added Challenge:
        Functionality to print results so far time-to-time in the loop
        Create a single line format string and add the following to the end:
            \033[1;1H\033[2J

        Prints old-school cursor ctrl sequences that 
        -   Move the cursor to line 1 column 1, and
        -   Erase everything below this position.

        \033 is the ESCAPE character represented in Octal.. Ocatal indicated by \0
*/


    .global main
    .align 2
    .data
        num_trials_print:        .asciz  "Executing: %d iterations.\n"
        num_hits_print:          .asciz  "Final Hits: %d\n"
        approximation_print:     .asciz  "Final Approximation: %f\n"
        random_number_print:     .asciz  "Random Value: %f\n"
        results_so_far_print:    .asciz  "Current Hits: %d\tCurrent Approximation: %f\t\033[1;1H\033[2J\n"

        // Must define float types in .data, can't do in .equ
        x_origin:                .double 0.0    
        y_origin:                .double 0.0
    .text
    
    x_val           .req    d8
    y_val           .req    d9
    num_trials      .req    x19
    current_count   .req    x20
    num_hits        .req    x21


    .equ    RAND_MAX, 2147483647
    .equ    DEFAULT_TRIALS, 100000
    .equ    LOOP_PRINT, 2048

/*
    Input: 
    x0 = argc, use to check if argc <= 1
    x1 = argv, deref and get first arg [x1, 8] to get num trials

    Regs:
    d0 = scratch
    d1 = distance
*/
main:
    stp     x29, x30, [sp, -16]!
    stp     x_val, y_val, [sp, -16]!
    stp     num_trials, current_count, [sp, -16]!
    str     num_hits, [sp, -16]!
    
    // Check if num trials arg given
    cmp     x0, 1
    beq     empty_arg    

    // Convert CMD arg to int
    ldr     x0, [x1, 8]
    bl      atoi
    b       init

empty_arg:
    ldr     x1, =DEFAULT_TRIALS // Note: LDR requires that =...
    mov     x0, x1

init:
    // Save & Print # of trials
    mov     num_trials, x0
    mov     x1, num_trials
    ldr     x0, =num_trials_print
    bl      printf

    // Seed the random number generator
    bl      seed

    // init the loop
    mov     current_count, xzr
    mov     num_hits, xzr

loop:
    cmp     current_count, num_trials
    beq     done
    
    // Generate x & y val
    bl      randf
    fmov    x_val, d0
    bl      randf
    fmov    y_val, d0

    // For loading doubles do this pattern, load address, then load double stored @ address
    ldr     x0, =x_origin
    ldr     d0, [x0]
    fsub    x_val, x_val, d0

    ldr     x0, =y_origin
    ldr     d0, [x0]
    fsub    y_val, y_val, d0

    fmul    d0, x_val, x_val
    fmov     x_val, d0

    fmul    d0, y_val, y_val
    fmov     y_val, d0

    // Distance = sqrt(x^2 + y^2)
    fadd    d1, x_val, y_val
    fsqrt   d0, d1

    // Check if lands
    fmov    d1, 1.0
    fcmp    d0, d1
    bgt     post

    // Landed, distance <= 1.0, score a hit
    add     num_hits, num_hits, 1
post:
    add     current_count, current_count, 1
    mov     x0, current_count
    mov     x1, LOOP_PRINT
    bl      mod
    cbnz    x0, step
    bl      print_current

step:
    b       loop
done:

    // Output # of hits
    mov     x1, num_hits
    ldr     x0, =num_hits_print
    bl      printf

    // Output Approximation... (# hits / # of trials) * 4
    scvtf   d3, num_hits
    scvtf   d4, num_trials

    fdiv    d0, d3, d4
    fmov    d1, 4.0
    fmul    d0, d0, d1
    ldr     x0, =approximation_print
    bl printf

    ldr     num_hits, [sp], 16
    ldp     num_trials, current_count, [sp], 16
    ldp     x_val, y_val, [sp], 16
    ldp     x29, x30, [sp], 16
    mov     x0, xzr
    ret


mod:
    sdiv    x2, x0, x1          // x2 gets a // b
    msub    x0, x2, x1, x0      // x0 gets  a - a // b * b
    ret

print_current:
    stp     x29, x30, [sp, -16]!
    scvtf   d3, num_hits
    scvtf   d4, current_count
    fdiv    d0, d3, d4
    fmov    d1, 4.0
    fmul    d0, d0, d1
    mov     x1, num_hits
    mov     x2, current_count
    ldr     x0, =results_so_far_print
    bl      printf
    ldp     x29, x30, [sp], 16
    ret

/*
    srand: srand((unsigned int) time(nullptr));

    time(null): returns an signed 8 byte integer

*/
seed:
    stp     x29, x30, [sp, -16]!
    mov     x0, xzr
    bl      time

    //      time returns an signed 8 byte integer, convert to float, then to uint
    scvtf   d0, x0
    fcvtzu  x0, d0
    bl      srand

    ldp     x29, x30, [sp], 16
    ret

/*
    rand() produces a number btwn 0 to RAND_MAX, div by RAND_MAX to get integer. signed number ret
        Formula:    v = float(rand()) / float(RAND_MAX)
    V returned in d0

    Integer to double conversion:    SCVTF   <DESTINATION>   <FLOAT>

    Double value return in d0 register
*/
randf:
    stp     x29, x30, [sp, -16]!
    
    // Rand stores the signed int val btwn 0 -> RAND_MAX in x0 register
    bl      rand
    
    // Convert signed int to double
    scvtf   d0, x0

    // Save for RAND_MAX
    mov     x0, RAND_MAX
    scvtf   d1, x0

    // Clamp to be btwn 0 -> 1
    fdiv    d0, d0, d1
    ldp     x29, x30, [sp], 16
    ret
.end
