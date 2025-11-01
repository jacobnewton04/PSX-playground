; psxlogo_exe.asm
; assemble: armips psxlogo_exe.asm
; output:   psxlogo.exe
; load @ 0x80010000, entry @ 0x80010000

.psx
.create "psxlogo.exe", 0

; -------------------------------------------------
; PS-X EXE header (0x800 bytes total)
; -------------------------------------------------
.org 0x000
.db "PS-X EXE", 0x00          ; magic
.fill 0x10 - ., 0x00          ; pad to 0x10

.org 0x010                    ; initial PC / entry
.dw 0x80010000

.org 0x018                    ; TEXT load address
.dw 0x80010000

.org 0x01C                    ; TEXT size (filled at end)
.dw CodeEnd - CodeStart

.org 0x030                    ; initial SP
.dw 0x801FFFF0

; rest of header is fine as zero
.org 0x800                    ; code starts on 2048-byte boundary

; -------------------------------------------------
; program body
; -------------------------------------------------
CodeStart:

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
    ; read pad: load label -> reg, then halfword
    la      $t9, PadBuf1
    lh      $t0, 2($t9)             ; t0 = buttons (active LOW)
    nop                             ; load delay

    ; ----- RIGHT (bit 5) -----
    andi    $t1, $t0, 0x0020
    bne     $t1, $zero, CheckLeft   ; if bit=1 -> not pressed
    nop
    lw      $t2, LogoX
    nop                             ; load delay
    addiu   $t2, $t2, 2
    sw      $t2, LogoX

CheckLeft:
    ; ----- LEFT (bit 7) -----
    andi    $t1, $t0, 0x0080
    bne     $t1, $zero, CheckDown
    nop
    lw      $t2, LogoX
    nop                             ; load delay
    addiu   $t2, $t2, -2
    sw      $t2, LogoX

CheckDown:
    ; ----- DOWN (bit 6) -----
    andi    $t1, $t0, 0x0040
    bne     $t1, $zero, CheckUp
    nop
    lw      $t2, LogoY
    nop                             ; load delay
    addiu   $t2, $t2, 2
    sw      $t2, LogoY

CheckUp:
    ; ----- UP (bit 4) -----
    andi    $t1, $t0, 0x0010
    bne     $t1, $zero, CheckCross
    nop
    lw      $t2, LogoY
    nop                             ; load delay
    addiu   $t2, $t2, -2
    sw      $t2, LogoY

CheckCross:
    ; Cross / X = bit 14, active LOW
    andi    $t1, $t0, 0x4000
    bne     $t1, $zero, DrawFrame   ; if not pressed -> skip color change
    nop

    ; pressed -> advance color 0..3
    lw      $t2, ColorIndex
    nop                             ; load delay
    addiu   $t2, $t2, 1
    andi    $t2, $t2, 3
    sw      $t2, ColorIndex

WaitRelease:
    ; poll until button released
    la      $t9, PadBuf1
    lh      $t0, 2($t9)
    nop                             ; load delay
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
    nop                             ; load delay
    lw      $t6, LogoY
    nop                             ; load delay

    ; pick current BGR color
    lw      $t7, ColorIndex
    nop                             ; load delay
    sll     $t7, $t7, 2             ; index * 4
    la      $t8, LogoColors
    addu    $t8, $t8, $t7
    lw      $t9, 0($t8)             ; BGR
    nop                             ; load delay

    ; ------------- rect 1 -------------
    li      $t4, 0x60000000
    or      $t4, $t4, $t9
    sw      $t4, 0($t3)
