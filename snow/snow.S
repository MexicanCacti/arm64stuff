/*
    To run:
    aarch64-linux-gnu-gcc snow.S -o snow
    qemu-aarch64 -L /usr/aarch64-linux-gnu ./snow
*/

/*
    Create a retro animation that mimic falling snow. (A trivial particle system)

    Particle:
        struct Particle {
            int32_t line;
            int32_t column;
        }
        So made up of 32 bit integers side by side, 8 Bytes total

        Screen Size
            Default terminal window: 80 chars across & 24 lines down. (1, 1) located on top-left
        
        Cursor Movement
            Snowflakes position using old-school escape sequence
                ESC [ line ; column H
            
            So to template using printf...
                "\033[%d;%dH"
            
            Erase screen after moving screen position:
                "\033[2J"
        
        Functions:
            Step()
                Line increased by 1, column either: unchanged, move left, move right
                If Line > 24, particle is Reset()
            
            Render()
                Move() to location then print a character w/out a newline
                Before print, ensure line & column within boundaries of terminal window
                Done print if outside range
            
            Reset()
                Inital Column can be anywhere btwn 1 -> 80 inclusive
                Always place particle above visible machine... choose randomly btwn -1 to -48 for line
        
        Allocate many snow flakes @ a time... Remember they each take up 2 int32_t values... so...
            Let n be the number of snow flakes you want to model @ a time
            Allocate 2 * 4 * n bytes
            Then need StepAll() and RenderAll()

        Main Loop:
            Position Cursor @ (1, 1)
            Erase the Screen
            StepAll()
            RenderAll()
            Position cursor @ (1,1), print new line
            Delay a short time... usleep()
*/

    .equ    NUM_FLAKES,     300
    .equ    BUFFER_SIZE,    2 * 4 * NUM_FLAKES
    .equ    LINE_INIT_LIMIT, 47
    .equ    TIOCGWINSZ,      0x5413

    .global     main
    .align      4
    .data

    COL_LIMIT:          .word   79
    COL_CHECK:          .word   80
    LINE_LIMIT:         .word   24

    terminal_info:      .asciz  "Rows: %d | Col: %d\n"
    print_int:          .asciz  "%d\n"
    line_col_print:     .asciz  "Line:%d | Col:%d\n"
    move_cursor:        .asciz  "\033[%d;%dH*"     // Line, Col
    new_line:           .asciz  "\n"
    clear_screen:       .asciz  "\033[2J"
    reset_cursor:       .asciz  "\033[1;1H"        // move cursor to 1,1
    print_flake:        .asciz  "*"
    snow_buffer:        .skip   BUFFER_SIZE  // Buffer for snow flakes   // 4 Byte Line, 4 Byte Col
    terminal_buffer:    .skip   8           // 4 Bytes for row, 4 bytes for col

    .text

/*
    x19 -> Base Address of snow_buffer
    x20 -> Ending Address of snow_buffer
*/

main:
    stp     x29,x30,[sp,-16]!
    stp     x19, x20, [sp, -16]!

    /*
        Get terminal dimenstion, use width & height to update COL_LIMIT, LINE_LIMIT, COL_CHECK
    */
    
    mov     x0, 1
    mov     x1, TIOCGWINSZ
    ldr     x2, =terminal_buffer
    bl      ioctl

    // Gonna assume no error :P
    // Resize Line/Col limits to be based on the size of the terminal this is ran on
    ldr     x3, =terminal_buffer
    ldrh    w1, [x3]    // LINE
    ldrh    w2, [x3, 2] // COL

    ldr     x0, =COL_CHECK
    str     w2, [x0]
    sub     w2, w2, 1
    ldr     x0, =COL_LIMIT
    str     w2, [x0]

    ldr     x0, =LINE_LIMIT
    str     w1, [x0]
    

    bl      Seed

    ldr     x19, =snow_buffer   // Base Address
    ldr     x20, =snow_buffer   
    mov     x0, BUFFER_SIZE
    add     x20, x20, x0        // x20 holds final address

    bl      Init_Flakes

    ldr     x0, =clear_screen
    bl      printf

    loop:
        ldr     x0, =reset_cursor
        bl      printf
        ldr     x0, =clear_screen
        bl      printf
        bl      StepAll
        bl      RenderAll
        ldr     x0, =reset_cursor
        bl      printf
        ldr     x0, =new_line
        bl      printf
        mov     x0, 131072
        bl      usleep
        b       loop
    done:
        ldp x19,x20,[sp],16
        ldp x29,x30,[sp],16
    ret

Print_Buf:
    stp     x29,x30,[sp,-16]!
    stp     x19,x20,[sp,-16]!

    print_loop:
    cmp     x19, x20
    beq     finish_print

    ldr     w1, [x20, -4]!  // line
    ldr     w2, [x20, -4]!  // col
    ldr     x0, =line_col_print
    bl      printf

    b       print_loop

    finish_print:
        ldp     x19,x20,[sp],16
        ldp     x29,x30,[sp],16

    ret

/*
    Input
        x19 -> Base Address of flake buffer
        x20 -> Final Address of flake buffer
    Output
        Flake buffer filled with NUM_FLAKES of form [ {Col, Line}, {Col, Line}, ...]
*/
Init_Flakes:
    stp     x29,x30,[sp,-16]!
    str     x20, [sp, -16]!

    init_flakes_loop:
        cmp     x20, x19
        beq     init_flakes_done
        bl      Rand_Line
        str     w0, [x20, -4]!
        bl      Rand_Col  
        str     w0, [x20, -4]!
        b       init_flakes_loop
    init_flakes_done:
        ldr     x20, [sp], 16
        ldp     x29,x30,[sp],16
    ret

Render:

    ret

/*
    Input
        x19 -> Base Address of flake buffer
        x20 -> Final Address of flake buffer
    Registers
        x21 -> Used to hold intermediary values
    Output
        Prints any flake whose line is visible @ its correct location
*/
RenderAll:
    stp     x29, x30, [sp, -16]!
    stp     x19, x20, [sp, -16]!

    render_all_loop:
        cmp     x19,x20
        beq     render_all_done
        ldr     w1, [x20, -4]!  // get line
        ldr     w2, [x20, -4]!  // get col

        ldr     x0, =LINE_LIMIT
        ldr     w3, [x0]
        cmp     w1, w3
        bgt     render_all_loop
        cmp     w1, 1
        blt     render_all_loop

        ldr     x0, =COL_CHECK
        ldr     w3, [x0]
        cmp     w2, w3
        bgt     render_all_loop
        cmp     w2, 1
        blt     render_all_loop

        ldr     x0, =move_cursor
        bl      printf

        b       render_all_loop

    render_all_done:
        ldp     x19,x20,[sp],16
        ldp     x29,x30,[sp],16
    ret

/*
    Input
        x1 -> line address to reset
    Ouput
        x0 -> Line is reset to be a value btwn -1 -> -48
*/
Reset:
    stp     x29, x30, [sp, -16]!
    bl      Rand_Line
    ldp     x29, x30, [sp], 16
    ret

/*
    Input
        x1 -> Address to Line in x20
        x2 -> Address to Col in x20

*/
Step:
    stp     x29, x30, [sp, -16]!
    stp     x19, x20, [sp, -16]!
    stp     x21, x22, [sp, -16]!

    mov     x19, x1
    mov     x22, x2
    // Line Update

    ldr     w1, [x19, -4]
    add     w1, w1, 1
    ldr     x0, =LINE_LIMIT
    ldr     w2, [x0]
    cmp     w1, w2
    ble     line_done

    bl      Reset
    mov     w1, w0
    line_done:
        str     w1, [x19, -4]

        // Col update
        mov     x20, x22
        ldr     w1, [x20, -4]
        mov     w21, w1
        bl      Rand_Col_Change
        mov     w1, w21
        cmp     x0, 1
        beq     col_done
        cmp     x0, 2
        beq     col_right

    col_left:
        sub     w1, w1, 1
        b       col_check
    col_right:
        add     w1, w1, 1
    col_check:
        ldr     x0, =COL_CHECK
        ldr     w2, [x0]
        cmp     w1, w2
        bgt     col_big
        cmp     w1, 1
        blt     col_small
        b       col_done
    col_big:
        // Col exceeds column limit, if limit was 80, move col to be @ 79
        ldr     x0, =COL_LIMIT
        ldr     w1, [x0]
        b       col_done
    col_small:
        mov     w1, 2
    col_done:
        str     w1, [X20, -4]

        ldp     x21, x22, [sp], 16
        ldp     x19, x20, [sp], 16
        ldp     x29, x30, [sp], 16
    ret

/*
    Input
        x19 -> Base Address of flake buffer
        x20 -> Final Address of flake buffer
    Registers
        x21 -> Used to hold intermediary values
    Output
        Every flake in buffer is updated to be line + 1, if line > 24, reset to be -1 -> -48
*/
StepAll:
    stp     x29, x30, [sp, -16]!
    stp     x20, x21, [sp, -16]!  
    step_all_loop:
        cmp     x20,x19
        beq     step_all_done
        
        mov     x1, x20
        sub     x20, x20, 4
        mov     x2, x20
        sub     x20, x20, 4
        bl      Step
        b       step_all_loop
    step_all_done:
        ldp     x20, x21, [sp], 16
        ldp     x29, x30, [sp], 16
    ret

Seed:
    stp     x29, x30, [sp, -16]!
    mov     x0, xzr
    bl      time

    //      time returns an signed 8 byte integer, convert to float, then to uint
    scvtf   d0, x0
    fcvtzu  x0, d0
    bl      srand
    ldp     x29, x30, [sp], 16
    ret

mod:
    sdiv    x2, x0, x1          // x2 gets a // b
    msub    x0, x2, x1, x0      // x0 gets  a - a // b * b
    ret

Rand_Line:
    stp     x29, x30, [sp, -16]!
    bl      rand
    
    mov     x1, LINE_INIT_LIMIT
    // Mod Returns 0 -> LINE_INIT_LIMIT, add 1 to be 1 -> LINE_INIT_LIMIT + 1
    bl      mod
    add     x0, x0, 1
    // Line needs to be -1 -> -LINE_INIT_LIMIT
    mov     x1, -1
    mul     x0, x0, x1
    ldp     x29, x30, [sp], 16
    ret

Rand_Col:
    stp     x29, x30, [sp, -16]!
    bl      rand
    ldr     x1, =COL_LIMIT
    ldr     w1, [x1]
    // Mod Returns 0 -> COL_LIMIT
    bl      mod
    add     x0, x0, 1
    ldp     x29, x30, [sp], 16
    ret

/*
    Output:
        x0 -> Either 0, 1, 2... 0 = stay the same, 1 = move left, 2 = move right
*/
Rand_Col_Change:
    stp     x29, x30, [sp, -16]!
    bl      rand
    mov     x1, 3
    // Mod Returns 0 -> 2
    bl      mod
    ldp     x29, x30, [sp], 16
    ret

.end
