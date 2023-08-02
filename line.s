.ifndef LINE_S
LINE_S:

        .include "./constants.s"
        .include "./pixel.s"
        .include "./fixed_point.s"

/* struct LineIter */
        .equ LINEI_REMAINING,           0                       // u64
        .equ LINEI_X_COORD,             LINEI_REMAINING + 8     // u64 (Q32)
        .equ LINEI_Y_COORD,             LINEI_X_COORD + 8       // u64 (Q32)
        .equ LINEI_X_STEP,              LINEI_Y_COORD + 8       // u64 (Q32)
        .equ LINEI_Y_STEP,              LINEI_X_STEP + 8        // u64 (Q32)

        .equ STRUCT_LINE_ITER_SIZE,     LINEI_Y_STEP + 8




/*
 * Params:
 *      x0: u64         <- x coordinate           (left) 0 <= x < SCREEN_WIDTH (right)
 *      x1: u64         <- y coordinate         (bottom) 0 <= y < SCREEN_HEIGHT (top)
 *      x2: u64         <- length > 0
 *      w3: u32         <- argb color
 *      x4: out u32*    <- beginning of framebuffer
 * Comments:
 *      Draws a line from (x0, x1) to (x0 + x2, x1)
 */
draw_horizontal_line:
        stp     lr, x19, [sp, -16]!

        mov     x5, x4
        mov     w4, w3
        mov     x3, x2
        mov     x2, BYTES_PER_PIXEL
        bl      draw_line_by_offset

        ldp     lr, x19, [sp], 16
        ret


/*
 * Params:
 *      x0: u64         <- x coordinate           (left) 0 <= x < SCREEN_WIDTH (right)
 *      x1: u64         <- y coordinate         (bottom) 0 <= y < SCREEN_HEIGHT (top)
 *      x2: u64         <- length > 0
 *      w3: u32         <- argb color
 *      x4: out u32*    <- beginning of framebuffer
 * Comments:
 *      Draws a line from (x0, x1) to (x0, x1 + x2)
 */
draw_vertical_line:
        stp     lr, x19, [sp, -16]!

        mov     x5, x4
        mov     w4, w3
        mov     x3, x2
        mov     x2, SCREEN_WIDTH
        lsl     x2, x2, BYTES_PER_PIXEL_SHIFT
        sub     x2, xzr, x2
        bl      draw_line_by_offset

        ldp     lr, x19, [sp], 16
        ret


/*
 * Params:
 *      x0: u64         <- x coordinate           (left) 0 <= x < SCREEN_WIDTH (right)
 *      x1: u64         <- y coordinate         (bottom) 0 <= y < SCREEN_HEIGHT (top)
 *      x2: u64         <- offset in bytes
 *      x3: u64         <- steps > 0
 *      w4: u32         <- argb color
 *      x5: out u32*    <- beginning of framebuffer
 * Comments:
 *      Draws a line from (x0, x1) to (x0 + x2, x1)
 */
draw_line_by_offset:
        stp     lr, x19, [sp, -64]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]
        stp     x24, x25, [sp, 48]

        mov     x20, x0         // x20 <- x coordinate
        mov     x21, x1         // x21 <- y coordinate
        mov     x22, x2         // x22 <- offset in bytes
        mov     x23, x3         // x23 <- steps > 0
        mov     w24, w4         // x24 <- argb color
        mov     x25, x5         // x25 <- beginning of framebuffer


        // Convert game y coordinates to screen y coordinates
        mov     x9, (SCREEN_HEIGH - 1)
        sub     x21, x9, x21

        mov     x9, SCREEN_WIDTH              // x9 = screen width
        mul     x9, x9, x21                   // x9 = initial vertical offset
        add     x9, x9, x20                   // x9 = initial vertical offset + initial horizontal offset
        lsl     x9, x9, BYTES_PER_PIXEL_SHIFT // x9 = total offset
        add     x25, x25, x9                  // x25 = &framebuffer['first pixel of line']


draw_line_by_offset__next_pixel:
        mov     w0, w24
        mov     x1, x25
        bl      draw_argb_pixel                         // Color pixel

        add     x25, x25, x22                           // Advance to next pixel by offset parameter
        subs    x23, x23, 1                             // Decrement remaining steps
        b.gt    draw_line_by_offset__next_pixel         // Loop only if line has not been completed

        ldp     x24, x25, [sp, 48]
        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 64
        ret


/*
 * Params:
 *      x0: first point x coordinate        (left) 0 <= x < SCREEN_WIDTH (right)
 *      x1: first point y coordinate      (bottom) 0 <= y < SCREEN_HEIGHT (top)
 *      x2: second point x coordinate       (left) 0 <= x < SCREEN_WIDTH (right)
 *      x3: second point y coordinate     (bottom) 0 <= y < SCREEN_HEIGHT (top)
 *      x4: beginning of framebuffer
 *      w5: color
 */
draw_line:
        stp     lr, x19, [sp, -32]!
        stp     x20, x21, [sp, 16]

        // TODO: implement hor. line and ver. line subroutines?

        // Convert game y coordinates to screen y coordinates
        mov     x19, (SCREEN_HEIGH - 1)
        sub     x1, x19, x1
        sub     x3, x19, x3


        subs    x19, x2, x0                     // x19 = dx = x1 - x0
        b.ge    draw_line__end_abs_dx
        sub     x19, xzr, x19                   // dx = -dx
draw_line__end_abs_dx:
        /* x19 = |x1 - x0| = |dx| */


        subs    x20, x3, x1                     // x20 = dy = y1 - y0
        b.ge    draw_line__end_abs_dy
        sub     x20, xzr, x20                   // dy = -dy
draw_line__end_abs_dy:
        /* x20 = |y1 - y0| = |dy| */


        cmp     x20, x19                  // (|y1 - y0| < |x1 - x0|)?  (is line low slope?)
        b.le    draw_line__case_low_slope
        b.gt    draw_line__case_high_slope



draw_line__case_low_slope:
        cmp     x0, x2          // x0 <= x1 ?
        b.gt    draw_line__case_low_slope_invert

        bl      draw_line_low_slope
        b       draw_line__end

draw_line__case_low_slope_invert:
        mov     x19, x0
        mov     x0, x2
        mov     x2, x19
        mov     x19, x1
        mov     x1, x3
        mov     x3, x19
        bl      draw_line_low_slope
        b       draw_line__end



draw_line__case_high_slope:
        cmp     x1, x3          // y0 <= y1 ?
        b.gt    draw_line__case_high_slope_invert

        bl      draw_line_high_slope
        b       draw_line__end

draw_line__case_high_slope_invert:
        mov     x19, x0
        mov     x0, x2
        mov     x2, x19
        mov     x19, x1
        mov     x1, x3
        mov     x3, x19
        bl      draw_line_high_slope
        b       draw_line__end


draw_line__end:
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 32
        ret


/*
 * Params:
 *      x0: left point x coordinate          (left) 0 <= x < SCREEN_WIDTH (right)
 *      x1: left point y coordinate           (top) 0 <= y < SCREEN_HEIGHT (bottom)
 *      x2: right point x coordinate         (left) 0 <= x < SCREEN_WIDTH (right)
 *      x3: right point y coordinate          (top) 0 <= y < SCREEN_HEIGHT (bottom)
 *      x4: beginning of framebuffer
 *      w5: color
 */
draw_line_low_slope:
        stp     lr, x19, [sp, -80]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]
        stp     x24, x25, [sp, 48]
        stp     x26, x27, [sp, 64]


        mov     x19, SCREEN_WIDTH               // x19 = screen width
        mul     x19, x19, x1                    // x19 = initial vertical offset
        add     x19, x19, x0                    // x19 = initial vertical offset + initial horizontal offset
        lsl     x19, x19, BYTES_PER_PIXEL_SHIFT // x19 = total offset
        add     x4, x4, x19                     // x4 = &framebuffer['line's leftmost pixel']



        sub     x19, x2, x0                     // x19 = dx = x1 - x0
        sub     x20, x3, x1                     // x20 = dy = y1 - y0
        mov     x22, 1                          // x22 = yi = 1 (assume dy >= 0)
        mov     x23, SCREEN_WIDTH
        lsl     x23, x23, BYTES_PER_PIXEL_SHIFT // x23 = "fi" = offset in bytes between two consecutive rows


        cmp     x20, 0                          // dy < 0 ?
        b.ge    draw_line_low_slope__nneg_dy    // continue if dy >= 0
        sub     x20, xzr, x20                   // dy = -dy
        sub     x22, xzr, x22                   // yi = -yi TODO: remove? (unused)
        sub     x23, xzr, x23                   // fi = -fi
draw_line_low_slope__nneg_dy:


        lsl     x21, x20, 1     // x21 = 2*dy
        sub     x21, x21, x19   // x21 = 2*dy - dx = D

        lsl     x24, x19, 1      // x24 = 2*dx
        lsl     x25, x20, 1      // x25 = 2*dy

        mov     x26, x0         // x26 = x
        mov     x27, x1         // x27 = y (unused)


draw_line_low_slope__next_col:
        str     w5, [x4]                        // Paint pixel at (x,y)
        add     x4, x4, BYTES_PER_PIXEL         // Move framebuffer one pixel right

        cmp     x21, 0                          // D > 0 ?
        b.le    draw_line_low_slope__keep_y     // if D <= 0 then stay in the same row
        add     x27, x27, x22                   // y = y + yi
        sub     x21, x21, x24                   // D = D - 2*dx
        add     x4, x4, x23                     // f = f + fi   move framebuffer by fi (+/- one row)
draw_line_low_slope__keep_y:

        add     x21, x21, x25           // D = D + 2*dy
        add     x26, x26, 1             // x = x + 1
        // Check if we finished drawing line
        cmp     x26, x2                 // x <= x1?
        b.le    draw_line_low_slope__next_col



        ldp     x26, x27, [sp, 64]
        ldp     x24, x25, [sp, 48]
        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 80
        ret


/*
 * Params:
 *      x0: top point screen x coordinate           (left) 0 <= x < SCREEN_WIDTH (right)
 *      x1: top point screen y coordinate            (top) 0 <= y < SCREEN_HEIGHT (bottom)
 *      x2: bottom point screen x coordinate        (left) 0 <= x < SCREEN_WIDTH (right)
 *      x3: bottom point screen y coordinate         (top) 0 <= y < SCREEN_HEIGHT (bottom)
 *      x4: beginning of framebuffer
 *      w5: color
 */
draw_line_high_slope:
        stp     lr, x19, [sp, -80]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]
        stp     x24, x25, [sp, 48]
        stp     x26, x27, [sp, 64]

        mov     x19, SCREEN_WIDTH               // x19 = screen width
        mul     x19, x19, x1                    // x19 = initial vertical offset
        add     x19, x19, x0                    // x19 = initial vertical offset + initial horizontal offset
        lsl     x19, x19, BYTES_PER_PIXEL_SHIFT // x19 = total offset
        add     x4, x4, x19                     // x4 = &framebuffer['line's topmost pixel']



        sub     x19, x2, x0                     // x19 = dx = x1 - x0
        sub     x20, x3, x1                     // x20 = dy = y1 - y0
        mov     x22, 1                          // x22 = xi = 1 (assume dx >= 0)
        mov     x23, BYTES_PER_PIXEL            // x23 = "fi" = how much to move framebuffer when moving to the next column


        cmp     x19, 0                          // dx < 0 ?
        b.ge    draw_line_high_slope__nneg_dx   // continue if dx >= 0
        sub     x19, xzr, x19                   // dx = -dx
        sub     x22, xzr, x22                   // xi = -xi TODO: remove? (unused)
        sub     x23, xzr, x23                   // fi = -fi
draw_line_high_slope__nneg_dx:


        lsl     x21, x19, 1     // x21 = 2*dx
        sub     x21, x21, x20   // x21 = 2*dx - dy = D

        lsl     x24, x19, 1      // x24 = 2*dx
        lsl     x25, x20, 1      // x25 = 2*dy

        mov     x27, x1         // x27 = y = y0
        mov     x26, x0         // x26 = x = x0 (unused)


draw_line_high_slope__next_row:
        str     w5, [x4]                        // Paint pixel at (x,y)
        add     x4, x4, BYTES_PER_SCREEN_ROW    // Move framebuffer one row down

        cmp     x21, 0                          // D > 0 ?
        b.le    draw_line_high_slope__keep_x    // if D <= 0 then stay in the same column
        add     x26, x26, x22                   // x = x + xi
        sub     x21, x21, x25                   // D = D - 2*dy
        add     x4, x4, x23                     // f = f + fi   move framebuffer by fi (+/- one column)
draw_line_high_slope__keep_x:

        add     x21, x21, x24           // D = D + 2*dx
        add     x27, x27, 1             // y = y + 1
        // Check if we finished drawing line
        cmp     x27, x3                 // y <= y1 ?
        b.le    draw_line_high_slope__next_row



        ldp     x26, x27, [sp, 64]
        ldp     x24, x25, [sp, 48]
        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 80
        ret




/*
 * Params:
 *      x0: u64         <- first point x coordinate
 *      x1: u64         <- first point y coordinate
 *      x2: u64         <- second point x coordinate
 *      x3: u64         <- second point y coordinate
 *      w4: u32         <- argb color
 *      x5: out u32*    <- framebuffer beginning
 */
draw_line_fixedp:
        stp     lr, x19, [sp, -64]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]
        stp     x24, x25, [sp, 48]

        /*
         * x19 <- remaining pixels
         * x20 <- x coordinate (x0)
         * x21 <- y coordinate (y0)
         * x22 <- x step (x1)
         * x23 <- y step (y1)
         * x24 <- rounding constant
         */

        sub     x10, x2, x0     // x10 = x1 - x0 = dx
        sub     x11, x3, x1     // x11 = y1 - y0 = dy

        cmp     x10, 0
        cneg    x12, x10, lt    // x12 = |x1 - x0| = |dx|

        cmp     x11, 0
        cneg    x13, x11, lt    // x13 = |y1 - y0| = |dy|



        cmp     x12, x13                        // cmp(|dx|, |dy|)

        /* Compute remaining pixels */
        csel    x19, x12, x13, ge       // x19 = (|dx| >= |dy|) ? |dx| : |dy|

        /* TODO: handle dx == 0 && dy == 0 (x0 == x1 && y0 == y1) */
        b.ge    draw_line_fixedp__low_slope     // |dx| >= |dy|
        b.lt    draw_line_fixedp__high_slope    // |dx| < |dy|



        /* |dx| >= |dy| */
draw_line_fixedp__low_slope:
        /* compute x step */
        mov     x22, 1          // x22 <- x step
        cmp     x10, 0
        cneg    x22, x22, lt    // x22 = dx < 0 ? -1 : 1
        lsl     x22, x22, 32    // Convert x step to     Q32

        /* compute y step */
        lsl     x23, x11, 32    // x23 = dy             (Q32)
        sdiv    x23, x23, x12   // x23 = dy / |dx|      (Q32)

        b       draw_line_fixedp__end_slope
/* end low slope */


        /* |dx| < |dy| */
draw_line_fixedp__high_slope:
        /* compute x step */
        lsl     x22, x10, 32    // x22 = dx             (Q32)
        sdiv    x22, x22, x13   // x22 = dx / |dy|      (Q32)

        /* compute y step */
        mov     x23, 1          // x23 <- y step
        cmp     x11, 0
        cneg    x23, x23, lt    // x23 = dy < 0 ? -1 : 1
        lsl     x23, x23, 32    // Convert y step to     Q32

        b       draw_line_fixedp__end_slope
/* end high slope */


draw_line_fixedp__end_slope:



        lsl     x20, x0, 32     // x20 <- x coordinate (Q32)
        lsl     x21, x1, 32     // x21 <- y coordinate (Q32)

        mov     x24, 1
        lsl     x24, x24, 31    // x24 <- rounding constant

draw_line_fixedp__next_pixel:
        /* round x */
        add     x0, x20, x24    // x0 <- x + "0.5"
        lsr     x0, x0, 32      // x0 <- round(x)

        /* round y */
        add     x1, x21, x24    // x1 <- y + "0.5"
        lsr     x1, x1, 32      // x1 <- round(y)

        mov     x2, x5          // x2 <- framebuffer
        mov     w3, w4          // w3 <- color

        bl      draw_argb_pixel_at



        add     x20, x20, x22   // Step x coordinate by x step
        add     x21, x21, x23   // Step y coordinate by y step
        subs    x19, x19, 1     // Decrement remaining pixels
        b.ge    draw_line_fixedp__next_pixel



        ldp     x24, x25, [sp, 48]
        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 64
        ret





/*
 * Params:
 *      x0: u64                         <- first point x coordinate
 *      x1: u64                         <- first point y coordinate
 *      x2: u64                         <- second point x coordinate
 *      x3: u64                         <- second point y coordinate
 *      x4: out struct LineIter*        <- line iterator
 */
line_iter_init:
        stp     lr, x19, [sp, -48]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]

        /*
         * x19 <- remaining pixels
         * x20 <- x coordinate (x0)
         * x21 <- y coordinate (y0)
         * x22 <- x step (x1)
         * x23 <- y step (y1)
         */

        sub     x10, x2, x0     // x10 = x1 - x0 = dx
        sub     x11, x3, x1     // x11 = y1 - y0 = dy

        cmp     x10, 0
        cneg    x12, x10, lt    // x12 = |x1 - x0| = |dx|

        cmp     x11, 0
        cneg    x13, x11, lt    // x13 = |y1 - y0| = |dy|



        cmp     x12, x13                        // cmp(|dx|, |dy|)

        /* Compute remaining pixels */
        csel    x19, x12, x13, ge       // x19 = (|dx| >= |dy|) ? |dx| : |dy|
        add     x19, x19, 1

        /* TODO: handle dx == 0 && dy == 0 (x0 == x1 && y0 == y1) */
        b.ge    line_iter_init__low_slope     // |dx| >= |dy|
        b.lt    line_iter_init__high_slope    // |dx| < |dy|



        /* |dx| >= |dy| */
line_iter_init__low_slope:
        /* compute x step */
        mov     x22, 1          // x22 <- x step
        cmp     x10, 0
        cneg    x22, x22, lt    // x22 = dx < 0 ? -1 : 1
        lsl     x22, x22, 32    // Convert x step to     Q32

        /* compute y step */
        lsl     x23, x11, 32    // x23 = dy             (Q32)
        sdiv    x23, x23, x12   // x23 = dy / |dx|      (Q32)

        b       line_iter_init__end_slope
/* end low slope */


        /* |dx| < |dy| */
line_iter_init__high_slope:
        /* compute x step */
        lsl     x22, x10, 32    // x22 = dx             (Q32)
        sdiv    x22, x22, x13   // x22 = dx / |dy|      (Q32)

        /* compute y step */
        mov     x23, 1          // x23 <- y step
        cmp     x11, 0
        cneg    x23, x23, lt    // x23 = dy < 0 ? -1 : 1
        lsl     x23, x23, 32    // Convert y step to     Q32

        b       line_iter_init__end_slope
/* end high slope */


line_iter_init__end_slope:



        lsl     x20, x0, 32     // x20 <- x coordinate (Q32)
        lsl     x21, x1, 32     // x21 <- y coordinate (Q32)

        str     x19, [x4, LINEI_REMAINING]
        str     x20, [x4, LINEI_X_COORD]
        str     x21, [x4, LINEI_Y_COORD]
        str     x22, [x4, LINEI_X_STEP]
        str     x23, [x4, LINEI_Y_STEP]

        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 48
        ret






/*
 * Params:
 *      x0: in/out struct LineIter*     <- line iterator
 * Returns:
 *      x0: u64                         <- x coordinate
 *      x1: u64                         <- y coordinate
 *      x2: u64                         <- remaining pixels
 */
line_iter_next:
        stp     lr, x19, [sp, -32]!
        stp     x20, x21, [sp, 16]

        mov     x20, x0                 // x20 <- struct LineIter*
        mov     x19, ROUNDING_CONSTANT  // x19 <- rounding constant


        /* round x and step */
        ldr     x9, [x20, LINEI_X_COORD]        // x9 <- x coord
        ldr     x10, [x20, LINEI_X_STEP]        // x10 <- x step

        add     x0, x9, x19     // x0 <- x + "0.5"
        lsr     x0, x0, 32      // x0 <- round(x)

        add     x9, x9, x10     // Step x coordinate by x step
        str     x9, [x20, LINEI_X_COORD]


        /* round y and step */
        ldr     x9, [x20, LINEI_Y_COORD]        // x9 <- y coord
        ldr     x10, [x20, LINEI_Y_STEP]        // x10 <- y step

        add     x1, x9, x19     // x1 <- y + "0.5"
        lsr     x1, x1, 32      // x1 <- round(y)

        add     x9, x9, x10     // Step y coordinate by y step
        str     x9, [x20, LINEI_Y_COORD]


        /* decrement remaining pixels */
        ldr     x2, [x20, LINEI_REMAINING]        // x2 <- remaining pixels
        sub     x2, x2, 1                         // Decrement remaining pixels
        str     x2, [x20, LINEI_REMAINING]


        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 32
        ret





/*
 * Params:
 *      x0: u64         <- first point x coordinate
 *      x1: u64         <- first point y coordinate
 *      x2: u64         <- second point x coordinate
 *      x3: u64         <- second point y coordinate
 *      w4: u32         <- argb color
 *      x5: out u32*    <- framebuffer beginning
 */
draw_line_with_iter:
        stp     lr, x19, [sp, -64]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]
        stp     x24, x25, [sp, 48]

        mov     w19, w4         // w19 <- color
        mov     x20, x5         // x20 <- framebuffer

        sub     sp, sp, STRUCT_LINE_ITER_SIZE

        mov     x4, sp
        bl      line_iter_init


draw_line_with_iter__next_pixel:
        mov     x0, sp
        bl      line_iter_next
        /*
         *      x0 <- x coordinate
         *      x1 <- y coordinate
         *      x2 <- remaining pixels
         */

        mov     x21, x2         // Save remaining pixels

        mov     x2, x20          // x2 <- framebuffer
        mov     w3, w19          // w3 <- color
        bl      draw_argb_pixel_at

        cmp     x21, 0
        b.gt    draw_line_with_iter__next_pixel



        add     sp, sp, STRUCT_LINE_ITER_SIZE

        ldp     x24, x25, [sp, 48]
        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 64
        ret




.endif
