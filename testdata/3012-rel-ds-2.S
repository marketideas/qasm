	rel


a	ent
b	ent
c	ent
	nop
	nop

* should generate $100 - 4  bytes of $ff since 2 bytes in first file, 2 bytes above.
* extra ent labels to verify the DS padding algorithm adjusts the relacation records.

	ds \,$ff
d	ent

	sav 3012-rel-ds-2.L
