		lst
		xc
		xc
		org	$018200

bank02	equ	$020000
bank03	equ $030000
dp		equ	$55
long	equ	$020304

		mx	%00
start	nop
		pea	#^start
		pea	#start
		pea ^start
		pea	start
		lda #^start
		lda start
		lda ^start
		mvn	bank02,bank03
		mvp	bank03,bank02
		lda	dp
		lda <dp
		lda >dp
		lda #^dp  ; just ^dp is illegal in Merlin16
		lda |dp
		lda #long
		lda #<long
		lda #>long
		lda	#^long
		lda	#long

		lst
		chk
		lst off
