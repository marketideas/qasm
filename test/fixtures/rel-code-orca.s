* Relocatable CODE section. The DATA section is rel-data-orca.s.
* code calls hook and addresses value. Both are resolved by the linker.

         case   on
         machine 65816
         longa  off
         longi  off
         org    0
code     start
         extern hook,value
         jsr    hook
         lda    |value
         dc     i2'value'
         rtl
         end
