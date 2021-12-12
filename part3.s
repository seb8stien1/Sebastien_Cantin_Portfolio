.global _start
array: .word -1, 23, 0, 12, -7
size: .word 5

_start:
	mov v1, #0 //initializes step
loop: 
	ldr v2, size  //loads size
	sub v2, #1 //size - 1
	cmp v1, v2 // step - size + 1 < 0
	bge end
	mov v3, #0 //initializes i
loop2:
	mov v4, v2 //size -1
	sub v4, v1 // size - step - 1
	cmp v3, v4 // i - size + step + 1 < 0
	bge loop_end
	mov v4, #[array]//grabs the address of ptr
	add v4, v4, v3, lsl#2  //calculates the address of ptr+i
	ldr v5, [v4] 	//loads the value of ptr+i
	add v6, v4, #4  //calculates the address of ptr+i+1
	ldr v7, [v6] 	//loads the value of ptr+i+1
	cmp v5, v7 		// value of ptr+i - value of ptr+i+1 > 0
	ble loop2_end
	str v7, [v4] 	//stores ptr+i+1 at ptr+i's address
	str v5, [v6] 	//stores ptr+i at ptr+i+1's address
loop2_end:
	add v3, #1		//increments i
	b loop2
loop_end:
	add v1, #1		//increments step
	b loop
end:
	ldr r0, array	//returns the value of the smallest value
	b end