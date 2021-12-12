.global _start
.equ PixelBuffer, 0xC8000000
.equ CharBuffer, 0xC9000000
.equ PS2data, 0xFF200100
_start:
        bl      input_loop
end:
        b       end

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

write_hex_digit:
        push    {r4, lr}
        cmp     r2, #9
        addhi   r2, r2, #55
        addls   r2, r2, #48
        and     r2, r2, #255
        bl      VGA_write_char_ASM
        pop     {r4, pc}
write_byte:
        push    {r4, r5, r6, lr}
        mov     r5, r0
        mov     r6, r1
        mov     r4, r2
        lsr     r2, r2, #4
        bl      write_hex_digit
        and     r2, r4, #15
        mov     r1, r6
        add     r0, r5, #1
        bl      write_hex_digit
        pop     {r4, r5, r6, pc}
input_loop:
        push    {r4, r5, lr}
        sub     sp, sp, #12
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r4, #0
        mov     r5, r4
        b       .input_loop_L9
.input_loop_L13:
        ldrb    r2, [sp, #7]
        mov     r1, r4
        mov     r0, r5
        bl      write_byte
        add     r5, r5, #3
        cmp     r5, #79
        addgt   r4, r4, #1
        movgt   r5, #0
.input_loop_L8:
        cmp     r4, #59
        bgt     .input_loop_L12
.input_loop_L9:
        add     r0, sp, #7
        bl      read_PS2_data_ASM
        cmp     r0, #0
        beq     .input_loop_L8
        b       .input_loop_L13
.input_loop_L12:
        add     sp, sp, #12
        pop     {r4, r5, pc}



