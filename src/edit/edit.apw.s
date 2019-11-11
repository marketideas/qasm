
loadapw     rep   $30
            stz   :toolarge
            stz   :merlin
            stz   :openflag
            stz   :loaded
            stz   apwlen
            stz   apwlen+2
:open       jsl   prodos
            dw    $10             ;open
            adrl  :oparm
            bcc   :ref
            jmp   :err
:ref        lda   :oparm
            sta   :rparm
            sta   :cparm
            sec
            ror   :openflag
            lda   #300            ;Read Header
            sta   :rin
:r1         jsl   prodos
            dw    $12
            adrl  :rparm
            bcc   :save
            jmp   :err
:save       jsr   newdoc1

:loop       rep   $30
            jsr   :readtwo
            bcs   :done1
            tay
            and   #$FF00
            cmp   #$D000
            bne   :n1
            jsr   :docr
            bcs   :done1
            bra   :loop
:n1         cmp   #$D800
            bge   :loop
            jsr   :dotext
            bcc   :loop
:done1      and   #$00ff
            cmp   #$4C
            beq   :done
            jmp   :err

:done       rep   $30
            lda   #$00
            sta   gotolnum
            sec
            ror   :loaded

:sfplp      rep   $30
            bit   :openflag
            bpl   :set
            jsl   prodos
            dw    $14
            adrl  :cparm
            stz   :openflag

:set        bit   :loaded
            bpl   :bit

            bit   :merlin
            bpl   :zero
            sep   $20
:tabson     ldx   #$07
]lup        lda   tabs1,x
            sta   tabs,x
            dex
            bpl   ]lup

:zero       sep   $30
            ldx   loadfilename
]lup        lda   loadfilename,x
            and   #$7f
            cmp   #'a'
            blt   :uc
            cmp   #'z'+1
            bge   :uc
            and   #$5f
:uc         sta   efilename,x
            dex
            bpl   ]lup
:bit        rep   $30
            bit   :toolarge
            bpl   :sfplp1
            jmp   :toolarge1
:sfplp1     jsr   erasebox
            lda   apwlen+2
            beq   :norm
            lda   #$ffff
            sta   flen
            sta   editlen
            jmp   :norm1
:norm       lda   apwlen
            sta   flen
            sta   editlen

:norm1      jsr   gotoline
            jsr   drawmem
            jsr   drawtabs
            jsr   drawfname
:cmdxit     plp
            clc
            rts
:err        rep   $30
            and   #$00ff
            jsr   doerror
            stz   :toolarge
            jmp   :sfplp
:toolarge1  lda   #toobigerr
            jmp   :err

:merlin     ds    2
:errcode    ds    2
:toolarge   ds    2
:loaded     ds    2
:openflag   ds    2
:flag       ds    2
:cparm      ds    2
:oparm      ds    2
            adrl  loadfilename
            adrl  $0000
:rparm      ds    2
:where      adrl  :databuff
:rin        adrl  $00
            adrl  $00
:info       adrl  loadfilename
            ds    2
:type       ds    2
:aux        ds    4
            ds    16
:eof        ds    6

:databuff   ds    512,0

:readtwo    php
            rep   $30
            lda   #$02
            sta   :rin
            stz   :rin+2
            jsr   :read
            bcs   :rsec
            lda   :databuff
            plp
            clc
            rts
:rsec       plp
            sec
            rts

:read       php
            rep   $30
            jsl   prodos
            dw    $12
            adrl  :rparm
            bcc   :rok
            jmp   :bad
* cmp #$4C
* jeq :bad
* jsl p8error
* bcc :read
* bra :bad
:rok        plp
            clc
            rts
:bad        plp
            sec
            rts

:dotext     php
            rep   $30
            tya                   ;Get Linerec Value
            and   #$00FF
            sta   :rin
            jsr   :read
            bcs   :txtbad
            sep   $30
            ldy   :databuff
            beq   :t4
:t1         lda   #$20
            jsr   :stuffit
            bcs   :tmem
            dey
            bne   :t1             ;Add Spaces
:t4         lda   :databuff+$1
            and   #$7F
            sta   :len
            ldy   #$00
:t2         cpy   :len
            beq   :t3
            lda   :databuff+$2,Y
            and   #$7F
            cmp   #$20
            blt   :t0
            jsr   :stuffit
            bcs   :tmem
:t0         iny
            bra   :t2
:t3         lda   :databuff+$1
            bpl   :txit
            lda   #$0D
            jsr   :stuffit
            bcs   :tmem
:txit       plp
            clc
            rts
:tmem       lda   #toobigerr
:txtbad     plp
            sec
            rts

:len        hex   0000

:docr       php
            tya                   ;Get LineRec Value
            sep   $30
            tay
            cpy   #$00
            beq   :cr2
:cr1        lda   #$20            ;SpaceChar
            jsr   :stuffit
            bcs   :memcr
            dey
            bne   :cr1
:cr2        lda   #$0D
            jsr   :stuffit
            bcs   :memcr1
            plp
            clc
            rts
:memcr      ply                   ;Remove counter
:memcr1     lda   #toobigerr
            plp
            sec
            rts


:stuffit    phy
            phx
            php
            rep   $30
            ldy   apwlen+2
            bne   :full
            ldy   apwlen
            cmp   #$ffff
            beq   :full
            sep   $20
            sta   [fileptr],y
            rep   $20
            inc   apwlen
            bne   :ok
            inc   apwlen+2
:ok         plp
            plx
            ply
            clc
            rts
:full       sec
            ror   :toolarge
            plp
            plx
            ply
            sec
            rts

apwlen      ds    4


saveapw     rep   $30
            lda   #$00
            sta   :mylen
            sta   :mylen+2
            sta   :openflag
            sta   :loaded

            lda   flen
            bne   :sapw
            clc
            jmp   :sapwout
:sapw       lda   loadfilename
            and   #$ff
            beq   :pd
            tax
            lda   loadfilename,x
            and   #$7f
            cmp   #'!'
            bne   :pd
            sep   $20
            dec   loadfilename
            rep   $20
:pd         jsl   prodos
            dw    $06
            adrl  :iparm
            bcs   :create
            lda   :ftype
            cmp   #$1A
            beq   :open
            lda   #$1A
            sta   :ftype
:q1         jsl   prodos
            dw    $05             ;set info
            adrl  :iparm
            bcc   :open
            jmp   :errout
:create     jsl   prodos
            dw    $01
            adrl  :crparm
            bcc   :open
            cmp   #$47
            beq   :open
            jmp   :errout
:open       jsl   prodos
            dw    $10
            adrl  :opnparm
            bcc   :o1
            jmp   :errout
:o1         lda   :opnparm
            sta   :wparm
            sta   :cparm
            sec
            ror   :openflag
            jsr   :write
            bcs   :errout
            jsl   prodos
            dw    $14
            adrl  :cparm
            stz   :openflag
            sec
            ror   :loaded
            clc
            jmp   :sapwout
:errout     rep   $30
            pha
            bit   :openflag
            bpl   :err1
            jsl   prodos
            dw    $14
            adrl  :cparm
            stz   :openflag
:err1       pla
            and   #$00ff
            jsr   doerror
            sec
            jmp   :sapwout

:sapwout    rep   $30

            bit   :loaded
            bpl   :sfplp

            stz   alldirty

            sep   $30
            ldx   loadfilename
]lup        lda   loadfilename,x
            and   #$7f
            cmp   #'a'
            blt   :uc
            cmp   #'z'+1
            bge   :uc
            and   #$5f
:uc         sta   efilename,x
            dex
            bpl   ]lup

            rep   $30

            jsr   drawfname

:sfplp      rep   $30
            jsr   erasebox
            sep   $30
            plp                   ;pull off processor placed by COMMANDS
            clc
            rts


:iparm      adrl  loadfilename
            dw    $00
:ftype      dw    $00
            ds    20,0
:crparm     adrl  loadfilename
            dw    $e3
            dw    $1a
            adrl  $0000
            dw    $01
            adrl  $00

:opnparm    dw    $00
            adrl  loadfilename
            adrl  $0000

:wparm      dw    $00
:buff       adrl  $0000
:ct         adrl  $0000
:trans      adrl  $0000

:cparm      dw    $00
:openflag   ds    2
:eofparm    ds    2
:eof        adrl  $0000

:smark      dw    $00
:pos        adrl  $12c

:mylen      ds    4
:loaded     ds    2

:write      rep   $30
            lda   #:header
            sta   :buff
            lda   #^:header
            sta   :buff+$2
            lda   #$12C
            sta   :ct
            lda   #$00
            sta   :done
            lda   :opnparm
            sta   :smark
            sta   :eofparm
:wrt        jsl   prodos
            dw    $13
            adrl  :wparm
            bcc   :l
            jmp   :werr
:l          lda   :done
            bne   :exit
            jsr   :gline
            rep   $30
            lda   :length
            and   #$00ff
            sta   :ct
            lda   #$00
            sta   :ct+$2
            lda   #:line
            sta   :buff
            lda   #^:line
            sta   :buff+$2
            jmp   :wrt
:exit       lda   #<:end
            sta   :buff
            lda   #^:end
            sta   :buff+$2
            lda   #$04
            sta   :ct
            lda   #$00
            sta   :ct+2
            jsl   prodos
            dw    $13
            adrl  :wparm
            bcc   :q2
            jmp   :werr
:q2         jsl   prodos
            dw    $17             ;getmark
            adrl  :smark
            bcc   :q3
            jmp   :werr
:q3         ldy   #$02
:e1         sep   $20
            lda   :pos,y
            sta   :eof,y
            dey
            bpl   :e1
            rep   $20
:q4         jsl   prodos
            dw    $18
            adrl  :eofparm
            bcc   :q5
            jmp   :werr
:q5         clc
            rts

:werr       sec
            rts

:header     hex   2e2200004f3d3d3d
            hex   3d3d7c3d3d3d3d7c
            hex   3d3d3d3d7c3d3d3d
            hex   3d7c3d3d3d3d7c3d
            hex   3d3d3d7c3d3d3d3d
            hex   7c3d3d3d3d7c3d3d
            hex   3d3d7c3d3d3d3d7c
            hex   3d3d3d3d7c3d3d3d
            hex   3d7c3d3d3d3d7c3d
            hex   3d3d3d7c3d3d3d3d
            hex   7c3d3d3d00002c22
            hex   02
            ds    211,0
:end        hex   00d0ffff


:gline      rep   $30
            lda   #$00
            sta   :line
            sta   :line+$2
            sta   :length
            sta   :glct
            sta   :spc
            sta   :tflag
            sta   :txt
            jmp   :main
:m1         sep   $30
            dec   :glct
:main       sep   $30
            lda   :glct
            cmp   #$50
            jeq   :glexit
            jsr   :gchar
            bcs   :glend
            and   #$7F
            sta   :char
            inc   :glct
            lda   :char
            cmp   #$0D
            beq   :cr
            cmp   #$20
            blt   :m1
            beq   :spc1
            inc   :tflag
:0          inc   :txt
            jmp   :1
:spc1       lda   :tflag
            bne   :0
            inc   :spc
:1          ldy   :txt
            dey
            lda   :char
            sta   :line1,y
            jmp   :main
:cr         lda   :tflag
            beq   :crrec
            lda   #$80
            bne   :2
:glexit     lda   #$00
:2          ora   :txt
            sta   :line+$3
            lda   :spc
            sta   :line+$2
            lda   #$00
            sta   :line+$1
            lda   :txt
            clc
            adc   #$02
            sta   :line
            adc   #$02
            sta   :length
            rts
:crrec      lda   :spc
            sta   :line
            lda   #$D0
            sta   :line+$1
            lda   #$02
            sta   :length
            rts
:glend      lda   #$01
            sta   :done
            jmp   :cr
            mx    %00


:gchar      php
            rep   $30
            ldy   :mylen
            lda   [fileptr],y
            and   #$ff
            iny
            beq   :gdone
            sty   :mylen
            cpy   flen
            bge   :gdone
            plp
            clc
            rts
:gdone      sec
            ror   :done
            plp
            sec
            rts

:glct       hex   0000
:tflag      hex   0000
:spc        hex   0000
:txt        hex   0000
:char       hex   0000

:done       hex   0000
:length     hex   0000
:line       hex   00000000
:line1      ds    275,0


gopos       rep   $30
            and   #$7f
            sec
            sbc   #$30
            dec
            sta   :temp
            pha
            pha
            lda   flen
            pha
            pea   $8              ;divide by 9
            tll   $0b0b
            pla
            plx
            pha
            pha
            pha
            lda   :temp
            pha
            tll   $090b
            pla
            sta   gotoposition
            pla
            jsr   gotopos
            stz   gotoposition
            jsr   getbuff
            jsr   drawline
            stz   pos
            jsr   poscurs
:cmdxit     sep   $30
            plp
            clc
            rts
:temp       ds    2

drawstr                           ;ent
            php
            phb
            phk
            plb
            phd
            rep   $30
            pha
            phx
            phy
            tsc
            tcd
            lda   [14]
            and   #$00FF
            sta   :len
            beq   :xit
            phy
            ldy   #$01
]lup        cpy   :len
            blt   :next
            beq   :next
            bra   :xit1
:next       lda   [14],y
            and   #$7F
            phy
            jsl   drawchar
            ply
            iny
            bra   ]lup
:xit1       ply
:xit        ldx   #12
]lup        lda   $00,X
            sta   $04,X
            dex
            dex
            bne   ]lup
            tsc
            clc
            adc   #$04
            tcs
            ply
            plx
            pla
            pld
            plb
            plp
            rtl
:len        ds    2

drawchar                          ;ent
            phx
            php
            rep   $30
            and   #$7F
            cmp   #$0D
            beq   :cr
            pha
            tll   $180C
            sep   $20
            lda   tcursx
            inc
            sta   tcursx
            lda   tcursx
            cmp   #80
            blt   :xit
:cr1        rep   $30
            lda   #$00
            sta   tcursx
            lda   tcursy
            inc
            cmp   #24
            blt   :st
            lda   #23
:st         sta   tcursy
:xit        plp
            plx
            rtl
            mx    %00
:cr         pha
            tll   $180C
            pea   $0A
            tll   $180C
            jmp   :cr1

ffeed       rtl


printdec                          ;ent
            php
            phb
            phd
            phk
            plb
            rep   $30
            stz   :first
            tsc
            tcd
            lda   $08
            sta   :flags
            lda   [$0A]
            ldx   #$00
]lup        cmp   #10000
            blt   :thous
            inx
            sec
            sbc   #10000
            jmp   ]lup
:thous      sta   :number
            txa
            clc
            adc   #$30
            jsr   :draw
            ldx   #$00
            lda   :number
]lup        cmp   #1000
            blt   :hun
            inx
            sec
            sbc   #1000
            jmp   ]lup
:hun        sta   :number
            txa
            clc
            adc   #$30
            jsr   :draw
            ldx   #$00
            lda   :number
]lup        cmp   #100
            blt   :ten
            inx
            sec
            sbc   #100
            jmp   ]lup
:ten        sta   :number
            txa
            clc
            adc   #$30
            jsr   :draw
            ldx   #$00
            lda   :number
]lup        cmp   #10
            blt   :one
            inx
            sec
            sbc   #10
            jmp   ]lup
:one        sta   :number
            txa
            clc
            adc   #$30
            jsr   :draw
            sec
            ror   :first
            lda   :number
            clc
            adc   #$30
            jsr   :draw
:xit        ldx   #$06
]lup        lda   0,x
            sta   6,x
            dex
            dex
            bpl   ]lup
            rep   $30
            tsc
            clc
            adc   #6
            tcs
            pld
            plb
            plp
            rtl

:draw       cmp   #'0'
            beq   :zero
            jsl   drawchar
            sec
            ror   :first
            rts
:zero       bit   :first
            bmi   :zeroout
            bit   :flags
            bpl   :rts
            bvs   :zeroout
            lda   #$20
:zeroout    jsl   drawchar
:rts        rts

:number     ds    2
:flags      ds    2
:first      ds    2

tprbytel                          ;ent
            php
            phb
            phk
            plb
            rep   $30
            sta   :byte
            xba
            jsl   prbyte
            lda   :byte
            jsl   prbyte
            plb
            plp
            rtl
:byte       ds    2

prbyte                            ;ent
            pha
            phy
            phx
            php
            phb
            phk
            plb
            rep   $30
            pha
            lsr
            lsr
            lsr
            lsr
            and   #$0F
            jsr   :nib
            pla
            and   #$F
            jsr   :nib
            plb
            plp
            plx
            ply
            pla
            rtl
:nib        ora   #"0"
            cmp   #"9"+1
            blt   :ok
            adc   #"A"-"9"-2
:ok         and   #$7F
            jsl   drawchar
            rts

