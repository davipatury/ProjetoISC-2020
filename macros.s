#########################################################
#	Multiplicar conte�dodo do registrador %r	#
#	com o imediato %imm, armazenando		#
#	o resultado em %r.				#
#########################################################
.macro apply_multiplier(%imm, %r, %mul)
li %r,%imm
mul %r,%r,%mul
.end_macro

.macro random_int(%bound)
li a7,42
li a0,0
li a1,%bound
ecall
.end_macro

.macro random_int_r(%bound)
li a7,42
li a0,0
li a1,%bound
ecall
.end_macro

.macro play_sound(%a0, %a1, %a2, %a3)
li a0,%a0
li a1,%a1
li a2,%a2
li a3,%a3
li a7,31
ecall
.end_macro

#########################################################
#	DEBUG: Imprime um inteiro armazenado em %r.	#
#########################################################
.macro print_int(%r)
mv a0,%r
li a7,1
ecall
li a0,' '
li a7,11
ecall
.end_macro

#########################################################
#	DEBUG: Imprime uma nova linha.			#
#########################################################
.macro print_nl()
li a0,10
li a7,11
ecall
.end_macro

#
.macro distance_between(%label1, %label2, %r)
lhu t0,%label1
lhu t1,%label2
sub %r,t1,t0
.end_macro

#########################################################
#	"Empurra" 2 words no offset %off para "baixo"	#
#########################################################
.macro push_clear(%off)
la t0,FRAME_CLR
addi t0,t0,%off
lw t1,0(t0)
lw t2,4(t0)
sw t1,8(t0)
sw t2,12(t0)
.end_macro

#########################################################
#	Adiciona um novo conjunto (%x, %y, %w, %h) ao	#
#	queue de limpeza de fundo.			#
#########################################################
.macro update_clear(%x, %y, %w, %h)
push_clear(16)
push_clear(8)
push_clear(0)
la t0,FRAME_CLR
sh %x,0(t0)
sh %y,2(t0)
li t1,%w
sh t1,4(t0)
li t1,%h
sh t1,6(t0)
.end_macro

#
.macro update_hitbox(%adr, %y0, %inc, %label)
lw t0,0(%adr)
lw t1,4(%adr)

mul t0,t0,t1

add t0,t0,%adr
addi t2,t0,%inc

li t0,14
divu t0,%y0,t0
la t1,%label
add t1,t1,t0

li t3,2
mul t0,t0,t3
add t2,t2,t0

lw t0,0(t2)
sw t0,0(t1)
.end_macro

#
.macro update_hitbox_i(%adr, %y0, %label)
li t1,4
mul t0,t1,%y0
la t1,%label
add t1,t1,t0

lw t0,0(%adr)
sw t0,0(t1)
.end_macro

#
.macro reset_hitbox(%y0, %label)
li t1,4
mul t0,t1,%y0
la t1,%label
add t1,t1,t0

sw zero,0(t1)
.end_macro

#
.macro collide_boxes(%p1, %p2, %adr1, %adr2, %imm1, %imm2, %r)
lbu t0,%imm1(%adr1)
add t0,t0,%p1
lbu t1,%imm2(%adr1)
add t1,t1,t0

lbu t2,%imm1(%adr2)
add t2,t2,%p2
lbu t3,%imm2(%adr2)
add t3,t3,t2

slt t4,t2,t1
slt t5,t2,t3

and t4,t4,t5

slt t5,t2,t0
or t4,t4,t5
slt t5,t0,t3
and t4,t4,t5

mv %r,t4
.end_macro

#########################################################
#			RENDERING			#
#		  Veja mais em render.s			#
#########################################################
.macro render(%adr, %x, %y, %w, %h, %f, %x0, %y0)
la a0,%adr	# endere�o da imagem
mv a1,%x	# x
mv a2,%y	# y
li a3,%w	# width
li a4,%h	# height
mv a5,%f	# frame (0 ou 1)
mv a6,%x0	# x0
mv a7,%y0	# y0
update_clear(%x, %y, %w, %h)
update_hitbox(a0, %y0, 8, P1_HURTBOX)
update_hitbox(a0, %y0, 12, P1_HITBOX)
jal RENDER
.end_macro

.macro render_s(%adr, %x, %y, %w, %h, %f, %x0, %y0)
la a0,%adr	# endereco da imagem
mv a1,%x	# x
mv a2,%y	# y
li a3,%w	# width
li a4,%h	# height
mv a5,%f	# frame (0 ou 1)
mv a6,%x0	# x0
mv a7,%y0	# y0
jal RENDER
.end_macro

.macro render_r(%adr, %x, %y, %w, %h, %f, %x0, %y0)
la a0,%adr	# endereco da imagem
mv a1,%x	# x
mv a2,%y	# y
mv a3,%w	# width
mv a4,%h	# height
mv a5,%f	# frame (0 ou 1)
mv a6,%x0	# x0
mv a7,%y0	# y0
jal RENDER
.end_macro

#########################################################
#	Armazena em %r o frame atual (que estao sendo	#
#	apresentado na tela).				#
#########################################################
.macro current_frame(%r)
li %r,0xFF200604
lw %r,0(%r)
.end_macro

#########################################################
#	Armazena em %r o proximo frame (que nao estao	#
#	sendo apresentado na tela)			#
#########################################################
.macro next_frame(%r)
li %r,0xFF200604
lw %r,0(%r)
xori %r,%r,0x001
.end_macro

#########################################################
#	Alterna o frame que deve ser apresentado	#
#########################################################
.macro toggle_frame()
li t0,0xFF200604
lw t1,0(t0)
xori t1,t1,0x001
sw t1,0(t0)

li a0,FPG_RARS
li a7,32
ecall	
.end_macro

#########################################################
#	Retorna o frame pra sua posicao original (0)	#
#########################################################
.macro reset_frame()
li t0,0xFF200604
sw zero,0(t0)
.end_macro

#########################################################
#	Armazena o offset vertical do sprite do		#
#	background em %r, usando %r1 como suporte	#
#########################################################
.macro background_offset(%r, %r1)
lb %r,CURRENT_MAP
li %r1,240
mul %r,%r,%r1
.end_macro

#########################################################
#	Incrementa o valor do registrador $r1 * %mul	#
#	a posicao do endereco %pos + %imm utilizando	#
#	%r2 a %r4 como suporte, sendo %mw a largura	#
#	maxima que o sprite pode alcancar.		#
#########################################################
.macro increment_pos_x(%pos, %r1, %imm, %mul, %mw, %r2, %r3, %r4)
lhu %r2,%imm(%pos)
mul %r3,%r1,%mul
add %r2,%r2,%r3

li %r3,320
addi %r3,%r3,-%mw
	
slt %r1,%r2,zero
mul %r4,%r2,%r1
sub %r2,%r2,%r4
	
slt %r1,%r3,%r2
sub %r4,%r2,%r3
mul %r4,%r4,%r1
sub %r2,%r2,%r4

sh %r2,%imm(%pos)
.end_macro

.macro load_value(%value, %r0, %mul, %r1)
slt %r1,%mul,zero
xori %r1,%r1,1
li %r0,%value
mul %r0,%r0,%r1
.end_macro

.macro load_value_r(%value, %r0, %mul, %r1)
slt %r1,%mul,zero
li %r0,%value
mul %r0,%r0,%r1
.end_macro

#########################################################
#	Armazena a posicao armazenada em %label		#
#	nos registradores %x e %y.			#
#########################################################
.macro load_pos(%label, %x, %y)
la %y,%label
lh %x,0(%y)
lh %y,2(%y)
.end_macro

#########################################################
#	Armazena a posicao armazenada no endereco	#
#	%r nos registradores %x e %y.			#
#########################################################
.macro load_pos_r(%r, %x, %y)
lh %x,0(%r)
lh %y,2(%r)
.end_macro

#########################################################
#	Pula para %label se %r for igual a %n, usando	#
#	%r1 como registrador auxiliar.			#
#########################################################
.macro check_key(%n, %label, %r, %r1)
li %r1,%n
beq %r,%r1,%label
.end_macro

#########################################################
#	Registra um ataque %n do Player %address	#
#	e pula para %label.				#
#							#
#	Para mais informa��es veja ATTACK TABLE		#
#	em game.s					#
#########################################################
.macro register_attack_nc(%address, %n)
li t1,%n
sh t1,0(%address)
.end_macro

.macro register_attack(%address, %n, %label)
lb t1,0(%address)
bnez t1,%label
li t1,%n
sb t1,0(%address)
j %label
.end_macro

#########################################################
#	Incrementa %value ao BYTE no endereco		#
#	%r1 + %imm usando $r como auxiliar.		#
#########################################################
.macro b_increment_ar(%r1, %value, %imm, %r)
lb %r,%imm(%r1)
add %r,%r,%value
sb %r,%imm(%r1)
.end_macro

#########################################################
#	Decrementa %value do BYTE no endereco		#
#	%r1 + %imm usando $r como auxiliar.		#
#########################################################
.macro b_decrement_ar(%r1, %value, %imm, %r)
li %r,-1
mul %value,%value,%r
lb %r,%imm(%r1)
add %r,%r,%value
sb %r,%imm(%r1)
.end_macro

#########################################################
#	Incrementa %value a HALFWORD no endereco	#
#	%r1 + %imm usando $r como auxiliar.		#
#########################################################
.macro h_increment_ar(%r1, %value, %imm, %r)
lh %r,%imm(%r1)
add %r,%r,%value
sh %r,%imm(%r1)
.end_macro

#########################################################
#		  Retorna o tempo atual			#
#		      e salva em %r			#
#########################################################
.macro tempo(%r)
li a7, 30
ecall
mv %r, a0
.end_macro

#########################################################
#	     Printa o inteiro correspondente		#
#            aos segundos restantes do round		#
#########################################################
.macro print_int_screen(%r, %x, %y, %cor, %f)
mv a0, %r		# Int a ser impresso
li a1, %x		# Coluna
li a2, %y		# Linha
li a3, %cor		# Cor
mv a4, %f		# Frame a ser impresso
li a7, 101		# PrintInt
ecall
.end_macro

.macro print_clock()
# Printa o retangulo embaixo
li t0, 152		# x
li t1, 5		# y
render_s(clock_retangule, t0, t1, 20, 8, s0, zero, zero)
	
# Printa o numero
print_int_screen(t5, 155, 5, 0xFF, s0)
.end_macro

#########################################################
#		     Printa o placar			#
#########################################################

.macro print_score()
# Print P1_SCORE
la t0, P1_SCORE
lb t5, 0(t0)			# t5 = P1 SCORE
beqz t5, PRINT_P2_SCORE		# 0 pontos
# 1� ying-yang
li t1, 52			# x
li t2, 4			# y
render_s(ying_yang, t1, t2, 20, 20, s0, zero, zero)
	
li t1, 2
blt t5, t1, PRINT_P2_SCORE	# if P1_SCORE < 2 than PC = PRINT_P2_SCORE
li t1, 76			# x
li t2, 4			# y
render_s(ying_yang, t1, t2, 20, 20, s0, zero, zero) # else (P1_SCORE == 2) than print 2� ying-yang
	
PRINT_P2_SCORE:
# Print P2_SCORE
la t0, P2_SCORE
lb t5, 0(t0)
beqz t5, PS_LOOP_OUT
# 1� ying-yang
li t1, 248		# x
li t2, 4		# y
render_s(ying_yang, t1, t2, 20, 20, s0, zero, zero)
	
li t1, 2
bne t5, t1,PS_LOOP_OUT	 	# if P1_SCORE != 2 than PC = PRINT_LOOP_OUT
li t1, 224			# x
li t2, 4			# y
render_s(ying_yang, t1, t2, 20, 20, s0, zero, zero) # else (P1_SCORE == 2) than print 2� ying-yang

PS_LOOP_OUT:
.end_macro

# MUSIC MACROS
.macro play_music(%b, %t)
li s1,%b
mv s2,%t
call MUSIC
.end_macro

.macro reset_music()
la t0,MUSIC_STATUS
sw zero,0(t0)
sw zero,4(t0)
sw zero,8(t0)
sw zero,16(t0)
sw zero,20(t0)
sw zero,24(t0)
.end_macro
