.ifndef TETRIS_CELL_S
TETRIS_CELL_S:

        .include "./constants.s"
        .include "./rectangle.s"
        .include "./line.s"

        /* Change these parameters to select your favorite TETRIS cell size */
        .equ TETRIS_CELL_SIZE,          21   // Original is 21px.
        .equ TETRIS_CELL_BORDER_SIZE,   4    // Original is 4px.

/*
 * Params:
 *      x0: u64                 <- bottom left x position (game coordinates)
 *      x1: u64                 <- bottom left y position (game coordinates)
 *      x2: in Tetromino*       <- tetromino
 *      x3: out u32*            <- framebuffer
 */
draw_tetris_cell:
        stp     lr, x19, [sp, -16]!

        mov     x9, x2          // x9 <- tetromino

        mov     x5, x3          // x5 <- framebuffer
        mov     x0, x0
        mov     x1, x1
        ldr     w2, [x9, TETROMINO_DIFFUSE_COLOR]
        ldr     w3, [x9, TETROMINO_SPECULAR_COLOR]
        ldr     w4, [x9, TETROMINO_AMBIENT_COLOR]
        bl      draw_tetris_cell_by_colors

        ldp     lr, x19, [sp], 16
        ret



/*
 * Params:
 *      x0: u64                 <- bottom left x position (game coordinates)
 *      x1: u64                 <- bottom left y position (game coordinates)
 *      w2: u32                 <- diffuse color
 *      w3: u32                 <- specular color
 *      w4: u32                 <- ambient color
 *      x5: out u32*            <- framebuffer
 */
draw_tetris_cell_by_colors:
        stp     lr, x19, [sp, -64]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]
        stp     x24, x25, [sp, 48]

        /* Save arguments */
        mov     x20, x0         // x20 <- bottom left x
        mov     x21, x1         // x21 <- bottom left y
        mov     w22, w2         // w22 <- diffuse color
        mov     w23, w3         // w23 <- specular color
        mov     w24, w4         // w24 <- ambient color
        mov     x25, x5         // x25 <- framebuffer


        /* Draw border trapezoids */
        mov     x0, x20
        mov     x1, x21
        mov     w2, w23
        mov     w3, w24
        mov     x4, x25
        bl      draw_tetris_cell_trapezoids

        /* Draw inner rectangle */
        add     x0, x20, TETRIS_CELL_BORDER_SIZE        // x0 = inner rectangle bottom left x
        add     x1, x21, TETRIS_CELL_BORDER_SIZE        // x1 = inner rectangle bottom left y

        add     x2, x20, TETRIS_CELL_SIZE - 1
        sub     x2, x2, TETRIS_CELL_BORDER_SIZE         // x2 = inner rectangle top right x

        add     x3, x21, TETRIS_CELL_SIZE - 1
        sub     x3, x3, TETRIS_CELL_BORDER_SIZE         // x3 = inner rectangle top right y

        mov     x4, x25                                 // x4 = framebuffer
        mov     w5, w22                                 // w5 = diffuse color
        bl      draw_filled_rectangle

        /* Draw bottom left diagonal line */
        mov     x0, x20
        mov     x1, x21
        add     x2, x0, TETRIS_CELL_BORDER_SIZE - 1
        add     x3, x1, TETRIS_CELL_BORDER_SIZE - 1
        mov     x4, x25                                 // x4 = framebuffer
        mov     w5, w22                                 // w5 = diffuse color
        bl      draw_line

        /* Draw top right diagonal line */
        add     x0, x20, TETRIS_CELL_SIZE - 1
        add     x1, x21, TETRIS_CELL_SIZE - 1
        sub     x2, x0, TETRIS_CELL_BORDER_SIZE - 1
        sub     x3, x1, TETRIS_CELL_BORDER_SIZE - 1
        mov     x4, x25                                 // x4 = framebuffer
        mov     w5, w22                                 // w5 = diffuse color
        bl      draw_line

        ldp     x24, x25, [sp, 48]
        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 64
        ret



/*
 * Params:
 *      x0: u64                 <- bottom left x position (game coordinates)
 *      x1: u64                 <- bottom left y position (game coordinates)
 *      w2: u32                 <- specular color
 *      w3: u32                 <- ambient color
 *      x4: out u32*            <- framebuffer
 */
draw_tetris_cell_trapezoids:
        stp     lr, x19, [sp, -80]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]
        stp     x24, x25, [sp, 48]
        stp     x26, x27, [sp, 64]

        mov     w22, w2         // const w22 <- specular color
        mov     w23, w3         // const w23 <- specular color


        /* Convert coordinates */
        mov     x9, SCREEN_HEIGH - 1
        sub     x1, x9, x1                      // x1 = bottom left y coordinate (screen coordinates)
        sub     x1, x1, TETRIS_CELL_SIZE - 1    // x1 = top left y coordinate (screen coordiantes)



        /* Initialize framebuffer pointers */
        mov     x24, SCREEN_WIDTH               // x24 = SCREEN_WIDTH
        mul     x24, x24, x1                    // x24 = SCREEN_WIDTH * y = vertical offset
        add     x24, x24, x0                    // x24 = (SCREEN_WIDTH * y) + x = vertical + horizontal offset
        lsl     x24, x24, BYTES_PER_PIXEL_SHIFT // x24 = total offset in bytes

        add     x24, x4, x24                    // x24 = top left of square

        mov     x9, TETRIS_CELL_SIZE - 1        // x9 = size - 1 = space between corners
        mov     x10, SCREEN_WIDTH
        mul     x10, x9, x10                    // x10 = space between corners * screen width = pixels between vertically aligned corners

        lsl     x9, x9, BYTES_PER_PIXEL_SHIFT   // x9 = space in bytes between horizontal corners
        lsl     x10, x10, BYTES_PER_PIXEL_SHIFT // x10 = space in bytes between vertical corners

        add     x25, x24, x10                   // x25 = bottom left of square
        mov     x26, x24                        // x26 = top left of square
        add     x27, x24, x9                    // x27 = top right of square
        /* End initialize framebuffer pointers */

        /*
        * x24 = top trapezoid pointer
        * x25 = bottom trapezoid pointer
        * x26 = left trapezoid pointer
        * x27 = right trapezoid pointer
        */

        mov     x20, 0                          // x iterator
        mov     x21, 0                          // y iterator
        mov     x15, TETRIS_CELL_SIZE           // x15 = current row size

draw_tetris_cell_trapezoids__next_row:
        cmp     x21, TETRIS_CELL_BORDER_SIZE
        b.ge    draw_tetris_cell_trapezoids__end

draw_tetris_cell_trapezoids__next_col:
        cmp     x20, x15                        // check if we are at the end of the row
        b.ge    draw_tetris_cell_trapezoids__end_row

        /* Draw pixels */
        str     w22, [x24]
        str     w23, [x25]
        str     w22, [x26]
        str     w23, [x27]

        /* Advance pointers */
        // Advance horizontally
        add     x24, x24, BYTES_PER_PIXEL
        add     x25, x25, BYTES_PER_PIXEL
        // Advance vertically
        mov     x9, SCREEN_WIDTH
        lsl     x9, x9, BYTES_PER_PIXEL_SHIFT
        add     x26, x26, x9
        add     x27, x27, x9

        add     x20, x20, 1     // Increment x iterator
        b       draw_tetris_cell_trapezoids__next_col


draw_tetris_cell_trapezoids__end_row:

        /* Advance pointers for horizontal trapezoids */
        // We need to move the pointers that are currently at the end of a row,
        // to the beginning of the next row (above or below), offseted by one pixel to the right
        neg     x10, x15
        add     x10, x10, 1
        lsl     x10, x10, BYTES_PER_PIXEL_SHIFT

        mov     x11, SCREEN_WIDTH
        lsl     x11, x11, BYTES_PER_PIXEL_SHIFT

        add     x9, x10, x11
        add     x24, x24, x9

        sub     x9, x10, x11
        add     x25, x25, x9


        /* Advance pointers to vertical trapezoids */
        // We need to move the pointers that are currently at the bottom of a column,
        // to the beginning of the next column (left or right), offseted by one row down
        mov     x10, SCREEN_WIDTH
        mul     x10, x10, x15
        neg     x10, x10
        add     x10, x10, SCREEN_WIDTH
        lsl     x10, x10, BYTES_PER_PIXEL_SHIFT
        // x10 now moves a pointer to the second element of the current column (which has the same height as the first element of the next column)

        add     x9, x10, BYTES_PER_PIXEL        // x9 now moves to the beginning of the column on the right
        add     x26, x26, x9

        sub     x9, x10, BYTES_PER_PIXEL        // x9 now moves to the beginning of the column on the left
        add     x27, x27, x9


        sub     x15, x15, 2             // Row size is decremented by 2
        mov     x20, 0                  // Reset x
        add     x21, x21, 1             // Increment y
        b       draw_tetris_cell_trapezoids__next_row


draw_tetris_cell_trapezoids__end:
        ldp     x26, x27, [sp, 64]
        ldp     x24, x25, [sp, 48]
        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 80
        ret


.endif
