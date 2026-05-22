    .global FindOldestPerson
    .text
    .align 2

/*  Dictionary to keep track of what register used for what
    w register used b/c age is an int :)
    x0 = struct Person* people, oldest_person * as return value
    w1 = int length
    w2 = oldest_age
    x3 = Person *
    x4 = end_ptr
    w5 = scratch
*/

/*
    // Implementation defined, but empty struct has 0 bytes or 1 byte
    struct Person
    {
        char* fname; // Pointer so 8 bytes 
        char* lname; // Pointer so 8 bytes
        int age; // 4 byte
        // 4 byte padding
    };
    So total size: 24 bytes
    // 8 byte alignment b/c struct alignment = max(member alignments)
    
*/

FindOldestPerson:
    cbz x0, 99f     // Short circuit, compare & branch if 0, check if nullptr
    mov w2, wzr     // Init oldest_Age to be 0
    mov x3, x0     // Init loop pointer, first person in Person list. Cpy base addr to x3 from x0.
                    // x0 holds both the first parameter & the place where return vals are found
    mov x0, xzr     // init ret val to 0 (null) after preserving init val into x3
    mov w5, 24      // Struct is 24 bytes wide
    smaddl x4, w1, w5, x3   // init end_ptr, signed multiply add long
                            // w1 (length) mutiplied by w5 (struct size) then added to x3 (base addr of array), then result into x4
                            // end addr = (length * struct Siz) + base addr
    b 10f   // Enter loop 

1:  ldr w5, [x3, p.age] // fetch loop ptr->age
    cmp w2, w5          // Compare to oldest_age
    csel w2, w2, w5, gt // Update based on cmp  If w2 > w5, then update w5 w/ value of w2 Equiv to...
                        // w2 = (w5 > w2) ? w5 : w2;

    csel x0, x0, x3, gt // Update based on cmp If w2 >w5, update return value to be ptr to person w/ oldest age
                        // x0 = (w5 > w2) ? x3 : x0;

    add x3, x3, 24      // Increment loop ptr (24 bytes since person struct 24 bytes long)
10: cmp x3, x4          // Check if loop ptr reached end_ptr
    blt 1b              // If loop ptr < end_ptr, back to label 1
99: ret

    .data
    .struct 0
p.fn:   .skip 8
p.ln:   .skip 8
p.age:  .skip 4
p.pad: .skip 4

    .end