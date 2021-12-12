.global _start

gx: .space 400
fx: .word 183, 207, 128, 30, 109, 0, 14, 52, 15, 210, 228, 76, 48, 82, 179, 194, 22, 168, 58, 116, 228, 217, 180, 181, 243, 65, 24, 127, 216, 118,64, 210, 138, 104, 80, 137, 212, 196, 150, 139, 155, 154, 36, 254, 218, 65, 3, 11, 91, 95, 219, 10, 45, 193, 204, 196, 25, 177, 188, 170, 189, 241, 102, 237, 251, 223, 10, 24, 171, 71, 0, 4, 81, 158, 59, 232, 155, 217, 181, 19, 25, 12, 80, 244, 227, 101, 250, 103, 68, 46, 136, 152, 144, 2, 97, 250, 47, 58, 214, 51
kx: .word 1,   1,  0,  -1,  -1, 0,   1,  0,  -1,   0, 0,   0,  1,   0,   0, 0,  -1,  0,   1,   0, -1, -1,  0,   1,   1
iw: .word 10
ih: .word 10
kw: .word 5
kh: .word 5
ksw: .word 2
khw: .word 2

_start:
	mov v1, #0 	//initialize y
	push {v1}	//pushes y to stack
loop1:
	ldr v2, ih	//loads ih
	pop {v1}	//pops y from the stack
	cmp v1, v2	//y - ih >= 0
	bge end
	push {v1}	//pushes y back to the bottom of the stack 
	mov v1, #0	//initialize x
	push {v1}	//pushes x to the stack
loop2:
	ldr v2, iw	//loads iw
	pop {v1}	//pops x from the stack
	cmp v1, v2
	bge loop1_end
	push {v1}	//pushes x back to the stack
	mov v8, #0	//initializes sum
	mov v1, #0	//initializes i
	push {v1}	//pushes i to the stack
loop3:
	ldr v2, kw	//loads kw
	pop {v1}		//pops i from the stack
	cmp v1, v2
	bge loop2_end
	push {v1}		//pushes i back to the stack
	mov v1, #0	//initializes j
	push {v1}		//pushes j to the stack
loop4:
	ldr v2, kh	//loads kh
	pop {v1}		//pops j from the stack
	cmp v1, v2
	bge loop3_end
	pop {v2}		//pops i from the stack
	pop {v5}		//pops x from the stack
	pop {v6}		//pops y from the stack
	ldr v4, khw	//loads khw
	sub v4, v6, v4
	add v4, v4, v2	//v4 = y + i - khw = temp2
	push {v6}	//pushes y back to the stack
	ldr v3, ksw	//loads ksw
	sub v3, v5, v3
	add v3, v1, v3	//v3 = x + j - ksw = temp1
	
	push {v5}		//pushes x back to the stack
	push {v2}		//pushes i back to the stack
	
	cmp v3, #0
	blt loop4_end 	//if v3(temp1) is smaller than 0, dont do if statement
	cmp v4, #0
	blt loop4_end	//if v4(temp2) is smaller than 0, dont do if statement
	cmp v3, #9
	bgt loop4_end	//if v3(temp1) is greater than 9, dont do if statement
	cmp v4, #9
	bgt loop4_end	//if v4(temp2) is greater than 9, dont do if statement
	
	pop {v2}		//pops i back from the stack
	ldr v6, kw		//loads kw to v6
	mul v5, v6, v1
	add v5, v5, v2	//index of the point we want
	lsl v5, v5, #2	//turns that into an address by multiplying by 4
	add v5, v5, #[kx]	//adds the starting address and the address we care about
	ldr v6, [v5]	//loads the value that we want from kx
	
	ldr v5, iw		//loads iw to r0
	mul v5, v3, v5
	add v5, v4, v5	//the index of the value we want from fx
	lsl v5, v5, #2	//turns that into an address by multiplying by 4
	add v5, v5, #[fx]	//adds the starting address and the address we care about
	ldr v5, [v5]	//loads the value we want from fx
	
	mul v5, v5, v6 	//multiplies the two values pulled from the arrays
	add v8, v8, v5	//adds the values to the sum
	push {v2}		//pushes i back to the stack
	
loop4_end:
	add v1, #1		//iterates j
	push {v1}		//pushes j to the stack
	b loop4
	
loop3_end:
	pop {v1}		//pops i from the stack
	add v1, #1		//iterates i
	push {v1}		//pushes i back to stack
	b loop3		
	
loop2_end:
	pop {v1}		//pops x from the stack
	pop {v2}		//pops y from the stack
	ldr v3, iw		//loads iw
	mul v3, v3, v1
	add v3, v3, v2	//index of the value we want to plug in
	lsl v3, v3, #2	//turns it into an address
	add v3, v3, #[gx] //adds the address we care about and start address
	str v8, [v3]	//stores the sum to gx
	add v1, v1, #1	//iterates x
	push {v2}		//pushes y back to the stack
	push {v1}		//pushes x back to the stack
	b loop2
loop1_end:
	pop {v1}		//pops y from the stack
	add v1, #1		//increments y
	push {v1}		//pushes y back to the stack
	b loop1
end:
	b end