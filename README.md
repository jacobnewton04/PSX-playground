# Shape Manipulator

### To run the project, do the following:
1. Open Tools -> Keyboard and Display MMIO Simulator and Connect to MIPS.
2. Open Tools -> Bitmap Display and Connect to MIPS with the following settings:
    - Unit Width in Pixels: 1
    - Unit Height in Pixels: 1
    - Display Width in Pixels: 512
    - Display Height in Pixels: 512
    - Base Address for Display: **0x10040000 (heap)**
3. Assemble (F3)
4. Run (F5)

### Interaction and Controls:
- Move the shape using WASD
- Change the shape using C, R, & L
- '1' = Red, '2' = Green, '3' = Blue, '4' = Yellow, '5' = Magenta, '6' = Cyan
- Press '+/=' to scale up, '-' to scale down
- Quit the Program using Q
