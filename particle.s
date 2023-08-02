.ifndef PARTICLE_S
PARTICLE_S:

        .include "./time.s"
        .include "./star.s"
        .include "./util.s"
        .include "./fixed_point.s"

        .equ MAX_PARTICLES,     256

/* struct ParticleState */
        .equ PS_TIMESTAMP,      0                       // u32
        .equ PS_COLOR,          PS_TIMESTAMP + 4        // u32
        .equ PS_POS_X,          PS_COLOR + 4            // u64
        .equ PS_POS_Y,          PS_POS_X + 8            // u64
        .equ PS_SIZE,           PS_POS_Y + 8            // u64
        .equ PS_PHASE,          PS_SIZE + 8             // u64 (Q32)

        .equ STRUCT_PS_SIZE,    PS_PHASE + 8

/* struct ParticleManager */
        .equ PM_PARTICLE_ARRAY,         0                                                       // struct ParticleState[MAX_PARTICLES]
        .equ PM_PARTICLE_COUNT,         PM_PARTICLE_ARRAY + (STRUCT_PS_SIZE * MAX_PARTICLES)    // u64 in [0..MAX_PARTICLES]

        .equ STRUCT_PM_SIZE,            PM_PARTICLE_COUNT + 8



/*
 * Params:
 *      x0: out struct ParticleManager*
 */
particle_manager_init:
        stp     lr, x19, [sp, -16]!

        str     xzr, [x0, PM_PARTICLE_COUNT]

        ldp     lr, x19, [sp], 16
        ret





/*
 * Params:
 *      x0: in/out struct ParticleManager*
 *      x1: u64                                 <- x coordinate
 *      x2: u64                                 <- y coordinate
 *      x3: u64                                 <- size
 *      w4: u32                                 <- color
 *      x5: u64                                 <- phase (Q32)
 */
particle_manager_create_star:
        stp     lr, x19, [sp, -16]!

        ldr     x9, [x0, PM_PARTICLE_COUNT]
        cmp     x9, MAX_PARTICLES
        b.ge    particle_manager_create_star__end

        // Calculate offset in bytes to new ParticleState
        mov     x10, STRUCT_PS_SIZE
        mul     x10, x9, x10                    // x10 <- offset in bytes to new particle from beginning of array
        add     x10, x10, PM_PARTICLE_ARRAY     // x10 <- offset in bytes to new particle from beginning of struct
        add     x10, x0, x10                    // x10 <- &particles[particle_count]

        // Increment particle count
        add     x9, x9, 1
        str     x9, [x0, PM_PARTICLE_COUNT]

        str     x1, [x10, PS_POS_X]
        str     x2, [x10, PS_POS_Y]
        str     x3, [x10, PS_SIZE]
        str     w4, [x10, PS_COLOR]
        str     x5, [x10, PS_PHASE]

        bl      get_time
        str     w0, [x10, PS_TIMESTAMP]





particle_manager_create_star__end:
        ldp     lr, x19, [sp], 16
        ret



/*
 * Params:
 *      x0: in struct ParticleManager*  <- particle manager
 *      x1: out u32*                    <- framebuffer
 */
particle_manager_render:
        stp     lr, x19, [sp, -32]!
        stp     x20, x21, [sp, 16]

        ldr     x19, [x0, PM_PARTICLE_COUNT]    // x19 <- remaining particles
        add     x20, x0, PM_PARTICLE_ARRAY      // x20 <- pointer to current particle
        mov     x21, x1                         // x21 <- framebuffer

particle_manager_render__next:
        cmp     x19, 0          // Check if any particles remain to be drawn
        cbz     x19, particle_manager_render__end

        mov     x0, x20         // x0 <- current particle*
        mov     x1, x21         // x1 <- framebuffer
        bl      particle_draw

        sub     x19, x19, 1                     // Decrement remaining particles
        add     x20, x20, STRUCT_PS_SIZE        // Advance pointer to next particle
        b       particle_manager_render__next




particle_manager_render__end:
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 32
        ret



/*
 * Params:
 *      x0: in struct ParticleState*    <- particle state
 *      x1: out u32*                    <- framebuffer
 */
particle_draw:
        stp     lr, x19, [sp, -32]!
        stp     x20, x21, [sp, 16]

        mov     x20, x0         // x20 <- particle state
        mov     x21, x1         // x21 <- framebuffer

        bl      get_time
        lsl     x0, x0, 32              // x0 <- time in us             (Q32)
        ldr     x9, =US_PER_SECOND
        udiv    x0, x0, x9              // x0 <- time in seconds        (Q32)

        orr     x1, xzr, 4 << 32        // x1 <- amplitude
        orr     x2, xzr, 1 << 31        // x2 <- frequency
        ldr     x3, [x20, PS_PHASE]     // x3 <- phase
        bl      sine_wave_advanced

        q32_to_int      x9, x0, x9      // x9 <- delta size


        ldr     x0, [x20, PS_POS_X]
        ldr     x1, [x20, PS_POS_Y]
        ldr     x2, [x20, PS_SIZE]
        add     x2, x2, x9
        ldr     w3, [x20, PS_COLOR]
        mov     x4, x21
        bl      draw_four_point_star

        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 32
        ret






.endif
