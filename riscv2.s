.data
.include "bg.data"
.include "char.data"

.text
	la a0,BG	# initial address
	lw a3,0(a0)	# w
	addi a0,a0,4	# += 4
	lw a4,0(a0)	# h
	addi a0,a0,4	# += 4

	li a1,0
	li a2,0
	li a5,0
	li a6,0
	li a7,0
	jal DRAW
	
	li a7,10
	ecall

.include "render.s"