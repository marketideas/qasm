* link file
* link script gequ symbols are visible to both the assembler and linker
*
*

	ovr all
* this geq available at asm-time
gequ1	geq 1
equ1	equ 2

	asm 3010-gequ.S
* this geq available at link-time
gequ2	geq 3

	lnk 3010-gequ.L
	sav 3010-gequ

	ent
