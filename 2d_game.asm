# --------------------------------------------
# 2D INTERACTIVE PROGRAM (FULLY WORKING)
# --------------------------------------------

.data
    frameBuffer: .space 0x80000      # 512 * 256 * 4

    player_x:   .word 200
    player_y:   .word 120
    player_size:.word 10

.text
main:
    # Framebuffer base pointer
    la   $s0, frameBuffer

main_loop:
    jal  clear_screen
    jal  read_keyboard
    jal  draw_player
    jal  delay
    j    main_loop


# --------------------------------------------
# CLEAR SCREEN
# --------------------------------------------
clear_screen:
    la  $t0, frameBuffer
    li  $t1, 131072              # 512 * 256
    li  $t2, 0x00000000          # black

clear_loop:
    beq $t1, $zero, clear_done
    sw  $t2, 0($t0)
    addi $t0, $t0, 4
    addi $t1, $t1, -1
    j clear_loop

clear_done:
    jr $ra


# --------------------------------------------
# READ KEYBOARD (WASD)
# Requires MMIO Keyboard Tool to be open!!
# --------------------------------------------
read_keyboard:
    # Check if key available
    lw  $t1, 0xFFFF0004          # status register
    beq $t1, $zero, no_key       # no key pressed

    # Read ASCII key
    lw  $t0, 0xFFFF0008

    # Load current position
    lw  $t3, player_x
    lw  $t4, player_y

    # Movement keys
    li  $t5, 119                 # 'w'
    beq $t0, $t5, move_up

    li  $t5, 97                  # 'a'
    beq $t0, $t5, move_left

    li  $t5, 115                 # 's'
    beq $t0, $t5, move_down

    li  $t5, 100                 # 'd'
    beq $t0, $t5, move_right

    j no_key


move_up:
    addi $t4, $t4, -3
    sw   $t4, player_y
    j    no_key

move_down:
    addi $t4, $t4, 3
    sw   $t4, player_y
    j    no_key

move_left:
    addi $t3, $t3, -3
    sw   $t3, player_x
    j    no_key

move_right:
    addi $t3, $t3, 3
    sw   $t3, player_x
    j    no_key

no_key:
    jr $ra


# --------------------------------------------
# DRAW PLAYER
# --------------------------------------------
draw_player:
    lw  $t0, player_x
    lw  $t1, player_y
    lw  $t2, player_size
    li  $t3, 0x00FF0000      # red

    move $a0, $t0            # x
    move $a1, $t1            # y
    move $a2, $t2            # width
    move $a3, $t2            # height
    move $t9, $t3            # color

    jal  draw_rect
    jr   $ra


# --------------------------------------------
# DRAW RECTANGLE (x=a0, y=a1, w=a2, h=a3, color=t9)
# --------------------------------------------
draw_rect:
    mul $t0, $a1, 512        # row offset = y * 512
    add $t0, $t0, $a0        # + x
    sll $t0, $t0, 2          # *4 bytes per pixel
    add $t0, $t0, $s0        # add framebuffer base

    move $t1, $a3            # height counter

row_loop:
    beq $t1, $zero, rect_done

    move $t3, $t0            # start of row pointer
    move $t2, $a2            # width counter

col_loop:
    beq $t2, $zero, next_row
    sw  $t9, 0($t3)
    addi $t3, $t3, 4
    addi $t2, $t2, -1
    j col_loop

next_row:
    addi $t0, $t0, 2048      # next row (512 * 4)
    addi $t1, $t1, -1
    j row_loop

rect_done:
    jr $ra


# --------------------------------------------
# DELAY
# --------------------------------------------
delay:
    li  $t0, 40000
delay_loop:
    addi $t0, $t0, -1
    bgtz $t0, delay_loop
    jr $ra
