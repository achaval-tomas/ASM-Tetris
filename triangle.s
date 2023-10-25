.ifndef TRIANGLE_S
TRIANGLE_S:

        .include "./constants.s"
        .include "./pixel.s"
        .include "./fixed_point.s"

/* struct DrawTriangleInfo */
        .equ DTI_X0,            0               // u64
        .equ DTI_Y0,            DTI_X0 + 8      // u64
        .equ DTI_X1,            DTI_Y0 + 8      // u64
        .equ DTI_Y1,            DTI_X1 + 8      // u64
        .equ DTI_X2,            DTI_Y1 + 8      // u64
        .equ DTI_Y2,            DTI_X2 + 8      // u64


        .equ STRUCT_DTI_SIZE,   DTI_Y2 + 8





        .macro swap, rA:req, rB:req, rT:req
        mov     \rT, \rA
        mov     \rA, \rB
        mov     \rB, \rT
        .endm


/*
 * Params:
 *      x0: u64         <- x0 coord (game coordinates)
 *      x1: u64         <- y0 coord (game coordinates) (y0 != y1, y2)
 *      x2: u64         <- x1 coord (game coordinates) (x1 <= x2)
 *      x3: u64         <- y1 coord (game coordinates) (y1 == y2)
 *      x4: u64         <- x2 coord (game coordinates) (x1 <= x2)
 *      x5: u64         <- y2 coord (game coordinates) (y1 == y2)
 *      w6: u32         <- argb color
 *      x7: out* u32    <- framebuffer
 */
draw_flat_bottom_triangle:
        stp     lr, x19, [sp, -80]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]
        stp     x24, x25, [sp, 48]
        stp     x26, x27, [sp, 64]
        sub     sp, sp, 8       // Make space for bottom y coord (TODO: clean)


        lsl     x20, x0, 32     // x20 <- left line x   (Q32)
        lsl     x21, x0, 32     // x21 <- right line x  (Q32)

        sub     x9, x2, x0      // x9 <- x1 - x0
        lsl     x9, x9, 32      // x9 <- x1 - x0        (Q32)
        sub     x10, x3, x1     // x10 <- y1 - y0
        sdiv    x22, x9, x10    // x22 <- (x1 - x0) / (y1 - y0)         (Q32)

        sub     x9, x4, x0      // x9 <- x2 - x0
        lsl     x9, x9, 32      // x9 <- x2 - x0        (Q32)
        sub     x10, x5, x1     // x10 <- y2 - y0
        sdiv    x23, x9, x10    // x23 <- (x2 - x0) / (y2 - y0)         (Q32)


        mov     x19, x1         // x19 <- y scanline
        str     x3, [sp]        // [sp] <- bottom y coord (last scanline)
        mov     w26, w6         // w26 <- color
        mov     x27, x7         // x27 <- framebuffer

draw_flat_bottom_triangle__next_line:
        mov     x25, ROUNDING_CONSTANT
        add     x24, x20, x25   // x24 <- left line x coordinate (Q32)
        lsr     x24, x24, 32    // x24 <- scanline x coordinate (rounded).

        add     x25, x21, x25   // x25 <- right line x coordinate (Q32)
        lsr     x25, x25, 32    // x25 <- right line x coordinate (rounded)

draw_flat_bottom_triangle__next_pixel:
        mov     x0, x24         // x0 <- line's pixel x
        mov     x1, x19         // x1 <- line y
        mov     x2, x27         // x2 <- framebuffer
        mov     w3, w26         // w3 <- color
        bl      draw_argb_pixel_at


        add     x24, x24, 1     // Advance scanline x
        cmp     x24, x25        // Check if we finished scanline
        b.le    draw_flat_bottom_triangle__next_pixel
        /* We finished drawing scanline */

        sub     x20, x20, x22   // Move left line x by slope
        sub     x21, x21, x23   // Move right line x by slope
        sub     x19, x19, 1
        ldr     x9, [sp]        // x9 <- last scanline y coordinate
        cmp     x19, x9         // Check if we are at or before last line
        b.ge    draw_flat_bottom_triangle__next_line
        /* We finished drawing triangle */


        add     sp, sp, 8
        ldp     x26, x27, [sp, 64]
        ldp     x24, x25, [sp, 48]
        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 80
        ret





/*
 * Params:
 *      x0: u64         <- x0 coord (game coordinates)
 *      x1: u64         <- y0 coord (game coordinates)
 *      x2: u64         <- x1 coord (game coordinates)
 *      x3: u64         <- y1 coord (game coordinates)
 *      x4: u64         <- x2 coord (game coordinates)
 *      x5: u64         <- y2 coord (game coordinates)
 *      w6: u32         <- argb color
 *      x7: out* u32    <- framebuffer
 */
draw_triangle:
        stp     lr, x19, [sp, -80]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]
        stp     x24, x25, [sp, 48]
        stp     x26, x27, [sp, 64]

        /* Sort coordinates by height (bubble sort) */

        cmp     x1, x3          // y0 < y1 ?
        b.ge    draw_triangle__end_sort_0
        /* y0 < y1 */
        swap    x0, x2, x9         // x0 <-> x1
        swap    x1, x3, x9         // y0 <-> y1
draw_triangle__end_sort_0:

        cmp     x3, x5          // y1 < y2 ?
        b.ge    draw_triangle__end_sort_1
        /* y1 < y2 */
        swap    x2, x4, x9         // x1 <-> x2
        swap    x3, x5, x9         // y1 <-> y2
draw_triangle__end_sort_1:

        cmp     x1, x3          // y0 < y1 ?
        b.ge    draw_triangle__end_sort_2
        /* y0 < y1 */
        swap    x0, x2, x9         // x0 <-> x1
        swap    x1, x3, x9         // y0 <-> y1
draw_triangle__end_sort_2:

        sub     sp, sp, STRUCT_DTI_SIZE
        str     x0, [sp, DTI_X0]
        str     x1, [sp, DTI_Y0]
        str     x2, [sp, DTI_X1]
        str     x3, [sp, DTI_Y1]
        str     x4, [sp, DTI_X2]
        str     x5, [sp, DTI_Y2]



        /* Now vertices are sorted by height, such that y2 <= y1 <= y0 */

        /* Now we draw flat bottom triangle, starting from y0 and ending at y1 */

        sub     x9, x2, x0      // x9 <- x1 - x0
        lsl     x9, x9, 32      // x9 <- x1 - x0        (Q32)
        sub     x10, x3, x1     // x10 <- y1 - y0
        sdiv    x22, x9, x10    // x22 <- (x1 - x0) / (y1 - y0)         (Q32)
        neg     x22, x22        // x22 <- -((x1 - x0) / (y1 - y0))      (Q32)

        sub     x9, x4, x0      // x9 <- x2 - x0
        lsl     x9, x9, 32      // x9 <- x2 - x0        (Q32)
        sub     x10, x5, x1     // x10 <- y2 - y0
        sdiv    x23, x9, x10    // x23 <- (x2 - x0) / (y2 - y0)         (Q32)
        neg     x23, x23        // x23 <- -((x2 - x0) / (y2 - y0))      (Q32)

        /* We need to figure out which line is left line */
        cmp     x22, x23        // Compare slopes
        b.le    draw_triangle__end_find_left
        swap    x22, x23, x9    // x23 is slope of left line, so swap x22 <-> x23
draw_triangle__end_find_left:




        /* Now we draw flat bottom triangle (top triangle) */

        /* Initialize line iterators */
        mov     x19, x1         // x19 <- scanline y
        lsl     x20, x0, 32     // x20 <- left line x   (Q32)
        lsl     x21, x0, 32     // x21 <- right line x  (Q32)

        mov     w26, w6         // w26 <- color
        mov     x27, x7         // x27 <- framebuffer

draw_triangle__next_line:
        /* Start scanline x at left line x */
        mov     x25, ROUNDING_CONSTANT
        add     x24, x20, x25   // x24 <- left line x (Q32)
        lsr     x24, x24, 32    // x24 <- scanline x

        /* Save to x25 last scanline x */
        add     x25, x21, x25   // x25 <- right line x (Q32)
        lsr     x25, x25, 32    // x25 <- right line x (rounded)

draw_triangle__next_pixel:
        mov     x0, x24         // x0 <- line's pixel x
        mov     x1, x19         // x1 <- line y
        mov     x2, x27         // x2 <- framebuffer
        mov     w3, w26         // w3 <- color
        bl      draw_argb_pixel_at

        add     x24, x24, 1     // Advance scanline x
        cmp     x24, x25        // Check if we finished scanline
        b.le    draw_triangle__next_pixel

        /* We finished drawing scanline */

        add     x20, x20, x22   // Move left line x by slope
        add     x21, x21, x23   // Move right line x by slope
        sub     x19, x19, 1     // Move scanline y down
        ldr     x9, [sp, DTI_Y1]        // x9 <- bottom scanline y
        cmp     x19, x9                 // Check if we finished top triangle
        b.gt    draw_triangle__next_line

        /* We finished drawing triangle */

        /* Now we are at y1 (x19 == y1) */

        /* x20 is the x coordinate of the bottom of the left line */
        /* x21 is the x coordinate of the bottom of the right line */

        ldr     x0, [sp, DTI_Y1]        // x0 <- y1 (where we are at)
        ldr     x1, [sp, DTI_X2]        // x1 <- x2 (bottom vertex x)
        lsl     x1, x1, 32              // x1 <- x2 (Q32)
        ldr     x2, [sp, DTI_Y2]        // x2 <- y2 (bottom vertex y)

        // TODO: neg x10 and remove neg x22, neg x23
        sub     x10, x2, x0             // x10 <- y2 - y1

        sub     x22, x1, x20            // x22 <- x2 - left_line_x              (Q32)
        sdiv    x22, x22, x10           // x22 <- (x2 - left_line_x) / (y2 - y1)         (Q32)
        neg     x22, x22                // x22 <- -((x2 - left_line_x) / (y2 - y1))      (Q32)

        sub     x23, x1, x21            // x23 <- x2 - right_line_x             (Q32)
        sdiv    x23, x23, x10           // x23 <- (x2 - right_line_x) / (y2 - y1)         (Q32)
        neg     x23, x23                // x23 <- -((x2 - right_line_x) / (y2 - y1))      (Q32)


        /* Draw bottom triangle */

draw_triangle__next_line_2:
        mov     x25, ROUNDING_CONSTANT
        add     x24, x20, x25   // x24 <- left line x coordinate (Q32)
        lsr     x24, x24, 32    // x24 <- scanline x coordinate (rounded).

        add     x25, x21, x25   // x25 <- right line x coordinate (Q32)
        lsr     x25, x25, 32    // x25 <- right line x coordinate (rounded)

draw_triangle__next_pixel_2:
        mov     x0, x24         // x0 <- line's pixel x
        mov     x1, x19         // x1 <- line y
        mov     x2, x27         // x2 <- framebuffer
        mov     w3, w26         // w3 <- color
        bl      draw_argb_pixel_at


        add     x24, x24, 1     // Advance scanline x
        cmp     x24, x25        // Check if we finished scanline
        b.le    draw_triangle__next_pixel_2

        /* We finished drawing scanline */

        add     x20, x20, x22   // Move left line x by slope
        add     x21, x21, x23   // Move right line x by slope
        sub     x19, x19, 1     // Move scanline y down
        ldr     x9, [sp, DTI_Y2]        // x9 <- last scanline y coordinate
        cmp     x19, x9                 // Check if we finished bottom triangle
        b.ge    draw_triangle__next_line_2

        /* We finished drawing bottom triangle */






        add     sp, sp, STRUCT_DTI_SIZE

        ldp     x26, x27, [sp, 64]
        ldp     x24, x25, [sp, 48]
        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 80
        ret



.endif
