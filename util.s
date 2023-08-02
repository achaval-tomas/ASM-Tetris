.ifndef UTIL_S
UTIL_S:

        .equ MOD_2_Q32_MASK,    (1 << 33) - 1
        .equ ONE_HALF_Q32,      1 << 31

/*
 * Params:
 *      x0: i64 (Q32)   <- x
 * Returns:
 *      x0: u64 (Q32)   <- sine_wave(x) in [0..1]
 */
sine_wave:
        stp     lr, x19, [sp, -16]!

        and     x0, x0, MOD_2_Q32_MASK          // x0 = x0 % 2 (map x0 to [0..2))

        /* Check if x0 is in [0..1) or [1..2] */
        lsr     x9, x0, 32                      // x9 = msb(x0 % 2)
        cbnz    x9, sine_wave__right_case       // (x0 % 2) >= 1.0 ?

        bl      sine_wave_left
        b       sine_wave__end
sine_wave__right_case:
        bl      sine_wave_right

sine_wave__end:
        ldp     lr, x19, [sp], 16
        ret



/*
 * Params:
 *      x0: i64 (Q32)   <- x (time)
 *      x1: u64 (Q32)   <- amplitude
 *      x2: u64 (Q32)   <- frequency
 *      x3: u64 (Q32)   <- phase
 * Returns:
 *      x0: u64 (Q32)   <- sine_wave_advanced(x) in [-amplitude..amplitude]
 * Comments:
 *      If x1 == x2 == 1 and x3 == 0 then this function looks like sin(2pix)
 */
sine_wave_advanced:
        stp     lr, x19, [sp, -16]!

        mov     x19, x1         // x19 <- amplitude

        asr     x0, x0, 16              // x0 <- time           (Q16)
        asr     x2, x2, 15              // x2 <- 2 * frequency  (Q16)
        mul     x0, x0, x2              // x0 <- time * 2*frequency               (Q32)
        add     x0, x0, x3              // x0 <- (time * 2*frequency) + phase     (Q32)
        mov     x9, ONE_HALF_Q32
        add     x0, x0, x9              // add default phase (so that it starts at y = 0)
        bl      sine_wave

        mov     x9, ONE_HALF_Q32
        sub     x0, x0, x9      // map x0 to [-0.5, 0.5]
        lsl     x0, x0, 1       // map x0 to [-1.0, 1.0]

        asr     x0, x0, 16      // Q16
        asr     x19, x19, 16    // Q16
        mul     x0, x0, x19     // map x0 to [-amplitude, amplitude]


        ldp     lr, x19, [sp], 16
        ret



/*
 * Params:
 *      x0: q32         <- x in [0..1]
 * Returns:
 *      x0: q32         <- sine_wave_left(x) in [0..1]
 */
sine_wave_left:
        asr     x9, x0, 16      // x9 = x       (Q16)
        mul     x9, x9, x9      // x9 = x^2     (Q32)

        mov     x10, #3         // x10 = 3
        lsl     x10, x10, 32    // x10 = 3              (Q32)
        lsl     x11, x0, 1      // x11 = 2*x            (Q32)
        sub     x10, x10, x11   // x10 = 3 - 2*x        (Q32)

        asr     x9, x9, 16      // x9 = x^2             (Q16)
        asr     x10, x10, 16    // x10 = 3 - 2*x        (Q16)

        mul     x0, x9, x10     // x0 = (x^2)(3 - 2*x)  (Q32)

        ret

/*
 * Params:
 *      x0: q32         <- x in [1..2]
 * Returns:
 *      x0: q32         <- sine_wave_right(x) in [0..1]
 */
sine_wave_right:
        mov     x9, #2          // x9 = 2
        lsl     x9, x9, 32      // x9 = 2               (Q32)
        sub     x9, x0, x9      // x9 = x - 2           (Q32)
        asr     x9, x9, 16      // x9 = x - 2           (Q16)
        mul     x9, x9, x9      // x9 = (x - 2)^2       (Q32)

        mov     x10, #1         // x10 = 1
        lsl     x10, x10, 32    // x10 = 1              (Q32)
        lsl     x11, x0, 1      // x11 = 2*x            (Q32)
        sub     x10, x11, x10   // x10 = 2*x - 1        (Q32)

        asr     x9, x9, 16      // x9 = (x - 2)^2       (Q16)
        asr     x10, x10, 16    // x10 = 2*x - 1        (Q16)

        mul     x0, x9, x10     // x0 = ((x - 2)^2)(2*x - 1)  (Q32)

        ret







.endif
