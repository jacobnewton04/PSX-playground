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






