.section .vectors, "ax"
B _start
B SERVICE_UND       // undefined instruction vector
B SERVICE_SVC       // software interrupt vector
B SERVICE_ABT_INST  // aborted prefetch vector
B SERVICE_ABT_DATA  // aborted data vector
.word 0 // unused vector
B SERVICE_IRQ       // IRQ interrupt vector
B SERVICE_FIQ       // FIQ interrupt vector

.text
.global _start

PB_int_flag: .word 0x0
tim_int_flag: .word 0x0
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
    /* Set up stack pointers for IRQ and SVC processor modes */
    MOV        R1, #0b11010010      // interrupts masked, MODE = IRQ
    MSR        CPSR_c, R1           // change to IRQ mode
    LDR        SP, =0xFFFFFFFF - 3  // set IRQ stack to A9 onchip memory
    /* Change to SVC (supervisor) mode with interrupts disabled */
    MOV        R1, #0b11010011      // interrupts masked, MODE = SVC
    MSR        CPSR, R1             // change to supervisor mode
    LDR        SP, =0x3FFFFFFF - 3  // set SVC stack to top of DDR3 memory
    BL     CONFIG_GIC           // configure the ARM GIC
    // To DO: write to the pushbutton KEY interrupt mask register
    // Or, you can call enable_PB_INT_ASM subroutine from previous task
    // to enable interrupt for ARM A9 private timer, use ARM_TIM_config_ASM subroutine
    LDR        R0, =0xFF200050      // pushbutton KEY base address
    MOV        R1, #0xF             // set interrupt mask bits
    STR        R1, [R0, #0x8]       // interrupt mask register (base + 8)
    // enable IRQ interrupts in the processor
    MOV        R0, #0b01010011      // IRQ unmasked, MODE = SVC
    MSR        CPSR_c, R0
	
	//CONFIG TIMER
	mov r1, #7		//set auto bit, interrupt bit and enable bit
	ldr r0, [pc, #-4]
	.word 0x1E8480	//set load value
	BL ARM_TIM_config_ASM
	mov r0, #0b111
	BL enable_PB_INT_ASM
IDLE:
    mov r3, #0
OFF: 
	ldr v1, =PB_int_flag
	ldr v2, [v1]
	
	tst v2, #1
	BGT ON
	tst v2, #4
	BGT RESET

	B OFF

RESET:
	mov r3, #0
	BL write_sequence
	b OFF
	
ON:
	ldr v1, =tim_int_flag
	ldr v2, [v1]
	mov v3, #0
	cmp v2, v3		//check if flag raised 
	strgt v3, [v1]	//resets flag if so
	blgt increment	//increments counter if so
	cmp v2, v3		//check if flag raised 
	blgt write_sequence	//writes to hexes if so
	
	ldr v1, =PB_int_flag
	ldr v2, [v1]
	cmp v2, #0
	
	tst v2, #2
	BGT OFF
	tst v2, #4
	BGT RESET
	B ON

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
	
	and v1, r3, #0xF0000	//checking value in fifth
	cmp v1, #0xA0000
	BICge r3, r3, #0xF0000	//sets value to 0 if hex4 is 10
	addge r3, r3, #0x100000//increases value of tens minutes if hex4 is 10
	
	and v1, r3, #0xF00000	//checking value in fifth
	cmp v1, #0x600000
	movge r3, #0x10000000//resets the value if its been an hour
	
	pop {v1-v4}
	bx lr
	
	
	/*--- Undefined instructions ---------------------------------------- */
SERVICE_UND:
    B SERVICE_UND
/*--- Software interrupts ------------------------------------------- */
SERVICE_SVC:
    B SERVICE_SVC
/*--- Aborted data reads -------------------------------------------- */
SERVICE_ABT_DATA:
    B SERVICE_ABT_DATA
/*--- Aborted instruction fetch ------------------------------------- */
SERVICE_ABT_INST:
    B SERVICE_ABT_INST
/*--- IRQ ----------------------------------------------------------- */
SERVICE_IRQ:
    PUSH {R0-R7, LR}
/* Read the ICCIAR from the CPU Interface */
    LDR R4, =0xFFFEC100
    LDR R5, [R4, #0x0C] // read from ICCIAR

/* To Do: Check which interrupt has occurred (check interrupt IDs)
   Then call the corresponding ISR
   If the ID is not recognized, branch to UNEXPECTED
   See the assembly example provided in the De1-SoC Computer_Manual on page 46 */
 Pushbutton_check:
    CMP R5, #73
	BLEQ KEY_ISR
	CMP R5, #29
	BLEQ ARM_TIM_ISR
UNEXPECTED:
	CMP R5, #73
	CMPNE R5, #29
    BNE UNEXPECTED      // if not recognized, jump to next check

	
EXIT_IRQ:
/* Write to the End of Interrupt Register (ICCEOIR) */
    STR R5, [R4, #0x10] // write to ICCEOIR
    POP {R0-R7, LR}
SUBS PC, LR, #4
/*--- FIQ ----------------------------------------------------------- */
SERVICE_FIQ:
    B SERVICE_FIQ
	
CONFIG_GIC:
    PUSH {LR}
/* To configure the FPGA KEYS interrupt (ID 73):
* 1. set the target to cpu0 in the ICDIPTRn register
* 2. enable the interrupt in the ICDISERn register */
/* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
/* To Do: you can configure different interrupts
   by passing their IDs to R0 and repeating the next 3 lines */
    MOV R0, #73            // KEY port (Interrupt ID = 73)
    MOV R1, #1             // this field is a bit-mask; bit 0 targets cpu0
    BL CONFIG_INTERRUPT

	MOV R0, #29            // KEY port (Interrupt ID = 29)
    MOV R1, #1             // this field is a bit-mask; bit 0 targets cpu0
    BL CONFIG_INTERRUPT
	
/* configure the GIC CPU Interface */
    LDR R0, =0xFFFEC100    // base address of CPU Interface
/* Set Interrupt Priority Mask Register (ICCPMR) */
    LDR R1, =0xFFFF        // enable interrupts of all priorities levels
    STR R1, [R0, #0x04]
/* Set the enable bit in the CPU Interface Control Register (ICCICR).
* This allows interrupts to be forwarded to the CPU(s) */
    MOV R1, #1
    STR R1, [R0]
/* Set the enable bit in the Distributor Control Register (ICDDCR).
* This enables forwarding of interrupts to the CPU Interface(s) */
    LDR R0, =0xFFFED000
    STR R1, [R0]
    POP {PC}

/*
* Configure registers in the GIC for an individual Interrupt ID
* We configure only the Interrupt Set Enable Registers (ICDISERn) and
* Interrupt Processor Target Registers (ICDIPTRn). The default (reset)
* values are used for other registers in the GIC
* Arguments: R0 = Interrupt ID, N
* R1 = CPU target
*/
CONFIG_INTERRUPT:
    PUSH {R4-R5, LR}
/* Configure Interrupt Set-Enable Registers (ICDISERn).
* reg_offset = (integer_div(N / 32) * 4
* value = 1 << (N mod 32) */
    LSR R4, R0, #3    // calculate reg_offset
    BIC R4, R4, #3    // R4 = reg_offset
    LDR R2, =0xFFFED100
    ADD R4, R2, R4    // R4 = address of ICDISER
    AND R2, R0, #0x1F // N mod 32
    MOV R5, #1        // enable
    LSL R2, R5, R2    // R2 = value
/* Using the register address in R4 and the value in R2 set the
* correct bit in the GIC register */
    LDR R3, [R4]      // read current register value
    ORR R3, R3, R2    // set the enable bit
    STR R3, [R4]      // store the new register value
/* Configure Interrupt Processor Targets Register (ICDIPTRn)
* reg_offset = integer_div(N / 4) * 4
* index = N mod 4 */
    BIC R4, R0, #3    // R4 = reg_offset
    LDR R2, =0xFFFED800
    ADD R4, R2, R4    // R4 = word address of ICDIPTR
    AND R2, R0, #0x3  // N mod 4
    ADD R4, R2, R4    // R4 = byte address in ICDIPTR
/* Using register address in R4 and the value in R2 write to
* (only) the appropriate byte */
    STRB R1, [R4]
    POP {R4-R5, PC}
	
	
KEY_ISR:
	push {r0, v1, lr}
	ldr v1, =PB_int_flag
    BL read_PB_edgecp_ASM	
	str r0, [v1]
	BL PB_clear_edgecp_ASM
	pop {r0, v1, lr}
    BX LR
	
ARM_TIM_ISR:
	push {r0, v1, lr}
	BL ARM_TIM_read_INT_ASM
	BL ARM_TIM_clear_INT_ASM
	ldr v1, =tim_int_flag
	str r0, [v1]
	pop {r0, v1, lr}
	bx lr
	
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