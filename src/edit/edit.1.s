findword       rts
findreplace    php
               rep   $30
               jsr   getreplace
               plp
               rts

find
               php
               rep   $30
               stz   :findpos
               lda   position
               sta   :oldpos
               lda   pos
               and   #$ff
               clc
               adc   position
               bcs   :atend
               inc
               beq   :atend
               cmp   flen
               blt   :fp
:atend         lda   #$00
               sta   findstr
:fp            sta   :pos
               tay
               beq   :sta
               sep   $20
]l             lda   [fileptr],y
               and   #$7f
               cmp   #$0d
               beq   :sta0
               dey
               bne   ]l
               bra   :sta1
:sta0          iny
:sta1          rep   $30
:sta           sty   :linepos
               lda   linenum
               sta   :line
               lda   findstr
               and   #$ff
               bne   :find
               jsr   getfind
               jcs   :xit
               lda   findstr
               and   #$ff
               jeq   :xit
               sep   $30
               ldx   findstr
]l             lda   findstr,x
               and   #$7f
               cmp   #'a'
               blt   :lc1
               cmp   #'z'+1
               bge   :lc1
               and   #$5f
:lc1           sta   findstr,x
               dex
               bne   ]l
               rep   $30
               stz   :pos
               stz   :linepos
               lda   #$01
               sta   :line
:find          ldy   :pos
               sep   $20
:f0            ldx   #$01
]f             cpy   flen
               bge   :notfound
:f2            lda   [fileptr],y
               and   #$7f
               cmp   #$0d
               beq   :no1
               cmp   #'a'
               blt   :f1
               cmp   #'z'+1
               bge   :f1
               and   #$5f
:f1            cmp   findstr,x
               bne   :nexty
               inx
               iny
               txa
               cmp   findstr
               blt   ]f
               beq   ]f
               sty   :findpos
               jmp   :done           ;found here
:nexty         iny
               bra   :f0
:no1           iny
               sty   :linepos
:no            rep   $30
               sty   :pos
               inc   :line
               jmp   :find
:notfound      rep   $30
               stz   gotoposition
               jsr   gotopos
               stz   findstr
               jmp   :xit
:done          rep   $30
               lda   :line
               sta   gotolnum
               jsr   gotoline
               lda   :findpos
               beq   :xit
               sec
               sbc   :linepos
               bcc   :xit
               tax
               lda   findstr
               and   #$ff
               pha
               txa
               sec
               sbc   1,s
               sta   1,s
               pla
               bcc   :xit
               and   #$ff
               sta   pos
               jsr   poscurs
:xit           plp
               rts
:oldpos        ds    2
:pos           ds    2
:line          ds    2
:linepos       ds    2
:findpos       ds    2

checkcommands  php
               rep   $30
               lda   commandlen
               and   #$00ff
               jeq   :sec
               sta   :len
               stz   :which
               stz   :max
:loop          rep   $20
               ldy   :max
               lda   cstrings,y
               and   #$ff
               jeq   :sec
               pha
               clc
               adc   :max
               sta   :max
               pla
               cmp   :len
               bne   :next
               ldx   #$00
:find          sep   $20
               lda   externname,x
               and   #$7f
               cmp   #'a'
               blt   :ok
               cmp   #'z'+1
               bge   :ok
               and   #$5f
:ok            cmp   cstrings+1,y
               bne   :next
               inx
               iny
               cpy   :max
               blt   :find
               jmp   :found
:next          rep   $30
               inc   :which
               inc   :max
               jmp   :loop
:found         rep   $30
               lda   :which
               asl
               tax
               lda   croutines,x
               sta   :jsr+1
:jsr           jsr   $ffff
               jmp   :clc
:sec           rep   $30
               lda   #$00
               plp
               sec
               rts
:clc           plp
               clc
               rts

:which         ds    2
:max           ds    2
:len           ds    2

cstrings       str   'PFX'
               str   'PREFIX'
               str   'CATALOG'
               str   'CAT'
               str   'NEW'
               hex   0000
               str   'DELETE'

croutines      dw    setprefix
               dw    setprefix
               dw    docatalog
               dw    docatalog
               dw    donew
               dw    delete

               mx    %00
delete         tll   $2c03
               tll   $2c03
               lda   #$00
               clc
               rts

donew          php
               rep   $30
               jsr   newdoc
               jsr   drawfname
               jsr   gotoline
               lda   #$00
               plp
               clc
               rts

               mx    %00
docatalog      lda   instring
               and   #$ff
               sta   :len
               cmp   commandlen
               jlt   :xit
               jeq   :current
               lda   commandlen
               and   #$ff
               tax
               inx
               ldy   #$00
               sep   $20
]flush         cpx   :len
               blt   :fl
               beq   :fl
               jmp   :current
:fl            lda   instring,x
               inx
               and   #$7f
               cmp   #' '
               jlt   :current
               beq   ]flush

               sta   :pfx+1
               ldy   #$01
:save
]lup           cpy   #64
               bge   :setit
               lda   instring,x
               and   #$7f
               cmp   #'/'
               beq   :sta
               cmp   #'.'
               beq   :sta
               cmp   #'0'
               blt   :setit
               cmp   #'9'+1
               blt   :sta
               cmp   #'A'
               blt   :setit
               cmp   #'Z'+1
               blt   :sta
               cmp   #'a'
               blt   :setit
               cmp   #'z'+1
               bge   :setit
               and   #$5f
:sta           sta   :pfx+1,y
               iny
               inx
               cpx   :len
               blt   ]lup
               beq   ]lup
:setit         sep   $20
               tya
               sta   :pfx
               rep   $30
               jmp   :showcat
:current       rep   $30
               jsl   prodos
               dw    $0a
               adrl  :pfxparm
               jcs   :err
               sep   $20
               dec   :pfx
               jmp   :showcat
:xit
:err           rep   $30
               lda   #syntaxerr
:err1          jsr   doerror
               lda   #$00
               sec
               rts
:nomem         rep   $30
               lda   #outofmem
               jmp   :err1

:showcat       rep   $30
               stz   :openflag
               stz   :close
               stz   :handle
               stz   :handle+2
               jsl   prodos
               dw    $06
               adrl  :info
               jcs   :caterr
               lda   :type
               cmp   #$0f
               jne   :nodir
               jsl   prodos
               dw    $10
               adrl  :open
               jcs   :caterr
               sec
               ror   :openflag
               lda   :open
               sta   :eof
               sta   :close
               sta   :read
               jsl   prodos
               dw    $19
               adrl  :eof
               jcs   :caterr

               psl   #$00
               psl   :eof1
               lda   userid
               pha
               pea   $C000
               psl   #$00
               tll   $0902
               plx
               ply
               jcs   :nomem
               stx   :handle
               stx   zpage
               sty   :handle+2
               sty   zpage+2
               lda   :eof1
               sta   :request
               lda   :eof1+2
               sta   :request+2
               ldy   #$02
               lda   [zpage]
               sta   :buffer
               lda   [zpage],y
               sta   :buffer+2
               jsl   prodos
               dw    $12
               adrl  :read
               jcs   :caterr
               jsl   prodos
               dw    $14
               adrl  :close
               jcs   :caterr
               stz   :openflag

               jsr   erasebox
               jsr   drawbox1

               lda   :handle
               sta   dirzp
               lda   :handle+2
               sta   dirzp+2
               ldy   #$02
               lda   [dirzp]
               tax
               lda   [dirzp],y
               sta   dirzp+2
               stx   dirzp

               do    0
               lda   dirzp
               clc
               adc   #$04
               sta   dirzp
               bcc   :adc1
               inc   dirzp+2
               fin

:adc1          ldy   #$23
               lda   [dirzp],y
               and   #$00ff
               sta   :entrylen
               iny
               lda   [dirzp],y
               and   #$ff
               sta   :entper
               iny
               lda   [dirzp],y
               sta   :count
               stz   :filepos


:adc           ldy   #$04
               lda   [dirzp],y
               and   #$0f
               sta   :entlen
               lda   #6
               sta   mycv
               lda   #22-7
               sta   mych
               jsl   textbascalc
               pea   "/"
               tll   $180c
               ldy   #$05
               ldx   #$01
]lup           lda   [dirzp],y
               phy
               phx
               and   #$7f
               pha
               tll   $180c
               plx
               ply
               iny
               inx
               cpx   :entlen
               blt   ]lup
               beq   ]lup

               jsl   print
               dfb   22-7
               dfb   7
               asc   "-----name-------typ---aux----len---------date------",00

               stz   :catwhich
               jsr   :catdraw
:key
               do    mouse
;jsr initmouse
               stz   mousecr
               stz   mousecrchar
:key2          jsr   mousekey
               bmi   :and7f
               else
:key2
               fin                   ;--- mouse ---

               jsl   keyscan
               bpl   :key2
:and7f         and   #$7f
               cmp   #$1b
               jeq   :showxit
               cmp   #$0d
               jeq   :showxit
               cmp   #$0a
               jeq   :down
               cmp   #$0b
               bne   :key
               jmp   :up
:showxit       jsr   erasebox1
               lda   #$01
:catxit        pha
               lda   :handle
               ora   :handle+2
               beq   :nodis
               psl   :handle
               _Disposehandle
:nodis         pla
               clc
               rts

:nodir         rep   $30
               lda   #notdir
:caterr        rep   $30
               jsr   doerror
               bit   :openflag
               bpl   :cat1
               jsl   prodos
               dw    $14
               adrl  :close
:cat1          lda   #$00
               jmp   :catxit

:up            lda   :filepos
               beq   :upxit
               dec   :filepos
               lda   #$8000
               sta   :catwhich
               jsr   catscrolldn
               jsr   :catdraw
:upxit         jmp   :key
:down          lda   :filepos
               clc
               adc   #catentries
               cmp   :count
               bge   :upxit
               inc   :filepos
               lda   #$4000
               sta   :catwhich
               jsr   catscrollup
               jsr   :catdraw
               jmp   :key

:count         ds    2
:entrylen      ds    2
:filepos       ds    2
:entper        ds    2

:len           ds    2
:handle        ds    4
:openflag      ds    2

:open          dw    $00
               adrl  :pfx
               adrl  $00
:info          adrl  :pfx
               dw    $00
:type          dw    $00
               adrl  $00
               ds    14,0
:read          dw    $00
:buffer        adrl  $00
:request       adrl  $00
:transfer      adrl  $00
:eof           dw    $00
:eof1          adrl  $00
:close         dw    $00

:pfxparm       dw    $00
               adrl  :pfx

:pfx           ds    68,0

:cdpos         ds    2
:catwhich      ds    2

:catdraw       php
               rep   $30
               lda   #08
               sta   mycv
               lda   :filepos
               sta   :cdpos
               sta   :cdcount
:cdloop        lda   :cdpos
               cmp   :count
               jge   :cdxit
               lda   mycv
               cmp   #8+catentries
               jge   :cdxit
               lda   #22-7
               sta   mych
               jsl   textbascalc

:pha           pha
               pha
               lda   :cdcount
               inc
               pha
               lda   :entper
               pha
               tll   $0b0b
               pla
               sta   :blocknum
               pla
               sta   :remain
               lda   :blocknum
               xba
               asl                   ;* $200
               clc
               adc   #$04
               sta   :ypos

               pha
               pha
               lda   :entrylen
               pha
               lda   :remain
               pha
               tll   $090b
               pla
               plx
               clc
               adc   :ypos
               sta   :ypos

               ldy   :ypos
               lda   [dirzp],y
               and   #$f0
               bne   :cshow
:inccd         inc   :cdcount
               jmp   :pha
:cshow         bit   :catwhich
               bvc   :cshow1
               lda   mycv
               inc
               cmp   #8+catentries
               jlt   :inccv
:cshow1        jsr   :printent
               bit   :catwhich
               bmi   :cdxit
:inccv         inc   mycv
               inc   :cdcount
               inc   :cdpos
               jmp   :cdloop
:cdxit         plp
               rts

:printent      php
               rep   $30
               ldy   :ypos
               lda   [dirzp],y
               and   #$0f
               beq   :inccd
               sta   :entlen
               iny
               ldx   #$01
]lup           lda   [dirzp],y
               and   #$7f
               ora   #$80
               phx
               phy
               pha
               tll   $180c
               ply
               plx
               inx
               iny
               cpx   :entlen
               blt   ]lup
               beq   ]lup
]lup           cpx   #$11
               bge   :dtype
               lda   #$a0
               phx
               pha
               tll   $180c
               plx
               inx
               jmp   ]lup
:dtype         lda   :ypos
               clc
               adc   #$10
               tay
               lda   [dirzp],y
               and   #$ff
               pha
               asl
               clc
               adc   1,s
               plx
               tax
               lda   filetypelist,x
               phx
               pha
               tll   $180c
               plx
               inx
               lda   filetypelist,x
               phx
               pha
               tll   $180c
               plx
               inx
               lda   filetypelist,x
               pha
               tll   $180c

               pea   $a0
               tll   $180c
               pea   $a0
               tll   $180c
:daux          pea   #"$"
               tll   $180c
               lda   :ypos
               clc
               adc   #$1f
               tay
               lda   [dirzp],y
               jsr   :prbytel

               pea   $a0
               tll   $180c
               pea   $a0
               tll   $180c
:dlen          pea   #"$"
               tll   $180c
               lda   :ypos
               clc
               adc   #$15
               tay
               lda   [dirzp],y
               jsr   :prbytel
               pea   $a0
               tll   $180c
               pea   $a0
               tll   $180c

               lda   :ypos
               clc
               adc   #$21
               tay
               lda   [dirzp],y
               sta   :year
               iny
               iny
               lda   [dirzp],y
               sta   :time

               lda   :year
               and   #%11111
               sta   :decimal
               cmp   #$0a
               bge   :d1
               pea   #" "
               tll   $180c
:d1            psl   #:decimal
               pea   $0000
               jsl   printdec
               pea   #"-"
               tll   $180c

               lda   :year
               lsr
               lsr
               lsr
               lsr
               lsr
               and   #%1111
               dec
               asl
               asl
               tax

               lda   ftmonths,x
               phx
               pha
               tll   $180c
               plx
               inx
               lda   ftmonths,x
               phx
               pha
               tll   $180c
               plx
               inx
               lda   ftmonths,x
               pha
               tll   $180c
               pea   #"-"
               tll   $180c

               lda   :year
               xba
               lsr
               and   #%1111111
               sta   :decimal
               cmp   #$0a
               bge   :d2
               pea   #"0"
               tll   $180c
:d2            psl   #:decimal
               pea   $0000
               jsl   printdec
               pea   #" "
               tll   $180c
               pea   #" "
               tll   $180c

               lda   :time
               xba
               and   #%11111
               sta   :decimal
               cmp   #$0a
               bge   :d3
               pea   #" "
               tll   $180c
:d3            psl   #:decimal
               pea   $0000
               jsl   printdec
               pea   #":"
               tll   $180c

               lda   :time
               and   #%111111
               sta   :decimal
               cmp   #$0a
               bge   :d4
               pea   #"0"
               tll   $180c
:d4            psl   #:decimal
               pea   $0000
               jsl   printdec

               plp
               rts


:cdcount       ds    2
:ypos          ds    2
:entlen        ds    2
:blocknum      ds    2
:remain        ds    2
:decimal       ds    2
:year          ds    2
:time          ds    2

:prbytel       php
               rep   $30
               sta   :byte
               xba
               jsr   :prbyte
               lda   :byte
               jsr   :prbyte
               plp
               rts
:byte          ds    2

:prbyte        php
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
               plp
               rts
:nib           ora   #"0"
               cmp   #"9"+1
               blt   :ok
               adc   #"A"-"9"-2
:ok            and   #$7F
               pha
               tll   $180c
               rts


catscrollup
                                     ;fast scroll routine
               phy
               php
               phb
               rep   $30
               ldy   #32             ;get ready for each column
:start         pea   $0101
               plb
               plb
               lda   $4a8,y
               sta   $428,y
               lda   $528,Y
               sta   $4A8,Y
               lda   $5A8,Y
               sta   $528,Y
               lda   $628,Y
               sta   $5A8,Y
               lda   $6A8,Y
               sta   $628,Y
               lda   $728,Y
               sta   $6A8,Y
               lda   $7A8,Y
               sta   $728,Y
               lda   $450,Y
               sta   $7A8,Y

* php
* sep $20
* lda #$A0 ;last line gets cleared
* xba
* lda #$A0
* plp
* sta $450,Y
               pea   $0000
               plb
               plb
* rep $30
:lda2
               lda   $4a8,y
               sta   $428,y
               lda   $528,Y
               sta   $4A8,Y
               lda   $5A8,Y
               sta   $528,Y
               lda   $628,Y
               sta   $5A8,Y
               lda   $6A8,Y
               sta   $628,Y
               lda   $728,Y
               sta   $6A8,Y
               lda   $7A8,Y
               sta   $728,Y
               lda   $450,Y
               sta   $7A8,Y

* php
* sep $20
* lda #$A0 ;last line gets cleared
* xba
* lda #$A0
* plp
* sta $450,Y
               dey                   ;decrement index
               dey
               cpy   #6
               blt   :exit           ;if not done with screen..
               brl   :start          ;continue
:exit          plb
               plp                   ;restore flags
               ply
               rts                   ;and return

catscrolldn
               phy
               php
               phb
               rep   $30
               ldy   #32             ;get ready for each column
:start         pea   $0101
               plb
               plb
               lda   $7A8,Y
               sta   $450,Y
               lda   $728,Y
               sta   $7A8,Y
               lda   $6A8,Y
               sta   $728,Y
               lda   $628,Y
               sta   $6A8,Y
               lda   $5A8,Y
               sta   $628,Y
               lda   $528,Y
               sta   $5A8,Y
               lda   $4A8,Y
               sta   $528,Y
               lda   $428,Y
               sta   $4A8,Y
** lda $780,Y
* sta $428,Y

* php
* sep $20
* lda #$A0 ;last line gets cleared
* xba
* lda #$A0
* plp
* sta $780,Y

               pea   $0000
               plb
               plb
* rep $30
:lda2
               lda   $7A8,Y
               sta   $450,Y
               lda   $728,Y
               sta   $7A8,Y
               lda   $6A8,Y
               sta   $728,Y
               lda   $628,Y
               sta   $6A8,Y
               lda   $5A8,Y
               sta   $628,Y
               lda   $528,Y
               sta   $5A8,Y
               lda   $4A8,Y
               sta   $528,Y
               lda   $428,Y
               sta   $4A8,Y
* lda $780,Y
* sta $428,Y

* php
* sep $20
* lda #$A0 ;last line gets cleared
* xba
* lda #$A0
* plp
* sta $780,Y
               dey                   ;decrement index
               dey
               cpy   #6
               blt   :exit           ;if not done with screen..
               jmp   :start          ;continue
:exit          plb
               plp                   ;restore flags
               ply
               rts                   ;and return


catscrollup1
                                     ;fast scroll routine
               phy
               php
               phb
               rep   $30
               ldy   #20             ;get ready for each column
:start         pea   $0101
               plb
               plb
               lda   $4a8,y
               sta   $428,y
               lda   $528,Y
               sta   $4A8,Y
               lda   $5A8,Y
               sta   $528,Y
               lda   $628,Y
               sta   $5A8,Y
               lda   $6A8,Y
               sta   $628,Y
               lda   $728,Y
               sta   $6A8,Y
               lda   $7A8,Y
               sta   $728,Y
               lda   $450,Y
               sta   $7A8,Y

* php
* sep $20
* lda #$A0 ;last line gets cleared
* xba
* lda #$A0
* plp
* sta $450,Y
               pea   $0000
               plb
               plb
:lda2
               lda   $4a8,y
               sta   $428,y
               lda   $528,Y
               sta   $4A8,Y
               lda   $5A8,Y
               sta   $528,Y
               lda   $628,Y
               sta   $5A8,Y
               lda   $6A8,Y
               sta   $628,Y
               lda   $728,Y
               sta   $6A8,Y
               lda   $7A8,Y
               sta   $728,Y
               lda   $450,Y
               sta   $7A8,Y

* php
* sep $20
* lda #$A0 ;last line gets cleared
* xba
* lda #$A0
* plp
* sta $450,Y
               dey                   ;decrement index
               dey
               cpy   #6
               blt   :exit           ;if not done with screen..
               jmp   :start          ;continue
:exit          plb
               plp                   ;restore flags
               ply
               rts                   ;and return

catscrolldn1
               phy
               php
               phb
               rep   $30
               ldy   #20             ;get ready for each column
:start         pea   $0101
               plb
               plb
               lda   $7A8,Y
               sta   $450,Y
               lda   $728,Y
               sta   $7A8,Y
               lda   $6A8,Y
               sta   $728,Y
               lda   $628,Y
               sta   $6A8,Y
               lda   $5A8,Y
               sta   $628,Y
               lda   $528,Y
               sta   $5A8,Y
               lda   $4A8,Y
               sta   $528,Y
               lda   $428,Y
               sta   $4A8,Y
** lda $780,Y
* sta $428,Y

* php
* sep $20
* lda #$A0 ;last line gets cleared
* xba
* lda #$A0
* plp
* sta $780,Y

               pea   $0000
               plb
               plb
:lda2
               lda   $7A8,Y
               sta   $450,Y
               lda   $728,Y
               sta   $7A8,Y
               lda   $6A8,Y
               sta   $728,Y
               lda   $628,Y
               sta   $6A8,Y
               lda   $5A8,Y
               sta   $628,Y
               lda   $528,Y
               sta   $5A8,Y
               lda   $4A8,Y
               sta   $528,Y
               lda   $428,Y
               sta   $4A8,Y
* lda $780,Y
* sta $428,Y

* php
* sep $20
* lda #$A0 ;last line gets cleared
* xba
* lda #$A0
* plp
* sta $780,Y
               dey                   ;decrement index
               dey
               cpy   #6
               blt   :exit           ;if not done with screen..
               jmp   :start          ;continue
:exit          plb
               plp                   ;restore flags
               ply
               rts                   ;and return




               mx    %00
setprefix      lda   instring
               and   #$ff
               sta   :len
               cmp   commandlen
               jlt   :xit
               jeq   :xit
               lda   commandlen
               and   #$ff
               tax
               inx
               ldy   #$00
               sep   $20
]flush         cpx   :len
               blt   :fl
               beq   :fl
               jmp   :err
:fl            lda   instring,x
               inx
               and   #$7f
               cmp   #' '
               jlt   :xit
               beq   ]flush

               sta   :pfx+1
               ldy   #$01
:save
]lup           cpy   #64
               bge   :setit
               lda   instring,x
               and   #$7f
               cmp   #'/'
               beq   :sta
               cmp   #'.'
               beq   :sta
               cmp   #'0'
               blt   :setit
               cmp   #'9'+1
               blt   :sta
               cmp   #'A'
               blt   :setit
               cmp   #'Z'+1
               blt   :sta
               cmp   #'a'
               blt   :setit
               cmp   #'z'+1
               bge   :setit
               and   #$5f
:sta           sta   :pfx+1,y
               iny
               inx
               cpx   :len
               blt   ]lup
               beq   ]lup
:setit         sep   $20
               tya
               sta   :pfx
               rep   $30

               jsl   prodos
               dw    $09
               adrl  :pfxparm
               jcs   :err1
               jsl   prodos
               dw    $0a
               adrl  mypfxparm
               lda   #$00
               clc
               rts
:xit
:err           rep   $30
               lda   #syntaxerr
               jsr   doerror
               lda   #$00
               sec
               rts

:err1          pha
               jsl   prodos
               dw    $09
               adrl  mypfxparm
               pla
               jmp   :err

:len           ds    2

:pfxparm       dw    $00
               adrl  :pfx

:pfx           ds    68,0

runcommand     php
               plp
               sec
               rts
               rep   $30
               stz   extdplen        ;zero out all variables
               stz   extdpadd
               stz   extuserid
               stz   extadd
               stz   extadd+2
               stz   dpsave
               stz   stacksave
               stz   extdphdl
               stz   extdphdl+2
               stz   extrunflag

               jsl   prodos
               dw    $06             ;file info
               adrl  :infoparm
               bcc   :chktype
               jmp   :xit

:chktype       lda   :type
               cmp   #$b5            ;EXE file?
               jne   :xit

               do    0
               pha
               pea   $5000
               tll   $2003
               pla
               fin

               pha
               pha
               pha
               pha
               pha
               pea   $0000

               psl   #externpath
               pea   $FFFF

               tll   $0911           ;InitialLoad..load the file
* brk $02

               tll   $2C03
               sec
               ror   equitflag
               jmp   :remove

               bcs   :remove         ;error loading??
               pla
               sta   extuserid       ;Save new userid
               pla
               sta   :extjsl+1       ;save Init address
               sta   extadd          ;save it again
               pla
               sep   $20
               sta   :extjsl+3       ;do the high byte
               sta   extadd+2
               rep   $20
               pla
               sta   extdpadd        ;Get DP address
               pla
               sta   extdplen        ;Get length of DP
               jmp   :ok             ;go run it...

:remove        nop                   ;brk $02
:remove1       tsc                   ;remove bad parameters from stack
               clc
               adc   #10
               tcs
               jml   :norun          ;fall through and don't run it!

:ok            lda   extdplen        ;Was DP assigned?
               bne   :setup          ;Yes...so just setup our stuff
               psl   #$00            ;We need to get some DP for Script
               psl   #1024           ;$400 bytes
               lda   extuserid       ;Use it's UserID
               pha
               pea   $c015           ;DP attributes
               psl   #$00            ;must be bank $00
               tll   $0902           ;NewHandle
               pla                   ;get the low handle
               plx                   ;high handle
               jcs   :norun          ;Error?
               sta   zpage           ;dereference it
               sta   extdphdl        ;and also save handle for Shutdown
               stx   zpage+2         ;do the High word
               stx   extdphdl+2
               lda   [zpage]
               sta   extdpadd        ;we just need the low word b'cuz it's bank $00
               lda   #1024           ;tell setup that we got $400 bytes
               sta   extdplen
:setup         lda   extadd
               ora   extadd+2
               jeq   :norun
               lda   extadd
               sta   zpage
               lda   extadd+2
               sta   zpage+2
               ldx   #$00
               ldy   #24             ;offset to ID word
               lda   [zpage],y
               cmp   #$01            ;QuickEdit ID?
               jne   :norun
               iny
               iny
               sep   $20
]lup           lda   [zpage],y
               cmp   asciiid,x
               bne   :norun
               iny
               inx
               cpx   #$05            ;"QUICK"
               blt   ]lup
               rep   $20
               tll   $2c03
:setup1        phd
               pla
               sta   dpsave          ;save our current DP
               tsc                   ;Save our current stack
               sta   stacksave
               php                   ;save the interupt status
               sei                   ;turn of interupts so no problems
               do    0
               ldal  $e100a8         ;replace P16 vectors
               sta   p16vec
               ldal  $e100a8+2
               sta   p16vec+2
               ldal  $e100b0
               sta   p16vec1
               ldal  $e100b0+2
               sta   p16vec1+2
               lda   p16jmp
               stal  $e100a8
               lda   p16jmp+2
               stal  $e100a8+2
               lda   p16jmp1
               stal  $e100b0
               lda   p16jmp1+2
               stal  $e100b0+2
               fin
               plp                   ;restore interupts

               sec
               ror   extrunflag      ;set high bit
               lda   extdpadd        ;set DP to Script DP
               pha
               pld
               clc                   ;add in the length to set up stack
               adc   extdplen
               tcs                   ;put it in stack
               lda   extuserid       ;A=Scripts UserID
* ldx #hsvectors ;X=Low word of vectortbl address
* ldy #^hsvectors ;Y=High word of vectortbl address
               jmp   :extjsl         ;go call the script init routine

:norun         rep   $30
               phd                   ;if we get here...there was some error
               pla                   ;save some stuff needed below
               sta   dpsave
               tsc
               sta   stacksave
               jmp   :restore        ;and fall through to the RESTORE routine

:extjsl        jsl   $FFFFFF         ;this gets modified above..to call script

:restore       clc                   ;OK make sure everything is kosher
               xce
               phk
               plb
               rep   $30
               lda   stacksave       ;restore "our" stack
               tcs
               lda   dpsave          ;restore "our" DP
               pha
               pld

               bit   extrunflag      ;did we run the utility?
               bpl   :xit            ;minus=yes

               php                   ;save the interupt status
               sei                   ;turn of interupts so no problems
               do    0
               lda   p16vec
               stal  $e100a8         ;replace P16 vectors
               lda   p16vec+2
               stal  $e100a8+2
               lda   p16vec1
               stal  $e100b0
               lda   p16vec1+2
               stal  $e100b0+2
               fin
               plp                   ;restore interupts
:xit           jsr   unloadext       ;and continue!!!
               plp
               rts

:infoparm      adrl  externpath
               dw    $00
:type          dw    $00
               ds    20,0

:busy          ds    2,0

p16jmp         jml   p16quit
p16jmp1        jml   p16quit1

p16qhandle
               clc                   ;OK make sure everything is kosher
               xce
               phk
               plb
               rep   $30
               lda   stacksave       ;restore "our" stack
               tcs
               lda   dpsave          ;restore "our" DP
               pha
               pld

               bit   extrunflag      ;did we run the utility?
               bpl   :xit            ;minus=yes

               php                   ;save the interupt status
               sei                   ;turn of interupts so no problems
               do    0
               lda   p16vec
               stal  $e100a8         ;replace P16 vectors
               lda   p16vec+2
               stal  $e100a8+2
               lda   p16vec1
               stal  $e100b0
               lda   p16vec1+2
               stal  $e100b0+2
               fin
               plp                   ;restore interupts

:xit           jsr   unloadext
               plp
               rts

p16quit        phb                   ;save the environment
               phk
               plb
               sty   p16y            ;save the Y reg
               php
               sep   $20
               lda   $05,s           ;get bank of call
               pha
               plb                   ;set to current bank
               ldy   #$01
               lda   ($03,s),y       ;read the command num of p16 call
               cmp   #$29            ;is it QUIT?
               beq   p16qhandle      ;yes, so shutdown/restore everything
               plp                   ;if not restore what we changed
               phk
               plb
               ldy   p16y            ;restore the Y
               plb                   ;and the bank
p16vec         jml   $FFFFFF         ;jump to P16 entry vector
p16y           ds    2

p16quit1       phb                   ;save the current bank
               phk
               plb                   ;set to our bank
               php                   ;save the processor
               sep   $20
               lda   $06,s           ;get command num from stack
               cmp   #$29            ;quit?
               beq   p16qhandle      ;yes so restore/shutdown external
               plp                   ;restore what we changed and call
               plb                   ;old P16 vector
p16vec1        jml   $FFFFFF

unloadext      rts
               php
               rep   $30

               lda   extuserid       ;check for valid UserID
               beq   :handle         ;Script doesn't exist!=>

               pea   $00             ;Free Script memory
               lda   extuserid
               pha
               pea   $00
               tll   $1211           ;User ShutDown
               pla                   ;Don't know the meaning of this!

* lda extuserid
* pha
* tll $2103 ;delete id

:handle        lda   extdphdl        ;Check for valid DP handle
               ora   extdphdl+2
               beq   :xit            ;if = then no DP was allocated by us.
               psl   extdphdl
               _Disposehandle        ;Kill the handle
:xit           stz   extuserid
               stz   extdphdl
               stz   extdphdl+2
               stz   extrunflag
               plp
               rts                   ;and Return

asciiid        asc   'QUICK'

extdpadd       ds    2,0             ;Script DP address
extdplen       ds    2,0             ;Script DP length
extuserid      ds    2,0             ;Script UserID
extdphdl       ds    4,0             ;Script DP Handle
extadd         ds    4,0             ;Script Init Address
extrunflag     ds    2,0             ;flag indicating "running" application

externdflt     dw    externname-extpath
externpath     dfb   externname-extpath
extpath        asc   '/PROFILE/'     ;Name of the script file.
externname     ds    64,0
commandlen     ds    2



drawbox        php
               rep   $30
               lda   termcv
               sta   :cv
               lda   termch
               sta   :ch
               lda   #$05
               sta   termcv
               lda   #40
               sta   termch
               jsl   setch
               sep   $20
               ldx   #$0000
:main          ldy   #40
:loop          phy
               phx
               jsl   pickchar
               plx
               ply
               sta   boxbuff,x
               cpy   #40
               beq   :left
               cpy   #40+36
               beq   :right
               lda   termcv
               cmp   #$05
               beq   :top
               cmp   #$05+6
               beq   :bottom
               lda   #" "
               jmp   :next
:left          lda   #$DA-$80
               jmp   :next
:right         lda   #$DF-$80
               jmp   :next
:top           lda   #$CC-$80
               jmp   :next
:bottom        lda   #"_"
:next          phx
               phy
               jsl   storchar
               ply
               plx
               inx
               iny
               cpy   #40+36
               blt   :loop
               beq   :loop
               lda   termcv
               inc
               cmp   #5+7
               bge   :done
               sta   termcv
               phx
               jsl   setch
               plx
               jmp   :main
:done          rep   $30
               lda   :cv
               sta   termcv
               lda   :ch
               sta   termch
               jsl   setch
               plp
               rts
:ch            ds    2
:cv            ds    2

erasebox       php
               rep   $30
               lda   termcv
               sta   :cv
               lda   termch
               sta   :ch
               lda   #$05
               sta   termcv
               lda   #40
               sta   termch
               jsl   setch
               sep   $20
               ldx   #$0000
:main          ldy   #40
:loop          lda   boxbuff,x
:next          phx
               phy
               jsl   storchar
               ply
               plx
               inx
               iny
               cpy   #40+36
               blt   :loop
               beq   :loop
               lda   termcv
               inc
               cmp   #5+7
               bge   :done
               sta   termcv
               phx
               jsl   setch
               plx
               jmp   :main
:done          rep   $30
               lda   :cv
               sta   termcv
               lda   :ch
               sta   termch
               jsl   setch
               plp
               rts
:ch            ds    2
:cv            ds    2


]top           equ   5
]bottom        equ   17
]left          equ   10
]right         equ   70

drawbox1       php
               rep   $30
               lda   termcv
               sta   :cv
               lda   termch
               sta   :ch
               lda   #]top
               sta   termcv
               lda   #]left
               sta   termch
               jsl   setch
               sep   $20
               ldx   #$0000
:main          ldy   #]left
:loop          phy
               phx
               jsl   pickchar
               plx
               ply
               sta   boxbuff,x
               cpy   #]left
               beq   :left
               cpy   #]right
               beq   :right
               lda   termcv
               cmp   #]top
               beq   :top
               cmp   #]bottom
               beq   :bottom
               lda   #" "
               jmp   :next
:left          lda   #$DA-$80
               jmp   :next
:right         lda   #$DF-$80
               jmp   :next
:top           lda   #$CC-$80
               jmp   :next
:bottom        lda   #"_"
:next          phx
               phy
               jsl   storchar
               ply
               plx
               inx
               iny
               cpy   #]right
               blt   :loop
               beq   :loop
               lda   termcv
               inc
               cmp   #]bottom+1
               bge   :done
               sta   termcv
               phx
               jsl   setch
               plx
               jmp   :main
:done          rep   $30
               lda   :cv
               sta   termcv
               lda   :ch
               sta   termch
               jsl   setch
               plp
               rts
:ch            ds    2
:cv            ds    2

drawbox1a      php
               rep   $30
               lda   termcv
               sta   :cv
               lda   termch
               sta   :ch
               lda   #]top
               sta   termcv
               lda   #]left
               sta   termch
               jsl   setch
               sep   $20
               ldx   #$0000
:main          ldy   #]left
:loop          cpy   #]left
               beq   :left
               cpy   #]right
               beq   :right
               lda   termcv
               cmp   #]top
               beq   :top
               cmp   #]bottom
               beq   :bottom
               lda   #" "
               jmp   :next
:left          lda   #$DA-$80
               jmp   :next
:right         lda   #$DF-$80
               jmp   :next
:top           lda   #$CC-$80
               jmp   :next
:bottom        lda   #"_"
:next          phx
               phy
               jsl   storchar
               ply
               plx
               inx
               iny
               cpy   #]right
               blt   :loop
               beq   :loop
               lda   termcv
               inc
               cmp   #]bottom+1
               bge   :done
               sta   termcv
               phx
               jsl   setch
               plx
               jmp   :main
:done          rep   $30
               lda   :cv
               sta   termcv
               lda   :ch
               sta   termch
               jsl   setch
               plp
               rts
:ch            ds    2
:cv            ds    2



erasebox1      php
               rep   $30
               lda   termcv
               sta   :cv
               lda   termch
               sta   :ch
               lda   #]top
               sta   termcv
               lda   #]left
               sta   termch
               jsl   setch
               sep   $20
               ldx   #$0000
:main          ldy   #]left
:loop          lda   boxbuff,x
:next          phx
               phy
               jsl   storchar
               ply
               plx
               inx
               iny
               cpy   #]right
               blt   :loop
               beq   :loop
               lda   termcv
               inc
               cmp   #]bottom+1
               bge   :done
               sta   termcv
               phx
               jsl   setch
               plx
               jmp   :main
:done          rep   $30
               lda   :cv
               sta   termcv
               lda   :ch
               sta   termch
               jsl   setch
               plp
               rts
:ch            ds    2
:cv            ds    2


]top           equ   7
]bottom        equ   17
]left          equ   10+3
]right         equ   34+1

drawbox2       php
               rep   $30
               lda   termcv
               sta   :cv
               lda   termch
               sta   :ch
               lda   #]top
               sta   termcv
               lda   #]left
               sta   termch
               jsl   setch
               sep   $20
               ldx   #$0000
:main          ldy   #]left
:loop          lda   termcv
               cmp   #]top
               beq   :top
               cmp   #]bottom
               beq   :bottom
:loop2         cpy   #]left
               beq   :left
               cpy   #]right
               beq   :right
:spc           lda   #" "
               jmp   :next
:left          lda   #$DA-$80
               jmp   :next
:right         lda   #$DF-$80
               jmp   :next
:top           cpy   #]right
               beq   :spc
               cpy   #]left
               beq   :spc
               lda   #"_"            ;#$CC-$80
               jmp   :next
:bottom        cpy   #]right
               beq   :ul
               cpy   #]left
               beq   :ul
               lda   #$dc-$80        ;#"_"
               jmp   :next
:ul            lda   #"_"
:next          phx
               phy
               jsl   storchar
               ply
               plx
               inx
               iny
               cpy   #]right
               blt   :loop
               beq   :loop
               lda   termcv
               inc
               cmp   #]bottom+1
               bge   :done
               sta   termcv
               phx
               jsl   setch
               plx
               jmp   :main
:done          rep   $30
               lda   :cv
               sta   termcv
               lda   :ch
               sta   termch
               jsl   setch
               plp
               rts
:ch            ds    2
:cv            ds    2


insertcr       rep   $30             ;NOT a subroutine
               lda   flen
               cmp   #$ffff
               bge   :cmdxit
               sep   $20
               ldy   pos
               lda   #$8d
               sta   linebuff+1,y
               lda   pos
               sta   oldlen
               inc
               sta   linebuff
               rep   $30
               lda   #$ffff
               sta   dirty
               jsr   savebuff
               rep   $30
               jsr   updatescreen

               lda   termcv
               inc
               cmp   #22
               blt   :dok
               jsl   scroll
               lda   #21
:dok           sta   termcv
               jsl   setch
               jsr   foreptr
               jsr   getbuff
               jsr   drawline
               stz   pos
               stz   pos1
               jsr   poscurs
               rep   $30
               inc   linenum
               jsr   drawcpos

:cmdxit        plp
               clc
               rts

               do    0
               jsr   drawcpos
               jsr   getbuff
               jsr   drawline
               stz   pos
               stz   pos1
               inc   linenum
               jsr   poscurs
               jsr   setfflags
               fin

loadfile       rep   $30             ;NOT a subroutine!!!!
               stz   getname
               stz   :flag

               jsr   getfname
               lda   getname
               and   #$ff
               beq   :all
               cmp   #$ff
               jeq   :cmdxit

               sec
               ror   :flag
               tax
               sep   $20
:m1            lda   getname,x
               sta   efilename,x
               dex
               bpl   :m1
               rep   $20
               jmp   :l

:all           lda   alldirty
               beq   :l

:l             stz   :openflag
               stz   :merlin
               stz   :toolarge
               stz   :loaded

               lda   linenum
               sta   gotolnum

:sep           sep   $30
               ldx   efilename
]lup           lda   efilename,x
               and   #$7f
               cmp   #'a'
               blt   :uc1
               cmp   #'z'+1
               bge   :uc1
               and   #$5f
:uc1           sta   :filename,x
               sta   loadfilename,x
               dex
               bpl   ]lup
               rep   $30

               jsr   drawbox
               bit   :flag
               jmi   :rep
               jsr   drawesccan
               jsl   print
               dfb   44
               dfb   7
               asc   "Load which file:",00
               jsl   getline
               adrl  :filename
               dfb   15
               dfb   44
               dfb   10
               php
               jsr   drawesc
               plp
               jcs   :sfplp
:rep           rep   $30
               lda   :filename
               and   #$00FF
               jeq   :sfplp
               jsl   print
               dfb   44
               dfb   7
               asc   "Loading...      ",00
               stz   :openflag
               lda   :filename
               and   #$ff
               cmp   #3
               blt   :ginfo
               tax
               lda   :filename,x
               and   #$7f
               cmp   #'S'
               beq   :gdex
               cmp   #'s'
               bne   :ginfo
:gdex          dex
               lda   :filename,x
               and   #$7f
               cmp   #'.'
               bne   :ginfo
               sec
               ror   :merlin
:ginfo         jsl   prodos
               dw    $06
               adrl  :info
               bcc   :gtype
               jmp   :err

               do    0
               cmp   #$46
               jne   :err
:chk           bit   :merlin
               jmi   :err
               sec
               ror   :merlin
               sta   :errcode
               lda   :filename
               and   #$00ff
               cmp   #14
               blt   :chkmerlin
:ec            lda   :errcode
               jmp   :err
:chkmerlin     lda   :filename
               and   #$00ff
               tax
               lda   :filename,x
               and   #$7f
               cmp   #'/'
               bne   :cm
               sep   $20
               dec   :filename
               rep   $30
               jmp   :ginfo
:cm            lda   :filename
               and   #$ff
               inc
               tax
               sep   $20
               lda   #'.'
               sta   :filename,x
               inx
               lda   #'S'
               sta   :filename,x
               txa
               sta   :filename
               rep   $20
               jmp   :ginfo
               fin

:gtype         lda   :type
               cmp   #$04            ;text
               beq   :doopen
               cmp   #$b0            ;SRC
               beq   :srcb0
               cmp   #$1a
               beq   :apw
               jmp   :nottxt
:srcb0         stz   :merlin
               jmp   :doopen

:nottxt        lda   #nottext
               jmp   :err

:apw           jmp   loadapw

:doopen        jsl   prodos
               dw    $10
               adrl  :open
               jcs   :err
               sec
               ror   :openflag
               lda   :open
               sta   :read
               sta   :close
               sta   :eof
               jsl   prodos
               dw    $19             ;get eof
               adrl  :eof
               lda   :eof+2
               sta   :request
               cmp   #$ffff
               beq   :too
               lda   :eof+4
               beq   :z
:too           sec
               ror   :toolarge
               lda   #$fffe
               sta   :request
:z
               stz   :request+2

               lda   fileptr
               sta   :where
               lda   fileptr+2
               sta   :where+2

               jsr   newdoc1         ;everything is wasted here....

               jsl   prodos
               dw    $12
               adrl  :read
               jcs   :err

               jsl   prodos
               dw    $14
               adrl  :close
               stz   :openflag

               lda   :request+4
               sta   flen
               sta   editlen

               stz   gotolnum
               sec
               ror   :loaded

:sfplp         rep   $30
               bit   :openflag
               bpl   :set
               jsl   prodos
               dw    $14
               adrl  :close
               stz   :openflag

:set           bit   :loaded
               bpl   :bit

               bit   :merlin
               bpl   :zero
               sep   $20
:tabson        ldx   #$07
]lup           lda   tabs1,x
               sta   tabs,x
               dex
               bpl   ]lup

:zero          sep   $30
               ldx   :filename
]lup           lda   :filename,x
               and   #$7f
               cmp   #'a'
               blt   :uc
               cmp   #'z'+1
               bge   :uc
               and   #$5f
:uc            sta   efilename,x
               dex
               bpl   ]lup
               rep   $30

:bit           bit   :toolarge
               bpl   :sfplp1
               jmp   :toolarge1
:sfplp1        jsr   erasebox
               jsr   gotoline
               jsr   drawmem
               jsr   drawtabs
               jsr   drawfname
:cmdxit        plp
               clc
               rts
:err           rep   $30
               jsr   doerror
               stz   :toolarge
               jmp   :sfplp

:toolarge1     lda   #toobigerr
               jmp   :err

:merlin        ds    2
:errcode       ds    2
:toolarge      ds    2
:loaded        ds    2
:openflag      ds    2
:flag          ds    2
:close         ds    2
:open          ds    2
               adrl  :filename
               adrl  $0000
:read          ds    2
:where         adrl  $00
:request       adrl  $00
               adrl  $00
:info          adrl  :filename
               ds    2
:type          ds    2
:aux           ds    4
               ds    16
:eof           ds    6

:filename      ds    20


checkload      php
               rep   $30
               stz   :flag
               psl   #tempbuff
               pea   128
               _QAGetCmdLine
               ldx   #tempbuff
               ldy   #^tempbuff
               jsr   parsepath
               bcc   :load
               plp
               sec
               rts
:load
               sec
               ror   :flag
               lda   filename
               and   #$ff
               tax
               sep   $20
:m1            lda   filename,x
               sta   efilename,x
               dex
               bpl   :m1
               rep   $20
               jmp   :l

:all           lda   alldirty
               beq   :l

:l             stz   :openflag
               stz   :merlin
               stz   :toolarge
               stz   :loaded

               lda   linenum
               sta   gotolnum

:sep           sep   $30
               ldx   efilename
]lup           lda   efilename,x
               and   #$7f
               cmp   #'a'
               blt   :uc1
               cmp   #'z'+1
               bge   :uc1
               and   #$5f
:uc1           sta   filename,x
               sta   loadfilename,x
               dex
               bpl   ]lup
               stz   efilename
               stz   loadfilename

               rep   $30
               lda   filename
               and   #$00FF
               jeq   :sfplp
               stz   :openflag
               sep   $30
               ldx   filename
               lda   filename,x
               and   #$7f
               cmp   #'/'
               beq   :nosufx
               cpx   #63
               bge   :nosufx
               inx
               lda   #'.'
               sta   filename,x
               inx
               lda   #'S'
               sta   filename,x
               stx   filename
               rep   $30
               sec
               ror   :merlin
:nosufx        rep   $30
:ginfo         jsl   prodos
               dw    $06
               adrl  :info
               bcc   :gtype
               jmp   :err

:gtype         lda   :type
               cmp   #$04            ;text
               beq   :doopen
               cmp   #$b0            ;SRC
               beq   :srcb0
* cmp #$1a
* beq :apw
               jmp   :nottxt
:srcb0         stz   :merlin
               jmp   :doopen

:nottxt        lda   #nottext
               jmp   :err

:apw           jmp   loadapw

:doopen        jsl   prodos
               dw    $10
               adrl  :open
               jcs   :err
               sec
               ror   :openflag
               lda   :open
               sta   :read
               sta   :close
               sta   :eof
               jsl   prodos
               dw    $19             ;get eof
               adrl  :eof
               lda   :eof+2
               sta   :request
               cmp   #$ffff
               beq   :too
               lda   :eof+4
               beq   :z
:too           sec
               ror   :toolarge
               lda   #$fffe
               sta   :request
:z
               stz   :request+2

               lda   fileptr
               sta   :where
               lda   fileptr+2
               sta   :where+2

               jsr   newdoc1         ;everything is wasted here....

               jsl   prodos
               dw    $12
               adrl  :read
               jcs   :err

               jsl   prodos
               dw    $14
               adrl  :close
               stz   :openflag

               lda   :request+4
               sta   flen
               sta   editlen

               stz   gotolnum
               sec
               ror   :loaded

:sfplp         rep   $30
               bit   :openflag
               bpl   :set
               jsl   prodos
               dw    $14
               adrl  :close
               stz   :openflag

:set           bit   :loaded
               bpl   :bit

               bit   :merlin
               bpl   :zero
               sep   $20
:tabson        ldx   #$07
]lup           lda   tabs1,x
               sta   tabs,x
               dex
               bpl   ]lup

:zero          sep   $30
               ldx   filename
]lup           lda   filename,x
               and   #$7f
               cmp   #'a'
               blt   :uc
               cmp   #'z'+1
               bge   :uc
               and   #$5f
:uc            sta   efilename,x
               dex
               bpl   ]lup
               rep   $30

:bit           bit   :toolarge
               bpl   :sfplp1
               jmp   :toolarge1
:sfplp1        jsr   gotoline
               jsr   drawmem
               jsr   drawtabs
               jsr   drawfname
:cmdxit        plp
               clc
               rts
:err           rep   $30
               pha
               jsr   drawbox
               pla
               jsr   doerror
               jsr   erasebox
               stz   :toolarge
               jmp   :sfplp

:toolarge1     lda   #toobigerr
               jmp   :err

:merlin        ds    2
:errcode       ds    2
:toolarge      ds    2
:loaded        ds    2
:openflag      ds    2
:flag          ds    2
:close         ds    2
:open          ds    2
               adrl  filename
               adrl  $0000
:read          ds    2
:where         adrl  $00
:request       adrl  $00
               adrl  $00
:info          adrl  filename
               ds    2
:type          ds    2
:aux           ds    4
               ds    16
:eof           ds    6

filename       ds    130,0
tempbuff       ds    256,0

ptr            =     0

parsepath      php
               rep   $30
:get           stx   ptr
               sty   ptr+2
               stz   filename
:go            ldy   #1
               sep   $20
               lda   [ptr]
               beq   :nopath
]lup           lda   [ptr],y
               and   #$7F
               cmp   #' '
               blt   :nopath
               bne   :l1
               iny
               jmp   ]lup
:l1            iny
               lda   [ptr],y
               and   #$7F
               cmp   #' '
               blt   :nopath
               bne   :l1
:l2            iny
               lda   [ptr],y
               and   #$7F
               cmp   #' '
               blt   :nopath
               beq   :l2
               cmp   #';'
               beq   :nopath
               rep   $30
               dey
               jsr   :getword        ;look for pathname or save
               bcc   :nopath
               lda   #$0000
               jmp   :error
:nopath        rep   $30
               lda   #$46
* _getprefix :pfx
:error         plp
               cmp   :one
               rts
:pfx           dw    $00
               adrl  filename

:getword       php
               sep   $30
               ldx   #0              ;no chars yet!
               stx   filename
]loop
               iny
               lda   [ptr],y         ;get pathname till eol or delimiter found
               and   #$7F
               clc
               beq   :done           ; 0 = end of line!
               cmp   #'.'
               blt   :done
               inx                   ;part of path, count & store it
               cpx   #65
               bge   :done           ;let's not let the bad boys in!
               cmp   #'a'
               blt   :sta
               cmp   #'z'+1
               bge   :sta
               and   #$5F
:sta           sta   filename,x      ;update pathname & it's length
               stx   filename
               bra   ]loop
:done          lda   filename
               plp
               cmp   :one
               rts
:one           dw    $01



showhelp       rep   $30

               plp
               clc
               rts

               lda   termch
               pha
               lda   termcv
               pha
               jsr   drawbox1
               jsl   print
               dfb   18
               dfb   8
               asc   "No Help available. ",00
               lda   #20
               sta   mych
               lda   #7
               sta   mycv
               jsl   textbascalc

:pkey          jsl   keyscan
               bpl   :pkey
               jsr   erasebox1
               pla
               sta   termcv
               pla
               sta   termch
               jsl   setch
               plp
               clc
               rts

]left          equ   20

exitquestion
               php
               rep   $30
               jsr   drawbox
               jsr   drawesccan1
               jsl   print
               dfb   47
               dfb   7
               asc   "Release buffer memory?",00
               sep   $30
               jsr   yesno
               dfb   51+3
               dfb   9
               rep   $30
               and   #$00ff
               pha
               php
               jsr   erasebox
               jsr   drawesc
               plp
               pla
               bcs   :sec
               cmp   #$01
               blt   :clc
               lda   #$ffff
               sta   superquit
:clc           plp
               clc
               rts
:sec           plp
               sec
               rts

aboutsd
               do    softdisk
               php
               rep   $30
* jsr erasebox1
               jsr   drawbox1a

               jsl   print
               dfb   ]left
               dfb   12-6
               asc   "Another fine program from:",00
               jsl   print
               dfb   ]left
               dfb   14-6
               asc   "         SoftDisk Publishing, Inc.",00
               jsl   print
               dfb   ]left
               dfb   15-6
               asc   "             606 Common Street",00

               jsl   print
               dfb   ]left
               dfb   16-6
               asc   "           Shreveport, LA  71101"00



               jsl   print
               dfb   ]left-4
               dfb   18-6
               asc   "For more information on SoftDisk, or to subscribe",00
               jsl   print
               dfb   ]left-4
               dfb   19-6
               asc   " to our monthly disk magazine that contains more",00
               jsl   print
               dfb   ]left-4
               dfb   20-6
               asc   "   GREAT programs like this one....call us at:",00

               jsl   print
               dfb   ]left-4
               dfb   22-6
               asc   "                1-800-831-2694",00

               plp
               rts
               else
               rts
               fin


getfname
               rep   $30
               lda   termch
               sta   :tch
               lda   termcv
               sta   :tcv
               stz   :iflag
               stz   :handle
               stz   :handle+2
:current       rep   $30
               stz   :count
               stz   :errflag
               stz   getname
               jsl   prodos
               dw    $0a
               adrl  :pfxparm
               sep   $20
               dec   :pfx

:showcat       rep   $30
               stz   :openflag
               stz   :close
               stz   :handle
               stz   :handle+2
               jsl   prodos
               dw    $06
               adrl  :info
               jcs   :caterr
               lda   :type
               cmp   #$0f
               jne   :nodir
               jsl   prodos
               dw    $10
               adrl  :open
               jcs   :caterr
               sec
               ror   :openflag
               lda   :open
               sta   :eof
               sta   :close
               sta   :read
               jsl   prodos
               dw    $19
               adrl  :eof
               jcs   :caterr

               psl   #$00
               psl   :eof1
               lda   userid
               pha
               pea   $C000
               psl   #$00
               tll   $0902
               plx
               ply
               jcs   :nomem
               stx   :handle
               stx   zpage
               sty   :handle+2
               sty   zpage+2
               lda   :eof1
               sta   :request
               lda   :eof1+2
               sta   :request+2
               ldy   #$02
               lda   [zpage]
               sta   :buffer
               lda   [zpage],y
               sta   :buffer+2
               jsl   prodos
               dw    $12
               adrl  :read
               jcs   :caterr
               jsl   prodos
               dw    $14
               adrl  :close
               jcs   :caterr
               stz   :openflag
               jmp   :bx
:caterr        rep   $30

               bit   :openflag
               bpl   :nodir
               jsl   prodos
               dw    $14
               adrl  :close
               stz   :openflag
               jcs   :caterr
:nodir
:nomem         sec
               ror   :errflag

:bx            rep   $30
               bit   :iflag
               jmi   :h
               jsr   drawbox1
               jsr   drawbox2
               lda   #$07
               ldx   #50-4
               ldy   #$00
               jsr   drawbutton
               lda   #$07+2
               ldx   #50-4
               ldy   #$8000
               jsr   drawbutton
               lda   #$07+4
               ldx   #50-4
               ldy   #$8000
               jsr   drawbutton
               lda   #$07+6
               ldx   #50-4
               ldy   #$ffff
               jsr   drawbutton

               jsl   print
               hex   3208
               asc   "Drive: <TAB>",00
               jsl   print
               hex   320A
               asc   "Open:  <CR>",00
               jsl   print
               hex   320C
               asc   "Close: <ESC>",00
               jsl   print
               hex   320E
               asc   "Cancel:<DEL>",00

:h             sec
               ror   :iflag
               jsr   :erase1
               bit   :errflag
               bpl   :deref
               stz   :entrylen
               stz   :entper
               stz   :count
               stz   :filepos
               stz   :selectpos
               jmp   :adc3
:deref         lda   :handle
               sta   dirzp
               lda   :handle+2
               sta   dirzp+2
               ldy   #$02
               lda   [dirzp]
               tax
               lda   [dirzp],y
               sta   dirzp+2
               stx   dirzp


:adc1          ldy   #$23
               lda   [dirzp],y
               and   #$00ff
               sta   :entrylen
               iny
               lda   [dirzp],y
               and   #$ff
               sta   :entper
               iny
               lda   [dirzp],y
               sta   :count
               stz   :filepos
               stz   :selectpos

:adc           ldy   #$04
               lda   [dirzp],y
               and   #$0f
               sta   :entlen
:adc3          rep   $30
               lda   #6
               sta   mycv
               lda   #22-7
               sta   mych
               jsl   textbascalc
               jsl   prodos
               dw    $0a
               adrl  :pfxparm
               ldx   #$01
               lda   :pfx
               and   #$ff
               beq   :c
               tay
]lup           lda   :pfx,x
               phy
               phx
               and   #$7f
               pha
               tll   $180c
               plx
               ply
               inx
               dey
               bne   ]lup
:c
]lup           cpx   #$40-8
               bge   :scd
               phx
               pea   $a0
               tll   $180c
               plx
               inx
               jmp   ]lup
:scd           stz   :catwhich
               jsr   :catdraw
               lda   #$00
               jsr   :select
:key
               do    mouse
;jsr initmouse
               lda   #$8d
               sta   mousecrchar
               lda   #$FFFF
               sta   mousecr
:key2          jsr   mousekey
               bmi   :and7f
               else
:key2
               fin                   ;--- mouse ---

               jsl   keyscan
               bpl   :key2
:and7f         and   #$7f
               cmp   #$1b
               jeq   :tab
               cmp   #$0d
               jeq   :showxitcr
               cmp   #$7f
               jeq   :showxitesc
               cmp   #$09
               jeq   :tab1
               ldy   :count
               beq   :key
               cmp   #$0a
               jeq   :down
               cmp   #$0b
               jeq   :up
               jmp   :key
:showxitcr     rep   $30
               jsr   :but2
               lda   getname
               and   #$ff
               jeq   :key
               jsl   prodos
               dw    $06
               adrl  :info1
               jcs   :key
               lda   :type1
               cmp   #$0f
               beq   :crdir
               cmp   #$04
               beq   :eb1
               cmp   #$b0
               beq   :eb1
               cmp   #$1a
               beq   :eb1
               jmp   :key
:crdir         lda   :pfx
               and   #$ff
               tax
               sep   $20
               clc
               adc   getname
               cmp   #64
               bge   :bell
               sta   :pfx
               ldy   #$01
               inx
]lup           lda   getname,y
               sta   :pfx,x
               iny
               inx
               cpy   #$10
               blt   ]lup
               jmp   :pfxset1
:bell          rep   $20
               tll   $2c03
               jmp   :key
:showxitesc    lda   #$ff
               sta   getname
               jsr   :but4
:eb1           jsr   erasebox1
               lda   #$01
:catxit        pha
               lda   :handle
               ora   :handle+2
               beq   :nodis
               psl   :handle
               _Disposehandle
:nodis         rep   $30
               lda   :tch
               sta   termch
               lda   :tcv
               sta   termcv
               jsl   setch
               pla
               clc
               rts
:tch           ds    2
:tcv           ds    2
:errflag       ds    2

:tab           jmp   :poppfx
:tab1          jmp   :newdisk

:up            lda   :selectpos
               beq   :upxit
               cmp   :filepos
               beq   :ups
               jsr   :erase
               dec   :selectpos
               lda   :selectpos
               sec
               sbc   :filepos
               jsr   :select
               jmp   :key

:ups           lda   #$8000
               sta   :catwhich
               jsr   :erase
               jsr   catscrolldn1
               dec   :filepos
               dec   :selectpos
               jsr   :catdraw
               lda   #$00
               jsr   :select
:upxit         jmp   :key
:down          lda   :selectpos
               sec
               sbc   :filepos
               bcc   :down1
               cmp   #catentries-1
               bge   :down1
               lda   :selectpos
               inc
               cmp   :count
               bge   :upxit
               sta   :selectpos
               jsr   :erase
               lda   :selectpos
               sec
               sbc   :filepos
               jsr   :select
               jmp   :key
:down1         lda   :filepos
               clc
               adc   #catentries
               cmp   :count
               bge   :upxit
               inc   :filepos
               inc   :selectpos
               jsr   :erase
               jsr   catscrollup1
               lda   #$4000
               sta   :catwhich
               jsr   :catdraw
               lda   #catentries-1
               jsr   :select
               jmp   :key

:select        php
               rep   $30
               stz   getname
               ldx   :count
               jeq   :sexit
               clc
               adc   #$08
               sta   termcv
               sta   :oldselect
               lda   #22-7
               sta   termch
               lda   termcv
               jsl   setch
               lda   termch
               tay
               stz   :sbit
               ldx   #$00
               sep   $20
:sloop1        jsl   pickchar
               and   #$7f
               bit   :sbit
               bmi   :scmp
               cmp   #'.'
               beq   :son
               cmp   #'0'
               blt   :soff
               cmp   #'9'+1
               blt   :son
               cmp   #'A'
               blt   :soff
               cmp   #'Z'+1
               blt   :son
               cmp   #'a'
               blt   :soff
               cmp   #'z'+1
               bge   :soff
:son           sta   getname+1,x
               inx
               pha
               txa
               sta   getname
               pla
               jmp   :scmp
:soff          sec
               ror   :sbit
:scmp          cmp   #$40
               blt   :stor
               cmp   #$60
               bge   :stor
               sec
               sbc   #$40
:stor          jsl   storchar
               iny
               cpy   #34
               blt   :sloop1
               rep   $20
:sexit         nop                   ;jsr showpath
               plp
               rts
:sbit          ds    2


:newdisk       rep   $30
               jsr   :but1
               jsl   prodos
               dw    $21
               adrl  :lastdev
               lda   :lastdev
               sta   :ldev1
]loop          inc   :lastdev
               lda   :lastdev
               cmp   :ldev1
               jeq   :nonew
               sta   :devname
               jsl   prodos
               dw    $2c
               adrl  :devname
               bcc   :dpfxset1
               cmp   #$11
               bne   ]loop
               stz   :lastdev
               jmp   ]loop
:dpfxset1      jsl   prodos
               dw    $08
               adrl  :volume
               jcs   ]loop
               lda   :volname
               sta   zpage
               lda   :volname+2
               sta   zpage+2
               lda   [zpage]
               and   #$ff
               tay
               sep   $20
]lup           lda   [zpage],y
               sta   :pfx,y
               dey
               bpl   ]lup
               rep   $30
               jmp   :pfxset1
:lastdev       ds    2
:ldev1         ds    2
:devname       ds    2
               adrl  :devname1
:devname1      ds    33,0
:volume        adrl  :devname1
:volname       adrl  $00
               ds    4
               ds    4
               dw    $00

:poppfx        rep   $30
               jsr   :but3
               stz   :pfx
               jsl   prodos
               dw    $0a
               adrl  :pfxparm2
               lda   :pfx
               and   #$00ff
               beq   :nonew
               dec
               beq   :nonew
               tay
]lup           lda   :pfx,y
               and   #$7f
               cmp   #'/'
               beq   :pfxset
               dey
               cpy   #$03
               bge   ]lup
               jmp   :nonew
:pfxset        cpy   #$02
               blt   :nonew
               tya
               sep   $20
               sta   :pfx
:pfxset1       rep   $20
               jsl   prodos
               dw    $09
               adrl  :pfxparm2
               lda   :handle
               ora   :handle+2
               beq   :np1
               psl   :handle
               _Disposehandle
               stz   :handle
               stz   :handle+2
:np1           jmp   :current
:nonew         rep   $30
               jmp   :key

:savech        php
               rep   $30
               lda   termch
               sta   :sch1
               lda   termcv
               sta   :sch2
               sta   termch
               stx   termcv
               jsl   setch
               plp
               rts
:rstch         php
               rep   $30
               lda   :sch1
               sta   termch
               lda   :sch2
               sta   termcv
               jsl   setch
               plp
               rts
:sch1          ds    2
:sch2          ds    2

:but1          php
               rep   $30
               lda   #$08
               jsr   :invbut
               plp
               rts
:but2          php
               rep   $30
               lda   #$0A
               jsr   :invbut
               plp
               rts
:but3          php
               rep   $30
               lda   #$0C
               jsr   :invbut
               plp
               rts
:but4          php
               rep   $30
               lda   #$0E
               jsr   :invbut
               plp
               rts


:invbut        php
               rep   $30
               tax
               lda   #$30
               jsr   :savech
               ldy   #$30
]lup           jsl   pickchar
               and   #$7f
               cmp   #$40
               blt   :ibok
               cmp   #$60
               bge   :ibok
               sec
               sbc   #$40
:ibok          jsl   storchar
               iny
               cpy   #$40
               blt   ]lup

               ldx   #$7000
]lup           sec
               sbc   #$01
               dex
               bne   ]lup

               ldy   #$30
]lup           jsl   pickchar
               ora   #$80
               jsl   storchar
               iny
               cpy   #$40
               blt   ]lup
               jsr   :rstch
               plp
               rts

:erase         php
               rep   $30
               lda   :oldselect
               sta   termcv
               sta   :oldselect
               lda   #22-7
               sta   termch
               lda   termcv
               jsl   setch
               lda   termch
               tay
               sep   $20
:sloop2        jsl   pickchar
               cmp   #$01
               blt   :ora
               cmp   #$20
               bge   :ora
               clc
               adc   #$40
:ora           ora   #$80
               jsl   storchar
               iny
               cpy   #34
               blt   :sloop2
               rep   $20
               plp
               rts

:erase1        php
               rep   $30
               lda   #$08
               sta   termcv
:e1l1          lda   #22-7
               sta   termch
               lda   termcv
               jsl   setch
               lda   termch
               tay
               sep   $20
:sloop21       lda   #$a0
               jsl   storchar
               iny
               cpy   #34
               blt   :sloop21
               rep   $30
               inc   termcv
               lda   termcv
               cmp   #8+catentries
               blt   :e1l1
               rep   $20
               plp
               rts

:count         ds    2
:entrylen      ds    2
:filepos       ds    2
:entper        ds    2
:selectpos     ds    2
:oldselect     ds    2
:len           ds    2
:handle        ds    4
:openflag      ds    2

:open          dw    $00
               adrl  :pfx
               adrl  $00
:info          adrl  :pfx
               dw    $00
:type          dw    $00
               adrl  $00
               ds    14,0
:info1         adrl  getname
               dw    $00
:type1         dw    $00
               adrl  $00
               ds    14,0
:read          dw    $00
:buffer        adrl  $00
:request       adrl  $00
:transfer      adrl  $00
:eof           dw    $00
:eof1          adrl  $00
:close         dw    $00

:pfxparm       dw    $00
               adrl  :pfx
:pfxparm2      dw    $00
               adrl  :pfx

:pfx           ds    129,0

:iflag         ds    2

:cdpos         ds    2
:catwhich      ds    2

:catdraw       php
               rep   $30
               lda   #08
               sta   mycv
               lda   :filepos
               sta   :cdpos
               sta   :cdcount
:cdloop        lda   :cdpos
               cmp   :count
               jge   :cdxit
               lda   mycv
               cmp   #8+catentries
               jge   :cdxit
               lda   #22-7
               sta   mych
               jsl   textbascalc

:pha           pha
               pha
               lda   :cdcount
               inc
               pha
               lda   :entper
               pha
               tll   $0b0b
               pla
               sta   :blocknum
               pla
               sta   :remain
               lda   :blocknum
               xba
               asl                   ;* $200
               clc
               adc   #$04
               sta   :ypos

               pha
               pha
               lda   :entrylen
               pha
               lda   :remain
               pha
               tll   $090b
               pla
               plx
               clc
               adc   :ypos
               sta   :ypos

               ldy   :ypos
               lda   [dirzp],y
               and   #$f0
               bne   :cshow
:inccd         inc   :cdcount
               jmp   :pha
:cshow         bit   :catwhich
               bvc   :cshow1
               lda   mycv
               inc
               cmp   #8+catentries
               jlt   :inccv
:cshow1        jsr   :printent
               bit   :catwhich
               bmi   :cdxit
:inccv         inc   mycv
               inc   :cdcount
               inc   :cdpos
               jmp   :cdloop
:cdxit         plp
               rts

:printent      php
               rep   $30
* pea $FF
* pea $80
* tll $0a0c
* lda :cdpos
* cmp :selectpos
* bne :ly
* pea $FF
* pea $00
* tll $0a0c
:ly            ldy   :ypos
               lda   [dirzp],y
               and   #$0f
               beq   :inccd
               sta   :entlen
               iny
               ldx   #$01
]lup           lda   [dirzp],y
               and   #$7f
               phx
               phy
               pha
               tll   $180c
               ply
               plx
               inx
               iny
               cpx   :entlen
               blt   ]lup
               beq   ]lup
]lup           cpx   #$11
               bge   :dtype
               lda   #$a0
               phx
               pha
               and   #$7f
               tll   $180c
               plx
               inx
               jmp   ]lup
:dtype         lda   :ypos
               clc
               adc   #$10
               tay
               lda   [dirzp],y
               and   #$ff
               pha
               asl
               clc
               adc   1,s
               plx
               tax
               lda   filetypelist,x
               phx
               pha
               and   #$7f
               tll   $180c
               plx
               inx
               lda   filetypelist,x
               phx
               pha
               and   #$7f
               tll   $180c
               plx
               inx
               lda   filetypelist,x
               pha
               and   #$7f
               tll   $180c

               do    0
               pea   $20
               tll   $180c
               pea   $20
               tll   $180c
:daux          pea   #'$'
               tll   $180c
               lda   :ypos
               clc
               adc   #$1f
               tay
               lda   [dirzp],y
               jsr   :prbytel

               pea   $20
               tll   $180c
               pea   $20
               tll   $180c
:dlen          pea   #'$'
               tll   $180c
               lda   :ypos
               clc
               adc   #$15
               tay
               lda   [dirzp],y
               jsr   :prbytel
               pea   $20
               tll   $180c
               pea   $20
               tll   $180c

               lda   :ypos
               clc
               adc   #$21
               tay
               lda   [dirzp],y
               sta   :year
               iny
               iny
               lda   [dirzp],y
               sta   :time

               lda   :year
               and   #%11111
               sta   :decimal
               cmp   #$0a
               bge   :d1
               pea   #' '
               tll   $180c
:d1            psl   #:decimal
               pea   $0000
               jsl   printdec
               pea   #'-'
               tll   $180c

               lda   :year
               lsr
               lsr
               lsr
               lsr
               lsr
               and   #%1111
               dec
               asl
               asl
               tax

               lda   ftmonths,x
               phx
               pha
               and   #$7f
               tll   $180c
               plx
               inx
               lda   ftmonths,x
               phx
               pha
               and   #$7f
               tll   $180c
               plx
               inx
               lda   ftmonths,x
               pha
               and   #$7f
               tll   $180c
               pea   #'-'
               tll   $180c

               lda   :year
               xba
               lsr
               and   #%1111111
               sta   :decimal
               cmp   #$0a
               bge   :d2
               pea   #'0'
               tll   $180c
:d2            psl   #:decimal
               pea   $0000
               jsl   printdec
               pea   #' '
               tll   $180c
               pea   #' '
               tll   $180c

               lda   :time
               xba
               and   #%11111
               sta   :decimal
               cmp   #$0a
               bge   :d3
               pea   #' '
               tll   $180c
:d3            psl   #:decimal
               pea   $0000
               jsl   printdec
               pea   #':'
               tll   $180c

               lda   :time
               and   #%111111
               sta   :decimal
               cmp   #$0a
               bge   :d4
               pea   #'0'
               tll   $180c
:d4            psl   #:decimal
               pea   $0000
               jsl   printdec

               fin
* pea $FF
* pea $80
* tll $0a0c

               plp
               rts


:cdcount       ds    2
:ypos          ds    2
:entlen        ds    2
:blocknum      ds    2
:remain        ds    2
:decimal       ds    2
:year          ds    2
:time          ds    2

:prbytel       php
               rep   $30
               sta   :byte
               xba
               jsr   :prbyte
               lda   :byte
               jsr   :prbyte
               plp
               rts
:byte          ds    2

:prbyte        php
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
               plp
               rts
:nib           ora   #"0"
               cmp   #"9"+1
               blt   :ok
               adc   #"A"-"9"-2
:ok            and   #$7F
               pha
               tll   $180c
               rts


drawbutton     php
               rep   $30
               sta   :temp
               sty   :flag
               lda   termch
               pha
               lda   termcv
               pha
               lda   :temp
               sta   termcv
               stx   termch
               stx   :temp
               jsl   setch

               bit   :flag
               bmi   :1

               ldx   #$00
               ldy   :temp
               iny
]lup           lda   #"_"
               phx
               phy
               jsl   storchar
               ply
               plx
               iny
               inx
               cpx   #20-2
               blt   ]lup
:1             inc   termcv
               jsl   setch

               ldy   :temp
               lda   #$da-$80
               jsl   storchar
               iny
               lda   #$20
               jsl   storchar
               iny
               ldx   #$00
]lup           lda   #$a0
               jsl   storchar
               iny
               inx
               cpx   #20-4
               blt   ]lup
               lda   #$20
               jsl   storchar
               iny
               lda   #$df-$80
               jsl   storchar
               inc   termcv
               jsl   setch
               ldy   :temp
               iny
               ldx   #$00
]lup           bit   :flag
               bvs   :n
               lda   #$dc-$80
               bra   :jsl
:n             lda   #$cc-$80
:jsl           jsl   storchar
               iny
               inx
               cpx   #20-2
               blt   ]lup

:xit           rep   $30
               pla
               sta   termcv
               pla
               sta   termch
               plp
               rts
:temp          ds    2
:flag          ds    2


clrescreen                           ;ent ;routine clears the editor screen
                                     ;top 2 and bottom 2 lines left alone
               phy
               php
               phb
               rep   $30
               ldy   #$26            ;get ready for each column
:start         pea   $0101
               plb
               plb
               lda   #$A0A0
               sta   $6D0,Y
               sta   $650,Y
               sta   $5D0,Y
               sta   $550,Y
               sta   $4D0,Y
               sta   $450,Y
               sta   $7A8,Y
               sta   $728,Y
               sta   $6A8,Y
               sta   $628,Y
               sta   $5A8,Y
               sta   $528,Y
               sta   $4A8,Y
               sta   $428,Y
               sta   $780,Y
               sta   $700,Y
               sta   $680,Y
               sta   $600,Y
               sta   $580,Y
               sta   $500,Y
               pea   #$0000
               plb
               plb
               sta   $6D0,Y
               sta   $650,Y
               sta   $5D0,Y
               sta   $550,Y
               sta   $4D0,Y
               sta   $450,Y
               sta   $7A8,Y
               sta   $728,Y
               sta   $6A8,Y
               sta   $628,Y
               sta   $5A8,Y
               sta   $528,Y
               sta   $4A8,Y
               sta   $428,Y
               sta   $780,Y
               sta   $700,Y
               sta   $680,Y
               sta   $600,Y
               sta   $580,Y
               sta   $500,Y
               dey                   ;decrement index
               dey
               bmi   :exit           ;if not done with screen..
               jmp   :start          ;continue
:exit          plb
               plp                   ;restore flags
               ply
               rtl                   ;and return


scrtbl                               ;ent ;table of screen offsets
               dw    $400
               dw    $480
               dw    $500
               dw    $580
               dw    $600
               dw    $680
               dw    $700
               dw    $780
               dw    $428
               dw    $4A8
               dw    $528
               dw    $5A8
               dw    $628
               dw    $6A8
               dw    $728
               dw    $7A8
               dw    $450
               dw    $4D0
               dw    $550
               dw    $5D0
               dw    $650
               dw    $6D0
               dw    $750
               dw    $7D0


               mx    %11
inczp          inc   zpage1
               bne   :1
               inc   zpage1+1
:1             rts

yesno          pla                   ;get return address
               sta   zpage1          ;and store in zero page
               pla
               sta   zpage1+$1
               jsr   inczp           ;point it at cursor position
               ldy   #$00
               lda   (zpage1),y      ;get cursor horizontal
               sta   :pos1           ;store in this subroutine
               sta   :pos2
               jsr   inczp
               lda   (zpage1),y      ;get cursor vertical
               sta   :pos1+$1        ;save value in subroutine
               sta   :pos2+$1
               lda   zpage1+$1       ;put new return address on
               pha                   ;stack
               lda   zpage1
               pha
               stz   :pos            ;initialize our position
               jsr   :prno
:wait
               do    mouse
;jsr initmouse
               sec
               ror   mousecr+1
               lda   #$8d
               sta   mousecrchar
:wait2         jsr   mousekey
               bmi   :kand
               else
:wait2
               fin                   ;--- mouse ---

               jsl   keyscan         ;get a key
               bpl   :wait2          ;wait if not valid
:kand          and   #$7f
               do    mouse
               stz   mousecr+1       ;only w/mouse usage
               fin
:key           cmp   #$1B            ;<esc>?
               beq   :esc
               cmp   #$0D            ;<cr>?
               beq   :cr
               cmp   #$0a
               beq   :wait
               cmp   #$0b
               beq   :wait
               cmp   #'Y'            ;check for "Y" and "N"
               beq   :yes            ;chars
               cmp   #'y'
               beq   :yes
               cmp   #'N'
               beq   :no
               cmp   #'n'
               beq   :no
               cmp   #$08            ;backspace?
               beq   :bs
               cmp   #$15            ;right arrow?
               beq   :rs
:err           jsr   :bell           ;error encountered
               jmp   :wait           ;get another char
:bell          rep   $30
               tll   $2c03
               sep   $30
               rts
:esc           sec                   ;indicate escape pressed
               rts                   ;return
:cr            lda   :pos            ;get answer
               clc                   ;ok char
               rts                   ;return
:yes           lda   #$01            ;signal "YES"
               clc
               rts                   ;return
:no            lda   #$00            ;nope..
               clc                   ;valid answer
               rts                   ;return
:bs            jsr   :prno

               stz   :pos            ;signal "NO"
               jmp   :wait           ;wait for another char
:rs            jsr   :pryes
               lda   #$01            ;signal "YES"
               sta   :pos            ;and save it
               jmp   :wait           ;get another char

:pos           hex   00

:prno          jsl   print
:pos1          hex   0000
               dfb   'O'&$1f
               asc   ' No '          ;print an inverted no
               dfb   'N'&$1f
               asc   ' Yes ',00
               rts

:pryes         jsl   print           ;print an inverted yes
:pos2          hex   1f17
               asc   ' No '
               dfb   'O'&$1f
               asc   ' Yes '
               dfb   'N'&$1f
               hex   00
               rts


*-----------------------------------------------*
* Name     : GETLINE                            *
* Function : GET A LINE OF INPUT                *
* Input    : JSL GETLINE                        *
*            ADRL <Address of String>           *
*            HEX <Maximun Length>               *
*            HEX CH/CV                          *
* Output   : CARRY                              *
*              CLEAR : INPUT LINE VALID         *
*              SET   : ESCAPE KEY PRESSED       *
* Volatile : NOTHING                            *
* Calls    : GETKEY, STORCHAR, SETCH            *
*-----------------------------------------------*

getline                              ;ent ;read in a line of text
               php
               phb
               phk
               plb
               rep   $30
               sta   :asave
               stx   :xsave
               sty   :ysave
               lda   termch
               sta   :oldch
               lda   termcv
               sta   :oldcv
               lda   cursor
               sta   :curs
               lda   #' '
               sta   cursor
               lda   3,s
               sta   tempzp
               lda   5,s
               and   #$00FF
               sta   tempzp+2
               inc   tempzp
               bne   :zp1
               inc   tempzp+2
:zp1           ldy   #$02
               lda   [tempzp]
               sta   tempzp1
               lda   [tempzp],y
               sta   tempzp1+2
               iny
               iny
               lda   [tempzp],y
               and   #$FF
               sta   :maxlen
               iny
               lda   [tempzp],y
               sep   $20
               sta   termch
               sta   :prompt
               xba
               sta   termcv
               rep   $30
               jsl   setch
               lda   #$06
               clc
               adc   tempzp
               sta   tempzp
               lda   #$00
               adc   tempzp+2
               sta   tempzp+2
               sep   $20
               sta   5,s
               rep   $20
               lda   tempzp
               sta   3,s
               stz   :cflag
               sep   $30
:start         ldy   #$FF            ;transfer current
:trnsfr        iny                   ;string to buffer
               lda   [tempzp1],y
               sta   buffer,y
               cpy   buffer
               blt   :trnsfr
               ldy   buffer          ;get length of current
               iny                   ;string
               lda   #$00
               sta   buffer,y        ;place marker at end
               sta   :pos            ;initialize position
               inc   :pos            ;position 1
:loop          jsr   :prline         ;show the string
               ldy   :pos            ;get our pos
               dey
               tya
               clc
               adc   :prompt         ;add with offset
               sta   termch          ;and move cursor.
               jsl   setch

               do    mouse
               sec
               ror   mousecr+1
               lda   #$9b            ;escape w/mouse control
               sta   mousecrchar
               fin

               jsr   getkey          ;get a key from keyboard
               ora   #$80            ;set high bit
               sta   :char           ;and save it
               cmp   #$8b
               beq   :loop
               cmp   #$8a
               beq   :loop
               cmp   #$9B            ;is it <esc>?
               beq   :key1           ;yes..
               cmp   #$8D            ;<cr>?
               beq   :key2
               cmp   #$88            ;back space?
               beq   :key3
               cmp   #$FF            ;delete?
               beq   :key4
               cmp   #$95            ;right arrow?
               beq   :key5
               cmp   #$99            ;control-y?
               beq   :key6
               cmp   #$A0            ;valid char?
               blt   :bell
               cmp   #$45+$80
               beq   :key7
               cmp   #$65+$80
               beq   :key7
               cmp   #$FF
               bge   :bell
:k7ins         jsr   :insert         ;ok, so insert it
               jmp   :loop
:key1          jmp   :esc            ;jump to key handler routines
:key2          jmp   :cr
:key3          jmp   :bkspc
:key4          jmp   :delete
:key5          jmp   :rghtarr
:key6          jmp   :cntrly
:key7          jmp   :ekey
:bell          rep   $30
               tll   $2C03
               sep   $30
               jmp   :loop

:ekey          pha
               lda   $E0C061
               tax
               pla
               cpx   #$80
               blt   :k7ins
               lda   cursor
               and   #$7F
               cmp   #' '
               beq   :ul
               lda   #' '
               sta   cursor
               jmp   :loop
:ul            lda   #"_"
               sta   cursor
               jmp   :loop

:cr            ldy   #$00            ;execute a carriage return
:mov           lda   buffer,y
               sta   [tempzp1],y
               iny
               cpy   :maxlen
               bne   :mov            ;done with move?
               lda   buffer,y        ;get last char
               sta   [tempzp1],y     ;move it
               lda   buffer          ;get length of input string
               cmp   :maxlen         ;greater than maximum?
               blt   :setsize        ;no=>
               lda   :maxlen         ;yes, so get maximum
:setsize       ldy   #$00            ;set index to length byte
               sta   [tempzp1],y     ;store length
               lda   :cflag          ;read change flag
               beq   :crout          ;if zero, don't move STRING
               lda   #$00
               jsl   bascalc         ;move cursor there
               ldy   #$32            ;reset counter
               ldx   #$00            ;loop counter
:restr         lda   topbuff,x       ;get a char
               jsl   storchar        ;restore it on screen
               inx                   ;increment counter
               iny                   ;increment pos
               cpy   #$50            ;end of screen?
               blt   :restr          ;nope=>
:crout         clc                   ;signal <cr>
               php                   ;save status
               jmp   :exit           ;exit

:esc           lda   :cflag          :read
               beq   :escout         ;if zero, exit
               lda   termcv          ;save cv value
               pha                   ;save it
               lda   #$00
               jsl   bascalc         ;set base address
               ldy   #$32            ;set screen pos
               ldx   #$00            ;set counter
:res           lda   topbuff,x       ;get a char
               jsl   storchar        ;restore it
               inx                   ;increment counter
               iny                   ;increment screen pos
               cpy   #$50            ;end of screen?
               blt   :res            ;nope=>
               pla                   ;get cv value
               sta   termcv          ;save it
               jsl   setch           ;set cursor
               stz   :cflag          ;reset change flag
               jmp   :start          ;do it all over!
:escout        sec                   ;signal <esc> pressed
               php                   ;put on stack
:exit          rep   $30
               lda   :oldch          ;get old cursor ch
               sta   termch          ;restore it
               lda   :oldcv          ;get old cv
               sta   termcv          ;restore it
               jsl   setch           ;set ch/cv
               lda   :curs
               sta   cursor
               lda   :asave          ;restore a-reg
               ldy   :ysave          ;restore y-reg
               ldx   :asave          ;restore x-reg
               plp                   ;restore status
               bcs   :sec
               plb
               plp
               clc
               rtl
:sec           plb
               plp
               sec
               rtl                   ;and return
               mx    %11

:delete        lda   :pos            ;get our position
               cmp   #$01            ;at the beginning?
               beq   :nodel          ;yes=>
               tay                   ;put value in y-reg
:delmov        lda   buffer,y        ;get a char
               beq   :delsize        ;if at end, continue
               dey                   ;move it left
               sta   buffer,y        ;store it
               iny                   ;get ready for next char
               iny
               bne   :delmov         ;continue until done
:delsize       dey
               sta   buffer,y        ;move last char
               dec   buffer          ;decrement length
               dec   termch          ;our cursor pos
               dec   :pos            ;and our pos in line
               jsr   :change         ;set the change flag
               jmp   :loop           ;return for more
:nodel         rep   $30             ;beeeeep!
               tll   $2C03
               sep   $30
               jmp   :loop           ;continue

:bkspc         lda   :pos            :get
               cmp   #$01            ;at left edge?
               beq   :nobkspc        ;yes=>
               dec   :pos            ;decrement position
               dec   termch          ;cursor position
               jmp   :loop           ;and continue
:nobkspc       jmp   :loop           ;continue

:rghtarr       ldy   :pos            :get
               dey                   ;set for correct value
               cpy   buffer          ;compare with length
               bge   :norght         ;can't go Right
               cpy   :maxlen         ;greater than max?
               bge   :norght         ;yes=>
               inc   :pos            ;otherwise, increment pos
               inc   termch          ;cursor,
               jmp   :loop           ;and continue
:norght        jmp   :nobkspc        ;ring the bell

:cntrly        ldy   :pos            :get
               dey                   ;modify it
               sty   buffer          ;set length to that value
               iny                   ;set y to end
               lda   #$00            ;get e.o.l marker
               sta   buffer,y        ;indicating end of line
               jsr   :change         ;set change flag
               jmp   :loop           ;continue

:insert        lda   :pos
               cmp   #$02
               bge   :ins1
               stz   buffer
               stz   buffer+1
               lda   #$01
               sta   :pos

:ins1          lda   cursor          ;get current cursor type
               and   #$7F            ;clear high bit
               cmp   #$20            ;is it a space?
               beq   :solid          ;yes=>
               lda   buffer          ;get length byte
               cmp   #$FE            ;full?
               bge   :full           ;yes=>
               ldy   :pos            ;get our position
               dey
               cpy   :maxlen         ;at max length?
               bge   :full           ;yes=>
               iny                   ;reset y-reg
               ldy   buffer          ;get length byte
               iny                   ;add one
:movrt         dey                   ;set for previous char
               lda   buffer+1,y      ;get the char
               iny                   ;move it right
               sta   buffer+1,y      ;store it
               dey                   ;ready for next char
               cpy   :pos            ;done?
               bge   :movrt          ;no, so loop
               ldy   :pos            ;get :pos
               lda   :char           ;get last char pressed
               sta   buffer,y        ;insert in string
               inc   buffer          ;increment length
               inc   :pos            ;increment our position
               inc   termch          ;our cursor pos
               jsr   :change         ;set the change flag
               rts                   ;return to main return


:solid         lda   buffer          ;get length
               cmp   #$FE            ;are we full?
               bge   :full           ;yes=>
               ldy   :pos            ;get our pos
               dey
               cpy   :maxlen         ;at max length?
               bge   :full           ;yes, so can't insert
               iny
               cpy   buffer          ;at the end?
               blt   :ins            ;no, so no problems
               iny                   ;otherwise, move e.o.l. char
               lda   #$00
               sta   buffer,y
               dey
:ins           lda   :char           ;get the char
               sta   buffer,y        ;insert it
               inc   termch          ;increment cursor
               lda   buffer          ;get length
               cmp   :pos            ;compare with position
               bge   :insmid
               inc   buffer          ;increment length
:insmid        inc   :pos            ;increment our position
               jsr   :change         ;set change flag
               rts                   ;return
:full          rep   $30             ;ring bell
               tll   $2C03
               sep   $30
               rts                   ;return

:prline        pha                   ;save the registers
               tya
               pha
               lda   :prompt         ;get start position
               sta   termch          ;store in cursor
               jsl   setch           ;move cursor to it
               ldy   #$00            ;reset index
:prt           lda   buffer+1,y      ;get a char
               beq   :end            ;if done, continue
               cpy   :maxlen         ;at our max length?
               bge   :end            ;yes, so stop
               jsr   :prntchar       ;otherwise, print the char
               iny                   ;increment index
               bne   :prt            ;go back for more
:end           lda   #$A0            ;get a space char
:clr           cpy   :maxlen         ;have we printed all chars
               bge   :lineout        ;yes, so exit
               jsr   :prntchar       ;otherwise, clear to end
               iny
               bne   :clr
:lineout       pla                   ;restore registers
               tay
               pla
               rts                   ;and return

:change        php
               sep   $30
               lda   termch          :save
               pha
               lda   termcv
               pha
               lda   :cflag          ;read change flag
               bmi   :mexit          ;if already set exit
               lda   #$FF            ;get a negative value
               sta   :cflag          ;set the flag
               lda   #$00
               jsl   bascalc         ;set base address
               ldx   #$00            ;reset loop counter
               ldy   #$32            ;get position counter
:movit         jsl   pickchar        ;get a char
               sta   topbuff,x       ;save it in buffer
               lda   #$A0            ;get a space char
               jsl   storchar        ;clear a position
               iny                   ;increment position
               inx                   ;increment counter
               cpy   #$50            ;at end of screen?
               blt   :movit          ;nope=>
               lda   #$3C
               sta   termch
               sta   mych
               stz   termcv
               stz   mycv
               jsl   textbascalc
               jsl   setch
               rep   $30
               psl   #:escstr
               jsl   drawstr
               sep   $30
:mexit         pla                   ;restore old cursor pos
               sta   termcv
               pla
               sta   termch
               jsl   setch           ;set values
               plp
               rts                   ;and return

:prntchar      phy
               php
               sep   $30
               ldy   termch
               ora   #$80
               jsl   storchar
               inc   termch
               plp
               ply
               rts

:escstr        str   "Escape: Erase entry"

:asave         ds    2
:ysave         ds    2
:xsave         ds    2
:oldch         ds    2
:oldcv         ds    2
:cflag         ds    2
:char          ds    2
:prompt        ds    2
:pos           ds    2
:maxlen        ds    2
:curs          ds    2

buffer         ds    275,0
topbuff        ds    40,0

keyscan                              ;ent ;read the keyboard using the
               php                   ;event manager.
               phb
               phk
               plb
               rep   $30
               bit   emstarted
               bmi   :emyes
               sep   $20
               ldal  $E0C000
               bmi   :hwyes
               jmp   :no
:hwyes         pha
               ldal  $E0C010
               ldal  $E0C025
               sta   emod+1
               pla
               rep   $20
               and   #$00FF
               jmp   :yes1
:emyes         pha
               pea   $FFFF
               psl   #event
               tll   $0A06           ;getnextevent
               pla
               beq   :no
               lda   event
               cmp   #$03
               beq   :yes
               cmp   #$05
               beq   :yes
:no            plb
               plp
               rep   $80
               rtl
:yes           lda   emess
               and   #$00FF
               ora   #$0080
:yes1          plb
               plp
               sep   $80
               rtl


memfull        php
               rep   $30
               jsr   drawbox
               jsl   print
               dfb   44
               dfb   7
               asc   "Memory Full",00
               lda   selecting
               pha
               lda   #$8000
               sta   selecting
               jsr   getkey
               pla
               sta   selecting
               jsr   erasebox
               plp
               rts

getfind        php
               rep   $30
               jsr   drawbox
               stz   findstr
               jsl   print
               dfb   44
               dfb   7
               asc   "Text to FIND:",00
               jsl   getline
               adrl  findstr
               dfb   30
               dfb   44
               dfb   10
               php
               jsr   erasebox
               plp
               bcs   :sec
               plp
               clc
               rts
:sec           plp
               sec
               rts

getreplace     php
               rep   $30
               jsr   drawbox
               stz   findstr
               stz   replacestr
               jsl   print
               dfb   44
               dfb   7
               asc   "Change: ",00
               jsl   print
               dfb   44
               dfb   7+2
               asc   "    To: ",00

               jsl   getline
               adrl  findstr
               dfb   20
               dfb   44+9
               dfb   7
               bcs   :erase

               jsl   getline
               adrl  replacestr
               dfb   20
               dfb   44+9
               dfb   7+2
               bcs   :sec

:erase         php
               jsr   erasebox
               plp
               bcs   :sec
               plp
               clc
               rts
:sec           plp
               sec
               rts


doerror        php
               rep   $30
               and   #$00ff
               sta   :errcode
               jsl   print
               dfb   44
               dfb   7
               asc   "                            ",00
               stz   :which
:loop          lda   :which
               asl
               tax
               lda   :tbl,x
               beq   :nocode
               cmp   :errcode
               beq   :found
               inc   :which
               jmp   :loop
:found         lda   :which
               asl
               tax
               lda   :tbl1,x
               sta   :add+1
               sta   :add1+1

               lda   #44
               sta   mych
               lda   #7
               sta   mycv
               jsl   textbascalc
:add           lda   $ffff
               and   #$00ff
               sta   :len
               ldx   #$01
]lup           phx
:add1          lda   $ffff,x
               and   #$007f
               jsl   drawchar
               plx
               inx
               cpx   :len
               blt   ]lup
               beq   ]lup
               jmp   :wait
:nocode        jsl   print
               dfb   44
               dfb   7
               asc   "GS/OS Error $",00
               lda   #57
               sta   mych
               lda   #7
               sta   mycv
               jsl   textbascalc
               lda   :errcode
               jsl   prbyte
:wait          tll   $2C03
:key           jsl   keyscan
               bpl   :key
               plp
               rts

:which         ds    2
:errcode       ds    2
:len           ds    2

:tbl           dw    nottext
               dw    toobigerr
               dw    syntaxerr
               dw    $07             ;ProDOS busy
               dw    $27             ;I/O error
               dw    $28             ;No Device
               dw    $2b             ;Write Protected
               dw    $2f             ;No Device
               dw    $40             ;bad pathname
               dw    $44             ;directory not found
               dw    $45             ;volume not found
               dw    $46             ;file not found
               dw    $47             ;duplicate filename
               dw    $48             ;disk full
               dw    $49             ;volume full
               dw    outofmem
               dw    notdir
               dw    $4e             ;File locked
               dw    $0000

:tbl1          dw    :str1
               dw    :str2
               dw    :str3
               dw    :str4
               dw    :str5
               dw    :str6
               dw    :str7
               dw    :str8
               dw    :str9
               dw    :str10
               dw    :str11
               dw    :str12
               dw    :str13
               dw    :str14
               dw    :str15
               dw    :str16
               dw    :str17
               dw    :str18

:str1          str   'Not a TXT/SRC file.'
:str2          str   'File too Large!'
:str3          str   'Syntax Error'
:str4          str   'ProDOS busy'
:str5          str   'I/O error'
:str6          str   'No Device Connected'
:str7          str   'Write Protected'
:str8          str   'No Device Connected'
:str9          str   'Bad Pathname'
:str10         str   'Directory not Found'
:str11         str   'Volume not Found'
:str12         str   'File not Found'
:str13         str   'Duplicate Filename'
:str14         str   'Disk Full'
:str15         str   'Volume Full'
:str16         str   'Not Enough Memory'
:str17         str   'Not Subdirectory'
:str18         str   'File Locked'

               do    library
userid         ext
               else
userid         ds    2,0
               fin

editlen        ds    4,0
dphandle       ds    4,0
dppointer      ds    2,0

efilename      ds    130,0
loadfilename   ds    130,0
getname        ds    67,0

pfxsave        ds    67,0
mypfx          ds    67,0
pfxparm        dw    $00
               adrl  pfxsave
mypfxparm      dw    $00
               adrl  mypfx

dpsave         ds    2
stacksave      ds    2

event          ds    2               ;event record...use by taskmaster
emess          ds    4               ;event message
ewhen          ds    4               ;tick count
ewhere
cursy          ds    2               ;cursor y in global coords
cursx          ds    2               ;cursor x in global coords
emod           ds    2               ;modifier keys

instring       ds    256,0

