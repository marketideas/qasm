
	rel
	xc
	xc


*	ext gequ1
	ext gequ2
	lda #gequ1
	ldy #equ1
	ldx #gequ2
	rtl

* verify all sizes work
	db gequ2
	dw gequ2
	ddb gequ2
	adr gequ2
	adrl gequ2

	sav 3010-gequ.L
	sym
