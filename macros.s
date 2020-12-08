.macro apply_multiplier(%imm, %r, %mul)
li %r,%imm
mul %r,%r,%mul
.end_macro

.macro push_clear(%off)
la t0,FRAME_CLR
addi t0,t0,%off
lw t1,0(t0)
lw t2,4(t0)
sw t1,8(t0)
sw t2,12(t0)
.end_macro

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

#################################################################
#	Desenhar imagem						#
#								#
# a0 = endereço inicial da imagem 				#
# a1 = x inicial NA FRAME					#
# a2 = y inicial NA FRAME					#
# a3 = largura da area de desenho				#
# a4 = altura da area de desenho				#
# a5 = frame (0 ou 1)						#
# a6 = x inicial NA IMAGEM					#
# a7 = y inicial NA IMAGEM					#
#								#
#################################################################
.macro render_a(%adr, %x, %y, %w, %h, %f, %x0, %y0)
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

.macro render_ab(%adr, %x, %y, %w, %h, %f, %x0, %y0)
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

.macro render_b(%adr, %x, %y, %w, %h, %f, %x0, %y0)
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

# FRAME CONTROL
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
#li a0,50
#li a7,32
#ecall	
.end_macro

.macro reset_frame()
li t0,0xFF200604
sw zero,0(t0)
.end_macro

.macro background_offset(%r, %r1)
lb %r,CURRENT_MAP
li %r1,240
mul %r,%r,%r1
.end_macro

# CHAR CONTROL
.macro load_pos(%label, %x, %y)
la %y,%label
lh %x,0(%y)
lh %y,2(%y)
.end_macro

.macro load_pos_r(%r, %x, %y)
lh %x,0(%r)
lh %y,2(%r)
.end_macro

.macro check_key(%n, %label, %r, %r1)
li %r1,%n
beq %r,%r1,%label
.end_macro

.macro register_p1_attack(%n)
lb t0,P1_ATTACK
bnez t0,REC_INPUT_CLN
la t0,P1_ATTACK
li t1,%n
sb t1,0(t0)
j REC_INPUT_CLN
.end_macro

# MEMORY

# BYTE
.macro b_increment_ar(%r1, %value, %imm, %r)
lb %r,%imm(%r1)
add %r,%r,%value
sb %r,%imm(%r1)
.end_macro

.macro b_decrement_ar(%r1, %value, %imm, %r)
li %r,-1
mul %value,%value,%r
lb %r,%imm(%r1)
add %r,%r,%value
sb %r,%imm(%r1)
.end_macro

# HALF WORD
.macro h_increment(%label, %value, %imm, %r, %r1)
la %r1,%label
lh %r,%imm(%r1)
addi %r,%r,%value
sh %r,%imm(%r1)
.end_macro

.macro h_increment_ar(%r1, %value, %imm, %r)
lh %r,%imm(%r1)
add %r,%r,%value
sh %r,%imm(%r1)
.end_macro

.macro h_decrement(%label, %value, %imm, %r, %r1)
la %r1,%label
lh %r,%imm(%r1)
addi %r,%r,-%value
sh %r,%imm(%r1)
.end_macro

.macro h_decrement_ar(%r1, %value, %imm, %r)
li %r,-1
mul %value,%value,%r
lh %r,%imm(%r1)
add %r,%r,%value
sh %r,%imm(%r1)
.end_macro

.macro print_int(%r)
mv a0,%r
li a7,1
ecall
li a0,' '
li a7,11
ecall
.end_macro

.macro print_nl()
li a0,10
li a7,11
ecall
.end_macro