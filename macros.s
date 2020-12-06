#################################################################
#	Desenhar imagem						#
#								#
# a0 = endereço inicial da imagem (excluindo o tamanho)		#
# a1 = x inicial NA FRAME					#
# a2 = y inicial NA FRAME					#
# a3 = largura da area de desenho				#
# a4 = altura da area de desenho				#
# a5 = frame (0 ou 1)						#
# a6 = x inicial NA IMAGEM					#
# a7 = y inicial NA IMAGEM					#
#								#
#################################################################
.macro render(%adr, %x, %y, %w, %h, %f, %x0, %y0)
la a0,%adr	# endereço da imagem
li a1,%x	# x
li a2,%y	# y
li a3,%w	# width
li a4,%h	# height
mv a5,%f	# frame (0 ou 1)
li a6,%x0	# x0
li a7,%y0	# y0
jal RENDER
.end_macro

.macro render_a(%adr, %x, %y, %w, %h, %f, %x0, %y0)
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

# FRAME CONTROL
.eqv FRAME_CTRL_ADDR 0xFF200604

.macro current_frame(%r)
li %r,0xFF200604
lw %r,0(%r)
.end_macro

.macro next_frame(%r)
li %r,0xFF200604
lw %r,0(%r)
xori %r,%r,0x001
.end_macro

.macro toggle_frame()
li t0,0xFF200604
lw t1,0(t0)
xori t1,t1,0x001
sw t1,0(t0)
li a0,50
li a7,32
ecall	
.end_macro

# CHAR CONTROL
.macro load_char_pos(%x, %y)
la %y,CHAR_POS
lh %x,0(%y)
lh %y,2(%y)
.end_macro

.macro check_key(%n, %label, %r, %r1)
li %r1,%n
beq %r,%r1,%label
.end_macro

.macro register_attack(%n)
lb t0,CHAR_ATTACK
bnez t0,REC_INPUT_CLN
la t0,CHAR_ATTACK
li t1,%n
sb t1,0(t0)
j REC_INPUT_CLN
.end_macro

# MEMORY
.macro b_increment(%label, %value, %imm, %r, %r1)
la %r1,%label
lb %r,%imm(%r1)
addi %r,%r,%value
sb %r,%imm(%r1)
.end_macro

.macro b_decrement(%label, %value, %imm, %r, %r1)
la %r1,%label
lb %r,%imm(%r1)
addi %r,%r,-%value
sb %r,%imm(%r1)
.end_macro
