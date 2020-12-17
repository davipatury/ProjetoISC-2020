.eqv MUSIC_VOL 40

.data
.word
MUSIC_STATUS:	0, 0, 0, 0		# current position / last duration / last played
		0, 0, 0, 0
MUSIC_LENGTH:	23, 24, 14, 18
		4, 4, 6, 15
MUSIC_TRACKS:	0, 0, 0, 0
		0, 0, 0, 0

MUSIC_TRACK1:	67,1000,76,125,76,125,76,125,74,375,76,250, 83,1000,76,125,76,125,76,125,79,375,79,250, 76,1000,69,125,69,125,69,125,72,375,72,250, 69,1000,65,250,69,250,65,250,69,250
MUSIC_TRACK2:	71,125,71,125,71,125,69,125,74,250,73,250, 71,125,71,125,71,125,69,125,76,250,74,250, 69,125,69,125,69,125,67,125,74,250,73,250, 71,125,71,125,71,125,69,125,74,250,73,250
MUSIC_TRACK3:	67,250,64,250,71,1000, 69,500, 67,250,69,250,66,1500, 67,250,64,250,69,1000, 67,500, 66,250,67,250,62,1000
MUSIC_TRACK4:	60,250,62,2250, 64,500,62,2000, 57,250,62,2250, 77,125,76,125,74,125,72,125, 71,125,69,125,67,125,65,125, 64,125,62,125,60,125,59,125

MUSIC_TRACK1_B:	55,2000,52,2000,57,2000,53,2000
MUSIC_TRACK2_B:	52,1000,55,1000,50,1000,52,1000
MUSIC_TRACK3_B:	55,1750,50,500,48,2000,52,1750,48,500,50,2000
MUSIC_TRACK4_B:	38,1000,38,1000,38,1000,38,1000,38,1000,38,1000,38,1000,38,1000,38,1000,38,1000,38,1000,38,1000,38,500,38,500,38,500

# s1 = track offset (0 = main, 1 = background)
# s2 = current track (0, 1, 2, 3)
.text
MUSIC:		li t0,16
		mul t0,t0,s1
		la s0,MUSIC_STATUS
		add s0,s0,t0

		lw t0,8(s0)		# last played
		tempo(t1)
		sub t1,t1,t0		# last played - now
		lw t0,4(s0)		# last duration
		bge t1,t0,MUSIC_PLAY
		
		ret

MUSIC_PLAY:	lw t0,0(s0)		# current position
		addi t1,s0,32
		li t2,4
		mul t2,t2,s2
		add t1,t1,t2
		lw t2,0(t1)		# track length
		blt t0,t2,MUSIC_NOTE
		
		sw zero,0(s0)
		sw zero,4(s0)
		sw zero,8(s0)
		
		j MUSIC_PLAY

MUSIC_NOTE:	addi t1,s0,64
		li t2,4
		mul t2,t2,s2
		add t1,t1,t2
		lw t2,0(t1)		# track address
		
		slli t0,t0,3		# curr position * 8
		add t2,t2,t0		# track address + (curr pos * 8)
		
		lw a0,0(t2)
		lw a1,4(t2)
		mv a2,zero
		li a3,MUSIC_VOL
		li a7,31
		ecall
		
		lw t0,0(s0)
		addi t0,t0,1
		sw t0,0(s0)		# current position += 1
		
		sw a1,4(s0)		# last duration
		
		tempo(t0)
		sw t0,8(s0)		# last played = now
		
		ret

SETUP_MUSIC:	la t0,MUSIC_TRACKS

		la t1,MUSIC_TRACK1
		sw t1,0(t0)
		la t1,MUSIC_TRACK2
		sw t1,4(t0)
		la t1,MUSIC_TRACK3
		sw t1,8(t0)
		la t1,MUSIC_TRACK4
		sw t1,12(t0)
		
		la t1,MUSIC_TRACK1_B
		sw t1,16(t0)
		la t1,MUSIC_TRACK2_B
		sw t1,20(t0)
		la t1,MUSIC_TRACK3_B
		sw t1,24(t0)
		la t1,MUSIC_TRACK4_B
		sw t1,28(t0)
		
		ret
