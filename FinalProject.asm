# Interactive MIPS Graphics Program
# Features: Change shapes (rectangle, circle, line) and colors
# 
# Instructions:
# 1. Connect the Bitmap Display tool (512x512, pixel size 1, base address 0x10010000)
# 2. Connect the Keyboard and Display MMIO Simulator
# 3. Run the program
# 4. Press keys to change drawing:
#    - 'r' = Rectangle
#    - 'c' = Circle  
#    - 'l' = Line
#    - '1' = Red, '2' = Green, '3' = Blue, '4' = Yellow, '5' = Magenta, '6' = Cyan

.data
    base_addr:    .word 0x10040000    # Bitmap display base address (heap)
    width:        .word 512           # Display width
    height:       .word 512           # Display height
    
    # Current settings
    current_shape: .word 0            # 0=rect, 1=circle, 2=line
    current_color: .word 0x00FF0000   # Default red
    
    # Shape parameters
    rect_x:       .word 100
    rect_y:       .word 100
    rect_w:       .word 150
    rect_h:       .word 100
    
    circle_cx:    .word 300
    circle_cy:    .word 250
    circle_r:     .word 80
    
    line_x1:      .word 50
    line_y1:      .word 400
    line_x2:      .word 450
    line_y2:      .word 400
    
    # Messages
    msg_rect:     .asciiz "Drawing Rectangle\n"
    msg_circle:   .asciiz "Drawing Circle\n"
    msg_line:     .asciiz "Drawing Line\n"
    msg_color:    .asciiz "Color changed\n"
    msg_start:    .asciiz "Interactive Graphics - Press r/c/l for shapes, 1-6 for colors\n"

.text
.globl main

main:
    # Print start message
    li $v0, 4
    la $a0, msg_start
    syscall
    
main_loop:
    # Clear screen (fill with black)
    jal clear_screen
    
    # Draw current shape
    lw $t0, current_shape
    beq $t0, 0, draw_rect
    beq $t0, 1, draw_circle
    beq $t0, 2, draw_line
    
draw_rect:
    jal draw_rectangle
    j check_input
    
draw_circle:
    jal draw_circle_shape
    j check_input
    
draw_line:
    jal draw_line_shape
    
check_input:
    # Check for keyboard input
    li $t0, 0xffff0000        # Keyboard control register
    lw $t1, 0($t0)            # Read control register
    andi $t1, $t1, 0x0001     # Check if key pressed
    beqz $t1, main_loop       # No key pressed, loop
    
    # Read the key
    lw $a0, 4($t0)            # Read from data register
    
    # Check which key was pressed
    li $t2, 'r'
    beq $a0, $t2, set_rect
    li $t2, 'c'
    beq $a0, $t2, set_circle
    li $t2, 'l'
    beq $a0, $t2, set_line
    
    # Check color keys
    li $t2, '1'
    beq $a0, $t2, set_red
    li $t2, '2'
    beq $a0, $t2, set_green
    li $t2, '3'
    beq $a0, $t2, set_blue
    li $t2, '4'
    beq $a0, $t2, set_yellow
    li $t2, '5'
    beq $a0, $t2, set_magenta
    li $t2, '6'
    beq $a0, $t2, set_cyan
    
    j main_loop

# Shape setters
set_rect:
    li $t0, 0
    sw $t0, current_shape
    li $v0, 4
    la $a0, msg_rect
    syscall
    j main_loop

set_circle:
    li $t0, 1
    sw $t0, current_shape
    li $v0, 4
    la $a0, msg_circle
    syscall
    j main_loop

set_line:
    li $t0, 2
    sw $t0, current_shape
    li $v0, 4
    la $a0, msg_line
    syscall
    j main_loop

# Color setters
set_red:
    li $t0, 0x00FF0000
    sw $t0, current_color
    li $v0, 4
    la $a0, msg_color
    syscall
    j main_loop

set_green:
    li $t0, 0x0000FF00
    sw $t0, current_color
    li $v0, 4
    la $a0, msg_color
    syscall
    j main_loop

set_blue:
    li $t0, 0x000000FF
    sw $t0, current_color
    li $v0, 4
    la $a0, msg_color
    syscall
    j main_loop

set_yellow:
    li $t0, 0x00FFFF00
    sw $t0, current_color
    li $v0, 4
    la $a0, msg_color
    syscall
    j main_loop

set_magenta:
    li $t0, 0x00FF00FF
    sw $t0, current_color
    li $v0, 4
    la $a0, msg_color
    syscall
    j main_loop

set_cyan:
    li $t0, 0x0000FFFF
    sw $t0, current_color
    li $v0, 4
    la $a0, msg_color
    syscall
    j main_loop

# Clear screen function
clear_screen:
    lw $t0, base_addr
    li $t1, 0x00000000        # Black color
    li $t2, 262144            # 512*512 pixels
    
clear_loop:
    sw $t1, 0($t0)
    addi $t0, $t0, 4
    addi $t2, $t2, -1
    bgtz $t2, clear_loop
    jr $ra

# Draw rectangle function
draw_rectangle:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    lw $t0, rect_y            # y counter
    lw $t1, rect_h
    add $t1, $t1, $t0         # y end
    
rect_y_loop:
    bge $t0, $t1, rect_done
    lw $t2, rect_x            # x counter
    lw $t3, rect_w
    add $t3, $t3, $t2         # x end
    
rect_x_loop:
    bge $t2, $t3, rect_y_next
    
    # Draw pixel at (t2, t0)
    move $a0, $t2
    move $a1, $t0
    lw $a2, current_color
    
    addi $sp, $sp, -12
    sw $t0, 0($sp)
    sw $t1, 4($sp)
    sw $t2, 8($sp)
    jal draw_pixel
    lw $t2, 8($sp)
    lw $t1, 4($sp)
    lw $t0, 0($sp)
    addi $sp, $sp, 12
    
    addi $t2, $t2, 1
    j rect_x_loop
    
rect_y_next:
    addi $t0, $t0, 1
    j rect_y_loop
    
rect_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Draw circle function
draw_circle_shape:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    lw $t0, circle_cy         # y start
    lw $t1, circle_r
    sub $t0, $t0, $t1
    lw $t2, circle_cy
    add $t2, $t2, $t1         # y end
    
circle_y_loop:
    bge $t0, $t2, circle_done
    lw $t3, circle_cx         # x start
    lw $t4, circle_r
    sub $t3, $t3, $t4
    lw $t5, circle_cx
    add $t5, $t5, $t4         # x end
    
circle_x_loop:
    bge $t3, $t5, circle_y_next
    
    # Check if point is in circle: (x-cx)^2 + (y-cy)^2 <= r^2
    lw $t6, circle_cx
    sub $t6, $t3, $t6         # dx
    mul $t6, $t6, $t6         # dx^2
    
    lw $t7, circle_cy
    sub $t7, $t0, $t7         # dy
    mul $t7, $t7, $t7         # dy^2
    
    add $t6, $t6, $t7         # dx^2 + dy^2
    lw $t7, circle_r
    mul $t7, $t7, $t7         # r^2
    
    bgt $t6, $t7, circle_skip
    
    # Draw pixel
    move $a0, $t3
    move $a1, $t0
    lw $a2, current_color
    
    addi $sp, $sp, -24
    sw $t0, 0($sp)
    sw $t1, 4($sp)
    sw $t2, 8($sp)
    sw $t3, 12($sp)
    sw $t4, 16($sp)
    sw $t5, 20($sp)
    jal draw_pixel
    lw $t5, 20($sp)
    lw $t4, 16($sp)
    lw $t3, 12($sp)
    lw $t2, 8($sp)
    lw $t1, 4($sp)
    lw $t0, 0($sp)
    addi $sp, $sp, 24
    
circle_skip:
    addi $t3, $t3, 1
    j circle_x_loop
    
circle_y_next:
    addi $t0, $t0, 1
    j circle_y_loop
    
circle_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Draw line function (Bresenham's algorithm simplified)
draw_line_shape:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    lw $t0, line_x1
    lw $t1, line_y1
    lw $t2, line_x2
    lw $t3, line_y2
    
line_loop:
    # Draw current pixel
    move $a0, $t0
    move $a1, $t1
    lw $a2, current_color
    
    addi $sp, $sp, -16
    sw $t0, 0($sp)
    sw $t1, 4($sp)
    sw $t2, 8($sp)
    sw $t3, 12($sp)
    jal draw_pixel
    lw $t3, 12($sp)
    lw $t2, 8($sp)
    lw $t1, 4($sp)
    lw $t0, 0($sp)
    addi $sp, $sp, 16
    
    # Check if done
    beq $t0, $t2, line_check_y
    
    # Increment x
    blt $t0, $t2, line_inc_x
    addi $t0, $t0, -1
    j line_loop
line_inc_x:
    addi $t0, $t0, 1
    j line_loop
    
line_check_y:
    beq $t1, $t3, line_done
    blt $t1, $t3, line_inc_y
    addi $t1, $t1, -1
    j line_loop
line_inc_y:
    addi $t1, $t1, 1
    j line_loop
    
line_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Draw pixel function
# $a0 = x, $a1 = y, $a2 = color
draw_pixel:
    lw $t0, width
    mul $t1, $a1, $t0         # y * width
    add $t1, $t1, $a0         # + x
    sll $t1, $t1, 2           # * 4 (bytes per pixel)
    lw $t0, base_addr
    add $t1, $t1, $t0         # + base address
    sw $a2, 0($t1)            # Store color
    jr $ra