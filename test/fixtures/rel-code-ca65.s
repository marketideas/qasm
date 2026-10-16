; Relocatable CODE section. The DATA section is rel-data-ca65.s.
; CODE calls HOOK and addresses VALUE. Both are resolved by the linker.

.p816
.a8
.i8
.org     0
.segment "CODE"
.export  CODE
.import  HOOK, VALUE
CODE:
         jsr    HOOK
         lda    a:VALUE
         .word  VALUE
         rtl
