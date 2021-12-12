.global _start
.equ SW_MEMORY, 0xFF200040
.equ LED_MEMORY, 0xFF200000
_start:
	
	BL read_slider_switches_ASM
	BL write_LEDs_ASM
	B _start
/* The EQU directive gives a symbolic name to a numeric constant,
a register-relative value or a PC-relative value. */
read_slider_switches_ASM:
    LDR R1, =SW_MEMORY
    LDR R0, [R1]
    BX  LR
	
write_LEDs_ASM:
    LDR R1, =LED_MEMORY
    STR R0, [R1]
    BX  LR