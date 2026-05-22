/*
    C++: 
        void memCopy(uint8_t * dest, uint8_t * src)
        {
            for(int i = 0 ; i < 16; i++)
            {
                *(dest++) = *(src++);
            }
        }

    Above is silly, no need for 16 loop can instead do:
        void memCopy(uint64_t * dest, uint64_t  * src)
        {
            *(dest++) = *(src++); Deref value in src, store in dest, then increments src * dest by size of long
            *dest = *src; Then just copy the rest of the 8 bytes, no need to increment since only two longs long
        }

*/

.global memCopy
.code

memCopy:
    ldr x2, [x0], 8 // Load 8 bytes from @ address x0 to x2, then increment x0 by 8
    str x2, [x1], 8 // Store 8 bytes into destination [x1], then increment x1 by 8
    ldr x2, [x0]    // Load 8 bytes @ address x0 to x2
    str x2, [x1]    // store 8 bytes into destination [x1]
    ret             // Ret jusmps to address stored in x30 (link register). By ABI convention, func return values in x0


/*
    Note memCopy can be written in multiple ways...
    memCopy:
        ldp x2, x3, [x0] // Load first 8 bytes into x2, then second 8 bytes into x3
        stp x2, x3, [x1] // Store into x1's first 8 bytes, x2 then x3
        ret


    // Since Q registers already 16 bytes, can just load/store with q regs
    memCopy:
        ldr q2, [x0]
        str q2, [x1]

*/