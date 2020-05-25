
              mx    %00

doop          stz   lvalue
              stz   lvalue+2
              lda   domask
              bpl   :ok
              lda   #nesterror
              sec
              rts
:ok           lda   dolevel
              bne   :set
              ldx   #$00
              jsr   eval
              bcc   :set
              cmp   #undeflable
              bne   :err
              lda   #forwardref
:err          sec
              rts
:set          lda   domask
              bne   :shift0
:shift1       sec
              rol   domask
              jmp   :test
:shift0       asl   domask
:test         lda   lvalue
              ora   lvalue+2
              beq   :dooff
              lda   domask
              trb   dolevel
              jmp   condout
:dooff        lda   domask
              tsb   dolevel
              jmp   condout

ifop          stz   lvalue
              stz   lvalue+2
              lda   domask
              bpl   :ok
              lda   #nesterror
              sec
              rts
:ok           lda   dolevel
              beq   :ok1
              jmp   :set
:ok1          lda   linebuff
              and   #$00ff
              bne   :test
:bad          rep   $30
              lda   #badoperand
              sec
:sec3         rep   $30
              rts
:test         stz   lvalue
              stz   lvalue+2
              sep   $30
              ldy   #$00
:flush        lda   (lineptr),y
              iny
              cmp   #' '
              blt   :bad
              beq   :flush
              cmp   #'M'
              beq   :mx
              cmp   #'m'
              beq   :mx
              cmp   #'X'
              beq   :xc1
              cmp   #'x'
              beq   :xc1
:save         sta   :first
              lda   (lineptr),y
              cmp   #' '+1
              blt   :bad
              iny
              lda   (lineptr),y
              cmp   #' '+1
              blt   :bad
              cmp   :first
              bne   :set
              inc   lvalue
:set          rep   $30
              lda   domask
              bne   :shift0
:shift1       sec
              rol   domask
              jmp   :test1
:xc1          jmp   :xc
:shift0       asl   domask
:test1        lda   lvalue
              ora   lvalue+2
              beq   :dooff
              lda   domask
              trb   dolevel
              jmp   condout
:dooff        lda   domask
              tsb   dolevel
              jmp   condout

              mx    %11
:mx           pha
              lda   (lineptr),y
              and   #$5f
              cmp   #'X'
              beq   :testmx
              pla
              bra   :save
:testmx       pla
              dey
              tyx
              lda   #ifflag
              tsb   modeflag+1
              jsr   eval
              pha
              php
              lda   #ifflag
              trb   modeflag+1
              plp
              pla
              bcc   :mxval
              cmp   #undeflable
              bne   :sec2
              lda   #forwardref
:sec2         rep   $30
              sec
              rts
:mxval        jmp   :set

              mx    %11
:xc           pha
              lda   [lineptr],y
              and   #$5f
              cmp   #'C'
              beq   :testxc
              pla
              jmp   :save
:testxc       pla
              dey
              tyx
              lda   #ifflag
              tsb   modeflag+1
              jsr   eval
              pha
              php
              lda   #ifflag
              trb   modeflag+1
              plp
              pla
              bcc   :set
              cmp   #undeflable
              bne   :sec1
              lda   #forwardref
:sec1         rep   $30
              sec
              rts
:first        ds    2



              do    0
***
ifop          lda   domask
              bpl   :ok
              lda   #nesterror
              sec
              rts
:ok           lda   dolevel
              bne   :set
              ldx   #$00
              jsr   eval
              bcc   :set
              cmp   #undeflable
              bne   :err
              lda   #forwardref
:err          rts
:set          lda   lvalue
              ora   lvalue+2
              beq   :dooff
              lda   domask
              trb   dolevel
              asl   domask
              jmp   condout
:dooff        lda   domask
              tsb   dolevel
              asl   domask
              jmp   condout
              fin

elseop        lda   domask
              eor   dolevel
              sta   dolevel
              jmp   condout

finop         lda   domask
              trb   dolevel
              lsr   domask
              jmp   condout

condout       lda   dolevel
              beq   :on
              lda   #doflag
              tsb   modeflag
              jmp   :setlist
:on           lda   #doflag
              trb   modeflag
:setlist      lda   #lstdoon
              bit   listflag+1
              beq   :clc
              lda   #$80
              trb   listflag+1
:clc          clc
              rts

macop         sep   $30
              lda   macflag
              and   #%01100000             ;if expanding either mactype
              beq   :mac
              rep   $30
              lda   #badopcode
              sec
              rts

              mx    %11

:mac          lda   #$40
              tsb   clrglob
              lda   #putflag
              bit   modeflag
              beq   :good
              pea   #badopcode
              jmp   :error
:good         lda   passnum
              jne   :p1
              lda   macflag
              bmi   :define

              lda   #doflag
              bit   modeflag
              beq   :rep

:define       lda   [fileptr]
              tax
              lda   inputtbl,x
              cmp   #' '+1
              blt   :bl
              cmp   #':'
              beq   :bl
              cmp   #']'
              beq   :bl
              ldy   #$00
              ldx   #$00
]l            lda   [fileptr],y
              phx
              tax
              lda   inputtbl,x
              plx
              cmp   #' '+1
              blt   :slab
              cpx   #lab_size
              bge   :siny
              sta   labstr+1,x
:siny         iny
              inx
              jmp   ]l
:slab         cpx   #lab_size+1
              blt   :slab1
              ldx   #lab_size
:slab1        stx   labstr
              lda   #$ff
              sta   linelable
              sta   linelable+1
              lda   macflag
              sta   :mflag
              rep   $20
              lda   oldglob
              sta   :old
              lda   globlab
              sta   :glob
              sep   $20
              stz   macflag
              jsr   defineall
              rep   $10
              ldy   :old
              sty   oldglob
              ldy   :glob
              sty   globlab
              sep   $10
              ldy   :mflag
              sty   macflag
              jcs   :err1
:rep          rep   $30
              lda   linelable
              bpl   :ok
:bl           pea   #badlable
              jmp   :error
:ok           asl
              asl
              tay
              lda   [lableptr1],y
              sta   lableptr
              iny
              iny
              lda   [lableptr1],y
              sta   lableptr+2

              lda   lablect
              cmp   #maxsymbols
              blt   :init
              pea   #symfull
              jmp   :error

:init         ldy   #o_labtype
              lda   #$8004
              sta   [lableptr],y
              ldy   #o_labval
              lda   nextlableptr
              sta   [lableptr],y
              tax
              ldy   #o_labval+2
              lda   nextlableptr+2
              sta   [lableptr],y
              sta   lableptr+2
              stx   lableptr

              lda   lablect
              asl
              asl
              tay
              lda   nextlableptr
              sta   [lableptr1],y
              iny
              iny
              lda   nextlableptr+2
              sta   [lableptr1],y
              ldy   #2
              lda   lastlen
              clc
              adc   fileptr
              tax
              lda   fileptr+2
              bcc   :sta
              inc
:sta          sta   [lableptr],y
              dey
              dey
              txa
              sta   [lableptr],y
              ldy   #4
              lda   #$0000
              sta   [lableptr],y
              ldy   #6
              sta   [lableptr],y
              ldy   #o_labtype
              sta   [lableptr],y
              jsr   inclablect
              bcs   :err1
:p1           sep   $20
              lda   #$80
              tsb   macflag
              rep   $30
              clc
              rts
:err1         rep   $30
              pha
:error        rep   $30
              pla
              sec
              rts
:mflag        ds    2
:old          ds    2
:glob         ds    2

pmcop         php
              sep   $30
              stz   :y
              stz   :y+1
              ldy   #$00
]lup          lda   [lineptr],y
              iny
              cmp   #' '
              blt   :err
              beq   ]lup
              dey
              ldx   #$00
]lup          lda   [lineptr],y
              cpx   #lab_size
              bge   :c1
              sta   labstr+1,x
:c1           cmp   #' '+1
              blt   :ok
              cmp   #','
              beq   :ok1
              cmp   #';'
              beq   :ok1
              inx
              iny
              cpx   #lab_size+1
              blt   ]lup
              bra   :ok
:ok1          iny
:ok           txa
              cmp   #lab_size+1
              blt   :ls
              lda   #lab_size
:ls           sta   labstr
              sty   :y
              sep   $30
              lda   macflag
              sta   :mflag
              stz   macflag
              jsr   findlable
              ldy   :mflag
              sty   macflag
* bcc :builtin ;not found so try built in macs
              bcc   :sec
              rep   $30
              ldy   #o_labtype
              lda   [lableptr],y
              cmp   #absolutebit.macrobit
              bne   :notmac
* bit expflag
* bmi :setup
* bvc :setup
* lda #$80
* trb listflag
:setup        sep   $30
              lda   macflag
              sta   :mflag
              lda   #$C1
              tsb   macflag
* sec
* ror lstobjflag
              ldy   :y
              sty   macvarpos
              stz   macvarpos+1
              jsr   initmac
              bcc   :clc
              ldy   :mflag
              sty   macflag
              plp
              sec
              rts
:clc          rep   $30
              plp
              clc
              rts
:sec          rep   $30
              stz   opcodeword
:err          rep   $30
              lda   #badlable
              plp
              sec                          ;return clear if handled opcode
              rts
:notmac       rep   $30
              lda   #notmacro
              plp
              sec                          ;return clear if handled opcode
              rts
:y            ds    2
:mflag        ds    2




eomop         sep   $30
              lda   macflag
              bmi   :ok
:bad          pea   #badopcode
              jmp   :error
:ok           bit   #%01100000
              beq   :define
              bit   #%00100000
              beq   :ext
              jmp   :internal
:ext          lda   maclevel
              and   #$ff
              beq   :bad
              jsr   pullmac
:rtn          sep   $30
              lda   #$FF
              jsr   setmaclist
              lda   maclevel
              bne   :noerror
              lda   #%01000000
              trb   macflag
:define       stz   maclevel
              lda   #%10000000
              trb   macflag
:noerror      pea   $00
:error        rep   $30
              pla
              cmp   #$01
              rts
:internal     rep   $30
              lda   imaclen
              sta   flen
              lda   imaclen+2
              sta   flen+2
              lda   imacptr
              sta   fileptr
              lda   imacptr+2
              sta   fileptr+2
              lda   imaclast
              sta   lastlen
              lda   #%00100000
              trb   macflag
              jmp   :rtn

definemacro
              sep   $30
              lda   opcode
              bne   :1
              rep   $30
              clc
              rts

:1            rep   $30
              jsr   hashopcode
              bcc   :test
              pha
              jsr   domac1
              pla
              bcc   :test
              clc
              rts

:test         hex   c9                     ;CMP 'EOM '
              usr   'EOM '
              beq   :eom
              hex   c9
              usr   '<<< '
              beq   :eom
              hex   c9
              usr   'MAC '                 ;CMP 'MAC '
              beq   :mac
:clcx         clc
              rts
:eom          jmp   eomop
:mac          lda   passnum
              bne   :clcx
              jmp   macop
:bad          rep   $30
              lda   #badlable
:sec          sec
              rts
;macstack definition
                                           ;0 = fileptr
;2 = fileptr+2
                                           ;4 = flen
                                           ;6 = flen+2
                                           ;8 = lastlen
                                           ;10 = mac lable num
                                           ;12 = num of variables
                                           ;14 = offset into macvars of var txt
;16.... same

initmac       php
              rep   $30
              lda   maclevel
              and   #$ff
              cmp   #macnestmax
              blt   :ok
              lda   #nesterror
              plp
              sec
              rts
:ok           asl
              asl
              asl
              asl
              asl
              tax
              lda   fileptr
              sta   macstack,x
              lda   fileptr+2
              sta   macstack+2,x
              lda   flen
              sta   macstack+4,x
              lda   flen+2
              sta   macstack+6,x
              lda   lastlen
              sta   macstack+8,x
              ldy   #o_labnum 
              lda   [lableptr],y
              sta   macstack+10,x

              stz   lastlen
              lda   #$FFFF
              sta   flen
              sta   flen+2

              ldy   #o_labval+2
              lda   [lableptr],y
              sta   workspace+2
              ldy   #o_labval
              lda   [lableptr],y
              sta   workspace
              ldy   #2
              lda   [workspace]
              sta   fileptr
              lda   [workspace],y
              sta   fileptr+2
              lda   passnum
              bne   :p1
              ldy   #04
              lda   [workspace],y
              inc
              sta   [workspace],y
              jmp   :get
:p1           ldy   #06
              lda   [workspace],y
              inc
              sta   [workspace],y
:get          jsr   getvars
              inc   maclevel
              lda   #$00
              jsr   setmaclist
              plp
              clc
              rts

setmaclist    php
              sep   $20
              cmp   #$00
              beq   :all
:eom          lda   linehaslab
              bne   :plp
              lda   #expflag
              bit   modeflag+1
              beq   :only
:all          lda   linehaslab
              bne   :plp
              lda   #exponly
              bit   modeflag+1
              beq   :plp
:only         lda   #$80
              trb   listflag+1
:plp          plp
              rts

macvarpos     ds    2

getvars

]where        =     workspace
]ct           =     ]where+2
]lit          =     ]ct+1
]done         =     ]lit+1

              php
              rep   $30

              lda   maclevel
              and   #$ff
              xba
              lsr                          ;quick * 128
              sta   ]where
              tax
              stz   :tbl                   ;init number
              sep   $20
              lda   #128
              sta   ]ct
              stz   ]lit
              stz   ]done
              ldy   macvarpos

:flush        lda   (lineptr),y
              cmp   #' '
              bne   :f0
              iny
              bra   :flush
:f0
              jlt   :move
              cmp   #';'
              jeq   :move

:first        cmp   #$22
              beq   :q
              cmp   #$27
              beq   :q

:loop
              sta   macvars,x
              dec   ]ct
              beq   :badvar
              iny
              inx

              lda   (lineptr),y
              cmp   #' '+1
              blt   :done
              cmp   #';'
              beq   :semi
              cmp   #$22
              beq   :q
              cmp   #$27
              beq   :q
              bra   :loop

:q            sta   ]lit
:qloop
              sta   macvars,x
              dec   ]ct
              beq   :badvar
              iny
              inx

              lda   (lineptr),y
              cmp   #' '
              blt   :done
              cmp   ]lit
              beq   :loop
              bra   :qloop

:done         sec
              ror   ]done
:semi         stz   macvars,x
              inx
              iny
              dec   ]ct
              rep   $20
              phx
              inc   :tbl
              lda   :tbl
              asl
              tax
              lda   ]where
              sta   :tbl,x
              plx
              stx   ]where
              lda   :tbl
              cmp   #$08
              bge   :move
              sep   $20
              lda   ]done
              bne   :move
              stz   ]lit
              lda   (lineptr),y
              cmp   #' '+1
              blt   :move
              jmp   :first
:badvar       rep   $30
              lda   #badoperand
              plp
              sec
              rts
:move         rep   $30
              lda   maclevel
              and   #$ff
              asl
              asl
              asl
              asl
              asl
              tax
              ldy   #$00
]lup          lda   :tbl,y
              sta   macstack+12,x
              iny
              iny
              inx
              inx
              cpy   #9*2
              blt   ]lup
:xit          plp
              clc
              rts
:tbl          ds    9*2

:print        php
              rep   $30
              phx
              phy
              pha
              jsr   drawchar
              pla
              ply
              plx
              plp
              rts
:printcr      php
              rep   $30
              phx
              phy
              pha
              lda   #'|'
              jsr   drawchar
              lda   #$0d
              jsr   drawchar
              sep   $20
:b999         ldal  $e0c010
              ldal  $e0c061
              bpl   :b999
              rep   $20
              pla
              ply
              plx
              plp
              rts


pullmac       php
              rep   $30
              dec   maclevel
              lda   maclevel
              and   #$ff
              asl
              asl
              asl
              asl
              asl
              tax
              lda   macstack,x
              sta   fileptr
              lda   macstack+2,x
              sta   fileptr+2
              lda   macstack+4,x
              sta   flen
              lda   macstack+6,x
              sta   flen+2
              lda   macstack+8,x
              sta   lastlen
              plp
              rts

expandmac     php
              rep   $30
              jmp   :init

:entry        sep   $20
              stz   linebuff
              stz   labstr
              stz   opcode
              stz   comment

              rep   $30
              stz   linehaslab
              lda   #$2020
              sta   opcode+1
              sta   opcode+3
              sta   opcode+5

:init
              lda   fileptr
              clc
              adc   lastlen
              sta   fileptr
              bcc   :prt
              inc   fileptr+2

:prt          lda   fileptr
              sta   printptr
              lda   fileptr+2
              sta   printptr+2

              stz   :errcode

              sep   $30
              ldy   #$00

              lda   [fileptr]
              tax
              lda   inputtbl,x
              cmp   #' '
              blt   :sjmp                  ;to savlen =>
              beq   :getopcode
              cmp   #'*'
              beq   :fjmp                  ;to flushiny =>
              cmp   #';'
              beq   :fjmp
              cmp   #':'                   ;is it a valid lable?
              bge   :glabel                ;yes...
:errbl        xba
              lda   #badlable
              sta   :errcode
              xba

:glabel       sta   labstr+1
              sta   linehaslab
              ldx   #$01
:gliny        iny
              lda   [fileptr],y
              phx
              tax
              lda   inputtbl,x
              plx
              cmp   #' '+1
              blt   :glabdone
              cmp   #'0'
              blt   :errbl1                ;bad lable
              cmp   #'<'
              blt   :cpx
              cmp   #'>'+1
              blt   :errbl1                ;"<=>" not allowed either..
:cpx          cpx   #lab_size
              bge   :gliny
              sta   labstr+1,x
              inx
              jmp   :gliny
:errbl1       pha
              lda   #badlable
              sta   :errcode
              pla
              jmp   :cpx
:fjmp         jmp   :flushiny
:sjmp         jmp   :savlen

:glabdone     cpx   #lab_size+1
              blt   :gl2
              ldx   #lab_size
:gl2          stx   labstr
              cmp   #' '
              bge   :getopcode
              jmp   :savlen

:getopcode
:giny         iny
              lda   [fileptr],y
              tax
              lda   inputtbl,x
              cmp   #' '
              blt   :sl1
              beq   :giny
              cmp   #';'
              jeq   :flushiny

              sta   opcode+1

              ldx   #$01
:goiny        iny
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

:sl1          jmp   :savlen
:fl1          jmp   :flushiny

:godone       cpx   #32
              blt   :go2
              ldx   #31
:go2          stx   opcode
              cmp   #' '
              blt   :sl1

:getoperand
:giny1        iny
              lda   [fileptr],y
              tax
              lda   inputtbl,x
              cmp   #' '
              blt   :sl1
              beq   :giny1
              cmp   #';'
              beq   :fl1

              dey
              ldx   #$00
              phx

:goiny1       iny
              lda   [fileptr],y
              phx
              tax
              lda   inputtbl,x
              plx
              cmp   #' '                   ;read in the rest of the line
              blt   :gotoper
              beq   :chklit
              cmp   #$27
              beq   :lit
              cmp   #$22
              beq   :lit
              jmp   :xba0
:chklit       xba
              lda   1,s
              bne   :xba1
              xba
              jmp   :gotoper
:lit          cmp   1,s
              beq   :litoff
              sta   1,s
              jmp   :cpx1
:litoff       xba
              lda   #$00
              sta   1,s
              jmp   :xba1
:xba0         xba
              lda   #doflag
              bit   modeflag
              bne   :xba1
              xba
              cmp   #']'
              bne   :cpx1
              xba
              iny
              lda   [fileptr],y
              phx
              tax
              lda   inputtbl,x
              plx
              cmp   #'0'
              blt   :xba
              beq   :number
              cmp   #'9'
              bge   :xba
              jmp   :expand
:number       phx
              rep   $30
              lda   maclevel
              and   #$ff
              dec
              asl
              asl
              asl
              asl
              asl
              tax
              lda   macstack+12,x
              sep   $30
              plx
              ora   #$30
              jmp   :cpx1
:xba          dey
:xba1         xba
:cpx1         cpx   #128
              bge   :goiny1
              sta   linebuff+1,x
              inx
              jmp   :goiny1

:gotoper      cpx   #128
              blt   :go3
              ldx   #128
:go3          stx   linebuff
              xba
              pla
              xba
              cmp   #' '
              blt   :savlen

:flushiny     ldx   passnum
              bne   :cp1
:cp0          iny
              lda   [fileptr],y
              tax
              lda   inputtbl,x
              cmp   #' '
              bge   :cp0
              jmp   :savlen
              bra   :cp0
:cp1          ldx   #$00
:cf1          lda   [fileptr],y
              phx
              tax
              lda   inputtbl,x
              plx
              cmp   #' '
              blt   :savcom
              bne   :c11
              iny
              bra   :cf1
:c11          lda   [fileptr],y
              phx
              tax
              lda   inputtbl,x
              plx
              cmp   #' '
              blt   :savcom
              iny
              cpx   #128
              bge   :c11
              sta   comment+1,x
              inx
              bra   :c11
:savcom       stx   comment
:savlen       iny
              sty   lastlen
              ldx   linebuff
              lda   #$0d
              sta   linebuff+1,x
              inc   linebuff

              lda   :errcode
              bne   :secxit
              lda   opcode                 ;was there an opcode?
              bne   :process
              jmp   :clcxit
                                           ;list the line if necessary

:process      sep   $30
              lda   opcode
              beq   :c1
              cmp   #$04
              blt   :p1
:c1           jmp   :clcxit
:p1           rep   $30
              jsr   hashopcode
              bcc   :noforce               ;not "forcelong"
              pha
              jsr   domac1
              pla
              bcs   :c1
:noforce      hex   c9                     ;CMP 'MAC '
              usr   'MAC '
              bne   :c1
              jmp   :entry

:clcxit       rep   $30
              lda   #$00
:secxit       rep   $30
              and   #$FF
              pha
              sep   $30
              lda   linebuff
              beq   :xit
              ldy   #$00
]lup          iny
              lda   linebuff,y
              cmp   #' '
              blt   :xit
              beq   ]lup
              cmp   #'#'
              beq   ]lup
              cmp   #'^'
              beq   :swap
              cmp   #'>'
              beq   :swap
              cmp   #'<'
              bne   :xit
:swap         iny
              xba
              lda   linebuff,y
              cmp   #'#'
              bne   :xit
              sta   linebuff-1,y
              xba
              sta   linebuff,y
              jmp   :swap
:xit          rep   $30
              pla
              plp
              cmp   :one
              rts
:one          dw    $01
:errcode      ds    2

:expand       phx
              phy
              rep   $30
              pha
              and   #$7f
              sec
              sbc   #'0'
              tay
              lda   maclevel
              and   #$ff
              dec
              asl
              asl
              asl
              asl
              asl
              tax
              tya
              cmp   macstack+12,x
              beq   :exok
              bge   :expbad
:exok         phx
              asl
              clc
              adc   1,s
              plx
              tax
              lda   macstack+12,x
              tay
              lda   4,s
              and   #$ff
              tax
              sep   $20
:exl          lda   macvars,y
              and   #$7f
              beq   :exgood
              cpx   #128
              bge   :xsta
:s1           sta   linebuff+1,x
              inx
:xsta         iny
              jmp   :exl
:exgood       rep   $30
              pla
              pla
              and   #$ff
              tay
              sep   $30
              jmp   :goiny1
:expbad       pla                          ;do not replace
              sep   $30
              ply
              plx
              jmp   :xba


hashopcode
              php
              pea   $00
              pea   $00
              rep   $30
              lda   opcode+$1
              xba
              sep   $30
              asl
              asl
              asl
              rep   $30
              asl
              asl
              asl
              sta   1,s
              lda   opcode+$4
              and   #$5F5F
              beq   :clc
              cmp   #$4C
              beq   :last
              cmp   #$4F44
              beq   :last
              sta   3,s
:clc          clc
:last         lda   opcode+$3
              and   #$1F
              rol
              ora   1,s
              plx
              plx
              bne   :sec
              plp
              clc
              rts
:sec          plp                          ;indicate "forcelong"
              sec
              rts

              mx    %00


lupbuffer     ds    16*maxlup,0

lupop         lda   luplevel
              cmp   #maxlup
              blt   :ok
              lda   #nesterror
              sec
              rts
:ok           ldx   #$00
              jsr   eval
              bcc   :start
              cmp   #undeflable
              bne   :sec
              lda   #forwardref
:sec          sec
              rts
:start        lda   lvalue
              ora   lvalue+2
              bne   :s1
              lda   #badoperand
              jmp   :sec
:s1           lda   #$80
              trb   listflag+1
              lda   luplevel
              asl
              asl
              asl
              asl
              tax
              lda   fileptr
              sta   lupbuffer,x
              lda   fileptr+2
              sta   lupbuffer+2,x
              lda   flen
              sta   lupbuffer+4,x
              lda   flen+2
              sta   lupbuffer+6,x
              lda   lastlen
              sta   lupbuffer+8,x
              lda   lvalue
              sta   lupbuffer+10,x
              lda   lvalue+2
              sta   lupbuffer+12,x
              lda   #lupflag
              tsb   modeflag
              inc   luplevel
              clc
              rts

lupend        lda   #lupflag
              bit   modeflag
              bne   :ok
              lda   #badopcode
              sec
              rts
:ok           lda   #$80
              trb   listflag+1
              lda   luplevel
              dec
              asl
              asl
              asl
              asl
              tax
              lda   lupbuffer+10,x
              bne   :dec
              lda   lupbuffer+12,x
              beq   :end
              dec   lupbuffer+12,x
:dec          dec   lupbuffer+10,x
              lda   lupbuffer+12,x
              ora   lupbuffer+10,x
              beq   :end
:cont         lda   lupbuffer,x
              sta   fileptr
              lda   lupbuffer+2,x
              sta   fileptr+2
              lda   lupbuffer+4,x
              sta   flen
              lda   lupbuffer+6,x
              sta   flen+2
              lda   lupbuffer+8,x
              sta   lastlen
              clc
              rts
:end          dec   luplevel
              bne   :clc
              lda   #lupflag
              trb   modeflag
:clc          clc
              rts


              do    0
lupstart      ds    4
luplen        ds    4
lupcount      ds    4
luplast       ds    2

lupop         lda   #lupflag
              bit   modeflag
              beq   :ok
              lda   #badopcode
              sec
              rts
:ok           ldx   #$00
              jsr   eval
              bcc   :start
              cmp   #undeflable
              bne   :sec
              lda   #forwardref
:sec          sec
              rts
:start        lda   lvalue
              ora   lvalue+2
              bne   :s1
              lda   #badoperand
              jmp   :sec
:s1           lda   #$80
              trb   listflag+1
              lda   fileptr
              sta   lupstart
              lda   fileptr+2
              sta   lupstart+2
              lda   flen
              sta   luplen
              lda   flen+2
              sta   luplen+2
              lda   lastlen
              sta   luplast
              lda   lvalue
              sta   lupcount
              lda   lvalue+2
              sta   lupcount+2
              lda   #lupflag
              tsb   modeflag
              clc
              rts

lupend
              lda   #lupflag
              bit   modeflag
              bne   :ok
              lda   #badopcode
              sec
              rts
:ok           lda   #$80
              trb   listflag+1
              lda   lupcount
              bne   :dec1
              dec   lupcount+2
:dec1         dec
              sta   lupcount
              ora   lupcount+2
              bne   :loop
              lda   #lupflag
              trb   modeflag
              clc
              rts
:loop         lda   lupstart
              sta   fileptr
              lda   lupstart+2
              sta   fileptr+2
              lda   luplen
              sta   flen
              lda   luplen+2
              sta   flen+2
              lda   luplast
              sta   lastlen
              clc
              rts
              fin

checklup      php
              rep   $30
              lda   luplevel
              beq   :xit
              dec
              asl
              asl
              asl
              asl
              tax
              lda   lupbuffer+10,x
              sta   :count
              sep   $30
              lda   labstr
              beq   :opc
              tax
:lab          lda   labstr,x
              cmp   #'@'
              bne   :dex1
              clc
              adc   :count
              sta   labstr,x
:dex1         dex
              bne   :lab

:opc          lda   opcode
              beq   :operand
              tax
:opc1         lda   opcode,x
              cmp   #'@'
              bne   :dex2
              clc
              adc   :count
              sta   opcode,x
:dex2         dex
              bne   :opc1
:operand      lda   linebuff
              beq   :xit
              tax
:oper1        lda   linebuff,x
              cmp   #'@'
              bne   :dex3
              clc
              adc   :count
              sta   linebuff,x
:dex3         dex
              bne   :oper1
:xit          plp
              rts
:count        ds    2

macinsert

]ct           equ   workspace
]offset       equ   ]ct+$2
]pos          equ   ]offset+$2
]pos1         equ   ]pos+$2
]len1         equ   ]pos1+$2
]len2         equ   ]len1+$2
]ptr          equ   ]len2+2

:entry        php
              rep   $30
              lda   #$0020
              sta   labtype
              lda   lablect
              cmp   #maxsymbols            ;max number of lables
              blt   :ne0
:full         lda   #symfull               ;symtable full
              jmp   :error
:ne0          lda   macvarptr
              cmp   #macsize
              bge   :full
:ne1          lda   labstr
              and   #$FF
              bne   :ne2
:bad          lda   #badlable
              jmp   :error
:ne2          sta   ]len1
              lda   labstr+$1              ;first byte of string
              and   #$7F
              cmp   #':'                   ;local lable?
              beq   :bad
* cmp #']' ;can't allow variables because
* beq :bad ;of parameter passing
              lda   maclevel
              dec
              and   #$ff
              asl
              asl
              asl
              asl
              asl
              sta   :offset
              tax
              lda   macstack+10,x
              asl
              asl
              tay
              lda   [lableptr1],y
              sta   lableptr
              iny
              iny
              lda   [lableptr1],y
              sta   lableptr+2
              ldy   #o_labval
              lda   [lableptr],y
              sta   ]ptr
              ldy   #o_labval+2
              lda   [lableptr],y
              sta   ]ptr+2
              ldy   #$04
              lda   passnum
              beq   :py2
              ldy   #$06
:py2          lda   []ptr],y
              sta   :count
              ldy   #o_lablocal
              lda   [lableptr],y
              jpl   :start
              lda   macstack+10,x
              bra   :ne3
:udf          lda   #undeflable
              jmp   :error
:ne3          sta   ]pos
              sta   labprev
              ldy   #o_lablocal
              lda   lablect
              sta   [lableptr],y           ;set local ptr for GLable
:save         rep   $30
              jsr   :saveit
              bcc   :nosave
              plp
              sec
              rts
:nosave       lda   #$00
              plp
              clc
              rts
:start        sta   ]pos
]lup          lda   ]pos
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
              ldx   #$02                   ;start at byte 2
              txy
]lup1         cpx   #lab_size+1
              jeq   :error2
              cpx   ]len1
              blt   :1
              beq   :1
              jmp   :goleft1
:1            cpx   ]len2
              blt   :2
              beq   :2
              jmp   :goright
:2            lda   [lableptr],y
              cmp   labstr,x
              bne   :next
              iny
              inx
              jmp   ]lup1
:next         rep   $30
              blt   :goright
              jmp   :goleft
:goleft1      rep   $30
              lda   ]len1
              cmp   ]len2
              bne   :goleft
:replace      ldy   #o_labprev                    ;offset to equ value
              lda   [lableptr],y
:rl           tay
              iny
              iny
              lda   [macptr],y
              cmp   :count
              beq   :r1
              dey
              dey
              lda   [macptr],y
              bpl   :rl
:rs           lda   macvarptr
              sta   [macptr],y
              tay
              lda   #$ffff
              sta   [macptr],y
              iny
              iny
              lda   :count
              sta   [macptr],y
              iny
              iny
              lda   labval
              sta   [macptr],y
              iny
              iny
              lda   labval+2               ;replace equate
              sta   [macptr],y
              iny
              iny
              sty   macvarptr
              jmp   :nosave
:r1           iny
              iny
              lda   labval
              sta   [macptr],y
              iny
              iny
              lda   labval+2               ;replace equate
              sta   [macptr],y
              jmp   :nosave
:goleft       rep   $30
              ldy   #o_lableft             ;leftptr
              lda   [lableptr],y
              bpl   :p1
              lda   lablect
              sta   [lableptr],y
              jmp   :save
:p1           sta   ]pos
              jmp   ]lup
:goright      rep   $30
              ldy   #o_labright            ;rightptr
              lda   [lableptr],y
              bpl   :p2
              lda   lablect
              sta   [lableptr],y
              jmp   :save
:p2           sta   ]pos
              jmp   ]lup
:error2       rep   $30
              lda   #badlable
:error        plp
              sec
              rts
:saveit       sta   labnum
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
              ora   dumor                  ;#$8000
              sta   labtype
:si1          lda   #$FFFF
              sta   lableft
              sta   labright
              sta   lablocal

              ldy   macvarptr
              lda   #$ffff
              sta   [macptr],y
              iny
              iny
              lda   :count
              sta   [macptr],y
              iny
              iny
              lda   labval
              sta   [macptr],y
              iny
              iny
              lda   labval+2
              sta   [macptr],y
              iny
              iny
              lda   macvarptr
              sta   labprev
              sty   macvarptr

              pla
              sta   ]pos                   ;for movefound
              asl
              asl
              tay
              lda   nextlableptr
              sta   [lableptr1],y
              sta   lableptr
              pha                          ;for mvn below
              iny
              iny
              lda   nextlableptr+2
              sta   [lableptr1],y
              sta   lableptr+2
              sep   $20
              sta   :mvn+1
              rep   $20
              ply                          ;low of destination
              tdc
              clc
              adc   #labstr
              tax                          ;source low word
              lda   #sym_size-1            ;MVN
              phb
:mvn          mvn   $000000,$000000
              plb
              jsr   inclablect
              rts
:offset       ds    2
:count        ds    2

macfind

]ct           equ   workspace
]offset       equ   ]ct+$2
]pos          equ   ]offset+$2
]pos1         equ   ]pos+$2
]len1         equ   ]pos1+$2
]len2         equ   ]len1+$2

:entry        php
              sep   $30
:normal       lda   modeflag
              and   #caseflag
              beq   :macentry
              jsr   caselable
:macentry     stz   labtype
              stz   labtype+1
              lda   lablect
              ora   lablect+1
              jeq   :notfound
              lda   labstr
              jeq   :notfound
              sta   ]len1
              stz   ]len1+1
              lda   maclevel
              sta   :lev
              stz   :lev+1
:loop         rep   $30
              lda   :lev
              beq   :notfound
              dec
              asl
              asl
              asl
              asl
              asl
              tax
              lda   macstack+10,x
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
              jmi   :nf1
              sta   ]pos
              ldy   #o_labval
              lda   [lableptr],y
              tax
              ldy   #o_labval+2
              lda   [lableptr],y
              sta   lableptr+2
              stx   lableptr
              ldy   #$04
              ldx   passnum
              beq   :noinx
              ldy   #$06
:noinx        lda   [lableptr],y
              sta   :count
:gloop
]lup          lda   ]pos
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
              and   #$0f
              sta   ]len2
              sep   $20
              ldx   #$02                   ;start at byte 2
              txy
]lup1         cpx   #lab_size+1
              bge   :movefound
              cpx   ]len1
              blt   :1
              beq   :1
              jmp   :goleft1
:notfound     plp
              clc
              rts
:1            cpx   ]len2
              blt   :2
              beq   :2
              jmp   :goright
:2            lda   labstr,x
              cmp   [lableptr],y
              bne   :next
              iny
              inx
              jmp   ]lup1
:next         blt   :goleft
              jmp   :goright
:goleft1      lda   ]len1
              cmp   ]len2
              beq   :movefound
:goleft       rep   $30
              ldy   #o_lableft
              lda   [lableptr],y
              bmi   :nf1
              sta   ]pos
              jmp   ]lup
:goright      rep   $30
              ldy   #o_labright
              lda   [lableptr],y
              bmi   :nf1
              sta   ]pos
              jmp   ]lup
:nf1          rep   $30
              dec   :lev
              jmp   :loop
:movefound    rep   $30
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
              ldy   #o_labprev
              lda   [lableptr],y
:lup          tay
              iny
              iny
              lda   [macptr],y
              cmp   :count
              beq   :valfound
              dey
              dey
              lda   [macptr],y
              bpl   :lup
              jmp   :nf1
:valfound     iny
              iny
              lda   [macptr],y
              tax
              iny
              iny
              lda   [macptr],y
              ldy   #o_labval+2
              sta   [lableptr],y
              txa
              ldy   #o_labval
              sta   [lableptr],y
              plp
              sec
              rts
:count        ds    2
:lev          ds    2

imacptr       ds    4
imaclen       ds    4
imaclast      ds    4

expandint     php
              rep   $30
              lda   fileptr
              clc
              adc   lastlen
              sta   fileptr
              bcc   :prt
              inc   fileptr+2

:prt          lda   fileptr
              sta   printptr
              lda   fileptr+2
              sta   printptr+2

              sep   $30
              ldy   #$00

              lda   [fileptr]
              tax
              lda   inputtbl,x
              cmp   #' '
              blt   :sjmp                  ;to savlen =>
              beq   :getopcode
              cmp   #'*'
              beq   :fjmp                  ;to flushiny =>
              cmp   #';'
              beq   :fjmp
:errbl        lda   #badlable
              jmp   :errflush
:fjmp         jmp   :flushiny
:sjmp         jmp   :savlen

:getopcode
:giny         iny
              lda   [fileptr],y
              tax
              lda   inputtbl,x
              cmp   #' '
              blt   :sl1
              beq   :giny
              cmp   #';'
              jeq   :flushiny

              and   tbxand
              sta   opcode+1

              ldx   #$01
:goiny        iny
              lda   [fileptr],y
              phx
              tax
              lda   inputtbl,x
              plx
              cmp   #' '+1
              blt   :godone
              cpx   #31
              bge   :goiny
              and   tbxand
              sta   opcode+1,x
              inx
              jmp   :goiny

:sl1          jmp   :savlen
:fl1          jmp   :flushiny

:godone       cpx   #32
              blt   :go2
              ldx   #31
:go2          stx   opcode
              cmp   #' '
              blt   :sl1

:getoperand
:giny1        iny
              lda   [fileptr],y
              tax
              lda   inputtbl,x
              cmp   #' '
              blt   :sl1
              beq   :giny1
              cmp   #';'
              beq   :fl1

              dey
              ldx   #$00
              phx
:goiny1       iny
              lda   [fileptr],y
              phx
              tax
              lda   inputtbl,x
              plx
              cmp   #' '                   ;read in the rest of the line
              blt   :gotoper
              beq   :chklit
              cmp   #$27
              beq   :lit
              cmp   #$22
              beq   :lit
              jmp   :xba0
:chklit       xba
              lda   1,s
              bne   :xba1
              xba
              jmp   :gotoper
:lit          cmp   1,s
              beq   :litoff
              sta   1,s
              jmp   :cpx1
:litoff       xba
              lda   #$00
              sta   1,s
              jmp   :xba1
:xba0         xba
              lda   #doflag
              bit   modeflag
              bne   :xba1
              xba
              cmp   #']'
              bne   :cpx1
              xba
              iny
              lda   [fileptr],y
              phx
              tax
              lda   inputtbl,x
              plx
              cmp   #'0'
              blt   :xba
              beq   :number
              cmp   #'9'
              bge   :xba
              jmp   :expand
:number       phx
              rep   $30
              lda   #macnestmax+1
              dec
              asl
              asl
              asl
              asl
              asl
              tax
              lda   macstack+12,x
              sep   $30
              plx
              ora   #$30
              jmp   :cpx1
:xba          dey
:xba1         xba
:cpx1         cpx   #128
              bge   :goiny1
              sta   linebuff+1,x
              inx
              jmp   :goiny1

:gotoper      cpx   #128
              blt   :go3
              ldx   #128
:go3          stx   linebuff
              xba
              pla
              xba
              cmp   #' '
              blt   :savlen

:flushiny     ldx   passnum
              bne   :cp1
:cp0          iny
              lda   [fileptr],y
              tax
              lda   inputtbl,x
              cmp   #' '
              bge   :cp0
              jmp   :savlen
              bra   :cp0
:cp1          ldx   #$00
:c11          lda   [fileptr],y
              phx
              tax
              lda   inputtbl,x
              plx
              cmp   #' '
              blt   :savcom
              iny
              cpx   #128
              bge   :c11
              sta   comment+1,x
              inx
              bra   :c11
:savcom       stx   comment
:savlen       iny
              sty   lastlen
              ldx   linebuff
              lda   #$0d
              sta   linebuff+1,x
              inc   linebuff


              lda   opcode                 ;was there an opcode?
              bne   :process
              jmp   :clcxit
                                           ;list the line if necessary

:errflush     pha                          ;we got an error somewhere..before
]f            iny                          ;we got to the EOLN...so we must
              lda   [fileptr],y            ;flush it out
              tax
              lda   inputtbl,x
              cmp   #' '
              bge   ]f
              iny
              sty   lastlen
              ldx   linebuff               ;put a <CR> at end anyway
              lda   #$0d
              sta   linebuff+1,x
              inc   linebuff
              pla                          ;restore the error code
              jmp   :secxit

:process
:clcxit       rep   $30
              lda   #$00
:secxit       rep   $30
              pha
              sep   $30
              lda   linebuff
              beq   :xit
              ldy   #$00
]lup          iny
              lda   linebuff,y
              cmp   #' '
              blt   :xit
              beq   ]lup
              cmp   #'#'
              beq   ]lup
              cmp   #'^'
              beq   :swap
              cmp   #'>'
              beq   :swap
              cmp   #'<'
              bne   :xit
:swap         iny
              xba
              lda   linebuff,y
              cmp   #'#'
              bne   :xit
              sta   linebuff-1,y
              xba
              sta   linebuff,y
              jmp   :swap
:xit          rep   $30
              pla
              plp
              cmp   :one
              rts
:one          dw    $01

:expand       phx
              phy
              rep   $30
              pha
              and   #$7f
              sec
              sbc   #'0'
              tay
              lda   #macnestmax+1
              dec
              asl
              asl
              asl
              asl
              asl
              tax
              tya
              cmp   macstack+12,x
              beq   :exok
              bge   :expbad
:exok         phx
              asl
              clc
              adc   1,s
              plx
              tax
              lda   macstack+12,x
              tay
              lda   4,s
              and   #$ff
              tax
              sep   $20
:exl          lda   macvars,y
              and   #$7f
              beq   :exgood
              cpx   #128
              bge   :xsta
:s1           sta   linebuff+1,x
              inx
:xsta         iny
              jmp   :exl
:exgood       rep   $30
              pla
              pla
              and   #$ff
              tay
              sep   $30
              jmp   :goiny1
:expbad       pla                          ;do not replace
              sep   $30
              ply
              plx
              jmp   :xba


initinternal  rep   $30
              sta   :low+1
              stx   :high+1
              lda   macflag
              bit   #%00100000
              beq   :ok
              lda   #badmacro
              sec
              rts
:ok           lda   fileptr
              sta   imacptr
              lda   fileptr+2
              sta   imacptr+2
              lda   lastlen
              sta   imaclast
              lda   flen
              sta   imaclen
              lda   flen+2
              sta   imaclen+2
              lda   #%10100001
              tsb   macflag
:high         lda   #$FFFF
              sta   fileptr+2
:low          lda   #$FFFF
              sta   fileptr
              stz   lastlen
              lda   #$ffff
              sta   flen
              sta   flen+2
              lda   maclevel
              pha
              lda   #macnestmax
              sta   maclevel
              stz   macvarpos
              jsr   getvars
              pla
              sta   maclevel
              lda   #$00
              jsr   setmaclist
              clc
              rts

