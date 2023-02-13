         lst   off
         xc    off
         xc
         xc

ZP       equ   $00
         org   $2000

         lda   <$fff0     ;zp
         lda   >$fff0     ;ABS (lo word)
         lda   ^$fff0     ;ABS (hi word)
         lda   |$fff0     ;ABS (long in 65816 mode)
         lda   <$FFF0+$FFFF

         lda   <$fff0+24  ;zp
         lda   >$fff0+24  ;ABS (lo word)
         lda   ^$fff0+24  ;ABS (hi word)
         lda   |$fff0+24  ;ABS (long in 65816 mode)
         ldal  $fff0+24   ;ABS (long in 65816 mode)
         lda:  $fff0+24   ;ABS (long in 65816 mode)
         lda:  $00

         mx    %11
         lda   #<$fff0    ;zp
         lda   #>$fff0    ;ABS (lo word)
         lda   #^$fff0    ;ABS (hi word)
         lda   #<$FFF0+$FFFF
         lda   #>$FFF0+$FFFF
         lda   #^$FFF0+$FFFF

         mx    %00
         lda   #<$fff0    ;zp
         lda   #>$fff0    ;ABS (lo word)
         lda   #^$fff0    ;ABS (hi word)
         lda   #<$FFF0+$FFFF
         lda   #>$FFF0+$FFFF
         lda   #^$FFF0+$FFFF

         ora   ($00)
         lda   ($00)
         bit:  $FFFE,X
         ror:  $FFFE,X
         ora   #ZP
]DPNOP   equ   $80
         lda   ]DPNOP
         jsr   DPCODE
         rts
ABS
         org   $0080
DPCODE   nop
         lda   DPCODE
         lda   |DPCODE
         lda   >DPCODE

        DFB $FF,#<ABS,#>ABS
        dfb 'string';D7;\slash\
        dfb 'string',D7,\slash\


         lst
         chk
         lst   off
