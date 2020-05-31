             ;use   ../macs/intcmd.macs.s
                  ;use   ../macs/tool.macs.s
             ;use   ../macs/qatools.macs.s

asm          php
             rep   $30
             sty   filehandle+2
             stx   filehandle
             pea   0
             _QAKeyAvail
             pla
             beq   :k
             pha
             _QAGetChar
             pla
:k
             stz   errorct
             stz   keyflag

:getlen      pha
             pha
             psl   filehandle
             _GetHandleSize
             plx
             ply
             jcs   :incerr
             cpx   #$00
             bne   :dec1
             dey
:dec1        dex

:nodec       stx   filelen
             sty   filelen+2

             ldy   #$04
             lda   [filehandle],y
             and   #$7fff                              ;
             sta   [filehandle],y

             jsr   getmemory
             jcs   :incerr

             jsr   initasm

             lda   #linebuff+1
             sta   lineptr
             lda   #^linebuff
             sta   lineptr+2

:dopass      rep   $30
             ldy   #$04
             lda   [filehandle],y
             ora   #$8000
             sta   [filehandle],y

             ldy   #$02
             lda   [filehandle]
             sta   fileptr
             lda   [filehandle],y
             sta   fileptr+$2
             lda   filelen
             sta   flen
             lda   filelen+$2
             sta   flen+$2

             lda   flen
             ora   flen+$2
             bne   :init
             jmp   :alldone                            ;if file is 0 bytes

:init        jsr   initpass

:lineloop
             rep   $30
             pea   0
             _QAKeyAvail
             pla
             beq   :nokey
             jsr   dokeypress

:nokey       sep   $20
             lda   passnum
             beq   :l2

             lda   objfull
             beq   :l1
             lda   #objectfull
             jmp   :perr1
:l1          lda   reloffset+2
             beq   :l2
             lda   #relflag
             bit   modeflag
             beq   :l2
             lda   #relfilefull
             jmp   :perr1
:l2          lda   prodoserr
             beq   :l3
             lda   #doserror
             jmp   :perr1

:l3          lda   #$01
             trb   macflag

             lda   putuse
             beq   :doline
             tsb   modeflag
             stz   putuse
             rep   $20
             stz   linenum
             sep   $20

:doline      lda   doneflag
             beq   :line
             jmp   :donepass

:line        rep   $30
             stz   opcode
             stz   linebuff
             stz   labstr
             stz   linelabtxt
             stz   comment
             stz   linehaslab

             lda   #$2020
             sta   opcode+1
             sta   opcode+3
             sta   opcode+5

             lda   #$ffff
             sta   linelable

:test        sep   $30
             lda   macflag
             bpl   :sep                                ;mac working?
             bit   #%00100000
             bne   :int
             bit   #%01000000
             beq   :sep
:ext         jsr   expandmac
             jcs   :perr1                              ;there was an error expanding
             jmp   :macentry
:int         jsr   expandint
             jcs   :perr1
             jmp   :macentry

:sep         rep   $30
             lda   lastlen
             clc
             adc   fileptr
             sta   fileptr
             bcc   :i1
             inc   fileptr+2
:i1          lda   flen
             sec
             sbc   lastlen
             sta   flen
             bcs   :test0
:dec         dec   flen+2
             bpl   :readline
:setflag     lda   #$ffff
             sta   doneflag
             jmp   :done
:test0       bne   :readline
             lda   flen+2
             beq   :setflag
:readline
             rep   $30                                 ;increment the line counter
             inc   linenum
;do tests here.....

             rep   $30
             lda   fileptr
             sta   printptr
             lda   fileptr+2
             sta   printptr+2

             sep   $30
             ldy   #$00

             lda   [fileptr]
             tax
             lda   inputtbl,x
             cmp   #' '
             blt   :sjmp                               ;to savlen =>
             beq   :getopcode
             cmp   #'*'
             beq   :c
             cmp   #';'
             beq   :c
             jmp   :glabel
:c           jmp   :comment

:glabel      sta   labstr+1
             sta   linehaslab
             ldx   #$01
:gliny       iny
             lda   [fileptr],y
             phx
             tax
             lda   inputtbl,x
             plx
             cmp   #' '+1
             blt   :glabdone
:cpx         cpx   #lab_size
             bge   :gliny
             sta   labstr+1,x
             inx
             jmp   :gliny

:sjmp        jmp   :savlen
:cjmp        jmp   :comment

:glabdone    cpx   #lab_size+1
             blt   :gl2
             ldx   #lab_size
:gl2         stx   labstr
             cmp   #' '
             blt   :sjmp

:getopcode
:giny        iny
             lda   [fileptr],y
             tax
             lda   inputtbl,x
             cmp   #' '
             blt   :sjmp
             beq   :giny
             cmp   #';'
             beq   :cjmp

             sta   opcode+1

             ldx   #$01
:goiny       iny
             lda   [fileptr],y
             phx
             tax
             lda   inputtbl,x
             plx
             cmp   #' '+1
             blt   :godone
             cpx   #31
             bge   :goiny
             sta   opcode+1,x
             inx
             jmp   :goiny

:godone      cpx   #32
             blt   :go2
             ldx   #31
:go2         stx   opcode
             cmp   #' '
             blt   :sjmp

:getoperand
:giny1       iny
             lda   [fileptr],y
             tax
             lda   inputtbl,x
             cmp   #' '
             blt   :sjmp
             beq   :giny1
             cmp   #';'
             beq   :comment


             ldx   #$00
             phx
             dey
:goiny1      iny
             lda   [fileptr],y
             phx
             tax
             lda   inputtbl,x
             plx
             cmp   #' '                                ;read in the rest of the line
             blt   :gotoper
             beq   :chklit
             cmp   #$27
             beq   :lit
             cmp   #$22
             beq   :lit
             jmp   :cpx1
:chklit      xba
             lda   1,s
             bne   :xba
             xba
             jmp   :gotoper
:lit         cmp   1,s
             beq   :litoff
             xba
             lda   1,s
             beq   :s
             jmp   :xba
:s           xba
             sta   1,s
             jmp   :cpx1
:litoff      xba
             lda   #$00
             sta   1,s
:xba         xba
:cpx1        cpx   #128
             bge   :goiny1
             sta   linebuff+1,x
             inx
             jmp   :goiny1

:gotoper     cpx   #128
             blt   :go3
             ldx   #128
:go3         stx   linebuff
             xba
             pla
             xba
             cmp   #' '
             blt   :savlen                             ;should always be taken...
             bne   :comment

:comment     ldx   passnum                             ;only read the comment on pass 2
             bne   :cp1
:cp0         iny
             lda   [fileptr],y
             tax
             lda   inputtbl,x
             cmp   #' '
             bge   :cp0
             jmp   :savlen
             bra   :cp0
:cp1         ldx   #$00
:cf1         lda   [fileptr],y
             phx
             tax
             lda   inputtbl,x
             plx
             cmp   #' '
             blt   :savcom
             bne   :c2
             iny
             bra   :cf1
:c2          lda   [fileptr],y
             phx
             tax
             lda   inputtbl,x
             plx
             cmp   #' '
             blt   :savcom
             iny
             cpx   #128
             bge   :c2
             sta   comment+1,x
             inx
             bra   :c2
:savcom      stx   comment

:savlen      iny
             sty   lastlen
             ldx   linebuff
             lda   #$0d
             sta   linebuff+1,x
             inc   linebuff

:macentry    sep   $30
             lda   labstr                              ;was there a lable or
             ora   opcode                              ;an opcode?
             bne   :process
             jsr   initline
             clc
             jmp   :printline                          ;nothing to process so just
                                                       ;list the line if necessary

:process
             jsr   initline
             lda   passnum
             beq   :al
             lda   #controld
             bit   keyflag
             beq   :al
             trb   keyflag
             lda   listflag
             and   #$80
             sta   oldlstflag
             lda   listflag
             eor   #$80
             sta   listflag
:al          jsr   asmline                             ;go process line
             bcc   :printline
             jmp   :perr
:perr1       rep   $30
             and   #$FF
:perr        rep   $30
             pha
             lda   #$0d
             jsr   drawchar
             lda   1,s
             jsr   asmerror

             lda   passnum
             beq   :perrpla

             lda   listflag
             pha
             ora   #$8080
             and   #%00011101_00011101!$FFFF
             sta   listflag
             jsr   printline
             pla
             and   #$7fff                              ;clear line list flag
             sta   listflag
             lda   #$0d
             jsr   drawchar
:perrpla     pla
             and   #$80
             beq   :printline
             jmp   :alldone

:printline
             sep   $20
             do    1
             lda   passnum
             beq   :nopr
             lda   listflag+1
             bpl   :nopr
             bit   #lstdoon
             beq   :printmac
             lda   dolevel
             ora   dolevel+1
             bne   :nopr
             else
             ldal  $e0c061
             bpl   :nopr
             jmp   :print
             fin
:printmac    lda   macflag
             bit   #%01100000
             beq   :print                              ;no macros expanding
             lda   modeflag+1
             bit   #expflag
             bne   :print
             lda   macflag
             bit   #%00000001
             beq   :nopr
:print       jsr   printline
:nopr        jmp   :lineloop

:done        sep   $30
             lda   modeflag
             and   #putflag.useflag
             beq   :donepass
             jsr   putuseend
             lda   doneflag
             bne   :donepass
             jmp   :lineloop

:donepass    rep   $30
             lda   #cancelflag
             bit   keyflag
             bne   :pn

             lda   macflag
             and   #$80                                ;is a macro still in progress?
             beq   :pn
             lda   #$0d
             jsr   drawchar
             lda   #badmacro
             jsr   asmerror
             lda   #$00
             jmp   :asmerrout

:pn          lda   passnum
             bne   :alldone
             lda   #$FFFF
             sta   passnum

             jmp   :dopass                             ;go do next pass

:alldone     sep   $30
             stz   prodoserr
             stz   prodoserr+1
             jsr   closedsk
             bcc   :nderr
             rep   $30
             pha
             _QAIncTotalErrs
             pla
             jsr   dskerror
:nderr       rep   $30
             pea   0
             _QAGetTotalErrs
             pla
             sta   errorct
             sep   $30
             lda   #cancelflag
             and   keyflag
             ora   errorct
             ora   errorct+1
             bne   :ad0
             bit   listflag
             bpl   :ad0
             lda   #symflag
             bit   modeflag1
             beq   :ad0
:symbols     jsr   drawlables
:ad0         rep   $30
             lda   #$00
:incerr
:asmerrout   rep   $30
             sta   :errcode
             jsr   showendstr
             jsr   disposemem
             lda   #cancelflag
             and   keyflag
             tay

             lda   :errcode
             plp
             cmpl  :one
             rtl
:one         dw    $01
:errcode     ds    2
:symstr      str   0d,'Print Symbol Table?',06




showendstr   php
             rep   $30
             lda   #cancelflag
             bit   keyflag
             jne   :cr
             psl   #:str1
             _QADrawString

             psl   totbytes
             pea   0
             pea   0
             _QADrawDec

             psl   #:str2
             _QADrawString
             pea   0
             lda   errorct
             pha
             pea   0
             pea   0
             _QADrawDec

             psl   #:str3
             _QADrawString

             pea   0
             lda   totallines
             pha
             pea   0
             pea   0
             _QADrawDec

             psl   #:str4
             _QADrawString

             pea   0
             lda   globalct
             pha
             pea   0
             pea   0
             _QADrawDec

             psl   #:str5
             _QADrawString
             jsr   calctime

:plp         plp
             rts
:cr          lda   #$0d
             jsr   drawchar
             jmp   :plp

:str1        str   0d,'End of QuickASM assembly. '
:str2        str   ' bytes, '
:str3        str   ' errors, '
:str4        str   ' lines, '
:str5        str   ' symbols.',0d,0d


calctime     php
             rep   $30
             pha
             pha
             pha
             _QAEndTiming
             pla
             sta   :hours
             pla
             sta   :minutes
             pla
             sta   :seconds
             stz   :flag

             psl   #:str1
             _QADrawString
             lda   :hours
             beq   :mins
             pea   0
             pha
             pea   0
             pea   0
             _QADrawDec
             psl   #:str2
             _QADrawString

             lda   :hours
             jsr   :plural
             inc   :flag

:mins        lda   :minutes
             beq   :secs
             lda   :flag
             beq   :m1
             jsr   :spc
:m1          pea   0
             lda   :minutes
             pha
             pea   0
             pea   0
             _QADrawDec
             psl   #:str3
             _QADrawString
             lda   :minutes
             jsr   :plural
             inc   :flag
:secs        lda   :flag
             beq   :s0
             lda   :seconds
             beq   :end
             jsr   :spc
             jmp   :s1
:s0          lda   :seconds
             bne   :s1
             lda   #'<'
             jsr   drawchar
             lda   #$20
             jsr   drawchar
             inc   :seconds
:s1          pea   0
             lda   :seconds
             pha
             pea   0
             pea   0
             _QADrawDec
             psl   #:str4
             _QADrawString
             lda   :seconds
             jsr   :plural
:end         lda   #'.'
             jsr   drawchar
             lda   #$0d
             jsr   drawchar
             jsr   drawchar
             plp
             rts
:plural      php
             rep   $30
             cmp   #$01
             beq   :c
             lda   #'s'
             jsr   drawchar
:c           plp
             rts
:spc         php
             rep   $30
             lda   #','
             jsr   drawchar
             lda   #' '
             jsr   drawchar
             plp
             rts

:flag        ds    2
:hours       ds    2
:minutes     ds    2
:seconds     ds    2
:str1        str   'Elapsed time = '
:str2        str   ' hour'
:str3        str   ' minute'
:str4        str   ' second'


numbytes     =     8

printline    php
             sep   $30
             stz   :objoutflag
             stz   :objoutflag+1

             lda   listflag+1
             bit   #%00000100
             jne   :equate

             lda   #dumflag
             bit   modeflag
             jne   :noobjcode

             lda   #%00000001
             bit   macflag
             bne   :objptr
             bit   listflag+1
             jeq   :noobjcode

:objptr      lda   listflag+1
             bit   #%00100000
             bne   :tradr
             lda   lineobjptr+2
             jsr   prbyte
:tradr       rep   $30
             lda   lineobjptr
             jsr   prbytel
             sep   $30
             lda   #':'
             jsr   drawchar
             lda   #' '
             jsr   drawchar

:noobjptr
             rep   $10

             ldy   #$00
             ldx   bytesout
             beq   :noobjcode
             stx   :objoutflag
             bmi   :group1
             cpx   #$05
             blt   :objloop
             ldx   #$04
:objloop     lda   bytesout+2,y
             jsr   prbyte
             cpx   #$01
             beq   :plx0
             lda   #' '
             jsr   drawchar
:plx0        iny
             dex
             bne   :objloop
             rep   $20
             lda   bytesout
             sec
             sbc   #$04
             bcs   :s1
             lda   #$00
:s1          sta   bytesout
             jmp   :noobjcode

:group1      rep   $30
             txa
             and   #$7fff
             tax
             sep   $20
             cpx   #$05
             blt   :objloop1
             ldx   #$04
:objloop1    lda   bytesout+2
             phx
             jsr   prbyte
             lda   1,s
             cmp   #$01
             beq   :plx1
             lda   #' '
             jsr   drawchar
:plx1        plx
             dex
             bne   :objloop1
             rep   $30
             lda   bytesout
             and   #$7fff
             sec
             sbc   #$04
             beq   :z
             bcs   :or
:z           stz   bytesout
             jmp   :noobjcode
:or          ora   #$8000
             sta   bytesout
             jmp   :noobjcode


:noobjcode   sep   $30
             lda   listflag+1
             bit   #branchlst
             bne   :branch
             jmp   :line

:branch
* rep $30
* pea #14
* _QATabToCol
             sep   $30
             lda   #'='
             jsr   drawchar
             lda   bytesout+3
             bpl   :bpos
             rep   $30
             ora   #$FF00
             jmp   :bpha
:bpos        rep   $30
             and   #$ff
:bpha        pha
             lda   lineobjptr
             clc
             adc   #$02
             clc
             adc   1,s
             plx
             jsr   prbytel
             jmp   :line

:equate      rep   $30
             pea   #12
             _QATabToCol
             sep   $30
             lda   #'='
             jsr   drawchar
             lda   equateval+2
             beq   :eq1
             jsr   prbyte
:eq1         lda   equateval+1
             beq   :eq2
             jsr   prbyte
:eq2         lda   equateval
             jsr   prbyte

:line        rep   $30
             pea   #20                                 ;pos of line number
             _QATabToCol
             sep   $30
             lda   modeflag
             bit   #putflag.useflag
             bne   :file
             lda   #' '
             jsr   drawchar
             jmp   :l1
:file        lda   #'>'
             jsr   drawchar
:l1          rep   $30
             pea   0
             lda   linenum
             pha
             pea   0
             pea   0
             _QADrawDec
             lda   #' '
             jsr   drawchar
* rep $30
* lda tabs
* and #$ff
* pha
* _QATabToCol
:sp2         sep   $30
             lda   [printptr]
             and   #$7f
             cmp   #' '
             jlt   :xit
             beq   :opcode
             cmp   #';'
             beq   :comment
             cmp   #'*'
             jeq   :comment1
             ldy   #$00
]lup         lda   [printptr],y
             and   #$7f
             cmp   #' '+1
             blt   :opcode
             jsr   drawchar
             iny
             jmp   ]lup
:opcode      rep   $30
             lda   tabs+1
             and   #$ff
             pha
             _QATabToCol
             psl   #opcode
             _WriteString
             lda   tabs+2
             and   #$ff
             pha
             _QATabToCol
             sep   $20
             lda   linebuff
             beq   :comment
             dec   linebuff
             rep   $20
             psl   #linebuff
             _WriteString
:comment     rep   $30
             lda   tabs+3
             and   #$ff
             pha
             _QATabToCol
:comment1    rep   $30
             psl   #comment
             _WriteString
:xit         rep   $30
             jsr   printcycles
             lda   #$0d
             jsr   drawchar
             jsr   checkpause

:trunc       rep   $30
             lda   passnum
             jeq   :plp
             lda   :objoutflag
             jeq   :plp
             lda   bytesout
             jeq   :plp
             lda   listflag+1
             bit   #%00000010
             jne   :plp
             bit   #%00000001
             jeq   :plp
             lda   #$ffff
             sta   :crout
             lda   lineobjptr
             clc
             adc   #$04
             sta   lineobjptr
             bcc   :t0
             inc   lineobjptr+2
:t0          lda   bytesout
             jmi   :group2
             lda   #$06
             sta   :pos
             jmp   :t2
:t1          rep   $30
             lda   lineobjptr
             clc
             adc   #numbytes
             sta   lineobjptr
             bcc   :t2
             inc   lineobjptr+2
:t2          lda   bytesout
             jeq   :tcrout
             sep   $30
             lda   listflag+1
             bit   #%00100000
             bne   :tradr1
             lda   lineobjptr+2
             jsr   prbyte
:tradr1      rep   $30
             lda   lineobjptr
             jsr   prbytel
             sep   $30
             lda   #':'
             jsr   drawchar
             lda   #' '
             jsr   drawchar
             ldx   #$00
:tlup        lda   bytesout
             jeq   :tcrout
             cpx   #numbytes
             bge   :tcr
             ldy   :pos
             lda   bytesout,y
             jsr   prbyte
             lda   #$20
             jsr   drawchar
             inx
             inc   :pos
             dec   bytesout
             stz   :crout
             jmp   :tlup
:tcr         lda   #$0d
             jsr   drawchar
             lda   #$ffff
             sta   :crout
             jsr   checkpause
             jmp   :t1
:tcrout      lda   :crout
             bne   :tc
             lda   #$0d
             jsr   drawchar
             jsr   checkpause
:tc          jmp   :plp

:group2      rep   $30
             lda   bytesout
             and   #$7fff
             sta   bytesout
             lda   #$ffff
             sta   :crout
             jmp   :t21
:t11         rep   $30
             lda   lineobjptr
             clc
             adc   #numbytes
             sta   lineobjptr
             bcc   :t21
             inc   lineobjptr+2
:t21         lda   bytesout
             beq   :tcr12
             sep   $30
             lda   listflag+1
             bit   #%00100000
             bne   :tradr11
             lda   lineobjptr+2
             jsr   prbyte
:tradr11     rep   $30
             lda   lineobjptr
             jsr   prbytel
             sep   $30
             lda   #':'
             jsr   drawchar
             lda   #' '
             jsr   drawchar
:tlup1       rep   $30
             ldx   #$00
:tlup12      lda   bytesout
             beq   :tcr12
             cpx   #numbytes
             bge   :tcr1
             lda   bytesout+2
             phx
             jsr   prbyte
             lda   #$20
             jsr   drawchar
             stz   :crout
             plx
             inx
             dec   bytesout
             jmp   :tlup12
:tcr1        lda   #$0d
             jsr   drawchar
             lda   #$ffff
             sta   :crout
             jmp   :t11
:tcr12       bit   :crout
             bmi   :plp
             lda   #$0d
             jsr   drawchar
:plp         plp
             rts
:pos         ds    2
:crout       ds    2
:objoutflag  ds    2


printcycles  php
             sep   $30
             lda   #cycflag
             bit   modeflag+1
             bne   :show
:xit         plp
             rts
:show        lda   linecycles
             beq   :xit
             rep   $30
             pea   #71                                 ;column for cycle count
             _QATabToCol
             sep   $30
             lda   #$20
             jsr   drawchar
             lda   linecycles
             and   #$0f
             ora   #$30
             jsr   drawchar
             lda   #' '
             ldy   cyclemarks
             beq   :d1
             cpy   #$02
             bge   :2
             lda   #$27
             jmp   :d1
:2           lda   #$22
:d1          jsr   drawchar
             lda   #','
             jsr   drawchar

             bit   cycflags
             bmi   :mx
             rep   $30
             lda   cycles
             jsr   prbytel
             jmp   :xit

             mx    %11
:mx          bit   mxflag
             bmi   :m1
             bvc   :m0x0
             lda   #$01
             jsr   prbyte
             jmp   :xit
:m0x0        lda   #$00
             jsr   prbyte
             jmp   :xit
:m1          bvc   :m1x0
             lda   #$11
             jsr   prbyte
             jmp   :xit
:m1x0        lda   #$10
             jsr   prbyte
             jmp   :xit


dokeypress   php
             rep   $30
             pea   0
             _QAKeyAvail
             pla
             beq   :clc
             pha
             _QAGetChar
             pla
             sep   $20
             and   #$7f
             xba
             sta   keymod
             xba
             cmp   #$20
             bne   :nopause
:pause       lda   #pauseflag
             tsb   keyflag
             sep   $20
             jmp   :sec
:nopause     cmp   #$1b
             beq   :cancel
             cmp   #'C'&$9f
             bne   :list
:cancel      lda   #$ff
             sta   doneflag
             sta   doneflag+1
             sta   passnum
             sta   passnum+1
             lda   #putflag.useflag
             trb   modeflag
             lda   #cancelflag
             tsb   keyflag

             rep   $30
             phx
             pea   $FFFF
             _QASetCancelFlag
             plx
             sep   $30
             jmp   :sec

:list        cmp   #'D'&$9f
             bne   :sec
             lda   #controld
             tsb   keyflag
* sta keyflag
             jmp   :sec
:clc         plp
             clc
             rts
:sec         plp
             sec
             rts

keymod       ds    2

checkpause   php
             rep   $30
             lda   #pauseflag
             bit   keyflag
             beq   :perrpla
             trb   keyflag
             lda   #cancelflag
             bit   keyflag
             bne   :perrpla
:kl1         jsr   dokeypress
             bcc   :kl1
:perrpla     plp
             rts



getmemory
             php
             rep   $30
             stz   :purgeflag
             stz   lableptr
             stz   lableptr+$2
             stz   lableptr1
             stz   lableptr1+$2
             stz   nextlableptr
             stz   nextlableptr+2
             stz   objhdl
             stz   objhdl+$2
             stz   objzpptr
             stz   objzpptr+$2
             stz   relptr
             stz   relptr+$2
             stz   macptr
             stz   macptr+2
             lda   #initobjsize
             sta   objsize


             pea   0
             _QALinkerActive
             pla
             jeq   :normal

             psl   #$00
             psl   #$00
             pea   0
             psl   #$00
             _QAGetSymTable
             pll   nextlableptr
             pla
             sta   lablect
             pll   linksymhdl
             pll   linksymtbl

             lda   linksymhdl
             ora   linksymhdl+2
             jeq   :normal
             lda   linksymtbl
             ora   linksymtbl+2
             jeq   :normal

             ldy   #$00
]lup         lda   [linksymtbl],y
             sta   atable,y
             iny
             iny
             cpy   #128*2
             blt   ]lup

             lda   linksymhdl
             sta   workspace
             lda   linksymhdl+2
             sta   workspace+2
             ldy   #$02
             lda   [workspace]
             tax
             lda   [workspace],y
             sta   lableptr1+2
             stx   lableptr1
             jmp   :all

:normal      rep   $30
             lda   #$ffff
             sta   lablect                             ;so memory is allocated
             jsr   inclablect
             bcc   :symok
             plp
             sec
             rts

:symok       rep   $30
             ldx   #$00
             lda   #$FFFF
]lup         sta   atable,x
             inx
             inx
             cpx   #128*2
             blt   ]lup

:m1          psl   #$00
             psl   #maxsymbols*4
             lda   userid
             ora   #asmmemid
             pha
             pea   $8000                               ;locked page aligned
             psl   #$00
             _NewHandle
             plx
             ply
             bcc   :m1out
             jsr   :purge
             bcc   :m1
             jmp   :err
:m1out
             stx   workspace
             sty   workspace+2
             ldy   #$02
             lda   [workspace]
             sta   lableptr1
             lda   [workspace],y
             and   #$00FF
             sta   lableptr1+$2

             rep   $30
             lda   #$0000
             tay
]lup         sta   [lableptr1],y
             iny
             iny
             cpy   #maxsymbols*4
             blt   ]lup

:all         rep   $30
:g1          psl   #$00
             psl   #initobjsize+1
             lda   userid
             ora   #asmmemid
             pha
             pea   $8000                               ;locked page aligned no bank cross
             psl   #$00
             _NewHandle
             plx
             ply
             bcc   :m2out
             jsr   :purge
             bcc   :g1
             jmp   :err
:m2out
             jcs   :xit
             stx   objhdl
             stx   workspace
             sty   objhdl+2
             sty   workspace+2
             ldy   #$02
             lda   [workspace]
             sta   objzpptr
             lda   [workspace],y
             sta   objzpptr+$2
             lda   #$0000
             ldy   #$0000
]lup         sta   [objzpptr],y
             iny
             iny
             beq   :next
             cpy   objsize
             blt   ]lup
:next        rep   $30
             psl   #$00
             psl   #macsize
             lda   userid
             ora   #asmmemid
             pha
             pea   $8000
             psl   #$00
             _NewHandle
             plx
             ply
             bcc   :m3out
             jsr   :purge
             bcc   :next
             jmp   :err
:m3out
             stx   macptr
             sty   macptr+2
             ldy   #02
             lda   [macptr]
             tax
             lda   [macptr],y
             sta   macptr+2
             stx   macptr
             stz   macvarptr

             lda   #$00

:xit         rep   $30
:err
             plp
             cmp   :one
             rts
:one         dw    $01
:purgeflag   ds    2

:purge       bit   :purgeflag
             bmi   :psec
             jmp   :psec
             sec
             ror   :purgeflag
             pea   $00
             _PurgeAll
             _CompactMem
             clc
             rts
:psec        sec
             rts

disposemem   php
             rep   $30
             ldal  userid
             ora   #memid
             pha
             _DisposeAll
             ldal  userid
             ora   #putid
             pha
             _DisposeAll
             ldal  userid
             ora   #useid
             pha
             _DisposeAll
             plp
             rts

initasm      php
             rep   $30
             stz   rellabct
             _QAInitTotalErrs

             psl   #$00
             pea   #vtoolmacs
             _QAGetVector
             pll   extmacptr

             pea   0
             _QALinkerActive
             pla
             beq   :norm
             lda   lablect
             sta   globalct
             bra   :all
:norm        stz   globalct
:all         stz   keyflag
             stz   passnum
             stz   extcount
             stz   entcount
             stz   totallines
             stz   maclocal
             stz   macvarptr
             stz   prodoserr
             stz   errorct
             stz   dskopen
             stz   dskwrite
             stz   dskeofparm
             stz   dskpath
             stz   dskclose
             stz   objfull
             stz   titlestr
             lda   #$06
             sta   objtype

             ldx   #$0000
]lup         stz   putbuffer,x
             stz   usebuffer,x
             inx
             inx
             cpx   #maxput*16
             blt   ]lup

             ldx   #$0000
]lup         stz   lupbuffer,x
             inx
             inx
             cpx   #maxlup*16
             blt   ]lup

             _QAStartTiming

             jsr   randomize

             plp
             rts
:s           ds    2

initpass     php
             sep   $30
             stz   encval
             stz   putuse
             stz   macflag
             stz   checksum
             stz   crc16
             stz   crc16+1
             stz   cycflags

             lda   #$FF
             sta   tbxand
             lda   #%11000000                          ;full native mode
             sta   xcflag
             stz   mxflag

             rep   $30

             do    oldshell
             ldx   goffset
             lda   idactive,x
             bit   #linkflag
             beq   :nolink
             else
             jmp   :nolink
             fin

             do    oldshell
             lda   linklstflag,x
             sep   $30
             and   #%10000000
             ora   #%01000000
             jmp   :linkent
             fin

:nolink      sep   $30
             lda   #%11000000
:linkent     sta   listflag                            ;both list and lstdo ON
             lda   #controld
             and   keyflag
             eor   listflag
             sta   listflag
             lda   #controld
             trb   keyflag

             rep   $30
             lda   passnum
             beq   :p1mode
             lda   #dskflag!$FFFF
             trb   modeflag
             jmp   :p2mode
:p1mode      stz   modeflag
:p2mode      lda   #expflag*256.caseflag
             tsb   modeflag
             stz   modeflag1

             stz   doneflag
             stz   dolevel
             stz   maclevel
             stz   putlevel
             stz   uselevel
             stz   linenum
             stz   domask

             stz   cycles
             stz   linecycles
             stz   cyclemarks
             stz   cycleavg


             lda   #$ffff
             sta   globlab
             sta   oldglob

             stz   dumor                               ;force to absolute

             lda   #$8000
             sta   orgor
             sta   objptr
             sta   orgval
             sta   oldobj
             stz   objptr+2
             stz   orgval+2
             stz   oldobj+2
             stz   objct
             stz   objoffset
             stz   objoffset+2
             stz   oldoffset
             stz   oldoffset+2
             stz   reloffset
             stz   reloffset+2
             stz   totbytes
             stz   totbytes+2
             stz   doneflag
             stz   lastlen
             stz   dsfill
             stz   dsoffset
             stz   errvalid
             stz   erraddress
             stz   erraddress+2
             stz   luplevel
             plp
             rts

initline     php
             lda   passnum
             bne   :pass2
:pass1       rep   $30
             lda   #$FFFF
             sep   $30

             rep   $30

:jmp         jmp   :all
:pass2       sep   $30
             lda   listflag
             sta   listflag+1
             rep   $30
             stz   bytesout

             stz   relout
             lda   reloffset
             sta   linerel
             inc   totallines
             stz   linecycles
             stz   cyclemarks

:all         rep   $30
             lda   #$FFFF
             sep   $30
             stz   clrglob
             stz   forcelong
             sta   notfound
             rep   $30
             stz   opflags
             stz   merrcode
             sta   fllast
             sta   lableused
             lda   objptr
             sta   lineobjptr
             sta   pcobjptr
             lda   objptr+2
             sta   lineobjptr+2
             sta   pcobjptr+2

:xit         plp
             rts

inclablect   php
             rep   $30
             inc   lablect
             lda   lablect
             and   #%11111111
             bne   :normal
             psl   #$00
             psl   #sym_size*256
             lda   userid
             ora   #asmmemid
             pha
             pea   $8014                               ;page aligned/locked/nocross
             psl   #$00
             _NewHandle
             plx
             ply
             jcs   :sec
             sei
             pei   0
             pei   2
             stx   0
             sty   2
             ldy   #$02
             lda   [0]
             sta   nextlableptr
             lda   [0],y
             sta   nextlableptr+2
             pla
             sta   2
             pla
             sta   0
             jmp   :rts
:normal      lda   nextlableptr
             clc
             adc   #sym_size
             sta   nextlableptr
             bcc   :rts
             inc   nextlableptr+2
:rts         plp
             clc
             rts
:sec         lda   #symfull
             plp
             sec
             rts


asmline
             php
             sep   $30
             lda   macflag
             bpl   :asmline
             and   #$7e
             bne   :asmline
             jsr   definemacro
             bcs   :s
             plp
             clc
             rts
:s           plp
             sec
             rts

:asmline     lda   modeflag
             bit   #lupflag
             beq   :lb
             jsr   checklup                            ;setup LUP lable
:lb          lda   labstr
             ora   opcode
             bne   :asm
             lda   #noerror
             jmp   :clc

:asm         lda   labstr                              ;was a lable defined?
             beq   :opcode
:dolable
             ldy   passnum
             beq   :passone
             lda   labstr+1                            ;get the first char
             cmp   #':'
             bne   :passone                            ;local lable?
             ldy   dolevel
             bne   :opcode
             ldy   dolevel+1
             bne   :opcode
             bit   globlab+1                           ;any global labels defined?
             bpl   :opcode
             lda   #undeflable
             jmp   :clc

:passone     jsr   definelable
             bcc   :opcode
             tay
             lda   modeflag
             and   #doflag
             bne   :opcode
             cpy   #duplable
             beq   :mis
             cpy   #misalignment
             beq   :mis
             lda   macflag
             and   #%11000000
             cmp   #%11000000
             bne   :bit
             jmp   :mis
:mis         lda   opcode
             beq   :bit
             sty   merrcode
             jsr   getopcode
             sep   $30
             ldy   merrcode
             jmp   :bit
:opcode      ldy   opcode
             beq   :bit
             jsr   getopcode
             sep   $30
             bcs   :clc
:noop        lda   #$00
:clc         tay
:bit         bit   clrglob
             bpl   :xit
             bvc   :xit
             lda   oldglob
             sta   globlab
             lda   oldglob+1
             sta   globlab+1
:xit         rep   $30
             tya
             and   #$ff
             plp
             cmp   :one
             rts
:one         dw    $0001


getopcode                                              ;ALWAYS returns in 16 bit mode
             sep   $30
             stz   forcelong

             lda   opcode
             bne   :1
             rep   $30
             clc
             rts

:1           rep   $30
             lda   opcode+$1
             xba
             sep   $30
             asl
             asl
             asl
             rep   $20
             asl
             asl
             asl
             sta   workspace
             lda   opcode+$4
             and   #$5F5F
             beq   :clc
             cmp   #$4C
             beq   :last
             cmp   #$4F44
             beq   :last
             sep   $20
             sec
             ror   forcelong
             rep   $20
:clc         clc
:last        lda   opcode+$3
             and   #$1F
             rol
             ora   workspace

             rep   $30
             tay                                       ;now get the table offset
             lda   opcode+1
             and   #$1f
             asl
             tax
             tya
             jsr   (opcodelookup,x)
             bcc   :op
             sta   opcodeword
             jmp   :macs

:op          sta   opcodeword
             sty   opdata
             sty   :jmp+1
             stx   opflags

             bit   forcelong-1
             bpl   :normop
             jsr   domac1
             bcs   :mfound

:normop      sep   $30
             bit   xcflag
             bvs   :opf                                ;65816 mode?
             bmi   :65c02
             bit   opflags+1
             bmi   :badop
             bvc   :opf
             jmp   :badop
:65c02       bit   opflags+1
             bvs   :badop
:opf         lda   opflags+1

             bit   #>macro
             bne   :cond

             bit   #>conditional
             bne   :cond

             xba
             lda   #doflag
             bit   modeflag
             bne   :noerr
             xba

             bit   #>branch
             bne   :branch
             bit   #>onebyte
             bne   :onebyte
             bit   #>general
             bne   :general
:cond        rep   $30
:jmp         jmp   $FFFF
:onebyte     rep   $30
             lda   opdata
             jmp   putopcode
:general     rep   $30
             jmp   generalop
:branch      rep   $30
             lda   opdata
             jmp   dobranch

:noerr       rep   $30
             clc
             rts
:badop       rep   $30
             lda   #badopcode
             sec
             rts
:mfound      rep   $30
             lda   #$FFFF
             jmp   :m1
:macs        rep   $30
             lda   #$0000                              ;we need to search
:m1          jsr   domacros
             rts


domacros     php                                       ;enter with $00 in A to search
             sep   $30                                 ;otherwise lableptr must point
             tay
             lda   #doflag                             ;to the macro to be expanded
             bit   modeflag
             beq   :ok
             plp
             clc
             rts
:ok          tya
             cmp   #$00
             bne   :nofind
             ldx   opcode
             cpx   #lab_size+1
             blt   :move
             ldx   #lab_size
:move        lda   opcode,x
             sta   labstr,x
             dex
             bpl   :move
             lda   macflag
             sta   :mflag
             stz   macflag
             jsr   findlable
             ldy   :mflag
             sty   macflag
             bcc   :builtin                            ;not found so try built in macs
             bcc   :bad
             rep   $20
             ldy   #o_labtype
             lda   [lableptr],y
             and   #$8004
             cmp   #$8004
             bne   :sec
:nofind
:setup       sep   $30
             lda   macflag
             sta   :mflag
             lda   #$c1                                ;expand and init
             tsb   macflag
             ldy   #$00
             sty   macvarpos
             sty   macvarpos+1
             jsr   initmac
             bcc   :clc
             ldy   :mflag
             sty   macflag
             plp
             sec
             rts
:clc         rep   $30
             plp
             clc
             rts
:bad         rep   $30
             lda   #badopcode
             plp
             sec                                       ;return clear if handled opcode
             rts
:sec         rep   $30
             lda   #notmacro
             plp
             sec                                       ;return clear if handled opcode
             rts
:mflag       ds    2

:builtin     sep   $30
             lda   #tbxflag
             bit   modeflag+1
             bne   :bok
:bd          jmp   :bad
:bd1         jmp   :bok1
:bok         lda   opcode
             cmp   #$02
             blt   :bd
             lda   opcode+1
             cmp   #'_'
             bne   :bd1
             lda   opcode+2
             and   #$5f
             cmp   #'A'
             blt   :bd1
             cmp   #'Z'+1
             bge   :bd1
             cmp   #'P'
             beq   :dos16
             cmp   #'G'
             bne   :nodos
             ldy   opcode
             cpy   #7
             blt   :nodos
             ldy   #$03
]l           lda   opcode,y
             cmp   #':'
             beq   :cmp1
             and   #$5f
:cmp1        cmp   :gsosstr,y
             bne   :nodos1
             iny
             cpy   #$07
             blt   ]l
             jmp   :gsos
:dos16       ldy   opcode
             cpy   #6
             blt   :nodos
             ldy   #$03
]l           lda   opcode,y
             cmp   :dos16str,y
             bne   :nodos1
             iny
             cpy   #$06
             blt   ]l
             jmp   :dos161
:nodos1      lda   opcode+2
             and   #$5f
:nodos       rep   $30
             and   #$ff
             sec
             sbc   #'A'
             asl
             asl
             tay

             lda   extmacptr
             ora   extmacptr+2
             beq   :bd1
             lda   extmacptr
             sta   workspace
             lda   extmacptr+2
             sta   workspace+2
             phy
             ldy   #$04
             lda   [workspace],y
             ora   #$8000
             sta   [workspace],y
             ldy   #$02
             lda   [workspace]
             sta   workspace+4
             lda   [workspace],y
             sta   workspace+6
             ply
             lda   [workspace+4],y
             tax
             iny
             iny
             lda   [workspace+4],y
             tay
             txa
             clc
             adc   workspace+4
             sta   workspace+4
             tya
             adc   workspace+6
             sta   workspace+6

:main        sep   $30
             lda   [workspace+4]
             beq   :nf1
             sta   :length
             stz   :length+1

             ldy   #$01
             lda   [workspace+4],y
             cmp   opcode
             bne   :next
             ldy   #$04                                ;now we're at the first char to CMP
             ldx   #$02
:find        lda   [workspace+4],y
             and   #$7f
             cmp   opcode-1,y
             beq   :inx
             and   #$5f                                ;set to uppercase
             cmp   opcode-1,y
             beq   :inx
             ora   #$20
             cmp   opcode-1,y
             bne   :next
:inx         iny
             inx
             cpx   opcode
             blt   :find
             jmp   :found

:next        rep   $30
             lda   :length
             clc
             adc   workspace+4
             sta   workspace+4
             bcc   :main
             inc   workspace+6
             jmp   :main

:nf1         rep   $30
             ldy   #$04
             lda   [workspace],y
             and   #$7FFF
             sta   [workspace],y
             jmp   :bad1

:found       rep   $30
             ldy   #$01
             lda   [workspace+4],y
             and   #$ff
             inc
             inc                                       ;to account for the two len bytes
             tay
             lda   [workspace+4],y

             pha
             ldy   #$04
             lda   [workspace],y
             and   #$7FFF
             sta   [workspace],y

:num         lda   #$2406                              ;length and '$'
             sta   linebuff
             sep   $30
             ldy   #$02
             lda   2,s
             lsr
             lsr
             lsr
             lsr
             ora   #'0'
             cmp   #'9'+1
             blt   :ok1
             adc   #'A'-'9'-2
:ok1         sta   linebuff,y
             iny
             lda   2,s
             and   #$0f
             ora   #'0'
             cmp   #'9'+1
             blt   :ok2
             adc   #'A'-'9'-2
:ok2         sta   linebuff,y
             iny
             lda   1,s
             lsr
             lsr
             lsr
             lsr
             ora   #'0'
             cmp   #'9'+1
             blt   :ok3
             adc   #'A'-'9'-2
:ok3         sta   linebuff,y
             iny
             lda   1,s
             and   #$0f
             ora   #'0'
             cmp   #'9'+1
             blt   :ok4
             adc   #'A'-'9'-2
:ok4         sta   linebuff,y
             lda   #$0d
             sta   linebuff+6
             rep   $30
             pla                                       ;remove from stack

             lda   #tlltxt1
             ldx   #^tlltxt1
             jsr   initinternal
             stz   linebuff
             bcc   :bcc
             jmp   :bsec

:bok1        rep   $30
             lda   opcodeword
             jsr   mactbl
             bcs   :bad1
             txa
             tyx
             jsr   initinternal
             bcc   :bcc
:bsec        plp
             sec
             rts
:bcc         plp
             clc
             rts
:bad1        rep   $30
             lda   #badopcode
             plp
             sec                                       ;return clear if handled opcode
             rts

:dos161      rep   $30
             lda   #'Z'+1-'A'
             jmp   :asl
:gsos        rep   $30
             lda   #'Z'+2-'A'
:asl         asl
             asl
             tay
             rep   $30
             lda   extmacptr
             ora   extmacptr+2
             jeq   :bd1
             lda   extmacptr
             sta   workspace
             lda   extmacptr+2
             sta   workspace+2
             phy
             ldy   #$04
             lda   [workspace],y
             ora   #$8000
             sta   [workspace],y
             ldy   #$02
             lda   [workspace]
             sta   workspace+4
             lda   [workspace],y
             sta   workspace+6
             ply
             lda   [workspace+4],y
             tax
             iny
             iny
             lda   [workspace+4],y
             tay
             txa
             clc
             adc   workspace+4
             sta   workspace+4
             tya
             adc   workspace+6
             sta   workspace+6

:main1       rep   $30
             lda   [workspace+4]
             and   #$ff
             beq   :nf2
             sta   :length

             sep   $30
             ldy   #$01
             lda   [workspace+4],y
             cmp   opcode
             bne   :next1
             iny                                       ;get to the "_"
             iny                                       ;first letter must already match
             iny                                       ;now we're at the first char to CMP
             ldx   #$02
:find1       lda   [workspace+4],y
             and   #$7f
             cmp   opcode-1,y
             beq   :inx1
             and   #$5f                                ;set to uppercase
             cmp   opcode-1,y
             bne   :next1
:inx1        iny
             inx
             cpx   opcode
             blt   :find1
             jmp   :found1

:next1       rep   $30
             lda   :length
             clc
             adc   workspace+4
             sta   workspace+4
             bcc   :main1
             inc   workspace+6
             jmp   :main1

:nf2         rep   $30
             ldy   #$04
             lda   [workspace],y
             and   #$7FFF
             sta   [workspace],y
             jmp   :bad1

:found1      rep   $30
             lda   opcode
             and   #$ff
             inc
             inc                                       ;to account for the two len bytes
             tay
             lda   [workspace+4],y

             pha
             ldy   #$04
             lda   [workspace],y
             and   #$7FFF
             sta   [workspace],y

             sep   $30
             ldy   #$00
             lda   2,s
             lsr
             lsr
             lsr
             lsr
             ora   #'0'
             cmp   #'9'+1
             blt   :ok11
             adc   #'A'-'9'-2
:ok11        sta   dosnum,y
             iny
             lda   2,s
             and   #$0f
             ora   #'0'
             cmp   #'9'+1
             blt   :ok22
             adc   #'A'-'9'-2
:ok22        sta   dosnum,y
             iny
             lda   1,s
             lsr
             lsr
             lsr
             lsr
             ora   #'0'
             cmp   #'9'+1
             blt   :ok33
             adc   #'A'-'9'-2
:ok33        sta   dosnum,y
             iny
             lda   1,s
             and   #$0f
             ora   #'0'
             cmp   #'9'+1
             blt   :ok44
             adc   #'A'-'9'-2
:ok44        sta   dosnum,y
             rep   $30
             pla                                       ;remove from stack

             lda   #dostxt1
             ldx   #^dostxt1
             jsr   initinternal
             bcc   :bcc2
             jmp   :bsec
:bcc2        jmp   :bcc


:length      ds    2,0
:gsosstr     str   '_GSOS:'
:dos16str    str   '_P16:'
:high        ds    2
:low         ds    2

domac1       php
             sep   $30
             lda   #doflag
             bit   modeflag
             beq   :ok
:clc         plp
             clc
             rts
:ok          sep   $30
             ldx   opcode
             beq   :clc
             phx

             ldx   labstr
]lup         lda   labstr,x
             sta   linelabtxt,x
             dex
             bpl   ]lup

             plx
]lup         lda   opcode,x
             sta   labstr,x
             dex
             bpl   ]lup
             lda   macflag
             sta   :mflag
             stz   macflag
             jsr   findlable
             ldy   :mflag
             sty   macflag
             bcc   :restore                            ;notfound
             rep   $20
             ldy   #o_labtype
             lda   [lableptr],y
             and   #$8004
             cmp   #$8004
             bne   :restore
             plp
             sec
             rts

:restore     sep   $30
             ldx   linelabtxt
]lup         lda   linelabtxt,x
             sta   labstr,x
             dex
             bpl   ]lup
             plp
             clc
             rts
:hash        ds    2
:mflag       ds    2

             mx    %00

amxindex     =     %0000_0000_0001
amyindex     =     %0000_0000_0010
amstack      =     %0000_0000_0100
amround      =     %0000_0000_1000
amsquare     =     %0000_0001_0000
amforce8     =     %0000_0010_0000
amforce16    =     %0000_0100_0000
amforce24    =     %0000_1000_0000
amacc        =     %0001_0000_0000
amimed       =     %0010_0000_0000
ammask       =     amforce8.amforce16.amforce24!$FFFF

tbld         =     0
tbldx        =     amxindex
tbldy        =     amyindex
tblds        =     amstack
tbld1        =     amround
tbldx1       =     amxindex+amround
tbldy1       =     amyindex+amround
tbldsy       =     amstack+amround+amyindex
tbld2        =     amsquare
tbldy2       =     amyindex+amsquare
tblal        =     amforce24
tblalx       =     amforce24+amxindex
tblacc       =     amacc
tblimed      =     amimed

addmode      php
             sep   $30
             stz   myvalue
             stz   myvalue+1
             bit   forcelong
             bpl   :long
             lda   #amforce16
             tsb   myvalue
             jmp   :init
:long        lda   opcodeword
             lsr
             bcc   :init
             lda   #amforce24
             tsb   myvalue
:init        ldy   #$00
]flush       lda   [lineptr],y
             cmp   #' '
             jlt   :zero
             beq   :iny
             cmp   #';'
             jeq   :zero
             jmp   :first
:iny         iny
             jmp   ]flush

:first       sta   firstchar+1
             sty   firstchar
             cmp   #'#'
             bne   :address
:imed        pea   #amimed
             jmp   :xit
:address     cmp   #'('
             beq   :round
             cmp   #'['
             beq   :square
             cmp   #'<'
             beq   :force8
             cmp   #'|'
             beq   :force16
             cmp   #'!'
             beq   :force16
             cmp   #'>'
             beq   :force24
             jmp   :index
:force8      lda   #amforce8
             tsb   myvalue
             jmp   :index
:force16     lda   #amforce16
             tsb   myvalue
             jmp   :index
:force24     lda   #amforce24
             tsb   myvalue
             jmp   :index
:round       lda   #amround
             tsb   myvalue
             jmp   :index
:square      lda   #amsquare
             tsb   myvalue
:index       iny
             lda   [lineptr],y
             cmp   #' '+1
             blt   :modexit
             cmp   #';'
             beq   :modexit
             cmp   #','
             bne   :index
:index1      iny
             lda   [lineptr],y
             and   #$5f
             cmp   #'Y'
             beq   :yindex
             cmp   #'X'
             beq   :xindex
             cmp   #'S'
             beq   :stack
:badmode     lda   #badaddress
             jmp   :errxit
:xindex      lda   #amxindex
             tsb   myvalue
             lda   myvalue
             and   #amround
             beq   :modexit
             lda   myvalue+1
             and   #amround
             bne   :badmode
             stz   myvalue+1
             iny
             lda   [lineptr],y
             cmp   #')'
             bne   :modexit
             lda   #amround
             tsb   myvalue+1
             jmp   :modexit
:yindex      lda   #amyindex
             tsb   myvalue
             dey
             dey
             lda   [lineptr],y
             cmp   #']'
             beq   :rsfound
             cmp   #')'
             beq   :rrfound
             jmp   :modexit
:rsfound     lda   #amsquare
             tsb   myvalue+1
             jmp   :modexit
:rrfound     lda   #amround
             tsb   myvalue+1
:modexit     lda   myvalue
             and   #amround.amsquare
             beq   :allok
             and   myvalue+1                           ;make sure all braces are there
             bne   :allok
             lda   myvalue
             and   #amyindex
             bne   :badmode1
             dey
             lda   [lineptr],y
             cmp   #')'
             beq   :rr2
             cmp   #']'
             bne   :badmode1
             lda   myvalue
             and   #amsquare
             bne   :allok
             jmp   :badmode1
:rr2         lda   myvalue
             and   #amround
             bne   :allok
:badmode1    lda   #badaddress
             jmp   :errxit

:stack       lda   #amstack
             tsb   myvalue
             lda   myvalue
             and   #amround
             beq   :modexit
             stz   myvalue+1
             iny
             lda   [lineptr],y
             cmp   #')'
             bne   :badmode1
             lda   #amround
             tsb   myvalue+1
             iny
             lda   [lineptr],y
             cmp   #','
             bne   :badmode1
             iny
             lda   [lineptr],y
             and   #$5f
             cmp   #'Y'
             bne   :badmode1
             lda   #amyindex
             tsb   myvalue
             jmp   :modexit
:allok       rep   $30
             lda   myvalue
             and   #$ff
             plp
             clc
             rts
:zero        pea   #amacc
:xit         rep   $30
             pla
             plp
             clc
             rts
:errxit      rep   $30
             and   #$ff
             plp
             sec
             rts

addmodetbl   dfb   6*3
             dfb   7*3
             dfb   8*3
             dfb   $FF
             dfb   19*3
             dfb   $FF
             dfb   $FF
             dfb   $FF
             dfb   9*3
             dfb   10*3
             dfb   11*3
             dfb   $FF
             dfb   $FF
             dfb   $FF
             dfb   20*3
             dfb   $FF
             dfb   12*3
             dfb   $FF
             dfb   13*3
             ds    109,$FF
             dfb   17*3
             dfb   18*3
             ds    126,$FF
             dfb   1*3
             ds    255,$FF
             dfb   0*3
             ds    511,$FF
             dfb   14*3
             dfb   15*3
             dfb   16*3
             dfb   $FF
             dfb   $FF
             dfb   $FF
             dfb   $FF
             dfb   $FF
             dfb   21*3
             dfb   22*3
             dfb   $FF
             dfb   $FF
             dfb   $FF
             dfb   $FF
             dfb   $FF
             dfb   $FF
             dfb   $FF
             dfb   $FF
             dfb   $FF
             ds    109,$FF
             dfb   17*3
             dfb   18*3

lastmode     ds    2

generalop    php
             rep   $30
             lda   #$ff00
             sta   :evalflag
             jsr   addmode
             bcc   :doit
             plp
             sec
             rts
:doit
             sta   :mode
             sta   lastmode
             bit   #amimed
             jne   :imediate
             bit   #amacc
             jne   :onebyte

             bit   #amforce16.amforce24
             bne   :nodp

             lda   :mode
             tax
             lda   addmodetbl,x
             and   #$FF
             cmp   #$FF
             jeq   :bad
             tay
             sep   $20
             bit   xcflag
             bpl   :get
             iny
             bvc   :get
             iny

:get         lda   (opdata),y
             bne   :putdp
             lda   :mode
             and   #amforce8
             beq   :nodp
             jmp   :bad

:putdp       sta   :opcode
             stz   :evalflag+1
             ldx   #$00
             jsr   eval
             sta   :evalflag
             bcc   :dpok
             ldy   passnum
             beq   :p12
:err         plp
             sec
             rts
:p12         cmp   #undeflable
             bne   :err
             lda   :mode
             bit   #amsquare.amround
             beq   :nodp
             lda   #00
             xba
             lda   #forwardref
             jmp   :err

:dpok        rep   $30
             lda   lvalue+2
             bne   :notdp
             lda   lvalue
             cmp   #$0100
             bge   :notdp
             lda   :opcode
             jsr   putopcode
             lda   lvalue
             jsr   putbyte
             plp
             jmp   relcorrect
:notdp       lda   :mode
             and   #amround.amsquare
             bne   :bad

:nodp        rep   $30
             lda   :mode
             and   #amforce8.amforce16!$FFFF
             clc
             adc   #$400
             tax
             lda   addmodetbl,x
             and   #$FF
             cmp   #$FF
             beq   :bad
             tay
             sep   $20
             bit   xcflag
             bpl   :get1
             iny
             bvc   :get1
             iny
:get1        lda   (opdata),y
             beq   :bad
             ldx   passnum
             beq   :p1
             jsr   putopcode
             bit   :evalflag+1
             bpl   :p3
             ldx   #$00
             jsr   eval
             bcc   :p2
:plp         plp
             sec
             rts
:p3          lda   :evalflag
             beq   :p2
             plp
             sec
             rts
:p1          rep   $30
             lda   :mode
             bit   #amforce24
             beq   :p11
             lda   #$04
             plp
             jmp   incobjptr
:p11         lda   #$03
             plp
             jmp   incobjptr

             mx    %10
:p2          lda   lvalue
             jsr   putbyte
             lda   lvalue+1
             jsr   putbyte
             lda   :mode
             bit   #amforce24
             beq   :plp1
             lda   lvalue+2
             jsr   putbyte
:plp1        plp
             jmp   relcorrect

:bad         rep   $30
             lda   #badaddress
             plp
             sec
             rts

             mx    %00
:onebyte     sep   $20
             ldy   #1*3
             bit   xcflag
             bpl   :ob1
             iny
             bvc   :ob1
             iny
:ob1         lda   (opdata),y
             beq   :bad
             jsr   putopcode
             plp
             clc
             rts

:imediate    rep   $30
             lda   :mode
             and   #amforce8.amforce16!$FFFF
             tax
             lda   addmodetbl,x
             and   #$FF
             cmp   #$FF
             beq   :bad
             tay
             sep   $20
             bit   xcflag
             bpl   :get2
             iny
             bvc   :get2
             iny
:get2        lda   (opdata),y
             beq   :bad
             jsr   putopcode
             lda   passnum
             beq   :putimed
             ldx   #$00
             jsr   eval
             bcc   :putimed
             plp
             sec
             rts
:putimed     lda   lvalue
             jsr   putbyte
             lda   opflags
             bit   #mX.mY
             bne   :indexreg
             bit   mxflag
             bmi   :imedout
:puttwo      lda   lvalue+1
             jsr   putbyte
             jmp   :imedout
:indexreg    bit   mxflag
             bvc   :puttwo
:imedout     plp
             jmp   relcorrect

:mode        ds    2
:opcode      ds    2
:evalflag    ds    2

putopcode    php
             rep   $30
             inc   linerel
             sep   $30
             pha
             lda   #cycflag
             bit   modeflag+1
             beq   :pla
             lda   1,s
             jsr   countcycles
:pla         pla
             xba
             jmp   put

putbyte      php
             sep   $30
             xba
             inc   relout
put          lda   passnum
             bne   :p22
             rep   $30
             inc   objptr
             bne   :off1
             inc   objptr+2
:off1        inc   objoffset
             bne   :plp1
             inc   objoffset+2
:plp1        plp
             clc
             rts

             mx    %11
:p22         lda   #dumflag
             bit   modeflag
             bne   :pass1
:pass2       rep   $10
             ldy   objct
             cpy   objsize
             blt   :xba
             lda   #$ff
             sta   objfull+1
             sta   objfull
             lda   #dskflag
             bit   modeflag
             beq   :nostore
             tax
             rep   $20
             lda   dskopen
             jsr   writedsk
             bcc   :reset
             phx
             jsr   dskerror
             plx
:reset       txa
             sep   $20
             jmp   :pass2
:xba         xba
             eor   encval
             sta   [objzpptr],y
             xba
             iny
             sty   objct
:nostore     ldy   bytesout
             xba
             sta   bytesout+2,y
             iny
             sty   bytesout
             bit   orgval+3
             bmi   :sep
             ldy   objptr
             sty   orgval
             ldy   objptr+2
             sty   orgval+2
             xba
             lda   #$80
             tsb   orgval+3
             xba
:sep         sep   $30
             tay
             eor   checksum
             sta   checksum
             lda   #crcflag
             bit   modeflag+1
             beq   :i2
             tya
             jsr   calccrc
:i2          lda   #%00000001
             tsb   listflag+1
             rep   $30
             inc   totbytes
             bne   :rel
             inc   totbytes+2
:rel         bit   modeflag-1                          ;rel active?
             bpl   :pass1
             inc   reloffset
             bne   :pass1
             inc   reloffset+2
:pass1       rep   $30
             inc   objptr
             bne   :off
             inc   objptr+2
:off         inc   objoffset
             bne   :plp
             inc   objoffset+2
:plp         plp
             clc
             rts

calccrc      rts

countcycles  php                                       ;must set to 16 bit mode
             rep   $30
             and   #$ff
             asl
             asl
             tax
             lda   cycletbl,x
             and   #$ff
             clc
             adc   linecycles
             sta   linecycles
             sep   $20
             lda   mxflag
             asl
             rol
             rol
             and   cycletbl+1,x
             cmp   cycletbl+1,x
             beq   :1
             sed
             lda   cycletbl+2,x
             clc
             adc   linecycles
             sta   linecycles
             cld

:1           lda   cycletbl+3,x
             lsr
             bcc   :2
             lda   mxflag+1
             and   #$40
             beq   :inc

             bit   cycflags
             bvc   :noavg
             inc   cycleavg                            ;put in avg code here
             lda   cycleavg
             and   #$01
             beq   :inc
             jmp   :2
:noavg       inc   cyclemarks
             jmp   :2
:inc         sed
             lda   linecycles
             clc
             adc   #$01
             sta   linecycles
             cld
:2

:done        rep   $30
             sed
             lda   linecycles
             clc
             adc   cycles
             sta   cycles
             cld
             plp
             rts

relcorrect   php
             sep   $30
             lda   passnum
             beq   :xit1
             lda   modeflag
             bit   #relflag
             beq   :xit1
             bit   #dumflag
             bne   :xit1
             bit   lableused+1
             bmi   :xit1
             bit   notfound
             bmi   :xit1

             rep   $30
             ldy   relct
             cpy   #relsize-16                         ;just in case!!
             blt   :setflags
:err1        jmp   :err
:xit1        jmp   :xit

:setflags    lda   #$0f
             sta   :flags
             stz   :external
             lda   noshift                             ;get low byte of unshifted value
             sta   :refnum
             lda   shiftct
             beq   :l
             cmp   #$10
             jeq   :ff
             ldy   relout
             cpy   #$02
             blt   :s8
             jmp   :ff
:s8          cmp   #$08
             bne   :l
             lda   #%01000000
             tsb   :flags
:l           lda   lableused
             cmp   #$7fff
             beq   :noext
             asl
             asl
             tay
             lda   [lableptr1],y
             sta   lableptr
             iny
             iny
             lda   [lableptr1],y
             sta   lableptr+2
             ldx   #$00
             ldy   #o_labtype
             lda   [lableptr],y
             and   #$10
             beq   :noext
             tsb   :flags
             ldy   #o_labprev
             lda   [lableptr],y
             sta   :refnum
             lda   #$8000
             tsb   :external
             lda   shiftct
             beq   :noext
             lda   #$ff
             sta   :flags
             lda   #$4000
             tsb   :external
:noext       lda   relout
             cmp   #$03
             blt   :twobytes
             lda   #%00100000
             tsb   :flags
             jmp   :insert
:twobytes    cmp   #$01
             beq   :insert
             lda   #$80
             tsb   :flags
:insert      ldy   relct
             lda   :flags
             sta   [relptr],y
             iny
             lda   linerel
             sta   [relptr],y
             iny
             iny
             lda   :refnum
             sta   [relptr],y
             iny
             bit   :external
             bvc   :stz
             lda   #$d0
             bit   :external
             bpl   :noext1
             ora   #%00000100
:noext1      ldx   shiftct
             cpx   #$10
             beq   :ffsta
             ldx   relout
             cpx   #$02
             blt   :ob1
             ora   #%00000001
             jmp   :ffsta
:ob1         ldx   shiftct
             cpx   #$08
             bne   :ffsta
             ora   #%00000011
:ffsta       sta   [relptr],y
             iny
             lda   noshift
             sta   [relptr],y
             iny
             iny
             lda   noshift+2
             sta   [relptr],y
             iny
:stz         sty   relct
             jmp   :xit
:ff          lda   #$ff
             sta   :flags
             lda   #$4000
             tsb   :external
             jmp   :l
:xit         sep   $30
             lda   #$80
             tsb   lableused+1
             tsb   notfound
             rep   $30
             stz   relout
             lda   reloffset
             sta   linerel
             plp
             clc
             rts
:err         sep   $30
             lda   #$80
             tsb   lableused+1
             tsb   notfound
             rep   $30
             stz   relout
             lda   reloffset
             sta   linerel
             lda   #relfull
             plp
             sec
             rts
:flags       ds    2
:refnum      ds    2
:external    ds    2

:show1       phx
             pha
             phy
             php
             rep   $30
             jsr   prbyte
             lda   #$20
             jsr   drawchar
             plp
             ply
             pla
             plx
             rts
:show1cr     phx
             pha
             phy
             php
             rep   $30
             jsr   prbyte
             lda   #$0d
             jsr   drawchar
             plp
             ply
             pla
             plx
             rts
:show2       phx
             pha
             phy
             php
             rep   $30
             jsr   prbytel
             lda   #$20
             jsr   drawchar
             plp
             ply
             pla
             plx
             rts


incobjptr    php
             rep   $30
             pha
             clc
             adc   objptr
             sta   objptr
             bcc   :offset
             inc   objptr+2
:offset      pla
             clc
             adc   objoffset
             sta   objoffset
             bcc   :xit
             inc   objoffset+2
:xit         plp
             clc
             rts

xref         rts

xlabnum      equ   0
xdoflag      equ   xlabnum+2
xlnum        equ   xdoflag+2
xlnum1       equ   xlnum+2
xflag        equ   xlnum1+2
xend         equ   xflag+2

xrefrec      ds    10,0

defineall    php
             sep   $30
             jmp   define
definelable
             php
             sep   $30
             lda   modeflag
             and   #doflag
             beq   define
             plp
             sec                                       ;tell caller do flag is off
             rts
define       ldy   #$00
             lda   labstr+1
             cmp   #':'
             beq   :l
             cmp   #']'
             bne   :statype
             iny
:l           iny
:statype     rep   $30
             sty   labtype
             lda   passnum
             jne   :pass1                              ;bne :pass1
:pass0       lda   #$ffff
             sta   fllast
             jsr   findlable
             bcc   :p0insert
             ldy   #o_labtype
             lda   [lableptr],y
             bit   #variablebit
             bne   :p0var
             bit   #entrybit
             bne   :p0insert
             bit   macflag-1
             bvs   :p0insert
             jmp   :dup
:p0var       ldy   #o_labnum
             lda   [lableptr],y
             sta   linelable
             ldy   #o_labval
             lda   [lableptr],y
             sta   varval
             lda   objptr
             sta   [lableptr],y
             ldy   #o_labval+2
             lda   [lableptr],y
             sta   varval+2
             lda   objptr+2
             sta   [lableptr],y
             jmp   :noerr
:p0insert    lda   objptr
             sta   labval
             lda   objptr+2
             sta   labval+2
             jsr   insertlable
             bcs   :err                                ;error returned in A
             ldy   #o_labnum
             lda   [lableptr],y
             sta   linelable
             stz   varval
             stz   varval+2
             jmp   :noerr
:err         pha
             jmp   :xit

:pass1       lda   #$ffff
             sta   fllast
             jsr   findlable
             bcc   :undef                              ;not found on second pass
             ldy   #o_labnum
             lda   [lableptr],y
             sta   linelable
             ldy   #o_labtype
             lda   [lableptr],y
             bit   #variablebit
             bne   :p1var
             bit   #$20.$10.$08.$04.$01.linkerbit      ;ext,macvar,macro,
             beq   :checkmis                           ;                    locals, or linkerequ's
             jmp   :noerr
:p1var       ldy   #o_labval
             lda   [lableptr],y
             sta   varval
             lda   objptr
             sta   [lableptr],y
             ldy   #o_labval+2
             lda   [lableptr],y
             sta   varval+2
             lda   objptr+2
             sta   [lableptr],y
             jmp   :noerr
:checkmis    ldy   #o_labval
             lda   [lableptr],y
             cmp   objptr
             bne   :misal
             ldy   #o_labval+2
             lda   [lableptr],y
             cmp   objptr+2
             beq   :noerr
:misal       ldy   #o_labval
             lda   [lableptr],y                        ;reset object pointer so we don't
             sta   objptr                              ;generate more misalign errors
             ldy   #o_labval+2
             lda   [lableptr],y
             sta   objptr+$2
             pea   #misalignment
             jmp   :xit
:undef       pea   #undeflable
             jmp   :xit
:dup         pea   #duplable
             jmp   :xit
:noerr       pea   #$00
:xit         rep   $30
             bit   linelable
             bmi   :geterr
             ldy   #o_labtype
             lda   [lableptr],y
             and   #%111111.linkerbit                  ;no macvars,externals,equates,macros,variables,
             bne   :geterr                             ;locals or linkerequ's...
             lda   globlab
             sta   oldglob
             ldy   #o_labnum
             lda   [lableptr],y
             sta   globlab
             lda   #$0080
             tsb   clrglob
:geterr      pla
             and   #$ff
             stz   fllast
             dec   fllast
             plp
             cmp   :one
             rts
:one         dw    $01

varval       ds    4

findlabval
findlable

]ct          equ   workspace
]offset      equ   ]ct+$2
]pos         equ   ]offset+$2
]pos1        equ   ]pos+$2
]len1        equ   ]pos1+$2
]len2        equ   ]len1+$2

:entry       php
             sep   $30
             bit   macflag
             bvc   :normal
             lda   labstr
             jeq   :notfound
             lda   labstr+1
             and   #$7f
             cmp   #']'
             beq   :normal
             cmp   #'@'
             beq   :normal
             jsr   macfind
             bcc   :macentry
             plp
             sec
             rts
:normal      lda   labstr+1
             cmp   #'@'
             jeq   :builtin
:nobuilt     lda   modeflag
             bit   #caseflag
             beq   :macentry
             jsr   caselable
:macentry    stz   labtype
             stz   labtype+1
             lda   lablect
             ora   lablect+1
             beq   :notfound
             lda   labstr
             beq   :notfound
             sta   ]len1
             stz   ]len1+1
             lda   labstr+$1
             cmp   #':'                                ;local lable?
             rep   $30
             bne   :global
             lda   globlab
             bmi   :notfound
             asl
             asl
             tay
             lda   [lableptr1],y
             sta   lableptr
             iny
             iny
             lda   [lableptr1],y
             sta   lableptr+2
             ldy   #o_lablocal
             lda   [lableptr],y
             bmi   :notfound                           ;none defined
             sta   ]pos
             jmp   :gloop
:global      and   #$ff
             asl
             tax
             lda   atable,x
             bmi   :notfound
             sta   ]pos
:gloop
]lup         lda   ]pos
             asl
             asl
             tay
             lda   [lableptr1],y
             sta   lableptr
             iny
             iny
             lda   [lableptr1],y
             sta   lableptr+2
             stz   ]offset
             lda   [lableptr]
             and   #label_mask
             sta   ]len2
             sep   $20
             ldx   #$02                                ;start at byte 2
             txy
]lup1        cpx   #lab_size+1
             bge   :movefound
             cpx   ]len1
             blt   :1
             beq   :1
             jmp   :goleft1
:nf1         lda   ]pos
             sta   fllast
:notfound    plp
             clc
             rts
:1           cpx   ]len2
             blt   :2
             beq   :2
             jmp   :goright
:2           lda   labstr,x
             cmp   [lableptr],y
             bne   :next
             iny
             inx
             jmp   ]lup1
:next        blt   :goleft
             jmp   :goright
:goleft1     lda   ]len1
             cmp   ]len2
             beq   :movefound
:goleft      rep   $30
             ldy   #o_lableft
             lda   [lableptr],y
             bmi   :nf1
             sta   ]pos
             jmp   ]lup
:goright     rep   $30
             ldy   #o_labright
             lda   [lableptr],y
             bmi   :nf1
             sta   ]pos
             jmp   ]lup

:movefound   rep   $30
             lda   ]pos
             asl
             asl
             tay
             lda   [lableptr1],y
             sta   lableptr
             iny
             iny
             lda   [lableptr1],y
             sta   lableptr+2
             plp
             sec
             rts
:builtin     jmp   :nobuilt

caselable    php
:doit        sep   $30
             ldx   labstr
             beq   :xit
]loop        ldy   labstr,x
             lda   converttable,y
             sta   labstr,x
             dex
             bne   ]loop
:xit         plp
             rts


insertlable

]ct          equ   workspace
]offset      equ   ]ct+$2
]pos         equ   ]offset+$2
]pos1        equ   ]pos+$2
]len1        equ   ]pos1+$2
]len2        equ   ]len1+$2

:entry       php
             rep   $30

             stz   labtype
             lda   lablect
             cmp   #maxsymbols                         ;max number of lables
             blt   :ne1
             lda   #symfull                            ;symtable full
             jmp   :error
:ne1         lda   labstr
             and   #$FF
             bne   :ne2
             lda   #badlable
             jmp   :error
:ne2         bit   macflag-1
             bvc   :ne22
             lda   labstr+1
             and   #$7f
             cmp   #']'
             beq   :ne12
             plp
             jmp   macinsert
:ne12        lda   labstr
             and   #$ff
:ne22        sta   ]len1
             bit   fllast
             bmi   :ne222
             jmp   :fastinsert
:ne222
             lda   labstr+$1                           ;first byte of string
             and   #$7F
             cmp   #':'                                ;local lable?
             beq   :local
             jmp   :global
:local       lda   #$01
             sta   labtype                             ;b0=Local Lable
             lda   globlab
             bmi   :udf
             asl
             asl
             tay
             lda   [lableptr1],y
             sta   lableptr
             iny
             iny
             lda   [lableptr1],y
             sta   lableptr+2
             ldy   #o_lablocal
             lda   [lableptr],y
             jpl   :start
             lda   globlab
             bra   :ne3
:udf         lda   #undeflable
             jmp   :error
:ne3         sta   ]pos
             sta   labprev
             asl
             asl
             tay
             lda   [lableptr1],y
             sta   lableptr
             iny
             iny
             lda   [lableptr1],y
             sta   lableptr+2
             ldy   #o_lablocal
             lda   lablect
             sta   [lableptr],y                        ;set local ptr for GLable
             jmp   :save
:global      ldx   #$00
             stx   labtype
             cmp   #']'
             bne   :asl01
             ldx   #$02
             stx   labtype
:asl01       asl
             tax
             lda   atable,x
             bpl   :start
             lda   #$FFFF
             sta   ]pos                                ;no previous
             lda   lablect
             sta   atable,x
:save        rep   $30
             jsr   :saveit
             bcc   :nosave
             plp
             sec
             rts
:nosave      lda   #$00
             plp
             clc
             rts
:start       sta   ]pos
]lup         lda   ]pos
             asl
             asl
             tay
             lda   [lableptr1],y
             sta   lableptr
             iny
             iny
             lda   [lableptr1],y
             sta   lableptr+2
             stz   ]offset
             sep   $20
             lda   [lableptr]
             sta   ]len2
             stz   ]len2+1
             ldx   #$02                                ;start at byte 2
             txy
]lup1        cpx   #lab_size+1
             jeq   :error2
             cpx   ]len1
             blt   :1
             beq   :1
             jmp   :goleft1
:1           cpx   ]len2
             blt   :2
             beq   :2
             jmp   :goright
:2           lda   [lableptr],y
             cmp   labstr,x
             bne   :next
             iny
             inx
             jmp   ]lup1
:next        rep   $30
             blt   :goright
             jmp   :goleft
:goleft1     rep   $30
             lda   ]len1
             cmp   ]len2
             bne   :goleft
:replace     ldy   #o_labtype                                 ;offset to equ value
             lda   labtype
             sta   [lableptr],y
             iny
             iny
             lda   labval                              ;replace equate
             sta   [lableptr],y
             iny
             iny
             lda   labval+$2
             and   #$00ff
             sta   [lableptr],y
             jmp   :nosave
:goleft      rep   $30
             ldy   #o_lableft                          ;leftptr
             lda   [lableptr],y
             bpl   :p1
             lda   lablect
             sta   [lableptr],y
             jmp   :save
:p1          sta   ]pos
             jmp   ]lup
:goright     rep   $30
             ldy   #o_labright                          ;rightptr
             lda   [lableptr],y
             bpl   :p2
             lda   lablect
             sta   [lableptr],y
             jmp   :save
:p2          sta   ]pos
             jmp   ]lup
:error2      rep   $30
             lda   #badlable
:error       plp
             sec
             rts
:saveit      sta   labnum
             pha
             lda   ]pos
             sta   labprev
             lda   labtype
             ora   orgor
             sta   labtype
             lda   #dumflag
             bit   modeflag
             beq   :si1
             lda   labtype
             ora   dumor                               ;#$8000
             sta   labtype
:si1         lda   #$FFFF
             sta   lableft
             sta   labright
             sta   lablocal
             lda   labval+2
             and   #$ff
             sta   labval+2
             pla
             sta   ]pos                                ;for movefound
             asl
             asl
             tay
             lda   nextlableptr
             sta   [lableptr1],y
             sta   lableptr
             pha                                       ;for mvn below
             iny
             iny
             lda   nextlableptr+2
             sta   [lableptr1],y
             sta   lableptr+2
             sep   $20
             sta   :mvn+1
             rep   $20
             ply                                       ;low of destination
             tdc
             clc
             adc   #labstr
             tax                                       ;source low word
             lda   #sym_size-1                         ;MVN
             phb
:mvn         mvn   $000000,$000000
             plb
             ldy   #o_labtype
             lda   [lableptr],y
             bpl   :and
             inc   rellabct
:and         bit   #localbit
             bne   :xref
             inc   globalct
:xref        ldx   #$00
             jsr   xref
             jsr   inclablect
             rts
:fastinsert  lda   fllast
             sta   ]pos
             ldx   #$00
             lda   labstr+1
             and   #$7f
             cmp   #':'
             beq   :filocal
             cmp   #']'
             bne   :figlobal
:fivar       inx
:filocal     inx
:figlobal    stx   labtype
             lda   ]pos
             asl
             asl
             tay
             lda   [lableptr1],y
             sta   lableptr
             iny
             iny
             lda   [lableptr1],y
             sta   lableptr+2

             ldy   #$00
             sep   $20
             lda   [lableptr]
             sta   ]len2
             ldy   #$02
             tyx                                       ;start at byte 2
]lup1        cpx   #lab_size+1
             jeq   :error2
             cpx   ]len1
             blt   :fi1
             beq   :fi1
             jmp   :figoleft1
:fi1         cpx   ]len2
             blt   :fi2
             beq   :fi2
             jmp   :figoright
:fi2         lda   [lableptr],y
             cmp   labstr,x
             bne   :finext
             iny
             inx
             jmp   ]lup1
:finext      rep   $30
             blt   :figoright
             jmp   :figoleft
:figoleft1   rep   $30
             lda   ]len1
             cmp   ]len2
             bne   :figoleft
:fireplace   rep   $30
             ldy   #o_labtype                                 ;offset to equ value
             lda   labtype
             sta   [lableptr],y
             iny
             iny
             lda   labval                              ;replace equate
             sta   [lableptr],y
             iny
             iny
             lda   labval+$2
             and   #$00ff
             sta   [lableptr],y
             jmp   :nosave
:figoright   rep   $30
             ldy   #o_labright
             jmp   :figo
:figoleft    rep   $30
             ldy   #o_lableft
:figo        lda   lablect
             sta   [lableptr],y
             jmp   :save


printlab     phy
             phx
             pha
             php
             sep   $30
             lda   labstr
             tay
             ldx   #$01
]lup         cpy   #$00
             beq   :xit
             lda   labstr,x
             jsr   drawchar
             inx
             dey
             jmp   ]lup
:xit         plp
             pla
             plx
             ply
             rts

drawlables   php
             rep   $30
             lda   #$00
             sta   :main
             sta   :recurslev
:loop        lda   :main
             asl
             tax
             lda   #' '
             sta   :treechar
             lda   atable,x
             jmi   :next
             pha
             jsr   :showtree
:next        inc   :main
             lda   :main
             cmp   #128
             blt   :loop
             plp
             rts
:main        ds    2

:recurslev   ds    2
:treechar    ds    2

             mx    %00
:showtree    inc   :recurslev
             lda   lableptr+2
             pha
             lda   lableptr
             pha
             lda   7,s
             asl
             asl
             tay
             lda   [lableptr1],y
             sta   lableptr
             iny
             iny
             lda   [lableptr1],y
             sta   lableptr+2
             ldy   #o_lableft
             lda   #'R'
             sta   :char
             lda   [lableptr],y
             bmi   :next1
             pha
             jsr   :showtree
             lda   #'L'
             sta   :char
:next1       jsr   :print
             lda   #'R'
             sta   :char
             ldy   #o_labright
             lda   [lableptr],y
             bmi   :done
             pha
             jsr   :showtree
:done        pla
             sta   lableptr
             pla
             sta   lableptr+2
             pla
             plx
             pha
             dec   :recurslev
             rts

:char        ds    2

:print       ldy   #$00
             sty   :offset
             lda   [lableptr],y
             and   #label_mask
             sta   :len
             sta   :bytes
             bne   :p1
             jmp   :pxit
:p1          ldal  $E0C061
             bmi   :p1
             lda   :recurslev
             phx
             phy
             jsr   prbyte
             lda   #' '
             jsr   drawchar
             lda   :char
             jsr   drawchar
             lda   #' '
             jsr   drawchar
             lda   :treechar
             jsr   drawchar
             lda   #' '
             jsr   drawchar
             ply
             plx
             ldx   #$01
             iny
             phx
             phy
             lda   [lableptr],y
             and   #$7F
             lda   #' '
             jsr   drawchar
             lda   #' '
             jsr   drawchar
             lda   #' '
             jsr   drawchar
             lda   :bytes
             clc
             adc   #$03
             sta   :bytes
:ply         ply
             plx
]lup         lda   [lableptr],y
             and   #$7F
             phx
             phy
             jsr   drawchar
             ply
             plx
             iny
             inx
             cpx   :len
             blt   ]lup
             beq   ]lup
             lda   #lab_size+5
             sec
             sbc   :bytes
             tax
]lup         lda   #' '
             phx
             jsr   drawchar
             plx
             dex
             bpl   ]lup
             lda   #'$'
             jsr   drawchar
             ldy   #o_labval+2
             ldx   #$03
]lup         lda   [lableptr],y
             and   #$FF
             phx
             phy
             jsr   prbyte
             ply
             plx
             dey
             dex
             bne   ]lup
             lda   #' '
             jsr   drawchar
             lda   #' '
             jsr   drawchar
             lda   :offset
             clc
             adc   #o_labtype
             tay
             lda   [lableptr],y
             jsr   prbytel
             lda   #' '
             jsr   drawchar
             lda   :offset
             clc
             adc   #o_labnum
             tay
             lda   [lableptr],y
             jsr   prbytel

             lda   #$0D
             jsr   drawchar
             ldy   #o_lablocal                                 ;offset to local labels
             lda   [lableptr],y
             bmi   :rts
             pha
             lda   #'/'
             sta   :treechar
             pla
             pha
             jsr   :showtree
             pha
             lda   #' '
             sta   :treechar
             pla
:rts
:pxit        rts

:len         ds    2
:offset      ds    2
:bytes       ds    2

