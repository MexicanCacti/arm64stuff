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
        unsigned char   d_type;      // type of file **  // 1 Byte,  Access: [Base ADDR, 18]
        char            d_name[256]; // null term filename ** // 1 Byte, Access: [Base ADDR, 19]
    
    }

*/

    .global main
    .align 2
    .data
        directory_output:       .asciz "%-20llu 0x%02x %s\n" // so 3 inputs, llu, 02x, s .. x1, x2, x3 x0 contain directory_output
        current_dir:            .asciz "."
    .text

/*
    Pass in args:
    x1 -> address of argv array, so first instruction should be in [x1, 8]

    Register Use:
    x26 ->  DIR* base
    x25 ->  struct dirent* for each x26 entry
    x24 ->  Dir name
    x1  ->  inode
    x2  ->  type
    x3  ->  name (base addr of char array)
*/

retval  .req    w27

main:
    stp     x29, x30, [sp, -16]!
    stp     x26, x25, [sp, -16]!
    str     x24, [sp, -16]!
    mov     retval, 0

    ldr     x1, [x1, 8]
    cbnz    x1, 1f
    // If reached here, then do directory passed in, use current directory (.)
    ldr     x1, =current_dir
    mov     x24, x1

1:
    mov x0, x1
    bl      opendir
    
    cbz     x0, 98f // Null check (directory not exist)

    // If here, then opened a valid directory
    // Should return a DIR* dir
    // use readdir(dir) until not null, print using directory_output

    // Store Dir*
    mov     x26, x0

    // Set errno to be 0 before continue
    bl      __errno_location
    str     wzr, [x0]
2:
    mov     x0, x26
    // Read next entry, readdir auto increments Dir*
    bl      readdir

    cbz     x0, 3f // Null check
    
    // Store directory entry
    mov     x25, x0

    ldr     x0, =directory_output
    ldr     x1, [x25, 0]    // inode
    ldrb    w2, [x25, 18]    // type
    add     x3, x25, 19     // name
    bl      printf

    b       2b
3:
    // Reached here, finished reading all directory entries (readdir ret NULL)
    // Close directory, check for any errors
    mov     x0, x26
    bl      closedir
    bl      __errno_location
    ldr     w0, [x0]
    cbnz    w0, 99f
    
97:
    // So readdir returned null, check if errno != 0, if so then null b/c error not end of dirs
    bl      __errno_location
    ldr     w0, [x0]
    cbz     x0, 99f

98:
    // Reached here, command line arg gave an invalid directory
    mov     retval, 1
    mov     x0, x24
    bl      perror

99:
    ldr     x24, [sp], 16
    ldp     x25, x26, [sp], 16
    ldp     x29, x30, [sp], 16
    mov     w0, retval
    ret
.end
