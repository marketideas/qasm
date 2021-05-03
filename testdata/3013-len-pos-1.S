
	rel

	ext my_pos_0
	ext my_len_1,my_pos_1
	ext my_len_2,my_pos_2

	lda #my_len_1
	lda #my_len_2
	ldx #my_pos_1
	ldx #my_pos_2
	ldy #my_pos_0
	rtl

	sav 3013-len-pos-1.L