.include "macros.s"

.align 2
.data
.include "sprites/background.data"
.include "sprites/char_torso.data"
.include "sprites/char_legs_idle.data"
.include "sprites/walking_1.data"
.include "sprites/walking_2.data"

CHAR_POS: .half 32, 168		# top left x, y
CHAR_WALKING: .byte 0, 0, 0, 0	# direction, mode, curr sprite

.text
		render(background, 0, 0, 320, 240, zero, 0, 0)
		li t0, 1
		render(background, 0, 0, 320, 240, t0, 0, 0)

M_LOOP:		jal RECEIVE_INPUT
		next_frame(s0)
		load_char_pos(s1, s2)
		
		addi t0,s1,-8
		addi t1,s2,-8
		render_a(background, t0, t1, 64, 72, s0, t0, t1)
		
		render_a(char_torso, s1, s2, 48, 32, s0, zero, zero)
		addi s2,s2,32
		#render_a(char_legs_idle, s1, s2, 48, 24, s0, zero, zero)
		
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
		j M_LOOP

		# exit
		li a7,10
		ecall

# 4px per frame
# Input
RECEIVE_INPUT:	li t1,0xFF200000
		lw t0,0(t1)
		andi t0,t0,0x0001
  	 	beq t0,zero,REC_INPUT_CLN
  		lw t0,4(t1)

  		li t1,'d'
  		beq t0,t1,RI_MOVE_RIGHT
  		li t1,'a'
  		beq t0,t1,RI_MOVE_LEFT
  		
REC_INPUT_CLN:	la t1,CHAR_WALKING
  		sw zero,0(t1)
  		j REC_INPUT_END

# Move right (press d)
RI_MOVE_RIGHT:	lh t0,CHAR_POS
		addi t0,t0,4
		sh t0,CHAR_POS,t1
		
		li t0,1
		sh t0,CHAR_WALKING,t1
		
		j REC_INPUT_END

# Move left (press a)
RI_MOVE_LEFT:	lh t0,CHAR_POS
		addi t0,t0,-4
		sh t0,CHAR_POS,t1
		
		li t0,-1
		sh t0,CHAR_WALKING,t1
		
		j REC_INPUT_END

REC_INPUT_END:	ret				# retorna

.include "render.s"
