.data
M_CUR_POS:	.half 0
M_LAST_DUR:	.word 0
M_LAST_PLAYED:	.word 0
M_STATUS:	0, 0, 0		# curr position / last duration / last played

M_NOTAS_TOTAL:	.word 63	# total de notas
M_NOTAS:	60,234,72,234,67,234,65,234,77,234,67,234,76,234,67,234,60,234,72,234,67,234,65,234,77,234,67,234,76,234,67,234,62,234,72,234,67,234,65,234,77,234,67,234,76,234,67,234,62,234,72,234,67,234,65,234,77,234,67,234,76,234,67,234,65,234,72,234,67,234,65,234,77,234,67,234,76,234,67,234,65,234,72,234,67,234,65,234,77,234,67,234,76,234,67,234,74,234,67,234,72,234,67,234,74,234,67,234,76,234,67,234,77,234,67,234,76,234,67,234,74,234,67,234,72,469

.text
MUSIC:	lw t1,M_LAST_PLAYED	# t1 = last played	
	beq t1,zero,M_CONT	# if last played == 0 THEN continue loop (primeira ocorrência)

	li a7,30		# define o syscall Time
	ecall			# time
	lw t0,M_LAST_DUR	# t0 = duracao da ultima nota
	sub t1,a0,t1		# t1 = agora - quando a ultima nota foi tocada (quanto tempo passou desde a ultima nota tocada)
	bge t1,t0,M_CONT	# if t1 >= last duration THEN continue loop (se o tempo que passou for maior que a duracao da nota, toca a proxima nota)
	ret			# retorna ao main loop

M_CONT:	lh t0,M_CUR_POS		# contador
	lw t1,M_NOTAS_TOTAL	# carrega o total de notas da memoria
	ble t0,t1,M_NOTE	# if s0 != s1 THEN toca a proxima nota
	sw zero,M_CUR_POS,t0
	sw zero,M_LAST_DUR,t0
	sw zero,M_LAST_PLAYED,t0
	ret			# volta ao main loop

M_NOTE:	la t2,M_NOTAS		# endereço das notas
	slli t0,t0,3
	add t2,t2,t0
	lw a0,0(t2)		# le o valor da nota
	lw a1,4(t2)		# le a duracao da nota
	li a2,27		# instrumento
	li a3,127		# volume
	li a7,31		# define a chamada de syscall
	ecall			# toca a nota
	
	lw t1,M_CUR_POS
	addi t1,t1,1		# contador += 1
	sw t1,M_CUR_POS,t0	# salva o contador
	sw a1,M_LAST_DUR,t0	# salva a duracao da nota atual no last duration

	li a7,30		# define o syscall Time
	ecall			# time
	sw a0,M_LAST_PLAYED,t0	# salva o instante atual no last played

	ret			# return
