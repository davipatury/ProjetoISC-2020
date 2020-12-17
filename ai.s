#########################################################
#	"Inteligencia artificical" do inimigo		#
#########################################################
.text
E_AI:		lb t0,GAMEMODE
		bnez t0,E_AI_END		# checa se o modo de jogo é só de 1 jogador
		
		la s0,P2_STATE
		lbu t0,0(s0)
		bnez t0,E_AI_C_BLOCK		# checa se já existe um movimento sendo feito
		
		lbu t0,P1_STATE
		li t1,16
		beq t0,t1,E_AI_TEABAG		# se o jogador morreu, começa a fazer teabag no corpo dele		
		
		distance_between(P1_POS, P2_POS, s1)
		
		li t0,86
		bgt s1,t0,E_AI_CONT
		
		random_int_r(100)
		lbu t0,DIFFICULTY
		li t1,5
		mul t0,t0,t1
		bgt a0,t0,E_AI_CONT
		
		lbu t0,P1_STATE
		beqz t0,E_AI_CONT
		li t1,1
		beq t0,t1,E_AI_H_BLOCK
		li t1,3
		ble t0,t1,E_AI_L_BLOCK
		li t1,9
		ble t0,t1,E_AI_H_BLOCK
		li t1,14
		beq t0,t1,E_AI_H_BLOCK		# se o jogador estiver fazendo um ataque, bloqueie

E_AI_CONT:	random_int_r(100)
		lbu t0,DIFFICULTY
		li t1,40
		mul t0,t0,t1
		bgt a0,t0,E_AI_END
		
		li t0,27
		bgt s1,t0,E_AI_WALK_TWDS	# se a distância for maior, anda em direção ao jogador
		
		li t0,-56
		blt s1,t0,E_AI_WALK_BACK
		
		random_int_r(100)
		lbu t0,DIFFICULTY
		li t1,15
		mul t0,t0,t1
		bgt a0,t0,E_AI_END
		
		bltz s1,E_AI_BACK_ATK

# Ataque frontal
E_AI_FRONT_ATK:	lbu t0,P1_STATE
		
		li t1,1
		li t2,3
		beq t0,t1,E_AI_ATK
		
		li t1,2
		li t2,7
		beq t0,t1,E_AI_ATK
		
		li t1,3
		li t2,7
		beq t0,t1,E_AI_ATK
		
		li t1,5
		li t2,3
		beq t0,t1,E_AI_ATK
		
		li t1,7
		li t2,3
		beq t0,t1,E_AI_ATK
		
		li t1,8
		li t2,3
		beq t0,t1,E_AI_ATK
		
		li t1,9
		li t2,1
		beq t0,t1,E_AI_ATK
		
		li t1,10
		li t2,12
		beq t0,t1,E_AI_ATK
		
		li t1,13
		li t2,8
		beq t0,t1,E_AI_ATK
		
		li t1,14
		li t2,1
		beq t0,t1,E_AI_ATK
		
		li t1,17
		li t2,3
		beq t0,t1,E_AI_ATK
		
		li t1,14			# high punch
		sb t1,0(s0)
		j E_AI_RST_WALK

# Ataque de costas
E_AI_BACK_ATK:	lbu t0,P1_STATE

		li t1,10
		li t2,4
		beq t0,t1,E_AI_ATK
		
		li t1,6				# high back kick
		sb t1,0(s0)
		j E_AI_RST_WALK

E_AI_ATK:	sb t2,0(s0)
		j E_AI_RST_WALK

# Walk back
E_AI_WALK_BACK:	li t0,1
		sb t0,2(s0)
		li t0,4
		li t1,1
		increment_pos_x(s0, t0, 4, t1, 48, t2, t3, t4)
		
		j E_AI_END

# Walk towards player
E_AI_WALK_TWDS:	li t0,0xff
		sb t0,2(s0)
		li t0,-4
		li t1,1
		increment_pos_x(s0, t0, 4, t1, 48, t2, t3, t4)
		
		j E_AI_END

# High block
E_AI_H_BLOCK:	li t1,17			# block
		sb t1,0(s0)
		j E_AI_RST_WALK

# Low block
E_AI_L_BLOCK:	li t1,10			# crouch
		sb t1,0(s0)
		j E_AI_RST_WALK

# Block check
E_AI_C_BLOCK:	li t1,17
		beq t0,t1,E_AI_R_BLOCK
		li t1,10
		beq t0,t1,E_AI_R_BLOCK
		j E_AI_END

# Refresh block
E_AI_R_BLOCK:	distance_between(P1_POS, P2_POS, s1)
		li t0,86
		bgt s1,t0,E_AI_END
		
		lbu t0,P1_STATE
		beqz t0,E_AI_END
		
		li t1,1
		beq t0,t1,E_AI_RR_BLOCK
		li t1,3
		ble t0,t1,E_AI_RR_BLOCK
		li t1,9
		ble t0,t1,E_AI_RR_BLOCK
		li t1,14
		beq t0,t1,E_AI_RR_BLOCK
		
		j E_AI_END

E_AI_RR_BLOCK:	lb t0,0(s0)
		sh t0,0(s0)
		j E_AI_RST_WALK

# Teabag
E_AI_TEABAG:	li t1,10			# crouch
		sb t1,0(s0)

# Reset walk animation
E_AI_RST_WALK:	la t0,P2_STATE			# zera o estado do walk
		sh zero,2(t0)

E_AI_END:	ret
