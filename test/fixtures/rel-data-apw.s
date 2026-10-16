* Relocatable DATA section. The CODE section is rel-code-apw.s.
* hook calls code and addresses it. value is the byte code loads.

* Assembler: APW
         case   on
         machine 65816
         longa  off
         longi  off
         absaddr off
         msb    off
         org    0
data     start
         extern code
value    dc     i1'$42'
hook     entry
         jsr    code
         lda    |code
         dc     i2'code'
         rts
         end
