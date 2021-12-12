.global _start
.equ TIMER_LOAD, 0xFFFEC600
.equ TIMER_COUNTER, 0xFFFEC604
.equ TIMER_CONTROL, 0xFFFEC608
.equ TIMER_INTERRUPT, 0xFFFEC60C
.equ HEX0, 0xFF200020
.equ HEX4, 0xFF200030
.equ LED_MEMORY, 0xFF200000


_start:
	mov r1, #0x7 	//set auto bit, interrupt bit and enable bit
	LDR r0, [PC, #-4]
	.word 200000000	//200 mHz so count 200 million times in a second
	BL ARM_TIM_config_ASM
	
	mov r2, #0	//number to be displayed
loop:
	BL ARM_TIM_read_INT_ASM
	BL ARM_TIM_clear_INT_ASM
	cmp r0, #1	//check if interrupt req was sent
	BNE loop	//checks again if not
	
	mov r0, #1	//Coord of hex0 to be printed to
	mov r1, r2	//value to be displayed
	BL HEX_write_ASM		
	mov r0, r2
	BL write_LEDs_ASM
	addeq r2, #1	//increments value
	cmp r2, #16		//if value is 16
	movEQ r2, #0	//resets it to 0
	B loop

	
	
ARM_TIM_config_ASM:
	push {v1}
	ldr v1, =TIMER_LOAD
	str r0, [v1]
	ldr v1, =TIMER_CONTROL
	str r1, [v1]	
	pop {v1}
	BX LR
	
ARM_TIM_read_INT_ASM:
	push {v1}
	ldr v1, =TIMER_INTERRUPT
	ldr r0, [v1]
	pop {v1}
	bx lr
	
ARM_TIM_clear_INT_ASM: 
	push {v1-v2}
	ldr v1, =TIMER_INTERRUPT
	str r0, [v1]
	pop {v1-v2}
	bx lr
	
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
	
write_LEDs_ASM:
    LDR R1, =LED_MEMORY
    STR R0, [R1]
    BX  LR