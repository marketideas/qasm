	lst 
	xc
	xc

	mx %00
	org $4000

start nop
	ldy #$00
]loop sta	$800,y
	dey
	bne 	]loop
	bcs		]loop
	bpl		]loop
	rts

	fls

	lst on

