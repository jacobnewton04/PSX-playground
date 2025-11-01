; psxlog.asm — logo playground for PCSX-Redux
; assemble: armips psxlog.asm
; output:   psxlogo.bin @ 0x80010000

.psx
.create "psxlogo.bin", 0x80010000

.org 0x80010000

; --------------------------------------------
; constants / addresses
; --------------------------------------------
GP0         equ 0x1F801810          ; GPU command port
GP1         equ 0x1F801814          ; GPU control port
PAD_BUFSZ   equ 0x22                ; 34 bytes

; --------------------------------------------
; entry
; --------------------------------------------
Start:
    ; $a0 = 0x1F800000 (I/O base)
    lui     $a0, 0x1F80

    ; ------------ GPU init -------------
    ; 1) enable / reset GPU
    lui     $t0, 0x0300             ; 0x03000000 -> GP1
    sw      $t0, 0x1814($a0)        ; GP1

    ; 2) display mode: NTSC, 320x240, 15bpp
    li      $t0, 0x08000001
    sw      $t0, 0x1814($a0)

    ; 3) horizontal display range
    li      $t0, 0x06C60260
    sw      $t0, 0x1814($a0)

    ; 4) vertical display range
    li      $t0, 0x07042018
    sw      $t0, 0x1814($a0)

    ; 5) drawing area / mode
    li      $t0, 0xE1000508         ; draw to display, 15bpp
    sw      $t0, 0x1810($a0)
    li      $t0, 0xE3000000         ; draw area top-left (0,0)
    sw      $t0, 0x1810($a0)
    li      $t0, 0xE403BD3F         ; draw area bottom-right (319,239)
    sw      $t0, 0x1810($a0)
    li      $t0, 0xE5000000         ; draw offset (0,0)
    sw      $t0, 0x1810($a0)

    ; --------------------------------------------
    ; Pad init using BIOS B-table
    ; a0=buf1, a1=sz1, a2=buf2, a3=sz2
    ; function index in $t1, then syscall 0xB0
    ; --------------------------------------------
    la      $a0, PadBuf1
    li      $a1, PAD_BUFSZ
    la      $a2, PadBuf2
    li      $a3, PAD_BUFSZ
    li      $t1, 0x12               ; InitPad
    syscall 0xB0

    li      $t1, 0x13               ; StartPad
    syscall 0xB0

    li      $a0, 0                  ; don't auto-clear
    li      $t1, 0x5B               ; ChangeClearPad
    syscall 0xB0

    ; --------------------------------------------
    ; initial state
    ; --------------------------------------------
    li      $t0, 140
    sw      $t0, LogoX
    li      $t0, 80
    sw      $t0, LogoY
    sw      $zero, ColorIndex

; --------------------------------------------
; main loop
; --------------------------------------------
MainLoop:
    ; read pad: we must load through a register first
    la      $t9, PadBuf1
    lh      $t0, 2($t9)             ; t0 = buttons (active LOW)

    ; ----- RIGHT (bit 5) -----
    andi    $t1, $t0, 0x0020
    bne     $t1, $zero, CheckLeft   ; if bit=1 -> not pressed
    nop
    lw      $t2, LogoX
    addiu   $t2, $t2, 2
    sw      $t2, LogoX

CheckLeft:
    ; ----- LEFT (bit 7) -----
    andi    $t1, $t0, 0x0080
    bne     $t1, $zero, CheckDown
    nop
    lw      $t2, LogoX
    addiu   $t2, $t2, -2
    sw      $t2, LogoX

CheckDown:
    ; ----- DOWN (bit 6) -----
    andi    $t1, $t0, 0x0040
    bne     $t1, $zero, CheckUp
    nop
    lw      $t2, LogoY
    addiu   $t2, $t2, 2
    sw      $t2, LogoY

CheckUp:
    ; ----- UP (bit 4) -----
    andi    $t1, $t0, 0x0010
    bne     $t1, $zero, CheckCross
    nop
    lw      $t2, LogoY
    addiu   $t2, $t2, -2
    sw      $t2, LogoY

CheckCross:
    ; Cross / X = bit 14, active LOW
    andi    $t1, $t0, 0x4000
    bne     $t1, $zero, DrawFrame   ; if not pressed -> skip color change
    nop

    ; pressed -> advance color 0..3
    lw      $t2, ColorIndex
    addiu   $t2, $t2, 1
    andi    $t2, $t2, 3
    sw      $t2, ColorIndex

WaitRelease:
    ; poll until button released
    la      $t9, PadBuf1
    lh      $t0, 2($t9)
    andi    $t1, $t0, 0x4000
    beq     $t1, $zero, WaitRelease
    nop

; --------------------------------------------
; draw frame
; --------------------------------------------
DrawFrame:
    ; clear VRAM: GP0(02h): color, xy, wh
    li      $t3, GP0
    li      $t4, 0x02000000
    ori     $t4, $t4, 0x2020        ; dark gray
    sw      $t4, 0($t3)             ; cmd
    sw      $zero, 0($t3)           ; xy = 0,0
    li      $t4, (320) | (240 << 16)
    sw      $t4, 0($t3)             ; wh

    ; get logo position
    lw      $t5, LogoX
    lw      $t6, LogoY

    ; pick current BGR color
    lw      $t7, ColorIndex
    sll     $t7, $t7, 2             ; index * 4
    la      $t8, LogoColors
    addu    $t8, $t8, $t7
    lw      $t9, 0($t8)             ; BGR

    ; ------------- rect 1 -------------
    li      $t4, 0x60000000
    or      $t4, $t4, $t9
    sw      $t4, 0($t3)             ; cmd+color

    sll     $t1, $t6, 16            ; y << 16
    or      $t1, $t1, $t5           ; x | (y<<16)
    sw      $t1, 0($t3)             ; xy

    li      $t1, 28 | (80 << 16)    ; w=28, h=80
    sw      $t1, 0($t3)             ; wh

    ; ------------- rect 2 -------------
    li      $t4, 0x60000000
    or      $t4, $t4, $t9
    sw      $t4, 0($t3)

    addiu   $t0, $t5, 20            ; x2 = x + 20
    addiu   $t1, $t6, 50            ; y2 = y + 50
    sll     $t1, $t1, 16
    or      $t1, $t1, $t0
    sw      $t1, 0($t3)

    li      $t1, 20 | (20 << 16)    ; w=20, h=20
    sw      $t1, 0($t3)

; --------------------------------------------
; delay
; --------------------------------------------
DelayLoop:
    li      $t0, 30000
DL1:
    addiu   $t0, $t0, -1
    bgtz    $t0, DL1
    nop

    j       MainLoop
    nop

; --------------------------------------------
; data section
; --------------------------------------------
.align 4
PadBuf1:
    .fill PAD_BUFSZ, 0
PadBuf2:
    .fill PAD_BUFSZ, 0

LogoX:      .word 0
LogoY:      .word 0
ColorIndex: .word 0

LogoColors:
    .word 0x000000FF
    .word 0x0000FF00
    .word 0x00FF0000
    .word 0x00FFFFFF

.close
