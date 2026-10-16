* Relocatable CODE section. The DATA section is rel-data-lisa.s.
* LISA has no EXT. HOOK and VALUE stand in as the other section.
* CODE calls HOOK and addresses VALUE.

         XC
         MX     %11
.OR    0
HOOK     .EQ    0
VALUE    .EQ    0
CODE
         JSR    HOOK
         LDA    |VALUE
         .DA    VALUE
         RTL
