*
* test rel DS \ command to verify it uses the current segment offset,
* not the current file offset.
*

	ovr all
	asm 3012-rel-ds-1.S
	asm 3012-rel-ds-2.S
	asm 3012-rel-ds-3.S

	lnk 3012-rel-ds-1.L
	lnk 3012-rel-ds-2.L
	lnk 3012-rel-ds-3.L

	sav 3012-rel-ds
