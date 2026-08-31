*
* verify ext imports an absolute ent label and can use it in expressions.
*
	ovr all
	asm 3014-ext.S
	lnk 3014-ext.L
extra	ext
	ds extra ; 128 byte reserved space
	sav 3014-ext
