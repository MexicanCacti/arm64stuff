/*
    Equivalent C++ code:
    long Sum(long * values, long length)                         
    {                                                            
        long sum = 0;                                           
        long * end = values + length;                            
        while (values < end)                                     
        {                                                        
            sum += *(values++);                                  
        }                                                        
        return sum;                                              
    }                                                            

*/

    .global Sum                                                // Make sum available to linker, func can be called in other source files
    .text                                                      // Tells ASsembler & linker what follows is code
    .align  4                                                  // Not necessary as all instructs are 4 bytes in length. Alignment rules

// Sum(long * values , long length)
// Means x0 has address of first long in the array
//       x1 contains the length



//  x0 is the pointer to data                                 
//  x1 is the length and is reused as `end`                    
//  x2 is the sum                                              
//  x3 is the current dereferenced value                        

Sum:                                                           
    mov     x2, xzr                                            // 0 out x2 register
    /*
        Below is equivalent to long * end = values + length
        Performing address arithmetic on longs
        Each long 8 bytes wide... x1, lsl 3 means....
        'Before adding value of x1 to x0, multiply x1 byte 8... shifting 3 to left is multiplying 2^3'
        So yk shifting 3 to right is dividing by 2^3
    */
    add     x1, x0, x1, lsl 3      // So add to the address the length * datasize, serves as buffer stop         
    b       2f                                                

1:  ldr     x3, [x0], 8            // Load value of address then increment by 8 bytes for next array value (post increment)                             
    add     x2, x2, x3             // Add x3 value to sum                             
2:  cmp     x0, x1                 // Check end of array      
    blt     1b                     // Address < length, still more to traverse, back to 1

    mov     x0, x2                 // Move the sum to the return register (x0)
    ret                                                        
`
    .end                                                       