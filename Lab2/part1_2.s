.global _start

.equ SW_MEMORY, 0xFF200040
.equ LED_MEMORY, 0xFF200000
.equ HEX0, 0xFF200020
.equ HEX4, 0xFF200030
.equ PUSH, 0xFF200050

_start:
	mov r0, #0xF0

	BL read_slider_switches_ASM
	mov v1, r0	//holds switch info
	
	BL write_LEDs_ASM	//writes switches to led
	
	BL read_PB_edgecp_ASM
	mov v6, r0	//holds edgecp info
	BL PB_clear_edgecp_ASM
	
	MOV r0, v6
	AND r1, v1, #0xF //sets r0 to value write to
	BL HEX_write_ASM
	
	ANDS v6, v1, #0x200	//asserts switch 9
	movgt r0, #0xFF	//Sets r0 so clear clears hexes 0-3
	BLGT HEX_clear_ASM
	movle r0, #0xF0
	BLLE HEX_flood_ASM

	
	B _start
	
read_PB_data_ASM:
	push {v1}
	ldr v1, =PUSH
	ldr r0, [v1]
	pop {v1}
	BX LR	

read_PB_edgecp_ASM:
	push {v1}
	ldr v1, =PUSH
	ldr r0, [v1, #0xC]
	pop {v1}
	BX LR

PB_clear_edgecp_ASM:
	push {v1-v2}
	ldr v1, =PUSH
	ldr v2, [v1, #0xC]
	str v2, [v1, #0xC]
	pop {v1-v2}
	BX LR
	
enable_PB_INT_ASM:
	push {v1-v3}
	ldr v1, =PUSH	//address of button
	ldr v2, [v1, #8]//loads interruptmask register
	mov v3, #1		//index and clear value
	
	TST r0, v3		//check if enable button 0
	ORRGT v2, v3
	lsl v3, #1
	
	TST r0, v3		//check if enable button 1
	ORRGT v2, v3
	lsl v3, #1
	
	TST r0, v3		//check if enable button 2
	ORRGT v2, v3
	lsl v3, #1
	
	TST r0, v3		//check if enable button 3
	ORRGT v2, v3

	str v2, [v1]
	pop {v1-v3}
	BX LR
	
disable_PB_INT_ASM:
	push {v1-v3}
	ldr v1, =PUSH	//address of button
	ldr v2, [v1, #8]//loads interruptmask register
	mov v3, #1		//index and clear value
	
	TST r0, v3		//check if enable button 0
	BICGT v2, v3
	lsl v3, #1
	
	TST r0, v3		//check if enable button 1
	BICGT v2, v3
	lsl v3, #1
	
	TST r0, v3		//check if enable button 2
	BICGT v2, v3
	lsl v3, #1
	
	TST r0, v3		//check if enable button 3
	BICGT v2, v3

	str v2, [v1]
	pop {v1-v3}
	BX LR
	
HEX_clear_ASM:
	push {v1-v4}
	ldr v1, =HEX0
	ldr v2, [v1]
	mov v3, #1
	mov v4, #0xFF
	TST r0, v3		//Checks if hex0 must be cleared
	BICGT v2, v4 	//NotAND, clears the hex0 bits
	
	lsl v3, #1
	lsl v4, #8
	TST r0, v3		//Checks if hex1 must be cleared
	BICGT v2, v4 	//NotAND, clears the hex1 bits
	
	lsl v3, #1
	lsl v4, #8
	TST r0, v3		//Checks if hex2 must be cleared
	BICGT v2, v4 	//NotAND, clears the hex2 bits
	
	lsl v3, #1
	lsl v4, #8
	TST r0, v3		//Checks if hex3 must be cleared
	BICGT v2, v4 	//NotAND, clears the hex3 bits
	
	str v2, [v1]
	
	ldr v1, =HEX4
	ldr v2, [v1]
	
	lsl v3, #1
	lsr v4, #24
	TST r0, v3		//Checks if hex4 must be cleared
	BICGT v2, v4 	//NotAND, clears the hex4 bits
	
	lsl v3, #1
	lsl v4, #8
	TST r0, v3		//Checks if hex5 must be cleared
	BICGT v2, v4 	//NotAND, clears the hex5 bits
	
	str v2, [v1]
	
	pop {v1-v4}
	BX LR
	
HEX_flood_ASM:
	push {v1-v4}
	ldr v1, =HEX0
	ldr v2, [v1]
	mov v3, #1
	mov v4, #0xFF
	TST r0, v3		//Checks if hex0 must be cleared
	ORRGT v2, v4 	//NotAND, floods the hex0 bits
	
	lsl v3, #1
	lsl v4, #8
	TST r0, v3		//Checks if hex1 must be cleared
	ORRGT v2, v4 	//NotAND, clears the hex1 bits
	
	lsl v3, #1
	lsl v4, #8
	TST r0, v3		//Checks if hex2 must be cleared
	ORRGT v2, v4 	//NotAND, clears the hex2 bits
	
	lsl v3, #1
	lsl v4, #8
	TST r0, v3		//Checks if hex3 must be cleared
	ORRGT v2, v4 	//NotAND, clears the hex3 bits
	
	str v2, [v1]
	
	ldr v1, =HEX4
	ldr v2, [v1]
	
	lsl v3, #1
	lsr v4, #24
	TST r0, v3		//Checks if hex4 must be cleared
	ORRGT v2, v4 	//NotAND, clears the hex4 bits
	
	lsl v3, #1
	lsl v4, #8
	TST r0, v3		//Checks if hex5 must be cleared
	ORRGT v2, v4 	//NotAND, clears the hex5 bits
	
	str v2, [v1]
	
	pop {v1-v4}
	BX LR
	
HEX_write_ASM:
	push {v1-v5}
	ldr v1, =HEX0
	ldr v2, [v1]
	mov v3, #1
	
	cmp R1, #0
	moveq v4, #0x3F
	cmp R1, #1
	moveq v4, #6
	cmp R1, #2
	moveq v4, #0x5B
	cmp R1, #3
	moveq v4, #0x4F
	cmp R1, #4
	moveq v4, #0x66
	cmp R1, #5
	moveq v4, #0x6D
	cmp R1, #6
	moveq v4, #0x7D
	cmp R1, #7
	moveq v4, #0x07
	cmp R1, #8
	moveq v4, #0x7F
	cmp R1, #9
	moveq v4, #0x6F
	cmp R1, #0xA
	moveq v4, #0x77
	cmp R1, #11
	moveq v4, #0x7c
	cmp R1, #0xC
	moveq v4, #0x39
	cmp R1, #0xD
	moveq v4, #0x5E
	cmp R1, #0xE
	moveq v4, #0x79
	cmp R1, #0xF
	moveq v4, #0x71
	
	mov v5, #0xFF
	TST r0, v3		//Checks if hex0 must be cleared
	BICGT v2, v5	// clears hex0 bits
	ORRGT v2, v4 	//NotAND, writes to the hex0 bits
	
	lsl v3, #1
	lsl v4, #8
	lsl v5, #8
	TST r0, v3		//Checks if hex1 must be cleared
	BICGT v2, v5	//clears hex1 bits
	ORRGT v2, v4 	//NotAND, writes to the hex1 bits
	
	lsl v3, #1
	lsl v4, #8
	lsl v5, #8
	TST r0, v3		//Checks if hex2 must be cleared
	BICGT v2, v5	//clears hex2 bits
	ORRGT v2, v4 	//NotAND, clears the hex2 bits
	
	lsl v3, #1
	lsl v4, #8
	lsl v5, #8
	TST r0, v3		//Checks if hex3 must be cleared
	BICGT v2, v5	//clears hex3 bits
	ORRGT v2, v4 	//NotAND, clears the hex3 bits
	
	str v2, [v1]
	
	ldr v1, =HEX4
	ldr v2, [v1]
	
	lsl v3, #1
	lsr v4, #24
	lsr v5, #24
	TST r0, v3		//Checks if hex4 must be cleared
	BICGT v2, v5	//clears hex4 bits
	ORRGT v2, v4 	//NotAND, clears the hex4 bits
	
	lsl v3, #1
	lsl v4, #8
	lsl v5, #8
	TST r0, v3		//Checks if hex5 must be cleared
	BICGT v2, v5	//clears hex5 bits
	ORRGT v2, v4 	//NotAND, clears the hex5 bits
	
	str v2, [v1]
	
	pop {v1-v5}
	BX LR
	
read_slider_switches_ASM:
    LDR R1, =SW_MEMORY
    LDR R0, [R1]
    BX  LR
	
write_LEDs_ASM:
    LDR R1, =LED_MEMORY
    STR R0, [R1]
    BX  LR
	
end:
	b end
	