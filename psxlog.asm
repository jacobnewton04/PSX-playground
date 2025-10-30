.psx
.create "psxlogo.bin", 0x80010000

.org 0x80010000
.set noreorder

; --------------------------------------------
; Constants / Addresses
; --------------------------------------------

GPU_BASE equ 0x1F800000     ; base
GP0 equ 0x1F801810          ; GPU command port
GP1 equ 0x1F801814          ; GPU control port

PAD_BUFSZ equ 0x22          ; 34 bytes per documentation

; --------------------------------------------
; start
; --------------------------------------------
Start:
    lui $a0, 0x1F80

    ; -- GPU init ---------------------------
    ; enable display
    lui $t0, 0x300
    sw 0x1814($a0)

    li $t0, 0x08000001      ; GP1(08h) display mode: NTSC, 320x240, 15-bit
    sw $t0, 0x1814($a0)

    ; horizontal display range -- 0x206..0xC60 - standard value
    li $t0, 0x06C60260
    sw $t0, 0x1814($a0)

    ; vertical display range
    li $t0, 0x07042018
    sw $t0, 0x1814($a0)

    ; drawing area and mode
    li $t0, 0xE1000508      ; draw to display, 15bpp
    sw $t0, 0x1810($a0)
    li $t0, 0xE3000000      ; draw area top-left = (0,0)
    sw $t0, 0x1810($a0)
    li $t0, 0xE403BD3F      ; draw area bottom-right = (319, 239)
    sw $t0, 0x1810($a0)
    li $t0, 0xE5000000      ; draw offset = (0,0)
    sw $t0, 0x1810($a0)

    ; --------------------------------------------
    ; pad setup: InitPad(buf1,22h,buf2,22h); StartPad(); ChangeClearPad();
    ; B-table calls: put function index in r9, syscall 0xB0 
    ; --------------------------------------------
    la $a0, PadBuf1             ; buf1
    li $a1, PAD_BUFSZ
    la $a2, PadBuf2             ; buf2
    li $a3 PAD_BUFSZ
    li $t1, 0x12                ; B(12h) = InitPad
    syscall 0xB0

    li $t1, 0x13                ; B(13h) = StartPad
    syscall 0xB0

    li $a0, 0                   ; don't auto-clear pad data
    li $t1, 0x5B                ; B(5Bh) = ChangeClearPad(int)
    syscall 0xB0

    ; --------------------------------------------
    ; initial state
    ; --------------------------------------------
    li $t0, 140                 ; start X
    sw $t0, LogoX               
    li $t0, 80                  ; start Y
    sw $t0, LogoY
    li $t0, 0
    sw $t0, ColorIndex

MainLoop:
    ;----- read pad --------------------------------
    ; pad layout after InitPad/StartPad
    ; [0] status, [1] id, [2..3] = 16-bit buttons, active LOW
    
    lh $t0, 2(PadBuf1)          ; t0 = buttons (low = pressed=0)

    ; D-Pad bits (active low)
    ; bit 4=up, 5=right, 6=down, 7=left - low when pressed
    ; move right
    andi $t1, $t0, 0x0020
    bne $t1, $zero, CheckLeft
    nop
    lw $t2, LogoX
    addiu $t2, $t2, 2
    sw $t2, LogoX

CheckLeft:
    andi $t1, $t0, 0x0080
    bne $t1, $zero, CheckDown
    nop
    lw $t2, LogoX
    addiu $t2, $t2, -2
    sw $t2, LogoX

CheckDown:
    andi $t1, $t0, 0x0040
    bne $t1, $zero, CheckUp
    nop
    lw $t2, LogoY
    addiu $t2, $t2, 2
    sw $t2, LogoY

CheckUp:
    andi $t1, $t0, 0x0010
    bne $t1, $zero, CheckCross
    nop
    lw $t2, LogoY
    addiu $t2, $t2, -2
    sw $t2, LogoY

CheckCross
    ; Cross = bit14, active low
    andi $t1, $t0, 0x4000
    bne $t1, $t0, DrawFrame         ; not pressed
    nop
    ; pressed -> advance color
    lw $t2, ColorIndex
    addiu $t2, $t2, 1
    andi $t2, $t2, 3                ; wrap 0...3
    sw $t2, ColorIndex

WaitRelease:
    lh $t0, 2(PadBuf1)
    andi $t1, $t0, 0x4000
    beq $t1, $zero, WaitRelease
    nop

DrawFrame:
    ;------------- clear screen (VRAM fill) -------
    ; GP0(02h): color, then XY, then WH
    li $t3, GP0
    li $t4, 0x02000000              ; fill dark grey
    ori $t4, $t4, 0x2020            ; B=0x20, G=0x20, R=0x20
    sw $t4, 0($t3)
    sw $zero, 0($t3)                ; x=0, y=0
    li $t4, (320) | (240 << 16)
    sw $t4, 0($t3)

    ; get current logo position
    lw $t5, LogoX
    lw $t6, LogoY

    ; pick current color (BGR)
    lw $t7, ColorIndex
    sll $t7, $t7, 2
    la $t8, LogoColors
    addu $t8, $t8, $t7
    lw $t9, 0($t8)                  ; t9 = BGR color

    ; draw 'logo'
    ; rect 1
    li $t4, 0x60000000
    or $t4, $t4, $t9
    sw $t4, 0($t3)
    ; pos = (x,y)
    sll $t1, $t6, 16
    or $t1, $t1, $t5
    sw $t1, 0($t3)
    ; size = (w=28, h=80)
    li $t1, 28 | (80 << 16)
    sw $t1, 0($t3)

    ; rect 2
    li $t4, 0x60000000
    or $t4, $t4, $t9
    sw $t4, 0($t3)
    addiu $t0, $t5, 20
    addiu $t1, $t6, 50
    sll $t1, $t1, 16
    or $t1, $t1, $t0
    sw $t1, 0($t3)
    
DelayLoop:
    li $t0, 30000
DL1:
    addiu $t0, $t0, -1
    bgtz $t0, DL1
    nop

    j MainLoop
    nop

; --------------------------------------------
; data
; --------------------------------------------
.align 4
PadBuf1: .space PAD_BUFSZ
PadBuf2: .space PAD_BUFSZ

LogoX: .word 0
LogoY: .word 0
ColorIndex: .word 0

LogoColors:
    .word 0x000000FF
    .word 0x0000FF00
    .word 0x00FF0000
    .word 0x00FFFFFF

.close






