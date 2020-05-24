noop          =     %0000_0000_0000_0000
rightbrace    =     %0100_0001_0000_0001
gt            =     %1000_0010_0001_0010
lt            =     %1000_0011_0010_0010
eq            =     %1000_0100_0100_0010
noteq         =     %1000_0101_1000_0010
plusop        =     %1000_0110_0000_0011
minusop       =     %1000_0111_0000_0011
multop        =     %1000_1000_0000_0100
divop         =     %1000_1001_0000_0100
modop         =     %1000_1010_0000_0100
evandop       =     %1000_1011_0000_0101
evorop        =     %1000_1100_0000_0101
eveorop       =     %1000_1101_0000_0101
negateop      =     %0010_1110_0000_0110
leftbrace     =     %0100_1111_0000_0111

levelmask     =     %0000_0000_0000_1111
flagmask      =     %0000_0000_1111_0000
mask          =     %1111_1111_1111_0000
bracemask     =     %0100_0000_0000_0000
negatemask    =     %0010_0000_0000_0000

eval          php
              rep   $30
              txa
              and   #$ff
              tax
              sep   $20
              ldy   #$00
              sty   evalrelok
              sty   shiftct
              sty   evallevel
              stz   notfound               ;8 bit value
              sty   lvalue
              sty   lvalue+2
              sty   noshift
              sty   noshift+2
              lda   #$ffff
              sta   lableused
              stx   offset                 ;save our offset
              txy                          ;put starting offset in Y
              sep   $20
]lup          lda   (lineptr),y
              cmp   #' '                   ;flush out all leading spaces
              blt   :badop1
              bne   :start
              iny
              jmp   ]lup
:badop1       pea   #badoperand            ;push error code on stack
              jmp   :error

:imedflag     ds    2

:start        ldx   #%00001111
              stx   :imedflag
:start1       cmp   #'#'                   ;check for
              beq   :nexty0
              cmp   #','
              beq   :nexty1
              cmp   #'('
              beq   :nexty
              cmp   #'['
              beq   :nexty
              jmp   :shiftop
:nexty0       rol   :imedflag
:nexty1       iny
              lda   (lineptr),y
              cmp   #' '+1
              blt   :badop1
              jmp   :start1
:nexty        iny
              lda   (lineptr),y
              cmp   #' '+1
              blt   :badop1
:shiftop      xba
              lda   :imedflag
              bit   #%00010000
              beq   :nshift
              xba
              bit   :imedflag
              bvs   :main1
              cmp   #'^'
              beq   :shift16
              cmp   #'<'
              beq   :shift0
              cmp   #'>'
              beq   :shift8
              jmp   :main1
:nshift       xba
              cmp   #'|'
              beq   :shift0
              cmp   #'!'
              beq   :shift0
              cmp   #'>'
              beq   :shift0
              cmp   #'<'
              beq   :shift0
              jmp   :main1
:shift8       lda   #8
              sta   shiftct
              jmp   :shift0
:shift16      lda   #16
              sta   shiftct
:shift0       iny
:main         lda   (lineptr),y
              cmp   #' '+1
              blt   :badop1
:main1        rep   $20
              stz   xreg
              stz   yreg
              stz   xreg+2
              stz   yreg+2
              stz   estack
              stz   op
              stz   top
              stz   bracevalid
              lda   #$ffff
              sta   xrel
              sta   yrel
              sta   zrel
              sty   offset
              lda   #$8000
              sta   number

:loop         rep   $30
              ldy   offset
              jsr   getnum
              bcc   :4
              sta   :err+1
              jmp   :err
:4            sty   offset
              bvc   :operand

:number       bit   number
              bmi   :numok
              pea   #badoperand
              jmp   :error
:numok        lsr   number
              ldy   evallevel
              beq   :numsta
              sec
              ror   bracevalid             ;left braces no longer valid
:numsta       sta   xreg                   ;save the values in the x register
              stx   xreg+2
              lda   zrel
              sta   xrel
              jmp   :loop                  ;go back for more

:operand      cmp   #noop                  ;no operation OK
              beq   :opok

              bit   #bracemask
              beq   :chk

              cmp   #leftbrace
              bne   :r

              bit   bracevalid
              bpl   :opok
              pea   #badopchar
              jmp   :error

:r            cmp   #rightbrace
              bne   :chk

              bit   bracevalid
              bmi   :opok
              pea   #badopchar
              jmp   :error

:chk          bit   number                 ;are we expecting an operand?
              bpl   :opok

              cmp   #negateop              ;we can get a NEGATE op if
              beq   :opok                  ;waiting for a number

              pea   #badoperand
              jmp   :error

:opok         sta   top                    ;store in temporary op

              and   #$8000                 ;should we shift brace flag
              beq   :testops               ;and number flag?
              lsr   bracevalid             ;clear high bit
              sec
              ror   number                 ;set high bit

:testops      bit   evalrelok
              bpl   :check
              jmp   :alldone               ;error will be found by xit routine

:check        ldx   evallevel
              bne   :test
              lda   top
              and   #bracemask.negatemask
              bne   :test
              jmp   :l2r
:test         lda   top
              beq   :checkstack
:test1        lda   op
              and   #levelmask
              sta   opmask
              lda   top
              and   #levelmask
              cmp   opmask
              blt   :checkstack
              beq   :eqexecute

:push         jsr   pushstack
              bcc   :push1
              sta   :err+1
              jmp   :err
:push1        lda   top
              cmp   #leftbrace
              bne   :push2
              stz   xreg
              stz   xreg+2
              lda   #$ffff
              sta   xrel
              inc   evallevel
              lda   #rightbrace
              sta   top
:push2        lda   top
              sta   op
              lda   xreg
              sta   yreg
              lda   xreg+2
              sta   yreg+2
              lda   xrel
              sta   yrel
              jmp   :loop
:eqexecute    lda   op
              beq   :push2
              cmp   #rightbrace
              beq   :pulllevel
              cmp   #negateop
              beq   :push
              jsr   execute
              jmp   :push2                 ;lda top
:pulllevel    jsr   execute
              dec   evallevel
              jsr   pullstack
              jcc   :loop
              pha
              jmp   :error

:l2r          lda   op
              beq   :noexec                ;anything to do?
              jsr   execute
:noexec       lda   top
              bne   :push2
              jmp   :noexec1

:checkstack
              lda   op
              beq   :noexec1
              jsr   execute
:noexec1      lda   estack
              beq   :checkdone
              jsr   pullstack
              bcc   :pull1
              sta   :err+1
              jmp   :err
:pull1        lda   op
              cmp   #negateop
              beq   :checkstack
              jmp   :testops

:checkdone    stz   op
              lda   top
              beq   :alldone
              jmp   :loop
:alldone      bit   evalrelok
              bpl   :done1
              pea   #badrelative
              jmp   :error
:done1        lda   evallevel
              beq   :store
              lda   #badoperand
              jmp   :errplp
:store        lda   xreg
              sta   noshift
              sta   lvalue
              lda   xreg+2
              sta   lvalue+2
              sta   noshift+2
              lda   xrel
              sta   lableused
              ldx   shiftct
              beq   :noerr
]lup          lsr   lvalue+2
              ror   lvalue
              dex
              bne   ]lup
:noerr        rep   $30
              lda   #$00
              jmp   :errplp
:err          pea   $0000
:error        rep   $30
:errpla       pla
:errplp       rep   $30
              bit   notfound-1
              bpl   :getx
              lda   #undeflable
:getx         ldx   offset
              and   #$ff
              plp
              cmp   :one
              rts
:one          dw    $01


execute       php
              rep   $30
              lda   op
              and   #flagmask
              beq   :noflags
              plp
              jmp   doflags
:noflags      lda   op
              xba
              and   #$0f
              asl
              tax
              plp
              jmp   (:tbl,x)
:tbl          dw    :rts                   ;noop
              dw    doright                ;rightbrace
              dw    doflags                ;GT
              dw    doflags                ;LT
              dw    doflags                ;EQ
              dw    doflags                ;notEQ
              dw    doplus
              dw    dominus
              dw    domult
              dw    dodiv
              dw    domod
              dw    doand
              dw    door
              dw    doeor
              dw    donegate
              dw    doleft
              dw    :rts                   ;just in case
:rts          rts

doflags       php
              rep   $30
              stz   :yext
              stz   :xext
              lda   op                     ;get the opflags
              and   #flagmask              ;clear any unneeded bits
              sta   :myflags               ;save it
              cmp   #gt.lt.eq&flagmask     ;is it <=>?
              jeq   :true                  ;yes so must be true

              lda   xrel
              bmi   :y
              cmp   #$7fff
              beq   :y
              asl
              asl
              tay
              lda   [lableptr1],y
              sta   lableptr
              iny
              iny
              lda   [lableptr1],y
              sta   lableptr+2
              ldy   #o_labtype
              lda   [lableptr],y
              bit   #externalbit
              beq   :y
              dec   :xext
:y            lda   yrel
              bmi   :test
              cmp   #$7fff
              beq   :test
              asl
              asl
              tay
              lda   [lableptr1],y
              sta   lableptr
              iny
              iny
              lda   [lableptr1],y
              sta   lableptr+2
              ldy   #o_labtype
              lda   [lableptr],y
              bit   #externalbit
              beq   :test
              dec   :yext
:test         lda   :myflags
              cmp   #gt.lt&flagmask        is
              bne   :stz
              lda   :myflags
              and   #gt.lt&flagmask!$FFFF  ;clear <> flags
              ora   #noteq&flagmask        ;set not = flag
              sta   :myflags

:stz          stz   :flags
              lda   yreg
              cmp   xreg
              bne   :noteq
              lda   yreg+2
              cmp   xreg+2
              bne   :noteq
              lda   #eq&flagmask
              tsb   :flags                 ;tell us it's equal
              jmp   :xit
:noteq        lda   #noteq&flagmask        ;tell us it's not =
              tsb   :flags
:trylt        lda   yreg+2                 ;check the signs of the values
              eor   xreg+2
              bmi   :diff
              lda   yreg
              sec
              sbc   xreg
              lda   yreg+2
              sbc   xreg+2
              bcc   :lt
              bra   :gt
:diff         lda   yreg+2
              bmi   :lt
              bra   :gt
:lt           lda   #lt&flagmask
              tsb   :flags
              bra   :xit
:gt           lda   #gt&flagmask
              tsb   :flags
:xit          lda   :myflags
              cmp   #lt&flagmask
              beq   :lt1
              cmp   #gt&flagmask
              beq   :gt1
              lda   :xext
              ora   :yext
              beq   :newxit
:bad          sec
              ror   evalrelok
              jmp   :false
:lt1          lda   :xext
              ora   :yext
              beq   :newxit
              lda   :xext
              beq   :lt2
              lda   yreg
              cmp   #$100
              bne   :bad
              lda   yreg+2
              bne   :bad
              jmp   :newxit
:lt2          lda   xreg
              cmp   #$100
              bne   :bad
              lda   xreg+2
              bne   :bad
              jmp   :newxit
:gt1          lda   :xext
              ora   :yext
              beq   :newxit
              lda   :xext
              beq   :gt2
              lda   yreg
              cmp   #$FF
              bne   :bad
              lda   yreg+2
              bne   :bad
              jmp   :newxit
:gt2          lda   xreg
              cmp   #$FF
              bne   :bad
              lda   xreg+2
              bne   :bad
:newxit       lda   :flags
              and   :myflags
              beq   :false
:true         rep   $30
              lda   #$01
              sta   xreg
              stz   xreg+2
              plp
              clc
              rts
:false        rep   $30
              stz   xreg
              stz   xreg+2
              plp
              clc
              rts
:myflags      ds    2
:flags        ds    2
:yext         ds    2
:xext         ds    2

donegate      php
              rep   $30
              lda   xreg+2
              eor   #$ffff
              tax
              lda   xreg
              eor   #$ffff
              inc
              bne   :sta
              inx
:sta          sta   xreg
              stx   xreg+2
              plp
              rts

doright
doleft        rts

doplus        php
              rep   $30
              lda   xrel
              ora   yrel
              bmi   :ok
              sec
              ror   evalrelok
              plp
              rts

:ok           lda   xrel
              bpl   :ok1
              lda   yrel
              sta   xrel
:ok1
              lda   yreg
              clc
              adc   xreg
              sta   xreg
              lda   yreg+2
              adc   xreg+2
              sta   xreg+2
              plp
              rts

dominus       php
              rep   $30

              do    0
              lda   xrel
              jsr   prbytel
              lda   #$20
              jsr   drawchar
              lda   yrel
              jsr   prbytel
              lda   #$20
              jsr   drawchar
              fin

:lda          lda   yreg
              sec
              sbc   xreg
              sta   xreg
              lda   yreg+2
              sbc   xreg+2
              sta   xreg+2

              lda   yrel                   ;were either relative?
              and   xrel
              bmi   :plp                   ;if neither exit
              lda   yrel                   ;was just one a relative?
              eor   xrel
              bmi   :xrel
              lda   #$ffff
              jmp   :sta
:xrel         lda   yrel
              bmi   :plp

:sta          sta   xrel
:plp
              do    0
              lda   xrel
              jsr   prbytel
              lda   #$20
              jsr   drawchar
              lda   yrel
              jsr   prbytel
              lda   #$0d
              jsr   drawchar
              fin
              plp
              rts

door          php
              rep   $30
              lda   xrel
              and   yrel
              bmi   :ok
              sec
              ror   evalrelok
              plp
              rts

:ok           lda   xrel
              bpl   :ok1
              lda   yrel
              sta   xrel
:ok1
              lda   yreg
              ora   xreg
              sta   xreg
              lda   yreg+2
              ora   xreg+2
              sta   xreg+2
              plp
              rts
doand         php
              rep   $30
              lda   xrel
              and   yrel
              bmi   :ok
              sec
              ror   evalrelok
              plp
              rts

:ok           lda   xrel
              bpl   :ok1
              lda   yrel
              sta   xrel
:ok1
              lda   yreg
              and   xreg
              sta   xreg
              lda   yreg+2
              and   xreg+2
              sta   xreg+2
              plp
              rts
doeor         php
              rep   $30
              lda   xrel
              and   yrel
              bmi   :ok
              sec
              ror   evalrelok
              plp
              rts

:ok           lda   xrel
              bpl   :ok1
              lda   yrel
              sta   xrel
:ok1
              lda   yreg
              eor   xreg
              sta   xreg
              lda   yreg+2
              eor   xreg+2
              sta   xreg+2
              plp
              rts

domult        php
              rep   $30
              lda   xrel
              and   yrel
              bmi   :ok
              sec
              ror   evalrelok
              plp
              rts

:ok           lda   xrel
              bpl   :ok1
              lda   yrel
              sta   xrel
:ok1
              stz   val
              stz   val+$2
              lda   yreg
              sta   myvalue
              lda   yreg+2
              sta   myvalue+2
              ldx   #32
:mloop        lsr   xreg+$2
              ror   xreg
              bcc   :noadd
              lda   myvalue
              clc
              adc   val
              sta   val
              lda   myvalue+$2
              adc   val+$2
              sta   val+$2
:noadd        asl   myvalue
              rol   myvalue+$2
              dex
              bne   :mloop
              lda   val
              sta   xreg
              lda   val+$2
              sta   xreg+$2
              plp
              rts

dodiv         php
              rep   $30

              lda   xrel
              and   yrel
              bmi   :ok
              sec
              ror   evalrelok
              plp
              rts

:ok           lda   xrel
              bpl   :ok1
              lda   yrel
              sta   xrel
:ok1
              psl   #$00
              psl   #$00
              lda   yreg+2
              pha
              lda   yreg
              pha
              lda   xreg+2
              pha
              lda   xreg
              pha
              _LongDivide
              pla
              sta   xreg
              pla
              sta   xreg+2
              pla
              pla
              plp
              rts

domod         php
              rep   $30

              lda   xrel
              and   yrel
              bmi   :ok
              sec
              ror   evalrelok
              plp
              rts

:ok           lda   xrel
              bpl   :ok1
              lda   yrel
              sta   xrel
:ok1
              psl   #$00
              psl   #$00
              lda   yreg+2
              pha
              lda   yreg
              pha
              lda   xreg+2
              pha
              lda   xreg
              pha
              _LongDivide
              pla
              pla
              pla
              sta   xreg
              pla
              sta   xreg+2
              plp
              rts


pushstack     php
              rep   $30
              lda   estack
              cmp   #40
              bge   :err
              asl
              asl
              asl
              tax
              lda   yreg
              sta   evalstack,x
              lda   yreg+2
              sta   evalstack+2,x
              lda   op
              sta   evalstack+4,x
              lda   yrel
              sta   evalstack+6,x
              inc   estack
              plp
              clc
              rts
:err          lda   #evaltoocomplex
              plp
              sec
              rts

pullstack     php
              rep   $30
              lda   estack
              beq   :err
              dec
              sta   estack
              asl
              asl
              asl
              tax
              lda   evalstack,x
              sta   yreg
              lda   evalstack+2,x
              sta   yreg+2
              lda   evalstack+4,x
              sta   op
              lda   evalstack+6,x
              sta   yrel
              plp
              clc
              rts
:err          lda   #evaltoocomplex
              plp
              sec
              rts


getnum        php
              rep   $30
              lda   #$FFFF
              sta   zrel
:nextch       lda   (lineptr),y
              and   #$7f
              cmp   #' '+1
              bge   :jmp
:noop         pea   #noop
              jmp   :operand
:operandiny   iny
:operand      rep   $30
              pla
              plp
              rep   $41
              rts
:number       plp
              sep   $40
              clc
              rts
:error        rep   $30
              pla
              plp
              sec
              rts


:jmp          pha
              sec
              sbc   #' '
              asl
              tax
              pla
              jmp   (:chartbl,x)

:flags        stz   :flag+1
              cmp   #'#'
              beq   :noteq
:fl1          rep   $20
              sec
              sbc   #'<'
              asl
              tax
              lda   :flagtbl,x
              tsb   :flag+1
:fl2          iny
              sep   $20
              lda   (lineptr),y
              cmp   #'#'
              beq   :noteq
              cmp   #'<'
              blt   :flag
              cmp   #'>'+1
              blt   :fl1
:flag         pea   $0000
              jmp   :operand
:noteq        rep   $20
              lda   #noteq
              tsb   :flag+1
              jmp   :fl2
:flagtbl      dw    #lt
              dw    #eq
              dw    #gt

:left         pea   #leftbrace
              jmp   :operandiny
:minus        bit   number
              bmi   :negate
              pea   #minusop
              jmp   :operandiny
:negate       pea   #negateop
              jmp   :operandiny
:mult         bit   number
              jmi   :lable
              pea   #multop
              jmp   :operandiny
:plus         bit   number
              bpl   :plus1
              iny
              jmp   :nextch
:plus1        pea   #plusop
              jmp   :operandiny
:mod          sty   offset
              pea   #modop
              jmp   :operandiny
:div          ldy   offset
              iny
              lda   (lineptr),y
              and   #$7f
              cmp   #'/'
              beq   :mod
              dey
:divit        pea   #divop
              jmp   :operandiny
:eor          pea   #eveorop
              jmp   :operandiny
:or           pea   #evorop
              jmp   :operandiny
:and          pea   #evandop
              jmp   :operandiny
:checkop      bit   number
              bpl   :chkno
:golab        jmp   :lable
:chkno        pea   #noop
              jmp   :operandiny
:right        bit   number
              bmi   :golab
              pea   #rightbrace
              jmp   :operandiny

:badop        pea   #badoperand
              jmp   :error
:bad
:badchar      pea   #badopchar
              jmp   :error
:chartbl
              dw    $0000                  ; 
              dw    :eor                   ;!
              dw    :ascii                 ;"
              dw    :flags                 ;#
              dw    :hex                   ;$
              dw    :binary                ;%
              dw    :and                   ;&
              dw    :ascii                 ;'
              dw    :bad                   ;(
              dw    :checkop               ;)
              dw    :mult                  ;*
              dw    :plus                  ;+
              dw    :noop                  ;,
              dw    :minus                 ;-
              dw    :or                    ;.
              dw    :div                   ;/
              dw    :decimal               ;0
              dw    :decimal               ;1
              dw    :decimal               ;2
              dw    :decimal               ;3
              dw    :decimal               ;4
              dw    :decimal               ;5
              dw    :decimal               ;6
              dw    :decimal               ;7
              dw    :decimal               ;8
              dw    :decimal               ;9
              dw    :lable                 ;:
              dw    :noop                  ;;
              dw    :flags                 ;<
              dw    :flags                 ;=
              dw    :flags                 ;>
              dw    :lable                 ;?
              dw    :lable                 ;@
              dw    :lable                 ;A
              dw    :lable                 ;B
              dw    :lable                 ;C
              dw    :lable                 ;D
              dw    :lable                 ;E
              dw    :lable                 ;F
              dw    :lable                 ;G
              dw    :lable                 ;H
              dw    :lable                 ;I
              dw    :lable                 ;J
              dw    :lable                 ;K
              dw    :lable                 ;L
              dw    :lable                 ;M
              dw    :lable                 ;N
              dw    :lable                 ;O
              dw    :lable                 ;P
              dw    :lable                 ;Q
              dw    :lable                 ;R
              dw    :lable                 ;S
              dw    :lable                 ;T
              dw    :lable                 ;U
              dw    :lable                 ;V
              dw    :lable                 ;W
              dw    :lable                 ;X
              dw    :lable                 ;Y
              dw    :lable                 ;Z
              dw    :lable                 ;[
              dw    :lable                 ;\
              dw    :checkop               ;]
              dw    :lable                 ;^
              dw    :lable                 ;_
              dw    :lable                 ;`
              dw    :lable                 ;a
              dw    :lable                 ;b
              dw    :lable                 ;c
              dw    :lable                 ;d
              dw    :lable                 ;e
              dw    :lable                 ;f
              dw    :lable                 ;g
              dw    :lable                 ;h
              dw    :lable                 ;i
              dw    :lable                 ;j
              dw    :lable                 ;k
              dw    :lable                 ;l
              dw    :lable                 ;m
              dw    :lable                 ;n
              dw    :lable                 ;o
              dw    :lable                 ;p
              dw    :lable                 ;q
              dw    :lable                 ;r
              dw    :lable                 ;s
              dw    :lable                 ;t
              dw    :lable                 ;u
              dw    :lable                 ;v
              dw    :lable                 ;w
              dw    :lable                 ;x
              dw    :lable                 ;y
              dw    :lable                 ;z
              dw    :left                  ;{
              dw    :lable                 ;|
              dw    :right                 ;}
              dw    :lable                 ;~
              dw    :lable                 ;


:hex          rep   $20
              stz   val
              stz   val+2
              stz   :valid
              sep   $20
              iny
              lda   (lineptr),y
              cmp   #' '+1
              blt   :hexbad
]lup          sep   $20
              lda   (lineptr),y
              cmp   #'0'
              blt   :hexout
              cmp   #'9'+1
              blt   :hexdig
              cmp   #'A'
              blt   :hexout
              cmp   #'Z'+1
              blt   :hexdiga
              cmp   #'a'
              blt   :hexout
              cmp   #'z'+1
              bge   :hexout
              and   #$5f
:hexdiga      sec
              sbc   #$37
              jmp   :hdig
:hexdig       sec
              sbc   #$30
:hdig         sec
              ror   :valid+1
              rep   $20
              and   #$0f
              asl   val
              rol   val+2
              asl   val
              rol   val+2
              asl   val
              rol   val+2
              asl   val
              rol   val+2
              tsb   val

:hexiny       iny
              jmp   ]lup
:hexout       rep   $20
              bit   :valid
              bpl   :hexbad
              jmp   :numout
:hexbad       pea   #badopchar
              jmp   :error
:valid        ds    2

:binary       rep   $20
              stz   val
              stz   val+2
              stz   :valid
              sep   $20
              iny
              lda   (lineptr),y
              cmp   #' '+1
              blt   :binbad
]lup          sep   $20
              lda   (lineptr),y
              cmp   #'_'
              beq   :biny
              cmp   #'0'
              blt   :binout
              cmp   #'1'+1
              bge   :binout
              lsr
              rep   $20
              rol   val
              rol   val+2
              sec
              ror   :valid
:biny         iny
              jmp   ]lup
:binout       rep   $20
              bit   :valid
              bpl   :binbad
              jmp   :numout
:binbad       pea   #badopchar
              jmp   :error

:decimal      rep   $20
              ldx   #$00
              stz   val                    ;past 1st digit...
              stz   val+$2
              sep   $20
:dlup         lda   (lineptr),y
              cmp   #'0'
              blt   :ddec
              cmp   #'9'+$1
              bge   :ddec
:ddig         sta   :valstr+$1,X
              iny
              inx
              cpx   #10
              blt   :dlup
:ddec         phy
              txy
              rep   $20
              beq   :ddone
              lda   #cnvttbl
              sta   deczp
:dloop        lda   :valstr,x
              and   #$000F
              asl
              asl
              tay
              lda   (deczp),Y
              adc   val
              sta   val
              iny
              iny
              lda   (deczp),Y
              adc   val+$2
              sta   val+$2
              lda   deczp
              clc
              adc   #40
              sta   deczp
              dex
              bne   :dloop
:ddone        rep   $20
              ply
              jmp   :numout

:ascii        sep   $20
              sta   :deliminator
              stz   :orflag
              iny
              cmp   #$27
              bge   :asclda
              sec
              ror   :orflag
:asclda       lda   (lineptr),y
              cmp   #' '
              blt   :ascbad
              iny
              cmp   :deliminator
              beq   :asczero
              xba
              lda   (lineptr),y
              cmp   #' '
              blt   :ascbad
              cmp   :deliminator
              beq   :asc1
              xba
              tax
              iny
              lda   (lineptr),y
              cmp   :deliminator
              bne   :ascbad
              rep   $20
              txa
              xba
              sep   $20
:asc2         ora   :orflag
              xba
              ora   :orflag
              iny
              rep   $20
              ldx   #$00
              jmp   :number
:asc1         xba
              iny
              rep   $20
              and   #$ff
              ora   :orflag
              ldx   #$00
              jmp   :number
:asczero      rep   $20
              ldx   #$00
              txa
              jmp   :number
:ascbad       pea   #badopchar
              jmp   :error

:deliminator  ds    2
:orflag       ds    2

:lable        rep   $20
              stz   val
              stz   val+2
              sep   $20
:lsta         ldx   #$00
]lup          lda   (lineptr),y
              cmp   #'0'
              blt   :lxit
              cmp   #'<'
              blt   :iny
              cmp   #'>'+1
              blt   :lxit
              cmp   #'}'
              beq   :brace
              cmp   #']'
              bne   :iny
              cpx   #$00
              bne   :lxit
              jmp   :iny
:brace        lda   evallevel
              bne   :lxit
* lda evallevel           ;don't need to do this here
* bne :lxit               ;unless level>256
              lda   #'}'
:iny          cpx   #lab_size
              bge   :iny1
              sta   labstr+1,x
:iny1         iny
              inx
              jmp   ]lup
:lxit         txa
              cmp   #lab_size+1
              blt   :lx
              lda   #lab_size
:lx           sta   labstr
              sty   :next
              jsr   findlable
              bcs   :lfound
              rep   $30
              ldy   passnum
              bne   :errlab
              sep   $20
              lda   #$FF
              sta   notfound
              rep   $20
              jmp   :lbxit
:errlab       lda   #undeflable
              jmp   :errxit
:lfound       rep   $30
              ldy   #o_labtype
              lda   [lableptr],y
              pha
              ldy   #o_labnum
              lda   [lableptr],y
              ldy   #o_labtype
              lda   [lableptr],y
              ora   #linkusedbit           ;indicate used!
              sta   [lableptr],y
              pla
              ora   #$8000

              do    0
              and   #$dfff
              cmp   #$8080                 ;Macro???
              bne   :lbmi
              lda   #undeflable
              jmp   :errxit
:lbmi         and   #$8000
              bne   :lsta1
              lda   modeflag
              bit   #relflag
              beq   :labcont
              bit   #dumflag
              bne   :labcont
              ldy   #o_labnum
              lda   [lableptr],y
              sta   zrel
              fin

:labcont      rep   $30
:lsta1        ldy   #o_labval
              lda   [lableptr],y
              sta   val
              ldy   #o_labval+2
              lda   [lableptr],y
              sta   val+2
:lbxit        ldy   :next

:numout       rep   $30
:lda          lda   val
              ldx   val+2

:clc          jmp   :number

:errxit
:sec          rep   $30
              pha
              jmp   :error

:valstr       ds    16,0
:next         ds    2

evalstack     ds    40*8

cnvttbl       adrl  0,1,2,3,4,5,6,7,8,9
              adrl  0,10,20,30,40,50,60,70,80,90
              adrl  0,100,200,300,400,500,600,700,800,900
              adrl  0,1000,2000,3000,4000,5000,6000,7000,8000,9000
              adrl  0,10000,20000,30000,40000,50000,60000,70000,80000,90000
              adrl  0,100000,200000,300000,400000,500000,600000,700000,800000
              adrl  900000
              adrl  0,1000000,2000000,3000000,4000000,5000000,6000000,7000000
              adrl  8000000,9000000
              adrl  0,10000000,20000000,30000000,40000000,50000000,60000000
              adrl  70000000,80000000,90000000
              adrl  0,100000000,200000000,300000000,400000000,500000000
              adrl  600000000,7000000000,800000000,900000000
              adrl  0,1000000000,2000000000,3000000000,4000000000,5000000000
              adrl  6000000000,7000000000,8000000000,900000000

