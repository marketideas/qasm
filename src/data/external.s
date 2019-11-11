             lst   off
             tr    on
             exp   only
             typ   EXE               ;we are a shell 'command'
             rel
             xc
             xc
             mx    %00               ; make sure we're in 16-bit mode!

             use   4/util.macs

             brl   start             ;starts with 8 branches
             brl   rtl
             brl   rtl
             brl   rtl
             brl   rtl
             brl   rtl
             brl   rtl
             brl   rtl
             dw    $00
             asc   'MERLIN'          ;id number

ptr          equ   0

userid       ds    2
commandline  ds    129,0

rtl          rtl

start        rep   $30
             phk
             plb
             sta   userid
             stx   ptr+2
             sty   ptr
             ldy   #$00
             sep   $20
]lup         lda   [ptr],y
             and   #$7f
             cmp   :id,y
             bne   :xit
             iny
             cpy   #$08
             blt   ]lup
             ldx   #$00
]f           lda   [ptr],y
             and   #$7f
             cmp   #' '
             blt   :xit
             beq   :iny
             cpx   #$00
             bne   :ok
             iny
             jmp   ]f
:iny         iny
             inx
             jmp   ]f
:ok          sep   $20
             ldx   #$00
             sta   commandline+1,x
]get         inx
             iny
             lda   [ptr],y
             and   #$7f
             cmp   #' '+1
             blt   :set
             sta   commandline+1,x
             jmp   ]get
:set         txa
             sta   commandline
             rep   $30
             jsr   doit
:xit         rep   $30
             jsl   prodos
             dw    $29
             adrl  :quit
             brk   $00
:quit        adrl  $00
             dw    $00

:id          asc   'MERLINGS'

doit         php
             rep   $30
             lda   commandline
             and   #$ff
             tax
             lda   commandline,x
             and   #$7f
             cmp   #'/'
             beq   :nosuff
             inx
             lda   #'.S'
             sta   commandline,x
             inx
             txa
             sep   $20
             sta   commandline
:nosuff      rep   $30
             psl   #commandline
             tll   $1c0c
             pea   "|"
             tll   $180c
             plp
             rts

             sav   6/external.l


