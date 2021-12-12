.global _start
//program works by pushing all the fibonnaci numbers
//to the stack, popping top 2, adding them, then pushing
//the now three numbers back to the stack until i = n
n: .word 7
_start:
	ldr v1, n
	cmp v1, #0
	beq zero_or_one
	cmp v1, #1
	beq zero_or_one
	mov v2, #2	//initializes i = 2
	mov v3, #1	//initializes f[1] = 1
	mov v4, #0	//initializes f[0] = 0
	push {v3,v4}//pushes f[0],f[1]
loop:	
	cmp v2, v1 	//compares i and n
	bgt end 	//if i > n, end loop
	pop {v4, v5} 	//loads value at [n-1], [n-2]
	add v3, v4, v5 	//f[i-1] + f[i-2]
	push {v3 - v5}	//pushes f[i],f[i-1],f[i-2] to stack
	add v2, #1 	//increments i
	b loop
end:
	pop {r0}	//pops the top result from the stack, ie f[n] to r0
	ldr v1, n	//loads n to v1 in order to clear the stack
restore_stack:
	pop {v2}	//pops all the values from the stack to reset it to its inital state
	subs v1, v1, #1	//pops the stack n times
	bgt restore_stack
final:
	b final		//endless loop at end
zero_or_one:
	mov r0, v1	//sends n to r0, because f[0]=0 and f[1]=1
	b final		//goes to final endless loop