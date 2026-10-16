* Relocatable DATA section. The CODE section is rel-code-merlin.s.
* HOOK calls CODE and addresses it. VALUE is the byte CODE loads.

         XC
         MX     %11
         REL
         EXT    CODE
VALUE    DFB    $42
HOOK     ENT
         JSR    CODE
         LDA    |CODE
         DA     CODE
         RTS
