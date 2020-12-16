#########################################################
#	"Inteligencia artificical" do inimigo		#
#########################################################
.text
E_AI:		lb t0,GAMEMODE
		bnez t0,E_AI_END		# checa se o modo de jogo é só de 1 jogador
		
		la s0,P2_STATE
		lbu t0,0(s0)
		bnez t0,E_AI_END		# checa se já existe um movimento sendo feito
		
		lbu t0,P1_STATE
		li t1,16
		beq t0,t1,E_AI_TEABAG		# se o jogador morreu, começa a fazer teabag no corpo dele
		
		distance_between(P1_POS, P2_POS, s1)

# Enemy AI step 1
E_AI_ST_1:	li t0,27
		bgt s1,t0,E_AI_WALK_TWDS	# se a distância for maior que 27, anda em direção ao jogador
		
		li t1,14			# high punch
		sb t1,0(s0)
		
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

E_AI_TEABAG:	li t1,10			# crouch
		sb t1,0(s0)
		
E_AI_RST_WALK:	la t0,P2_STATE			# zera o estado do walk
		sh zero,2(t0)

E_AI_END:	ret