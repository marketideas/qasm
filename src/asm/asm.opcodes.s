              mx        %00
dobranch
              lda       opdata
              bit       #$800
              jne       :long
              lda       #$02
              ldy       passnum
              jeq       :p1
              ldx       #$00
              jsr       eval
              bcc       :offset
              jmp       :errput2
:offset       lda       objptr
              clc
              adc       #$02
              sta       workspace
              lda       lvalue
              sec
              sbc       workspace
              sta       lvalue
              cmp       #127+1                                                ;positive allowed
              blt       :pass
              cmp       #$FF80                                                ;negative allowed
              bge       :pass
              lda       #badbranch
              jmp       :errput2
:pass         lda       opdata
              jsr       putopcode
              lda       lvalue
              jsr       putbyte
              lda       #branchlst
              tsb       listflag+1
              lda       #cycflag
              bit       modeflag+1
              beq       :clc
              lda       opdata
              bit       #$400
              bne       :clc
              sep       $30
              bit       cycflags
              bvc       :noavg
              inc       cycleavg                                              ;put in avg code here
              lda       cycleavg
              and       #$01
              beq       :inc
              jmp       :clc
:noavg        inc       cyclemarks
              jmp       :clc
:inc          sed
              lda       linecycles
              clc
              adc       #$01
              sta       linecycles
              cld
:clc          rep       $30
              clc
              rts
:errput3      rep       $30
              pha
              lda       #$00
              jsr       putbyte
              pla
:errput2      rep       $30
              pha
              lda       #$00
              jsr       putbyte
              lda       #$00
              jsr       putbyte
              pla
              sec
              rts
:long         lda       #$03
              ldy       passnum
              beq       :p1
              ldx       #$00
              jsr       eval
              bcc       :offset1
              jmp       :errput3
:offset1      lda       objptr
              clc
              adc       #$03
              sta       workspace
              lda       lvalue
              sec
              sbc       workspace
              sta       lvalue
              lda       opdata
              jsr       putopcode
              lda       lvalue
              jsr       putbyte
              lda       lvalue+1
              jsr       putbyte
              lda       #lbranchlst
              tsb       listflag+1
              clc
              rts
:p1           jmp       incobjptr



              mx        %00
brkop         lda       #$00
              jmp       implied2
copop         lda       #$02
              jmp       implied2
wdmop         lda       #$42
implied2      jsr       putopcode
              jsr       addmode
              bit       #amacc
              bne       :zero
              and       #ammask
              cmp       #$0000
              bne       :bad
              lda       passnum
              beq       :ok
              ldx       #$00
              jsr       eval
              bcc       :ok
              rts
:ok           lda       lvalue
              jsr       putbyte
:zero         jmp       relcorrect
:bad          lda       #badaddress
              sec
              rts

jmpop         rep       $30
              jsr       addmode
              bcc       :ok
              rts
:ok           sep       $30
              bit       #amforce24.amsquare
              jne       jmlop
              and       #amforce24.amforce16.amforce8!$FFFF
              cmp       #$00
              beq       :4c
              cmp       #amround
              beq       :6c
              cmp       #amround.amxindex
              bne       :bad
              lda       xcflag
              and       #%11000000
              beq       :bad
              lda       #$7c
              jmp       :put
:4c           lda       #$4c
              jmp       :put
:6c           lda       #$6c
:put          jsr       putopcode
              lda       passnum
              beq       :ok1
              rep       $30
              ldx       #$00
              jsr       eval
              bcc       :ok1
              rts
:ok1          sep       $30
              lda       lvalue
              jsr       putbyte
              lda       lvalue+1
              jsr       putbyte
              rep       $30
              jmp       relcorrect
:bad          rep       $30
              lda       #badaddress
              sec
              rts

jmlop         rep       $30
              lda       xcflag
              and       #%01000000
              beq       :bad
              jsr       addmode
              bcc       :ok
              rts
:ok           and       #amforce24.amforce16.amforce8!$FFFF
              cmp       #$00
              beq       :5c
              cmp       #amsquare
              beq       :dc
              cmp       #amround
              beq       :dc
              jmp       :bad
:5c           lda       #$5c
              jmp       :put
:dc           lda       #$dc
:put          sta       :mode
              jsr       putopcode
              ldy       passnum
              beq       :ok1
              ldx       #$00
              jsr       eval
              bcc       :ok1
              rts
:ok1          lda       lvalue
              jsr       putbyte
              lda       lvalue+1
              jsr       putbyte
              lda       :mode
              cmp       #$5c
              bne       :rel
              lda       lvalue+2
              jsr       putbyte
:rel          jmp       relcorrect
:bad          lda       #badaddress
              sec
              rts
:mode         ds        2

jslop         rep       $30
              lda       xcflag
              and       #%01000000
              beq       :bad
              lda       passnum
              beq       :p1
              lda       #$22
              jsr       putopcode
              ldx       #$00
              jsr       eval
              bcc       :ok
              rts
:ok           lda       lvalue
              jsr       putbyte
              lda       lvalue+1
              jsr       putbyte
              lda       lvalue+2
              jsr       putbyte
              jmp       relcorrect
:p1           lda       #$04
              jmp       incobjptr
:bad          lda       #badopcode
              sec
              rts

jsrop         rep       $30
              jsr       addmode
              bcc       :ok
              rts
:ok           sep       $30
              bit       #amforce24
              jne       jslop
              and       #amforce24.amforce16.amforce8!$FFFF
              cmp       #$00
              beq       :20
              cmp       #amround.amxindex
              bne       :bad
              lda       xcflag
              and       #%01000000
              beq       :bad
              lda       #$FC
              jmp       :put
:20           lda       #$20
:put          jsr       putopcode
              lda       passnum
              beq       :ok1
              rep       $30
              ldx       #$00
              jsr       eval
              bcc       :ok1
              rts
:ok1          sep       $30
              lda       lvalue
              jsr       putbyte
              lda       lvalue+1
              jsr       putbyte
              rep       $30
              jmp       relcorrect
:bad          rep       $30
              lda       #badaddress
              sec
              rts

mvnop         ldy       passnum
              beq       :three
              ldy       #$00
:flush        lda       [lineptr],y
              iny
              and       #$7f
              cmp       #' '
              blt       :err
              beq       :flush
              cmp       #','
              beq       :found
              cmp       #';'
              beq       :err
              jmp       :flush
:err          lda       #badoperand
              sec
              rts
:found        tyx
              jsr       eval
              bcs       :err1
              lda       #$54                                                  ;MVN opcode
              jsr       putopcode
              lda       lvalue+$2
              jsr       putbyte
              lda       #$10
              sta       shiftct
              jsr       relcorrect
              bcc       :ok
              rts
:ok           ldx       #$00
              jsr       eval
              bcs       :err1
              lda       lvalue+$2
              jsr       putbyte
              lda       #$10
              sta       shiftct
              jsr       relcorrect
              rts
:three        jsr       putbyte
              jsr       putbyte
              jsr       putbyte
              clc
:err1         rts

mvpop         ldy       passnum
              beq       :three
              ldy       #$00
:flush        lda       [lineptr],y
              iny
              and       #$7f
              cmp       #' '
              blt       :err
              beq       :flush
              cmp       #','
              beq       :found
              cmp       #';'
              beq       :err
              jmp       :flush
:err          lda       #badoperand
              sec
              rts
:found        tyx
              jsr       eval
              bcs       :err1
              lda       #$44                                                  ;MVP opcode
              jsr       putopcode
              lda       lvalue+$2
              jsr       putbyte
              lda       #$10
              sta       shiftct
              jsr       relcorrect
              bcc       :ok
              rts
:ok           ldx       #$00
              jsr       eval
              bcs       :err1
              lda       lvalue+$2
              jsr       putbyte
              lda       #$10
              sta       shiftct
              jsr       relcorrect
              rts
:three        jsr       putbyte
              jsr       putbyte
              jsr       putbyte
              clc
:err1         rts


peaop         php
              rep       $30
              lda       passnum
              bne       :p2
              plp
              lda       #$03
              jmp       incobjptr
:p2           sep       $20
              lda       linebuff
              jeq       :badadd
              lda       linebuff+1
              sta       :first
              cmp       #'#'
              bne       :check
              lda       #' '
              sta       linebuff+1
:check        jsr       addmode
              pha
              php
              lda       :first
              sta       linebuff+1
              plp
              pla
              bcs       :err
              rep       $30
              and       #amimed.amforce24.amforce16.amforce8!$FFFF
              bne       :badadd
              stz       :flag
              sep       $20
              lda       linebuff+1
              cmp       #'#'
              beq       :go
              lda       linebuff
              inc
              sta       linebuff-1
              lda       #'#'
              sta       linebuff
              dec       :flag
              lda       lineptr
              sec
              sbc       #$01
              sta       lineptr
              lda       lineptr+2
              sbc       #$00
              sta       lineptr+2
:go           rep       $30
              ldx       #$00
              jsr       eval
              pha
              php
              lda       :flag
              beq       :plp
              inc       lineptr
              bne       :rst
              inc       lineptr+2
:rst          sep       $20
              lda       linebuff-1
              dec
              sta       linebuff
:plp          plp
              pla
              bcs       :err
              sep       $20
              lda       #$F4
              jsr       putopcode
              lda       lvalue
              jsr       putbyte
              lda       lvalue+1
              jsr       putbyte
              plp
              jmp       relcorrect
:badadd       rep       $30
              lda       #badaddress
:err          plp
              sec
              rts
:first        ds        2
:flag         ds        2

perop         lda       passnum
              bne       :per
              lda       #$03
              jmp       incobjptr
:per          jsr       addmode
              and       #amforce24.amforce16.amforce8!$FFFF
              bne       :bad
              ldx       #$00
              jsr       eval
              bcc       :ok
              rts
:ok           lda       #relflag                                              ;if rel'ing you can't use an
              bit       modeflag                                              ;absolute value
              beq       :ok1
              bit       lableused
              bpl       :ok1
                                                                              ;check for lableused
:ok1          lda       objptr
              clc
              adc       #$03
              pha
              lda       lvalue
              sec
              sbc       1,s
              ply
              sta       lvalue
              lda       #$62
              jsr       putopcode
              lda       lvalue
              jsr       putbyte
              lda       lvalue+1
              jsr       putbyte
              lda       #$7fff
              sta       lableused
              lda       lvalue
              sta       noshift
              jmp       relcorrect
* clc
* rts
:bad          lda       #badaddress
              sec
              rts

sepop         ldx       #$00
              jsr       eval
              bcc       :ok
              cmp       #undeflable
              bne       :err
              lda       #forwardref
:err          sec
              rts
:ok           bit       lableused
              bmi       :ok1
              lda       #badrelative
              jmp       :err
:ok1          sep       $20
              lda       lvalue
              pha
              lda       #$e2
              jsr       putopcode
              lda       1,s
              jsr       putbyte
              pla
              sep       $20
              asl
              asl
              and       #%11000000
              tsb       mxflag
              rep       $30
              clc
              rts

repop         ldx       #$00
              jsr       eval
              bcc       :ok
              cmp       #undeflable
              bne       :err
              lda       #forwardref
:err          sec
              rts
:ok           bit       lableused
              bmi       :ok1
              lda       #badrelative
              jmp       :err
:ok1          sep       $20
              lda       lvalue
              pha
              lda       #$C2
              jsr       putopcode
              lda       1,s
              jsr       putbyte
              pla
              sep       $20
              asl
              asl
              and       #%11000000
              trb       mxflag
              rep       $30
              clc
              rts


xceop         lda       #%11000000
              tsb       mxflag
              lda       #$fb
              jmp       putopcode


**************************
***     Peusdo-ops     ***
**************************
              mx        %00

casop         php
              sep       $30
              ldy       #$00
]lup          lda       [lineptr],y
              and       #$7F
              cmp       #' '
              blt       :on
              beq       :iny
              cmp       #';'
              beq       :on
              and       #$5F
              cmp       #'S'
              beq       :off
              cmp       #'I'
              beq       :on
:iny          iny
              jmp       ]lup
:on           lda       #caseflag
              tsb       modeflag
              plp
              clc
              rts
:off          lda       #caseflag
              trb       modeflag
              plp
              clc
              rts
              mx        %0



chkop         sep       $20
              lda       checksum
              jsr       putbyte
              stz       checksum
              rep       $20
              clc
              rts


dumop         bit       macflag-1
              bmi       :bad
              ldx       #$00
              jsr       eval
              bcc       :dfn
              cmp       #undeflable
              bne       :sec1
              lda       #forwardref
:sec1         sec
              rts
:bad          lda       #badopcode
              sec
              rts
:dfn          lda       objptr
              pha
              lda       objptr+$2
              pha
              lda       #$8000
              sta       dumor
              lda       lvalue
              sta       objptr
              lda       lvalue+$2
              sta       objptr+$2
              lda       lableused
              bmi       :bit
              stz       dumor                                                 ;make dummys relative
:bit          lda       #dumflag
              bit       modeflag
              bne       :pull
              pla
              sta       dumorg+$2
              pla
              sta       dumorg
              lda       #dumflag
              tsb       modeflag
              clc
              rts
:pull         pla
              pla
              clc
              rts

              mx        %00
dendop        lda       #dumflag
              bit       modeflag
              bne       :ok
:bad          lda       #badopcode
              sec
              rts
:ok           bit       macflag-1
              bmi       :bad
              stz       dumor
              lda       dumorg
              sta       objptr
              lda       dumorg+$2
              sta       objptr+$2
              lda       #dumflag
              trb       modeflag
              clc
              rts
dumorg        ds        4


              mx        %00
dsop          sep       $30
              ldy       #$00
]lup          lda       [lineptr],y
              cmp       #' '
              blt       :badoper
              beq       :iny
              cmp       #'\'
              bne       :nofill
              jmp       :fillpage
:iny          iny
              jmp       ]lup
:fillpage     iny
              lda       [lineptr],y
              cmp       #' '+1
              blt       :fp0
              cmp       #','
              bne       :badoper
              iny
:fp0          rep       $30
              tyx
              stz       lvalue+2
              lda       objptr
              and       #$00ff
              sta       lvalue
              beq       :dsfill
              ora       #$ff00
              eor       #$FFFF
              inc
              sta       lvalue
:dsfill       bit       modeflag-1                                            ;REL'ing?
              bpl       :ok
              lda       passnum
              beq       :clc
              stz       lvalue
              jsr       eval
              bcc       :dsf2
              cmp       #badoperand
              bne       :sec1
:dsf2         bit       lableused
              bmi       :dsf0
              lda       #badrelative
              sec
              rts
:dsf0         sep       $20
              lda       dsfill+1
              bne       :clc
              lda       lvalue
              sta       dsfill
              rep       $20
              lda       #$FF00
              tsb       dsfill
              lda       linerel
              sta       dsoffset
:clc          clc
              rts
:sec1         sec
              rts
:badoper      rep       $30
              lda       #badoperand
              sec
              rts
:nofill       rep       $30
              tyx
              jsr       eval
              bcc       :ok
              rts
:ok           rep       $30
              stx       :next
              lda       #relflag
              bit       modeflag
              beq       :howmany
              bit       lableused
              bmi       :howmany
              lda       #badrelative
              sec
              rts
:howmany      lda       lvalue+2
              jeq       :positive
              cmp       #$FFFF
              beq       :negative
              jmp       :bad1
:negative     lda       objptr
              clc
              adc       lvalue
              sta       objptr
              lda       objptr+2
              adc       lvalue+2
              sta       objptr+2
              lda       #dumflag
              bit       modeflag
              jne       :d2
              lda       objoffset
              clc
              adc       lvalue
              sta       objoffset
              lda       objoffset+2
              adc       lvalue+2
              jmi       :outofmem
              sta       objoffset+2
              lda       passnum
              beq       :d2
              lda       #dskflag
              bit       modeflag
              beq       :d0
              lda       dskopen
              jsr       writedsk
              bcc       :d00
:oserr        sta       prodoserr
              lda       #doserror
              sec
              rts
:d00          lda       dskopen
              sta       :markparm
              _getmark  :markparm
              bcs       :oserr
              lda       :mark
              clc
              adc       lvalue
              sta       :mark
              lda       :mark+2
              adc       lvalue+2
              sta       :mark+2
              _setmark  :markparm
              bcs       :oserr
:d0           lda       #relflag
              bit       modeflag
              beq       :d1

* jmp :d1

              lda       reloffset
              clc
              adc       lvalue
              sta       reloffset
              lda       reloffset+2
              adc       lvalue+2
              sta       reloffset+2
              bmi       :outofmem
:d1           lda       totbytes
              clc
              adc       lvalue
              sta       totbytes
              lda       totbytes+2
              adc       lvalue+2
              sta       totbytes+2
              bmi       :outofmem
              lda       #dskflag
              bit       modeflag
              bne       :d2
              lda       objct
              clc
              adc       lvalue
              sta       objct
:d2           clc
              rts
:outofmem     lda       #memfull
              sec
              rts
:bad1         lda       #badoperand
              sec
              rts
:positive     lda       lvalue
              sta       :count
              bne       :p1
              clc
              rts
:p1           cmp       #$8000
              blt       :p11
              lda       #badoperand
              sec
              rts
:p11          lda       #dumflag
              bit       modeflag
              beq       :p111
              lda       :count
              jmp       incobjptr

:p111         bit       orgval+2
              bmi       :l1
              lda       objptr
              sta       orgval
              lda       objptr+2
              ora       #$8000
              sta       orgval+2

:l1           lda       passnum
              bne       :pass2

              lda       :count
              jmp       incobjptr

:pass2        sep       $30
              ldy       :next
]lup          lda       [lineptr],y
              cmp       #' '
              blt       :zero
              bne       :eval2
              iny
              jmp       ]lup
:eval2        tyx
              jsr       eval
              bcc       :get
              rep       $30
              rts

              mx        %11
:get          lda       lvalue
              and       #$ff
              sta       :byte
              lda       #relflag
              bit       modeflag
              beq       :put1
              bit       lableused+1
              bmi       :pass22
              rep       $30
              lda       #badrelative
              sec
              rts

              mx        %11
:zero         stz       :byte
              lda       modeflag
              bit       #relflag
              beq       :put1

:pass22       rep       $30
              lda       :count
              clc
              adc       reloffset
              sta       reloffset
              bcc       :put1
              inc       reloffset+2

:put1         rep       $30
              lda       :count
              clc
              adc       totbytes
              sta       totbytes
              bcc       :put11
              inc       totbytes+2
:put11
              lda       modeflag
              bit       #dskflag
              jne       :dsk2

              lda       objsize
              sec
              sbc       objct
              bcc       :objfull
              sta       :room
              lda       :count
              cmp       :room
              blt       :store
              lda       :room
:store        ldy       objct
              tax
              sep       $20
              lda       :byte
]lup          cpx       #$00
              beq       :savey
              sta       [objzpptr],y
              iny
              dex
              jmp       ]lup
:savey        sty       objct
              cpy       objsize
              blt       :byteout
:objfull      lda       #$FFFF
              sta       objfull
:byteout      rep       $30
              lda       :count
              ora       #$8000
              sta       bytesout
              lda       :byte
              sta       bytesout+2
              lda       #$01
              tsb       listflag+1
              lda       :count
              bit       #$0001
              beq       :nochk
              sep       $20
              lda       :byte
              eor       checksum
              sta       checksum
              rep       $20
:nochk        lda       #crcflag
              bit       modeflag+1
              beq       :nocrc
              lda       #$FF00
              trb       :byte
              ldx       :count
]lup          cpx       #$00
              beq       :nocrc
              phx
              lda       :byte
              jsr       calccrc
              plx
              dex
              jmp       ]lup
:nocrc        lda       :count
              jmp       incobjptr


:dsk2         rep       $30
              lda       dskopen
              jsr       writedsk
              bcc       :dsk3
              sta       prodoserr
              lda       #doserror
              sec
              rts
:dsk3         sep       $20
              lda       :byte
              xba
              lda       :byte
              rep       $30
              ldy       #$0000
]lup          sta       [objzpptr],y
              iny
              iny
              cpy       #1024
              blt       ]lup
:write        rep       $30
              lda       :count
              sta       :count1
]lup          ldy       #1024
              lda       :count1
              jeq       :byteout
              cmp       #1024
              bge       :512
              tay
:512          sty       objct
              sty       :sbc1+1
              lda       dskopen
              jsr       writedsk
              bcc       :sbc
              sta       prodoserr
              lda       #doserror
              sec
              rts
:sbc          lda       :count1
              sec
:sbc1         sbc       #$FFFF
              sta       :count1
              bcs       ]lup
              jmp       :byteout

:count        ds        2
:count1       ds        2
:next         ds        2
:byte         ds        2
:room         ds        2
:markparm     dw        $00
:mark         ds        4,0

              mx        %00
endop         lda       #$FFFF
              sta       doneflag
              stz       macflag
              clc
              rts

              mx        %00
equop         stz       equateflag
              jmp       equate

kbdop         lda       #$0001
              sta       equateflag
              jmp       equate
pekop         lda       #$0002
              sta       equateflag
              jmp       equate
rndop         lda       #$0003
              sta       equateflag
              jmp       equate

equate        php
              rep       $30
              lda       #dupok
              bit       modeflag1
              beq       :normal
              lda       merrcode
              cmp       #duplable
              bne       :normal
              lda       linelable
              bpl       :normal
              jsr       findlable
              bcc       :bl
              ldy       #o_labtype
              lda       [lableptr],y
              bit       #equatebit
              beq       :normal
              ldy       #o_labval
              lda       [lableptr],y
              sta       :oldval
              ldy       #o_labval+2
              lda       [lableptr],y
              sta       :oldval+2
              ldx       #$00
              jsr       equeval
              jcs       :bad
              lda       lvalue
              cmp       :oldval
              bne       :dup
              lda       lvalue+2
              cmp       :oldval+2
              bne       :dup
              stz       merrcode
              jmp       :noerr
:dup          pea       #duplable
              jmp       :err
:normal       stz       :foundflag
              lda       linelable
              bpl       :ok
              jsr       findlable
              bcc       :bl
              ldy       #o_labval
              lda       [lableptr],y
              sta       :oldval
              ldy       #o_labval+2
              lda       [lableptr],y
              sta       :oldval+2
              ldy       #o_labnum
              sty       :foundflag
              lda       [lableptr],y
              jmp       :ok
:bl           pea       #badlable
              jmp       :err
:ok           pha
              lda       #%00000100
              tsb       listflag+1
              pla
:ok9          asl
              asl
              tay
              lda       [lableptr1],y
              sta       :ptr
              iny
              iny
              lda       [lableptr1],y
              sta       :ptr+2
              sep       $20
              lda       #$40
              tsb       clrglob
              rep       $20
              lda       macflag
              and       #%01100000
              beq       :nomac

              ldy       #o_labtype
              lda       [lableptr],y
              bit       #variablebit
              bne       :nomac

              lda       passnum
              bne       :macp2
:pass1        ldx       #$00
              jsr       equeval
              jcs       :bad
              lda       lvalue
              sta       labval
              lda       lvalue+2
              and       #$FF
              sta       labval+2
              lda       :ptr
              sta       lableptr
              lda       :ptr+2
              sta       lableptr+2
              sep       $30
              ldy       #$00
]lup          lda       [lableptr],y
              tyx
              sta       labstr,x
              iny
              cpy       #lab_size+1
              blt       ]lup
              plp
              jmp       insertlable
              mx        %00
:macp2        lda       :ptr
              sta       lableptr
              lda       :ptr+2
              sta       lableptr+2
              sep       $30
              lda       :foundflag
              bne       :macp21
              ldy       #$00
]lup          lda       [lableptr],y
              tyx
              sta       labstr,x
              iny
              cpy       #lab_size+1
              blt       ]lup
              jsr       findlable
              bcs       :macp21
              pea       #undeflable
              jmp       :err
:macp21       rep       $30
              ldy       #o_labval
              lda       [lableptr],y
              sta       equateval
              ldy       #o_labval+2
              lda       [lableptr],y
              sta       equateval+2
              jmp       :noerr

              mx        %00
:nomac        lda       passnum
              bne       :pass2
              lda       :ptr
              sta       lableptr
              lda       :ptr+2
              sta       lableptr+2
              ldy       #o_labtype
              lda       [lableptr],y
              bit       #variablebit
              beq       :eval
              ldy       #o_labval
              lda       varval
              sta       [lableptr],y
              ldy       #o_labval+2
              lda       varval+2
              sta       [lableptr],y
:eval         ldx       #$00
              jsr       equeval
              bcc       :equ
:bad          pha
              jmp       :err
:pass2        lda       :ptr
              sta       lableptr
              lda       :ptr+2
              sta       lableptr+2
              ldy       #o_labtype
              lda       [lableptr],y
              and       #variablebit
              beq       :equval
              ldy       #o_labval
              lda       varval
              sta       [lableptr],y
              ldy       #o_labval+2
              lda       varval+2
              sta       [lableptr],y
              ldx       #$00
              jsr       equeval
              bcs       :bad
:equ          lda       :ptr
              sta       lableptr
              lda       :ptr+2
              sta       lableptr+2
:entry        ldy       #o_labtype
              lda       [lableptr],y
              and       #$7FFF
              ora       #equatebit
              bit       lableused
              bpl       :rel
              ora       #absolutebit                                          ;**** CAN'T FORCE ALL EQU TO ABSOLUTE
:rel          sta       [lableptr],y
              iny
              iny
              lda       lvalue
              sta       [lableptr],y
              iny
              iny
              lda       lvalue+2
              sta       [lableptr],y
:equval       ldy       #o_labval
              lda       [lableptr],y
              sta       equateval
              ldy       #o_labval+2
              lda       [lableptr],y
              sta       equateval+2
:noerr        pea       $00
:err          rep       $30
              do        0
              lda       #dupok
              bit       modeflag1
              beq       :epla
              lda       merrcode
              cmp       #duplable
              bne       :epla
              ldy       #o_labval
              lda       [lableptr],y
              cmp       :oldval
              bne       :epla
              ldy       #o_labval+2
              lda       [lableptr],y
              cmp       :oldval+2
              bne       :epla
              stz       merrcode
              fin
:epla         pla
              plp
              cmp       :one
              rts
:one          dw        $01
:ptr          ds        4
:foundflag    ds        2
:oldval       ds        4

equateflag    ds        2                                                     ;$0000 = normal equate
;$8000 = keyboard equate

equeval       php
              rep       $30
              lda       equateflag
              asl
              tax
              jmp       (:tbl,x)
:tbl          dw        :equate
              dw        :kbd
              dw        :pek
              dw        :random

:equate       jsr       eval                                                  ;process normally
              jcc       :clc
              jmp       :sec

:random       jsr       random
              sta       lvalue
              jsr       random
              sta       lvalue+2
              lda       #$00
              jmp       :clc

:pek          lda       #$ffff
              sta       lableused
              ldx       #$00
              jsr       eval
              bcc       :pek1
              jmp       :sec
:pek1         lda       lvalue+2
              cmp       #$100
              bge       :badop
              lda       #relflag
              bit       modeflag
              beq       :pek2
              bit       lableused
              bmi       :pek2
              lda       #badrelative
              jmp       :sec
:pek2         pei       $02
              pei       $00
              lda       lvalue
              sta       $00
              lda       lvalue+2
              sta       $02
              sep       $20                                                   ;only read the one byte
              lda       [$00]
              rep       $20
              and       #$ff
              sta       lvalue
              stz       lvalue+2
              pla
              sta       $00
              pla
              sta       $02
              lda       #$00
              jmp       :clc
:badop        lda       #badoperand
              jmp       :sec

:kbd          stz       lvalue
              stz       lvalue+2
              lda       #$ffff
              sta       lableused
              lda       merrcode                                              ;was there a duplicate lab err?
              and       #$ff
              beq       :readkey
              cmp       #duplable
              jne       :sec

              pea       0
              _QALinkerActive
              pla
              beq       :readkey

              jsr       findlable
              bcc       :readkey
              ldy       #o_labtype
              lda       [lableptr],y
              bit       #linkerbit
              beq       :duplicate
              ldy       #o_labval
              lda       [lableptr],y
              sta       lvalue
              ldy       #o_labval+2
              lda       [lableptr],y
              sta       lvalue+2
              lda       #$00                                                  ;0 here if linker passed value
              sta       merrcode                                              ;leave alone if not.
              jmp       :clc

:readkey      lda       #$1234                                                ;*** print the message and parse input
              sta       lvalue
              stz       lvalue+2
              psl       #:str
              _QADrawString
              lda       #$00
              jmp       :clc
:str          str       'Enter value: ',0d

:duplicate    lda       #duplable
              jmp       :sec

:clc          plp
              clc
              rts
:sec          rep       $30
              ldy       passnum
              bne       :sec1
              cmp       #undeflable
              bne       :sec1
              lda       #forwardref
:sec1         plp
              sec
              rts

extop
]len          equ       workspace

              lda       passnum
              bne       :xit

              lda       macflag
              bit       #%01100000
              beq       :nomac
              lda       #badopcode
              sec
              rts
:nomac

              lda       linelable
              bmi       :group
              asl
              asl
              tay
              lda       [lableptr1],y
              sta       lableptr
              iny
              iny
              lda       [lableptr1],y
              sta       lableptr+2
              ldy       #o_labtype
              lda       [lableptr],y
              and       #%11111
              bne       :bad
              jmp       :equ
:badop        lda       #badopcode
              sec
              rts
:bad          lda       #badlable
              sec
              rts
:equ          stz       :offset
              ldy       #o_labtype                                                   ;point to type
              lda       [lableptr],y
              bit       #%1100_0000_0011_1111
              bne       :bad
              and       #%0010_0000_0000_0000                                 ;used bit
              ora       #externalbit
              sta       [lableptr],y
              phy
              ldy       #o_labprev
              lda       extcount
              sta       [lableptr],y
              inc       extcount
              ply
              iny
              iny
              lda       #$8000
              sta       [lableptr],y
              iny
              iny
              lda       #$0000
              sta       [lableptr],y
:xit          lda       #$00
              clc
              rts
:group        ldy       #$FFFF
]lup          iny
              lda       [lineptr],y
              and       #$7f
              cmp       #';'
              beq       :xit
              cmp       #' '
              blt       :xit
              beq       ]lup
:gloop        sep       $20
              lda       [lineptr],y
              ldx       #$01
              cmp       #'?'
              jlt       :gerr
              cmp       #']'
              jeq       :gerr
              sta       labstr,x
              iny
]lup          lda       [lineptr],y
              cmp       #' '+1
              blt       :insert
              cmp       #','
              beq       :insert
              cmp       #';'
              beq       :insert
              cpx       #lab_size
              bge       :iny
              sta       labstr+1,x
:iny          iny
              inx
              jmp       ]lup
:insert       txa
              cmp       #lab_size+1
              blt       :ls
              lda       #lab_size
:ls           sta       labstr
              rep       $30
              sty       :ypos
              lda       #$ffff
              sta       fllast
              jsr       findlable
              jcs       :gerr2
              jsr       insertlable
              stz       fllast
              dec       fllast
              jcs       :gerr1
              stz       :offset
              ldy       #o_labtype                                                   ;point to type
              lda       [lableptr],y
              bit       #%1100_0000_0011_1111
              bne       :gerr
              and       #%0010_0000_0000_0000                                 ;used bit
              ora       #externalbit
              sta       [lableptr],y
              phy
              ldy       #o_labprev
              lda       extcount
              sta       [lableptr],y
              inc       extcount
              ply
              iny
              iny
              lda       #$8000
              sta       [lableptr],y
              iny
              iny
              lda       #$0000
              sta       [lableptr],y
              ldy       :ypos
              lda       [lineptr],y
              iny
              and       #$7f
              cmp       #','
              jeq       :gloop
              lda       #$00
              clc
              rts
:gerr         rep       $30
              lda       #badlable
              jmp       :gerr1
:gerr2        rep       $30
              lda       #duplable
:gerr1        rep       $30
              sec
              rts
:offset       ds        2
:ypos         ds        2


exdop
]len          equ       workspace

              lda       passnum
              bne       :xit

              lda       macflag
              bit       #%01100000
              beq       :nomac
              lda       #badopcode
              sec
              rts
:nomac
              lda       linelable
              bmi       :group
              asl
              asl
              tay
              lda       [lableptr1],y
              sta       lableptr
              iny
              iny
              lda       [lableptr1],y
              sta       lableptr+2
              ldy       #o_labtype
              lda       [lableptr],y
              and       #%11111
              bne       :bad
              jmp       :equ
:badop        lda       #badopcode
              sec
              rts
:bad          lda       #badlable
              sec
              rts
:equ          stz       :offset
              ldy       #o_labtype                                                   ;point to type
              lda       [lableptr],y
              bit       #%1100_0000_0011_1111
              bne       :bad
              and       #%0010_0000_0000_0000                                 ;used bit
              ora       #externalbit
              sta       [lableptr],y
              phy
              ldy       #o_labprev
              lda       extcount
              sta       [lableptr],y
              inc       extcount
              ply
              iny
              iny
              lda       #$0000
              sta       [lableptr],y
              iny
              iny
              lda       #$0000
              sta       [lableptr],y
:xit          lda       #$00
              clc
              rts
:group        ldy       #$FFFF
]lup          iny
              lda       [lineptr],y
              and       #$7f
              cmp       #';'
              beq       :xit
              cmp       #' '
              blt       :xit
              beq       ]lup
:gloop        sep       $20
              lda       [lineptr],y
              ldx       #$01
              cmp       #'?'
              jlt       :gerr
              cmp       #']'
              jeq       :gerr
              sta       labstr,x
              iny
]lup          lda       [lineptr],y
              cmp       #' '+1
              blt       :insert
              cmp       #','
              beq       :insert
              cmp       #';'
              beq       :insert
              cpx       #lab_size
              bge       :iny
              sta       labstr+1,x
:iny          iny
              inx
              jmp       ]lup
:insert       txa
              cmp       #lab_size+1
              blt       :ls
              lda       #lab_size
:ls           sta       labstr
              rep       $30
              sty       :ypos
              lda       #$ffff
              sta       fllast
              jsr       findlable
              jcs       :gerr2
              jsr       insertlable
              stz       fllast
              dec       fllast
              jcs       :gerr1
              stz       :offset
              ldy       #o_labtype                                                   ;point to type
              lda       [lableptr],y
              bit       #%1100_0000_0011_1111
              bne       :gerr
              and       #%0010_0000_0000_0000                                 ;used bit
              ora       #externalbit
              sta       [lableptr],y
              phy
              ldy       #o_labprev
              lda       extcount
              sta       [lableptr],y
              inc       extcount
              ply
              iny
              iny
              lda       #$0000
              sta       [lableptr],y
              iny
              iny
              lda       #$0000
              sta       [lableptr],y
              ldy       :ypos
              lda       [lineptr],y
              iny
              and       #$7f
              cmp       #','
              jeq       :gloop
              lda       #$00
              clc
              rts
:gerr         rep       $30
              lda       #badlable
              jmp       :gerr1
:gerr2        rep       $30
              lda       #duplable
:gerr1        rep       $30
              sec
              rts
:offset       ds        2
:ypos         ds        2

entop
]len          equ       workspace

              lda       macflag
              bit       #%01100000
              beq       :nomac
              lda       #badopcode
              sec
              rts
:nomac
              lda       linelable
              bmi       :group
* label ent - first pass only.
              ldx       passnum
              bne       :xit
              asl
              asl
              tay
              lda       [lableptr1],y
              sta       lableptr
              iny
              iny
              lda       [lableptr1],y
              sta       lableptr+2
              ldy       #o_labtype
              lda       [lableptr],y
              and       #macvarbit.externalbit.macrobit.variablebit.localbit
              bne       :bad
              jmp       :equ
:badop        lda       #badopcode
              sec
              rts
:bad          lda       #badlable
              sec
              rts
:equ          stz       :offset
              ldy       #o_labtype                                                   ;point to type
              lda       [lableptr],y
              and       #usedbit.absolutebit.equatebit
              ora       #entrybit
              sta       [lableptr],y
              phy
              ldy       #o_labprev
              lda       entcount
              sta       [lableptr],y
              inc       entcount
              ply
:xit          rep       $30
              lda       #$00
              clc
              rts
:group        ldy       #$00
              sep       $20
]g            lda       [lineptr],y
              and       #$7f
              cmp       #' '
              blt       :group1
              bne       :and
              iny
              bra       ]g
:and          and       #$5f
              cmp       #'O'
              bne       :group1
              iny
              lda       [lineptr],y
              and       #$5f
              cmp       #'N'
              beq       :gon
              cmp       #'F'
              bne       :group1
              iny
              lda       [lineptr],y
              and       #$5f
              cmp       #'F'
              bne       :group1
:gon          xba
              iny
              lda       [lineptr],y
              and       #$7f
              cmp       #' '+1
              bge       :group1
              xba
              cmp       #'F'
              beq       :goff
              rep       $20
              lda       #entrybit
              tsb       orgor
              jmp       :xit
:goff         rep       $20
              lda       #entrybit
              trb       orgor
              jmp       :xit

* ent label[,label] - second pass only.
:group1       rep       $30
              ldx       passnum
              beq       :xit
              sep       $20
              ldy       #$FFFF
]lup          iny
              lda       [lineptr],y
              and       #$7f
              cmp       #';'
              beq       :xit
              cmp       #' '
              blt       :xit
              beq       ]lup
:gloop        rep       $30
              sep       $20
              lda       [lineptr],y
              ldx       #$01
              cmp       #'?'
              jlt       :gerr
              cmp       #']'
              jeq       :gerr
              sta       labstr,x
              iny
]lup          lda       [lineptr],y
              cmp       #' '+1
              blt       :insert
              cmp       #','
              beq       :insert
              cmp       #';'
              beq       :insert
              cpx       #lab_size
              bge       :iny
              sta       labstr+1,x
:iny          iny
              inx
              jmp       ]lup
:insert       txa
              cmp       #lab_size+1
              blt       :ls
              lda       #lab_size
:ls           sta       labstr
              rep       $30
              sty       :ypos
              lda       #$ffff
              sta       fllast
              jsr       findlable
              bcc       :gerr3

              stz       :offset
              ldy       #o_labtype                                                   ;point to type
              lda       [lableptr],y
              and       #macvarbit.externalbit.macrobit.variablebit.localbit
              bne       :gerr
              lda       [lableptr],y
              and       #usedbit.absolutebit.equatebit
              ora       #entrybit                                             ;entry lable
              sta       [lableptr],y
              ldy       #o_labprev
              lda       entcount
              sta       [lableptr],y
              inc       entcount

              ldy       :ypos
              lda       [lineptr],y
              iny
              and       #$7f
              cmp       #','
              jeq       :gloop
              lda       #$00
              clc
              rts
:gerr         rep       $30
              lda       #badlable
              jmp       :gerr1
:gerr3        rep       $30
              lda       #undeflable
              jmp       :gerr1
:gerr2        rep       $30
              lda       #duplable
:gerr1        rep       $30
              sec
              rts
:offset       ds        2
:ypos         ds        2


lstop         php
              sep       $30
              ldy       #$00
]lup          lda       [lineptr],y
              and       #$7F
              cmp       #' '
              blt       :on
              beq       :iny
              cmp       #';'
              beq       :on
              and       #$5F
              cmp       #'F'
              beq       :off
              cmp       #'N'
              beq       :on
              cmp       #'R'
              beq       :rtn
:iny          iny
              jmp       ]lup
:on           lda       listflag
              and       #$80
              sta       oldlstflag
              lda       #$80
              tsb       listflag
              trb       listflag+1
              plp
              clc
              rts
:off          lda       listflag
              and       #$80
              sta       oldlstflag
              lda       #$80
              trb       listflag
              trb       listflag+1
              plp
              clc
              rts
:rtn          lda       listflag
              pha
              lda       listflag
              and       #$7f
              ora       oldlstflag
              sta       listflag
              lda       #$80
              trb       listflag+1
              pla
              and       #$80
              sta       oldlstflag
              plp
              clc
              rts
oldlstflag    ds        4

              mx        %00
lstdoop       php
              sep       $30
              ldy       #$00
]lup          lda       [lineptr],y
              and       #$7F
              cmp       #' '
              blt       :on
              beq       :iny
              cmp       #';'
              beq       :on
              and       #$5F
              cmp       #'F'
              beq       :off
              cmp       #'N'
              beq       :on
:iny          iny
              jmp       ]lup
:off          lda       #lstdoon
              tsb       listflag
              lda       #$80
              trb       listflag+1
              plp
              clc
              rts
:on           lda       #lstdoon
              trb       listflag
              lda       #$80
              trb       listflag+1
              plp
              clc
              rts

              mx        %00
dupop         php
              sep       $30
              ldy       #$00
]lup          lda       [lineptr],y
              and       #$7F
              cmp       #' '
              blt       :on
              beq       :iny
              cmp       #';'
              beq       :on
              and       #$5F
              cmp       #'F'
              beq       :off
              cmp       #'N'
              beq       :on
:iny          iny
              jmp       ]lup
:on           lda       #dupok
              tsb       modeflag1
              plp
              clc
              rts
:off          lda       #dupok
              trb       modeflag1
              plp
              clc
              rts


              mx        %00
trop          php
              sep       $30
              ldy       #$00
]lup          lda       [lineptr],y
              and       #$7F
              cmp       #' '
              blt       :on
              beq       :iny
              cmp       #';'
              beq       :on
              and       #$5F
              cmp       #'F'
              beq       :off
              cmp       #'N'
              beq       :on
              cmp       #'A'
              beq       :adr
:iny          iny
              jmp       ]lup
:on           lda       #%00000010
              tsb       listflag
              plp
              clc
              rts
:off          lda       #%00100010
              trb       listflag
              plp
              clc
              rts
:adr          lda       #%00100000
              tsb       listflag
              plp
              clc
              rts

              mx        %00
crcop         php
              sep       $30
              lda       modeflag
              bit       #crcflag
              beq       :init
              lda       passnum
              bne       :put
              rep       $30
              stz       crc16
              lda       #$02
              jmp       incobjptr
:put          rep       $30
              lda       crc16
              jsr       putbyte
              lda       crc16+1
              jsr       putbyte
:init         rep       $30
              lda       #crcflag
              tsb       modeflag+1
              stz       crc16
              plp
              clc
              rts

              mx        %00
encop         lda       passnum
              bne       :ok
              lda       #encflag
              tsb       modeflag+1
              clc
              rts
:ok           sep       $30
              lda       #encflag
              tsb       modeflag+1
              lda       #relflag
              bit       modeflag
              beq       :flush
              rep       $30
              lda       #badopcode
              sec
              rts
              mx        %11
:flush        ldy       #$ff
]lup          iny
              lda       [lineptr],y
              and       #$7f
              cmp       #' '
              blt       :off
              beq       ]lup
              cmp       #';'
              beq       :off
              ldx       #$00
              jsr       eval
              bcc       :good1
              rep       $30
              rts
              mx        %11
:off          stz       lvalue
:good1        lda       lvalue
              sta       encval
              rep       $31
              rts


              mx        %00
cycop         php
              sep       $30
              lda       passnum
              bne       :ok
              plp
              clc
              rts
:ok           ldy       #$00
]lup          lda       [lineptr],y
              and       #$7F
              cmp       #' '
              blt       :on
              beq       :iny
              cmp       #';'
              beq       :on
              and       #$5F
              cmp       #'F'
              beq       :flags
              cmp       #'N'
              beq       :on
              cmp       #'A'
              beq       :avg
:iny          iny
              jmp       ]lup
:flags        iny
              lda       [lineptr],y
              and       #$df
              cmp       #'L'
              bne       :off
              lda       #cycflag
              tsb       modeflag+1
              lda       #$80
              jmp       :xit
:on           lda       #cycflag
              tsb       modeflag+1
              lda       #$00
              jmp       :xit
:off          lda       #cycflag
              trb       modeflag+1
              lda       #$00
              stz       cycflags
              jmp       :xit
:avg          lda       #cycflag
              tsb       modeflag+1
              lda       #$40
:xit          rep       $30
              stz       cycles
              stz       cycleavg
              and       #$FF
              tsb       cycflags
              plp
              clc
              rts

              mx        %00
expop         php
              sep       $30
              ldy       #$00
]lup          lda       [lineptr],y
              and       #$7F
              cmp       #' '
              blt       :on
              beq       :iny
              cmp       #';'
              beq       :on
              and       #$5F
              cmp       #'F'
              beq       :off
              cmp       #'N'
              beq       :only
:iny          iny
              jmp       ]lup
:only         iny
              lda       [lineptr],y
              and       #$df
              cmp       #'L'
              bne       :on
              lda       #exponly.expflag
              tsb       modeflag+1
              plp
              clc
              rts
:on           lda       #expflag
              tsb       modeflag+1
              lda       #exponly
              trb       modeflag+1
              plp
              clc
              rts
:off          lda       #exponly.expflag
              trb       modeflag+1
              plp
              clc
              rts

              mx        %00
tbxop         php
              sep       $30
              ldy       #$00
]lup          lda       [lineptr],y
              and       #$7F
              cmp       #' '
              blt       :on
              beq       :iny
              cmp       #';'
              beq       :on
              and       #$5F
              cmp       #'F'
              beq       :off
              cmp       #'N'
              beq       :on
              cmp       #'U'
              beq       :uc
              cmp       #'L'
              beq       :lc
:iny          iny
              jmp       ]lup

:on           lda       #tbxflag
              tsb       modeflag+1
              jmp       :xit
:off          lda       #tbxflag
              trb       modeflag+1
              lda       #$FF
              sta       tbxand
              jmp       :xit
:uc           lda       #$5f
              sta       tbxand
              jmp       :on
:lc           lda       #$ff
              sta       tbxand
              jmp       :on
:xit          rep       $30
              plp
              clc
              rts


              mx        %00
evlop         php
              sep       $30
              ldy       #$00
]lup          lda       [lineptr],y
              and       #$7F
              cmp       #' '
              blt       :on
              beq       :iny
              cmp       #';'
              beq       :on
              and       #$5F
              cmp       #'F'
              beq       :off
              cmp       #'N'
              beq       :on
:iny          iny
              jmp       ]lup
:on           lda       #algflag
              tsb       modeflag+1
              jmp       :xit
:off          lda       #algflag
              trb       modeflag+1
:xit          rep       $30
              plp
              clc
              rts


              mx        %00
mxop          php
              rep       $30
              bit       xcflag-1
              bvs       :mx
              lda       #badopcode
              plp
              sec
              rts
:mx           ldx       #$00
              jsr       eval
              bcc       :peachy
              cmp       #undeflable
              bne       :sec1
              lda       #forwardref
:sec1         plp
              sec
              rts
:peachy       lda       lvalue
              cmp       #$04
              blt       :ok
              lda       #badoperand
              plp
              sec
              rts
:ok           sep       $20
              and       #$03
              lsr
              ror
              ror                                                             ;shift into b7-b6
              sep       $20
              sta       mxflag
              plp
              clc
              rts
              mx        %00

orgop         sep       $30
              ldy       #$FF
]lup          iny
              lda       [lineptr],y
              cmp       #' '
              blt       :restore
              beq       ]lup
              ldx       #$00
              jsr       eval
              bcc       :org
              rep       $30
              cmp       #undeflable
              bne       :err
              lda       #forwardref
:err          rep       $30
              sec
              rts
:org          rep       $30
              lda       #relflag
              bit       modeflag
              beq       :o1
              lda       lableused
              bmi       :orel
              lda       #badrelative
              sec
              rts
:orel         lda       #$8000
              tsb       orgor
:o1           lda       objoffset
              sta       oldoffset
              lda       objoffset+2
              sta       oldoffset+2
              lda       objptr
              sta       oldobj
              lda       objptr+2
              sta       oldobj+2
              lda       lvalue
              sta       objptr
              lda       lvalue+2
              sta       objptr+2
              stz       objoffset
              stz       objoffset+2
              clc
              rts
:restore      rep       $30
              lda       oldobj
              clc
              adc       objoffset
              sta       objptr
              lda       oldobj+2
              adc       objoffset+2
              sta       objptr+2
              lda       #relflag
              bit       modeflag
              beq       :o2
              lda       #$8000
              trb       orgor
:o2           clc
              rts


relop         rep       $30
              bit       macflag-1
              bpl       :rel
:bad          lda       #badopcode
              sec
              rts
:rel          lda       #encflag*256+relflag
              bit       modeflag
              bne       :bad
              lda       passnum
              jne       :p2
              lda       rellabct
              bne       :bad
              psl       #$00
              psl       #relsize+1
              ldal      userid
              ora       #memid
              pha
              pea       $8000                                                 ;locked page aligned
              psl       #$00
              _NewHandle
              plx
              ply
              bcs       :merr01
              stx       relptr
              sty       relptr+2
              ldy       #$02
              lda       [relptr]
              tax
              lda       [relptr],y
              sta       relptr+$2
              stx       relptr
* jmp :p1
:p2           lda       relptr
              ora       relptr+2
              beq       :p1
              lda       #relflag
              tsb       modeflag
:p1           lda       #$8000
              trb       orgor                                                 ;stz orgor
              stz       relct
              clc
              rts
:merr01       sta       prodoserr
              lda       #doserror
              sec
              rts

              mx        %00
dwop          php
              sep       $30
              ldy       passnum
              bne       :pass2
:p0           stz       :count
              lda       (lineptr)
              cmp       #' '+1
              blt       :bad
:p00          lda       (lineptr),y
              iny
              cmp       #' '+1
              blt       :p0xit
              beq       :p00
              cmp       #','
              bne       :p00
              inc       :count
              jmp       :p00
:p0xit        rep       $30
              lda       :count
              inc
              asl
              plp
              jmp       incobjptr
:bad          rep       $30
              lda       #badoperand
              plp
              sec
              rts

              mx        %11
:pass2        ldx       #$00
:loop         jsr       eval
              bcc       :pass21
:sec          plp
              sec
              rts
:pass21       phx
              lda       lvalue
              jsr       putbyte
              lda       lvalue+$1
              jsr       putbyte
              jsr       relcorrect
              rep       $30
              lda       objptr
              sta       pcobjptr
              lda       objptr+2
              sta       pcobjptr+2
              sep       $30
              plx
              txy
              lda       (lineptr),y
              cmp       #' '+1
              bge       :loop
:clc          plp
              clc
              rts
:count        ds        2


              mx        %00
dfbop         php
              sep       $30
              ldy       passnum
              bne       :pass2
:p0           stz       :count
              lda       (lineptr)
              cmp       #' '+1
              blt       :bad
:p00          lda       (lineptr),y
              iny
              cmp       #' '+1
              blt       :p0xit
              beq       :p00
              cmp       #','
              bne       :p00
              inc       :count
              jmp       :p00
:p0xit        rep       $30
              lda       :count
              inc
              plp
              jmp       incobjptr
:bad          rep       $30
              lda       #badoperand
              plp
              sec
              rts

              mx        %11
:pass2        ldx       #$00
:loop         jsr       eval
              bcc       :pass21
:sec          plp
              sec
              rts
:pass21       phx
              lda       lvalue
              jsr       putbyte
              jsr       relcorrect
              rep       $30
              lda       objptr
              sta       pcobjptr
              lda       objptr+2
              sta       pcobjptr+2
              sep       $30
              plx
              txy
              lda       (lineptr),y
              cmp       #' '+1
              bge       :loop
:clc          plp
              clc
              rts
:count        ds        2


              mx        %00
ddbop         ldx       #$00
              bra       :init
:loop         ldy       :val
              lda       [lineptr],y
              and       #$7F
              cmp       #' '+$1
              jlt       :clc
              cmp       #','
              bne       :err
              tyx
:init         jsr       eval
              bcc       :pass1
              cmp       #undeflable
              bne       :sec
              ldy       passnum
              beq       :pass1
:sec          sec
              rts
:err          lda       #badoperand
              sec
              rts
:pass1        stx       :val
              lda       lvalue+$1
              jsr       putbyte
              lda       lvalue
              jsr       putbyte
              lda       passnum
              beq       :jmp
              lda       objptr
              sta       pcobjptr
              lda       objptr+2
              sta       pcobjptr+2
              lda       modeflag
              bit       #relflag
              beq       :jmp
              bit       lableused
              bmi       :jmp
              bit       notfound-1
              bmi       :jmp
              lda       lableused
              cmp       #$7fff
              beq       :internal
:nrel         asl
              asl
              tay
              lda       [lableptr1],y
              sta       lableptr
              iny
              iny
              lda       [lableptr1],y
              sta       lableptr+2
              stz       :offset
              ldy       #o_labtype
              lda       [lableptr],y
              bit       #externalbit
              beq       :internal
              ldy       #o_labprev
              lda       [lableptr],y
              and       #$00ff
              sta       noshift+1
              lda       #$bf
              jmp       :relsta
:internal     lda       #$AF
:relsta       ldy       relct
              cpy       #relsize-16
              bge       :relfull
              sta       [relptr],y
              iny
              lda       linerel
              sta       [relptr],y
              iny
              iny
              lda       noshift+1
              sta       [relptr],y
              iny
              sty       relct
              stz       relout
              sep       $20
              sec
              ror       notfound
              rep       $20
              sec
              ror       lableused
              lda       reloffset
              sta       linerel
:jmp          jmp       :loop
:clc          clc
              rts
:relfull      lda       #relfull
              sec
              rts
:val          ds        2
:offset       ds        2

              mx        %00
adrop         php
              sep       $30
              ldy       passnum
              bne       :pass2
:p0           stz       :count
              lda       (lineptr)
              cmp       #' '+1
              blt       :bad
:p00          lda       (lineptr),y
              iny
              cmp       #' '+1
              blt       :p0xit
              beq       :p00
              cmp       #','
              bne       :p00
              inc       :count
              jmp       :p00
:p0xit        rep       $30
              lda       :count
              inc
              pha
              asl
              clc
              adc       1,s
              plx
              plp
              jmp       incobjptr
:bad          rep       $30
              lda       #badoperand
              plp
              sec
              rts

              mx        %11
:pass2        ldx       #$00
:loop         jsr       eval
              bcc       :pass21
:sec          plp
              sec
              rts
:pass21       phx
              lda       lvalue
              jsr       putbyte
              lda       lvalue+$1
              jsr       putbyte
              lda       lvalue+2
              jsr       putbyte
              jsr       relcorrect
              rep       $30
              lda       objptr
              sta       pcobjptr
              lda       objptr+2
              sta       pcobjptr+2
              sep       $30
              plx
              txy
              lda       (lineptr),y
              cmp       #' '+1
              bge       :loop
:clc          plp
              clc
              rts
:count        ds        2

              mx        %00
adrlop        php
              sep       $30
              ldy       passnum
              bne       :pass2
:p0           stz       :count
              lda       (lineptr)
              cmp       #' '+1
              blt       :bad
:p00          lda       (lineptr),y
              iny
              cmp       #' '+1
              blt       :p0xit
              beq       :p00
              cmp       #','
              bne       :p00
              inc       :count
              jmp       :p00
:p0xit        rep       $30
              lda       :count
              inc
              asl
              asl
              plp
              jmp       incobjptr
:bad          rep       $30
              lda       #badoperand
              plp
              sec
              rts

              mx        %11
:pass2        ldx       #$00
:loop         jsr       eval
              bcc       :pass21
:sec          plp
              sec
              rts
:pass21       phx
              lda       lvalue
              jsr       putbyte
              lda       lvalue+$1
              jsr       putbyte
              lda       lvalue+$2
              jsr       putbyte
              lda       lvalue+$3
              jsr       putbyte
              jsr       relcorrect
              rep       $30
              lda       objptr
              sta       pcobjptr
              lda       objptr+2
              sta       pcobjptr+2
              sep       $30
              plx
              txy
              lda       (lineptr),y
              cmp       #' '+1
              bge       :loop
:clc          plp
              clc
              rts
:count        ds        2

              mx        %00
strop         jsr       getasc
              bcc       :ok
              rts
:ok           lda       passnum
              bne       :pass2
              lda       asclength
              and       #$FF
              inc
              jmp       incobjptr
:pass2        sep       $30
              lda       asclength
              jsr       putbyte
              ldx       asclength
              ldy       #$00
]lup          cpx       #$00
              beq       :clc
              lda       ascstr,y
              phx
              phy
              jsr       putbyte
              ply
              plx
              iny
              dex
              jmp       ]lup
:clc          rep       $31
              rts

strlop        jsr       getasc
              bcc       :ok
              rts
:ok           lda       passnum
              bne       :pass2
              lda       asclength
              and       #$FF
              inc
              inc
              jmp       incobjptr
:pass2        sep       $30
              lda       asclength
              jsr       putbyte
              lda       asclength+1
              jsr       putbyte
              ldx       asclength
              ldy       #$00
]lup          cpx       #$00
              beq       :clc
              lda       ascstr,y
              phx
              phy
              jsr       putbyte
              ply
              plx
              iny
              dex
              jmp       ]lup
:clc          rep       $31
              rts


***************************
*
*   Remember: when converting this code
*   to support precompiled source files
*   this routine must be modified so that
*   it does not read directly from the
*   source file itself.  Preferably by
*   checking a flag that is set by the
*   initial "readline" routine indicating
*   that the fields are correctly set up.
*
****************************

getasc1       php
              rep       $30
              lda       #$ffff
              sta       ascflag
              jmp       getasc2
getasc        php
              rep       $30
              stz       ascflag
getasc2       stz       asclength
              stz       :macflag
              ldy       #$00
              lda       macflag
              and       #%01100000
              sep       $30
              bne       :oper1
              bit       ascflag+1
              bpl       :norm
:spec1        lda       [lineptr],y
              tax
              lda       inputtbl,x
              cmp       #' '
              blt       :err
              bne       :cmpspec
              iny
              bra       :spec1
:cmpspec      cmp       #'#'
              jeq       :special
              ldy       #$00
:norm         rep       $30
              lda       #$FFFF
              sta       :macflag
              stz       linebuff
              stz       comment
              lda       fileptr
              sta       lineptr
              lda       fileptr+2
              sta       lineptr+2
              sep       $30
              lda       [lineptr]
              tax
              lda       inputtbl,x
              cmp       #' '
              blt       :err
              beq       :nolable
:lup1         iny
              lda       [lineptr],y
              tax
              lda       inputtbl,x
              cmp       #' '
              blt       :err
              bne       :lup1
:nolable      iny
              lda       [lineptr],y
              tax
              lda       inputtbl,x
              cmp       #' '
              blt       :err
              beq       :nolable
:opcode       iny
              lda       [lineptr],y
              tax
              lda       inputtbl,x
              cmp       #' '
              blt       :err
              bne       :opcode
:oper         iny
:oper1        lda       [lineptr],y
              tax
              lda       inputtbl,x
              cmp       #' '
              blt       :err
              beq       :oper
              jmp       :start

:err          rep       $30
              lda       #badoperand
:sec          rep       $30
              stz       asclength
              plp
              sec
              rts

              mx        %11
:start        ldx       #$00
              stz       :length
              stz       :length+1
              stz       :deliminator
:loop         lda       [lineptr],y
              phx
              tax
              lda       inputtbl,x
              plx
              bit       :macflag
              bpl       :cmp0
              cpx       #128
              bge       :cmp0
              sta       linebuff+1,x
              inx
:cmp0         cmp       #' '+1
              jlt       :done
              cmp       #','
              jeq       :next
              cmp       #'$'
              beq       :hex0
              cmp       #'0'
              jlt       :delim
              cmp       #'9'+1
              blt       :hex
              cmp       #'a'
              blt       :check
              cmp       #'f'+1
              bge       :check
              and       #$5f
              jmp       :hex1
:check        cmp       #'A'
              jlt       :delim
              cmp       #'F'+1
              blt       :hex1
              cmp       #'Z'+1
              blt       :err
              cmp       #'a'
              jlt       :delim
              cmp       #'z'+1
              blt       :err
              jmp       :delim
:hex0         iny
              lda       [lineptr],y
              phx
              tax
              lda       inputtbl,x
              plx
              bit       :macflag
              bpl       :cmp1
              cpx       #128
              bge       :cmp1
              sta       linebuff+1,x
              inx
:cmp1         cmp       #'0'
              jlt       :err
              cmp       #'9'+1
              blt       :hex
              cmp       #'A'
              jlt       :err
              cmp       #'Z'+1
              blt       :hex1
              cmp       #'a'
              jlt       :err
              cmp       #'z'+1
              jge       :err
              and       #$5f
:hex1         sec
              sbc       #$37
              jmp       :hexdigit
:hex          sec
              sbc       #$30
:hexdigit     asl
              asl
              asl
              asl
              sta       :digit
              iny
              lda       [lineptr],y
              phx
              tax
              lda       inputtbl,x
              plx
              bit       :macflag
              bpl       :cmp2
              cpx       #128
              bge       :cmp2
              sta       linebuff+1,x
              inx
:cmp2         cmp       #'a'
              blt       :hd1
              cmp       #'z'+1
              jge       :err
              and       #$5f
              jmp       :hd2
:hd1          cmp       #'0'
              jlt       :err
              cmp       #'9'+1
              blt       :hd3
              cmp       #'A'
              jlt       :err
              cmp       #'F'+1
              blt       :hd2
              jmp       :err
:hd2          sec
              sbc       #$37
              jmp       :hd4
:hd3          sec
              sbc       #$30
:hd4          ora       :digit
              phx
              ldx       :length
              sta       ascstr,x
              plx
              inc       :length
              iny
              jmp       :loop
:delim        sta       :deliminator
              stz       :orflag
              cmp       #$27
              bge       :string
              lda       #$80
              sta       :orflag
:string       iny
              lda       [lineptr],y
              phx
              tax
              lda       inputtbl,x
              plx
              bit       :macflag
              bpl       :cmp3
              cpx       #128
              bge       :cmp3
              sta       linebuff+1,x
              inx
:cmp3         cmp       #' '
              blt       :done
              cmp       :deliminator
              bne       :phx
              stz       :deliminator
              jmp       :next
:phx          phx
              ldx       :length
              ora       :orflag
              sta       ascstr,x
              plx
              inc       :length
              jmp       :string
:next         iny
              jmp       :loop
:done         bit       :macflag
              bpl       :rep2
              stx       linebuff
:comment      lda       passnum
              beq       :rep
:comment1     lda       [lineptr],y
              tax
              lda       inputtbl,x
              cmp       #' '
              blt       :rep
              bne       :getcomment
              iny
              bra       :comment1
:getcomment   ldx       #$00
              sta       comment+1,x
              inx
              iny
:c1           lda       [lineptr],y
              phx
              tax
              lda       inputtbl,x
              plx
              cmp       #' '
              blt       :rep1
              sta       comment+1,x
              inx
              iny
              bra       :c1
:rep1         stx       comment
:rep          rep       $30
              lda       #linebuff+1
              sta       lineptr
              lda       #^linebuff
              sta       lineptr+2
:rep2         rep       $30
              lda       :deliminator
              and       #$ff
              beq       :rep3
              jmp       :err
:rep3         lda       :length
              and       #$ff
              sta       asclength
              plp
              clc
              rts

:special      rep       $30
              stz       :length
              stz       :orflag
              stz       :rightflag
              stz       :deliminator
              iny
:specloop     lda       [lineptr],y
              and       #$7f
              phx
              tax
              lda       inputtbl,x
              and       #$7f
              plx
              cmp       #' '+1
              jlt       :err
              cmp       #$27
              beq       :delim1
              cmp       #$22
              beq       :delim1
              cmp       #'>'
              beq       :right
              jmp       :eval
:right        bit       :rightflag
              jmi       :err
              sec
              ror       :rightflag
              iny
              jmp       :specloop
:delim1       ldx       :deliminator
              jne       :err
              sta       :deliminator
              iny
              jmp       :specloop
:eval         tyx
              lda       #$ffff
              sta       lableused
              jsr       eval
              bcc       :ok
              cmp       #undeflable
              jne       :sec
              jmp       :forward
:ok           bit       lableused
              bmi       :ok1
:forward      lda       #forwardref
              jmp       :sec
:ok1          lda       lvalue+2
              jne       :err
              stz       :flag
              lda       :rightflag
              beq       :setor
              sec
              ror       :flag
:setor        stz       :orflag
              lda       :deliminator
              and       #$ff
              cmp       #$22
              bne       :lv
              lda       #$80
              sta       :orflag
:lv           lda       lvalue
:nosign       ldy       #$00
              sty       :length
              stz       :zeroflag
:main         ldx       #$00
:1            cmp       :tbl,y
              blt       :11
              inx
              sec
              sbc       :tbl,y
              bra       :1
:11           phy
              pha
              txa
              cpy       #08
              bge       :pha
              cmp       #$00
              bne       :pha
              bit       :flag
              bpl       :snext
              bit       :zeroflag
              bmi       :pha
              lda       #$20
              jmp       :ora1
:pha          and       #$000f
              ora       #$30
              sec
              ror       :zeroflag
:ora1         ora       :orflag
              phx
              ldx       :length
              sta       ascstr,x
              inc       :length
              plx
              sec
              ror       :flag
:snext        pla
              ply
              iny
              iny
              cpy       #10
              blt       :main
              stz       :deliminator
              jmp       :done

:flag         ds        2
:tbl          dw        10000,1000,100,10,1
:digit        ds        2
:length       ds        2
:deliminator  ds        2
:orflag       ds        2
:rightflag    ds        2
:zeroflag     ds        2
:macflag      ds        2

              do        0
getasc1       php
              rep       $30
              lda       #$ffff
              sta       ascflag
              jmp       getasc2
getasc        php
              rep       $30
              stz       ascflag
getasc2       stz       asclength

              jsr       ascoperand

              sep       $20
:flush        lda       [lineptr],y
              and       #$7f
              cmp       #' '
              blt       :err
              bne       :start
              iny
              jmp       :flush
:err          rep       $30
              lda       #badoperand
:sec          rep       $30
              stz       asclength
              plp
              sec
              rts
              mx        %10

:start        stz       :length
              stz       :length+1
              bit       ascflag+1
              bpl       :loop
              cmp       #'#'
              jeq       :special
:loop         lda       [lineptr],y
              and       #$7f
              cmp       #' '+1
              jlt       :done
              cmp       #','
              jeq       :next
              cmp       #'$'
              beq       :hex0
              cmp       #'0'
              jlt       :delim
              cmp       #'9'+1
              blt       :hex
              cmp       #'a'
              blt       :check
              cmp       #'z'+1
              bge       :check
              and       #$5f
              jmp       :hex1
:check        cmp       #'A'
              blt       :err
              cmp       #'Z'+1
              blt       :hex1
              jmp       :err
:hex0         iny
              lda       [lineptr],y
              and       #$7f
              cmp       #'0'
              jlt       :err
              cmp       #'9'+1
              blt       :hex
              cmp       #'A'
              jlt       :err
              cmp       #'Z'+1
              blt       :hex1
              cmp       #'a'
              jlt       :err
              cmp       #'z'+1
              jge       :err
              and       #$5f
:hex1         sec
              sbc       #$37
              jmp       :hexdigit
:hex          sec
              sbc       #$30
:hexdigit     asl
              asl
              asl
              asl
              sta       :digit
              iny
              lda       [lineptr],y
              and       #$7f
              cmp       #'a'
              blt       :hd1
              cmp       #'z'+1
              jge       :err
              and       #$5f
              jmp       :hd2
:hd1          cmp       #'0'
              jlt       :err
              cmp       #'9'+1
              blt       :hd3
              cmp       #'A'
              jlt       :err
              cmp       #'F'+1
              blt       :hd2
              jmp       :err
:hd2          sec
              sbc       #$37
              jmp       :hd4
:hd3          sec
              sbc       #$30
:hd4          ora       :digit
              ldx       :length
              sta       ascstr,x
              inc       :length
              iny
              jmp       :loop
:delim        sta       :deliminator
              stz       :orflag
              cmp       #$27
              bge       :string
              lda       #$80
              sta       :orflag
:string       iny
              lda       [lineptr],y
              and       #$7f
              cmp       #' '
              blt       :done
              cmp       :deliminator
              beq       :next
              ldx       :length
              ora       :orflag
              sta       ascstr,x
              inc       :length
              jmp       :string
:next         iny
              jmp       :loop
:done         rep       $30
              lda       :length
              and       #$ff
              sta       asclength
              plp
              clc
              rts

:special      rep       $30
              stz       :orflag
              stz       :rightflag
              stz       :deliminator
              iny
:specloop     lda       [lineptr],y
              and       #$7f
              cmp       #' '+1
              jlt       :err
              cmp       #$27
              beq       :delim1
              cmp       #$22
              beq       :delim1
              cmp       #'>'
              beq       :right
              jmp       :eval
:right        bit       :rightflag
              jmi       :err
              sec
              ror       :rightflag
              iny
              jmp       :specloop
:delim1       ldx       :deliminator
              jne       :err
              sta       :deliminator
              iny
              jmp       :specloop
:eval         tyx
              jsr       eval
              bcc       :ok
              cmp       #undeflable
              jne       :sec
:ok           lda       lvalue+2
              jne       :err
              stz       :flag
              lda       :rightflag
              beq       :setor
              sec
              ror       :flag
:setor        stz       :orflag
              lda       :deliminator
              and       #$ff
              cmp       #$22
              bne       :lv
              lda       #$80
              sta       :orflag
:lv           lda       lvalue
:nosign       ldy       #$00
              sty       :length
              stz       :zeroflag
:main         ldx       #$00
:1            cmp       :tbl,y
              blt       :11
              inx
              sec
              sbc       :tbl,y
              bra       :1
:11           phy
              pha
              txa
              cpy       #08
              bge       :pha
              cmp       #$00
              bne       :pha
              bit       :flag
              bpl       :snext
              bit       :zeroflag
              bmi       :pha
              lda       #$20
              jmp       :ora1
:pha          and       #$000f
              ora       #$30
              sec
              ror       :zeroflag
:ora1         ora       :orflag
              phx
              ldx       :length
              sta       ascstr,x
              inc       :length
              plx
              sec
              ror       :flag
:snext        pla
              ply
              iny
              iny
              cpy       #10
              blt       :main
              jmp       :done

:flag         ds        2
:tbl          dw        10000,1000,100,10,1
:digit        ds        2
:length       ds        2
:deliminator  ds        2
:orflag       ds        2
:rightflag    ds        2
:zeroflag     ds        2
              fin
ascflag       ds        2
asclength     ds        2                                                     ;keep these two together
ascstr        ds        256,0                                                 ;as one is length word

              mx        %00
ascop         jsr       getasc1
              bcc       :ok
              rts
:ok           lda       passnum
              bne       :pass2
              lda       asclength
              and       #$FF
              jmp       incobjptr
:pass2        sep       $30
              ldx       asclength
              ldy       #$00
]lup          cpx       #$00
              beq       :clc
              lda       ascstr,y
              phx
              phy
              jsr       putbyte
              ply
              plx
              iny
              dex
              jmp       ]lup
:clc          rep       $31
              rts

              mx        %00
revop         jsr       getasc
              bcc       :ok
              rts
:ok           lda       passnum
              bne       :pass2
              lda       asclength
              and       #$FF
              jmp       incobjptr
:pass2        sep       $30
              ldx       asclength
]lup          cpx       #$00
              beq       :clc
              lda       ascstr-1,x
              phx
              jsr       putbyte
              plx
              dex
              jmp       ]lup
:clc          rep       $31
              rts

              mx        %00
invop         jsr       getasc
              bcc       :ok
              rts
:ok           lda       passnum
              bne       :pass2
              lda       asclength
              and       #$FF
              jmp       incobjptr
:pass2        sep       $30
              ldx       asclength
              ldy       #$00
]lup          cpx       #$00
              beq       :clc
              lda       ascstr,y
              phx
              phy
              and       #$7f
              cmp       #$40
              blt       :1
              cmp       #$60+1
              bge       :1
              sec
              sbc       #$40
:1            jsr       putbyte
              ply
              plx
              iny
              dex
              jmp       ]lup
:clc          rep       $31
              rts


              mx        %00
flsop         jsr       getasc
              bcc       :ok
              rts
:ok           lda       passnum
              bne       :pass2
              lda       asclength
              and       #$FF
              jmp       incobjptr
:pass2        sep       $30
              ldx       asclength
              ldy       #$00
]lup          cpx       #$00
              beq       :clc
              lda       ascstr,y
              phx
              phy
              and       #$7f
              cmp       #$40
              bge       :1
              clc
              adc       #$40
:1            jsr       putbyte
              ply
              plx
              iny
              dex
              jmp       ]lup
:clc          rep       $31
              rts


              mx        %00
mtxop         jsr       getasc
              bcc       :ok
              rts
:ok           lda       passnum
              bne       :pass2
              lda       asclength
              and       #$FF
              jmp       incobjptr
:pass2        sep       $30
              ldx       asclength
              ldy       #$00
]lup          cpx       #$00
              beq       :clc
              lda       ascstr,y
              phx
              phy
              and       #$1f
              ora       #$40
              jsr       putbyte
              ply
              plx
              iny
              dex
              jmp       ]lup
:clc          rep       $31
              rts




dciop         jsr       getasc
              bcc       :ok
              rts
:ok           lda       passnum
              bne       :pass2
              lda       asclength
              and       #$FF
              jmp       incobjptr
:pass2        sep       $30
              ldx       asclength
              beq       :clc
              lda       ascstr
              and       #$80
              sta       :orflag
              ldy       #$00
]lup          cpx       #$00
              beq       :clc
              lda       ascstr,y
              and       #$7f
              ora       :orflag
              cpx       #$01
              bne       :phx
              eor       #$80
:phx          phx
              phy
              jsr       putbyte
              ply
              plx
              iny
              dex
              jmp       ]lup
:clc          rep       $31
              rts
:orflag       ds        2



              mx        %00
hexop         rep       $30
              ldy       #$00
]flush        lda       [lineptr],y
              and       #$7F
              cmp       #$20
              blt       :err
              bne       hexop1
              iny
              beq       ]flush
:err          lda       #badoperand
              sec
              rts
hexop1        rep       $30
              tya
              and       #$00FF
              tay
              stz       hexcount
hexop2        sep       $30
              stz       :temp
:next         lda       [lineptr],y
              iny
              cmp       #$20+1
              blt       :done
              cmp       #','
              beq       :next
              cmp       #'0'
              blt       :err
              cmp       #'9'+$1
              blt       :num
              and       #$5F
              cmp       #'A'
              blt       :err
              cmp       #'F'+$1
              bge       :err
              sec
              sbc       #$37
              bra       :ok
:num          sec
              sbc       #$30
:ok           asl
              asl
              asl
              asl
              sta       :temp
              lda       [lineptr],y
              iny
              cmp       #$20+$1
              blt       :err
              cmp       #'0'
              blt       :err
              cmp       #'9'+1
              blt       :num1
              and       #$5F
              cmp       #'A'
              blt       :err
              cmp       #'F'+$1
              bge       :err
              sec
              sbc       #$37
              bra       :ok2
:num1         sec
              sbc       #$30
:ok2          ora       :temp
              ldx       passnum
              bne       :phy
              inc       hexcount
              bne       hexop2
              inc       hexcount+1
              jmp       hexop2
:phy          phy
              jsr       putbyte
              ply
              jmp       hexop2
:done         rep       $30
              ldy       passnum
              bne       :clc
              lda       hexcount
              jmp       incobjptr
:clc          clc
              rts
:err          rep       $30
              lda       #badoperand
              sec
              rts
:temp         ds        2
hexcount      ds        2

********************************
*  Print Formatting Psuedo0ops *
********************************

              mx        %00
astop         lda       passnum
              beq       :pass1
              lda       listflag+1
              bit       #$80
              beq       :pass1
              ldx       #$00
              jsr       eval
              bcc       :ok
              cmp       #undeflable
              bne       :sec1
              lda       #forwardref
:sec1         sec
              rts
:ok           ldal      tcursx
              and       #$ff
              cmp       #21
              bge       :ast
              lda       #' '
              jsr       drawchar
              jmp       :ok
:ast          lda       lvalue
              and       #$00FF
              tay
:loop         lda       #'*'
              phy
              jsr       drawchar
              ply
              dey
              bne       :loop
              lda       #$0D
              jsr       drawchar
              lda       #$80
              trb       listflag+1
:pass1        clc
              rts

              mx        %00
datop         rep       $30
              lda       #$80
              sta       :orflag
              ldy       #$00
              sep       $20
]lup          lda       [lineptr],y
              and       #$7f
              iny
              cmp       #' '
              blt       :zero
              beq       ]lup
              rep       $20
              ldx       #$00
              jsr       eval
              bcc       :v
              cmp       #undeflable
              bne       :sec1
              lda       #forwardref
:sec1         sec
              rts
:zero         rep       $20
              stz       lvalue
:v            bit       lableused
              bpl       :bo
              lda       lvalue
              cmp       #$09+1
              blt       :val
:bo           lda       #badoperand
              sec
              rts
:val          asl
              tax
              lda       :tbl,x
              sta       :jsr+1
:jsr          jsr       $ffff
              rts
:datop        lda       passnum
              beq       :pass1
              jsr       :convert

:dat          ldy       #$00
:loop         lda       :buffspace,y
              and       #$7F
              beq       :done
              sta       opcode+1,y
              iny
              jmp       :loop
*:done lda #$0d
* sta opcode+1,y
* iny
:done         sep       $20
              tya
              sta       opcode
              rep       $20
              stz       linebuff
:pass1        clc
              rts
:buffer       ds        24,0
:buffspace    asc       ' '
:buffer1      asc       '31-JAN-89  12:00:00 AM',00
:orflag       ds        2

:tbl          dw        :datop
              dw        :dat1
              dw        :dat2
              dw        :dat3
              dw        :dat4
              dw        :dat5
              dw        :dat6
              dw        :dat7
              dw        :dat8
              dw        :dat9
:dat5         stz       :orflag
              jmp       :dat1
:dat6         stz       :orflag
              jmp       :dat2
:dat7         stz       :orflag
              jmp       :dat3
:dat8         stz       :orflag
              jmp       :dat4
:dat1         lda       passnum
              beq       :d19
              jsr       :convert
:d19          ldy       #$00
]lup          lda       :buffer1,y
              and       #$7f
              ora       :orflag
              phy
              jsr       putbyte
              ply
              iny
              cpy       #$09
              blt       ]lup
              clc
              rts
:dat2         lda       passnum
              beq       :d29
              psl       #:buffer
              _ReadAsciiTime
:d29          ldy       #$00
]lup          lda       :buffer,y
              and       #$7f
              ora       :orflag
              phy
              jsr       putbyte
              ply
              iny
              cpy       #$08
              blt       ]lup
              clc
              rts
:dat3         lda       passnum
              beq       :d39
              jsr       :convert
:d39          ldy       #$00
]lup          lda       :buffer1,y
              and       #$7f
              ora       :orflag
              phy
              jsr       putbyte
              ply
              iny
              cpy       #22
              blt       ]lup
              clc
              rts
:dat4         lda       passnum
              beq       :d49
              psl       #:buffer
              _ReadAsciiTime
:d49          ldy       #$00
]lup          lda       :buffer,y
              and       #$7f
              ora       :orflag
              phy
              jsr       putbyte
              ply
              iny
              cpy       #20
              blt       ]lup
              clc
              rts

:dat9         lda       passnum
              beq       :d91
              pha
              pha
              pha
              pha
              _ReadTimeHex
              lda       1,s
              jsr       putbyte
              pla
              xba
              jsr       putbyte
              lda       1,s
              jsr       putbyte
              pla
              xba
              jsr       putbyte
              lda       1,s
              inc
              jsr       putbyte
              pla
              xba
              inc
              jsr       putbyte
              lda       #$00
              jsr       putbyte
              pla
              xba
              jsr       putbyte
              clc
              rts
:d91          ldy       #$00
]lup          lda       #$00
              phy
              jsr       putbyte
              ply
              iny
              cpy       #8
              blt       ]lup
              clc
              rts

:convert      php
              rep       $30
              pha
              pha
              pha
              pha
              _ReadTimeHex
              lda       1,s
              and       #$ff
              jsr       :num
              sta       :buffer1+17
              pla
              xba
              and       #$ff
              jsr       :num
              sta       :buffer1+14
              lda       1,s
              and       #$ff
              pha
              sep       $20
              cmp       #12
              bge       :pm
              lda       #'A'
              bra       :ampm
:pm           rep       $20
              lda       1,s
              sec
              sbc       #12
              sta       1,s
              sep       $20
              lda       #'P'
:ampm         sta       :buffer1+20
              rep       $20
              pla
              asl
              tax
              lda       :htbl,x
              sta       :buffer1+11
              pla
              xba
              and       #$ff
]y2k          cmp       #100
              bcc       :yy
              sbc       #100
              bne       ]y2k
:yy           jsr       :num
              sta       :buffer1+7
              lda       1,s
              and       #$ff
              inc
              jsr       :num
              sta       :buffer1+0
              pla
              xba
              and       #$ff
              pha
              asl
              clc
              adc       1,s
              plx
              plx
              tax
              lda       :montbl,x
              sta       :buffer1+3
              sep       $20
              inx
              inx
              lda       :montbl,x
              sta       :buffer1+5
              plp
              rts

:num          php
              rep       $30
              ldx       #'00'
              stx       :number
              sep       $20
]lup          cmp       #10
              blt       :one
              sec
              sbc       #10
              inc       :number
              jmp       ]lup
:one          cmp       #00
              beq       :numxit
              dec
              inc       :number+1
              jmp       :one
:numxit       rep       $20
              lda       :number
              plp
              rts
:number       ds        3

:htbl         asc       '12'
              asc       ' 1'
              asc       ' 2'
              asc       ' 3'
              asc       ' 4'
              asc       ' 5'
              asc       ' 6'
              asc       ' 7'
              asc       ' 8'
              asc       ' 9'
              asc       '10'
              asc       '11'
:montbl       asc       'JAN'
              asc       'FEB'
              asc       'MAR'
              asc       'APR'
              asc       'MAY'
              asc       'JUN'
              asc       'JUL'
              asc       'AUG'
              asc       'SEP'
              asc       'OCT'
              asc       'NOV'
              asc       'DEC'


              mx        %00
skpop         lda       passnum
              beq       :pass1
              lda       listflag+1
              bit       #$80
              beq       :pass1
              ldx       #$00
              jsr       eval
              bcc       :ok
              cmp       #undeflable
              bne       :sec1
              lda       #forwardref
:sec1         sec
              rts
:ok           lda       lvalue
              and       #$00FF
              tay
:loop         lda       #$0D
              phy
              jsr       drawchar
              ply
              dey
              bne       :loop
              lda       #$80
              trb       listflag+1
:pass1        clc
              rts

              mx        %00
ttlop         lda       passnum
              bne       :ttl
              clc
              rts
:ttl          ldy       #$00
              sty       titlestr
              lda       #$80
              trb       listflag+1
]flush        lda       [lineptr],y
              iny
              and       #$7F
              cmp       #' '
              blt       :xit
              beq       ]flush
              sta       :delim
:string       ldx       #$00
]loop         lda       [lineptr],y
              iny
              and       #$7F
              cmp       :delim
              beq       :done
              cmp       #' '
              blt       :err
              sta       titlestr+$1,X
              inx
              cpx       #$100
              blt       ]loop
:err          rep       $30
              lda       #badoperand
              sec
              rts
:done         txa
              sep       $30
              sta       titlestr
:xit          rep       $30
              clc
              rts

:delim        ds        2

              mx        %00
pagop         lda       passnum
              beq       :clc
              lda       listflag+1
              bit       #$80
              beq       :clc
              jmp       :ok
:clc          clc
              rts
:ok           lda       #$0C
              jsr       drawchar
              lda       #$80
              trb       listflag+1
              clc
              rts

              mx        %00
typop         lda       passnum
              bne       :ok
              clc
              rts
:ok           ldy       #$00
]lup          lda       [lineptr],y
              and       #$7f
              cmp       #' '
              blt       :bad
              bne       :start
              iny
              jmp       ]lup
:start        jsr       :check
              rep       $30
              bcc       :eval
              and       #$FF
              sta       lvalue
              jmp       :ok1
:eval         ldx       #$00
              jsr       eval
              bcc       :ok1
              cmp       #undeflable
              bne       :sec1
              lda       #forwardref
              jmp       :sec1
:bad          lda       #badoperand
              jmp       :sec1
:sec1         sec
              rts
:ok1          lda       lvalue
              and       #$00FF
              sta       objtype

              pea       0
              _QALinkerActive
              pla
              beq       :clc
              lda       lvalue
              and       #$ff
              pha
              _QASetObjType

:clc          clc
              rts

:check        sep       $30
              and       #$7f
              sta       :typ+1
              iny
              lda       [lineptr],y
              and       #$7f
              cmp       #' '+1
              blt       :chkbad
              sta       :typ+2
              iny
              lda       [lineptr],y
              and       #$7f
              cmp       #' '+1
              blt       :chkbad
              sta       :typ+3
              lda       #$03
              sta       :typ
              rep       $30
              pea       0
              psl       #:typ
              _QAConvertTxt2Typ
              pla
              bcc       :found
:chkbad       rep       $30
              clc
              rts
:found        rep       $30
              sec
              rts
:typ          ds        4

              do        floatingpoint
floop         lda       passnum
              bne       :p2
              ldy       #10
]lup          phy
              jsr       putbyte
              ply
              dey
              bne       ]lup
              clc
              rts
:p2           jsr       getasc
              bcc       :ok
              rts
:clc          clc
              rts
:ok           ldx       asclength
              beq       :clc
              sep       $20
]lup          lda       ascstr,x
              and       #$7f
              sta       ascstr,x
              dex
              bne       ]lup
              lda       asclength
              sta       ascstr-1
              rep       $20
              lda       #$01
              sta       :index
              psl       #ascstr-1
              psl       #:index
              psl       #:thedec
              psl       #:vp
              fpstr2dec
              psl       #:thedec
              psl       #:x
              fdec2x
              ldx       #0
]lup          lda       :x,x
              phx
              jsr       putbyte
              plx
              inx
              cpx       #10
              blt       ]lup
              clc
              rts
:index        ds        2
:vp           ds        2
:x            ds        10
:thedec       ds        33
              else
floop         lda       #badopcode
              sec
              rts
              fin

              mx        %00
xcop          php
              sep       $30
              ldy       #$00
]lup          lda       [lineptr],y
              and       #$7F
              cmp       #' '
              blt       :on
              beq       :iny
              and       #$5F
              cmp       #'F'
              beq       :off
              cmp       #'N'
              beq       :on
              cmp       #';'
              beq       :on
:iny          iny
              jmp       ]lup
:on           sec
              ror       xcflag
              plp
              clc
              rts
:off          lda       #$00
              sta       xcflag
              lda       #%11000000
              tsb       mxflag
              plp
              clc
              rts

              mx        %00
xcop1         sep       $30
              lda       xcflag
              and       #$C0
              asl
              sta       xcflag
              lda       #%11000000
              tsb       mxflag
              rep       $31
              rts

pauop         sep       $30
              lda       passnum
              beq       :xit
              lda       #$80
              trb       listflag+1
              rep       $30
              pea       0
              _QAKeyAvail
              pla
              beq       :key
              pha
              _QAGetChar
              pla
:key          sep       $30
              jsr       dokeypress
              bcc       :key
:xit          rep       $31
              rts

              mx        %00
belop         _SysBeep
              lda       #$80
              trb       listflag+1
              clc
              rts

              mx        %00
opcop         lda       passnum
              bne       :pass2
              lda       #$02
              jmp       incobjptr
:pass2        ldy       #$00
:flush        lda       [lineptr],y
              iny
              and       #$7F
              cmp       #' '
              blt       :err
              beq       :flush
              sta       :test
              iny
              iny
              iny
              iny
              lda       [lineptr],y
              and       #$7F
              cmp       :test
              bne       :err
              stz       :test
              dey
              dey
              dey
              dey
              sep       $30
              sty       :yval
              ldx       #$00
:add1         lda       [lineptr],y
              and       #$7F
              cmp       #' '+1                                                ; set carry bit if <> space
              rol       :test                                                 ; shift up
              inx
              iny
              cpx       #4
              blt       :add1                                                 ; not done yet.
              lda       :test
              cmp       #%1000                                                ; 1 char?
              beq       :ok                                                   ; yep.
              cmp       #%1100                                                ; 2 char?
              beq       :ok                                                   ; yep.
              cmp       #%1110                                                ; 3 char?
              beq       :ok
              cmp       #%1111                                                ; 4 char?
              beq       :ok                                                   ; good and fine

:err          rep       $30
              lda       #badoperand
              sec
              rts

              mx        %11
:ok           stz       :psop+1
              ldy       :yval
              lda       [lineptr],y
              asl
              asl
              asl                                                             ; x8
              sta       :psop+0
              iny
              lda       [lineptr],y
              lsr
              ror       :psop+1
              lsr
              ror       :psop+1
              and       #7
              ora       :psop+0
              sta       :psop+0
              iny
              lda       [lineptr],y
              and       #$1F
              asl
              ora       :psop+1
              pha
              iny
              lda       [lineptr],y
              iny
              iny
              sty       :yval
              tay
              pla
              cpy       #'L'
              beq       :o0                                                   ; carry set if equal
              cpy       #'l'                                                  ; same here.
              beq       :o0
              clc                                                             ; not equal.
:o0           adc       #0                                                    ; set b0 if "D" or 'd'
              sta       :psop+1
              lda       :psop+$1
              rep       $30
              jsr       putbyte
              lda       :psop
              jsr       putbyte

              jmp       :xit

              lda       reloffset
              sta       linerel
              stz       relout
              lda       :yval
              and       #$00FF
              tay
              lda       [lineptr],y
              and       #$7F
              cmp       #','
              beq       :iny
              cmp       #';'
              bne       :err1
:iny          iny
              tyx
              jsr       eval
              bcc       :okxit
              rts
:err1         lda       #badoperand
              sec
              rts
:okxit        stx       :yval
              lda       lvalue
              jsr       putbyte
              lda       lvalue+$1
              jsr       putbyte
              rep       $30
              jsr       relcorrect
              bcc       :ok3
              plp
              sec
              rts
:ok3          lda       :yval
              and       #$00FF
              tay
              lda       [lineptr],y
              and       #$7F
              cmp       #','
              beq       :iny2
              cmp       #';'
              bne       :err12
:iny2         iny
              tyx
              jsr       eval
              bcc       :okxit1
              rts
:err12        lda       #badoperand
              sec
              rts
:okxit1       stx       :yval
              lda       reloffset
              sta       linerel
              stz       relout

              lda       lvalue
              jsr       putbyte
              lda       lvalue+$1
              jsr       putbyte
              rep       $30
              jmp       relcorrect
:xit          rep       $30
              clc
              rts

:psop         hex       0000
:test         hex       0000
:yval         ds        2


              mx        %00
varop         lda       macflag
              and       #%01100000
              beq       :var
              lda       #badopcode
              sec
              rts
:var          lda       #$01
              sta       :number
              lda       #$00
              sta       :pos
              sep       $30
              ldy       #$00
]lup          lda       [lineptr],y
              iny
              and       #$7f
              cmp       #' '
              blt       :bad
              beq       ]lup
              cmp       #';'
              beq       :bad
              dey
              sty       :pos
              jmp       :loop
:bad          rep       $30
              lda       #badoperand
              sec
              rts
:loop         rep       $30
              lda       :number
              cmp       #$09
              jge       :xit
              and       #$7f
              ora       #$30
              sta       labstr+2
              lda       #$5d02
              sta       labstr
              lda       #$ffff
              sta       fllast
              jsr       findlable
              bcs       :eval
              stz       labnum
              stz       labval
              stz       labval+2
              lda       #$ffff
              sta       lableft
              sta       labright
              sta       lablocal
              sta       labprev
              jsr       insertlable
              stz       fllast
              dec       fllast
              bcc       :eval
              rts
:eval         ldy       #o_labnum
              lda       [lableptr],y
              sta       :label
              lda       #$ffff
              sta       lableused
              ldx       :pos
              jsr       eval
              stx       :pos
              bcc       :save
              rts
:save         lda       :label
              asl
              asl
              tay
              lda       [lableptr1],y
              sta       lableptr
              iny
              iny
              lda       [lableptr1],y
              sta       lableptr+2
              ldy       #o_labtype
              lda       [lableptr],y
              and       #$7FFF
              bit       lableused
              bpl       :rel
              ora       #absolutebit                                          ;**** CAN'T FORCE ALL EQU TO ABSOLUTE
:rel          sta       [lableptr],y
              iny
              iny
              lda       lvalue
              sta       [lableptr],y
              iny
              iny
              lda       lvalue+2
              sta       [lableptr],y
              ldy       :pos
]lup          lda       [lineptr],y
              iny
              and       #$7f
              cmp       #' '+1
              blt       :xit
              sty       :pos
              inc       :number
              jmp       :loop
:xit          rep       $31
              rts
:pos          ds        2
:number       ds        2
:label        ds        2

objop         clc                                                             ;do nothing opcode
              rts


errop         lda       passnum
              bne       :ok
:clc          clc
              rts
:ok           ldy       #$00
]lup          lda       [lineptr],y
              iny
              and       #$7f
              cmp       #' '
              blt       :bad
              beq       ]lup
              cmp       #';'
              beq       :bad
              cmp       #'('
              beq       :bad
              cmp       #'\'
              jeq       :relit
              jmp       :norel
:bad          lda       #badoperand
              sec
              rts
:norel        tyx
              dex
]lup          iny
              lda       [lineptr],y
              and       #$7f
              cmp       #' '+1
              blt       :norm
              cmp       #'('
              beq       :bad
              cmp       #')'
              beq       :bad
              bra       ]lup
:norm         jsr       eval
              bcc       :ok1
:sec1         sec
              rts
:ok1          lda       modeflag
              bit       #relflag
              beq       :ok2
              bit       lableused
              bmi       :ok2
              jmp       :badrel
:ok2          lda       lvalue
              ora       lvalue+$2
              beq       :clc
              lda       #usererror
              sec
              rts
:relit        lda       modeflag
              bit       #relflag
              bne       :enter
              tyx
              jmp       :norm
:enter        tyx
              lda       #$FFFF
              sta       lableused
              jsr       eval
              bcs       :sec1
              bit       lableused
              bpl       :badrel
              lda       errvalid
              beq       :first
              lda       lvalue+2
              and       #$ff
              sta       lvalue+2
              lda       erraddress+2
              cmp       lvalue+2
              blt       :eclc
              bne       :first
              lda       erraddress
              cmp       lvalue
              blt       :eclc
:first        lda       #$ffff
              sta       errvalid
              lda       lvalue
              sta       erraddress
              lda       lvalue+2
              and       #$ff
              sta       erraddress+2
:eclc         clc
              rts
:badrel       lda       #badrelative
              sec
              rts
:relfull      lda       #relfull
              sec
              rts

              mx        %00
symop         lda       #symflag
              tsb       modeflag1
              clc
              rts

