* Relocatable DATA section. The CODE section is rel-code-lisa.s.
* LISA has no EXT. CODE stands in as the other section.
* HOOK calls CODE and addresses it. VALUE is the byte CODE loads.

         XC
         MX     %11
.OR    0
CODE     .EQ    0
VALUE
         .DB    $42
HOOK
         JSR    CODE
         LDA    |CODE
         .DA    CODE
         RTS
