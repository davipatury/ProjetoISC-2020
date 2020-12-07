.include "macros.s"

.align 2
.data
P1_POS: .half 32, 168	# top left x, y
P2_POS: .half 240, 168

#################################
# 	  ATTACK TABLE		#
#################################
# 0:  STATIC (non-attacking)	#
###### FIRE BUTTON ATTACKS ######
# 1:  MID KICK			#
# 2:  SHORT JAB KICK		#
# 3:  FORWARD SWEEP		#
# 4:  BACKWARDS SWEEP		#
# 5:  ROUNDHOUSE		#
# 6:  HIGH BACK KICK		#
# 7:  FLYING KICK		#
# 8:  HIGH KICK			#
#### NON FIRE BUTTON ATTACKS ####
# 9:  JAB			#
# 10: CROUCH BLOCK		#
# 11: BACK SOMERSAULT		#
# 12: FORWARD SOMERSAULT	#
# 13: JUMP			#
# 14: HIGH PUNCH		#
#################################
P1_ATTACK: .byte 0, 0	# attack, curr sprite
P1_WALKING: .byte 0, 0	# direction, curr sprite

P2_ATTACK: .byte 0, 0
P2_WALKING: .byte 0, 0

#################################
#	    MAP TABLE		#
#################################
# 0:  STATUE			#
# 1:  TOWER			#
# 2:  BEACH			#
# 3:  TEMPLE			#
#################################
CURRENT_MAP: .byte 1


.text
SPLASH:		reset_frame()
		render(splash, 0, 0, 320, 240, zero, 0, 0)

SPLASH_LOOP:	li t1,0xFF200000
		lw t0,0(t1)
		andi t0,t0,0x0001
  	 	beq t0,zero,SPLASH_LOOP
  		lw t0,4(t1)
 
  		li t1,'1'
  		bne t0,t1,SPLASH_LOOP

GAME:		background_offset(s0, t0)
		render_a(backgrounds, zero, zero, 320, 240, zero, zero, s0)
		li t0, 1
		render_a(backgrounds, zero, zero, 320, 240, t0, zero, s0)

GAME_LOOP:	call RECEIVE_INPUT
		#call MUSIC

		#################################################
		#		REGISTERS TABLE			#
		#################################################
		#	s0 = drawing frame			#
		#	s1 = current player x			#
		#	s2 = current player y			#
		#	s3 = current player position address	#
		#	s4 = sprite y offset			#
		#	s5 = multiplier (1 = P1, -1 = P2)	#
		#	s6 = state address			#
		#	s9 = return address			#
		#################################################

		next_frame(s0)
		
		# Clear background
		# TODO: Implement a more efficient way to clear background,
		# 	the current one is slow af
		background_offset(s1, t0)	# s1 is not used yet
		load_pos(P1_POS, t0, t1)
		addi t0,t0,-24
		addi t1,t1,-24
		add t2,t1,s1
		render_a(backgrounds, t0, t1, 120, 96, s0, t0, t2)

		#load_pos(P2_POS, t0, t1)
		#addi t0,t0,-24
		#addi t1,t1,-24
		#add t2,t1,s1
		#render_a(backgrounds, t0, t1, 120, 96, s0, t0, t2)
		
		#########################
		#	PLAYER 1	#
		#########################
		load_pos(P1_POS, s1, s2)
		la s3,P1_POS
		mv s4,zero
		li s5,1
		la s6,P1_ATTACK
		
		lb a0,0(s6)
		jal s9,ATTACK
		
		#########################
		#	PLAYER 2	#
		#########################
		#load_pos(P2_POS, s1, s2)
		#la s3,P2_POS
		#li s4,56
		#li s5,-1
		#la s6,P2_ATTACK
		
		#lb a0,0(s6)
		#jal s9,ATTACK
		
		j FRAME_END
		
ATTACK:		beqz a0,STATIC_CHAR
		li t1,1
		beq a0,t1,MID_KICK
		li t1,2
		beq a0,t1,SJ_KICK
		li t1,3
		beq a0,t1,FWD_SWEEP
		li t1,4
		beq a0,t1,BWD_SWEEP
		li t1,5
		beq a0,t1,ROUNDHOUSE
		li t1,6
		beq a0,t1,HIGH_BK_KICK
		li t1,7
		beq a0,t1,FLYING_KICK
		li t1,8
		beq a0,t1,HIGH_KICK
		
		li t1,9
		beq a0,t1,JAB
		li t1,10
		beq a0,t1,CROUCH_BLOCK
		#li t1,11
		#beq a0,t1,BSOMERSAULT
		#li t1,12
		#beq a0,t1,FSOMERSAULT
		li t1,13
		beq a0,t1,JUMP
		li t1,14
		beq a0,t1,HIGH_PUNCH
		
		jr s9

#########################################
#	MID KICK MOVEMENT		#
#########################################
MID_KICK:	lbu t0,1(s6)		# current sprite
		
		beqz t0,MID_KICK_0
		li t1,1
		beq t0,t1,MID_KICK_1
		li t1,2
		beq t0,t1,MID_KICK_2
		li t1,5
		blt t0,t1,MID_KICK_3
		beq t0,t1,MID_KICK_1
		li t1,6
		beq t0,t1,MID_KICK_0
		j ATTACK_END

MID_KICK_0:	render_a(kick, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
MID_KICK_1:	render_a(mid_kick_1, s1, s2, 56, 56, s0, zero, s4)
		j ATTACK_ANIM_E
MID_KICK_2:	render_a(mid_kick_2, s1, s2, 76, 56, s0, zero, s4)
		j ATTACK_ANIM_E
MID_KICK_3:	render_a(mid_kick_2, s1, s2, 76, 56, s0, zero, s4)
		j ATTACK_ANIM_E

#########################################
#	SHORT JAB KICK MOVEMENT		#
#########################################
SJ_KICK:	lbu t0,1(s6)		# current sprite
		
		beqz t0,SJ_KICK_0
		li t1,3
		ble t0,t1,SJ_KICK_1
		li t1,4
		beq t0,t1,SJ_KICK_0
		j ATTACK_END
		
SJ_KICK_0:	render_a(kick, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
SJ_KICK_1:	render_a(sj_kick, s1, s2, 56, 56, s0, zero, s4)
		j ATTACK_ANIM_E

#########################################
#	FORWARD SWEEP MOVEMENT		#
#########################################
FWD_SWEEP:	lbu t0,1(s6)		# current sprite
		
		beqz t0,FWD_SWEEP_0
		li t1,1
		beq t0,t1,FWD_SWEEP_1
		li t1,5
		blt t0,t1,FWD_SWEEP_2
		beq t0,t1,FWD_SWEEP_1
		li t1,6
		beq t0,t1,FWD_SWEEP_0
		j ATTACK_END
		
FWD_SWEEP_0:	render_a(crouch_block, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FWD_SWEEP_1:	render_a(fwd_sweep_1, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FWD_SWEEP_2:	render_a(fwd_sweep_2, s1, s2, 76, 56, s0, zero, s4)
		j ATTACK_ANIM_E

#########################################
#	BACKWARDS SWEEP MOVEMENT	#
#########################################
BWD_SWEEP:	lbu t0,1(s6)		# current sprite
		
		beqz t0,BWD_SWEEP_0
		li t1,1
		beq t0,t1,BWD_SWEEP_1
		li t1,2
		beq t0,t1,BWD_SWEEP_2
		li t1,5
		blt t0,t1,BWD_SWEEP_3
		beq t0,t1,BWD_SWEEP_4
		li t1,6
		beq t0,t1,BWD_SWEEP_1
		li t1,7
		beq t0,t1,BWD_SWEEP_0
		j ATTACK_END
		
BWD_SWEEP_0:	render_a(crouch_block, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
BWD_SWEEP_1:	render_a(bwd_sweep_1, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
BWD_SWEEP_2:	apply_multiplier(24, t1, s5)
		h_decrement_ar(s3, t1, 0, t0)
		load_pos_r(s3, s1, s2)
		render_a(bwd_sweep_2, s1, s2, 76, 56, s0, zero, s4)
		j ATTACK_ANIM_E
BWD_SWEEP_3:	render_a(bwd_sweep_2, s1, s2, 76, 56, s0, zero, s4)
		j ATTACK_ANIM_E
BWD_SWEEP_4:	render_a(bwd_sweep_2, s1, s2, 76, 56, s0, zero, s4)
		apply_multiplier(24, t1, s5)
		h_increment_ar(s3, t1, 0, t0)
		j ATTACK_ANIM_E

#########################################
#	ROUNDHOUSE MOVEMENT		#
#########################################
ROUNDHOUSE:	lbu t0,1(s6)		# current sprite
		
		beqz t0,ROUNDHOUSE_0
		li t1,1
		beq t0,t1,ROUNDHOUSE_1
		li t1,2
		beq t0,t1,ROUNDHOUSE_2
		li t1,3
		beq t0,t1,ROUNDHOUSE_3
		li t1,8
		blt t0,t1,ROUNDHOUSE_4
		beq t0,t1,ROUNDHOUSE_5
		li t1,9
		beq t0,t1,ROUNDHOUSE_6
		j ATTACK_END
		
ROUNDHOUSE_0:	render_a(roundhouse_1, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
ROUNDHOUSE_1:	render_a(roundhouse_2, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
ROUNDHOUSE_2:	render_a(roundhouse_3, s1, s2, 60, 56, s0, zero, s4)
		j ATTACK_ANIM_E
ROUNDHOUSE_3:	render_a(roundhouse_4, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
ROUNDHOUSE_4:	render_a(roundhouse_5, s1, s2, 72, 56, s0, zero, s4)
		j ATTACK_ANIM_E
ROUNDHOUSE_5:	render_a(mid_kick_1, s1, s2, 56, 56, s0, zero, s4)
		j ATTACK_ANIM_E
ROUNDHOUSE_6:	render_a(kick, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E

#########################################
#	HIGH BACK KICK MOVEMENT		#
#########################################
HIGH_BK_KICK:	lbu t0,1(s6)		# current sprite
		
		beqz t0,HIGH_BK_KICK_0
		li t1,1
		beq t0,t1,HIGH_BK_KICK_1
		li t1,5
		blt t0,t1,HIGH_BK_KICK_2
		beq t0,t1,HIGH_BK_KICK_3
		li t1,6
		beq t0,t1,HIGH_BK_KICK_0
		j ATTACK_END
		
HIGH_BK_KICK_0:	render_a(high_bk_kick_1, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
HIGH_BK_KICK_1:	apply_multiplier(16, t1, s5)
		h_decrement_ar(s3, t1, 0, t0)
		load_pos_r(s3, s1, s2)
		render_a(high_bk_kick_2, s1, s2, 56, 56, s0, zero, s4)
		j ATTACK_ANIM_E
HIGH_BK_KICK_2:	render_a(high_bk_kick_3, s1, s2, 72, 56, s0, zero, s4)
		j ATTACK_ANIM_E
HIGH_BK_KICK_3:	render_a(high_bk_kick_2, s1, s2, 56, 56, s0, zero, s4)
		apply_multiplier(16, t1, s5)
		h_increment_ar(s3, t1, 0, t0)
		j ATTACK_ANIM_E

#########################################
#	FLYING KICK MOVEMENT		#
#########################################
FLYING_KICK:	lbu t0,1(s6)		# current sprite
		
		beqz t0,FLYING_KICK_0
		li t1,1
		beq t0,t1,FLYING_KICK_1
		li t1,2
		beq t0,t1,FLYING_KICK_2
		li t1,3
		beq t0,t1,FLYING_KICK_3
		li t1,8
		blt t0,t1,FLYING_KICK_4
		beq t0,t1,FLYING_KICK_5
		li t1,9
		beq t0,t1,FLYING_KICK_6
		li t1,10
		beq t0,t1,FLYING_KICK_7
		j ATTACK_END
		
FLYING_KICK_0:	render_a(kick, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FLYING_KICK_1:	render_a(jump, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FLYING_KICK_2:	apply_multiplier(8, t1, s5)
		h_decrement_ar(s3, t1, 2, t0)		# y -= 8
		load_pos_r(s3, s1, s2)
		render_a(jump, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FLYING_KICK_3:	apply_multiplier(8, t1, s5)
		h_increment_ar(s3, t1, 0, t0)		# x += 8
		apply_multiplier(16, t1, s5)
		h_decrement_ar(s3, t1, 2, t0)		# y -= 16	
		load_pos_r(s3, s1, s2)
		render_a(flying_kick_1, s1, s2, 64, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FLYING_KICK_4:	render_a(flying_kick_1, s1, s2, 64, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FLYING_KICK_5:	apply_multiplier(8, t1, s5)
		h_increment_ar(s3, t1, 2, t0)		# y += 8	
		load_pos_r(s3, s1, s2)
		render_a(flying_kick_1, s1, s2, 64, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FLYING_KICK_6:	apply_multiplier(16, t1, s5)
		h_increment_ar(s3, t1, 2, t0)		# y += 16	
		load_pos_r(s3, s1, s2)
		render_a(jump, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FLYING_KICK_7:	render_a(landing, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E

#########################################
#	HIGH KICK MOVEMENT		#
#########################################
HIGH_KICK:	lbu t0,1(s6)		# current sprite
		
		beqz t0,HIGH_KICK_0
		li t1,1
		beq t0,t1,HIGH_KICK_1
		li t1,5
		blt t0,t1,HIGH_KICK_2
		beq t0,t1,HIGH_KICK_1
		li t1,6
		beq t0,t1,HIGH_KICK_0
		j ATTACK_END
		
HIGH_KICK_0:	render_a(kick, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
HIGH_KICK_1:	render_a(high_kick_1, s1, s2, 56, 56, s0, zero, s4)
		j ATTACK_ANIM_E
HIGH_KICK_2:	render_a(high_kick_2, s1, s2, 68, 56, s0, zero, s4)
		j ATTACK_ANIM_E

#########################################
#	JAB MOVEMENT			#
#########################################
JAB:		lbu t0,1(s6)		# current sprite
		
		beqz t0,JAB_0
		li t1,2
		ble t0,t1,JAB_1
		li t1,3
		beq t0,t1,JAB_0
		j ATTACK_END
		
JAB_0:		render_a(punch, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
JAB_1:		render_a(jab, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E

#########################################
#	CROUCH BLOCK MOVEMENT		#
#########################################
CROUCH_BLOCK:	lbu t0,1(s6)		# current sprite
		
		li t1,3
		ble t0,t1,CROUCH_BLOCK_0
		j ATTACK_END
		
CROUCH_BLOCK_0:	render_a(crouch_block, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E

#########################################
#	JUMP MOVEMENT			#
#########################################
JUMP:		lbu t0,1(s6)		# current sprite
		
		beqz t0,JUMP_0
		li t1,1
		beq t0,t1,JUMP_1
		li t1,2
		beq t0,t1,JUMP_2
		li t1,7
		blt t0,t1,JUMP_3
		beq t0,t1,JUMP_4
		li t1,8
		beq t0,t1,JUMP_5
		j ATTACK_END
		
JUMP_0:		render_a(landing, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
JUMP_1:		render_a(jump, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
JUMP_2:		apply_multiplier(8, t1, s5)
		h_decrement_ar(s3, t1, 2, t0)		# y -= 8
		load_pos_r(s3, s1, s2)
		render_a(jump, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
JUMP_3:		render_a(jump, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
JUMP_4:		apply_multiplier(8, t1, s5)
		h_increment_ar(s3, t1, 2, t0)		# y += 8
		load_pos_r(s3, s1, s2)
		render_a(jump, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
JUMP_5:		render_a(landing, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E

#########################################
#	HIGH PUNCH MOVEMENT		#
#########################################
HIGH_PUNCH:	lbu t0,1(s6)		# current sprite
		
		beqz t0,HIGH_PUNCH_0
		li t1,2
		ble t0,t1,HIGH_PUNCH_1
		li t1,3
		beq t0,t1,HIGH_PUNCH_0
		j ATTACK_END
		
HIGH_PUNCH_0:	render_a(punch, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
HIGH_PUNCH_1:	render_a(high_punch, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E

#########################################
#	GENERIC ATTACK OPERATIONS	#
#########################################
ATTACK_ANIM_E:	li t1,1
		b_increment_ar(s6, t1, 1, t0)
		jr s9

ATTACK_END:	sh zero,0(s6)
		j STATIC_CHAR

#########################################
#	NON-ATTACKING MOVEMENT		#
#########################################
STATIC_CHAR:	render_a(char_torso, s1, s2, 48, 32, s0, zero, s4)
		addi s2,s2,32

#########################################
#	WALKING ANIMATION		#
#########################################
		lb t0,2(s6)		# direction
		beqz t0,WALK_IDLE	# if not moving (direction == 0) draw idle sprite
		
		li t1,-1		# -1 = reverse
		beq t0,t1,WALK_REV

		lbu t0,3(s6)		# current sprite
		li t2,3
		blt t0,t2,WALK_CONT	# if curr sprite < 3 then continue animation
		sb zero,3(s6)		# else restart animation counter
		j WALK_IDLE		# draw idle sprite

WALK_CONT:	li t1,48
		mul t1,t1,t0		# curr sprite * 48 = x in spritesheet
		render_a(walking_1, s1, s2, 48, 24, s0, t1, s4)
		li t1,1
		b_increment_ar(s6, t1, 3, t0)
		jr s9

WALK_REV:	lbu t0,3(s6)			# current sprite
		beqz t0,WALK_REV_SET
		bgtz t0,WALK_REV_CONT		# if curr sprite > 0 then continue animation
		li t2,3				# goto last sprite
		sb t2,3(s6)			# else restart animation counter
		j WALK_IDLE			# draw idle sprite

WALK_REV_SET:	li t0,3
		sb t0,3(s6)
		j WALK_REV_CONT

WALK_REV_CONT:	li t1,48
		addi t0,t0,-1
		mul t1,t1,t0		# curr sprite * 48 = x in spritesheet
		render_a(walking_1, s1, s2, 48, 24, s0, t1, s4)
		li t1,1
		b_decrement_ar(s6, t1, 3, t0)
		jr s9

WALK_IDLE:	render_a(char_legs_idle, s1, s2, 48, 24, s0, zero, s4)
		jr s9

#########################
FRAME_END:	toggle_frame()
		j GAME_LOOP

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

		# P1
  		check_key('d', RI_P1_MV_RIGHT, t0, t1)
  		check_key('c', RI_JAB, t0, t1)
  		check_key('x', RI_CROUCH_BLK, t0, t1)
  		check_key('z', RI_BSOMERSAULT, t0, t1)
  		check_key('a', RI_P1_MV_LEFT, t0, t1)
  		check_key('q', RI_FSOMERSAULT, t0, t1)
  		check_key('w', RI_JUMP, t0, t1)
  		check_key('e', RI_HIGH_PUNCH, t0, t1)
 
 		# Fire movements
  		check_key('D', RI_MID_KICK, t0, t1)
  		check_key('C', RI_SJ_KICK, t0, t1)
  		check_key('X', RI_FWD_SWEEP, t0, t1)
  		check_key('Z', RI_BWD_SWEEP, t0, t1)
  		check_key('A', RI_ROUNDHOUSE, t0, t1)
  		check_key('Q', RI_HIGH_B_KICK, t0, t1)
  		check_key('W', RI_FLYING_KICK, t0, t1)
  		check_key('E', RI_HIGH_KICK, t0, t1)
  		
REC_INPUT_CLN:	la t1,P1_WALKING
  		sh zero,0(t1)
  		j REC_INPUT_END

# Move right 		(press d)
RI_P1_MV_RIGHT:	lb t0,P1_ATTACK
		bnez t0,REC_INPUT_CLN
		h_increment(P1_POS, 4, 0, t0, t1)

		la t1,P1_WALKING
		li t0,1
		sb t0,0(t1)
		
		j REC_INPUT_END

# Move left 		(press a)
RI_P1_MV_LEFT:	lb t0,P1_ATTACK
		bnez t0,REC_INPUT_CLN
		h_decrement(P1_POS, 4, 0, t0, t1)
		la t1,P1_WALKING
		li t0,0xff
		sb t0,0(t1)
		
		j REC_INPUT_END

# Mid kick		(press D, shift + d)
RI_MID_KICK:	register_p1_attack(1)
# Short jab kick	(press C, shift + c)
RI_SJ_KICK:	register_p1_attack(2)
# Forward sweep		(press X, shift + x)
RI_FWD_SWEEP:	register_p1_attack(3)
# Backwards sweep	(press Z, shift + z)
RI_BWD_SWEEP:	register_p1_attack(4)
# Roundhouse		(press A, shift + a)
RI_ROUNDHOUSE:	register_p1_attack(5)
# High back kick	(press Q, shift + q)
RI_HIGH_B_KICK:	register_p1_attack(6)
# Fling kick		(press W, shift + w)
RI_FLYING_KICK:	register_p1_attack(7)
# High kick		(press E, shift + e)
RI_HIGH_KICK:	register_p1_attack(8)

# Jab			(press c)
RI_JAB:		register_p1_attack(9)
# Crouch block		(press x)
RI_CROUCH_BLK:	register_p1_attack(10)
# Back somersault	(press z)
RI_BSOMERSAULT:	register_p1_attack(11)
# Forward somersault	(press q)
RI_FSOMERSAULT:	register_p1_attack(12)
# Jump			(press w)
RI_JUMP:	register_p1_attack(13)
# High punch		(press e)
RI_HIGH_PUNCH:	register_p1_attack(14)

REC_INPUT_END:	ret	# retorna

.align 2
.data
.include "sprites/misc/splash.data"

.include "sprites/misc/backgrounds.data"

.include "sprites/static_char/char_torso.data"
.include "sprites/static_char/char_legs_idle.data"
.include "sprites/static_char/walking_1.data"

.include "sprites/generic/crouch_block.data"
.include "sprites/generic/kick.data"
.include "sprites/generic/punch.data"
.include "sprites/generic/jump.data"
.include "sprites/generic/landing.data"

.include "sprites/mid_kick/mid_kick_1.data"
.include "sprites/mid_kick/mid_kick_2.data"

.include "sprites/sj_kick/sj_kick.data"

.include "sprites/fwd_sweep/fwd_sweep_1.data"
.include "sprites/fwd_sweep/fwd_sweep_2.data"

.include "sprites/bwd_sweep/bwd_sweep_1.data"
.include "sprites/bwd_sweep/bwd_sweep_2.data"

.include "sprites/roundhouse/roundhouse_1.data"
.include "sprites/roundhouse/roundhouse_2.data"
.include "sprites/roundhouse/roundhouse_3.data"
.include "sprites/roundhouse/roundhouse_4.data"
.include "sprites/roundhouse/roundhouse_5.data"

.include "sprites/high_bk_kick/high_bk_kick_1.data"
.include "sprites/high_bk_kick/high_bk_kick_2.data"
.include "sprites/high_bk_kick/high_bk_kick_3.data"

.include "sprites/flying_kick/flying_kick_1.data"

.include "sprites/high_kick/high_kick_1.data"
.include "sprites/high_kick/high_kick_2.data"

.include "sprites/jab/jab.data"

.include "sprites/high_punch/high_punch.data"

.text
.include "render.s"
.include "music.s"
