#################################################################
#	Desenhar imagem						#
#								#
# a0 = endereço inicial da imagem				#
# a1 = x inicial NA FRAME					#
# a2 = y inicial NA FRAME					#
# a3 = largura da area de desenho				#
# a4 = altura da area de desenho				#
# a5 = frame (0 ou 1)						#
# a6 = x0 inicial NA IMAGEM					#
# a7 = y0 inicial NA IMAGEM					#
# Usa de t0 ate t4						#
#################################################################
.text
RENDER:		li t0,0xFF0	# t0 = 0xFF0
		add a5,a5,t0	# frame = 0xFF0 + frame
		slli a5,a5,20	# frame << 20

		mv t4,a0	# endereço inicial da imagem
		addi a0,a0,8	# += 8 pra igualar ao endereço da imagem

		# Endereço inicial NA IMAGEM
		lw t1,0(t4)	# t1 = rw (real width)
		mul t1,t1,a7	# t1 = rw * y0
		add t1,t1,a6	# t1 = (rw * y0) + x0
		add a0,t1,a0	# t2 = a0 + (rw * y0) + x0
	
		li t0,320	# t0 = 320
		# Endereço inicial DA FRAME
		mul t1,t0,a2	# t1 = 320 * y
		add t1,t1,a1	# t1 = (320 * y) + x
		add a5,t1,a5	# a5 = a5 + (320 * y) + x
		mv t2,a5	# t2 (incrementador) = a5 (valor inicial)

		# Endereço final DA FRAME
		mul t3,t0,a4	# t3 = 320 * h
		add t3,t3,a3	# t3 = (320 * h) + w
		add t3,t3,a5	# t3 = a5 + (320 * h) + w

# Render Loop
# a0 = endereço da imagem
# t2 = endereço da frame
RENDER_LOOP:	bgeu t2,t3,RENDER_L_EXIT	# if endereço atual >= endereço final THEN jump to RLE
		lw t0,0(a0)	# carrega o conteudo da imagem no endereço a0 (imagem) em t0
		li t1,0xc7c7c7c7
		beq t0,t1,RENDER_LOOP_C
		sw t0,0(t2)	# salva o conteudo da imagem no endereço t2 (frame)
RENDER_LOOP_C:	addi a0,a0,4	# a0 += 4
		addi t2,t2,4	# t2 += 4

		li t0,320	# t0 = 320
		sub t1,t2,a5	# t1 = t2 - a5
		rem t1,t1,t0	# t1 = (t2 - a5) % 320

		blt t1,a3,RENDER_L_CHK_Y	# if current x >= width THEN incrementa

# Draw Loop Check X
RENDER_L_CHK_X:	sub t0,t0,a3	# t0 = 320 - w
		add t2,t2,t0	# incrementa o endereço pra proxima linha

		lw t0,0(t4)	# t0 = real image width
		sub t0,t0,a3	# t0 = real width - desired width	
		add a0,a0,t0	# a0 += real width - desired width

# Render Loop Check Y
RENDER_L_CHK_Y:	li t0,320	# t0 = 320
		sub t1,t2,a5	# t1 = t2 - a5
		div t1,t1,t0	# t1 = (t2 - a5) // 320

		blt,t1,a4,RENDER_L_CONT
		j RENDER_L_EXIT
	
# Render Loop Continue
RENDER_L_CONT:	j RENDER_LOOP

# Render Loop Exit
RENDER_L_EXIT:	ret		# return
