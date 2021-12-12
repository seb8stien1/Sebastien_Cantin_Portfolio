.global _start
.equ PixelBuffer, 0xC8000000
.equ CharBuffer, 0xC9000000
.equ PS2data, 0xFF200100
keyStore: .word 0
writtenSquares: .word 0
player1Squares: .word 0
player2Squares: .word 0  
_start:
	bl VGA_clear_charbuff_ASM
	bl draw_game
	bl wait_to_start 
start:
	mov r0, #0
	bl player_turn
	mov r0, #0 
	bl read
	cmp r0, #0
	beq restart
	
	bl draw_x
	
	mov r0, #0	
	bl determine_tie
	cmp r0, #0
	beq game_over

	mov r0, #0
	bl determine_winner
	cmp r0, #1
	moveq r0, #0
	bleq player_win
	cmp  r0, #2
	beq game_over
	
	mov r0, #1
	bl player_turn
	mov r0, #1
	bl read
	cmp r0, #0
	beq restart
	
	bl draw_o
	bl determine_winner
	cmp r0, #1
	bleq player_win
	cmp r0, #2
	beq game_over
	
	b start
	
determine_tie:
	push {v1-v2,lr}
	ldr v1, =writtenSquares
	ldr v2, =#0x1FF
	ldr v1, [v1]
	cmp v1, v2
	moveq r0, #0
	movne r0, #1
	bleq draw_tie
	pop {v1-v2,lr}
	bx lr

draw_tie:
	push {r0, lr}
	bl VGA_clear_charbuff_ASM
	
	mov r0, #38	//write draw
	mov r1, #2
	mov r2,	#68		// D
	bl VGA_write_char_ASM
	
	add r0, #1
	mov r2, #114	// r
	bl VGA_write_char_ASM
	
	add r0, #1
	mov r2, #97 	// a
	bl VGA_write_char_ASM
	
	add r0, #1
	mov r2, #119 	// w
	bl VGA_write_char_ASM
	
	pop {r0, lr}
	bx lr



game_over:
	mov r0, #0
	ldr r1, =writtenSquares
	str r0, [r1]
	ldr r1, =player1Squares
	str r0, [r1]
	ldr r1, =player2Squares
	str r0, [r1]
	bl wait_to_start
	bl draw_game
	b start
	
restart:
	mov r0, #0
	ldr r1, =writtenSquares
	str r0, [r1]
	ldr r1, =player1Squares
	str r0, [r1]
	ldr r1, =player2Squares
	str r0, [r1]
	bl draw_game
	b start


//first subroutine
draw_game:
	push {v1, lr}
	bl VGA_clear_pixelbuff_ASM
	mov r0, #123
	mov r1, #17
	ldr r2, =0xFFFE //green
	ldr v1, =263
	bl draw_col1
	mov r0, #193
	mov r1, #17
	bl draw_col2
	mov r0, #57
	mov r1, #83
	bl draw_row1
	mov r0, #57
	mov r1, #153
	bl draw_row2
	pop {v1, lr}
	bx lr
draw_col1:
	push {lr}
col1_loop:
	bl VGA_draw_point_ASM
	add r0, #1
	cmp r0, #127
	movge r0, #123
	addge r1, #1
	cmp r1, #224
	ble col1_loop
	pop {lr}
	bx lr
draw_col2:
	push {lr}
col2_loop:
	bl VGA_draw_point_ASM
	add r0, #1
	cmp r0, #197
	movge r0, #193
	addge r1, #1
	cmp r1, #224
	ble col2_loop
	pop {lr}
	bx lr
draw_row1:
	push {lr}
row1_loop:
	bl VGA_draw_point_ASM
	add r1, #1
	cmp r1, #87
	movge r1, #83
	addge r0, #1
	cmp r0, v1
	ble row1_loop
	pop {lr}
	bx lr
draw_row2:
	push {lr}
row2_loop:
	bl VGA_draw_point_ASM
	add r1, #1
	cmp r1, #157
	movge r1, #153
	addge r0, #1
	cmp r0, v1
	ble row2_loop
	pop {lr}
	bx lr
	

	
wait_to_start:
	push {v1, lr}
wait_loop:
	ldr r0, =keyStore
	bl read_PS2_data_ASM
	cmp r0, #1	//check rvalid is 1
	bne wait_loop
	ldr v1, =keyStore
	ldr v1, [v1]
	and v1, #0x45
	cmp v1, #0x45
	popeq {v1, lr}
	bxeq lr
	b wait_loop


//takes r0 as an argument to indicate which player's turn it is
player_turn:
	push {v1, lr}
	mov v1, r0
	bl VGA_clear_charbuff_ASM
	
	mov r0, #34	//write player x turn
	mov r1, #2
	mov r2,	#80		// P
	bl VGA_write_char_ASM
	
	add r0, #1
	mov r2, #108	// l
	bl VGA_write_char_ASM
	
	add r0, #1
	mov r2, #97 	// a
	bl VGA_write_char_ASM
	
	add r0, #1
	mov r2, #121 	// y
	bl VGA_write_char_ASM
	
	add r0, #1
	mov r2, #101 	// e
	bl VGA_write_char_ASM
	
	add r0, #1
	mov r2, #114 	// r
	bl VGA_write_char_ASM
	
	add r0, #2
	cmp v1, #0
	moveq r2, #49 	// 1
	movne r2, #50	// 2
	bl VGA_write_char_ASM
	
	add r0, #2
	mov r2, #116 	// t
	bl VGA_write_char_ASM
	
	add r0, #1
	mov r2, #117 	// u
	bl VGA_write_char_ASM

	add r0, #1
	mov r2, #114 	// r
	bl VGA_write_char_ASM
	
	add r0, #1
	mov r2, #110 	// n
	bl VGA_write_char_ASM
	
	mov r0, #2
	pop {v1, lr}
	bx lr
	
	
	
//takes r0 as an argument, which player's turn it is
//returns rvalid r0, updates value of table automatically
read:		
	push {v1-v5, lr} 
	cmp r0, #0
	ldreq v4, =player1Squares
	ldrne v4, =player2Squares
	ldr v5, [v4]
read_loop:
	ldr r0, =keyStore
	bl read_PS2_data_ASM
	cmp r0, #1	//check rvalid is 1
	bne read_loop
	
	bl translate
	
	cmp r0, #10
	beq read_loop	//if input not a number between 0-9, check for another press
	mov v1, r0
	ldr v2, =writtenSquares
	ldr v3, [v2]
	
	and v2, v3, #0x100
	cmp v1, #9
	cmpeq v2, #0x100	//check if square9 already pressed
	beq read_loop	//square9 already pressed and input was 9
	cmp v1, #9
	addeq v3, #0x100
	addeq v5, #0x100
	beq read_end
	
	and v2, v3, #0x80
	cmp v1, #8
	cmpeq v2, #0x80	//check if square8 already pressed
	beq read_loop	//square8 already pressed and input was 8
	cmp v1, #8
	addeq v3, #0x80
	addeq v5, #0x80
	beq read_end
	
	and v2, v3, #0x40
	cmp v1, #7	//check if square7 already pressed
	cmpeq v2, #0x40
	beq read_loop	//square7 already pressed and input was 7
	cmp v1, #7
	addeq v3, #0x40
	addeq v5, #0x40
	beq read_end
	
	and v2, v3, #0x20
	cmp v1, #6	//check if square6 already pressed
	cmpeq v2, #0x20
	beq read_loop	//square6 already pressed and input was 6
	cmp v1, #6
	addeq v3, #0x20
	addeq v5, #0x20
	beq read_end
	
	and v2, v3, #0x10
	cmp v1, #5	//check if square5 already pressed
	cmpeq v2, #0x10
	beq read_loop	//square5 already pressed and input was 5
	cmp v1, #5
	addeq v3, #0x10
	addeq v5, #0x10
	beq read_end
	
	and v2, v3, #0x8
	cmp v1, #4	//check if square4 already pressed
	cmpeq v2, #0x8
	beq read_loop	//square4 already pressed and input was 4
	cmp v1, #4
	addeq v3, #0x8
	addeq v5, #0x8
	beq read_end
	
	and v2, v3, #0x4
	cmp v1, #3	//check if square3 already pressed
	cmpeq v2, #0x4
	beq read_loop	//square3 already pressed and input was 3
	cmp v1, #3
	addeq v3, #0x4
	addeq v5, #0x4
	beq read_end
	
	and v2, v3, #0x2
	cmp v1, #2	//check if square2 already pressed
	cmpeq v2, #2
	beq read_loop	//square2 already pressed and input was 2
	cmp v1, #2
	addeq v3, #2
	addeq v5, #2
	beq read_end
	
	and v2, v3, #0x1
	cmp v1, #1
	cmpeq v2, #1	//check if square1 already pressed
	beq read_loop	//square1 already pressed and input was 1
	cmp v1, #1
	addeq v3, #1
	addeq v5, #1
read_end:
	ldr v1, =writtenSquares
	str v3, [v1]
	str v5, [v4]
	pop {v1-v5, lr}
	bx lr
	
translate: 
	push {v1, lr}
	ldr v1, =keyStore
	ldr v1, [v1]
	and v1, #0xFF
	
	cmp v1, #0x16
	moveq r0, #1
	beq translate_end
	
	cmp v1, #0x1E
	moveq r0, #2
	beq translate_end
	
	cmp v1, #0x26
	moveq r0, #3
	beq translate_end
	
	cmp v1, #0x25
	moveq r0, #4
	beq translate_end
	
	cmp v1, #0x2E
	moveq r0, #5
	beq translate_end
	
	cmp v1, #0x36
	moveq r0, #6
	beq translate_end
	
	cmp v1, #0x3D
	moveq r0, #7
	beq translate_end
	
	cmp v1, #0x3E
	moveq r0, #8
	beq translate_end
	
	cmp v1, #0x46
	moveq r0, #9
	beq translate_end
	
	cmp v1, #0x45
	moveq r0, #0
	beq translate_end
	
	mov r0, #10
translate_end:
	pop {v1, lr}
	bx lr
player_win:
	push {v1, lr}
	mov v1, r0
	bl VGA_clear_charbuff_ASM
	
	mov r0, #34	//write player x wins
	mov r1, #2
	mov r2,	#80		// P
	bl VGA_write_char_ASM
	
	add r0, #1
	mov r2, #108	// l
	bl VGA_write_char_ASM
	
	add r0, #1
	mov r2, #97 	// a
	bl VGA_write_char_ASM
	
	add r0, #1
	mov r2, #121 	// y
	bl VGA_write_char_ASM
	
	add r0, #1
	mov r2, #101 	// e
	bl VGA_write_char_ASM
	
	add r0, #1
	mov r2, #114 	// r
	bl VGA_write_char_ASM
	
	add r0, #2
	cmp v1, #0
	moveq r2, #49 	// 1
	movne r2, #50	// 2
	bl VGA_write_char_ASM
	
	add r0, #2
	mov r2, #87 	// W
	bl VGA_write_char_ASM
	
	add r0, #1
	mov r2, #105 	// i
	bl VGA_write_char_ASM
	
	add r0, #1
	mov r2, #110 	// n
	bl VGA_write_char_ASM
	
	add r0, #1
	mov r2, #115 	// s
	bl VGA_write_char_ASM
	
	add r0, #1
	mov r2, #33 	// !
	bl VGA_write_char_ASM
	
	mov r0, #2
	pop {v1, lr}
	bx lr
	
	//takes r0 as an argument to indicate which player is being checked
	//returns 1 in r0 if the player has won
determine_winner:
	push {v1} 
	cmp r0, #0
	ldreq v1, =player1Squares
	ldrne v1, =player2Squares
	ldr v1, [v1]
	tst v1, #0x100 //row 1
	tstgt v1, #0x80
	tstgt v1, #0x40
	movgt r0, #1
	bgt winner_end
	tst v1, #0x20	//row 2
	tstgt v1, #0x10
	tstgt v1, #8
	movgt r0, #1
	bgt winner_end
	tst v1, #0x4	//row 3
	tstgt v1, #0x2
	tstgt v1, #0x1
	movgt r0, #1
	bgt winner_end
	tst v1, #0x100	//col 1
	tstgt v1, #0x20
	tstgt v1, #0x4
	movgt r0, #1
	bgt winner_end
	tst v1, #0x80	//col 2
	tstgt v1, #0x10
	tstgt v1, #0x2
	movgt r0, #1
	bgt winner_end
	tst v1, #0x40	//col 3
	tstgt v1, #0x8
	tstgt v1, #0x1
	movgt r0, #1
	bgt winner_end
	tst v1, #0x100	//diagonal 1
	tstgt v1, #0x10
	tstgt v1, #1
	movgt r0, #1
	bgt winner_end
	tst v1, #0x40	//diagonal 2
	tstgt v1, #0x10
	tstgt v1, #4
	movgt r0, #1
	bgt winner_end
	mov r0, #0
winner_end:
	pop {v1}
	bx lr
	

draw_o:	//will essentially draw a diamond instead, basically a circle
	push {v1, lr}
	mov v1, r0
	mov r2, #0x1F	//red x
	
	cmp v1, #1
	moveq r0, #59
	moveq r1, #49
	bleq draw_o_bar1	//draw first bar
	cmp v1, #1
	moveq r0, #59
	moveq r1, #50
	bleq draw_o_bar2	//draw second bar
	
	cmp v1, #2
	moveq r0, #129
	moveq r1, #49
	bleq draw_o_bar1	//draw first bar
	cmp v1, #2
	moveq r0, #129
	moveq r1, #50
	bleq draw_o_bar2	//draw second bar
	
	cmp v1, #3
	moveq r0, #199
	moveq r1, #49
	bleq draw_o_bar1	//draw first bar
	cmp v1, #3
	moveq r0, #199
	moveq r1, #50
	bleq draw_o_bar2	//draw second bar
	
	cmp v1, #4
	moveq r0, #59
	moveq r1, #119
	bleq draw_o_bar1	//draw first bar
	cmp v1, #4
	moveq r0, #59
	moveq r1, #120
	bleq draw_o_bar2	//draw second bar
	
	cmp v1, #5
	moveq r0, #129
	moveq r1, #119
	bleq draw_o_bar1	//draw first bar
	cmp v1, #5
	moveq r0, #129
	moveq r1, #120
	bleq draw_o_bar2	//draw second bar
	
	cmp v1, #6
	moveq r0, #199
	moveq r1, #119
	bleq draw_o_bar1	//draw first bar
	cmp v1, #6
	moveq r0, #199
	moveq r1, #120
	bleq draw_o_bar2	//draw second bar
	
	cmp v1, #7
	moveq r0, #59
	moveq r1, #190
	bleq draw_o_bar1	//draw first bar
	cmp v1, #7
	moveq r0, #59
	moveq r1, #191
	bleq draw_o_bar2	//draw second bar
	
	cmp v1, #8
	moveq r0, #129
	moveq r1, #190
	bleq draw_o_bar1	//draw first bar
	cmp v1, #8
	moveq r0, #129
	moveq r1, #191
	bleq draw_o_bar2	//draw second bar
	
	cmp v1, #9
	moveq r0, #199
	moveq r1, #190
	bleq draw_o_bar1	//draw first bar
	cmp v1, #9
	moveq r0, #199
	moveq r1, #191
	bleq draw_o_bar2	//draw second bar
	
	mov r0, v1
	pop {v1, lr}
	bx lr

draw_o_bar1:
	push {v1, v2, lr}
	add v1, r1, #1
	sub v2, r1, #29
obar1_loop1:
	bl VGA_draw_point_ASM
	add r0, #1
	bl VGA_draw_point_ASM
	add r0, #1
	bl VGA_draw_point_ASM
	sub r0, #1
	sub r1, #1
	cmp r1, v2
	bgt obar1_loop1
	add r1, #1
obar1_loop2:
	bl VGA_draw_point_ASM
	add r0, #1
	bl VGA_draw_point_ASM
	add r0, #1
	bl VGA_draw_point_ASM
	sub r0, #1
	add r1, #1
	cmp r1, v1
	ldrge r3, =0xFFFFffff
	blge VGA_draw_point_ASM
	cmp r1, v1
	popge {v1, v2, lr}
	bxge lr
	b obar1_loop2
draw_o_bar2:
	push {v1, v2, lr}
	sub v1, r1, #1
	add v2, r1, #29
obar2_loop1:
	bl VGA_draw_point_ASM
	add r0, #1
	bl VGA_draw_point_ASM
	add r0, #1
	bl VGA_draw_point_ASM
	sub r0, #1
	add r1, #1
	cmp r1, v2
	blt obar2_loop1
	sub r1, #1
obar2_loop2:
	bl VGA_draw_point_ASM
	add r0, #1
	bl VGA_draw_point_ASM
	add r0, #1
	bl VGA_draw_point_ASM
	sub r0, #1
	sub r1, #1
	cmp r1, v1
	ldrle r3, =0xFFFFffff
	blle VGA_draw_point_ASM
	cmp r1, v1
	pople {v1, v2, lr}
	bxle lr
	b obar2_loop2

//takes r0 as an argument to indicate which square to draw in.
draw_x:
	push {v1, lr}
	mov v1, r0
	mov r2, #0xF000	//red x
	cmp v1, #1					//draw in square 1
	moveq r0, #59
	moveq r1, #20
	bleq draw_x_bar1	//draw first bar
	cmp v1, #1
	moveq r0, #59
	moveq r1, #79
	bleq draw_x_bar2	//draw second bar
	cmp v1, #2					//draw in square 2
	moveq r0, #129
	moveq r1, #20
	bleq draw_x_bar1	//draw first bar
	cmp v1, #2
	moveq r0, #129
	moveq r1, #79
	bleq draw_x_bar2	//draw second bar
	cmp v1, #3					//draw in square 3
	moveq r0, #199
	moveq r1, #20
	bleq draw_x_bar1	//draw first bar
	cmp v1, #3
	moveq r0, #199
	moveq r1, #79
	bleq draw_x_bar2	//draw second bar
	cmp v1, #4					//draw in square 4
	moveq r0, #59
	moveq r1, #90
	bleq draw_x_bar1	//draw first bar
	cmp v1, #4
	moveq r0, #59
	moveq r1, #149
	bleq draw_x_bar2	//draw second bar
	cmp v1, #5					//draw in square 5
	moveq r0, #129
	moveq r1, #90
	bleq draw_x_bar1	//draw first bar
	cmp v1, #5
	moveq r0, #129
	moveq r1, #149
	bleq draw_x_bar2	//draw second bar
	cmp v1, #6					//draw in square 6
	moveq r0, #199
	moveq r1, #90
	bleq draw_x_bar1	//draw first bar
	cmp v1, #6
	moveq r0, #199
	moveq r1, #149
	bleq draw_x_bar2	//draw second bar
	cmp v1, #7					//draw in square 7
	moveq r0, #59
	moveq r1, #161
	bleq draw_x_bar1	//draw first bar
	cmp v1, #7
	moveq r0, #59
	moveq r1, #220
	bleq draw_x_bar2	//draw second bar
	cmp v1, #8					//draw in square 8
	moveq r0, #129
	moveq r1, #161
	bleq draw_x_bar1	//draw first bar
	cmp v1, #8
	moveq r0, #129
	moveq r1, #220
	bleq draw_x_bar2	//draw second bar
	cmp v1, #9					//draw in square 9
	moveq r0, #199
	moveq r1, #161
	bleq draw_x_bar1	//draw first bar
	cmp v1, #9
	moveq r0, #199
	moveq r1, #220
	bleq draw_x_bar2	//draw second bar
	mov r0, v1
	pop {v1, lr}
	bx lr
draw_x_bar1:	//arguments are r0, r1 and r2 (start x, start y, color)
	push {v1, lr}
	add v1, r1, #59
xbar1_loop:
	bl VGA_draw_point_ASM
	add r0, #1
	bl VGA_draw_point_ASM
	add r0, #1
	bl VGA_draw_point_ASM
	add r0, #1
	bl VGA_draw_point_ASM
	sub r0, #2
	add r1, #1
	cmp r1, v1
	popgt {v1, lr}
	bxgt lr
	b xbar1_loop
draw_x_bar2:
	push {v1, lr}
	sub v1, r1, #59
xbar2_loop:
	bl VGA_draw_point_ASM
	add r0, #1
	bl VGA_draw_point_ASM
	add r0, #1
	bl VGA_draw_point_ASM
	add r0, #1
	bl VGA_draw_point_ASM
	sub r0, #2
	sub r1, #1
	cmp r1, v1
	poplt {v1, lr}
	bxlt lr
	b xbar2_loop
	

	


	
	

read_PS2_data_ASM:
	push {v1-v4}
	mov v3, r0
	ldr v1, =PS2data
	ldr v2, [v1]
	and r0, v2, #0x8000
	cmp r0, r0
	lsrge r0, #15
	andge v2, v2, #0xff
	strgeb v2, [v3]
	pop {v1-v4}
	bx lr

VGA_draw_point_ASM:
	push {v1-v3}
	
	cmp r0, #0
	poplt {v1-v3}
	bxlt lr
	cmp r1, #0
	poplt {v1-v3}
	bxlt lr
	cmp r0, #320
	popge {v1-v3}
	bxge lr
	cmp r1, #240
	popge {v1-v3}
	bxge lr
	
	mov v1, r1
	lsl v1, #9
	add v1, r0
	lsl v1, #1
	ldr v2, =PixelBuffer
	strh r2, [v2, v1]
	pop {v1-v3}
	bx lr

VGA_clear_pixelbuff_ASM:
	push {v1, v2,lr}
	mov r0, #0
	mov r1, #0
	mov r2, #0
	ldr v1, =320
	ldr v2, =240
pixel_clear_loop:
	bl VGA_draw_point_ASM
	add r0, #1
	cmp r0, v1
	movge r0, #0
	addge r1, #1
	cmp r1, v2
	popge {v1, v2, lr}
	bxge lr
	b pixel_clear_loop

VGA_write_char_ASM:
	push {v1-v3}
	
	cmp r0, #0
	poplt {v1-v3}
	bxlt lr
	cmp r1, #0
	poplt {v1-v3}
	bxlt lr
	cmp r0, #80
	popge {v1-v3}
	bxge lr
	cmp r1, #60
	popge {v1-v3}
	bxge lr
	
	mov v1, r1
	lsl v1, #7
	add v1, r0
	ldr v2, =CharBuffer
	strb r2, [v2, v1]
	pop {v1-v3}
	bx lr
	
VGA_clear_charbuff_ASM:
	push {v1, v2,lr}
	mov r0, #0
	mov r1, #0
	mov r2, #0
	ldr v1, =80
	ldr v2, =60
char_clear_loop:
	bl VGA_write_char_ASM
	add r0, #1
	cmp r0, v1
	movge r0, #0
	addge r1, #1
	cmp r1, v2
	popge {v1, v2, lr}
	bxge lr
	b char_clear_loop