/*
    To run:
    aarch64-linux-gnu-gcc main.S -o main
    qemu-aarch64 -L /usr/aarch64-linux-gnu ./main

    Debug:
    aarch64-linux-gnu-gcc -g -O0 main.S -o main
    qemu-aarch64 -L /usr/aarch64-linux-gnu -g 1234 ./main
*/

/*
    Use library calls to open given linux directory (or default current) for reading
    Will read every directory entry & print on each files inode number, type and name
    inode -> Index node, stores all metadata for file

    Format of print:
    Inode number        type    name
    40905818             0x04 .
    7943328              0x04 ..
    40905889             0x08 README.md
    40908053             0x08 a.out
    40906048             0x08 main.c
    40905888             0x08 .gitignore
    40905819             0x04 .git
    40907182             0x04 .vscode

    
    Inode Number -> Left justified in a field of 20 digits using printf
    File Type -> Single Byte hex
    File name

    If given directory that doesn't exist: give error message produced by perror()

    All ends well: return 0 else 1

    use struct: struct dirent * de;

    Library calls:
    DIR* opendir(const char* name)
        Ret: pointer to directory stream, Stream positioned at first entry in directory
             NULL on error, errno set to indicate error

    int closedir(DIR *dirp)
        Ret: 0 on success
            -1 on error, errno set to indicate error

    struct dirent* readdir(DIR * dirp);
        Returns pointer to dirent structre representing next entry directory in direcory stream
            pointed to by dirp
        Returns NULL on reaching end of directory stream or if error occurs

    int*  __errno_location(void*);
        Returns ADDRESS to location of errno, dereference with [] to get value

    dirent structre:
    struct dirent {
        ino_t           d_ino;       // inode number ** -> 8 Bytes, Access: [Base ADDR] 
        off_t           d_off;       // Position of dir entry in dir stream -> 8 Bytes, Access: [Base ADDR , 8]
        unsigned short  d_reclen;    // length of record -> 2 Bytes, Access: [Base ADDR, 16] 
        unsigned char   d_type;      // type of file **  // 1 Byte, Access: [Base ADDR, 18]
        char            d_name[256]; // null term filename ** // 1 Byte, Access: [Base ADDR, 19]
    
    }

*/

    .global main
    .align 2
    .data
        default_dir:        .asciz  "."
        test_output:        .asciz  "%d\n"
        directory_entry:    .asciz  "%-20llu 0x%02x %s\n"
    .text

// x19 -> x28 callee saved registers

/*
    Input -> x1 = argv, deref and get first arg [x1, 8] to get dir name
    
    x19 -> Dir name
    x20 -> Base Directory Dir*
    x21 -> Directory Entry Dir*

    w27 -> Return value

*/


retval  .req    w27

// If statements: avoid if condition false
main:
    stp     x29, x30, [sp, -16]!
    stp     x19, x20, [sp, -16]!
    stp     x21, x27, [sp, -16]!

    mov     retval, 1

    ldr     x19, [x1, 8]

    cbnz    x19, 1f

    // Reached here, no directory provided, use the default
    ldr     x19, =default_dir
1:  
    mov     x0, x19
    bl      opendir
    cbz     x0, 98f
    // Reached here, can open DIR. Save into x20
    mov     x20, x0

    // Set errno to 0
    bl      __errno_location
    str     xzr, [x0]

2:
    mov     x0, x20
    bl      readdir
    // Null check
    cbz     x0, 96f
    // Reached here, can get directory entry
    mov     x21, x0

    ldr     x1, [x21]       // inode
    ldrb    w2, [x21, 18]   // type, Type is 1 byte so load 1 byte!

    mov     x3, x21        
    add     x3, x3, 19     // name, get start of memory address for char array. Base + offset
    ldr     x0, =directory_entry
    bl      printf

    b       2b
96: 
    bl      __errno_location
    ldr     x1, [x0]
    cbz     x1, 97f

    // Reached here, there was an error in readdir
    mov     x0, x19
    bl      perror
97:
    // Clean up
    mov     x0, x20
    bl      closedir
    b       99f
98:
    // Reached here, directory input invalid/couldn't open
    mov     x0, x19
    bl      perror
99:
    ldp     x21, x27, [sp], 16
    ldp     x19, x20, [sp], 16
    ldp     x29, x30, [sp], 16
    mov     w0, retval
    ret
.end





    