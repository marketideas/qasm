* [QASM] SYNTAX MERLIN16
* [QASM] Filetype $06
* [QASM] AuxType $2000
* [QASM] Volume TESTASM test.2mg 800K prodos 2mg
* [QASM] save TESTASM :SOURCE:${FILE}.bin


         xc    off
         xc
         xc
                          ;lst  OFF
ZP       equ   $00
         org   $2000
         ora   ($00)
         lda   ($00)
         bit:  $FFFE,X
         ror:  $FFFE,X
         ora   #ZP
begin
                          ;]m   equ        *
                          ;     lda        begin
                          ;     lda        ]m
         lst   on
                          ;end

_mymac   mac
]mac1    lda   ]mac1
         ldal  ]1
         ldal  ]2
         eom

_ascmac  mac
         asc   ]1,]2,8D
         eom
         lst   off
                          ;var  'one';'two';'three'
justlable                  ;line with just a lable
start
another  lda   #$00       ;line with everything
         lda   #$00       ;line with opcode, operand comment
         nop              ;line with just opcode
         _mymac *;1
         _mymac *;2
         _ascmac 'hello';'there'

         lup   2
]m       equ   *
         nop
         lda   ]m
         bra   ]m
         --^
]1       nop
         nop
         lst
         bra   ]1

                          ;typ  $06
         sav   0/test.bin
         lst   off
