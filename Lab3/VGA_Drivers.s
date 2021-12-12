.global _start
.equ PixelBuffer, 0xC8000000
.equ CharBuffer, 0xC9000000
_start:

        bl      draw_test_screen
end:
        b       end

@ TODO: Insert VGA driver functions here.

draw_test_screen:
        push    {r4, r5, r6, r7, r8, r9, r10, lr}
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r6, #0
        ldr     r10, .draw_test_screen_L8
        ldr     r9, .draw_test_screen_L8+4
        ldr     r8, .draw_test_screen_L8+8
        b       .draw_test_screen_L2
.draw_test_screen_L7:
        add     r6, r6, #1
        cmp     r6, #320
        beq     .draw_test_screen_L4
.draw_test_screen_L2:
        smull   r3, r7, r10, r6
        asr     r3, r6, #31
        rsb     r7, r3, r7, asr #2
        lsl     r7, r7, #5
        lsl     r5, r6, #5
        mov     r4, #0
.draw_test_screen_L3:
        smull   r3, r2, r9, r5
        add     r3, r2, r5
        asr     r2, r5, #31
        rsb     r2, r2, r3, asr #9
        orr     r2, r7, r2, lsl #11
        lsl     r3, r4, #5
        smull   r0, r1, r8, r3
        add     r1, r1, r3
        asr     r3, r3, #31
        rsb     r3, r3, r1, asr #7
        orr     r2, r2, r3
        mov     r1, r4
        mov     r0, r6
        bl      VGA_draw_point_ASM
        add     r4, r4, #1
        add     r5, r5, #32
        cmp     r4, #240
        bne     .draw_test_screen_L3
        b       .draw_test_screen_L7
.draw_test_screen_L4:
        mov     r2, #72
        mov     r1, #5
        mov     r0, #20
        bl      VGA_write_char_ASM
        mov     r2, #101
        mov     r1, #5
        mov     r0, #21
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #22
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #23
        bl      VGA_write_char_ASM
        mov     r2, #111
        mov     r1, #5
        mov     r0, #24
        bl      VGA_write_char_ASM
        mov     r2, #32
        mov     r1, #5
        mov     r0, #25
        bl      VGA_write_char_ASM
        mov     r2, #87
        mov     r1, #5
        mov     r0, #26
        bl      VGA_write_char_ASM
        mov     r2, #111
        mov     r1, #5
        mov     r0, #27
        bl      VGA_write_char_ASM
        mov     r2, #114
        mov     r1, #5
        mov     r0, #28
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #29
        bl      VGA_write_char_ASM
        mov     r2, #100
        mov     r1, #5
        mov     r0, #30
        bl      VGA_write_char_ASM
        mov     r2, #33
        mov     r1, #5
        mov     r0, #31
        bl      VGA_write_char_ASM
        pop     {r4, r5, r6, r7, r8, r9, r10, pc}
.draw_test_screen_L8:
        .word   1717986919
        .word   -368140053
        .word   -2004318071

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