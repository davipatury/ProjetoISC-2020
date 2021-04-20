.include "macros.s"		# Macros do codigo

.text
	call SETUP_MUSIC
LOOP:	play_music(0, zero)	# normal track
	play_music(1, zero)	# bg track
	j LOOP
	

.include "music.s"
