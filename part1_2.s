 .global _start
 n: .word 7
  _start:
	ldr r0, n
	bl fib_rec
end:
b end
	
fib_rec:
	cmp r0, #0
	bxeq lr
	cmp r0, #1
	bxeq lr
	
	push {v1,v2, lr}
	mov v1, #0	//internal counter
	mov v2, r0	//keeps track of n of curent recursion
	sub r0, #1
	bl fib_rec
	add v1, r0
	mov r0, v2
	sub r0, #2
	bl fib_rec
	add r0, v1
	pop {v1,v2, lr}
	bx lr