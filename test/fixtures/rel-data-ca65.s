; Relocatable DATA section. The CODE section is rel-code-ca65.s.
; HOOK calls CODE and addresses it. VALUE is the byte CODE loads.

.p816
.a8
.i8
.org     0
.segment "DATA"
.import  CODE
.export  VALUE
.export  HOOK
VALUE:
         .byte  $42
HOOK:
         jsr    CODE
         lda    a:CODE
         .word  CODE
         rts
