.include "macros.s"

############## ATENÇÃO #############
# MUDE O VALOR ABAIXO PARA 75 CASO #
# FOR RODAR O JOGO USANDO FPGRARS  #
####################################
.eqv FPG_RARS 75

.data
#################################
# 	  STATE TABLE		#
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
########## MISC STATES ##########
# 15: BOWING			#
# 16: DEATH			#
#################################
P1_STATE:	.byte 0, 0		# attack, curr sprite
P1_WALKING:	.byte 0, 0		# direction, curr sprite
P1_POS:		.half 32, 168		# top left x, y

P2_STATE:	.byte 0, 0
P2_WALKING:	.byte 0, 0
P2_POS:		.half 240, 168

P1_HITBOX:	.byte 0, 0, 0, 0
P2_HITBOX:	.byte 0, 0, 0, 0

P1_HURTBOX:	.byte 16, 1, 10, 53
P2_HURTBOX:	.byte 22, 1, 10, 53

DEF_HURTBOX:	.byte 16, 1, 10, 53
DEF_R_HURTBOX:	.byte 22, 1, 10, 53

#################################
#	    MAP TABLE		#
#################################
# 0:  STATUE			#
# 1:  TOWER			#
# 2:  BEACH			#
# 3:  TEMPLE			#
#################################
CURRENT_MAP:	.byte 3
GAMEMODE:	.byte 0			# 0 = one player, 1 = two player

#################################################################################
#	Usado para fazer a limpeza inteligente do fundo				#
#	Consiste numa queue composta por (x, y, w, z) que serão utilizados	#
#	para fazer a re-renderização do fundo no próximo frame.			#
#################################################################################
FRAME_CLR:	.word 0, 0, 0, 0, 0, 0, 0, 0

.text
SPLASH:		reset_frame()
		li t0,1
		render_s(splash, zero, zero, 320, 240, t0, zero, zero)
		toggle_frame()
		render_s(splash, zero, zero, 320, 240, zero, zero, zero)

SPLASH_RENDER:	lb s0,GAMEMODE
		li s1,32
		li s2,80
		next_frame(s3)
		
		mul t0,s1,s0
		addi t0,t0,168
		render_s(splash_selection, s2, t0, 160, 28, s3, zero, zero)
		
		xori s0,s0,1
		mul t0,s1,s0
		addi t0,t0,168
		render_s(splash, s2, t0, 160, 28, s3, s2, t0)
		
		toggle_frame()

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

TOGGLE_SPLASH:	la t0,GAMEMODE
		lb t1,0(t0)
		xori t1,t1,1
		sb t1,0(t0)
		j SPLASH_RENDER

START_GAME:	#li a7,34
		#la a0,P1_STATE
		#lw a0,0(a0)
		#ecall

NEXT_ROUND:	reset_frame()	# Set frame to 0

		# Set players state to (15 (bowing), 0, 0, 0)
		li t0,0x0000000f
		la t1,P1_STATE
		sw t0,0(t1)
		la t1,P2_STATE
		sw t0,0(t1)
		
		# Reset players position
		la t0,P1_POS
		li t1,0x00a80020	# 32,	168
		sw t1,0(t0)
		la t0,P2_POS
		li t1,0x00a800f0	# 240,	168
		sw t1,0(t0)
		
		# Reset hitbox
		la t0,P1_HITBOX
		sw zero,0(t0)
		sw zero,4(t0)
		
		# Cycle background
		la t0,CURRENT_MAP
		lb t1,0(t0)
		li t2,3
		blt t1,t2,INCREMENT_MAP
		li t1,-1
INCREMENT_MAP:	addi t1,t1,1
		sb t1,0(t0)
		
		# Draw background on both frames
		background_offset(s0, t0)
		li t0,1
		render_s(backgrounds, zero, zero, 320, 240, t0, zero, s0)
		toggle_frame()
		render_s(backgrounds, zero, zero, 320, 240, zero, zero, s0)

GAME_LOOP:	call RECEIVE_INPUT
		# call MUSIC
		
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
		la s6,P1_STATE
		
		lb a0,0(s6)
		jal s9,ATTACK
		
		#########################
		#	PLAYER 2	#
		#########################
		load_pos(P2_POS, s1, s2)
		la s3,P2_POS
		li s4,1
		li s5,-1
		la s6,P2_STATE
		
		lb a0,0(s6)
		jal s9,ATTACK
		
		jal s9,HIT_CHECK
		
		toggle_frame()
		j GAME_LOOP

#########################
#	HIT CHECK	#
#########################
HIT_CHECK:	la s2,P1_HITBOX
		la s3,P2_HURTBOX
		la s4,P2_STATE
		lbu t0,2(s2)
		beqz t0,HC_P2
		
		load_pos(P1_POS, s0, t0)
		load_pos(P2_POS, s1, t0)
		collide_boxes(s0, s1, s2, s3, 0, 2, s8)		# x
		
		load_pos(P1_POS, t0, s0)
		load_pos(P2_POS, t0, s1)
		collide_boxes(s0, s1, s2, s3, 1, 3, t0)		# y

		and s8,s8,t0
		
		bnez s8,HC_DEATH

HC_P2:		la s2,P2_HITBOX
		la s3,P1_HURTBOX
		la s4,P1_STATE
		lbu t0,2(s2)
		beqz t0,HC_END
		
		load_pos(P2_POS, s0, t0)
		load_pos(P1_POS, s1, t0)
		collide_boxes(s0, s1, s2, s3, 0, 2, s8)		# x
		
		load_pos(P2_POS, t0, s0)
		load_pos(P1_POS, t0, s1)
		collide_boxes(s0, s1, s2, s3, 1, 3, t0)		# y
		
		and s8,s8,t0
		bnez s8,HC_DEATH
		
		j HC_END

HC_DEATH:	li t0,16
		sb t0,0(s4)

HC_END:		jr s9

#########################
#	ATTACK CHECK	#
#########################
ATTACK:		beqz a0,A_STATIC_CHAR

		li t1,56
		mul s4,s4,t1

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
		
		li t1,15
		beq a0,t1,A_BOW
		
		li t1,16
		beq a0,t1,A_DEATH
						
		jr s9

#########################################################################################
#	Nós tivemos que usar essa solução por que o alcance da instrução 'beq'		#
#	é menor que da instrução 'jump' e isso estava limitando o desenvolvimento.	#
#########################################################################################
A_STATIC_CHAR:	j STATIC_CHAR
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
A_BOW:		j BOW
A_DEATH:	j DEATH

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
		beq t0,t1,MID_KICK_4
		li t1,6
		beq t0,t1,MID_KICK_5
		j ATTACK_END

MID_KICK_0:	render(kick, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
MID_KICK_1:	load_value_r(8, t0, s5, t1)
		increment_pos_x(s3, t0, 0, s5, 56, t1, t2, t3)
		load_pos_r(s3, s1, s2)
		render(mid_kick_1, s1, s2, 56, 56, s0, zero, s4)
		j ATTACK_ANIM_E
MID_KICK_2:	load_value_r(20, t0, s5, t1)
		increment_pos_x(s3, t0, 0, s5, 76, t1, t2, t3)
		load_pos_r(s3, s1, s2)
		render(mid_kick_2, s1, s2, 76, 56, s0, zero, s4)
		j ATTACK_ANIM_E
MID_KICK_3:	render(mid_kick_2, s1, s2, 76, 56, s0, zero, s4)
		j ATTACK_ANIM_E
MID_KICK_4:	load_value_r(-20, t0, s5, t1)
		increment_pos_x(s3, t0, 0, s5, 56, t1, t2, t3)
		load_pos_r(s3, s1, s2)
		render(mid_kick_1, s1, s2, 56, 56, s0, zero, s4)
		j ATTACK_ANIM_E
MID_KICK_5:	load_value_r(-8, t0, s5, t1)
		increment_pos_x(s3, t0, 0, s5, 48, t1, t2, t3)
		load_pos_r(s3, s1, s2)
		render(kick, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E

#########################################
#	SHORT JAB KICK MOVEMENT		#
#########################################
SJ_KICK:	lbu t0,1(s6)
		
		beqz t0,SJ_KICK_0
		li t1,1
		beq t0,t1,SJ_KICK_1
		li t1,3
		ble t0,t1,SJ_KICK_2
		li t1,4
		beq t0,t1,SJ_KICK_3
		j ATTACK_END
		
SJ_KICK_0:	render(kick, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
SJ_KICK_1:	load_value_r(8, t0, s5, t1)
		increment_pos_x(s3, t0, 0, s5, 56, t1, t2, t3)
		load_pos_r(s3, s1, s2)
		render(sj_kick, s1, s2, 56, 56, s0, zero, s4)
		j ATTACK_ANIM_E
SJ_KICK_2:	render(sj_kick, s1, s2, 56, 56, s0, zero, s4)
		j ATTACK_ANIM_E
SJ_KICK_3:	load_value_r(-8, t0, s5, t1)
		increment_pos_x(s3, t0, 0, s5, 48, t1, t2, t3)
		render(kick, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E

#########################################
#	FORWARD SWEEP MOVEMENT		#
#########################################
FWD_SWEEP:	lbu t0,1(s6)
		
		beqz t0,FWD_SWEEP_0
		li t1,1
		beq t0,t1,FWD_SWEEP_1
		li t1,2
		beq t0,t1,FWD_SWEEP_2
		li t1,5
		blt t0,t1,FWD_SWEEP_3
		beq t0,t1,FWD_SWEEP_4
		li t1,6
		beq t0,t1,FWD_SWEEP_1
		li t1,7
		beq t0,t1,FWD_SWEEP_0
		j ATTACK_END
		
FWD_SWEEP_0:	render(crouch_block, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FWD_SWEEP_1:	render(fwd_sweep_1, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FWD_SWEEP_2:	load_value_r(28, t0, s5, t1)
		increment_pos_x(s3, t0, 0, s5, 76, t1, t2, t3)
		load_pos_r(s3, s1, s2)
		render(fwd_sweep_2, s1, s2, 76, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FWD_SWEEP_3:	render(fwd_sweep_2, s1, s2, 76, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FWD_SWEEP_4:	render(fwd_sweep_2, s1, s2, 76, 56, s0, zero, s4)
		load_value_r(-28, t0, s5, t1)
		increment_pos_x(s3, t0, 0, s5, 48, t1, t2, t3)
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
BWD_SWEEP_2:	load_value(-28, t0, s5, t1)
		increment_pos_x(s3, t0, 0, s5, 76, t1, t2, t3)
		load_pos_r(s3, s1, s2)
		render(bwd_sweep_2, s1, s2, 76, 56, s0, zero, s4)
		j ATTACK_ANIM_E
BWD_SWEEP_3:	render(bwd_sweep_2, s1, s2, 76, 56, s0, zero, s4)
		j ATTACK_ANIM_E
BWD_SWEEP_4:	render(bwd_sweep_2, s1, s2, 76, 56, s0, zero, s4)
		load_value(28, t0, s5, t1)
		increment_pos_x(s3, t0, 0, s5, 48, t1, t2, t3)
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
		li t1,5
		beq t0,t1,ROUNDHOUSE_4
		li t1,9
		blt t0,t1,ROUNDHOUSE_5
		beq t0,t1,ROUNDHOUSE_6
		li t1,10
		beq t0,t1,ROUNDHOUSE_7
		j ATTACK_END
		
ROUNDHOUSE_0:	render(roundhouse_1, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
ROUNDHOUSE_1:	render(roundhouse_2, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
ROUNDHOUSE_2:	load_value_r(12, t0, s5, t1)
		increment_pos_x(s3, t0, 0, s5, 60, t1, t2, t3)
		load_pos_r(s3, s1, s2)
		render(roundhouse_3, s1, s2, 60, 56, s0, zero, s4)
		j ATTACK_ANIM_E
ROUNDHOUSE_3:	load_value_r(-12, t0, s5, t1)
		increment_pos_x(s3, t0, 0, s5, 48, t1, t2, t3)
		load_pos_r(s3, s1, s2)
		render(roundhouse_4, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
ROUNDHOUSE_4:	load_value_r(24, t0, s5, t1)
		increment_pos_x(s3, t0, 0, s5, 72, t1, t2, t3)
		load_pos_r(s3, s1, s2)
		render(roundhouse_5, s1, s2, 72, 56, s0, zero, s4)
		j ATTACK_ANIM_E
ROUNDHOUSE_5:	render(roundhouse_5, s1, s2, 72, 56, s0, zero, s4)
		j ATTACK_ANIM_E
ROUNDHOUSE_6:	load_value_r(-16, t0, s5, t1)
		increment_pos_x(s3, t0, 0, s5, 56, t1, t2, t3)
		load_pos_r(s3, s1, s2)
		render(mid_kick_1, s1, s2, 56, 56, s0, zero, s4)
		j ATTACK_ANIM_E
ROUNDHOUSE_7:	load_value_r(-8, t0, s5, t1)
		increment_pos_x(s3, t0, 0, s5, 48, t1, t2, t3)
		load_pos_r(s3, s1, s2)
		render(kick, s1, s2, 48, 56, s0, zero, s4)
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
HIGH_BK_KICK_1:	li t0,-16
		increment_pos_x(s3, t0, 0, s5, 72, t1, t2, t3)
		load_pos_r(s3, s1, s2)
		render(high_bk_kick_2, s1, s2, 56, 56, s0, zero, s4)
		j ATTACK_ANIM_E
HIGH_BK_KICK_2:	render(high_bk_kick_3, s1, s2, 72, 56, s0, zero, s4)
		j ATTACK_ANIM_E
HIGH_BK_KICK_3:	render(high_bk_kick_2, s1, s2, 56, 56, s0, zero, s4)
		li t0,16
		increment_pos_x(s3, t0, 0, s5, 48, t1, t2, t3)
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
FLYING_KICK_2:	li t1,-8
		h_increment_ar(s3, t1, 2, t0)		# y -= 8
		load_pos_r(s3, s1, s2)
		render(jump, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FLYING_KICK_3:	li t0,8
		increment_pos_x(s3, t0, 0, s5, 64, t1, t2, t3)	# x += 8
		li t1,-16
		h_increment_ar(s3, t1, 2, t0)		# y -= 16	
		load_pos_r(s3, s1, s2)
		render(flying_kick_1, s1, s2, 64, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FLYING_KICK_4:	render(flying_kick_1, s1, s2, 64, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FLYING_KICK_5:	li t1,8
		h_increment_ar(s3, t1, 2, t0)		# y += 8	
		load_pos_r(s3, s1, s2)
		render(flying_kick_1, s1, s2, 64, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FLYING_KICK_6:	li t1,16
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
		li t1,2
		beq t0,t1,HIGH_KICK_2
		li t1,5
		blt t0,t1,HIGH_KICK_3
		beq t0,t1,HIGH_KICK_4
		li t1,6
		beq t0,t1,HIGH_KICK_5
		
		j ATTACK_END
		
HIGH_KICK_0:	render(kick, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
HIGH_KICK_1:	load_value_r(8, t0, s5, t1)
		increment_pos_x(s3, t0, 0, s5, 56, t1, t2, t3)
		load_pos_r(s3, s1, s2)
		render(high_kick_1, s1, s2, 56, 56, s0, zero, s4)
		j ATTACK_ANIM_E
HIGH_KICK_2:	load_value_r(12, t0, s5, t1)
		increment_pos_x(s3, t0, 0, s5, 68, t1, t2, t3)
		load_pos_r(s3, s1, s2)
		render(high_kick_2, s1, s2, 68, 56, s0, zero, s4)
		j ATTACK_ANIM_E
HIGH_KICK_3:	render(high_kick_2, s1, s2, 68, 56, s0, zero, s4)
		j ATTACK_ANIM_E
HIGH_KICK_4:	load_value_r(-12, t0, s5, t1)
		increment_pos_x(s3, t0, 0, s5, 56, t1, t2, t3)
		load_pos_r(s3, s1, s2)
		render(high_kick_1, s1, s2, 56, 56, s0, zero, s4)
		j ATTACK_ANIM_E
HIGH_KICK_5:	load_value_r(-8, t0, s5, t1)
		increment_pos_x(s3, t0, 0, s5, 56, t1, t2, t3)
		load_pos_r(s3, s1, s2)
		render(kick, s1, s2, 48, 56, s0, zero, s4)
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
#	BSOMERSAULT MOVEMENT		#
#########################################
BSOMERSAULT:	lbu t0,1(s6)
		
		# 72px
		beqz t0,BSOMERSAULT_0
		li t1,1
		beq t0,t1,BSOMERSAULT_1
		li t1,2
		beq t0,t1,BSOMERSAULT_2
		li t1,3
		beq t0,t1,BSOMERSAULT_3
		li t1,4
		beq t0,t1,BSOMERSAULT_4
		li t1,5
		beq t0,t1,BSOMERSAULT_5
		li t1,6
		beq t0,t1,BSOMERSAULT_6
		li t1,7
		beq t0,t1,BSOMERSAULT_7
		li t1,8
		beq t0,t1,BSOMERSAULT_8
		li t1,9
		beq t0,t1,BSOMERSAULT_9
		j ATTACK_END
		
BSOMERSAULT_0:	render(landing, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
BSOMERSAULT_1:	li t1,-8
		h_increment_ar(s3, t1, 2, t0)		# y -= 8
		load_pos_r(s3, s1, s2)
		render(ss_straight, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
BSOMERSAULT_2:	li t1,-12
		h_increment_ar(s3, t1, 2, t0)		# y -= 8
		li t0,-20
		increment_pos_x(s3, t0, 0, s5, 48, t1, t2, t3)	# x -= 20
		load_pos_r(s3, s1, s2)
		render(ss_straight, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
BSOMERSAULT_3:	render(ss_left, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
BSOMERSAULT_4:	render(ss_upside, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
BSOMERSAULT_5:	li t0,-20
		increment_pos_x(s3, t0, 0, s5, 48, t1, t2, t3)	# x -= 20
		load_pos_r(s3, s1, s2)
		render(ss_right, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
BSOMERSAULT_6:	li t0,-20
		increment_pos_x(s3, t0, 0, s5, 48, t1, t2, t3)	# x -= 20
		load_pos_r(s3, s1, s2)
		render(ss_right, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
BSOMERSAULT_7:	li t1,12
		h_increment_ar(s3, t1, 2, t0)		# y += 8
		li t0,-12
		increment_pos_x(s3, t0, 0, s5, 48, t1, t2, t3)	# x -= 12
		load_pos_r(s3, s1, s2)
		render(ss_landing, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
BSOMERSAULT_8:	li t1,8
		h_increment_ar(s3, t1, 2, t0)		# y += 8
		li t0,-12
		increment_pos_x(s3, t0, 0, s5, 48, t1, t2, t3)	# x -= 12
		load_pos_r(s3, s1, s2)
		render(ss_landing, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
BSOMERSAULT_9:	li t0,-12
		increment_pos_x(s3, t0, 0, s5, 48, t1, t2, t3)	# x -= 12
		load_pos_r(s3, s1, s2)
		render(landing, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E

#########################################
#	BSOMERSAULT MOVEMENT		#
#########################################
FSOMERSAULT:	lbu t0,1(s6)
		
		# 72px
		beqz t0,FSOMERSAULT_0
		li t1,1
		beq t0,t1,FSOMERSAULT_1
		li t1,2
		beq t0,t1,FSOMERSAULT_2
		li t1,3
		beq t0,t1,FSOMERSAULT_3
		li t1,4
		beq t0,t1,FSOMERSAULT_4
		li t1,5
		beq t0,t1,FSOMERSAULT_5
		li t1,6
		beq t0,t1,FSOMERSAULT_6
		li t1,7
		beq t0,t1,FSOMERSAULT_7
		li t1,8
		beq t0,t1,FSOMERSAULT_8
		li t1,9
		beq t0,t1,FSOMERSAULT_9
		j ATTACK_END
		
FSOMERSAULT_0:	render(landing, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FSOMERSAULT_1:	li t1,-8
		h_increment_ar(s3, t1, 2, t0)		# y -= 8
		load_pos_r(s3, s1, s2)
		render(ss_landing, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FSOMERSAULT_2:	li t1,-12
		h_increment_ar(s3, t1, 2, t0)		# y -= 8
		li t0,20
		increment_pos_x(s3, t0, 0, s5, 48, t1, t2, t3)	# x += 20
		load_pos_r(s3, s1, s2)
		render(ss_landing, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FSOMERSAULT_3:	render(ss_right, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FSOMERSAULT_4:	render(ss_right, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FSOMERSAULT_5:	li t0,20
		increment_pos_x(s3, t0, 0, s5, 48, t1, t2, t3)	# x += 20
		load_pos_r(s3, s1, s2)
		render(ss_upside, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FSOMERSAULT_6:	li t0,20
		increment_pos_x(s3, t0, 0, s5, 48, t1, t2, t3)	# x += 20
		load_pos_r(s3, s1, s2)
		render(ss_left, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FSOMERSAULT_7:	li t1,12
		h_increment_ar(s3, t1, 2, t0)		# y += 8
		li t0,12
		increment_pos_x(s3, t0, 0, s5, 48, t1, t2, t3)	# x += 12
		load_pos_r(s3, s1, s2)
		render(ss_straight, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FSOMERSAULT_8:	li t1,8
		h_increment_ar(s3, t1, 2, t0)		# y += 8
		li t0,12
		increment_pos_x(s3, t0, 0, s5, 48, t1, t2, t3)	# x += 12
		load_pos_r(s3, s1, s2)
		render(ss_straight, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
FSOMERSAULT_9:	li t0,12
		increment_pos_x(s3, t0, 0, s5, 48, t1, t2, t3)	# x += 12
		load_pos_r(s3, s1, s2)
		render(landing, s1, s2, 48, 56, s0, zero, s4)
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
JUMP_2:		li t1,-8
		h_increment_ar(s3, t1, 2, t0)		# y -= 8
		load_pos_r(s3, s1, s2)
		render(jump, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
JUMP_3:		render(jump, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
JUMP_4:		li t1,8
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
#	BOW MOVEMENT			#
#########################################
BOW:		lbu t0,1(s6)
		
		li t1,5
		blt t0,t1,BOW_0
		li t1,15
		blt t0,t1,BOW_1
		li t1,20
		blt t0,t1,BOW_0
		
		j ATTACK_END

BOW_0:		render(bow_1, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
BOW_1:		render(bow_2, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E

#########################################
#	DEATH MOVEMENT (?)		#
#########################################
DEATH:		lbu t0,1(s6)
		
		beqz t0,DEATH_0
		li t1,1
		beq t0,t1,DEATH_1
		li t1,2
		beq t0,t1,DEATH_2
		li t1,5
		blt t0,t1,DEATH_3
		
		j NEXT_ROUND

DEATH_0:	render(death_1, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
DEATH_1:	render(death_2, s1, s2, 48, 56, s0, zero, s4)
		j ATTACK_ANIM_E
DEATH_2:	render(death_3, s1, s2, 68, 56, s0, zero, s4)
		j ATTACK_ANIM_E
DEATH_3:	render(death_4, s1, s2, 72, 56, s0, zero, s4)
		j ATTACK_ANIM_E

#########################################
#	GENERIC ATTACK OPERATIONS	#
#########################################
ATTACK_ANIM_E:	li t1,1
		b_increment_ar(s6, t1, 1, t0)
		jr s9

ATTACK_END:	sh zero,0(s6)
		li t0,56
		divu s4,s4,t0
		j STATIC_CHAR

#########################################
#	NON-ATTACKING MOVEMENT		#
#########################################
STATIC_CHAR:	la t0,DEF_HURTBOX
		li t1,4
		mul t1,s4,t1
		add s8,t0,t1
		update_hitbox_i(s8, s4, P1_HURTBOX)
		reset_hitbox(s4, P1_HITBOX)

		li t0,32
		mul t0,s4,t0
		render_s(char_torso, s1, s2, 48, 32, s0, zero, t0)
		addi s2,s2,32
		
		li t0,24
		mul s4,s4,t0

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
		beq t0,t2,WALK_TMODE
		li t2,10
		blt t0,t2,WALK_2_CONT

		sb zero,3(s6)			# else restart animation counter
		j WALK_IDLE			# draw idle sprite

WALK_TMODE:	li t1,1
		b_increment_ar(s6, t1, 3, t0)
		j WALK_IDLE

WALK_2_CONT:	addi t0,t0,-1
WALK_CONT:	li t1,48
		mul t1,t1,t0			# curr sprite * 48 = x in spritesheet
		render_s(walking, s1, s2, 48, 24, s0, t1, s4)
		li t1,1
		b_increment_ar(s6, t1, 3, t0)
		addi s2,s2,-32
		j WALK_CLEAR

WALK_REV:	lbu t0,3(s6)			# current sprite
		beqz t0,WALK_REV_SET
		li t1,1
		beq t0,t1,WALK_REV_TMODE
		li t1,5
		blt t0,t1,WALK_REV_CONT		# if curr sprite > 0 then continue animation
		bgt t0,t1,WALK_2REV_CONT

		li t2,4				# goto last sprite
		sb t2,3(s6)			# else restart animation counter
		j WALK_IDLE			# draw idle sprite

WALK_REV_SET:	li t0,4
		sb t0,3(s6)
		j WALK_REV_CONT

WALK_REV_TMODE:	li t0,11
		sb t0,3(s6)
		j WALK_IDLE

WALK_2REV_CONT:	addi t0,t0,-3
WALK_REV_CONT:	li t1,48
		addi t0,t0,-1
		mul t1,t1,t0			# curr sprite * 48 = x in spritesheet
		render_s(walking, s1, s2, 48, 24, s0, t1, s4)
		li t1,1
		b_decrement_ar(s6, t1, 3, t0)
		addi s2,s2,-32
		j WALK_CLEAR

WALK_IDLE:	render_s(char_legs_idle, s1, s2, 48, 24, s0, zero, s4)
		addi s2,s2,-32

WALK_CLEAR:	update_clear(s1, s2, 48, 56)
		jr s9

#########################
#	USER INPUT	#
#########################
RECEIVE_INPUT:	li t1,0xFF200000
		lw t0,0(t1)
		andi t0,t0,0x0001
  	 	beq t0,zero,REC_INPUT_CLN
  		lw t0,4(t1)
  		
  		# Cheats
  		check_key('v', RI_NEXT_ROUND, t0, t1)

		# P1 normal movements
		la s0,P1_STATE
  		check_key('d', RI_MV_RIGHT, t0, t1)
  		check_key('c', RI_JAB, t0, t1)
  		check_key('x', RI_CROUCH_BLK, t0, t1)
  		check_key('z', RI_BSOMERSAULT, t0, t1)
  		check_key('a', RI_MV_LEFT, t0, t1)
  		check_key('q', RI_FSOMERSAULT, t0, t1)
  		check_key('w', RI_JUMP, t0, t1)
  		check_key('e', RI_HIGH_PUNCH, t0, t1)
 
 		# P1 fire movements
  		check_key('D', RI_MID_KICK, t0, t1)
  		check_key('C', RI_SJ_KICK, t0, t1)
  		check_key('X', RI_FWD_SWEEP, t0, t1)
  		check_key('Z', RI_BWD_SWEEP, t0, t1)
  		check_key('A', RI_ROUNDHOUSE, t0, t1)
  		check_key('Q', RI_HIGH_B_KICK, t0, t1)
  		check_key('W', RI_FLYING_KICK, t0, t1)
  		check_key('E', RI_HIGH_KICK, t0, t1)
  		
  		lb t1,GAMEMODE
  		beqz t1,REC_INPUT_CLN
  		
  		# P2 normal movements
  		la s0,P2_STATE
  		check_key('k', RI_MV_RIGHT, t0, t1)
  		check_key('b', RI_JAB, t0, t1)
  		check_key('n', RI_CROUCH_BLK, t0, t1)
  		check_key('m', RI_BSOMERSAULT, t0, t1)
  		check_key('h', RI_MV_LEFT, t0, t1)
  		check_key('i', RI_FSOMERSAULT, t0, t1)
  		check_key('u', RI_JUMP, t0, t1)
  		check_key('y', RI_HIGH_PUNCH, t0, t1)
 
 		# P1 fire movements (NEEDS REWORK)
  		check_key('H', RI_MID_KICK, t0, t1)
  		check_key('B', RI_SJ_KICK, t0, t1)
  		check_key('N', RI_FWD_SWEEP, t0, t1)
  		check_key('M', RI_BWD_SWEEP, t0, t1)
  		check_key('K', RI_ROUNDHOUSE, t0, t1)
  		check_key('I', RI_HIGH_B_KICK, t0, t1)
  		check_key('U', RI_FLYING_KICK, t0, t1)
  		check_key('Y', RI_HIGH_KICK, t0, t1)
  		
REC_INPUT_CLN:	la t0,P1_STATE
		sh zero,2(t0)
		
		lb t0,GAMEMODE
		beqz t0,REC_INPUT_END
		
		la t0,P2_STATE
		sh zero,2(t0)

  		j REC_INPUT_END

# Move right 		(press d)
RI_MV_RIGHT:	lb t0,0(s0)
		bnez t0,REC_INPUT_CLN

		li t0,1
		sb t0,2(s0)
		li t0,4
		li t1,1
		increment_pos_x(s0, t0, 4, t1, 48, t2, t3, t4)
		
		j REC_INPUT_END

# Move left 		(press a)
RI_MV_LEFT:	lb t0,0(s0)
		bnez t0,REC_INPUT_CLN

		li t0,0xff
		sb t0,2(s0)
		li t0,-4
		li t1,1
		increment_pos_x(s0, t0, 4, t1, 48, t2, t3, t4)
		
		j REC_INPUT_END

# Mid kick		(press D, shift + d)
RI_MID_KICK:	register_attack(s0, 1, REC_INPUT_CLN)
# Short jab kick	(press C, shift + c)
RI_SJ_KICK:	register_attack(s0, 2, REC_INPUT_CLN)
# Forward sweep		(press X, shift + x)
RI_FWD_SWEEP:	register_attack(s0, 3, REC_INPUT_CLN)
# Backwards sweep	(press Z, shift + z)
RI_BWD_SWEEP:	register_attack(s0, 4, REC_INPUT_CLN)
# Roundhouse		(press A, shift + a)
RI_ROUNDHOUSE:	register_attack(s0, 5, REC_INPUT_CLN)
# High back kick	(press Q, shift + q)
RI_HIGH_B_KICK:	register_attack(s0, 6, REC_INPUT_CLN)
# Fling kick		(press W, shift + w)
RI_FLYING_KICK:	register_attack(s0, 7, REC_INPUT_CLN)
# High kick		(press E, shift + e)
RI_HIGH_KICK:	register_attack(s0, 8, REC_INPUT_CLN)

# Jab			(press c)
RI_JAB:		register_attack(s0, 9, REC_INPUT_CLN)
# Crouch block		(press x)
RI_CROUCH_BLK:	register_attack(s0, 10, REC_INPUT_CLN)
# Back somersault	(press z)
RI_BSOMERSAULT:	register_attack(s0, 11, REC_INPUT_CLN)
# Forward somersault	(press q)
RI_FSOMERSAULT:	register_attack(s0, 12, REC_INPUT_CLN)
# Jump			(press w)
RI_JUMP:	register_attack(s0, 13, REC_INPUT_CLN)
# High punch		(press e)
RI_HIGH_PUNCH:	register_attack(s0, 14, REC_INPUT_CLN)

RI_NEXT_ROUND:	j NEXT_ROUND

REC_INPUT_END:	ret	# retorna

EXIT:		li a7,10
		ecall

.data
.include "sprites/misc/splash.data"
.include "sprites/misc/splash_selection.data"
.include "sprites/misc/backgrounds.data"

.include "sprites/static_char/char_torso.data"
.include "sprites/static_char/char_legs_idle.data"
.include "sprites/static_char/walking.data"

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

.include "sprites/somersault/ss_landing.data"
.include "sprites/somersault/ss_straight.data"
.include "sprites/somersault/ss_upside.data"
.include "sprites/somersault/ss_right.data"
.include "sprites/somersault/ss_left.data"

.include "sprites/bow/bow_1.data"
.include "sprites/bow/bow_2.data"

.include "sprites/death/death_1.data"
.include "sprites/death/death_2.data"
.include "sprites/death/death_3.data"
.include "sprites/death/death_4.data"

.text
.include "render.s"
.include "music.s"
