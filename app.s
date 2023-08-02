        .include "./constants.s"
        .include "./time.s"
        .include "./pixel.s"
        .include "./star.s"
        .include "./line.s"
        .include "./rectangle.s"
        .include "./tetris_cell.s"
        .include "./particle.s"
        .include "./util.s"
        .include "./rand.s"
        .include "./background.s"


        /* Choose a different BOARD_WIDTH and/or BOARD_HEIGHT to play tetris of any size! */
        .equ BOARD_WIDTH,               10  // Original is 10, minimum 4.
        .equ BOARD_HEIGHT,              20  // Original is 20, minimum 4.

        .equ BOARD_SIZE,                BOARD_WIDTH * BOARD_HEIGHT
        .equ BOARD_SIZE_IN_BYTES,       BOARD_SIZE * 1

        .equ TETROMINO_ID_BIAS,         1

        .equ TEST_BINARY_TO_DECIMAL_MAX,        10000

        .equ TICKS_PER_SECOND,          60
        .equ MS_PER_TICK,               1000 / TICKS_PER_SECOND         // unused
        .equ US_PER_TICK,               1000000 / TICKS_PER_SECOND

        .equ MOVEMENT_PER_STEP,         16

        .equ MS_PER_DROP,               400
        .equ US_PER_AUTO_DROP,          MS_PER_DROP * 1000

        .equ DESTROY_PARTICLE_RADIUS,	10
        .equ DESTROY_PARTICLE_COLOR,    0xFFFF0000

        .equ BACK_BUFFER_ADDRESS,       0x1000000

        .equ GPIO_BASE,                 0x3f200000
        .equ GPIO_GPFSEL0,              0x00
        .equ GPIO_GPLEV0,               0x34
        .equ GPIO_W,                    0b000010        // (GPIO_1)
        .equ GPIO_A,                    0b000100        // (GPIO_2)
        .equ GPIO_S,                    0b001000        // (GPIO_3)
        .equ GPIO_D,                    0b010000        // (GPIO_4)
        .equ GPIO_SPACE,                0b100000        // (GPIO_5)
        .equ MS_PER_STEP,               250
        .equ US_PER_STEP,               MS_PER_STEP * 1000


        /* Bit flags used for drawing digits. */
        .equ DIGIT_SEGMENT_0,           1 << 0
        .equ DIGIT_SEGMENT_1,           1 << 1
        .equ DIGIT_SEGMENT_2,           1 << 2
        .equ DIGIT_SEGMENT_3,           1 << 3
        .equ DIGIT_SEGMENT_4,           1 << 4
        .equ DIGIT_SEGMENT_5,           1 << 5
        .equ DIGIT_SEGMENT_6,           1 << 6


        .equ BACKGROUND_COLOR,          0xFF000000


        BG_COLORS: .word 0x00FF0000, 0x00FFFF00, 0x0000FF00, 0x0000FFFF, 0x000000FF, 0x001E1E1E, 0x00000000
        BG_COLOR: .dword 0xFFFFFFFF
        PLAYER_COLOR: .dword 0xFFFFFFFF

        .globl main

/* enum CollisionResult */
        .equ COLLISION_RESULT_NO_COLLISION,     0b00
        .equ COLLISION_RESULT_OUT_OF_BOUNDS,    0b01
        .equ COLLISION_RESULT_EXISTING_BLOCK,   0b10

/* struct GameState */
        .equ LAST_TICK,                 0                                               // u32
        .equ LAST_DROP,                 LAST_TICK + 4                                   // u32
        .equ TICK_COUNTER,              LAST_DROP + 4                                   // u64
        .equ GAME_STATS,                TICK_COUNTER + 8                                // struct GameStats
        .equ INPUT_STATE,               GAME_STATS + STRUCT_GS_SIZE                     // struct InputState
        .equ TETROMINO_STATE,           INPUT_STATE + STRUCT_INPUT_STATE_SIZE           // struct TetrominoState
        .equ CHOOSER_BAG_STATE,         TETROMINO_STATE + STRUCT_TSTATE_SIZE            // struct ChooserBagState
        .equ BOARD_STATE,               CHOOSER_BAG_STATE + STRUCT_CBAG_STATE_SIZE      // struct BoardState
        .equ PARTICLE_MANAGER,          BOARD_STATE + STRUCT_BSTATE_SIZE                // struct ParticleManager

        .equ STRUCT_GAME_STATE_SIZE,    PARTICLE_MANAGER + STRUCT_PM_SIZE

/* struct GameStats */
        .equ GS_SCORE,                  0                       // u64
        .equ GS_COMPLETED_ROWS,         GS_SCORE + 8            // u64

        .equ STRUCT_GS_SIZE,            GS_COMPLETED_ROWS + 8

/* struct InputState */
        .equ PRESSED_STATE,             0                       // u32
        .equ ON_PRESS_STATE,            PRESSED_STATE + 4       // u32

        .equ STRUCT_INPUT_STATE_SIZE,   ON_PRESS_STATE + 4

/* struct TetrominoState */
        .equ TSTATE_ID,                 0                       // u64
        .equ TSTATE_ROT,                TSTATE_ID + 8           // u64
        .equ TSTATE_POS_X,              TSTATE_ROT + 8          // i64
        .equ TSTATE_POS_Y,              TSTATE_POS_X + 8        // i64

        .equ STRUCT_TSTATE_SIZE,        TSTATE_POS_Y + 8

/* struct ChooserBagState */
        .equ CBAG_REMAINING,            0                       // u8
        .equ CBAG_VALUES,               CBAG_REMAINING + 1      // u8[7] = u8[NUM_TETROMINOS]

        .equ STRUCT_CBAG_STATE_SIZE,    CBAG_VALUES + (NUM_TETROMINOS * 1)

/* struct BoardState */
        .equ BSTATE_BOARD,              0                                       // u8[22][10] = u8[BOARD_HEIGHT][BOARD_WIDTH]
        .equ BSTATE_DESTROYED_ROWS,	BSTATE_BOARD + BOARD_SIZE_IN_BYTES	// u8[4]

        .equ STRUCT_BSTATE_SIZE,        BSTATE_DESTROYED_ROWS + 4



/* struct DrawNumberInfo */
        .equ DNI_POS_X,                 0                       // u64
        .equ DNI_POS_Y,                 DNI_POS_X + 8           // u64
        .equ DNI_VALUE,                 DNI_POS_Y + 8           // i64
        .equ DNI_MAX_DIGITS,            DNI_VALUE + 8           // u64
        .equ DNI_DIGIT_WIDTH,           DNI_MAX_DIGITS + 8      // u64
        .equ DNI_DIGIT_THICKNESS,       DNI_DIGIT_WIDTH + 8     // u64
        .equ DNI_DIGIT_SPACING,         DNI_DIGIT_THICKNESS + 8 // u64
        .equ DNI_COLOR,                 DNI_DIGIT_SPACING + 8   // u32

        .equ STRUCT_DNI_SIZE,           DNI_COLOR + 4





/* Data for drawing decimal digits */
/* u32[10] */
DIGITS_FONT:
/* Digit 0: */
        .word DIGIT_SEGMENT_0 | DIGIT_SEGMENT_1 | DIGIT_SEGMENT_2 | DIGIT_SEGMENT_4 | DIGIT_SEGMENT_5 | DIGIT_SEGMENT_6
/* Digit 1: */
        .word DIGIT_SEGMENT_2 | DIGIT_SEGMENT_5
/* Digit 2: */
        .word DIGIT_SEGMENT_0 | DIGIT_SEGMENT_1 | DIGIT_SEGMENT_3 | DIGIT_SEGMENT_5 | DIGIT_SEGMENT_6
/* Digit 3: */
        .word DIGIT_SEGMENT_0 | DIGIT_SEGMENT_2 | DIGIT_SEGMENT_3 | DIGIT_SEGMENT_5 | DIGIT_SEGMENT_6
/* Digit 4: */
        .word DIGIT_SEGMENT_2 | DIGIT_SEGMENT_3 | DIGIT_SEGMENT_4 | DIGIT_SEGMENT_5
/* Digit 5: */
        .word DIGIT_SEGMENT_0 | DIGIT_SEGMENT_2 | DIGIT_SEGMENT_3 | DIGIT_SEGMENT_4 | DIGIT_SEGMENT_6
/* Digit 6: */
        .word DIGIT_SEGMENT_0 | DIGIT_SEGMENT_1 | DIGIT_SEGMENT_2 | DIGIT_SEGMENT_3 | DIGIT_SEGMENT_4 | DIGIT_SEGMENT_6
/* Digit 7: */
        .word DIGIT_SEGMENT_2 | DIGIT_SEGMENT_5 | DIGIT_SEGMENT_6
/* Digit 8: */
        .word DIGIT_SEGMENT_0 | DIGIT_SEGMENT_1 | DIGIT_SEGMENT_2 | DIGIT_SEGMENT_3 | DIGIT_SEGMENT_4 | DIGIT_SEGMENT_5 | DIGIT_SEGMENT_6
/* Digit 9: */
        .word DIGIT_SEGMENT_2 | DIGIT_SEGMENT_3 | DIGIT_SEGMENT_4 | DIGIT_SEGMENT_5 | DIGIT_SEGMENT_6
/* Digit - (minus) (i = 10): */
        .word DIGIT_SEGMENT_3

        .equ DIGIT_MINUS_INDEX,         10


/*
 * x19: framebuffer address (could be x9-15 ?)
 * x20: player x
 * x21: player y
 * x22: bg color index
 * w23: bg color
 * w24: player color
 * x25: remaining columns of row
 * x26: remaining rows
 * x28 (const): beginning of framebuffer
 */
main:
        sub     sp, sp, 8
        // TODO: clean framebuffer saving
        str     x0, [sp]        // Save framebuffer to stack

        // mov     x28, x0         // Save framebuffer address to x28
        ldr     x28, =BACK_BUFFER_ADDRESS

        // Set GPIOs 0..9 to read
        mov     x9, GPIO_BASE
        str     wzr, [x9, GPIO_GPFSEL0]

        // Allocate and init struct GameState
        mov     x9, STRUCT_GAME_STATE_SIZE
        sub     sp, sp, x9
restart:
        mov     x0, sp
        bl      init_game_state


        add     x0, sp, PARTICLE_MANAGER
        bl      create_background_starfield



/*
 * ************* *
 * * GAME LOOP * *
 * ************* *
 */
game_loop:

        add     x0, sp, INPUT_STATE
        bl      read_input

        add     x0, sp, INPUT_STATE
        add     x1, sp, TETROMINO_STATE
        add     x2, sp, BOARD_STATE
        bl      process_input

        mov     x0, sp
        mov     x1, x28
        bl      tetromino_fall
        cbz     x0, game_loop__keep_tetromino
        /* We have just placed a tetromino, and we need to get a new one */


        add     x0, sp, TETROMINO_STATE
        bl      init_tetromino_state

        add     x0, sp, CHOOSER_BAG_STATE
        bl      choose_next_tetromino

        sturb   w0, [sp, TETROMINO_STATE + TSTATE_ID]  // Start with new tetromino.
game_loop__keep_tetromino:


        mov     x0, x28
        bl      draw_canvas


        add     x0, sp, PARTICLE_MANAGER
        mov     x1, x28
        bl      particle_manager_render


        mov     x0, ((SCREEN_WIDTH / 2) - (TETRIS_CELL_SIZE * ((BOARD_WIDTH / 2) + 1)))
        mov     x1, ((SCREEN_HEIGH / 2) - (TETRIS_CELL_SIZE * ((BOARD_HEIGHT / 2) + 1)))
        mov     x19, x1
        add     x2, sp, BOARD_STATE
        add     x3, sp, TETROMINO_STATE
        mov     x4, x28
        bl      draw_board


        mov     x0, (SCREEN_WIDTH - 1)
        sub     x0, x0, x19
        mov     x1, x19
        add     x2, sp, GAME_STATS
        mov     x3, x28
        bl      draw_stats


        mov     x0, sp
        mov     x1, x28
        bl      draw_destroy_particles


        /* Copy back buffer to real framebuffer */
        mov     x0, x28
        mov     x9, STRUCT_GAME_STATE_SIZE
        ldr     x1, [sp, x9]                    // restore original framebuffer address from stack
        bl      copy_framebuffer


game_loop__sleep:
        ldr     w0, [sp, LAST_TICK]
        bl      get_elapsed_time
        mov     w2, US_PER_TICK
        cmp     w0, w2
        b.lt    game_loop__sleep


        ldr     w0, [sp, LAST_TICK]
        add     w0, w0, w2
        str     w0, [sp, LAST_TICK]

        ldr     x0, [sp, TICK_COUNTER]
        add     x0, x0, 1
        str     x0, [sp, TICK_COUNTER]
        b game_loop


game_over:
        add             x0, sp, INPUT_STATE
        bl              read_input
        
	add		x0, sp, INPUT_STATE
	ldr		w0, [x0, ON_PRESS_STATE]
	add		x1, sp, TETROMINO_STATE
	bl		handle_space

	b		game_over



/*
 * Params:
 *      x0: in u32*             <- src framebuffer
 *      x1: out u32*            <- dst framebuffer
 */
copy_framebuffer:
        stp     lr, x19, [sp, -80]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]
        stp     x24, x25, [sp, 48]
        stp     x26, x27, [sp, 64]

        ldr     x19, =SCREEN_PIXELS     // x19 = width * height
        lsl     x19, x19, BYTES_PER_PIXEL_SHIFT
        add     x19, x0, x19

copy_framebuffer__next_pixel:
        ldp     x9, x10, [x0]
        ldp     x11, x12, [x0, 16]
        ldp     x13, x14, [x0, 32]
        ldp     x15, x16, [x0, 48]
        ldp     x20, x21, [x0, 64]
        ldp     x22, x23, [x0, 80]
        ldp     x24, x25, [x0, 96]
        ldp     x26, x27, [x0, 112]

        stp     x9, x10, [x1]
        stp     x11, x12, [x1, 16]
        stp     x13, x14, [x1, 32]
        stp     x15, x16, [x1, 48]
        stp     x20, x21, [x1, 64]
        stp     x22, x23, [x1, 80]
        stp     x24, x25, [x1, 96]
        stp     x26, x27, [x1, 112]

        add     x0, x0, 128
        add     x1, x1, 128
        cmp     x0, x19
        b.lt    copy_framebuffer__next_pixel


        ldp     x26, x27, [sp, 64]
        ldp     x24, x25, [sp, 48]
        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 80
        ret



/*
 * Params:
 *      x0: out struct GameState*       <- game_state
 */
init_game_state:
        stp     lr, x19, [sp, -16]!

        mov     x19, x0                 // x19 <- game_state

        bl      get_time
        str     w0, [x19, LAST_TICK]
        str     w0, [x19, LAST_DROP]

        str     xzr, [x19, TICK_COUNTER]

        add     x0, x19, INPUT_STATE
        bl      init_input_state

        add     x0, x19, TETROMINO_STATE
        bl      init_tetromino_state

        add     x0, x19, CHOOSER_BAG_STATE
        bl      recreate_chooser_bag

        add     x0, x19, CHOOSER_BAG_STATE
        bl      choose_next_tetromino
        stur    x0, [x19, TETROMINO_STATE + TSTATE_ID]  // Set first tetromino.

        add     x0, x19, PARTICLE_MANAGER
        bl      particle_manager_init

        add	x0, x19, BOARD_STATE
        bl	init_board_state

        add 	x0, x19, GAME_STATS
        bl 	init_game_stats

        ldp     lr, x19, [sp], 16
        ret


/*
 * Params:
 *      x0: out struct InputState*
 */
init_input_state:
        stur    wzr, [x0, PRESSED_STATE]
        stur    wzr, [x0, ON_PRESS_STATE]
        ret


/*
 * Params:
 *      x0: out struct TetrominoState*
 */
init_tetromino_state:
        stur    xzr, [x0, TSTATE_ID]
        mov     x9, ((BOARD_WIDTH / 2) - 2)
        stur    x9, [x0, TSTATE_POS_X]
        mov     x9, (BOARD_HEIGHT - 4)
        stur    x9, [x0, TSTATE_POS_Y]
        stur    xzr, [x0, TSTATE_ROT]
        ret



/*
 * Params:
 *      x0: out struct BoardState*
 */
init_board_state:
        sub     sp, sp, 8
        stur    x19, [sp]

        mov     x19, x0             // x19 <- board state

        add     x9, x19, BSTATE_BOARD   // x9 <- u32* pointer to current cell
        mov     x10, BOARD_SIZE         // x10 <- remaining cells


init_board_state__board_loop:
        sturb   wzr, [x9]
        add     x9, x9, 1       // Advance board pointer
        sub     x10, x10, 1     // Decrement remaining cells
        cbnz    x10, init_board_state__board_loop


        add     x9, x19, BSTATE_DESTROYED_ROWS  // x9 <- pointer to destroyed rows array
        mov     x10, 4                          // x10 <- remaining destroyed rows elements
        mov     w11, 0xFF

init_board_state__destroyed_rows_loop:
        sturb   w11, [x9]
        add     x9, x9, 1
        sub     x10, x10, 1
        cbnz    x10, init_board_state__destroyed_rows_loop


        ldur    x19, [sp]
        add     sp, sp, 8
        ret



/*
 * Params:
 *      x0: out struct GameStats*
 */
init_game_stats:
        stur xzr, [x0, GS_SCORE]
        stur xzr, [x0, GS_COMPLETED_ROWS]
        ret



/*
 * Params:
 *      x0: out u32*    <- framebuffer
 */
draw_canvas:
        stp     lr, x19, [sp, -16]!

        ldr     w9, =BACKGROUND_COLOR   // x9 <- background color
        ldr     x19, =SCREEN_PIXELS     // x19 = width * height = remaining pixels

draw_canvas__next_pixel:
        str     w9, [x0]                // Paint pixel with background color

        add     x0, x0, BYTES_PER_PIXEL // Advance framebuffer
        subs    x19, x19, 1             // Decrement remaining pixels
        b.gt    draw_canvas__next_pixel // Loop if pixels remain

        ldp     lr, x19, [sp], 16
        ret


/*
 * Params:
 *      x0: u64                         <- bottom left x coordinate (game coordinates)
 *      x1: u64                         <- bottom left y coordinate (game coordinates)
 *      x2: in struct BoardState*       <- board state
 *      x3: in struct TetrominoState*   <- tetromino state
 *      x4: in/out u32*                 <- framebuffer
 */
draw_board:
        stp     lr, x19, [sp, -48]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]

        mov     x20, x0
        mov     x21, x1
        mov     x22, x2
        mov     x23, x3
        mov     x19, x4

        add     x0, x20, TETRIS_CELL_SIZE
        add     x1, x21, TETRIS_CELL_SIZE
        mov     x2, x22
        mov     x3, x23
        mov     x4, x19
        bl      draw_board_inner

        mov     x0, x20
        mov     x1, x21
        mov     x2, x19
        bl      draw_board_frame

        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 48
        ret



/*
 * Params:
 *      x0: u64                         <- bottom left x coordinate (game coordinates)
 *      x1: u64                         <- bottom left y coordinate (game coordinates)
 *      x2: in struct BoardState*       <- board state
 *      x3: in struct TetrominoState*   <- tetromino state
 *      x4: in/out u32*                 <- framebuffer
 */
draw_board_inner:
        stp     lr, x19, [sp, -80]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]
        stp     x24, x25, [sp, 48]
        stp     x26, x27, [sp, 64]

        mov     x20, x0         // x20 <- bottom left x coordinate
        mov     x21, x1         // x21 <- bottom left y coordinate
        mov     x22, x2         // x22 <- board state
        mov     x23, x3         // x23 <- tetromino state
        mov     x24, x4         // x24 <- framebuffer


        mov     x26, 0          // x26 <- row iterator

draw_board_inner__next_row:
        mov     x25, 0          // x25 <- column iterator

draw_board_inner__next_col:
        mov     x0, x25
        mov     x1, x26
        mov     x2, x22
        mov     x3, x23
        bl      get_cell_id_with_tetromino_at
        cbz     x0, draw_board_inner__skip_cell       // skip if cell is air
        sub     x0, x0, TETROMINO_ID_BIAS       // x0 <- normalized cell id

        bl      get_tetromino_by_index
        mov     x2, x0                          // x2: in struct Tetromino* <- current tetromino

        mov     x9, TETRIS_CELL_SIZE
        mul     x0, x9, x25     // x0 <- x offset in coords to current cell
        add     x0, x20, x0     // x0 <- bottom left x of current cell
        mul     x1, x9, x26     // x1 <- y offset in coords to current cell
        add     x1, x21, x1     // x1 <- bottom left y of current cell
        mov     x3, x24
        bl      draw_tetris_cell

draw_board_inner__skip_cell:
        add     x25, x25, 1             // Advance to next column
        cmp     x25, BOARD_WIDTH        // Check if we finished row
        b.lt    draw_board_inner__next_col
        /* We are at the end of the row */

        add     x26, x26, 1             // Advance to next row
        cmp     x26, BOARD_HEIGHT       // Check if we finished all rows
        b.lt    draw_board_inner__next_row
        /* We finished drawing inner board */


        ldp     x26, x27, [sp, 64]
        ldp     x24, x25, [sp, 48]
        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 80
        ret



/*
 * Params:
 *      x0: u64                         <- bottom left x coordinate (game coordinates)
 *      x1: u64                         <- bottom left y coordinate (game coordinates)
 *      x2: in/out u32*                 <- framebuffer
 */
draw_board_frame:
        stp     lr, x19, [sp, -64]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]
        stp     x24, x25, [sp, 48]

        mov     x20, x0         // x20 <- bottom left x coordinate
        mov     x21, x1         // x21 <- bottom left y coordinate
        mov     x22, x2         // x22 <- framebuffer


/* Draw bottom and top rows */
        mov     x23, ((BOARD_HEIGHT + 1) * TETRIS_CELL_SIZE)    // vertical offset for top row, in pixels

        mov     x24, 0          // x iterator
draw_board_frame__rows_next_col:
        mov     x9, TETRIS_CELL_SIZE
        mul     x25, x9, x24    // x25 <- x offset in coords to current cell
        add     x25, x20, x25   // x25 <- bottom left x of current cell

        mov     x0, x25
        mov     x1, x21         // x1 <- bottom left y of bottom row
        ldr     x2, =FRAME_DIFFUSE_COLOR
        ldr     x3, =FRAME_SPECULAR_COLOR
        ldr     x4, =FRAME_AMBIENT_COLOR
        mov     x5, x22
        bl      draw_tetris_cell_by_colors

        mov     x0, x25
        add     x1, x21, x23    // x1 <- bottom left y of top row
        ldr     x2, =FRAME_DIFFUSE_COLOR
        ldr     x3, =FRAME_SPECULAR_COLOR
        ldr     x4, =FRAME_AMBIENT_COLOR
        mov     x5, x22
        bl      draw_tetris_cell_by_colors

        add     x24, x24, 1
        cmp     x24, (BOARD_WIDTH + 2)
        b.lt    draw_board_frame__rows_next_col



/* Draw left and right columns */
        mov     x23, ((BOARD_WIDTH + 1) * TETRIS_CELL_SIZE)    // horizontal offset for right column, in pixels

        mov     x24, 1          // y iterator (we start at 1 because 0 has already been drawn)
draw_board_frame__cols_next_row:
        mov     x9, TETRIS_CELL_SIZE
        mul     x25, x9, x24    // x25 <- y offset in coords to current cell
        add     x25, x21, x25   // x25 <- bottom left y of current cell

        mov     x0, x20
        mov     x1, x25
        ldr     x2, =FRAME_DIFFUSE_COLOR
        ldr     x3, =FRAME_SPECULAR_COLOR
        ldr     x4, =FRAME_AMBIENT_COLOR
        mov     x5, x22
        bl      draw_tetris_cell_by_colors

        add     x0, x20, x23    // x1 <- bottom left y of right column
        mov     x1, x25
        ldr     x2, =FRAME_DIFFUSE_COLOR
        ldr     x3, =FRAME_SPECULAR_COLOR
        ldr     x4, =FRAME_AMBIENT_COLOR
        mov     x5, x22
        bl      draw_tetris_cell_by_colors

        add     x24, x24, 1
        cmp     x24, (BOARD_HEIGHT + 1)
        b.lt    draw_board_frame__cols_next_row


        ldp     x24, x25, [sp, 48]
        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 64
        ret



/*
 * Params:
 *      x0: u64                         <- x coordinate 0 <= x < BOARD_WIDTH
 *      x1: u64                         <- y coordinate 0 <= y < BOARD_HEIGHT
 *      x2: in struct BoardState*       <- board state
 *      x3: in struct TetrominoState*   <- tetromino state
 * Returns:
 *      x0: u64                         <- 0 or tetromino id + TETROMINO_ID_BIAS
 */
get_cell_id_with_tetromino_at:
        stp     lr, x19, [sp, -80]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]
        stp     x24, x25, [sp, 48]
        stp     x26, x27, [sp, 64]

        mov     x20, x0                 // x20 <- x board coordinate
        mov     x21, x1                 // x21 <- y board coordinate
        mov     x22, x2                 // x22 <- board state
        mov     x23, x3                 // x23 <- tetromino state

        ldr     x24, [x3, TSTATE_POS_X] // x24 <- tetromino x
        ldr     x25, [x3, TSTATE_POS_Y] // x25 <- tetromino y

        sub     x24, x0, x24            // x24 <- tetromino x relative to cell x
        cmp     x24, 0
        b.lt    get_cell_id_with_tetromino_at__not_tetromino
        cmp     x24, TETROMINO_BOARD_WIDTH
        b.ge    get_cell_id_with_tetromino_at__not_tetromino

        sub     x25, x1, x25            // x25 <- tetromino y relative to cell y
        cmp     x25, 0
        b.lt    get_cell_id_with_tetromino_at__not_tetromino
        cmp     x25, TETROMINO_BOARD_HEIGHT
        b.ge    get_cell_id_with_tetromino_at__not_tetromino

        /* Current cell is inside tetromino matrix, we should check that first */

        mov     x0, x3
        bl      get_tetromino           // x0 <- tetromino data of current tetromino's rotation

        mov     x2, x0                  // x2 <- current tetromino data
        mov     x0, x24                 // x0 <- tetromino x in tetromino board
        mov     x1, x25                 // x1 <- tetromino y in tetromino board
        bl      is_tetromino_cell_air
        cbnz    x0, get_cell_id_with_tetromino_at__not_tetromino

        /* Current cell belongs to tetromino */
        ldr     x0, [x23, TSTATE_ID]            // x0 <- cell id without bias
        add     x0, x0, TETROMINO_ID_BIAS       // x0 <- cell id with bias
        b       get_cell_id_with_tetromino_at__end


get_cell_id_with_tetromino_at__not_tetromino:
        mov     x9, BOARD_WIDTH
        mul     x9, x21, x9
        add     x9, x9, x20
        add     x9, x9, BSTATE_BOARD    // x9 <- offset to board cell
        add     x9, x22, x9             // x9 <- pointer to board cell

        ldrb    w0, [x9]        // x0 <- cell id (already has bias)
        b       get_cell_id_with_tetromino_at__end


get_cell_id_with_tetromino_at__end:
        ldp     x26, x27, [sp, 64]
        ldp     x24, x25, [sp, 48]
        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 80
        ret



/*
 * Params:
 *      x0: u64                         <- tetromino index 0 <= i < NUM_TETROMINOS
 * Returns:
 *      x0: in struct Tetromino*        <- tetromino of current tetromino
 */
get_tetromino_by_index:
        stp     lr, x19, [sp, -16]!

        mov     x9, STRUCT_TETROMINO_SIZE       // x0 <- size of tetromino in bytes
        mul     x9, x9, x0                      // x9 <- offset to tetromino in bytes
        ldr     x0, =TETROMINOS                 // x0 <- pointer to first tetromino
        add     x0, x0, x9                      // x0 <- pointer to current tetromino

        ldp     lr, x19, [sp], 16
        ret



/*
 * Params:
 *      x0: u64                         <- x tetromino board coordinate 0 <= x < TETROMINO_BOARD_WIDTH
 *      x1: u64                         <- y tetromino board coordinate 0 <= y < TETROMINO_BOARD_HEIGHT
 *      x2: in struct TetrominoData*    <- tetromino data
 * Returns:
 *      x0: bool                        <- is TetrominoData[y][x] air
 */
is_tetromino_cell_air:
        stp     lr, x19, [sp, -16]!

        mov     x9, TETROMINO_BOARD_WIDTH
        mul     x9, x1, x9                      // x9 <- vertical offset
        add     x9, x9, x0                      // x9 <- vertical offset + horizontal offset
        add     x9, x9, TDATA
        add     x9, x2, x9                      // x9 <- pointer to cell at (x, y)

        ldrb    w9, [x9]                        // x9 <- cell at (x, y)
        cmp     x9, 0                           // Check if cell is air
        cset    x0, eq                          // x0 = is_air() ? 1 : 0

        ldp     lr, x19, [sp], 16
        ret



/*
 * Params:
 *      x0: u64                         <- bottom right x (game coordinates)
 *      x1: u64                         <- bottom right y (game coordinates)
 *      x2: in struct GameStats*        <- game stats
 *      x3: out u32*                    <- framebuffer
 */
draw_stats:
        stp     lr, x19, [sp, -16]!
        sub     sp, sp, STRUCT_DNI_SIZE

        str     x0, [sp, DNI_POS_X]
        str     x1, [sp, DNI_POS_Y]

        ldr     x9, [x2, GS_COMPLETED_ROWS]
        str     x9, [sp, DNI_VALUE]

        mov     x9, 5
        str     x9, [sp, DNI_MAX_DIGITS]

        mov     x9, 48
        str     x9, [sp, DNI_DIGIT_WIDTH]

        mov     x9, 12
        str     x9, [sp, DNI_DIGIT_THICKNESS]

        mov     x9, 12
        str     x9, [sp, DNI_DIGIT_SPACING]

        ldr     w9, =0xFFFFFFFF
        str     w9, [sp, DNI_COLOR]

        mov     x0, sp
        mov     x1, x3
        bl      draw_number

        add     sp, sp, STRUCT_DNI_SIZE
        ldp     lr, x19, [sp], 16
        ret




/*
 * Params:
 *      x0: struct GameState*   <- game state
 *	x1: in/out u32*         <- framebuffer
 */
draw_destroy_particles:
        sub     sp, sp, 72
        stur    lr, [sp]
        stur    x19, [sp, 8]
        stur    x20, [sp, 16]
        stur    x21, [sp, 24]
        stur    x22, [sp, 32]
        stur    x23, [sp, 40]
        stur    x24, [sp, 48]
        stur    x25, [sp, 56]
        stur    x26, [sp, 64]

        add     x19, x0, (BOARD_STATE + BSTATE_DESTROYED_ROWS)
        mov     x24, x0

        add     x0, x0, LAST_DROP
        ldur    w0, [x0]
        mov     x20, x0

        mov     x21, ( (SCREEN_WIDTH - BOARD_WIDTH * TETRIS_CELL_SIZE) / 2 )
        sub     x21, x21, TETRIS_CELL_SIZE

        mov     x22, ( (TETRIS_CELL_SIZE + SCREEN_HEIGH - BOARD_HEIGHT * TETRIS_CELL_SIZE) / 2 )

        mov     x23, x1

        mov     x2, 4

draw_destroy_particles__loop:
        ldurb   w3, [x19]

        cmp     x3, 0xff
        b.eq    draw_destroy_particles__end

        sub     sp, sp, 8
        stur    x2, [sp]

        mov     x0, x20
        bl      get_elapsed_time
        lsl     x0, x0, 5
        ldr     w2, =US_PER_AUTO_DROP
        udiv    x4, x0, x2
        mov     x5, 1
        lsl     x5, x5, 5
        sub     x5, x5, x4
        mov     x0, DESTROY_PARTICLE_RADIUS
        mul     x2, x5, x0
        lsr     x2, x2, 5
        mov     x10, x2
        mov     x25, x2


        mov     x2, 50
        mul     x4, x4, x2
        lsr     x4, x4, 5
        mov     x24, x4

        mov     x26, TETRIS_CELL_SIZE
        mul     x26, x26, x3

        sub     x0, x21, x24

        add     x1, x22, x26

        mov     x2, x23
        mov     x3, x25
        ldr     x4, =DESTROY_PARTICLE_COLOR
        bl      draw_circle_at

        mov     x0, SCREEN_WIDTH
        sub     x0, x0, x21
        add     x0, x0, x24

        add     x1, x22, x26

        mov     x2, x23
        mov     x3, x25
        ldr     x4, =DESTROY_PARTICLE_COLOR
        bl      draw_circle_at

        ldur    x2, [sp]
        add     sp, sp, 8

        sub     x2, x2, 1
        add     x19, x19, 1
        cbnz    x2, draw_destroy_particles__loop
        b       draw_destroy_particles__end


draw_destroy_particles__end:

        ldur    x26, [sp, 64]
        ldur    x25, [sp, 56]
        ldur    x24, [sp, 48]
        ldur    x23, [sp, 40]
        ldur    x22, [sp, 32]
        ldur    x21, [sp, 24]
        ldur    x20, [sp, 16]
        ldur    x19, [sp, 8]
        ldur    lr, [sp]
        add     sp, sp, 72
        ret



/*
 * Params:
 *      x0: in/out struct InputState*
 */
read_input:
        stp     lr, x19, [sp, -32]!
        stp     x20, x21, [sp, 16]

        ldr     w19, [x0, PRESSED_STATE]        // Load last pressed state to compute on press state

        mov     x20, GPIO_BASE
        ldr     w20, [x20, GPIO_GPLEV0]         // w20 = new pressed state

        // Input in bit 'n' is "on press" if current pressed state is 1 and previous pressed state is 0
        mvn     w19, w19                        // Bitwise NOT last pressed state
        and     w21, w20, w19                   // w21 = new on press state

        str     w20, [x0, PRESSED_STATE]
        str     w21, [x0, ON_PRESS_STATE]

        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 32
        ret



/*
 * Params:
 *      x0: const struct InputState*
 *      x1: mut struct TetrominoState*
 *      x2: const struct BoardState*      // Para chequear colision en los handle (MEJORARLO)
 */
process_input:
        stp     lr, x19, [sp, -32]!
        stp     x20, x21, [sp, 16]

        mov     x19, x0         // x19 = const struct InputState*
        mov     x20, x1         // x20 = mut struct TetrominoState*
        mov 	x21, x2         // x21 = const struct BoardState*

        ldr     w0, [x19, ON_PRESS_STATE]
        mov     x1, x20
        bl      handle_w

        ldr     w0, [x19, ON_PRESS_STATE]
        mov     x1, x20
        bl      handle_a

        ldr     w0, [x19, ON_PRESS_STATE]
        mov     x1, x20
        bl      handle_s

        ldr     w0, [x19, ON_PRESS_STATE]
        mov     x1, x20
        bl      handle_d

        ldr     w0, [x19, ON_PRESS_STATE]
        mov     x1, x20
        bl      handle_space



        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 32
        ret



/*
 * Params:
 *      x0: u32 (on press flags)
 *      x1: mut struct TetrominoState*
 *	x2: in struct BoardState*
 */
handle_w:
        sub     sp, sp, 32
        stur    lr, [sp]
        stur    x19, [sp, 8]
        stur    x20, [sp, 16]
        stur    x21, [sp, 24]

        and     x19, x0, GPIO_W
        cbz     x19, handle_w__end

        mov     x20, x1

        mov     x0, x1
        mov     x1, x2

        ldur    x19, [x20, TSTATE_ROT]
        mov     x21, x19
        add     x19, x19, 1
        cmp     x19, 4
        b.ne    handle_w__rot_ok
        mov     x19, 0
handle_w__rot_ok:
        stur    x19, [x20, TSTATE_ROT]

        bl      check_collision
        cbz     x0, handle_w__end

        stur    x21, [x20, TSTATE_ROT]

handle_w__end:
        ldur    lr, [sp]
        ldur    x19, [sp, 8]
        ldur    x20, [sp, 16]
        ldur    x21, [sp, 24]
        add     sp, sp, 32
        ret



/*
 * Params:
 *      x0: u32 (on press flags)
 *      x1: mut struct TetrominoState*
 *	x2: in struct BoardState*
 */
handle_s:
        sub     sp, sp, 40
        stur    lr, [sp]
        stur    x19, [sp, 8]
        stur    x20, [sp, 16]
        stur    x21, [sp, 24]
        stur    x22, [sp, 32]

        and     x19, x0, GPIO_S
        cbz     x19, handle_s__end

        mov     x20, x1

        mov     x0, x1
        mov     x1, x2

handle_s__loop:
        ldur    x19, [x20, TSTATE_POS_Y]
        sub     x19, x19, 1
        stur    x19, [x20, TSTATE_POS_Y]

        mov     x21, x0
        mov     x22, x1
        bl      check_collision
        mov     x2, x0
        mov     x0, x21
        mov     x1, x22
        cbz     x2, handle_s__loop

        ldur    x19, [x20, TSTATE_POS_Y]
        add     x19, x19, 1
        stur    x19, [x20, TSTATE_POS_Y]

handle_s__end:
        ldur    lr, [sp]
        ldur    x19, [sp, 8]
        ldur    x20, [sp, 16]
        ldur    x21, [sp, 24]
        ldur    x22, [sp, 32]
        add     sp, sp, 40
        ret



/*
 * Params:
 *      x0: u32 (on press flags)
 *      x1: mut struct TetrominoState*
 *	x2: const struct BoardState*
 */
handle_a:
        sub     sp, sp, 24
        stur    lr, [sp]
        stur    x19, [sp, 8]
        stur    x20, [sp, 16]

        and     x19, x0, GPIO_A
        cbz     x19, handle_a__end

        mov     x20, x1

        mov     x0, x1
        mov     x1, x2

        ldur    x19, [x20, TSTATE_POS_X]
        sub     x19, x19, 1
        stur    x19, [x20, TSTATE_POS_X]

        bl      check_collision
        cbz     x0, handle_a__end

        ldur    x19, [x20, TSTATE_POS_X]
        add     x19, x19, 1
        stur    x19, [x20, TSTATE_POS_X]

handle_a__end:
        ldur    lr, [sp]
        ldur    x19, [sp, 8]
        ldur    x20, [sp, 16]
        add     sp, sp, 24
        ret



/*
 * Params:
 *      x0: u32 (on press flags)
 *      x1: mut struct TetrominoState*
 *	x2: const struct BoardState*
 */
handle_d:
        sub     sp, sp, 24
        stur    lr, [sp]
        stur    x19, [sp, 8]
        stur    x20, [sp, 16]

        and     x19, x0, GPIO_D
        cbz     x19, handle_d__end

        mov     x20, x1

        mov     x0, x1
        mov     x1, x2

        ldur    x19, [x20, TSTATE_POS_X]
        add     x19, x19, 1
        stur    x19, [x20, TSTATE_POS_X]

        bl      check_collision
        cbz     x0, handle_d__end

        ldur    x19, [x20, TSTATE_POS_X]
        sub     x19, x19, 1
        stur    x19, [x20, TSTATE_POS_X]

handle_d__end:
        ldur    lr, [sp]
        ldur    x19, [sp, 8]
        ldur    x20, [sp, 16]
        add     sp, sp, 24
        ret



/*
 * Params:
 *      x0: u32 (on press flags)
 *      x1: mut struct TetrominoState*
*/
handle_space:
        stp     lr, x19, [sp, -16]!

        and     x19, x0, GPIO_SPACE
        cbz     x19, handle_space__end

        sub     sp, x1, TETROMINO_STATE
        b       restart

handle_space__end:
        ldp     lr, x19, [sp], 16
        ret



/*
 * Params:
 *      x0: struct GameState*   <- game state
 */
tetromino_fall:
        sub sp, sp, 64
        stur lr, [sp]
        stur x19, [sp, 8]
        stur x20, [sp, 16]
        stur x21, [sp, 24]
        stur x22, [sp, 32]
        stur x23, [sp, 40]
        stur x24, [sp, 48]
        stur x25, [sp, 56]

        mov     x19, x0         // x19 <- struct GameState*

        ldur    w0, [x19, LAST_DROP]    // w0 = last time tetromino moved
        bl      get_elapsed_time        // Sets w0, w1

        ldr     x9, =US_PER_AUTO_DROP
        cmp     x0, x9                  // Check time to see if tetromino should fall
        b.lt    tetromino_fall__end

        stur    w1, [x19, LAST_DROP]    // update LAST_DROP with LAST ATTEMPTED DROP time.

        // am, destruir las partículas que haya
        sub     sp, sp, 16
        stur    x0, [sp]
        stur    x1, [sp, 8]
        mov     x0, x19
        bl      update_destroy_particles
        ldur    x1, [sp, 8]
        ldur    x0, [sp]
        add     sp, sp, 16

        // Try to drop tetromino 1 block. Don't move if not possible.
        add     x0, x19, TETROMINO_STATE
        add     x1, x19, BOARD_STATE
        bl      try_drop_tetromino

        cbnz    x0, tetromino_fall__end

        // Try to integrate tetromino with board, if not possible, then GAME OVER.
        add     x0, x19, TETROMINO_STATE
        add     x1, x19, BOARD_STATE
        bl      try_place_tetromino

        // Check full lines and update board matrix.
        add     x0, x19, BOARD_STATE
        add     x1, x19, (TETROMINO_STATE + TSTATE_POS_Y)
        ldur    x1, [x1]                                  // x1 = posY of tetromino
        bl      update_board

        ldur    x1, [x19, GAME_STATS + GS_COMPLETED_ROWS]
        add     x1, x0, x1                                   // Update completed rows
        stur    x1, [x19, GAME_STATS + GS_COMPLETED_ROWS]

        mov x0, 1
        b tetromino_fall__fullend

tetromino_fall__end:
        mov     x0, 0

tetromino_fall__fullend:

        ldur    x25, [sp, 56]
        ldur    x24, [sp, 48]
        ldur    x23, [sp, 40]
        ldur    x22, [sp, 32]
        ldur    x21, [sp, 24]
        ldur    x20, [sp, 16]
        ldur    x19, [sp, 8]
        ldur    lr, [sp]
        add     sp, sp, 64
        ret



/*
 * Params:
 *      x0:	struct GameState*
 */
update_destroy_particles:
        sub     sp, sp, 24
        stur    x0, [sp]
        stur    x1, [sp, 8]
        stur    x2, [sp, 16]

        add     x0, x0, (BOARD_STATE + BSTATE_DESTROYED_ROWS)
        movz    x1, 0xff, lsl 00
        mov     x2, 4

update_destroy_particles__loop:
        sturb   w1, [x0]
        add     x0, x0, 1
        sub     x2, x2, 1
        cbnz    x2, update_destroy_particles__loop

        ldur    x2, [sp, 16]
        ldur    x1, [sp, 8]
        ldur    x0, [sp]
        add     sp, sp, 24
        ret



// Tries to move tetromino one position down.
/*
 * Params:
 *      x0: in/out struct TetrominoState*
 *      x1: in struct BoardState*
 * Returns:
 *      x0: bool
 */
try_drop_tetromino:
        sub sp, sp, 24
        stur lr, [sp]
        stur x20, [sp, 8]
        stur x19, [sp, 16]

        mov x20, x0

        ldur x9, [x20, TSTATE_POS_Y]
        sub x9, x9, 1                       // new TSTATE_POS_Y = previous TSTATE_POS_Y - 1
        stur x9, [x20, TSTATE_POS_Y]

        // check if tetromino is colliding
        bl check_collision
        cbz x0, try_drop_tetromino__success
        b try_drop_tetromino__failure

try_drop_tetromino__success:
        mov x0, 1
        b try_drop_tetromino__end


try_drop_tetromino__failure:
        ldur x9, [x20, TSTATE_POS_Y]
        add x9, x9, 1                       // new TSTATE_POS_Y = previous TSTATE_POS_Y + 1 = original TSTATE_POS_Y
        stur x9, [x20, TSTATE_POS_Y]

        mov x0, 0
        b try_drop_tetromino__end

try_drop_tetromino__end:
        // go back to tetromino_fall to try to place it on the board.
        ldur lr, [sp]
        ldur x20, [sp, 8]
        ldur x19, [sp, 16]
        add sp, sp, 24
        br lr



// Tries to place tetromino in its current position. Does it if possible, GAME OVER if not.
// INTENDED USE: COLLISION CHECK POSITIVE & PLACE TETROMINO NEGATIVE => GAME OVER
//               COLLISION CHECK POSITIVE & PLACE TETROMINO => SELECT NEXT TETROMINO TO DROP
/*
 * Params:
 *      x0: in struct TetrominoState*
 *      x1: in/out struct BoardState*
 * Returns:
 *      x0: bool
 */
try_place_tetromino:
        sub     sp, sp, 64
        stur    lr, [sp]
        stur    x19, [sp, 8]
        stur    x20, [sp, 16]
        stur    x21, [sp, 24]
        stur    x22, [sp, 32]
        stur    x23, [sp, 40]
        stur    x24, [sp, 48]
        stur    x25, [sp, 56]

        mov     x21, x0
        mov     x20, x1

        bl      check_collision
        cbz    x0, try_place_tetromino__not_game_over  

	sub		sp, x21, TETROMINO_STATE
	b		game_over

try_place_tetromino__not_game_over:	

        mov     x0, x21
        bl      get_tetromino
/*	CURRENT KNOWN DATA
 *      x0: in struct TetrominoData* -> matrix of tetromino
 *	x1: i64                      -> pos x
 *	x2: i64                      -> pos y
 *	x3: u32                      -> color
*/
        add     x26, x0, TETROMINO_BOARD_SIZE

        mov     x3, BOARD_WIDTH
        mul     x3, x2, x3
        add     x3, x3, x1

        add     x3, x3, x20  // x3 = Board[x][y]*

        ldur    x27, [x21, TSTATE_ID]
        add     x27, x27, TETROMINO_ID_BIAS

        mov     x4, 0
        // place tetromino on board.
        b       try_place_tetromino__loop

try_place_tetromino__bigloop:
        add     x3, x3, (BOARD_WIDTH-TETROMINO_BOARD_WIDTH)  // Jump to next Tetromino Matrix's Line.
        mov     x4, 0
try_place_tetromino__loop:
        ldurb   w22, [x0]

        cmp     x22, 0
        b.eq    try_place_tetromino__next_cell  // If Tetromino's cell is empty, move on.

        sturb   w27, [x3]   // else, place full Tetromino Matrix's cell into it's corresponding BoardState position.

try_place_tetromino__next_cell:
        add     x0, x0, 1        // move to next Tetromino Matrix cell.
        add     x3, x3, 1        // move to next board cell.
        add     x4, x4, 1        // increase count per line.

        cmp     x0, x26
        b.eq    try_place_tetromino__end  // If x0 reached the end, then game IS NOT over and BoardState IS Updated.

        cmp     x4, 4    // if tetromino matrix line is done, jump to next line.
        b.eq    try_place_tetromino__bigloop

        b       try_place_tetromino__loop

try_place_tetromino__end:
        mov     x0, 1

        ldur    x25, [sp, 56]
        ldur    x24, [sp, 48]
        ldur    x23, [sp, 40]
        ldur    x22, [sp, 32]
        ldur    x21, [sp, 24]
        ldur    x20, [sp, 16]
        ldur    x19, [sp, 8]
        ldur    lr, [sp]
        add     sp, sp, 64
        ret



/*
 * Params:
 *      x0:	in/out struct BoardState*
 *      x1:	i64                             <- tetromino y position
 * Returns:
 *      x0:	u64				<- number of rows removed
 */
update_board:
        sub     sp, sp, 8
        stur    lr, [sp]

        mov     x9, x0
        mov     x10, 0

        mov     x2, 4
        add     x0, x9, BSTATE_DESTROYED_ROWS
        movz    x3, 0x00ff, lsl 00
update_board__reset_destroyed:
        sturb   w3, [x0]
        add     x0, x0, 1
        sub     x2, x2, 1
        cbz     x2, update_board__reset_destroyed

        // x0 = max(x1, 0)
        cmp     x1, 0
        b.lt    update_board__max_branch0
        mov     x0, x1
        b       update_board__next_row

update_board__max_branch0:
        mov     x0, 0

        // x0 is the row i'm currently checking
update_board__next_row:
        add     x2, x1, TETROMINO_BOARD_WIDTH
        cmp     x0, x2
        b.ge    update_board__end

        mov     x2, BOARD_WIDTH
        mul     x2, x0, x2
        add     x2, x2, x9			// x2 points to first element of current row

        mov     x3, 0

update_board__next_elem:
        add     x5, x2, x3
        ldurb   w4, [x5]	// x4 is element of board

        cbz     x4, update_board__row_not_complete

        add     x3, x3, 1
        cmp     x3, BOARD_WIDTH
        b.eq    update_board__row_complete
        b       update_board__next_elem

update_board__row_complete:
        add     x6, x9, x10
        add	x6, x6, BSTATE_DESTROYED_ROWS
        add     x7, x0, x10
        sturb   w7, [x6]

        add     x10, x10, 1

        sub     sp, sp, 32
        stur    x0, [sp]
        stur    x1, [sp, 8]
        stur    x9, [sp, 16]
        stur    x10, [sp, 24]

        mov     x1, x0
        mov     x0, x9

        bl      erase_board_line

        ldur    x1, [sp]
        ldur    x0, [sp, 16]

        bl      fall_one_block

        ldur    x0, [sp]
        ldur    x1, [sp, 8]
        ldur    x9, [sp, 16]
        ldur    x10, [sp, 24]
        add     sp, sp, 32

        sub     x1, x1, 1
        b       update_board__next_row

update_board__row_not_complete:
        add     x0, x0, 1
        b       update_board__next_row

update_board__end:
        mov     x0, x10

        ldur    lr, [sp]
        add     sp, sp, 8
        ret



/*
 * Params:
 *      x0: u8          <- id of tetromino
 * Returns:
 *      x0: u32         <- diffuse color
 *      x1: u32         <- specular color
 *      x2: u32         <- ambient color
 */
get_tetromino_color:
        mov     x1, STRUCT_TETROMINO_SIZE
        mul     x0, x0, x1
        ldr     x2, =TETROMINOS
        add     x2, x0, x2					// x0 = TETROMINOS + STRUCT_TETROMINO_SIZE*id

        ldur    w0, [x2, TETROMINO_DIFFUSE_COLOR]
        ldur    w1, [x2, TETROMINO_SPECULAR_COLOR]
        ldur    w2, [x2, TETROMINO_AMBIENT_COLOR]
        ret



/*
 * Params:
 *      x0: in struct TetrominoState*
 * Returns:
 *	x0: in struct TetrominoData* -> matrix of tetromino
 *	x1: i64                      -> pos x
 *	x2: i64                      -> pos y
 *	x3: u32                      -> color
 */
get_tetromino:
        mov     x4, x0

        ldur    x5, [x4, TSTATE_ID]
        mov     x1, STRUCT_TETROMINO_SIZE
        mul     x5, x5, x1
        ldr     x6, =TETROMINOS
        add     x5, x5, x6				// x5 = TETROMINOS + STRUCT_TETROMINO_SIZE*id

        ldur    x6, [x4, TSTATE_ROT]
        mov     x0, STRUCT_TDATA_SIZE
        mul     x0, x0, x6
        add     x0, x0, TETROMINO_ROTS
        add     x0, x0, x5				// x0 = x5 + TETROMINO_ROTS + STRUCT_TDATA_SIZE*TSTATE_ROT

        ldur    x1, [x4, TSTATE_POS_X]

        ldur    x2, [x4, TSTATE_POS_Y]

        ldur    w3, [x5, TETROMINO_SPECULAR_COLOR]

        ret



/*
 * Params:
 *      x0: u8[BOARD_WIDTH][BOARD_HEIGHT]       <- address of board
 *      x1: u8					<- line to erase
 * Functionality:
 *      eliminates everything on the line
 */
erase_board_line:
        sub     sp, sp, 8
        stur    lr, [sp]

        movz    x2, 0   // black
        mov     x6, BOARD_WIDTH
        mul     x6, x6, x1
        add     x6, x0, x6  // x6 points to the first element of the line x8

        mov     x11, BOARD_WIDTH
erase_board_line_turn_squares_off:
        sturb   w2, [x6]
        add     x6, x6, 1
        sub     x11, x11, 1
        cbnz    x11, erase_board_line_turn_squares_off

        ldur    lr, [sp]
        add     sp, sp, 8
        ret



/*
 * Params
 *      x0: u8[BOARD_WIDTH][BOARD_HEIGHT]       <- address of board
 *      x1: u8					<- line from which lines will start to fall
 * Functionality:
 *    lowers by 1 block all the elements on the grid avobe line at height x1
 */
fall_one_block:
        sub     sp, sp, 8
        stur    lr, [sp]

        mov     x7, BOARD_SIZE

        mov     x15, BOARD_WIDTH
        mul     x15, x15, x1
        add     x15, x15, x0    // starts at first square from desired line x8

keepgoing:
        add     x5, x15, BOARD_WIDTH

        ldur    x2, [x5]         // get info from square avobe
        sturb   w2, [x15]       // replace current square with new info

        add     x15, x15, 1       // move on to the next square (-->)

        sub     x5, x5, x0
        cmp     x5, (BOARD_SIZE - 1)
        bne     keepgoing         // stop before reaching top line of grid (x15 at square #189, x5 at #199)

        mov     x1, (BOARD_HEIGHT - 1)
        bl      erase_board_line   // Erase anything on top line

        ldur    lr, [sp]
        add     sp, sp, 8
        ret



/*
 * Params:
 *      x0: x coordinate
 *      x1: y coordinate
 *      x2: beginning of framebuffer
 *      x3: radius
 *      w4: color
 */
draw_circle_at:
        stp     lr, x19, [sp, -48]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]

        add     x19, x3, 1
        mul     x19, x3, x19     // x19 "=" r^2 === r*(r+1)


        sub     x21, xzr, x3    // x21 = current circle y coordinate
circle_next_row:
        sub     x20, xzr, x3    // x20 = current circle x coordinate
circle_next_col:

        mul     x22, x20, x20   // x22 = x^2
        mul     x23, x21, x21   // x23 = y^2
        add     x22, x22, x23   // x22 = x^2 + y^2
        cmp     x22, x19
        b.gt    skip_circle_pixel       // only draw if x^2 + y^2 <= r^2



        stp     x0, x1, [sp, -16]!
        mov     x22, x3
        mov     w3, w4

        add     x0, x0, x20
        cmp     x0, SCREEN_WIDTH
        b.hs    pixel_out_of_bounds       // Out of screen
        add     x1, x1, x21
        cmp     x1, SCREEN_HEIGH
        b.hs    pixel_out_of_bounds       // Out of screen
        bl      draw_argb_pixel_at

pixel_out_of_bounds:
        mov     x3, x22
        ldp     x0, x1, [sp], 16


skip_circle_pixel:
        add     x20, x20, 1
        cmp     x20, x3
        b.le    circle_next_col

        add     x21, x21, 1
        cmp     x21, x3
        b.le    circle_next_row


        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 48
        ret



/*
 * Params:
 *      x0: in struct TetrominoState*   <- tetromino_state
 *      x1: in struct BoardState*       <- board_state
 * Returns:
 *      x0: enum CollisionResult        <- collision_result
 */
check_collision:
        stp     lr, x19, [sp, -64]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]
        stp     x24, x25, [sp, 48]


        mov     x25, x1

        bl      get_tetromino
/*       CURRENT INFO:
 *	x0: in struct TetrominoData* -> matrix of tetromino
 *	x1: i64                      -> pos x
 *	x2: i64                      -> pos y
 *	x3: u32                      -> color
 */
        mov     x24, 0
        add     x26, x0, TETROMINO_BOARD_SIZE

        mov     x22, BOARD_WIDTH
        mul     x22, x2, x22
        add     x22, x22, x1

        add     x22, x22, x25          // x22 = Board[x][y]*
        mov     x20, x25  // x20 = start of board
        // Check overlap.
        b       check_collision__loop

check_collision__bigloop:
        add     x22, x22, (BOARD_WIDTH-TETROMINO_BOARD_WIDTH)  // Jump to next Tetromino Matrix's Line.
        mov     x24, 0
check_collision__loop:
        ldurb   w19, [x0]
        cmp     x19, 0             // If Tetromino Matrix's cell IS empty, move on.
        b.eq    check_collision__next_cell


        /* Current block is not empty */

        cmp     x22, x20  // If an active tetromino cell is below the bottom line of board,
        b.lt    check_collision__badending    // it means tetromino is trying to go below the base of the board.
        add     x19, x1, x24
        cmp     x19, 0
        b.lt    check_collision__badending

        cmp     x19, BOARD_WIDTH
        b.ge    check_collision__badending

        ldurb   w23, [x22]
        cmp     x23, 0
        b.eq    check_collision__next_cell  // If Tetromino Matrix's cell IS NOT empty but grid's cell IS available, move on.

        // If grid cell IS NOT available && Tetromino Matrix's cell IS NOT empty, then there IS collision.
        b       check_collision__badending

check_collision__next_cell:
        add     x0, x0, 1        // move to next Tetromino Matrix cell.
        add     x22, x22, 1      // move to next board cell.
        add     x24, x24, 1      // increase count per line.

        cmp     x0, x26
        b.eq    check_collision__goodending     // If x0 reached the end, then there was NO collision.

        cmp     x24, 4    // if tetromino matrix line is done, jump to next line.
        b.eq    check_collision__bigloop

        b       check_collision__loop

check_collision__goodending:
        mov     x0, 0
        b       check_collision__end_end
check_collision__badending:
        mov     x0, 1
check_collision__end_end:
        ldp     x24, x25, [sp, 48]
        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 64
        ret



/*
 * Params:
 *      x0: out struct ChooserBagState*  <- chooser_bag_state
 */
recreate_chooser_bag:
        stp     lr, x19, [sp, -48]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]

        mov     w19, NUM_TETROMINOS             // x19 <- NUM_TETROMINOS
        strb    w19, [x0, CBAG_REMAINING]       // chooser_bag_state.remaining = NUM_TETROMINOS

        add     x20, x0, CBAG_VALUES    // x20 = &chooser_bag_state.values[0]

        mov     x21, 0                  // i = 0
recreate_chooser_bag__init_values:
        strb    w21, [x20]              // chooser_bag_state.values[i] = i
        add     x20, x20, 1             // x20 = &chooser_bag_state.values[i + 1] (move to next byte)
        add     x21, x21, 1             // i += 1
        cmp     x21, NUM_TETROMINOS     // i < NUM_TETROMINOS ?
        b.lt    recreate_chooser_bag__init_values
        /* values == [0, 1, 2, 3, ..., NUM_TETROMINOS - 1] */


        add     x20, x0, CBAG_VALUES    // x20 <- pointer to the beginning of the array's segment that remains 'not randomized'
        mov     w21, NUM_TETROMINOS     // w21 <- amount of remaining (non randomized) tetrominos

recreate_chooser_bag__randomize:
        /* Gen random number in range [0..rem_tetrominos) */
        mov     w0, 0
        mov     w1, w21
        bl      rand_gen_in_range
        /* x0 contains random index */

        // Swap a[0] with a[r]
        add     x9, x20, x0     // x9 = &a[r] = pointer to the randomly chosen element
        ldrb    w22, [x20]      // w22 = a[0]
        ldrb    w23, [x9]       // w23 = a[r]
        strb    w23, [x20]      // a[0] = a[r]
        strb    w22, [x9]       // a[r] = a[0]

        add     x20, x20, 1             // advance array pointer to the beginning of the next segment
        subs    w21, w21, 1             // decrement remaining tetrominos
        b.gt    recreate_chooser_bag__randomize // loop only if more than 1 tetromino is not yet randomized
        /* values = [randomized] */


        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 48
        ret



/*
 * Params:
 *      x0: in/out struct ChooserBagState*  <- chooser_bag_state
 * Returns:
 *      x0: u64         <- tetromino_id
 */
choose_next_tetromino:
        stp     lr, x19, [sp, -16]!

        mov     x19, x0         // x19 <- struct ChooserBagState*

        ldrb    w9, [x19, CBAG_REMAINING]               // w9 = chooser_bag_state.remaining
        cmp     w9, 0                                   // chooser_bag_state.remaining == 0 ?
        b.gt    choose_next_tetromino__dont_recreate
        /* Bag out of values, we need to recreate it */
        mov     x0, x19
        bl      recreate_chooser_bag
choose_next_tetromino__dont_recreate:

        /* Load last value and decrement remaining count */
        ldrb    w9, [x19, CBAG_REMAINING]       // x9 = chooser_bag_state.remaining
        sub     w9, w9, 1                       // x9 <- index of last element in bag
        strb    w9, [x19, CBAG_REMAINING]       // chooser_bag_state.remaining -= 1
        add     x9, x9, CBAG_VALUES             // x9 <- offset to start of array + index of last element
        add     x9, x19, x9                     // x9 <- pointer to last element of array
        ldrb    w0, [x9]                        // x0 = chooser_bag_state.values[LAST]


        ldp     lr, x19, [sp], 16
        ret



/*
 * Params:
 *      x0: i64         <- binary number
 *      x1: out u8*     <- output buffer
 *      x2: u64         <- buffer length
 * Returns:
 *      x0: u64         <- amount of digits of decimal number
 * Comments:
 *      Number is converted to binary and written to the buffer pointed by x1,
 *      where each element represents a decimal digit.
 *      Least significant digits are written to the beginning of the array.
 *      E.g.: convert 0xFF to decimal (255)
 *              -> x1 = [5, 5, 2]
 */
binary_to_decimal:
        stp     lr, x19, [sp, -48]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]

        cmp     x0, 0                   // check if x0 is negative
        cset    x22, lt                 // x22 <- is_negative(x0)
        cneg    x0, x0, lt              // x0 <- |x0|

        mov     x19, x0                 // x19 <- current dividend
        mov     x20, 10                 // x20 <- divisor (always 10)
        mov     x21, 0                  // x21 <- i (current digit, from right to left, used for indexing buffer)

binary_to_decimal__next_digit:
        cmp     x21, x2                 // check if there is buffer remaining
        b.ge    binary_to_decimal__end  // break if buffer ended

        udiv    x9, x19, x20            //  x9 <- dividend `div` 10             (quotient)
        mul     x10, x9, x20            // x10 <- (dividend `div` 10) * 10      (quotient times divisor)
        sub     x10, x19, x10           // x10 <- remainder of x19 / 10         (remainder, in range [0..9])

        strb    w10, [x1]               // store digit in buffer
        mov     x19, x9                 // use quotient as new dividend
        add     x1, x1, 1               // advance pointer to next element
        add     x21, x21, 1             // increment index
        cbnz    x19, binary_to_decimal__next_digit      // loop only if new dividend is not 0


        /* Now we push minus if original number was negative, but first we check if buffer has sufficient space */
        cbz     x22, binary_to_decimal__end
        cmp     x21, x2                 // check if there is buffer remaining
        b.ge    binary_to_decimal__end  // skip if buffer ended
        mov     w10, DIGIT_MINUS_INDEX  // w10 <- digit minus index
        strb    w10, [x1]               // store minus in buffer
        add     x21, x21, 1             // increment index

binary_to_decimal__end:
        mov     x0, x21         // x0 <- amount of digits of converted decimal number

        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 48
        ret



/*
 * Params:
 *      x0: u64         <- bottom left x coordinate        (left) 0 <= x < SCREEN_WIDTH (right)
 *      x1: u64         <- bottom left y coordinate      (bottom) 0 <= y < SCREEN_HEIGHT (top)
 *      x2: u64         <- width  =>  height = 2 * width - 1
 *      w3: u8          <- binary digit in range [0..9]
 *      w4: u32         <- color
 *      x5: out u32*    <- beginning of framebuffer
 */
draw_decimal_digit:
        stp     lr, x19, [sp, -64]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]
        stp     x24, x25, [sp, 48]

        mov     x20, x0                 // x20 <- bottom left x coordinate
        mov     x21, x1                 // x21 <- bottom left y coordinate
        mov     x22, x2                 // x22 <- segment size
        mov     w23, w4                 // w23 <- color
        mov     x24, x5                 // x24 <- beginning of framebuffer

        ldr     x19, =DIGITS_FONT       // x19 <- pointer to array of digits font
        lsl     x9, x3, 2               // Convert index (digit) to offset in bytes (u32)
        add     x19, x19, x9            // x19 <- pointer to data for our digit
        ldr     w19, [x19]              // w19 <- segment flags of our digit


        and     w9, w19, DIGIT_SEGMENT_0
        cbz     w9, draw_decimal_digit__skip_seg_0

        mov     x0, x20
        mov     x1, x21
        mov     x2, x22
        mov     w3, w23
        mov     x4, x24
        bl      draw_horizontal_line
draw_decimal_digit__skip_seg_0:


        and     w9, w19, DIGIT_SEGMENT_1
        cbz     w9, draw_decimal_digit__skip_seg_1

        mov     x0, x20
        mov     x1, x21
        mov     x2, x22
        mov     w3, w23
        mov     x4, x24
        bl      draw_vertical_line
draw_decimal_digit__skip_seg_1:


        and     w9, w19, DIGIT_SEGMENT_2
        cbz     w9, draw_decimal_digit__skip_seg_2

        add     x0, x20, x22
        sub     x0, x0, 1
        mov     x1, x21
        mov     x2, x22
        mov     w3, w23
        mov     x4, x24
        bl      draw_vertical_line
draw_decimal_digit__skip_seg_2:


        and     w9, w19, DIGIT_SEGMENT_3
        cbz     w9, draw_decimal_digit__skip_seg_3

        mov     x0, x20
        add     x1, x21, x22
        sub     x1, x1, 1
        mov     x2, x22
        mov     w3, w23
        mov     x4, x24
        bl      draw_horizontal_line
draw_decimal_digit__skip_seg_3:


        and     w9, w19, DIGIT_SEGMENT_4
        cbz     w9, draw_decimal_digit__skip_seg_4

        mov     x0, x20
        add     x1, x21, x22
        sub     x1, x1, 1
        mov     x2, x22
        mov     w3, w23
        mov     x4, x24
        bl      draw_vertical_line
draw_decimal_digit__skip_seg_4:


        and     w9, w19, DIGIT_SEGMENT_5
        cbz     w9, draw_decimal_digit__skip_seg_5

        add     x0, x20, x22
        sub     x0, x0, 1
        add     x1, x21, x22
        sub     x1, x1, 1
        mov     x2, x22
        mov     w3, w23
        mov     x4, x24
        bl      draw_vertical_line
draw_decimal_digit__skip_seg_5:


        and     w9, w19, DIGIT_SEGMENT_6
        cbz     w9, draw_decimal_digit__skip_seg_6

        mov     x0, x20
        add     x1, x21, x22
        add     x1, x1, x22
        sub     x1, x1, 2
        mov     x2, x22
        mov     w3, w23
        mov     x4, x24
        bl      draw_horizontal_line
draw_decimal_digit__skip_seg_6:


        ldp     x24, x25, [sp, 48]
        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 64
        ret



/*
 * Params:
 *      x0: u64         <- bottom left x coordinate        (left) 0 <= x < SCREEN_WIDTH (right)
 *      x1: u64         <- bottom left y coordinate      (bottom) 0 <= y < SCREEN_HEIGHT (top)
 *      x2: u64         <- width  =>  height = 2 * width - (thickness % 2)
 *      x3: u64         <- thickness
 *      w4: u8          <- binary digit in range [0..9] U { 10 (minus) }
 *      w5: u32         <- color
 *      x6: out u32*    <- beginning of framebuffer
 */
draw_decimal_digit_with_thickness:
        stp     lr, x19, [sp, -80]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]
        stp     x24, x25, [sp, 48]
        stp     x26, x27, [sp, 64]

        mov     x20, x0                 // x20 <- bottom left x coordinate
        mov     x21, x1                 // x21 <- bottom left y coordinate
        mov     w22, w5                 // w22 <- color
        mov     x23, x6                 // x23 <- beginning of framebuffer


        sub     x24, x2, 1              // x24 <- A = width - 1
        sub     x25, x3, 1              // x25 <- B = thickness - 1
        lsr     x26, x3, 1              // x26 <- C = thickness / 2
        add     x27, x24, x26           // x27 <- D = A + C

        sub     sp, sp, 8
        and     x9, x3, 0b1             // 1 if odd, 0 if even
        eor     x9, x9, 0b1             // 1 if even, 0 if odd
        add     x9, x24, x9             // x9 = A + (0|1)
        sub     x9, x9, x26             // x9 = A - C + (0|1)
        str     x9, [sp]                // [sp] = A - C + (0|1)



        ldr     x19, =DIGITS_FONT       // x19 <- pointer to array of digits font
        lsl     x9, x4, 2               // Convert index (digit) to offset in bytes (u32)
        add     x19, x19, x9            // x19 <- pointer to data for our digit
        ldr     w19, [x19]              // w19 <- segment flags of our digit





        and     w9, w19, DIGIT_SEGMENT_0
        cbz     w9, draw_decimal_digit_with_thickness__skip_seg_0

        mov     x0, x20         // x0 <- x
        mov     x1, x21         // x1 <- y
        add     x2, x20, x24    // x2 <- x + A
        add     x3, x21, x25    // x3 <- y + B
        mov     x4, x23         // x4 <- framebuffer
        mov     w5, w22         // w5 <- color
        bl      draw_filled_rectangle
draw_decimal_digit_with_thickness__skip_seg_0:


        and     w9, w19, DIGIT_SEGMENT_1
        cbz     w9, draw_decimal_digit_with_thickness__skip_seg_1

        mov     x0, x20         // x0 <- x
        mov     x1, x21         // x1 <- y
        add     x2, x20, x25    // x2 <- x + B
        add     x3, x21, x27    // x3 <- y + D
        mov     x4, x23         // x4 <- framebuffer
        mov     w5, w22         // w5 <- color
        bl      draw_filled_rectangle
draw_decimal_digit_with_thickness__skip_seg_1:


        and     w9, w19, DIGIT_SEGMENT_2
        cbz     w9, draw_decimal_digit_with_thickness__skip_seg_2

        add     x0, x20, x24    // x0 <- x + A
        sub     x0, x0, x25     // x0 <- x + A - B
        mov     x1, x21         // x1 <- y
        add     x2, x20, x24    // x2 <- x + A
        add     x3, x21, x27    // x3 <- y + D
        mov     x4, x23         // x4 <- framebuffer
        mov     w5, w22         // w5 <- color
        bl      draw_filled_rectangle
draw_decimal_digit_with_thickness__skip_seg_2:


        ldr     x9, [sp]
        add     x21, x21, x9    // y = y + (A - C + (0|1))


        and     w9, w19, DIGIT_SEGMENT_3
        cbz     w9, draw_decimal_digit_with_thickness__skip_seg_3

        mov     x0, x20         // x0 <- x
        mov     x1, x21         // x1 <- y
        add     x2, x20, x24    // x2 <- x + A
        add     x3, x21, x25    // x3 <- y + B
        mov     x4, x23         // x4 <- framebuffer
        mov     w5, w22         // w5 <- color
        bl      draw_filled_rectangle
draw_decimal_digit_with_thickness__skip_seg_3:


        and     w9, w19, DIGIT_SEGMENT_4
        cbz     w9, draw_decimal_digit_with_thickness__skip_seg_4

        mov     x0, x20         // x0 <- x
        mov     x1, x21         // x1 <- y
        add     x2, x20, x25    // x2 <- x + B
        add     x3, x21, x24    // x3 <- y + A
        add     x3, x3, x26     // x3 <- y + A + C
        mov     x4, x23         // x4 <- framebuffer
        mov     w5, w22         // w5 <- color
        bl      draw_filled_rectangle
draw_decimal_digit_with_thickness__skip_seg_4:


        and     w9, w19, DIGIT_SEGMENT_5
        cbz     w9, draw_decimal_digit_with_thickness__skip_seg_5

        add     x0, x20, x24    // x0 <- x + A
        sub     x0, x0, x25     // x0 <- x + A - B
        mov     x1, x21         // x1 <- y
        add     x2, x20, x24    // x2 <- x + A
        add     x3, x21, x24    // x3 <- y + A
        add     x3, x3, x26     // x3 <- y + A + C
        mov     x4, x23         // x4 <- framebuffer
        mov     w5, w22         // w5 <- color
        bl      draw_filled_rectangle
draw_decimal_digit_with_thickness__skip_seg_5:


        ldr     x9, [sp]
        add     x21, x21, x9    // y = y + (A - C + (0|1))


        and     w9, w19, DIGIT_SEGMENT_6
        cbz     w9, draw_decimal_digit_with_thickness__skip_seg_6

        mov     x0, x20         // x0 <- x
        mov     x1, x21         // x1 <- y
        add     x2, x20, x24    // x2 <- x + A
        add     x3, x21, x25    // x3 <- y + B
        mov     x4, x23         // x4 <- framebuffer
        mov     w5, w22         // w5 <- color
        bl      draw_filled_rectangle
draw_decimal_digit_with_thickness__skip_seg_6:

        add     sp, sp, 8

        ldp     x26, x27, [sp, 64]
        ldp     x24, x25, [sp, 48]
        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 80
        ret


/*
 * Params:
 *      x0: u64         <- bottom right x coordinate        (left) 0 <= x < SCREEN_WIDTH (right)
 *      x1: u64         <- bottom right y coordinate      (bottom) 0 <= y < SCREEN_HEIGHT (top)
 *      w2: u32         <- color
 *      x3: out u32*    <- beginning of framebuffer
 */
draw_time:
        stp     lr, x19, [sp, -16]!

        mov     x19, x3         // x19 <- framebuffer

        sub     sp, sp, STRUCT_DNI_SIZE

        str     x0, [sp, DNI_POS_X]
        str     x1, [sp, DNI_POS_Y]
        mov     x9, 5
        str     x9, [sp, DNI_MAX_DIGITS]
        mov     x9, 33
        str     x9, [sp, DNI_DIGIT_WIDTH]
        mov     x9, 8
        str     x9, [sp, DNI_DIGIT_THICKNESS]
        mov     x9, 8
        str     x9, [sp, DNI_DIGIT_SPACING]
        str     w2, [sp, DNI_COLOR]

        bl      get_time
        mov     w9, 1000
        udiv    w0, w0, w9      // w0 <- time in milliseconds




        lsl     x0, x0, 32      // x0 <- time in milliseconds   (Q32)
        udiv    x0, x0, x9      // x0 <- time in seconds        (Q32)
        // orr     x0, xzr, 1 << 29
        orr     x1, xzr, 1 << 32
        orr     x2, xzr, 1 << 30
        // orr     x3, xzr, 1 << 30
        mov     x3, 0
        bl      sine_wave_advanced
        mov     x9, 1000
        mul     x0, x0, x9      // x0 <- number between 0 and 1000 (Q32)
        asr     x0, x0, 32      // x0 <- number between 0 and 1000




        str     x0, [sp, DNI_VALUE]

        mov     x0, sp
        mov     x1, x19          // x1 <- beginning of framebuffer
        bl      draw_number

        add     sp, sp, STRUCT_DNI_SIZE

        ldp     lr, x19, [sp], 16
        ret




/*
 * Params:
 *      x0: in/out struct DrawNumberInfo*       <- draw_number_info   (consumed)
 *      x1: out u32*                            <- beginning of framebuffer
 */
draw_number:
        stp     lr, x19, [sp, -48]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]

        /* (dni.pos_x, dni.pos_y) represents the bottom right coordinate of the drawn number */

        mov     x19, x1                 // const x19 <- beginning of framebuffer
        mov     x20, x0                 // const x20 <- in/out struct DrawNumberInfo*

        ldr     x9, [x20, DNI_MAX_DIGITS]
        sub     sp, sp, x9              // Make space for digits array
        mov     x21, sp                 // x21: const u8* <- pointer to beginning of digits array

        // Convert number to decimal
        ldr     x0, [x20, DNI_VALUE]    // x0 <- number to draw
        mov     x1, x21                 // x1 <- pointer to digits array
        mov     x2, x9                  // x2 <- max digits
        bl      binary_to_decimal

        mov     x22, x0                 // x22 <- amount of digits to draw (<= max digits)

draw_number__next_digit:
        ldr     x9, [x20, DNI_POS_X]            // x9 = dni.pos_x
        ldr     x10, [x20, DNI_DIGIT_WIDTH]     // x10 = dni.digit_width
        sub     x9, x9, x10                     // x9 -= dni.digit_width <- move x coordinate left by digit width
        add     x9, x9, 1                       // x9 += 1 <- x coordinate points to bottom left coordinate of digit
        str     x9, [x20, DNI_POS_X]            // dni.pos_x = x9

        ldr     x0, [x20, DNI_POS_X]            // x0 <- x coordinate
        ldr     x1, [x20, DNI_POS_Y]            // x1 <- y coordinate
        ldr     x2, [x20, DNI_DIGIT_WIDTH]      // x2 <- digit width
        ldr     x3, [x20, DNI_DIGIT_THICKNESS]  // x3 <- thickness
        ldrb    w4, [x21]                       // w4 <- digits[i]
        ldr     w5, [x20, DNI_COLOR]            // w5 <- color
        mov     x6, x19                         // x6 <- beginning of framebuffer
        bl      draw_decimal_digit_with_thickness // draw digit

        ldr     x9, [x20, DNI_POS_X]            // x9 = dni.pos_x
        ldr     x10, [x20, DNI_DIGIT_SPACING]   // x10 = dni.digit_spacing
        sub     x9, x9, x10                     // x9 -= dni.digit_spacing <- move x by digit spacing for drawing next digit
        sub     x9, x9, 1                       // (off by one)
        str     x9, [x20, DNI_POS_X]            // dni.pos_x = x9
        add     x21, x21, 1                     // x21 = &digits[i + 1] <- pointer to next digit
        subs    x22, x22, 1                     // x22 <- decrement remaining digits and check if any remain
        b.gt    draw_number__next_digit

        /* All digits are drawn */

        ldr     x9, [x20, DNI_MAX_DIGITS]
        add     sp, sp, x9              // Pop digits array from stack

        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 48
        ret


test_binary_to_decimal:
        stp     lr, x19, [sp, -16]!


        sub     sp, sp, 4       // reserve space for 4 digits
        mov     x0, 0           // use 0 as initial number
test_binary_to_decimal__again:
        mov     x1, sp
        mov     x2, 4
        bl      binary_to_decimal

        mov     w0, 0
        ldr     w1, =TEST_BINARY_TO_DECIMAL_MAX
        bl      rand_gen_in_range
        b       test_binary_to_decimal__again
        add     sp, sp, 4


        ldp     lr, x19, [sp], 16
        ret



