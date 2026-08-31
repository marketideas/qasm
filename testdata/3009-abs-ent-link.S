* link file
* generated file should not have any OMF relocation records.

	ovr all
	asm 3009-abs-ent-1.S
	asm 3009-abs-ent-2.S
	lnk 3009-abs-ent-1.L
	lnk 3009-abs-ent-2.L
	sav 3009-abs-ent
