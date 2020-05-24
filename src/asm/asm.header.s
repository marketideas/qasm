            lst   off
            ;cas   in
            tr    on
            exp   only

            rel
            xc
            xc
            mx    %00               ; make sure we're in 16-bit mode!

            ;use   util.macs
            use   ../macros/builtin.macs
            use   ../macros/qatools.macs
            use   ../data/qa.equates
            use   ../data/sym.equates

            use   asm.macs


            brl   start

userid      ds    2                 ;my userid
message     ds    2
subtype     ds    4
asmdp       ds    2

filename    ds    130,0
txttypes    hex   0204B0

start       php
            phb
            phd
            phk
            plb
            rep   $30
            sta   userid
            tdc
            sta   asmdp
            pea   0
            _QAStatus
            pla
            bne   :ok
            pld
            plb
            plp
            rep   $30
            jsl   prodos
            dw    $29
            adrl  :quit
:quit       adrl  $00
            dw    $00

:ok         rep   $30
            stz   prodoserr

            pea   0
            psl   #$00
            lda   userid
            pha
            _QAGetMessagebyID
            pll   subtype
            pla
            sta   message
            beq   :0
            cmp   #maxamessage
            blt   :call
            lda   #$FFFF
            jmp   :xit
:0          lda   #$00
            jmp   :xit
:call       dec
            asl
            tax
            jsr   (:tbl,x)
:xit        rep   $30
            pha
            lda   userid
            ora   #asmmemid
            pha
            _DisposeAll
            pla
            pld
            plb
            plp
            cmpl  :one
            rtl
:one        dw    $01

:tbl        dw    cmdline           ;parsecmdline
            dw    txtfile
            dw    loadedfile

loadedfile  php
            rep   $30
            psl   #asmstr
            _QADrawString
            lda   #'.'
            jsr   drawchar
            lda   #$0d
            jsr   drawchar
            jsr   drawchar
            ldx   subtype
            ldy   subtype+2
            jsl   asm
            bcc   :clc
:sec        rep   $30
            plp
            sec
            rts
:clc        plp
            clc
            rts

txtfile     php
            rep   $30
            psl   #pathname
            _QAGetPath
            lda   pathname
            and   #$ff
            jeq   :notfound
            tay
            sep   $20
]lup        lda   pathname,y
            tyx
            sta   filename,x
            dey
            bpl   ]lup
            rep   $30
            jsr   append_dots

            psl   #$00
            psl   #filename
            psl   #$00              ;filepos
            psl   #-1               ;whole file
            psl   #txttypes
            lda   userid
            ora   #asmmemid
            pha
            psl   #$00
            pea   $8000
            _QALoadfile
            plx
            ply
            jcs   :sec
            phx
            phy
            psl   #asmstr
            _QADrawString
            lda   #' '
            jsr   drawchar
            psl   #filename
            _QADrawString
            lda   #$0d
            jsr   drawchar
            jsr   drawchar
            ply
            plx
            jsl   asm
            bcc   :clc
            jmp   :sec
:notfound   rep   $30
            lda   #$46              ;file not found error
:sec        rep   $30
            plp
            sec
            rts
:clc        rep   $30
            lda   #$00
            plp
            clc
            rts

cmdline     php
            rep   $30
            stz   pathname
            psl   #pathname
            pea   80
            _QAGetCmdLine
            ldy   #$01
            sep   $30
            lda   pathname
            beq   :notfound
]lup        lda   pathname,y
            and   #$7f
            cmp   #' '
            blt   :notfound
            bne   :p1
            iny
            jmp   ]lup
:p1         iny
]lup        lda   pathname,y
            and   #$7f
            cmp   #' '
            blt   :notfound
            beq   :p2
            iny
            jmp   ]lup
:p2         iny
]lup        lda   pathname,y
            and   #$7f
            cmp   #' '
            blt   :notfound
            bne   :ok
            iny
            jmp   ]lup
:ok         ldx   #$00
            sta   filename+1,x
]get        inx
            iny
            lda   pathname,y
            and   #$7f
            cmp   #' '+1
            blt   :set
            sta   filename+1,x
            jmp   ]get
:notfound   jmp   :nf1
:set        txa
            sta   filename
            rep   $30
            jsr   append_dots

            psl   #$00
            psl   #filename
            psl   #$00              ;filepos
            psl   #-1               ;whole file
            psl   #txttypes
            lda   userid
            ora   #asmmemid
            pha
            psl   #$00
            pea   $8000
            _QALoadfile
            plx
            ply
            bcs   :xit
            phy
            phx
            psl   #asmstr
            _QADrawString
            lda   #' '
            jsr   drawchar
            psl   #filename
            _QADrawString
            lda   #$0d
            jsr   drawchar
            jsr   drawchar
            plx
            ply
            jsl   asm
            bcc   :clc1
            jmp   :xit
:nf1        rep   $30
            lda   #$46
            sec
            jmp   :xit
:clc1       rep   $30
            lda   #$0000
:xit        rep   $30
            plp
            cmpl  :one
            rts
:one        dw    $01


append_dots
            lda   filename
            and   #$ff
            beq   :rts
            cmp   #62
            bcs   :rts
            tax
            lda   #'.S'
            sta   filename+1,x
            sep   $30
            lda   filename,x
            cmp   #'/'
            beq   :rts
            cmp   #':'
            beq   :rts
            and   #$df
            cmp   #'S'
            bne   :append
            lda   filename-1,x
            cmp   #'.'
            beq   :rts
:append     inx
            inx
            stx filename

:rts        rep   $30
            rts

asmstr      str   0d,'Assembling'

prbytel
            php
            rep   $30
            phy
            phx
            pha
            pha
            _QAPrbytel
            pla
            plx
            ply
            plp
            rts

prbyte
            php
            rep   $30
            phy
            phx
            pha
            pha
            _QAPrbyte
            pla
            plx
            ply
            plp
            rts


drawchar    php
            rep   $30
            phx
            phy
            pha
            and   #$7f
            pha
            _QADrawChar
:plp        pla
            ply
            plx
            plp
            rts


printdec    php
            rep   $30
            phx
            pha
            psl   #:str
            pea   #11
            pea   $00
            _Long2Dec
            sep   $30
            ldy   #$00
            ldx   #$00
]lup        lda   :str,x
            and   #$7f
            cmp   #' '
            beq   :inx
            cmp   #'0'
            bne   :draw
            cpx   #10
            bge   :draw
            cpy   #$00
            beq   :inx
:draw       phy
            phx
            rep   $30
            jsr   drawchar
* pha
* _WriteChar
            sep   $30
            plx
            ply
            iny
:inx        inx
            cpx   #11
            blt   ]lup
            plp
            rts
:str        ds    12,0

drawlable   php
            rep   $30
            pea   $00
            tdc
            clc
            adc   #labstr
            pha
            _QADrawString
            lda   #$0d
            jsr   drawchar
            plp
            rts

random      php                     ;save environment
            phb
            phk
            plb
            rep   %00111001
            ldx   indexi
            ldy   indexj
            lda   array-2,x
            adc   array-2,y
            sta   array-2,x
            dex
            dex
            bne   :dy
            ldx   #17*2             ;cycle index if at end of
:dy         dey                     ; the array
            dey
            bne   :setix
            ldy   #17*2
:setix      stx   indexi
            sty   indexj
            plb
            plp
            rts

indexi      da    17*2              ;the relative positions of
indexj      da    5*2               ; these indexes is crucial

array       da    1,1,2,3,5,8,13,21,54,75,129,204
            da    323,527,850,1377,2227

            err   *-array-34

*=================================================
* SEED seeds generator from 16 bit contents of AXY
*-------------------------------------------------

seed        php
            rep   %00110000
seed2       phb
            phk
            plb
            pha
            ora   #1                ;at least one must be odd
            sta   array
            stx   array+2
            phx                     ;push index regs on stack
            phy
            ldx   #30
]lup        sta   array+2,x
            dex
            dex
            lda   1,s               ;was y
            sta   array+2,x
            dex
            dex
            lda   3,s               ;was x
            sta   array+2,x
            lda   5,s               ;original a
            dex
            dex
            bne   ]lup
            lda   #17*2
            sta   indexi            ;init proper indexes
            lda   #5*2              ; into array
            sta   indexj
            jsr   random            ;warm the generator up.
            jsr   random
            ply                     ;replace all registers
            plx
            pla
            plb
            plp
            rts

*=================================================
* RANDOMIZE seed generator from system clock.
* Assumes Misc Toolset active.
*-------------------------------------------------

randomize   php
            rep   %00110000
            lda   #0
            pha
            pha
            pha
            pha
            ldx   #$D03             ;readtimehex
            jsl   $E10000
            pla
            plx
            ply
            sta   1,s               ;trick to pull last word
            pla                     ; fm stack without ruining
            bra   seed2             ; the previous ones.

            put   asm.vars
            put   asm.1
            put   asm.eval
            put   asm.cond
            put   asm.opcodes
            put   asm.dsk
            put   asm.errors
            put   ../data/opdata

            lst
            chk
            lst   off

            ;typ   exe
            sav   qasmgs.l

