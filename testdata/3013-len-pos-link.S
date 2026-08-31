
	ovr all

	asm 3013-len-pos-1.S
	asm 3013-len-pos-2.S

	lnk 3013-len-pos-1.L

	len my_len_1
	pos my_pos_1

	lnk 3013-len-pos-2.L

	len my_len_2
	pos my_pos_2

	pos
	pos my_pos_0



	sav 3013-len-pos

	ent