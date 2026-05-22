/*
    To run:
    aarch64-linux-gnu-gcc main.S -o main
    qemu-aarch64 -L /usr/aarch64-linux-gnu ./main
*/

    .global     main
    .align      2
    .data
    io_buffer:  .skip   8 // static buffer of 8 bytes
//    file_name:  .asciz  "echo.txt"
//    fmt:        .asciz "%s"
//    nl:         .asciz "\n"
    write_error: .asciz "Error in write"
    .text

/*
    Lowest level I/O:
    ssize_t read(int fd, void* buf, size_t count);
        Read up to count bytes from file descripter (fd) into the buffer starting @ buf
        RET: # of bytes read, 0 means EOF, the file positio nadvanced by that number

    ssize_t write(int fd, const void* buf, size_t count);
        Write up to count bytes from buffer starting at buf to file referred to by file descripter fd
        RET: # of bytes written, -1 if error

    ssize_t -> long -> x
    int -> int -> w
    void* -> void* -> x
    size_t -> ulong -> x

    Both cases, need a buffer, static buffer in .data segment

    File Descriptor     Name        C++ equiv
    0                   stdin       cin
    1                   stdout      cout
    2                   stderr      cerr

*/

/*
    w0 = file descriptor
    x1 = buffer


*/

//fd 		.req	w28 // fd always stored in w28
retval  .req    w27

main:
    stp     x29, x30, [sp, -16]!
    mov     x29, sp

    mov retval, 0
    /*
    // Attempt open file
    bl      open_file
    cmp     w0, wzr
    bge     1f

    // Else failed
    b       98f
    */

1:
    // Read from console
    mov     w0, 0           // cin
    ldr     x1, =io_buffer
    mov     x2, 1   // Read 1 byte @ a time
    bl      read

    // Check for ctrl + D or error
    cmp      x0, 0      
    ble      99f

    // std out
    mov     w0, 1           // cout
    ldr     x1, =io_buffer
    mov     x2, 1
    bl      write    

    cmp     x0, 0
    blt     98f

    // Loop
    b       1b

98:
    ldr x0, =write_error
    bl perror
    mov retval, 1

99:
    /*
    // close file
    mov w0, fd
    bl close
    */
    ldp     x29, x30, [sp], 16
    mov     w0, retval
    ret
.end

/*
    int open(const char* pathname, int flags, mode_t mode)
    Ret: fd, -1 if unsucessful
    0102: flag O_RDRW | O_CREAT
    0600: mode rw------, rw for owner but no permission for anyone else

*/
/*
open_file:
    stp     x29, x30, [sp, -16]!
    ldr     x0, =file_name
    mov     w1, 0102        // flags
    mov     w2, 0600        // mode
    bl      open
    mov     fd, w0
    ldp     x29, x30, [sp], 16
    ret
*/