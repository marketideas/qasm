* Relocatable CODE section. The DATA section is rel-data-merlin32.s.
* CODE calls HOOK and addresses VALUE. Both are resolved by the linker.

PAD      GEQ    0
         XC
         MX     %11
         REL
CODE     ENT
         EXT    HOOK,VALUE
         JSR    HOOK
         LDA    |VALUE
         DA     VALUE
         RTL
