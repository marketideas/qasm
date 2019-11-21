		lst
		xc
		xc
		org	$018200

bank02	equ	$020000
bank03	equ $030000
dp		equ	$A5
long	equ	$020304

		mx	%00
start	nop
		pea	^start
		pea	start
		mvn	bank02,bank03
		mvp	bank03,bank02
		lda	dp
		lda <dp
		lda >dp
		lda ^dp
		lda |dp
		lda #long
		lda #<long
		lda #>long
		lda	#^long
		lda	#long

		lst off
