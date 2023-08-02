.ifndef BACKGROUND_S
BACKGROUND_S:

        .include "./constants.s"
        .include "./rand.s"
        .include "./particle.s"

        .equ BACKGROUND_STAR_SECTION_SIZE,      80
        .equ STARS_PER_BACKGROUND_SECTION,      1



/*
 * Params:
 *      x0: in/out struct ParticleManager*      <- particle manager
 */
create_background_starfield:
        stp     lr, x19, [sp, -80]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]
        stp     x24, x25, [sp, 48]
        stp     x26, x27, [sp, 64]

        mov     x19, x0         // x19 <- particle manager

        mov     x21, 0          // x21 <- section y iterator

create_background_starfield__next_row:
        mov     x20, 0          // x20 <- section x iterator

create_background_starfield__next_col:

        mov     x25, 0          // x25 <- star counter
create_background_starfield__next_star:
        mov     w0, 0
        mov     w1, BACKGROUND_STAR_SECTION_SIZE
        bl      rand_gen_in_range
        mov     x22, x0         // x22 <- star x inside section

        mov     w0, 0
        mov     w1, BACKGROUND_STAR_SECTION_SIZE
        bl      rand_gen_in_range
        mov     x23, x0         // x23 <- star y inside section

        mov     w0, 5
        mov     w1, 24
        bl      rand_gen_in_range
        mov     x24, x0         // x24 <- star size

        mov     w0, 0
        mov     w1, 16
        bl      rand_gen_in_range
        lsl     x26, x0, 32     // x26 <- star animation phase (Q32)

        mov     w0, 0x10
        mov     w1, 0xCF
        bl      rand_gen_in_range
        lsl     x27, x0, 24     // x27 <- star alpha

        mov     x0, x19

        mov     x9, BACKGROUND_STAR_SECTION_SIZE

        mul     x1, x20, x9
        add     x1, x1, x22

        mul     x2, x21, x9
        add     x2, x2, x23

        mov     x3, x24
        ldr     w4, =0x00FFFFFF
        add     w4, w4, w27             // Insert alpha to color
        mov     x5, x26                 // x5 <- phase
        bl      particle_manager_create_star



        add     x25, x25, 1     // Increment star counter
        cmp     x25, STARS_PER_BACKGROUND_SECTION
        b.lt    create_background_starfield__next_star

        add     x20, x20, 1
        cmp     x20, (SCREEN_WIDTH / BACKGROUND_STAR_SECTION_SIZE)
        b.lt    create_background_starfield__next_col

        add     x21, x21, 1
        cmp     x21, (SCREEN_HEIGH / BACKGROUND_STAR_SECTION_SIZE)
        b.lt    create_background_starfield__next_row




        ldp     x26, x27, [sp, 64]
        ldp     x24, x25, [sp, 48]
        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 80
        ret












.endif
