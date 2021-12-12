.global _start

.equ TIMER_LOAD, 0xFFFEC600
.equ TIMER_COUNTER, 0xFFFEC604
.equ TIMER_CONTROL, 0xFFFEC608
.equ TIMER_INTERRUPT, 0xFFFEC60C
.equ SW_MEMORY, 0xFF200040
.equ LED_MEMORY, 0xFF200000
.equ HEX0, 0xFF200020
.equ HEX4, 0xFF200030
.equ PUSH, 0xFF200050

_start:
	mov r3, #0	//number to be displayed
	
timer_setup:
	mov r1, #7		//set auto bit, interrupt bit and enable bit
	ldr r0, =2000000	//200 mHz so count 2000000 times in ten milli seconds
	BL ARM_TIM_config_ASM

off:
	BL read_PB_edgecp_ASM	//read edgecapture
	BL PB_clear_edgecp_ASM
	TST r0, #1				//if button 0 was pressed, turn on
	BGT on
	tst r0, #4				//if button 2 was pressed, reset
	BGT reset
	B off
	
on:
	BL ARM_TIM_read_INT_ASM	//read timer interrupt
	BL ARM_TIM_clear_INT_ASM
	
	cmp r0, #1	//check if interrupt req was sent
	BNE on		//if it wasn't, check again
	
	BL increment
	BL write_sequence	//write new value to hexes if interrupt
	
	BL read_PB_edgecp_ASM	//read edgecapture
	BL PB_clear_edgecp_ASM
	TST r0, #2				//if button 1 was pressed, turn off
	BGT off
	tst r0, #4				//if button 2 was pressed, reset
	BGT reset
	B on
	
reset:
	mov r3, #0
	BL write_sequence
	B off

increment:
	push {v1-v4}
	add r3, r3, #1
	and v1, r3, #0xF
	cmp v1, #0xA
	BICge r3, r3, #0xF	//sets value to 0 if its 10
	addge r3, r3, #0x10	//increases value of the tens if prev was 10
	
	and v1, r3, #0xF0	//checking value in second
	cmp v1, #0xA0
	BICge r3, r3, #0xF0	//sets value to 0 if hex1 is 10
	addge r3, r3, #0x100//increases value of seconds if hex1 is 10
	
	and v1, r3, #0xF00	//checking value in third
	cmp v1, #0xA00
	BICge r3, r3, #0xF00	//sets value to 0 if hex2 is 10
	addge r3, r3, #0x1000//increases value of tens seconds if hex2 is 10

	and v1, r3, #0xF000	//checking value in fourth
	cmp v1, #0x6000
	BICge r3, r3, #0xF000	//sets value to 0 if hex3 is 6
	addge r3, r3, #0x10000//increases value of minutes if hex3 is 6
	
	and v1, r3, #0xF00000	//checking value in fifth
	cmp v1, #0xA00000
	BICge r3, r3, #0xF0000	//sets value to 0 if hex4 is 10
	addge r3, r3, #0x100000//increases value of tens minutes if hex4 is 10
	
	and v1, r3, #0xF0000000	//checking value in fifth
	cmp v1, #0x60000000
	BICge r3, r3, #0xF000000	//sets value to 0 if hex4 is 6
	movge r3, #0x10000000//resets the value if its been an hour
	
	pop {v1-v4}
	bx lr
	
write_sequence:
	push {lr}
	mov r0, #1	//Coord of hex0 to be printed to
	AND r1, r3, #0xF	//value to be displayed in hex0
	BL HEX_write_ASM	//write to hex0 if interrupt is 1
	
	AND r1, r3, #0xF0	// value to be printed on hex1
	lsr r1, #4
	mov r0, #2			//sets write to hex1
	BL HEX_write_ASM
	
	AND r1, r3, #0xF00	// value to be printed on hex2
	lsr r1, #8
	mov r0, #4			//sets write to hex2
	BL HEX_write_ASM
	
	AND r1, r3, #0xF000	// value to be printed on hex3
	lsr r1, #12
	mov r0, #8			//sets write to hex3
	BL HEX_write_ASM
	
	AND r1, r3, #0xF0000	// value to be printed on hex4
	lsr r1, #16
	mov r0, #16			//sets write to hex4
	BL HEX_write_ASM
	
	AND r1, r3, #0xF00000	// value to be printed on hex5
	lsr r1, #20
	mov r0, #32			//sets write to hex5
	BL HEX_write_ASM
	pop {lr}
	BX LR
	
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
	push {v1}
	ldr v1, =PUSH
	str R0, [v1, #0xC]
	pop {v1}
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
	push {v1}
	ldr v1, =TIMER_INTERRUPT
	str r0, [v1]
	pop {v1}
	bx lr