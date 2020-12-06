.include "macros.s"

.align 2
.data
.include "sprites/misc/background.data"
.include "sprites/static_char/char_torso.data"
.include "sprites/static_char/char_legs_idle.data"
.include "sprites/static_char/walking_1.data"
.include "sprites/generic/crouch_block.data"
.include "sprites/generic/kick.data"
.include "sprites/mid_kick/mid_kick_1.data"
.include "sprites/mid_kick/mid_kick_2.data"
.include "sprites/high_kick/high_kick_1.data"
.include "sprites/high_kick/high_kick_2.data"
.include "sprites/sj_kick/sj_kick.data"
.include "sprites/fwd_sweep/fwd_sweep_1.data"
.include "sprites/fwd_sweep/fwd_sweep_2.data"

CHAR_POS: .half 32, 168		# top left x, y
CHAR_WALKING: .byte 0, 0	# direction, curr sprite

#################################
# ATTACK TABLE			#
#################################
# 0: STATIC (non-attacking)	#
#################################
# FIRE BUTTON ATTACKS		#
# 1: MID KICK			#
# 2: HIGH KICK			#
# 3: SHORT JAB KICK		#
# 4: FORWARD SWEEP		#
#################################
# NON FIRE BUTTON ATTACKS	#
#				#
#################################
CHAR_ATTACK: .byte 0, 0

.text
		render(background, 0, 0, 320, 240, zero, 0, 0)
		li t0, 1
		render(background, 0, 0, 320, 240, t0, 0, 0)

M_LOOP:		call RECEIVE_INPUT
		next_frame(s0)
		load_char_pos(s1, s2)
		
		addi t0,s1,-8
		addi t1,s2,-8
		render_a(background, t0, t1, 100, 72, s0, t0, t1)
		
		lb t0,CHAR_ATTACK
		beq t0,zero,STATIC_CHAR
		
		li t1,1
		beq t0,t1,MID_KICK
		li t1,2
		beq t0,t1,HIGH_KICK
		li t1,3
		beq t0,t1,SJ_KICK
		li t1,4
		beq t0,t1,FWD_SWEEP
		
		j FRAME_END

#################################
#	MID KICK MOVEMENT	#
#################################
MID_KICK:	la t1,CHAR_ATTACK
		lbu t0,1(t1)		# current sprite
		
		beqz t0,MID_KICK_0
		li t1,1
		beq t0,t1,MID_KICK_1
		li t1,2
		beq t0,t1,MID_KICK_2
		li t1,3
		beq t0,t1,MID_KICK_1
		li t1,4
		beq t0,t1,MID_KICK_0
		j ATTACK_END

MID_KICK_0:	render_a(kick, s1, s2, 48, 56, s0, zero, zero)
		j ATTACK_ANIM_E
MID_KICK_1:	render_a(mid_kick_1, s1, s2, 56, 56, s0, zero, zero)
		j ATTACK_ANIM_E
MID_KICK_2:	render_a(mid_kick_2, s1, s2, 76, 56, s0, zero, zero)
		j ATTACK_ANIM_E

#################################
#	HIGH KICK MOVEMENT	#
#################################
HIGH_KICK:	la t1,CHAR_ATTACK
		lbu t0,1(t1)		# current sprite
		
		beqz t0,HIGH_KICK_0
		li t1,1
		beq t0,t1,HIGH_KICK_1
		li t1,2
		beq t0,t1,HIGH_KICK_2
		li t1,3
		beq t0,t1,HIGH_KICK_1
		li t1,4
		beq t0,t1,HIGH_KICK_0
		j ATTACK_END
		
HIGH_KICK_0:	render_a(kick, s1, s2, 48, 56, s0, zero, zero)
		j ATTACK_ANIM_E
HIGH_KICK_1:	render_a(high_kick_1, s1, s2, 56, 56, s0, zero, zero)
		j ATTACK_ANIM_E
HIGH_KICK_2:	render_a(high_kick_2, s1, s2, 68, 56, s0, zero, zero)
		j ATTACK_ANIM_E

#########################################
#	SHORT JAB KICK MOVEMENT		#
#########################################
SJ_KICK:	la t1,CHAR_ATTACK
		lbu t0,1(t1)		# current sprite
		
		beqz t0,SJ_KICK_0
		li t1,4
		ble t0,t1,SJ_KICK_1
		li t1,5
		beq t0,t1,SJ_KICK_0
		j ATTACK_END
		
SJ_KICK_0:	render_a(kick, s1, s2, 48, 56, s0, zero, zero)
		j ATTACK_ANIM_E
SJ_KICK_1:	render_a(sj_kick, s1, s2, 56, 56, s0, zero, zero)
		j ATTACK_ANIM_E

#########################################
#	FORWARD SWEEP MOVEMENT		#
#########################################
FWD_SWEEP:	la t1,CHAR_ATTACK
		lbu t0,1(t1)		# current sprite
		
		beqz t0,FWD_SWEEP_0
		li t1,1
		beq t0,t1,FWD_SWEEP_1
		li t1,2
		beq t0,t1,FWD_SWEEP_2
		li t1,3
		beq t0,t1,FWD_SWEEP_1
		li t1,4
		beq t0,t1,FWD_SWEEP_0
		j ATTACK_END
		
FWD_SWEEP_0:	render_a(crouch_block, s1, s2, 48, 56, s0, zero, zero)
		j ATTACK_ANIM_E
FWD_SWEEP_1:	render_a(fwd_sweep_1, s1, s2, 48, 56, s0, zero, zero)
		j ATTACK_ANIM_E
FWD_SWEEP_2:	render_a(fwd_sweep_2, s1, s2, 76, 56, s0, zero, zero)
		j ATTACK_ANIM_E

#########################################
#	GENERIC ATTACK OPERATIONS	#
#########################################
ATTACK_ANIM_E:	b_increment(CHAR_ATTACK, 1, 1, t0, t1)
		j FRAME_END

ATTACK_END:	la t0,CHAR_ATTACK
		sh zero,0(t0)
		j STATIC_CHAR

######################################
#	NON-ATTACKING MOVEMENT	     #
######################################
STATIC_CHAR:	render_a(char_torso, s1, s2, 48, 32, s0, zero, zero)
		addi s2,s2,32

#################################
#	WALKING ANIMATION	#
#################################
		lb t0,CHAR_WALKING	# direction
		beqz t0,WALK_IDLE	# if not moving (direction == 0) draw idle sprite
		
		li t1,-1		# -1 = reverse
		beq t0,t1,WALK_REV

		la t1,CHAR_WALKING
		lbu t0,1(t1)		# current sprite
		li t2,3
		blt t0,t2,WALK_CONT	# if curr sprite < 3 then continue animation
		sb zero,1(t1)		# else restart animation counter
		j WALK_IDLE		# draw idle sprite

WALK_CONT:	li t1,48
		mul t1,t1,t0		# curr sprite * 48 = x in spritesheet
		render_a(walking_1, s1, s2, 48, 24, s0, t1, zero)
		b_increment(CHAR_WALKING, 1, 1, t0, t1)
		j FRAME_END

WALK_REV:	la t1,CHAR_WALKING
		lbu t0,1(t1)			# current sprite
		bgt t0,zero,WALK_REV_CONT	# if curr sprite < 0 then continue animation
		li t2,2				# goto last sprite
		sb t2,1(t1)			# else restart animation counter
		j WALK_IDLE			# draw idle sprite

WALK_REV_CONT:	li t1,48
		mul t1,t1,t0		# curr sprite * 48 = x in spritesheet
		render_a(walking_1, s1, s2, 48, 24, s0, t1, zero)
		b_decrement(CHAR_WALKING, 1, 1, t0, t1)
		j FRAME_END

WALK_IDLE:	render_a(char_legs_idle, s1, s2, 48, 24, s0, zero, zero)

##############################
FRAME_END:	toggle_frame()
		j M_LOOP

		li a7,10
		ecall

#########################
#	USER INPUT	#
#########################
RECEIVE_INPUT:	li t1,0xFF200000
		lw t0,0(t1)
		andi t0,t0,0x0001
  	 	beq t0,zero,REC_INPUT_CLN
  		lw t0,4(t1)

  		check_key('d', RI_MOVE_RIGHT, t0, t1)
  		check_key('a', RI_MOVE_LEFT, t0, t1)
  		check_key('D', RI_MID_KICK, t0, t1)
  		check_key('E', RI_HIGH_KICK, t0, t1)
  		check_key('C', RI_SJ_KICK, t0, t1)
  		check_key('X', RI_FWD_SWEEP, t0, t1)
  		
REC_INPUT_CLN:	la t1,CHAR_WALKING
  		sh zero,0(t1)
  		j REC_INPUT_END

# Move right (press d)
RI_MOVE_RIGHT:	lh t0,CHAR_POS
		addi t0,t0,4
		sh t0,CHAR_POS,t1
		
		la t1,CHAR_WALKING
		li t0,1			# 00000000 00000001 <- curr sprite = 0, dir = 1
		sh t0,0(t1)
		
		j REC_INPUT_END

# Move left (press a)
RI_MOVE_LEFT:	lh t0,CHAR_POS
		addi t0,t0,-4
		sh t0,CHAR_POS,t1
		
		la t1,CHAR_WALKING
		li t0,0x2ff		# 00000010 11111111 <- curr sprite = 2, dir = -1
		sh t0,0(t1)
		
		j REC_INPUT_END

# Mid kick (press D, shift + d)
RI_MID_KICK:	register_attack(1)
# High kick (press E, shift + e)
RI_HIGH_KICK:	register_attack(2)
# Short jab kick (press C, shift + c)
RI_SJ_KICK:	register_attack(3)
# Forward sweep (press X, shift + x)
RI_FWD_SWEEP:	register_attack(4)

REC_INPUT_END:	ret				# retorna

.include "render.s"