         lst   off
* Merlin 16+ opcode / addressing smoke test
* File type BIN ($06), load $2000



         xc    off
         xc
         xc

ZP       equ   $00
         org   $2000

         lda   <$fff0     ; force DP
         lda   >$fff0     ; force long
         lda   ^$fff0     ; abs, high word
         lda   |$fff0     ; force abs
         lda   <$FFF0+$FFFF

         lda   <$fff0+24  ; force DP
         lda   >$fff0+24  ; force long
         lda   ^$fff0+24  ; abs, high word
         lda   |$fff0+24  ; force abs
         ldal  $fff0+24   ; long
         lda:  $fff0+24   ; force abs
         lda:  $00

         mx    %11
         lda   #<$fff0    ; imm low byte
         lda   #>$fff0    ; imm high byte
         lda   #^$fff0    ; imm bank
         lda   #<$FFF0+$FFFF
         lda   #>$FFF0+$FFFF
         lda   #^$FFF0+$FFFF

         mx    %00
         lda   #<$fff0    ; imm low word
         lda   #>$fff0    ; imm high word
         lda   #^$fff0    ; imm bank word
         lda   #<$FFF0+$FFFF
         lda   #>$FFF0+$FFFF
         lda   #^$FFF0+$FFFF

         ora   ($00)
         lda   ($00)
         bit:  $FFFE,X
         ror:  $FFFE,X
         ora   #ZP
begin
                          ;]m      equ   *
         lda   begin
                          ;lda  ]m

_mymac   mac
]mac1    lda   ]mac1
         ldal  ]1
         ldal  ]2
         eom

_ascmac  mac
         asc   ]1,]2,8D
         eom
                          ;var  'one';'two';'three'
justlable                  ;line with just a lable
start
another  lda   #$00       ;line with everything
         lda   #$00       ;line with opcode, operand comment
         nop              ;line with just opcode
         _mymac *;1
         _mymac *;2
                          ;_ascmac 'hello';'there'

                          ;lup  2
                          ;]m      equ   *
                          ;nop
                          ;lda  ]m
                          ;bra  ]m
                          ;--^

]1       nop
         nop
                          ;bra  ]1

                          ;typ  $06
         db    255
]DPNOP   equ   $80
         lda   ]DPNOP
         jsr   DPCODE
         rts
         org   $0080
DPCODE   nop
         lda   DPCODE
         lda   |DPCODE
         lda   >DPCODE

         lst
         chk
         lst   off
