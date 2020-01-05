* QAsm builtin macros

tll	mac
	ldx	#]1
	jsl	$e10000
	eom
dos	mac
	jsl	$e100a8
	dw	]1
	adrl	]2
	eom
tlc	mac
	ldx	#]1
	jsl	$e10000
	bcc	*+4
	brk	$00
	eom
psl	mac
	if	#,]1
	pea	^]1
	pea	]1
	else
	lda	]1+2
	pha
	lda	]1
	pha
	fin
	eom
psw	mac
	if	#,]1
	pea	]1
	else
	lda	]1
	pha
	fin
	eom
pll	mac
	pla
	sta	]1
	pla
	sta	]1+2
	eom
plw	mac
	pla
	sta	]1
	eom
bsr	mac
	per	*+4
	bra	]1
	eom
bsrl	mac
	per	*+5
	brl	]1
	eom
jmi	mac
	bpl	*+5
	jmp	]1
	eom
jpl	mac
	bmi	*+5
	jmp	]1
	eom
jne	mac
	beq	*+5
	jmp	]1
	eom
jeq	mac
	bne	*+5
	jmp	]1
	eom
jlt	mac
	bge	*+5
	jmp	]1
	eom
jge	mac
	blt	*+5
	jmp	]1
	eom
ble	mac
	blt	]1
	beq	]1
	eom
jle	mac
	beq	*+4
	bge	*+5
	jmp	]1
	eom
jcs	mac
	bcc	*+5
	jmp	]1
	eom
jcc	mac
	bcs	*+5
	jmp	]1
	eom
jvs	mac
	bvc	*+5
	jmp	]1
	eom
jvc	mac
	bvs	*+5
	jmp	]1
	eom
jmil	mac
	bpl	*+6
	jml	]1
	eom
jpll	mac
	bmi	*+6
	jmp	]1
	eom
jnel	mac
	beq	*+6
	jml	]1
	eom
jeql	mac
	bne	*+6
	jml	]1
	eom
jgel	mac
	blt	*+6
	jml	]1
	eom
jltl	mac
	bge	*+6
	jml	]1
	eom
jlel	mac
	beq	*+4
	bge	*+6
	jml	]1
	eom
jcsl	mac
	bcc	*+6
	jml	]1
	eom
jccl	mac
	bcs	*+6
	jml	]1
	eom
jvsl	mac
	bvc	*+6
	jml	]1
	eom
jvcl	mac
	bvs	*+6
	jml	]1
	eom
