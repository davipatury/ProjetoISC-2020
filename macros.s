#########################################################
#	Multiplicar conteúdo do registrador %r		#
#	com o imediato %imm, armazenando		#
#	o resultado em %r.				#
#########################################################
.macro apply_multiplier(%imm, %r, %mul)
li %r,%imm
mul %r,%r,%mul
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

#########################################################
#			RENDERING			#
#		  Veja mais em render.s			#
#########################################################
.macro render(%adr, %x, %y, %w, %h, %f, %x0, %y0)
update_clear(%x, %y, %w, %h)
la a0,%adr	# endereço da imagem
mv a1,%x	# x
mv a2,%y	# y
li a3,%w	# width
li a4,%h	# height
mv a5,%f	# frame (0 ou 1)
mv a6,%x0	# x0
mv a7,%y0	# y0
jal RENDER
.end_macro

.macro render_s(%adr, %x, %y, %w, %h, %f, %x0, %y0)
la a0,%adr	# endereço da imagem
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
la a0,%adr	# endereço da imagem
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
#	Armazena em %r o frame atual (que está sendo	#
#	apresentado na tela).				#
#########################################################
.macro current_frame(%r)
li %r,0xFF200604
lw %r,0(%r)
.end_macro

#########################################################
#	Armazena em %r o próximo frame (que não está	#
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

# Remova os comentários das linhas abaixo caso queira rodar o jogo usando FPGRARS
# (sim, ele é tão rápido que a gente tem que dar uma segurada usando sleep)
#li a0,50
#li a7,32
#ecall	
.end_macro

#########################################################
#	Retorna o frame pra sua posição original (0)	#
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
#	a posição do endereço %pos + %imm utilizando	#
#	%r2 e %r3 como suporte, sendo %mw a largura	#
#	máxima que o sprite pode alcançar.		#
#########################################################
.macro increment_pos_x(%pos, %r1, %imm, %mul, %mw, %r2, %r3)
	lh %r2,%imm(%pos)
	mul %r3,%r1,%mul
	add %r2,%r2,%r3

	li %r3,320
	addi %r3,%r3,-%mw
	
	blez %r2,ZERO
	ble %r2,%r3,SAVE
	mv %r2,%r3
	j SAVE
ZERO:	mv %r2,zero
SAVE:	sh %r2,%imm(%pos)
.end_macro
#########################################################
#	Armazena a posição armazenada em %label		#
#	nos registradores %x e %y.			#
#########################################################
.macro load_pos(%label, %x, %y)
la %y,%label
lh %x,0(%y)
lh %y,2(%y)
.end_macro

#########################################################
#	Armazena a posição armazenada no endereço	#
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
#	e pula para %label.
#							#
#	Para mais informações veja ATTACK TABLE		#
#	em game.s					#
#########################################################
.macro register_attack(%address, %n, %label)
	lb t1,0(%address)
	bnez t1,END
	li t1,%n
	sb t1,0(%address)
END:	j %label
.end_macro

#########################################################
#	Incrementa %value ao BYTE no endereço		#
#	%r1 + %imm usando $r como auxiliar.		#
#########################################################
.macro b_increment_ar(%r1, %value, %imm, %r)
lb %r,%imm(%r1)
add %r,%r,%value
sb %r,%imm(%r1)
.end_macro

#########################################################
#	Decrementa %value do BYTE no endereço		#
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
#	Incrementa %value a HALFWORD no endereço	#
#	%r1 + %imm usando $r como auxiliar.		#
#########################################################
.macro h_increment_ar(%r1, %value, %imm, %r)
lh %r,%imm(%r1)
add %r,%r,%value
sh %r,%imm(%r1)
.end_macro
