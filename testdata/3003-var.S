	lst 
	xc
	xc

	mx %00
	org $4000

getkey = $FF00

]myvar = getkey

start nop
	ldy #$00
]loop sta	$800,y
	dey
	;dw 	]loop;]loop2
	;bne 	]myvar;

	bcs		]loop
	bpl		]loop
	rts

	;use		var
	lst on

