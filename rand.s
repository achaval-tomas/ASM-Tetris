.ifndef RAND_S
RAND_S:

        .include "./addresses.s"

/*
 * Params:
 *      w0: u32         <- min (inclusive)
 *      w1: u32         <- max (exclusive)
 * Returns:
 *      w0: u32         <- random number in range [min; max)
 */
rand_gen_in_range:
        stp     lr, x19, [sp, -32]!
        stp     x20, x21, [sp, 16]

        ldr     x19, =RNG_NUMBER_ADDRESS
        ldr     w19, [x19]              // w19 <- random number in range [0..U32_MAX]

        sub     w20, w1, w0             // w20 <- max - min == length of range
        udiv    w21, w19, w20           // w21 <- R div (max - min)
        mul     w21, w21, w20           // w21 <- (R div (max - min)) * (max - min)

        sub     w19, w19, w21           // w19 <- remainder of R / (max - min), in range [0..(max - min))
        add     w0, w19, w0             //  w0 <- offseted remainder, in range [min..max)

        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 32
        ret


.endif
