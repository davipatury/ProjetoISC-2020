.data
.include "sprites/walking_1.data"
.include "sprites/walking_2.data"
CHAR_WALKING: .byte 0, 0, 0, 0	# direction, mode, curr sprite

.text
		lb t0,CHAR_WALKING
		beqz t0,LEGS_IDLE

		li t1,-1
		beq t0,t1,LEGS_REVERSE
		
		la t3,CHAR_WALKING
		lbu t1,1(t3)	# mode (0xd80)
		lbu t2,2(t3)	# curr sprite
		
		#mv a0,t2
		#li a7,1
		#ecall
		
		bnez t1,WALK_MODE_1
		li t3,3
		blt t2,t3,WALK_MODE_0C

		la t3,CHAR_WALKING
		xori t1,t1,0x001
		sb t1,1(t3)
		sb zero,2(t3)
		j LEGS_IDLE

		#(t2 * 48)
WALK_MODE_0C:	li t3,48
		mul t3,t3,t2
		mv s3,t2
		render_a(walking_1, s1, s2, 48, 24, s0, t3, zero)
		addi s3,s3,1
		la t3,CHAR_WALKING
		sb s3,2(t3)
		j WALK_END

WALK_MODE_1:	li t3,6
		blt t2,t3,WALK_MODE_1C
		li t3,0
		la t4,CHAR_WALKING
		sb t3,2(t4)
		xori t1,t1,0x001
		sb t1,1(t4)
		j LEGS_IDLE

WALK_MODE_1C:	li t3,48
		mul t3,t3,t2
		mv s3,t2
		render_a(walking_2, s1, s2, 48, 24, s0, t3, zero)
		addi s3,s3,1
		la t3,CHAR_WALKING
		sb s3,2(t3)
		j WALK_END
		
WALK_END:	j LEGS_CONT

LEGS_REVERSE:	
		j LEGS_CONT
LEGS_IDLE:	render_a(char_legs_idle, s1, s2, 48, 24, s0, zero, zero)
LEGS_CONT:	toggle_frame()
