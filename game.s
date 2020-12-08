.include "macros.s"

.align 2
.data
P1_POS:		.half 32, 168		# top left x, y
P2_POS:		.half 240, 168

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
P1_ATTACK:	.byte 0, 0		# attack, curr sprite
P1_WALKING:	.byte 0, 0		# direction, curr sprite

P2_ATTACK:	.byte 0, 0
P2_WALKING:	.byte 0, 0

#################################
#	    MAP TABLE		#
#################################
# 0:  STATUE			#
# 1:  TOWER			#
# 2:  BEACH			#
# 3:  TEMPLE			#
#################################
CURRENT_MAP:	.byte 1
SPLASH_SEL:	.byte 0
GAMEMODE:	.byte 0			# 0 = one player, 1 = two player

#################################################################################
#	Usado para fazer a limpeza inteligente do fundo				#
#	Consiste numa queue composta por (x, y, w, z) que serão utilizados	#
#	para fazer a re-renderização do fundo no próximo frame.			#
#################################################################################
FRAME_CLR:	.word 0, 0, 0, 0, 0, 0, 0, 0

.text
SPLASH:		reset_frame()
		render_s(splash, zero, zero, 320, 240, zero, zero, zero)
		
		la t0,RECEIVE_INPUT
		la t1,RI_HIGH_PUNCH
		sub a0,t0,t1
		li a7,1
		ecall

SPLASH_RENDER:	lb s0,SPLASH_SEL
		li s1,32
		li s2,80
		
		mul t0,s1,s0
		addi t0,t0,168
		render_s(splash_selection, s2, t0, 160, 28, zero, zero, zero)
		
		xori s0,s0,1
		mul t0,s1,s0
		addi t0,t0,168
		render_s(splash, s2, t0, 160, 28, zero, s2, t0)

SPLASH_LOOP:	li t1,0xFF200000
		lw t0,0(t1)
		andi t0,t0,0x0001
  	 	beq t0,zero,SPLASH_LOOP

  		lw t0,4(t1) 
  		li t1,'w'
  		beq t0,t1,TOGGLE_SPLASH
  		li t1,'s'
  		beq t0,t1,TOGGLE_SPLASH
  		li t1,10 # enter
  		beq t0,t1,START_GAME

  		j SPLASH_LOOP

TOGGLE_SPLASH:	la t0,SPLASH_SEL
		lb t1,0(t0)
		xori t1,t1,1
		sb t1,0(t0)
		j SPLASH_RENDER

START_GAME:	lb t0,SPLASH_SEL
		la t1,GAMEMODE
		sb t0,0(t1)

GAME:		background_offset(s0, t0)
		render_s(backgrounds, zero, zero, 320, 240, zero, zero, s0)
		li t0,1
		render_s(backgrounds, zero, zero, 320, 240, t0, zero, s0)
		j GAME_LOOP

GAME_LOOP:	call RECEIVE_INPUT
		#call MUSIC
		
		next_frame(s0)
		#################################################
		#	Limpeza inteligente do background	#
		#################################################
		la s1,FRAME_CLR
		addi s1,s1,16
		
		lh t0,0(s1)
		lh t1,2(s1)
		lhu t2,4(s1)
		lhu t3,6(s1)
		
		background_offset(s2, t4)
		add t4,t1,s2
		render_r(backgrounds, t0, t1, t2, t3, s0, t0, t4)
		
		addi s1,s1,8
		lh t0,0(s1)
		lh t1,2(s1)
		lhu t2,4(s1)
		lhu t3,6(s1)

		background_offset(s2, t4)
		add t4,t1,s2
		render_r(backgrounds, t0, t1, t2, t3, s0, t0, t4)

		#################################################
		#	     TABELA DE REGISTRADORES		#
		#################################################
		#	s0 = frame a desenhar			#
		#	s1 = coordenada x			#
		#	s2 = coordenada y			#
		#	s3 = endereço da coordenada do jogador	#
		#	s4 = offset y do sprite			#
		#	s5 = multiplicador (1 = P1, -1 = P2)	#
		#	s6 = endereço de estado			#
		#	s9 = endereço de retorno		#
		#################################################
		
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
		load_pos(P2_POS, s1, s2)
		la s3,P2_POS
		li s4,0#56
		li s5,-1
		la s6,P2_ATTACK
		
		lb a0,0(s6)
		jal s9,ATTACK
		
		toggle_frame()
		j GAME_LOOP

#########################################
#	NON-ATTACKING MOVEMENT		#
#########################################
STATIC_CHAR:	render_s(char_torso, s1, s2, 48, 32, s0, zero, s4)
		addi s2,s2,32

#########################################
#	WALKING ANIMATION		#
#########################################
		lb t0,2(s6)			# direction
		beqz t0,WALK_IDLE		# if not moving (direction == 0) draw idle sprite
		
		li t1,-1			# -1 = reverse
		beq t0,t1,WALK_REV

		lbu t0,3(s6)			# current sprite
		li t2,3
		blt t0,t2,WALK_CONT		# if curr sprite < 3 then continue animation
		sb zero,3(s6)			# else restart animation counter
		j WALK_IDLE			# draw idle sprite

WALK_CONT:	li t1,48
		mul t1,t1,t0			# curr sprite * 48 = x in spritesheet
		render_s(walking_1, s1, s2, 48, 24, s0, t1, s4)
		li t1,1
		b_increment_ar(s6, t1, 3, t0)
		addi s2,s2,-32
		update_clear(s1, s2, 48, 56)
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
		mul t1,t1,t0			# curr sprite * 48 = x in spritesheet
		render_s(walking_1, s1, s2, 48, 24, s0, t1, s4)
		li t1,1
		b_decrement_ar(s6, t1, 3, t0)
		addi s2,s2,-32
		update_clear(s1, s2, 48, 56)
		jr s9

WALK_IDLE:	render_s(char_legs_idle, s1, s2, 48, 24, s0, zero, s4)
		addi s2,s2,-32
		update_clear(s1, s2, 48, 56)
		jr s9

ATTACK:		beqz a0,STATIC_CHAR
		li t1,1
		beq a0,t1,A_MID_KICK
		li t1,2
		beq a0,t1,A_SJ_KICK
		li t1,3
		beq a0,t1,A_FWD_SWEEP
		li t1,4
		beq a0,t1,A_BWD_SWEEP
		li t1,5
		beq a0,t1,A_ROUNDHOUSE
		li t1,6
		beq a0,t1,A_HIGH_BK_KICK
		li t1,7
		beq a0,t1,A_FLYING_KICK
		li t1,8
		beq a0,t1,A_HIGH_KICK
		
		li t1,9
		beq a0,t1,A_JAB
		li t1,10
		beq a0,t1,A_CROUCH_BLOCK
		li t1,11
		beq a0,t1,A_BSOMERSAULT
		li t1,12
		beq a0,t1,A_FSOMERSAULT
		li t1,13
		beq a0,t1,A_JUMP
		li t1,14
		beq a0,t1,A_HIGH_PUNCH
		
		jr s9

#########################################################################################
#	Nós tivemos que usar essa solução por que o alcance da instrução 'beq'		#
#	é menor que da instrução 'jump' e isso estava limitando o desenvolvimento.	#
#########################################################################################
A_MID_KICK: 	j MID_KICK
A_SJ_KICK:	j SJ_KICK
A_FWD_SWEEP:	j FWD_SWEEP
A_BWD_SWEEP:	j BWD_SWEEP
A_ROUNDHOUSE:	j ROUNDHOUSE
A_HIGH_BK_KICK:	j HIGH_BK_KICK
A_FLYING_KICK:	j FLYING_KICK
A_HIGH_KICK:	j HIGH_KICK
A_JAB:		j JAB
A_CROUCH_BLOCK:	j CROUCH_BLOCK
A_BSOMERSAULT:	j BSOMERSAULT
A_FSOMERSAULT:	j FSOMERSAULT
A_JUMP:		j JUMP
A_HIGH_PUNCH:	j HIGH_PUNCH

#########################################
#	MID KICK MOVEMENT		#
#########################################
MID_KICK:	lbu t0,1(s6)
		
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

MID_KICK_0:	render(kick, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
MID_KICK_1:	render(mid_kick_1, s1, s2, 56, 56, s0, zero, s4)
		j ATTACK_ANIM_E
MID_KICK_2:	render(mid_kick_2, s1, s2, 76, 56, s0, zero, s4)
		j ATTACK_ANIM_E
MID_KICK_3:	render(mid_kick_2, s1, s2, 76, 56, s0, zero, s4)
		j ATTACK_ANIM_E

#########################################
#	SHORT JAB KICK MOVEMENT		#
#########################################
SJ_KICK:	lbu t0,1(s6)
		
		beqz t0,SJ_KICK_0
		li t1,3
		ble t0,t1,SJ_KICK_1
		li t1,4
		beq t0,t1,SJ_KICK_0
		j ATTACK_END
		
SJ_KICK_0:	render(kick, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
SJ_KICK_1:	render(sj_kick, s1, s2, 56, 56, s0, zero, s4)
		j ATTACK_ANIM_E

#########################################
#	FORWARD SWEEP MOVEMENT		#
#########################################
FWD_SWEEP:	lbu t0,1(s6)
		
		beqz t0,FWD_SWEEP_0
		li t1,1
		beq t0,t1,FWD_SWEEP_1
		li t1,5
		blt t0,t1,FWD_SWEEP_2
		beq t0,t1,FWD_SWEEP_1
		li t1,6
		beq t0,t1,FWD_SWEEP_0
		j ATTACK_END
		
FWD_SWEEP_0:	render(crouch_block, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FWD_SWEEP_1:	render(fwd_sweep_1, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FWD_SWEEP_2:	render(fwd_sweep_2, s1, s2, 76, 56, s0, zero, s4)
		j ATTACK_ANIM_E

#########################################
#	BACKWARDS SWEEP MOVEMENT	#
#########################################
BWD_SWEEP:	lbu t0,1(s6)
		
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
		
BWD_SWEEP_0:	render(crouch_block, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
BWD_SWEEP_1:	render(bwd_sweep_1, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
BWD_SWEEP_2:	apply_multiplier(24, t1, s5)
		h_decrement_ar(s3, t1, 0, t0)
		load_pos_r(s3, s1, s2)
		render(bwd_sweep_2, s1, s2, 76, 56, s0, zero, s4)
		j ATTACK_ANIM_E
BWD_SWEEP_3:	render(bwd_sweep_2, s1, s2, 76, 56, s0, zero, s4)
		j ATTACK_ANIM_E
BWD_SWEEP_4:	render(bwd_sweep_2, s1, s2, 76, 56, s0, zero, s4)
		apply_multiplier(24, t1, s5)
		h_increment_ar(s3, t1, 0, t0)
		j ATTACK_ANIM_E

#########################################
#	ROUNDHOUSE MOVEMENT		#
#########################################
ROUNDHOUSE:	lbu t0,1(s6)
		
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
		
ROUNDHOUSE_0:	render(roundhouse_1, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
ROUNDHOUSE_1:	render(roundhouse_2, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
ROUNDHOUSE_2:	render(roundhouse_3, s1, s2, 60, 56, s0, zero, s4)
		j ATTACK_ANIM_E
ROUNDHOUSE_3:	render(roundhouse_4, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
ROUNDHOUSE_4:	render(roundhouse_5, s1, s2, 72, 56, s0, zero, s4)
		j ATTACK_ANIM_E
ROUNDHOUSE_5:	render(mid_kick_1, s1, s2, 56, 56, s0, zero, s4)
		j ATTACK_ANIM_E
ROUNDHOUSE_6:	render(kick, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E

#########################################
#	HIGH BACK KICK MOVEMENT		#
#########################################
HIGH_BK_KICK:	lbu t0,1(s6)
		
		beqz t0,HIGH_BK_KICK_0
		li t1,1
		beq t0,t1,HIGH_BK_KICK_1
		li t1,5
		blt t0,t1,HIGH_BK_KICK_2
		beq t0,t1,HIGH_BK_KICK_3
		li t1,6
		beq t0,t1,HIGH_BK_KICK_0
		j ATTACK_END
		
HIGH_BK_KICK_0:	render(high_bk_kick_1, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
HIGH_BK_KICK_1:	apply_multiplier(16, t1, s5)
		h_decrement_ar(s3, t1, 0, t0)
		load_pos_r(s3, s1, s2)
		render(high_bk_kick_2, s1, s2, 56, 56, s0, zero, s4)
		j ATTACK_ANIM_E
HIGH_BK_KICK_2:	render(high_bk_kick_3, s1, s2, 72, 56, s0, zero, s4)
		j ATTACK_ANIM_E
HIGH_BK_KICK_3:	render(high_bk_kick_2, s1, s2, 56, 56, s0, zero, s4)
		apply_multiplier(16, t1, s5)
		h_increment_ar(s3, t1, 0, t0)
		j ATTACK_ANIM_E

#########################################
#	FLYING KICK MOVEMENT		#
#########################################
FLYING_KICK:	lbu t0,1(s6)
		
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
		
FLYING_KICK_0:	render(kick, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FLYING_KICK_1:	render(jump, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FLYING_KICK_2:	apply_multiplier(8, t1, s5)
		h_decrement_ar(s3, t1, 2, t0)		# y -= 8
		load_pos_r(s3, s1, s2)
		render(jump, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FLYING_KICK_3:	apply_multiplier(8, t1, s5)
		h_increment_ar(s3, t1, 0, t0)		# x += 8
		apply_multiplier(16, t1, s5)
		h_decrement_ar(s3, t1, 2, t0)		# y -= 16	
		load_pos_r(s3, s1, s2)
		render(flying_kick_1, s1, s2, 64, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FLYING_KICK_4:	render(flying_kick_1, s1, s2, 64, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FLYING_KICK_5:	apply_multiplier(8, t1, s5)
		h_increment_ar(s3, t1, 2, t0)		# y += 8	
		load_pos_r(s3, s1, s2)
		render(flying_kick_1, s1, s2, 64, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FLYING_KICK_6:	apply_multiplier(16, t1, s5)
		h_increment_ar(s3, t1, 2, t0)		# y += 16	
		load_pos_r(s3, s1, s2)
		render(jump, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FLYING_KICK_7:	render(landing, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E

#########################################
#	HIGH KICK MOVEMENT		#
#########################################
HIGH_KICK:	lbu t0,1(s6)
		
		beqz t0,HIGH_KICK_0
		li t1,1
		beq t0,t1,HIGH_KICK_1
		li t1,5
		blt t0,t1,HIGH_KICK_2
		beq t0,t1,HIGH_KICK_1
		li t1,6
		beq t0,t1,HIGH_KICK_0
		j ATTACK_END
		
HIGH_KICK_0:	render(kick, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
HIGH_KICK_1:	render(high_kick_1, s1, s2, 56, 56, s0, zero, s4)
		j ATTACK_ANIM_E
HIGH_KICK_2:	render(high_kick_2, s1, s2, 68, 56, s0, zero, s4)
		j ATTACK_ANIM_E

#########################################
#	JAB MOVEMENT			#
#########################################
JAB:		lbu t0,1(s6)
		
		beqz t0,JAB_0
		li t1,2
		ble t0,t1,JAB_1
		li t1,3
		beq t0,t1,JAB_0
		j ATTACK_END
		
JAB_0:		render(punch, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
JAB_1:		render(jab, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E

#########################################
#	CROUCH BLOCK MOVEMENT		#
#########################################
CROUCH_BLOCK:	lbu t0,1(s6)
		
		li t1,3
		ble t0,t1,CROUCH_BLOCK_0
		j ATTACK_END
		
CROUCH_BLOCK_0:	render(crouch_block, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E

#########################################
#	JUMP MOVEMENT			#
#########################################
JUMP:		lbu t0,1(s6)
		
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
		
JUMP_0:		render(landing, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
JUMP_1:		render(jump, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
JUMP_2:		apply_multiplier(8, t1, s5)
		h_decrement_ar(s3, t1, 2, t0)		# y -= 8
		load_pos_r(s3, s1, s2)
		render(jump, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
JUMP_3:		render(jump, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
JUMP_4:		apply_multiplier(8, t1, s5)
		h_increment_ar(s3, t1, 2, t0)		# y += 8
		load_pos_r(s3, s1, s2)
		render(jump, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
JUMP_5:		render(landing, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E

#########################################
#	HIGH PUNCH MOVEMENT		#
#########################################
HIGH_PUNCH:	lbu t0,1(s6)
		
		beqz t0,HIGH_PUNCH_0
		li t1,2
		ble t0,t1,HIGH_PUNCH_1
		li t1,3
		beq t0,t1,HIGH_PUNCH_0
		j ATTACK_END
		
HIGH_PUNCH_0:	render(punch, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
HIGH_PUNCH_1:	render(high_punch, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E

#########################################
#	BSOMERSAULT MOVEMENT		#
#########################################
BSOMERSAULT:	lbu t0,1(s6)
		
		beqz t0,BSOMERSAULT_0
		li t1,1
		beq t0,t1,BSOMERSAULT_1
		li t1,2
		beq t0,t1,BSOMERSAULT_2
		li t1,7
		blt t0,t1,BSOMERSAULT_3
		beq t0,t1,BSOMERSAULT_4
		li t1,8
		beq t0,t1,BSOMERSAULT_5
		j ATTACK_END
		
BSOMERSAULT_0:	render(landing, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
BSOMERSAULT_1:	render(jump, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
BSOMERSAULT_2:	apply_multiplier(8, t1, s5)
		h_decrement_ar(s3, t1, 2, t0)		# y -= 8
		load_pos_r(s3, s1, s2)
		render(jump, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
BSOMERSAULT_3:	render(jump, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
BSOMERSAULT_4:	apply_multiplier(8, t1, s5)
		h_increment_ar(s3, t1, 2, t0)		# y += 8
		load_pos_r(s3, s1, s2)
		render(jump, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
BSOMERSAULT_5:	render(landing, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E

#########################################
#	FSOMERSAULT MOVEMENT		#
#########################################
FSOMERSAULT:	lbu t0,1(s6)
		
		beqz t0,FSOMERSAULT_0
		li t1,1
		beq t0,t1,FSOMERSAULT_1
		li t1,2
		beq t0,t1,FSOMERSAULT_2
		li t1,7
		blt t0,t1,FSOMERSAULT_3
		beq t0,t1,FSOMERSAULT_4
		li t1,8
		beq t0,t1,FSOMERSAULT_5
		j ATTACK_END
		
FSOMERSAULT_0:	render(landing, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FSOMERSAULT_1:	render(jump, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FSOMERSAULT_2:	apply_multiplier(8, t1, s5)
		h_decrement_ar(s3, t1, 2, t0)		# y -= 8
		load_pos_r(s3, s1, s2)
		render(jump, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FSOMERSAULT_3:	render(jump, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FSOMERSAULT_4:	apply_multiplier(8, t1, s5)
		h_increment_ar(s3, t1, 2, t0)		# y += 8
		load_pos_r(s3, s1, s2)
		render(jump, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FSOMERSAULT_5:	render(landing, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E

#########################################
#	GENERIC ATTACK OPERATIONS	#
#########################################
ATTACK_ANIM_E:	li t1,1
		b_increment_ar(s6, t1, 1, t0)
		jr s9

ATTACK_END:	sh zero,0(s6)
		j STATIC_CHAR

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

EXIT:		li a7,10
		ecall

.align 2
.data
.include "sprites/misc/splash.data"
.include "sprites/misc/splash_selection.data"
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
