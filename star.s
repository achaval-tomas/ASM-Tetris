.ifndef STAR_S
STAR_S:

        .include "./constants.s"
        .include "./line.s"
        .include "./pixel.s"

/*
 * Params:
 *      x0: u64         <- x position
 *      x1: u64         <- y position
 *      x2: u64         <- size => final size = isOdd(size) ? size : size - 1
 *      w3: u32         <- argb color
 *      x4: out u32*    <- framebuffer
 */
draw_four_point_star:
        stp     lr, x19, [sp, -80]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]
        stp     x24, x25, [sp, 48]
        stp     x26, x27, [sp, 64]

        stp     x0, x1, [sp, -16]!      // Save x0 and x1 in stack for later use

        /* Normalize size (subtract 1 if size is even) */
        and     x9, x2, 0b1
        eor     x9, x9, 0b1
        sub     x2, x2, x9

        /* Early return if size <= 0 */
        cmp     x2, 0
        b.le    draw_four_point_star__end
        /* size >= 1 */

        sub     x19, x2, 1      // x19 = size - 1
        lsr     x19, x19, 1     // x19 = (size - 1) / 2

        sub     x22, x0, x19    // x22 = x - ((size - 1) / 2) = x position of circle center
        sub     x23, x1, x19    // x23 = y - ((size - 1) / 2) = y position of circle center

        /* Initialize framebuffer pointers */
        mov     x24, SCREEN_WIDTH               // x24 = SCREEN_WIDTH
        mul     x24, x24, x23                   // x24 = SCREEN_WIDTH * circle y = vertical offset
        add     x24, x24, x22                   // x24 = (SCREEN_WIDTH * circle y) + circle x = vertical + horizontal offset
        lsl     x24, x24, BYTES_PER_PIXEL_SHIFT // x24 = total offset in bytes
        add     x24, x4, x24                    // x24 = top left of second quadrant

        sub     x9, x2, 1                       // x9 = size - 1 = space between corners
        mov     x10, SCREEN_WIDTH
        mul     x10, x9, x10                    // x10 = space between corners * screen width = pixels between vertically aligned corners

        lsl     x9, x9, BYTES_PER_PIXEL_SHIFT   // x9 = space in bytes between horizontal corners
        lsl     x10, x10, BYTES_PER_PIXEL_SHIFT // x10 = space in bytes between vertical corners

        add     x25, x24, x9                    // x25 = top right of first quadrant
        add     x26, x24, x10                   // x26 = bottom left of third quadrant
        add     x27, x26, x9                    // x27 = bottom right of fourth quadrant
        /* End initialize framebuffer pointers */


        mov     x20, 0          // Quadrant x
        mov     x21, 0          // Quadrant y

        sub     x15, x19, 1     // x15 = r       (x19 is r + 1)
        mul     x15, x15, x19   // x15 = r * (r + 1)

draw_four_point_star__next_row:
        cmp     x21, x19
        b.ge    draw_four_point_star__end_of_quadrant

draw_four_point_star__next_col:
        cmp     x20, x19
        b.ge    draw_four_point_star__end_of_row

        mul     x10, x20, x20   // x10 = x^2
        mul     x11, x21, x21   // x11 = y^2
        add     x10, x10, x11   // x10 = x^2 + y^2

        cmp     x10, x15        // x^2 + y^2 > r*(r + 1) ?
        b.le    draw_four_point_star__inside_circle

        /* Draw in all 4 quadrants */
        /* TODO: check bounds for each str */
        mov     w0, w3
        mov     x1, x24
        bl      draw_argb_pixel
        mov     w0, w3
        mov     x1, x25
        bl      draw_argb_pixel
        mov     w0, w3
        mov     x1, x26
        bl      draw_argb_pixel
        mov     w0, w3
        mov     x1, x27
        bl      draw_argb_pixel

draw_four_point_star__inside_circle:
        mov     x9, SCREEN_WIDTH
        lsl     x9, x9, BYTES_PER_PIXEL_SHIFT

        add     x24, x24, BYTES_PER_PIXEL
        sub     x25, x25, BYTES_PER_PIXEL
        add     x26, x26, BYTES_PER_PIXEL
        sub     x27, x27, BYTES_PER_PIXEL

        add     x20, x20, 1
        b       draw_four_point_star__next_col


draw_four_point_star__end_of_row:
        mov     x20, 0
        add     x21, x21, 1

        lsl     x9, x19, BYTES_PER_PIXEL_SHIFT          // x9 = bytes of any row of one quadrant

        mov     x10, SCREEN_WIDTH
        lsl     x10, x10, BYTES_PER_PIXEL_SHIFT         // x10 = bytes between two rows of one quadrant

        sub     x24, x24, x9            // Make x24 point to beginning of current row
        add     x24, x24, x10           // Make x24 point to beginning of next row

        add     x25, x25, x9
        add     x25, x25, x10

        sub     x26, x26, x9
        sub     x26, x26, x10

        add     x27, x27, x9
        sub     x27, x27, x10

        b       draw_four_point_star__next_row


draw_four_point_star__end_of_quadrant:

        ldp     x0, x1, [sp], 16        // Restore x0 and x1 from stack

        /* Save arguments */
        mov     x20, x0         // x20 = center x coordinate
        mov     x9, SCREEN_HEIGH - 1
        sub     x21, x9, x1     // x21 = center y coordinate (in game coordinates)
        mov     x22, x2         // x22 = size
        mov     w23, w3         // w23 = color
        mov     x24, x4         // x24 = framebuffer


        /* Draw center horizontal line */
        sub     x0, x20, x19
        mov     x1, x21
        mov     x2, x22
        mov     w3, w23
        mov     x4, x24
        bl      draw_horizontal_line


        /* Draw center bottom vertical line */
        mov     x0, x20
        sub     x1, x21, x19
        lsr     x2, x22, 1
        mov     w3, w23
        mov     x4, x24
        bl      draw_vertical_line

        /* Draw center top vertical line */
        mov     x0, x20
        add     x1, x21, 1
        lsr     x2, x22, 1
        mov     w3, w23
        mov     x4, x24
        bl      draw_vertical_line


draw_four_point_star__end:
        ldp     x26, x27, [sp, 64]
        ldp     x24, x25, [sp, 48]
        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 80
        ret

.endif
