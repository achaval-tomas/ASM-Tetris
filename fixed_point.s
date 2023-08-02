.ifndef FIXED_POINT_S
FIXED_POINT_S:

        .equ ROUNDING_CONSTANT,         1 << 31


        /* PRE: Rn != Rt */
        .macro q32_to_int, Rd:req, Rn:req, Rt:req
        mov     \Rt, ROUNDING_CONSTANT
        add     \Rd, \Rn, \Rt
        asr     \Rd, \Rd, 32
        .endm








.endif
