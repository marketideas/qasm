              lst             off
              ttl             "QuickEdit v2.00d2"
              tr              on
              lstdo           off
              cas             in
              exp             off
*======================================================
* QuickEdit -- for use with the QuickAsm system

* Written by Shawn Quick & ReWritten by Lane Roath

* Copyright (c) 1988-1990 QuickSoft & Ideas From the Deep
*------------------------------------------------------
* 29-Feb-89 2.00 :d1- start rewrite
*======================================================

              xc
              xc
              mx              %00
              rel

              use             4/util.macs
              use             qatools.macs
              use             edit.macs
              put             2/qa.equates
              put             edit.equs

*------------------------------------------------------

editor
              phb
              phd
              phk
              plb
              rep             $30
              sta             userid
              tdc
              sta             editdp
              sta             dppointer
              pea             0
              _QAStatus
              pla
              bne             :runit

              pld
              plb
              plp
              rep             $30
              jsl             $e100a8                        ;error- quit
              dw              $29
              adrl            :q
:q            adrl            $0
              dw              $0
:runit
              rep             $30
              pea             0
              pea             0
              _QACompilerActive
              _QALinkerActive
              pla
              ora             1,s
              sta             1,s
              pla
              jne             :allout

              pea             0
              psl             #$00
              lda             userid
              pha
              _QAGetMessagebyID
              pla
              plx
              ply
              cmp             #startmess
              beq             :runit1
              pld
              plb
              clc
              rtl

:runit1       stz             superquit
              sep             $20
              ldal            $e0c029
              sta             grafentry
              ldal            $E100BC
              jeq             :editerr
              rep             $20
              stz             emstarted

              lda             userid
              bne             :haveuser
              ~GetNewID       #$5000                         ;get a user id if a CDA
              pla
              sta             userid
:haveuser
              lda             dppointer
              bne             :havedp
              phd
              tsc
              sec
              sbc             #5
              tcs
              inc
              pha
              pld

              ~NewHandle      #0;#dplength;userid;#$C015;#0
              bcc             :derefdp
              plx
              plx
              tsc
              clc
              adc             #5
              tcs
              pld
              brl             :editerr
:derefdp
              pla
              sta             dphandle
              sta             0
              pla
              sta             dphandle+2
              sta             2
              lda             [0]
              sta             dppointer
              tsc
              clc
              adc             #5
              tcs
              pld
              lda             dppointer
              pha
              pld
              ldx             #0
]lup          stz             0,X                            ;init direct page
              inx
              inx
              cpx             #dplength
              blt             ]lup
:havedp
* lda editbufhdl
* ora editbufhdl+2
* beq :needbuf
* psl editbufhdl
* tll $1E02
              ~CheckHandle    editbufhdl                     ;is our text handle valid?
              bcs             :needbuf
              lda             editbufhdl
              sta             zpage
              lda             editbufhdl+2
              sta             zpage+2
              ldy             #$02
              lda             [zpage]                        ; yes- still point to valid data?
              ora             [zpage],y
              bne             :havebuffer
:rstrbuf
* psl editbufhdl
* tll $0B02 ;restorehandle
              ~RestoreHandle  editbufhdl                     ; no- reallocate it!
              jcs             :editerr
              jsr             newdoc1
              bra             :havebuffer

:needbuf      psl             #$00
              psl             #$10000
              pea             0
              _QAGetShellID
              pla
              ora             #$100
              pha                                            ;allocate text buffer
              pea             $0010
              psl             #$00
              _NewHandle
              bcc             :deref
              plx
              plx
              brl             :editerr
:deref
              pll             editbufhdl
              jsr             newdoc1

:havebuffer
* pea 0
* psl editbufhdl
* tll $2402 ;no more purging...
              ~SetPurge       #0;editbufhdl                  ;don't allow purge while in use

* stz equitflag
* stz superquit
* stz dirty
* stz intstatus
* stz loaderstat

              do              mouse
              pea             $00
              tll             $1803                          ;init mouse
              jsr             initmouse
              fin

              pha
              tll             $0606                          ;event manager active??
              pla
              beq             :noem
              sec
              ror             emstarted

:noem         psl             editbufhdl
              tll             $2002

              lda             editbufhdl
              sta             zpage
              lda             editbufhdl+2
              sta             zpage+2

              ldy             #$02
              lda             [zpage]
              sta             fileptr
              lda             [zpage],y
              sta             fileptr+2

              stz             loaderstat
:init
              jsr             initedit
              jsr             selectoff
:loop         rep             $30
              jsr             drawcpos

              do              debug
              jsr             showinfo
              fin

              bit             equitflag
              jmi             :editout

              do              mouse
              stz             mousecr
              stz             mousecrchar                    ;init if mouse is in use
              fin

              jsr             getkey
              sep             $30
              and             #$7F
              sta             :char
              bit             selecting+1
              bpl             :sel1
              cmp             #$0a
              beq             :sel1
              cmp             #$0b
              beq             :sel1
              cmp             #$15
              beq             :sel0
              cmp             #$08
              beq             :sel0
              and             #$5f
              cmp             #'C'
              beq             :sel0
              cmp             #'X'
              beq             :sel0
:sel3         jsr             selectoff
              jmp             :loop
:sel0         lda             emod+1
              bit             emstarted+1
              bmi             :sel2
              and             #%10000000
              beq             :sel3
              bra             :sel1
:sel2         and             #%00000001
              beq             :sel3
:sel1         lda             :char
              cmp             #$0d
              beq             :c
              bit             oflag
              bmi             :nomod
:c            stz             oflag
              jsr             commands
              bcc             :loop
              lda             :char
              jsr             keypads
              bcc             :loop
              lda             :char
              jsr             controls
              bcc             :loop
:nomod        lda             cursor
              stz             oflag
              and             #$7F
              cmp             #'_'
              beq             :insert
              ldx             pos
              inx
              cpx             linebuff
              bge             :insert
              dex
:over         lda             :char
              sta             linebuff+1,x
              sec
              ror             dirty
              lda             termch
              cmp             #right-1
              bge             :dl
              inc             pos
:dl           jsr             drawline
              jsr             poscurs
              jmp             :loop
:insert       ldx             linebuff
              cpx             #$FF
              jge             :loop
              ldx             pos
              cpx             linebuff
              bge             :ldx
              ldx             linebuff
]lup          lda             linebuff,x
              sta             linebuff+1,x
              dex
              beq             :ldx
              cpx             pos
              bge             ]lup
:ldx          ldx             pos
              lda             :char
              sta             linebuff+1,x
              sec
              ror             dirty
              inc             linebuff
              lda             termch
              cmp             #right-1
              bge             :dl1
              inc             pos
:dl1          rep             $30
              jsr             drawline
              jsr             poscurs
              jmp             :loop

:editout      rep             $30
              jsr             savebuff
* jsr exitquestion
* bcc :lds
* stz equitflag
* jmp :loop
:lds
:pfx
              do              0
              jsl             prodos
              dw              $0a
              adrl            mypfxparm
              jsl             prodos
              dw              $09                            ;setpfx
              adrl            pfxparm
              fin

              lda             flen
              sta             editlen
              psl             editbufhdl
              tll             $2202
              psl             dphandle
              _disposehandle
              stz             dphandle
              stz             dphandle+2
              stz             dppointer
              sep             $20
              ldal            $E0C027
              and             #%10111111
              ora             intstatus
              stal            $E0C027
              rep             $20
              lda             texttype
              pha
              psl             textdevice
              tll             $100C                          ;setoutputdevice
              lda             textand
              pha
              lda             textor
              pha
              tll             $0A0C

              bit             emstarted
              bpl             :super
              pha
              pea             %0000010000101110
              pea             0
              tll             $1506                          ;flush events
              pla
:super
              do              cda.library
              bit             superquit
              bpl             :pldxit
              fin
              jsl             shutdown
:pldxit       rep             $30
              sep             $20
              lda             grafentry
              stal            $e0c029
:allout       rep             $30
              pld
              plb
              clc
              rtl

:editerr      rep             $30
              psl             #:es1
              tll             $200c
              ldy             #20
              ldal            $e0c01f
              and             #$80
              beq             :c1
]lup          phy
              pea             $20
              tll             $180c
              ply
              dey
              bne             ]lup
:c1           psl             #:es2
              tll             $200c
              ldy             #20
              ldal            $e0c01f
              and             #$80
              beq             :c2
]lup          phy
              pea             $20
              tll             $180c
              ply
              dey
              bne             ]lup
:c2           psl             #:es3
              tll             $200c
              pha
              pea             $0000
              tll             $220c
              pla
              jmp             :pldxit
              pld
              plb
              rtl

:char         ds              2
:es1          hex             0c0d0d0d0d0d0d0d0d,00
:es2          asc             '        Unable to run QuickEDIT',8d,00
:es3          asc             'Insufficient memory or GS/OS not active',0d,00

editsdown     ent
shutdown
              php
              phb
              phd
              phk
              plb
              rep             $30

              lda             editbufhdl
              ora             editbufhdl+2
              beq             :nobuffer
              pea             2
              psl             editbufhdl
              tll             $2402                          ;set purge

              do              0                              ;cda!1
              psl             editbufhdl
              _Disposehandle
              stz             editbufhdl
              stz             editbufhdl+2
              fin

:nobuffer     lda             dphandle
              ora             dphandle+2
              beq             :nodp
              psl             dphandle
              _Disposehandle
              stz             dphandle
              stz             dphandle+2
              stz             dppointer
:nodp         lda             userid
              beq             :nouserid
* pha
* tll $2103
* stz userid
:nouserid
              jsl             inittext
              psl             #:str
              tll             $1c0c
              pld
              plb
              rtl

:str          str             0d,'Shell.',0d,0d
shutdownrtl
              rtl

inittext      php
              rep             $30
              pea             $00
              psl             #$03
              tll             $100c
              pea             $00
              psl             #$03
              tll             $0f0c
              pea             $00
              psl             #$03
              tll             $110c

              pea             $00
              tll             $150c
              pea             $01
              tll             $150c
              pea             $02
              tll             $150c

              pea             #$ff
              pea             #$80
              tll             $0a0c

              pea             #$ff
              pea             #$80
              tll             $090c

              pea             $0c
              tll             $180c
              plp
              rtl



newdoc        jsr             newdoc1
              jsr             drawfname
              jsr             drawmem
              stz             gotolnum
              lda             #-1
              sta             linenum                        ;fool goto line!!
              jsr             gotoline
              rts

newdoc1       php
              sep             $20
:tabsoff      ldx             #$07
]lup          stz             tabs,x                         ;zero out tabs
              dex
              bpl             ]lup
:dtabs        ldx             #$07
]lup          lda             dtabs,x
              sta             tabs1,x
              sta             tabs,x
              dex
              bpl             ]lup
              jsr             drawtabs
              rep             $20
              stz             linenum
              stz             flen
              stz             editlen
              stz             showcr
              stz             pos
              stz             pos1
              stz             position
              stz             dirty
              stz             selecting
              stz             efilename
              stz             alldirty
              stz             marker
              lda             #$FFFF
              sta             selstart
              sta             selend
              plp
              rts

              put             edit.1

cmdxit        sep             $30
              plp
              clc
              rts

keypads       php
              sep             $30
              and             #$7F
              cmp             #'a'
              blt             :schar
              cmp             #'z'+1
              bge             :schar
              and             #$5F
:schar        sta             :char
              lda             emod+1
              bit             emstarted+1
              bmi             :emmod
              bit             #%00010000
              beq             :xit
              jmp             :chk
:emmod        bit             #%00100000
              beq             :xit
:chk          ldx             #$00
]lup          lda             :tbl,x
              beq             :xit1
              cmp             :char
              beq             :found
              inx
              jmp             ]lup
:found        rep             $30
              txa
              asl
              tax
              lda             :tbl1,x
              sta             :jmp+1
              lda             dirty
              beq             :sep
              jsr             savebuff
              jsr             getbuff
              jsr             drawline
              jsr             poscurs
:sep          sep             $30
              lda             :char
:jmp          jmp             $FFFF
:cmdxit       sep             $30
              plp
              clc
              rts
:xit          lda             :char
              plp
              sec
              rts
:xit1         lda             :char
              plp
              clc
              rts
:char         ds              2


:tbl          dfb             'X'&$1f

:tbl1         dw              :donew
              dw              $00

:donew        rep             $30
              jsr             drawbox
              stz             :string
              jsr             drawesccan1
              jsl             print
              dfb             47
              dfb             7
              asc             "CLEAR current contents?",00
              sep             $30
              jsr             yesno
              dfb             51+3
              dfb             9
              rep             $30
              pha
              php
              jsr             erasebox
              jsr             drawesc
              plp
              pla
              bcs             :cbplp1
              and             #$ff
              beq             :cbplp1
              jsr             newdoc
              jsr             drawfname
              jsr             gotoline
:cbplp1       jmp             :cmdxit
:string       ds              33,0


commands      php
              sep             $30
              and             #$7F
              cmp             #'a'
              blt             :schar
              cmp             #'z'+1
              bge             :schar
              and             #$5F
:schar        sta             :char
              lda             emod+1
              bit             emstarted+1
              bmi             :emmod
              and             #%10000000
              beq             :xit
              jmp             :chk
:emmod        and             #%00000001
              beq             :xit
:chk          ldx             #$00
]lup          lda             :tbl,x
              beq             :xit1
              cmp             :char
              beq             :found
              inx
              jmp             ]lup
:found        rep             $30
              txa
              asl
              tax
              lda             :tbl1,x
              sta             :jmp+1
              lda             dirty
              beq             :sep
              jsr             savebuff
              jsr             getbuff
              jsr             drawline
              jsr             poscurs
:sep          sep             $30
              lda             :char
:jmp          jmp             $FFFF
:cmdxit       sep             $30
              plp
              clc
              rts
:xit          sep             $30
              lda             :char
              and             #$ff
              plp
              sec
              rts
:xit1         lda             :char
              and             #$ff
              plp
              clc
              rts
:char         ds              2


:tbl          dfb             'Q'                            ;Quit
              dfb             'E'                            ;Toggle cursor
              dfb             'M'                            ;show <CR>
              hex             0b                             ;up 10 lines
              hex             0a                             ;down 10 lines
              hex             08                             ;up 24 lines
              hex             15                             ;down 24 lines
              dfb             '9'                            ;eof
              dfb             'N'                            ;eof
              dfb             'B'                            ;beginning of file
              dfb             '1'                            ;beginning of file
              dfb             'Z'                            ;center current line
              dfb             'D'                            ;delete current line
              dfb             'I'                            ;insert line
              hex             09                             ;insert line (same as 'I')
              dfb             'J'                            ;goto line number/label
              hex             7f                             ;delete line above
              dfb             'S'                            ;save file
              dfb             '-'                            ;tabs off
              dfb             '_'                            ;tabs off
              dfb             '+'                            ;default tabs on
              dfb             '='                            ;default tabs on
              dfb             '0'                            ;set/clear tabs
              dfb             'C'                            ;copy command
              hex             1b                             ;quit
              dfb             'O'                            ;open command box
              dfb             'L'                            ;load file
              dfb             'P'                            ;show prefix (status box)
              dfb             'A'                            ;Assemble
              dfb             '/'                            ;status box
              dfb             '?'                            ;status box
              hex             0D                             ;insert CR
              dfb             '2'                            ;go relative position
              dfb             '3'
              dfb             '4'
              dfb             '5'
              dfb             '6'
              dfb             '7'
              dfb             '8'
              dfb             'T'                            ;goto marker
              dfb             'X'                            ;cut
              dfb             'V'                            ;paste
              dfb             'Y'                            ;select all
              dfb             'W'                            ;find word
              dfb             'F'                            ;find
              dfb             'R'                            ;find/replace
              hex             00                             ;must end with $00

:tbl1         dw              :quit
              dw              :cursor
              dw              :showcr
              dw              :up10
              dw              :dn10
              dw              :up24
              dw              :dn24
              dw              :goend
              dw              :goend
              dw              :gobegin
              dw              :gobegin
              dw              :crupdate
              dw              :delline
              dw              :insline
              dw              :insline
              dw              :gotolabel
              dw              :delline1
              dw              :savefile
              dw              :tabsoff
              dw              :tabsoff
              dw              :tabson
              dw              :tabson
              dw              :settabs
              dw              :copy
              dw              :superquit
              dw              :extcommand
              dw              loadfile
              dw              :prefix1
              dw              :asm                           ;:marker
              dw              :prefix
              dw              :prefix
              dw              insertcr
              dw              gopos
              dw              gopos
              dw              gopos
              dw              gopos
              dw              gopos
              dw              gopos
              dw              gopos
              dw              :marker
              dw              :cut
              dw              :paste
              dw              :selall
              dw              :findword
              dw              :find
              dw              :replace


:findword     jsr             findword
              jmp             :cmdxit
:find         jsr             find
              jmp             :cmdxit
:replace      jsr             findreplace
              jmp             :cmdxit

:asm          rep             $30

              do              0
              stz             automode
              stz             asmpath
              lda             flen
              sta             editlen

              jsl             inittext

              phd
              lda             globalptr
              tcd
              clc
              adc             #goasmptr
              sta             :jsl+1
              stz             shellerrors
              stz             objcodesaved
              stz             keyquit
              stz             gobjaux
              stz             gobjaux+2
              stz             gobjtype
              lda             #$02
              sta             asmhdlid
              lda             editbufhdl
              sta             asmfileptr
              lda             editbufhdl+2
              sta             asmfileptr+2
              lda             editlen
              sta             asmfilelen
              stz             asmfilelen+2
              lda             #$01
              sta             asmhdlid

:jsl          jsl             $000000
              rep             $30
              tay
              phk
              plb
              pld

              pha
              psl             #:keystr
              tll             $1c0c
              sep             $20
:k1           ldal            $e0c000
              bpl             :k1
              ldal            $e0c010
              rep             $20
              pea             $01                            ;pascal...
              psl             #$03                           ;turn on 80 column
              tll             $100c
              pea             $01
              tll             $150c

              pea             $02
              psl             #textdriver
              tll             $100C                          ;setoutputdevice

              pea             $FF
              pea             $80
              tll             $0A0C

              jsl             clrscreen
              jsr             editscreen

              stz             termcv
              stz             termch
              sta             oflag

              lda             #$FFFF
              sta             sof
              jsl             setch

              lda             linenum
              sta             gotolnum
              jsr             gotoline

              pla
              fin

              jmp             :cmdxit
:keystr       str             'Press a key.',0d

:marker       rep             $30
              lda             marker
              sta             gotolnum
              jsr             gotoline
              jmp             :cmdxit

]left         equ             24

:prefix1      jmp             :cmdxit

:prefix       rep             $30
              lda             termch
              pha
              lda             termcv
              pha
              jsr             drawbox1

              jsl             print
              dfb             ]left
              dfb             12-6
              asc             "         QuickEdit v2.00d2",00
              jsl             print
              dfb             ]left
              dfb             13-6
              asc             "               by",00
              jsl             print
              dfb             ]left
              dfb             14-6
              asc             "Shawn Quick & Lane Roath",00
              jsl             print

              do              softdisk
              dfb             ]left-5
              dfb             16-6
              asc             "copyright 1989, SoftDisk Publishing, Inc.",00
              else
              dfb             ]left-1
              dfb             16-6
              asc             "copyright 1989, QuickSoft Software",00
              fin

              jsl             print
              dfb             ]left
              dfb             17-6
              asc             "      All Rights Reserved.",00


              jsl             print
              dfb             18
              dfb             16
              asc             "Prefix: ",00
              lda             #26
              sta             mych
              lda             #16
              sta             mycv
              jsl             textbascalc
              jsl             prodos
              dw              $0a
              adrl            :pparm
              jcc             :pprt
              sta             :pfx
:pprt         lda             :pfx
              and             #$00ff
              sta             :plen
              jeq             :pinfo
              ldx             #$00
]lup          lda             :pfx+1,x
              phx
              jsl             drawchar
              plx
              inx
              cpx             :plen
              bge             :pinfo
              cpx             #70-26
              blt             ]lup
:pinfo        jsl             print
              dfb             ]left
              dfb             9+4
              asc             "Memory:  Used: ",00
              lda             #]left+15
              sta             mych
              lda             #9+4
              sta             mycv
              jsl             textbascalc
              psl             #flen
              pea             $0000
              jsl             printdec
              lda             flen
              eor             #$FFFF
              sta             :pfree
              jsl             print
              dfb             ]left+22
              dfb             9+4
              asc             "Free: ",00
              lda             #]left+28
              sta             mych
              lda             #9+4
              sta             mycv
              jsl             textbascalc
              psl             #:pfree
              pea             $0000
              jsl             printdec

              jsl             print
              dfb             ]left+9
              dfb             9+5
              asc             "Clip: ",00
              lda             cliphandle
              ora             cliphandle+2
              beq             :czero
              psl             #$00
              psl             cliphandle
              _gethandlesize
              pll             :pfree
              bra             :pclip
:czero        stz             :pfree
              stz             :pfree+2
:pclip        lda             #]left+15
              sta             mych
              lda             #9+5
              sta             mycv
              jsl             textbascalc
              psl             #:pfree
              pea             $0000
              jsl             printdec


:pkey2        jsl             keyscan
              bpl             :pkey2
              and             #$7f
              cmp             #$1b
              beq             :done
* jmp :about
:done                                                        ;jsr initmouse
              jsr             erasebox1
              pla
              sta             termcv
              pla
              sta             termch
              jsl             setch
              jmp             :cmdxit

:about        jsr             aboutsd
                                                             ;jsr initmouse
:pkeysd       jsl             keyscan
              bpl             :pkeysd
              jmp             :done

:plen         ds              2
:pfree        ds              4
:pparm        dw              $00
              adrl            :pfx
:pfx          ds              68,0

:extcommand   rep             $30
              jsr             drawbox
              stz             instring
              stz             commandlen
              jsr             drawesccan
              jsl             print
              dfb             44
              dfb             7
              asc             "Command?",00
              jsl             getline
              adrl            instring
              dfb             30
              dfb             44
              dfb             10
              php
              jsr             drawesc
              plp
              lda             #$00
              bcs             :dcplp
              rep             $30
              sep             $20
              lda             instring
              beq             :dcplp
              sta             :len1
              ldx             #$00
]lup          cpx             :len1
              bge             :run
              lda             instring+1,x
              and             #$7f
              cmp             #' '
              beq             :run
              cmp             #'a'
              blt             :sta
              cmp             #'z'+1
              bge             :sta
              and             #$5f
:sta          sta             externname,x
              inx
              jmp             ]lup
:run          txa
              and             #$00ff
              sta             commandlen
              clc
              adc             externdflt
              sta             externpath
              rep             $30
              jsr             checkcommands
              bcc             :dcplp
              lda             #syntaxerr
              jsr             doerror
              lda             #$00
              jmp             :dcplp

              jsr             runcommand

:dcplp        rep             $30
              and             #$00ff
              beq             :dc1
              jmp             :cmdxit
:dc1          jsr             erasebox
              jmp             :cmdxit

:len1         ds              2,0
:string1      ds              65

:superquit    rep             $30
              lda             #$FFFF
              sta             equitflag
              sta             superquit
              jmp             :cmdxit

:copy         rep             $30
              bit             selecting
              jmi             :copy1
              lda             position
              sta             selstart
              pha
              ldx             eof
              beq             :copyyes
              lda             flen
              bra             :copy0
:copyyes      jsr             foreptr
              lda             position
              dec
:copy0        sta             selend
              pla
              sta             position
              sec
              ror             selecting
              jsr             drawline
              jmp             :cmdxit

:copy1        jsr             copyselect
              lda             selstart
              sta             gotoposition
              jsr             selectoff1
              jsr             gotopos
              jsr             drawmem
              jmp             :cmdxit

:cut          rep             $30
              bit             selecting
              bmi             :cut1
              lda             position
              sta             selstart
              pha
              ldx             eof
              beq             :copyyes1
              lda             flen
              jmp             :cut0
:copyyes1     jsr             foreptr
              lda             position
              dec
:cut0         sta             selend
              pla
              sta             position
              sec
              ror             selecting
              jsr             drawline
              jmp             :cmdxit

:cut1         jsr             copyselect
              bcs             :cutxit
              psl             #$00
              psl             cliphandle
              _GetHandlesize
              pla
              plx
              ldx             selend
              ldy             selstart
              jsr             deletetext
              lda             selstart
              sta             gotoposition
              jsr             selectoff1
              jsr             gotopos
              jsr             drawmem
:cutxit       jmp             :cmdxit

:paste        rep             $30
              lda             cliphandle
              ora             cliphandle+2
              bne             :paste1
              jmp             :cmdxit

:paste1       psl             #$00
              psl             cliphandle
              _GetHandleSize
              pla
              plx
              sta             workspace
              lda             position
              clc
              adc             workspace
              tay
              ldx             position
              lda             workspace
              jsr             inserttext
              jcs             :cmdxit
              psl             cliphandle
              lda             position
              clc
              adc             fileptr
              tax
              lda             #$00
              adc             fileptr+2
              pha
              phx
              psl             #$00
              psl             cliphandle
              _GetHandleSize
              tll             $2902                          ;_HandToPtr
              jsr             drawmem
              lda             position
              jsr             updatescreen
              jsr             drawcpos
              jsr             getbuff
              jsr             drawline
              jsr             poscurs
              jsr             setfflags

:pastexit     jmp             :cmdxit

:selall       rep             $30
              lda             position
              sta             selstart
              lda             flen
              sta             selend
              sta             gotoposition
              lda             #$8000
              sta             selecting
              jsr             gotopos
              jmp             :cmdxit

              mx              %11
:settabs
              lda             termch
              sta             :ch
              lda             termcv
              sta             :cv
              lda             cursor
              sta             :curs
              lda             #$16
              sta             termcv
              lda             #$01
              sta             termch
              jsl             setch
              lda             #' '
              sta             cursor
              ldx             #$07
]lup          lda             tabs,x
              sta             tabstemp,x
              dex
              bpl             ]lup
:stloop
              do              mouse
              sec
              ror             mousecr+1                      ;setup for mouse
              lda             #'S'
              sta             mousecrchar
              fin

              jsr             getkey
              and             #$7F
              cmp             #$1B
              jeq             :stcan
              cmp             #$0D
              jeq             :stcr
              and             #$5F
              cmp             #'C'
              beq             :stclr
              cmp             #'S'
              beq             :set
              cmp             #'R'
              jeq             :reset
              cmp             #$08
              beq             :stbs
              cmp             #$15
              beq             :stra
              cmp             #'D'
              beq             :default
              jmp             :stloop
:default      ldx             #$07
]lup          lda             dtabs,x
              sta             tabs,x
              dex
              bpl             ]lup
              jsr             drawtabs
              jmp             :stloop
:stbs         lda             termch
              cmp             #$02
              jlt             :stloop
              dec
              sta             termch
              jsl             setch
              jmp             :stloop
:stra         lda             termch
              cmp             #right-2
              jge             :stloop
              inc
              sta             termch
              jsl             setch
              jmp             :stloop
:stclr        ldx             #$07
]lup          stz             tabs,x                         ;zero out tabs
              dex
              bpl             ]lup
              jsr             drawtabs
              jmp             :stloop
:set          ldx             #$07
              ldy             #$00
]lup          lda             tabs,x
              beq             :sdex
              iny
:sdex         dex
              bpl             ]lup
              cpy             #$08
              blt             :set2
              rep             $30
              tll             $2C03
              sep             $30
              jmp             :stloop
:set2         lda             termch
              sta             :temp
              ldx             #$00
]lup          lda             tabs,x
              beq             :stset1
              cmp             :temp
              jeq             :stloop
              bge             :sthere
              inx
              cpx             #$08
              blt             ]lup
              jmp             :stloop
:sthere       stx             :temp
              ldx             #$08
]lup          lda             tabs,x
              sta             tabs+1,x
              dex
              cpx             #$FF
              beq             :zero
              cpx             :temp
              bge             ]lup
              jmp             :ldx1
:zero         ldx             #$00
              bra             :stset1
:ldx1         ldx             :temp
:stset1       lda             termch
              sta             tabs,x
              jsr             drawtabs
              jmp             :stloop

:reset        ldx             #$07
              lda             termch
]lup          cmp             tabs,x
              beq             :kill
              dex
              bpl             ]lup
              jmp             :stloop
:kill         lda             tabs+1,x
              sta             tabs,x
              inx
              cpx             #$08
              blt             :kill
              stz             tabs+7
              stz             tabs+8
              jsr             drawtabs
              jmp             :stloop
:stcan        ldx             #$07
]lup          lda             tabstemp,x
              sta             tabs,x
              dex
              bpl             ]lup
              jsr             drawtabs
              jmp             :stxit
:stcr         ldx             #$07
]lup          lda             tabs,x
              sta             tabs1,x
              dex
              bpl             ]lup
              jsr             drawtabs
              rep             $30
              lda             linenum
              sta             gotolnum
              jsr             gotoline
              sep             $30
              jmp             :stxit1
:stxit        lda             :cv
              sta             termcv
              lda             :ch
              sta             termch
              jsl             setch
:stxit1       lda             :curs
              sta             cursor
              jmp             :cmdxit

:temp         ds              2
:ch           ds              2
:cv           ds              2
:curs         ds              2

              mx              %11
:tabsoff      ldx             #$07
]lup          lda             tabs,x
              sta             tabs1,x
              stz             tabs,x
              dex
              bpl             ]lup
              rep             $30
              jsr             drawtabs
              lda             linenum
              sta             gotolnum
              jsr             gotoline
              jsr             getbuff
              jsr             drawline
              stz             pos
              jsr             poscurs
              jmp             :cmdxit

              mx              %11
:tabson       ldx             #$07
]lup          lda             tabs1,x
              sta             tabs,x
              dex
              bpl             ]lup
              jsr             drawtabs
              rep             $30
              lda             linenum
              sta             gotolnum
              jsr             gotoline
              jsr             getbuff
              jsr             drawline
              stz             pos
              jsr             poscurs
              jmp             :cmdxit

:savefile     rep             $30
              lda             flen
              bne             :sstz
              jmp             :cmdxit
:sstz         stz             :openflag
              stz             :loaded
              jsr             drawbox
              jsr             drawesccan

              sep             $30
              ldx             efilename
]lup          lda             efilename,x
              and             #$7f
              cmp             #'a'
              blt             :uc1
              cmp             #'z'+1
              bge             :uc1
              and             #$5f
:uc1          sta             :filename,x
              dex
              bpl             ]lup
              rep             $30

              jsl             print
              dfb             44
              dfb             7
              asc             "SAVE file as:",00
              jsl             getline
              adrl            :filename
              dfb             15
              dfb             44
              dfb             10
              php
              jsr             drawesc
              plp
              jcs             :sfplp
              rep             $30
              lda             :filename
              and             #$00FF
              jeq             :sfplp
              jsl             print
              dfb             44
              dfb             7
              asc             "Saving...    ",00

              lda             flen
              sta             editlen
              sta             :request
              sta             :eof+2
              stz             :openflag

              lda             :filename
              and             #$ff
              tax
              lda             :filename,x
              and             #$7f
              cmp             #'!'
              bne             :notapw
              lda             :filename
              and             #$ff
              tax
              sep             $20
:lfn          lda             :filename,x
              sta             loadfilename,x
              dex
              bpl             :lfn
              rep             $20
              jmp             saveapw

:notapw       lda             :filename
              and             #$ff
              cmp             #3
              blt             :notmerlin
              tax
              lda             :filename,x
              and             #$5f
              cmp             #'S'
              bne             :notmerlin
              dex
              lda             :filename,x
              and             #$7f
              cmp             #'.'
              bne             :notmerlin
              jmp             :merlin
:notmerlin
              ldy             #$00
              sep             $20
]lup          lda             [fileptr],y
              and             #$7f
              sta             [fileptr],y
              iny
              cpy             editlen
              blt             ]lup
              rep             $20
:merlin
              jsl             prodos
              dw              $01
              adrl            :create
              jsl             prodos
              dw              $06
              adrl            :info
              jcs             :err
              lda             :type
              cmp             #$b0
              beq             :p16open
              cmp             #$1a
              beq             :settxt
              cmp             #$04
              bne             :badtype
              lda             #$04
              sta             :type
              lda             :aux
              and             #$fffe
              sta             :aux
              bra             :p16
:settxt       lda             #$04
              sta             :type
              stz             :aux
:p16          jsl             prodos
              dw              $05
              adrl            :info
              jcs             :err
              jmp             :p16open
:badtype      lda             #nottext
              jmp             :err
:p16open      jsl             prodos
              dw              $10
              adrl            :open
              jcs             :err
              sec
              ror             :openflag
              lda             :open
              sta             :write
              sta             :close
              sta             :eof
              stz             :request+2
              stz             :eof+4
              lda             fileptr
              sta             :where
              lda             fileptr+2
              sta             :where+2
              jsl             prodos
              dw              $18
              adrl            :eof
              jcs             :err
              jsl             prodos
              dw              $13
              adrl            :write
              jcs             :err

              jsl             prodos
              dw              $14
              adrl            :close
              stz             :openflag

              sec
              ror             :loaded

              stz             alldirty

              sep             $30
              ldx             :filename
]lup          lda             :filename,x
              and             #$7f
              cmp             #'a'
              blt             :uc
              cmp             #'z'+1
              bge             :uc
              and             #$5f
:uc           sta             efilename,x
              dex
              bpl             ]lup
              rep             $30

              jsr             drawfname

:sfplp        rep             $30
              bit             :openflag
              bpl             :sfplp1
              jsl             prodos
              dw              $14
              adrl            :close
              stz             :openflag
:sfplp1       jsr             erasebox
              jmp             :cmdxit
:err          jsr             doerror
              jmp             :sfplp

:loaded       ds              2
:openflag     ds              2
:close        ds              2
:open         ds              2
              adrl            :filename
              adrl            $0000
:write        ds              2
:where        adrl            $00
:request      adrl            $00
              adrl            $00
:info         adrl            :filename
              ds              2
:type         ds              2
:aux          ds              4
              ds              16
:eof          ds              6

:filename     ds              16,0

:create       adrl            :filename
              dw              $E3
              dw              $04
              adrl            $00
              dw              $01
              adrl            $0000

:gotolabel    rep             $30
              jsr             drawbox
              stz             :string
              jsr             drawesccan
              jsl             print
              dfb             44
              dfb             7
              asc             "JUMP to:",00
              jsl             getline
              adrl            :string
              dfb             28
              dfb             44
              dfb             10
              php
              jsr             erasebox
              jsr             drawesc
              plp
              bcs             :cbplp
              rep             $30
              lda             :string
              and             #$FF
              beq             :cbplp
              lda             :string+1
              and             #$7F
              cmp             #'0'
              blt             :label
              cmp             #'9'+1
              bge             :label
              pha
              psl             #:string+1
              lda             :string
              and             #$FF
              pha
              pea             $00
              tll             $280B
              pla
              sta             gotolnum
              jsr             gotoline
:cbplp        jmp             :cmdxit

:label        sep             $30
              ldx             :string
]lup          lda             :string,x
              cpx             #$00
              beq             :sl8
              and             #$7f
              cmp             #'a'
              blt             :sl8
              cmp             #'z'+1
              bge             :sl8
              and             #$5f
:sl8          sta             glabstr,x
              dex
              bpl             ]lup
              rep             $30
              lda             #$ffff
              sta             gotolnum
              jsr             gotolable
              jmp             :cmdxit
:string       ds              30


:insline      rep             $30
              jsr             savebuff
              lda             flen
              cmp             #$FFFF
              jge             :nomem
              jsr             setfflags
              lda             #$FFFF
              sta             dirty
              stz             oldlen
              lda             #$0D01
              sta             linebuff
              jsr             savebuff
:crup         jsl             setch
              jsr             updatescreen
              jsr             drawcpos
              jsr             getbuff
              stz             pos
              jsr             drawline
              jsr             poscurs
              jsr             setfflags
              jmp             :cmdxit
:nomem        jsr             memfull
              jmp             :cmdxit
:crtemp       ds              2

:delline      rep             $30
              lda             position
              cmp             flen
              jge             :cmdxit
              lda             position
              sta             :dpos
              jsr             foreptr
              sep             $20
              lda             fileptr+2
              sta             :mvn+1
              sta             :mvn+2
              rep             $30
              ldy             :dpos
              ldx             position
              lda             flen
              sec
              sbc             position
              dec
              cmp             #$FFFF
              beq             :ateof
              phb
:mvn          mvn             $00,$00
              plb
              lda             flen
              sec
              sbc             oldlen
              sta             flen
              jmp             :dupd
:ateof        lda             :dpos
              sta             flen
:dupd         lda             :dpos
              sta             position
              jsr             updatescreen
              jsr             drawcpos
              jsr             getbuff
              jsr             drawline
              jsr             poscurs
              jsr             drawmem
              jsr             setfflags
              jmp             :cmdxit
:dpos         ds              2

:delline1     rep             $30
              lda             sof
              jne             :cmdxit
              lda             position
              sta             :dpos
              jsr             backptr
              jsr             getbuff
              sep             $20
              lda             fileptr+2
              sta             :mvn1+1
              sta             :mvn1+2
              rep             $30
              ldy             position
              ldx             :dpos
              lda             flen
              sec
              sbc             :dpos
              dec
              cmp             #$FFFF
              beq             :eof1
              phb
:mvn1         mvn             $00,$00
              plb
:eof1         lda             flen
              sec
              sbc             oldlen
              sta             flen
              dec             linenum
              lda             termcv
              beq             :sch1
              dec
:ok           sta             termcv
:sch1         jsl             setch
              jmp             :dupd1
:eof12        lda             :dpos
              sta             flen
:dupd1        jsr             updatescreen
              jsr             drawcpos
              jsr             getbuff
              jsr             drawline
              jsr             poscurs
              jsr             drawmem
              jsr             setfflags
              jmp             :cmdxit


:gobegin      rep             $30
              stz             findstr
              stz             replacestr
              lda             sof
              jne             :cmdxit
              lda             #$0001
              sta             gotolnum
              jsr             gotoline
              jmp             :cmdxit

:goend        rep             $30
              stz             findstr
              stz             replacestr
              lda             eof
              jne             :cmdxit
              lda             #$FFFF
              sta             gotolnum
              jsr             gotoline
              jmp             :cmdxit

:up10         rep             $30
              lda             sof
              jne             :cmdxit
              lda             dirty
              beq             :u1
              jsr             savebuff
:u1           lda             linenum
              sec
              sbc             #10
              bcs             :u10ok
              lda             #$01
:u10ok        sta             gotolnum
              lda             #10
              jsr             selbackward
              jsr             gotoline
              jmp             :cmdxit

:dn10         rep             $30
              lda             eof
              jne             :cmdxit
              lda             dirty
              beq             :d1
              jsr             savebuff
:d1           lda             linenum
              clc
              adc             #10
              bcc             :d10ok
              lda             #$FFFF
:d10ok        sta             gotolnum
              lda             #10
              jsr             selforward
              jsr             gotoline
              jmp             :cmdxit

:up24         rep             $30
              lda             sof
              jne             :cmdxit
              lda             dirty
              beq             :u2
              jsr             savebuff
:u2           lda             linenum
              sec
              sbc             #24
              bcs             :u24ok
              lda             #$01
:u24ok        sta             gotolnum
              lda             #24
              jsr             selbackward
              jsr             gotoline
              jmp             :cmdxit

:dn24         rep             $30
              lda             eof
              jne             :cmdxit
              lda             dirty
              beq             :d2
              jsr             savebuff
:d2           lda             linenum
              clc
              adc             #24
              bcc             :d24ok
              lda             #$FFFF
:d24ok        sta             gotolnum
              lda             #24
              jsr             selforward
              jsr             gotoline
              jmp             :cmdxit


              mx              %11
:quit         lda             #$FF
              sta             equitflag
              sta             equitflag+1
              jmp             :cmdxit

:cursor       lda             cursor
              and             #$7F
              cmp             #'_'
              beq             :ow
              lda             #"_"
              sta             cursor
              jmp             :cmdxit
:ow           lda             #' '
              sta             cursor
              jmp             :cmdxit

:showcr       lda             showcr
              bne             :soff
              lda             #$FF
              sta             showcr
              sta             showcr+1
              jmp             :crupdate
:soff
              stz             showcr
              stz             showcr+1

:crupdate     rep             $30
              lda             linenum
              sta             gotolnum
              jsr             gotoline
              jmp             :cmdxit
              mx              %11

controls      php
              sep             $30
              ldx             #$00
              sta             :char
              cmp             #$7F
              jeq             :delete
              cmp             #$20
              bge             :plp
]lup          lda             :tbl,x
              beq             :plp1
              cmp             :char
              beq             :found
              inx
              jmp             ]lup
:found        rep             $30
              txa
              asl
              tax
              lda             :tbl1,x
              sta             :jmp+1
              sep             $30
:jmp          jmp             $FFFF
:plp          lda             :char
              plp
              sec
              rts
:plp1         lda             :char
              plp
              clc
              rts
:char         ds              2

:tbl          hex             08                             ;backspace char
              hex             15                             ;right arrow
              hex             0d                             ;carriage return
              hex             0a                             ;down arrow
              hex             0b                             ;up arrow
              hex             1b                             ;escape
              hex             09                             ;tab
              hex             0e                             ;^N eoln
              hex             0f                             ;^O insert next char
              hex             02                             ;^B beginning of line
              hex             14                             ;^T set marker
              dfb             'Y'&$1f                        ;^Y truncate line
              dfb             'X'&$1f                        ;^X cancel find/replace
              hex             00                             ;must end with zero

:tbl1         dw              :bspace
              dw              :rarrow
              dw              :cr
              dw              :darrow
              dw              :uarrow
              dw              :esc
              dw              :tab
              dw              :controln
              dw              :controlo
              dw              :controlb
              dw              :controla
              dw              :controly
              dw              :controlx

:tab          lda             #$09
              plp
              sec
              rts
:controlx     jsr             controlx
              jmp             :ctrlxit
:controly     jsr             controly
              jmp             :ctrlxit

:controlo     sec
              ror             oflag
              jmp             :ctrlxit

:controln     lda             #$FF
              sta             pos
              jsr             poscurs
              jmp             :ctrlxit

:controlb
              stz             pos
              jsr             poscurs
              jmp             :ctrlxit

:controla     lda             linenum
              sta             marker
              lda             linenum+1
              sta             marker+1
              jmp             :ctrlxit

:esc          lda             #$FF
              sta             equitflag
              sta             equitflag+1
:ctrlxit      plp
              clc
              rts

:cr           rep             $30
              jsr             savebuff
              lda             flen
              cmp             #$FFFF
              jge             :nomem
              jsr             setfflags
              lda             eof
              sta             :crtemp
              jsr             foreptr
              lda             #$FFFF
              sta             dirty
              stz             oldlen
              lda             #$0D01
              sta             linebuff
              jsr             savebuff
              lda             :crtemp
              bne             :crup
              inc             linenum
              lda             termcv
              inc
              cmp             #22
              blt             :s
              jsl             scroll
              lda             #21
:s            sta             termcv
:crup         jsl             setch
              jsr             updatescreen
* jsr showcv
              jsr             drawcpos
              jsr             getbuff
              stz             pos
              jsr             drawline
              jsr             poscurs
              jsr             setfflags
:cmdxit       plp
              clc
              rts
:nomem        jsr             memfull
              jmp             :cmdxit
:crtemp       ds              2

              mx              %11
:darrow       lda             dirty
              beq             :dn
              jsr             savebuff
:dn           lda             eof
              bne             :darx
              lda             termch
              sta             :ch
              jsr             foreptr
              lda             termcv
              inc
              cmp             #22
              blt             :dok
              jsl             scroll
              lda             #21
:dok          sta             termcv
              jsl             setch
              bit             selecting+1
              bpl             :dg
              lda             position
              sta             selend
              lda             position+1
              sta             selend+1
:dg           jsr             getbuff
              jsr             drawline
              lda             :ch
              sta             oldch
              jsr             setpos
              jsr             poscurs
              rep             $30
              inc             linenum
              jsr             drawcpos
* jsr showcv
:darx         plp
              clc
              rts
:ch           ds              2
              mx              %11

:uarrow       lda             dirty
              beq             :up
              jsr             savebuff
:up           rep             $30
              bit             selecting
              bpl             :nosel
              lda             selend
              pha
              stz             selend
              jsr             drawline
              pla
              sta             selend
:nosel        lda             position
              sta             :pos
              lda             termch
              sta             :ch
              jsr             backptr
              lda             position
              cmp             :pos
              bne             :tcv

              sep             $30
              lda             sof
              bne             :uarx
:tcv          sep             $30
              lda             termcv
              beq             :bs
              dec
              jmp             :uok
:bs           jsl             bscroll
              lda             #00
:uok          sta             termcv
              jsl             setch
              bit             selecting+1
              bpl             :ug
              rep             $30
              lda             position
              sta             selend
              cmp             selstart
              bge             :ug
              jsr             selectoff1
:ug           sep             $30
              jsr             getbuff
              jsr             drawline
              lda             :ch
              sta             oldch
              jsr             setpos
              jsr             poscurs
              rep             $30
              dec             linenum
              jsr             drawcpos
* jsr showcv
:uarx         plp
              clc
              rts
:pos          ds              2
              mx              %11

:rarrow       lda             linebuff
              beq             :bxit
              lda             termch
              cmp             #right-1
              bge             :bxit
              lda             pos
              inc
              cmp             linebuff
              bge             :bxit
              inc             pos
              lda             pos
              cmp             #255
              blt             :rpos
              lda             #255
              sta             pos
:rpos         jsr             poscurs
              jmp             :bxit
:bspace       lda             linebuff
              beq             :bxit
              lda             pos
              beq             :bxit
              cmp             #right
              blt             :bdec
              lda             #right
              sta             pos
:bdec         dec             pos
              jsr             poscurs
:bxit         plp
              clc
              rts

:delete       lda             linebuff
              beq             :dxit
              ldx             pos
              beq             :dxit
]lup          cpx             linebuff
              bge             :ddec
:d            lda             linebuff+1,x
              sta             linebuff,x
              inx
              jmp             ]lup
:ddec         dec             linebuff
              dec             pos
              sec
              ror             dirty
              jsr             drawline
              jsr             poscurs
:dxit         plp
              clc
              rts

controlx      php
              rep             $30
              stz             findstr
              stz             replacestr
              plp
              rts

controly      php
              sep             $30
              ldx             pos
              beq             :cy
              inx
              stx             linebuff
              lda             #$0d
              sta             linebuff,x
:cy1          lda             #$ff
              sta             dirty
              sta             dirty+1
              jsr             savebuff
              jsr             getbuff
              jsr             drawline
              jsr             poscurs
              jmp             :xit
:cy           stz             pos
              lda             #$01
              sta             linebuff
              lda             #$0d
              sta             linebuff+1
              jmp             :cy1
:xit          plp
              rts

selectoff     php
              rep             $30
              jsr             selectoff1                     ;why duplicate?
              lda             position
              sta             gotoposition
              jsr             gotopos
              plp
              rts

selectoff1    php
              rep             $30
              lda             #$ffff
              sta             selstart
              sta             selend
              stz             selecting
              lda             #$80
              sta             selectflag
              plp
              rts

inserttext    php
              rep             $30
              sta             :ct
              stx             :source
              sty             :dest
              clc
              adc             flen
              bcs             :toobig
              lda             fileptr
              clc
              adc             :source
              tax
              lda             fileptr+2
              adc             #$00
              pha
              phx
              lda             fileptr
              clc
              adc             :dest
              tax
              lda             fileptr+2
              adc             #$00
              pha
              phx
              pea             0
              lda             flen
              sec
              sbc             :source
              pha
              tll             $2b02                          ;_BlockMove
              lda             :ct
              clc
              adc             flen
              sta             flen
              plp
              clc
              rts

:toobig       jsr             memfull
              plp
              sec
              rts

:ct           ds              2
:source       ds              2
:dest         ds              2

deletetext    php
              rep             $30
              sta             :ct
              stx             :source
              sty             :dest
              lda             flen
              sec
              sbc             :ct
              bcs             :ok
              stz             flen
              plp
              clc
              rts
:ok           lda             fileptr
              clc
              adc             :source
              tax
              lda             fileptr+2
              adc             #$00
              pha
              phx
              lda             fileptr
              clc
              adc             :dest
              tax
              lda             fileptr+2
              adc             #$00
              pha
              phx
              pea             0
              lda             flen
              sec
              sbc             :source
              pha
              tll             $2b02                          ;_BlockMove
              lda             flen
              sec
              sbc             :ct
              bcs             :f
              lda             #$00
:f            sta             flen
              plp
              clc
              rts
:ct           ds              2
:source       ds              2
:dest         ds              2


selforward    php
              rep             $30
              bit             selecting
              bpl             :xit
              and             #$ff
              sta             :ct
              stz             eof
]lup          lda             :ct
              beq             :done
              jsr             foreptr
              dec             :ct
              bra             ]lup
:done         lda             position
              sta             selend
:xit          plp
              rts
:ct           ds              2

selbackward   php
              rep             $30
              bit             selecting
              bpl             :xit
              and             #$ff
              sta             :ct
              stz             eof
]lup          lda             :ct
              beq             :done
              jsr             backptr
              dec             :ct
              bra             ]lup
:done         lda             position
              sta             selend
              cmp             selstart
              bge             :xit
              jsr             selectoff1
:xit          plp
              rts
:ct           ds              2

*------------------------------------------------------
copyselect    php
              rep             $30
              lda             cliphandle
              ora             cliphandle+2
              bne             :resize
              psl             #$00
              psl             #$01
              lda             userid
              ora             #$900
              pha
              pea             0
              psl             #$00
              _Newhandle
              plx
              ply
              jcs             :err
              stx             cliphandle
              sty             cliphandle+2
:resize       lda             position
              pha
              lda             sof
              pha
              lda             eof
              pha
              stz             eof
              stz             sof
              lda             selend
              sta             position
              jsr             foreptr
              lda             position
              ldy             eof
              beq             :1
              lda             flen
:1            sta             selend
              sec
              sbc             selstart
              pea             0
              pha
              psl             cliphandle
              _SetHandleSize
              ply
              sty             eof
              ply
              sty             sof
              ply
              sty             position
              jcs             :err
              lda             selstart
              clc
              adc             fileptr
              tax
              lda             #$00
              adc             fileptr+2
              pha
              phx
              psl             cliphandle
              psl             #$00
              psl             cliphandle
              _GetHandleSize
              tll             $2802                          ;_PtrToHand
              plp
              clc
              rts

:err          jsr             memfull
              plp
              sec
              rts

              mx              %00
initedit      php
              rep             $30
              stz             findstr
              stz             replacestr
              stz             cliphandle
              stz             cliphandle+2
              lda             editlen
              sta             flen
              stz             pos
              stz             pos1
              stz             linebuff
              stz             position
              stz             eof
              stz             dirty
              stz             selecting
              lda             #$FFFF
              sta             selstart
              sta             selend
              sta             selstart
              sta             selend
              stz             termcv
              stz             termch

              pha
              psl             #$00
              tll             $130C
              pll             textdevice
              pla
              sta             texttype

              pha
              pha
              tll             $0D0C
              pla
              sta             textor
              pla
              sta             textand

              pea             $01                            ;pascal...
              psl             #$03                           ;turn on 80 column
              tll             $100c
              pea             $01
              tll             $150c

              pea             $02
              psl             #textdriver
              tll             $100C                          ;setoutputdevice

              pea             $FF
              pea             $80
              tll             $0A0C

              jsl             clrscreen
              jsr             editscreen

              stz             termcv
              stz             termch
              sta             oflag

              lda             #$FFFF
              sta             sof
              jsl             setch

              jsr             checkload

              lda             linenum
              sta             gotolnum
              jsr             gotoline

              sep             $20
              ldal            $E0C029
              and             #$7F
              stal            $E0C029
              rep             $20
              plp
              rts

*------------------------------------------------------
savebuff

]y1           equ             workspace
]y2           equ             ]y1+2
]len          equ             ]y2+2
]where        equ             ]len+2
]len1         equ             ]where+2

              php
              rep             $30
              lda             dirty
              bne             :save
              plp
              rts
:save         sec
              ror             alldirty
              lda             linebuff
              and             #$00FF
              sta             ]len1
              bne             :tax
              lda             #$0D01
              sta             linebuff
              and             #$00FF
              sta             ]len1
:tax          tax
              lda             linebuff,x
              and             #$7F
              cmp             #$0D
              beq             :olen
              cpx             #$FF
              beq             :noinc
              inx
:noinc        lda             #$0D
              sta             linebuff,x
              txa
              and             #$00FF
              sta             ]len1
:olen         lda             oldlen
              and             #$00FF
              sta             oldlen
              lda             ]len1
              sec
              sbc             oldlen
              jeq             :replace
              jcs             :bigger
:smaller      lda             position
              clc
              adc             oldlen
              sta             ]len
              lda             flen
              sec
              sbc             ]len
              dec
              sta             ]y2
              lda             oldlen
              sec
              sbc             ]len1
              and             #$00FF
              sta             ]y1
              lda             flen
              sec
              sbc             ]y1
              sta             flen
              sep             $20
              lda             fileptr+2
              sta             :mvn+1
              sta             :mvn+2
              rep             $20
              ldx             ]len
              lda             position
              clc
              adc             ]len1
              tay
              lda             ]y2
              cmp             #$FFFF
              jeq             :replace
              phb
:mvn          mvn             $00,$00
              plb
              jmp             :replace
:bigger       and             #$00FF
              sta             ]y1                            ;num of bytes to move
              lda             position
              cmp             flen
              jeq             :add
              clc
              adc             oldlen
              sta             ]y2                            ;temp
              lda             flen
              sec
              sbc             ]y2
* dec
              sta             ]y2                            ;for mvp call
              sep             $20
              lda             fileptr+2
              sta             :mvp+1
              sta             :mvp+2
              rep             $20
              ldx             flen
              txa
              clc
              adc             ]y1
              bcs             :memerr
              sta             flen
              tay
              lda             ]y2
              phb
:mvp          mvp             $00,$00
              plb
              jmp             :replace
:memerr       jsr             memfull
              jmp             :xit
:add          lda             ]y1
              clc
              adc             flen
              bcs             :memerr
              sta             flen
:replace      rep             $30
              sep             $20
              lda             #^linebuff
              sta             :mvn1+2
              lda             fileptr+2
              sta             :mvn1+1
              rep             $20
              lda             ]len1
              and             #$00FF
              beq             :xit
              dec
              ldx             #linebuff+1
              ldy             position
              phb
:mvn1         mvn             $00,$00
              plb
:xit          rep             $30
              jsr             drawmem
              jsr             setfflags
              stz             dirty
              plp
              rts

getbuff       php
              rep             $30
              stz             oldlen
              lda             eof
              jne             :newline
:main         ldy             position
              cpy             flen
              bge             :newline
              ldx             #$00
              sep             $20
:loop         lda             [fileptr],y
              sta             linebuff+1,x
              and             #$7F
              iny
              inx
              cmp             #$0D
              beq             :next
              cpx             #$FF
              bge             :next1
              cpy             flen
              blt             :loop
              jmp             :next
:next1        ldx             #$FF
:next         txa
              sta             linebuff
              lda             linebuff,x
              and             #$7F
              cmp             #$0D
              beq             :plp
              lda             linebuff
              cmp             #$FF
              bge             :stacr
              inx
              inc             linebuff
:stacr        lda             #$0D
              sta             linebuff,x
:plp          lda             linebuff
              sta             oldlen
              stz             dirty
              stz             dirty+1
              plp
              rts
              mx              %00
:newline      lda             #$0D01
              sta             linebuff
              stz             oldlen
              stz             dirty
              plp
              rts
              mx              %00

setrange      php
              rep             $30
              lda             selstart
              cmp             selend
              beq             :couldbe
              bge             :off
:couldbe      lda             position
              cmp             selstart
              blt             :off
              cmp             selend
              beq             :on
              bge             :off
:on
              stz             selectflag
              plp
              rts
:off          lda             #$80
              sta             selectflag
* stz selecting
              plp
              rts

setfflags     php
              rep             $30
              stz             eof
              stz             sof
              lda             position
              bne             :seof
              dec             sof
:seof         cmp             flen
              blt             :plp
              dec             eof
:plp          plp
              rts

backptr       php
              rep             $30
              stz             sof
              stz             eof
              stz             :crflag
              ldy             position
              bne             :move
:sof          jmp             :plp

:move         sep             $20

]loop         dey
              cpy             #$FFFF
              beq             :endxit
              lda             [fileptr],y
              and             #$7F
              cmp             #$0D
              beq             :cr
:first        sec
              ror             :crflag
              jmp             ]loop
:cr           bit             :crflag
              bpl             :first
:endxit       iny
:xit          sty             position
:plp          rep             $30
              lda             position
              bne             :qeof
              ldy             #$FFFF
              sty             sof
:qeof         cmp             flen
              blt             :plp1
              lda             #$FFFF
              sta             eof
:plp1         plp
              rts
:crflag       ds              2
              mx              %00


              do              1
gotoline      php
              rep             $30
              lda             #$01
              sta             :line
              stz             position
              stz             :offset
              stz             :ct
              ldy             #$00
:nline        rep             $30
              lda             :offset
              asl
              tax
              lda             position
              sta             :array,x
              inc             :offset
              inc             :ct
              lda             :offset
              cmp             #12
              blt             :gline
              stz             :offset
:gline        lda             :line
              cmp             gotolnum
              bge             :done
              sep             $20
]lup          lda             [fileptr],y
              and             #$7f
              cmp             #$0d
              beq             :eoln
              iny
              cpy             flen
              blt             ]lup
              bra             :done
:eoln         iny
              sty             position
              inc             :line
              bne             :nline
              inc             :line+1
              bra             :nline
:done         rep             $30
              stz             termch
              stz             pos
              lda             :line
              sta             linenum
              lda             position
              sta             :pos
              lda             :ct
              cmp             #12
              blt             :garray
]sbc          cmp             #12
              blt             :goffset
              sec
              sbc             #12
              jmp             ]sbc
:goffset      inc
              cmp             #12
              blt             :asl
              lda             #$00
:asl          asl
              tax
              lda             :array,x
              sta             position
              lda             #10
              sta             termcv
              jmp             :set

:garray       dec
              sta             :offset
              lda             #$00
              asl
              tax
              lda             :array,x
              sta             position
              lda             :offset
              sta             termcv
:set          jsl             setch
              jsr             drawcpos

              jsr             drawscreen
              stz             eof
              stz             sof
              lda             :pos
              sta             position
              cmp             #$00
              bne             :seof
              dec             sof
:seof         cmp             flen
              blt             :gbuff
              dec             eof
:gbuff        jsr             getbuff
              jsr             drawline
              jsr             poscurs
              plp
              rts

:line         ds              2
:offset       ds              2
:ct           ds              2
:array        ds              24*2,0
:pos          ds              2


              else
gotoline      php
              rep             $30
              stz             eof
              stz             position
              lda             position
              cmp             flen
              bne             :stz
              lda             #$ffff
              sta             eof
:stz          stz             position
              stz             :offset
              stz             :ct
              lda             #$01
              sta             sof
              sta             :line
]lup          lda             :offset
              asl
              tax
              lda             position
              sta             :array,x
              inc             :offset
              inc             :ct
              lda             :offset
              cmp             #12
              blt             :gline
              stz             :offset
:gline        lda             :line
              cmp             gotolnum
              bge             :done
              lda             eof
              bne             :done
              jsr             foreptr
              inc             :line
              jmp             ]lup
:done
              stz             termch
              stz             pos
              lda             :line
              sta             linenum
              lda             position
              sta             :pos
              lda             :ct
              cmp             #12
              blt             :garray
]sbc          cmp             #12
              blt             :goffset
              sec
              sbc             #12
              jmp             ]sbc
:goffset      inc
              cmp             #12
              blt             :asl
              lda             #$00
:asl          asl
              tax
              lda             :array,x
              sta             position
              lda             #10
              sta             termcv
              jmp             :set

:garray       dec
              sta             :offset
              lda             #$00
              asl
              tax
              lda             :array,x
              sta             position
              lda             :offset
* clc
* adc #$02
              sta             termcv
:set          jsl             setch
              jsr             drawcpos

              jsr             drawscreen
* jsr showch
* jsr showcv
              stz             eof
              stz             sof
              lda             :pos
              sta             position
* cmp #$00
              bne             :seof
              dec             sof
:seof         cmp             flen
              blt             :gbuff
              dec             eof
:gbuff        jsr             getbuff
              jsr             drawline
              jsr             poscurs
              plp
              rts

:line         ds              2
:offset       ds              2
:ct           ds              2
:array        ds              24*2,0
:pos          ds              2
              fin

gotolable     php
              rep             $30
              lda             glabstr
              and             #$ff
              jeq             :gbuff
              sta             :len
              stz             eof
              stz             position
* lda position
              lda             flen
              bne             :stz
              lda             #$ffff
              sta             eof
:stz          stz             position
              stz             :offset
              stz             :ct
              lda             #$01
              sta             sof
              sta             :line
]lup          lda             :offset
              asl
              tax
              lda             position
              sta             :array,x
              inc             :offset
              inc             :ct
              lda             :offset
              cmp             #12
              blt             :gline
              stz             :offset
:gline        lda             :line
              cmp             gotolnum
              bge             :done
              lda             eof
              bne             :done
              ldx             #$01
              ldy             position
              sep             $20
]cmp          lda             [fileptr],y
              and             #$7f
              cmp             #'a'
              blt             :l1
              cmp             #'z'+1
              bge             :l1
              and             #$5f
:l1           cmp             glabstr,x
              bne             :no
              iny
              inx
              cpy             flen
              bge             :done
              cpx             :len
              blt             ]cmp
              beq             ]cmp
              jmp             :done
:no           rep             $30
              jsr             foreptr
              inc             :line
              jmp             ]lup
:done         rep             $30
              stz             termch
              stz             pos
              lda             :line
              sta             linenum
              lda             position
              sta             :pos
              lda             :ct
              cmp             #12
              blt             :garray
]sbc          cmp             #12
              blt             :goffset
              sec
              sbc             #12
              jmp             ]sbc
:goffset      inc
              cmp             #12
              blt             :asl
              lda             #$00
:asl          asl
              tax
              lda             :array,x
              sta             position
              lda             #10
              sta             termcv
              jmp             :set

:garray       dec
              sta             :offset
              lda             #$00
              asl
              tax
              lda             :array,x
              sta             position
              lda             :offset
* clc
* adc #$02
              sta             termcv
:set          jsl             setch
              jsr             drawcpos

              jsr             drawscreen
* jsr showch
* jsr showcv
              stz             eof
              stz             sof
              lda             :pos
              sta             position
* cmp #$00
              bne             :seof
              dec             sof
:seof         cmp             flen
              blt             :gbuff
              dec             eof
:gbuff        rep             $30
              jsr             getbuff
              jsr             drawline
              jsr             poscurs
              plp
              rts
:len          ds              2
:line         ds              2
:offset       ds              2
:ct           ds              2
:array        ds              24*2,0
:pos          ds              2


gotopos       php
              rep             $30
              stz             eof
              stz             position
* lda position
              lda             flen
              bne             :stz
              lda             #$ffff
              sta             eof
:stz          stz             position
              stz             :offset
              stz             :ct
              lda             #$01
              sta             sof
              sta             :line
]lup          lda             :offset
              asl
              tax
              lda             position
              sta             :array,x
              inc             :offset
              inc             :ct
              lda             :offset
              cmp             #12
              blt             :gline
              stz             :offset
:gline        lda             position
              cmp             gotoposition
              bge             :done
              lda             eof
              bne             :done
              jsr             foreptr
              inc             :line
              jmp             ]lup
:done
              stz             termch
              stz             pos
              lda             :line
              sta             linenum
              lda             position
              sta             :pos
              lda             :ct
              cmp             #12
              blt             :garray
]sbc          cmp             #12
              blt             :goffset
              sec
              sbc             #12
              jmp             ]sbc
:goffset      inc
              cmp             #12
              blt             :asl
              lda             #$00
:asl          asl
              tax
              lda             :array,x
              sta             position
              lda             #10
              sta             termcv
              jmp             :set

:garray       dec
              sta             :offset
              lda             #$00
              asl
              tax
              lda             :array,x
              sta             position
              lda             :offset
* clc
* adc #$02
              sta             termcv
:set          jsl             setch
              jsr             drawcpos

              jsr             drawscreen
* jsr showch
* jsr showcv
              stz             eof
              stz             sof
              lda             :pos
              sta             position
* cmp #$00
              bne             :seof
              dec             sof
:seof         cmp             flen
              blt             :gbuff
              dec             eof
:gbuff        jsr             getbuff
              jsr             drawline
              jsr             poscurs
              plp
              rts

:line         ds              2
:offset       ds              2
:ct           ds              2
:array        ds              24*2,0
:pos          ds              2



foreptr       php
              rep             $30
              stz             eof
              stz             sof
              ldy             position
              cpy             flen
              bge             :plp
              ldx             #$00
              sep             $20
:loop         lda             [fileptr],y
              and             #$7F
              iny
              inx
              cmp             #$0D
              beq             :cr
              cpx             #$100
              bge             :cr
              cpy             flen
              blt             :loop
              jmp             :cr
:cr           sty             position
:plp          rep             $30
              lda             position
              bne             :qeof
              ldy             #$FFFF
              sty             sof
:qeof         cmp             flen
              blt             :plp1
              lda             #$FFFF
              sta             eof
:plp1         plp
              rts
              mx              %00
:pos          ds              2

drawscreen    php
              rep             $30
* lda flen
* bne :sta
* plp
* rts
:sta          lda             position
              sta             :pos
              lda             termcv
              sta             :cv
              stz             termcv
              jsl             setch
              jsr             setfflags
              lda             eof
              bne             :done
:main         ldy             position
              ldx             #$00
              cpy             flen
              bge             :docr
              sep             $20
:loop         lda             [fileptr],y
              sta             linebuff+1,x
              and             #$7F
              iny
              inx
              cmp             #$0D
              beq             :next
              cpx             #$100
              bge             :next1
              cpy             flen
              blt             :loop
:docr         sep             $20
              lda             #$0D
              sta             linebuff+1,x
              inx
              jmp             :next
:next1        ldx             #$FF
:next         txa
              sta             linebuff
              rep             $30
              jsr             drawline
              lda             termcv
              inc
              sta             termcv
              cmp             #22
              bge             :done
              jsl             setch
              bit             eof
              bmi             :done
              jsr             foreptr
              jmp             :main
:done         sep             $20
              lda             termcv
              cmp             #22
              bge             :done1
              jsl             setch
              ldy             #$00
]clr          lda             #" "
              phy
              jsl             storchar
              ply
              iny
              cpy             #right
              blt             ]clr
              lda             termcv
              inc
              sta             termcv
              jmp             :done
:done1        lda             :cv
              sta             termcv
              jsl             setch
              rep             $30
              lda             :pos
              sta             position
              jsr             setfflags
              jsr             getbuff
              plp
              rts
:pos          ds              2
:cv           ds              2

updatescreen  php
              rep             $30
:sta          lda             position
              sta             :pos
              lda             termcv
              sta             :cv
              jsl             setch
              jsr             setfflags
              lda             flen
              jeq             :done
              lda             eof
              bne             :done
:main         ldy             position
              ldx             #$00
              cpy             flen
              bge             :docr
              sep             $20
:loop         lda             [fileptr],y
              sta             linebuff+1,x
              and             #$7F
              iny
              inx
              cmp             #$0D
              beq             :next
              cpx             #$100
              bge             :next1
              cpy             flen
              blt             :loop
:docr         sep             $20
              lda             #$0D
              sta             linebuff+1,x
              inx
              jmp             :next
:next1        ldx             #$FF
:next         txa
              sta             linebuff
              rep             $30
              jsr             drawline
              lda             termcv
              inc
              sta             termcv
              cmp             #22
              bge             :done
              jsl             setch
              bit             eof
              bmi             :done
              jsr             foreptr
              jmp             :main
:done         sep             $20
              lda             termcv
              cmp             #22
              bge             :done1
              jsl             setch
              ldy             #$00
]clr          lda             #" "
              phy
              jsl             storchar
              ply
              iny
              cpy             #right
              blt             ]clr
              lda             termcv
              inc
              sta             termcv
              jmp             :done
:done1        lda             :cv
              sta             termcv
              jsl             setch
              rep             $30
              lda             :pos
              sta             position
              jsr             setfflags
              plp
              rts
:pos          ds              2
:cv           ds              2


drawline      pha
              phx
              phy
              php
              sep             $30
              jsr             modify
              jsr             setrange
              stz             :litflag
              ldy             #$00
              sty             :ch
              sty             :tabct
              lda             linebuff
              jeq             :xit
              ldx             #$07
              lda             #$00
]lup          ora             tabs,x
              dex
              bpl             ]lup
              ldx             #$00
              cmp             #$00
              jeq             :normal
              lda             linebuff+1
              and             #$7F
              cmp             #';'
              jeq             :docomment
              cmp             #'*'
              jeq             :normal
              cmp             #$0D
              jeq             :normal
:loop         lda             :ch
              cmp             #right
              jge             :xit
              inx
              cpx             linebuff
              blt             :ok
              beq             :ok
              jmp             :xit
:ok           lda             linebuff,x
              cmp             #$A0
              beq             :tab
              and             #$7F
              cmp             #';'
              beq             :comment
              cmp             #$09
              beq             :tab
              cmp             #$27
              beq             :literal
              cmp             #$22
              beq             :literal
              cmp             #$0D
              bne             :ora
              lda             showcr
              beq             :loop
              bit             selectflag
              bmi             :ncr
              lda             #$46+$80
              bra             :phx
:ncr          lda             #$4D+$80
              bra             :phx
:ora          cmp             #$20
              blt             :phx
* ora selectflag
:phx          phx
              ldy             :ch
              jsl             storchar1
              plx
:incch        inc             :ch
              jmp             :loop
:literal      pha
              lda             #$80
              eor             :litflag
              sta             :litflag
              pla
              jmp             :ora
:comment      bit             :litflag
              bmi             :cjmp
              dex
              lda             linebuff,x
              and             #$7F
              cmp             #$20
              jeq             :docomment
              cmp             #$09
              jeq             :docomment
              inx
              lda             #';'
:cjmp         jmp             :ora
:tab          ldy             :tabct
              cpy             #$08
              bge             :space
              inc             :tabct
              lda             tabs,y
              beq             :space
              cmp             :ch
              blt             :space
              beq             :space
              sta             :tabval
              ldy             :ch
              sta             :ch
]lup          cpy             :tabval
              blt             :s1
              jmp             :loop
:s1           lda             #' '
* ora selectflag
              phy
              jsl             storchar1
              ply
              iny
              jmp             ]lup
:space        lda             #$20
              jmp             :ora
:xit          sep             $30
              ldy             :ch
              dey
]lup          iny
              cpy             #right
              bge             :plp1
              lda             #' '
* ora selectflag
              phy
              jsl             storchar1
              ply
              jmp             ]lup
:plp1         plp
              ply
              plx
              pla
              rts

:docomment    phx
              ldx             #$07
:xloop        lda             tabs,x
              beq             :dext
              cmp             :ch
              blt             :space1
              beq             :space1
              sta             :tabval
              ldy             :ch
              sta             :ch
]lup          cpy             :tabval
              blt             :s11
              jmp             :cplx
:s11          lda             #' '
* ora selectflag
              phy
              jsl             storchar1
              ply
              iny
              jmp             ]lup
:space1       lda             #$20
* ora selectflag
              ldy             :ch
              jsl             storchar1
              plx
              phx
              beq             :cplx
              lda             linebuff,x
              and             #$7F
              cmp             #$20
              beq             :cplx
              cmp             #$09
              beq             :cplx
:dcinx        inc             :ch
              jmp             :cplx
:dext         dex
              bpl             :xloop
:cplx         plx

:normal       lda             :ch
              cmp             #right
              jge             :xit
              inx
              cpx             linebuff
              blt             :ok3
              beq             :ok3
              jmp             :xit
:ok3          lda             linebuff,x
              and             #$7F
              cmp             #$0D
              bne             :nora
              lda             showcr
              beq             :normal
              bit             selectflag
              bmi             :nncr
              lda             #$46+$80
              bra             :phx2
:nncr         lda             #$4D+$80
              bra             :phx2
:nora         cmp             #$09
              bne             :nora1
              lda             #$20
:nora1        cmp             #$20
              blt             :phx2
* ora selectflag
:phx2         phx
              ldy             :ch
              jsl             storchar1
              plx
              inc             :ch
              jmp             :normal

:ch           ds              2
:tabct        ds              2
:tabval       ds              2
:schar        ds              2
:litflag      ds              2

modify        php
              sep             $30
              lda             #$A0
              sta             :space
              lda             linebuff
              jeq             :mxit
              lda             #$00
              ldx             #$07
]lup          ora             tabs,x
              dex
              bpl             ]lup
              cmp             #$00
              jeq             :20
              lda             linebuff+1
              and             #$7F
              cmp             #'*'
              jeq             :20
              cmp             #';'
              beq             :20
              stz             :spacect
              stz             :spacect+1
              lda             #$80
              sta             :eorflag
              ldx             #$01
]lup          lda             linebuff,x
              and             #$7F
              cmp             #$27
              beq             :literal
              cmp             #$22
              beq             :literal
              cmp             #$20
              bne             :inx
              lda             :space
              sta             linebuff,x
:inx          cmp             #$A0
              beq             :incsp
              cmp             #$09
              beq             :incsp
              cmp             #';'
              bne             :inx1
              bit             :space
              bpl             :inx1
              dex
              beq             :stz1
              lda             linebuff,x
              inx
              and             #$7F
              cmp             #$20
              beq             :stz
              cmp             #$09
              beq             :stz
              jmp             :inx1
:incsp        inc             :spacect
              ldy             :spacect
              cpy             #$08
              bge             :stz
              lda             tabs,y
              bne             :inx1
              bra             :stz
:stz1         inx
:stz          stz             :eorflag
              lda             #$20
              sta             :space
:inx1         inx
              cpx             linebuff
              blt             ]lup
              beq             ]lup
              jmp             :mxit
:literal      pha
              lda             :space
              eor             :eorflag
              sta             :space
              pla
              jmp             :inx
:20           ldx             linebuff
]lup          lda             linebuff,x
              and             #$7F
              cmp             #$20
              bne             :dex
              sta             linebuff,x
:dex          dex
              bne             ]lup
:mxit         plp
              rts

:char         ds              2
:space        ds              2
:spacect      ds              2
:eorflag      ds              2

poscurs       pha
              phx
              phy
              php
              sep             $30
              jsr             modify
              stz             :litflag
              stz             aval
              stz             aval+1
              ldy             #$00
              sty             :ch
              sty             :tabct
              lda             pos
              cmp             linebuff
              blt             :ldx
              ldx             linebuff
              beq             :stapos
              lda             linebuff,x
              and             #$7F
              cmp             #$0D
              bne             :stapos
              dex
:stapos       stx             pos

:ldx          ldx             pos
              lda             linebuff
              jeq             :xit
              ldx             #$07
              lda             #$00
]lup          ora             tabs,x
              dex
              bpl             ]lup
              ldx             #$00
              cmp             #$00
              jeq             :normal
              lda             linebuff+1
              and             #$7F
              cmp             #';'
              jeq             :docomment
              cmp             #'*'
              jeq             :normal
              cmp             #$0D
              jeq             :normal
:loop         stz             :incflag
              inx
              cpx             pos
              blt             :lb
              beq             :lb
              jmp             :xit
:lb           cpx             linebuff
              blt             :ok
              beq             :ok
              jmp             :xit
:ok           lda             linebuff,x
              cmp             #$A0
              beq             :tab
              and             #$7F
              cmp             #';'
              beq             :comment
              cmp             #$09
              beq             :tab
              cmp             #$27
              beq             :literal
              cmp             #$22
              beq             :literal
:ora
:space
:incch        inc             :ch
              jmp             :loop
:literal      pha
              lda             #$80
              eor             :litflag
              sta             :litflag
              pla
              jmp             :ora
:comment      bit             :litflag
              bmi             :cjmp
              dex
              lda             linebuff,x
              and             #$7F
              cmp             #$20
              jeq             :docomment
              cmp             #$09
              jeq             :docomment
              inx
              lda             #';'
:cjmp         jmp             :ora
:tab          cpx             pos
              blt             :tab1
              bit             :litflag
              bmi             :tab1
              inx
              cpx             linebuff
              beq             :chkcomm
              bge             :tab2
:chkcomm      lda             linebuff,x
              dex
              and             #$7F
              cmp             #';'
              bne             :tab1
              sec
              ror             :incflag
              jmp             :docomment
:tab2         dex
:tab1         ldy             :tabct
              cpy             #$08
              bge             :space
              inc             :tabct
              lda             tabs,y
              beq             :space
              cmp             :ch
              blt             :space
              beq             :space
              sta             :ch
              jmp             :loop

:xit          stx             pos1
              rep             $30
              lda             :ch
              and             #$00FF
              cmp             #right
              blt             :s
              lda             #right-1
:s            sta             termch
              lda             termcv
              jsl             setch
              plp
              ply
              plx
              pla
              rts
              mx              %11

:docomment    phx
              ldx             #$07
:xloop        lda             tabs,x
              beq             :dext
              cmp             :ch
              blt             :space1
              beq             :space1
              sta             :ch
              sta             aval
              jmp             :cplx
:space1       plx
              phx
              beq             :cplx
              lda             linebuff,x
              and             #$7F
              cmp             #$20
              beq             :cplx1
              cmp             #$09
              bne             :dcinx
:cplx1        bit             :incflag
              bpl             :cplx
:dcinx        inc             :ch
              jmp             :cplx
:dext         dex
              bpl             :xloop
:cplx         plx

:normal       inx
              cpx             pos
              blt             :ok3
              beq             :ok3
              jmp             :xit
:ok3          lda             linebuff,x
              and             #$7F
              inc             :ch
              jmp             :normal

:ch           ds              2
:tabct        ds              2
:tabval       ds              2
:schar        ds              2
:litflag      ds              2
:incflag      ds              2

setpos        pha
              phx
              phy
              php
              sep             $30
              jsr             modify
              stz             :litflag
              stz             aval
              stz             aval+1
              lda             #$FF
              sta             pos
              ldy             #$00
              sty             :ch
              sty             :tabct
              lda             pos
              cmp             linebuff
              blt             :ldx
              ldx             linebuff
              beq             :stapos
              lda             linebuff,x
              and             #$7F
              cmp             #$0D
              bne             :stapos
              dex
:stapos       stx             pos

:ldx          ldx             pos
              lda             linebuff
              jeq             :xit
              ldx             #$07
              lda             #$00
]lup          ora             tabs,x
              dex
              bpl             ]lup
              ldx             #$00
              cmp             #$00
              jeq             :normal
              lda             linebuff+1
              and             #$7F
              cmp             #';'
              jeq             :docomment
              cmp             #'*'
              jeq             :normal
              cmp             #$0D
              jeq             :normal
:loop         stz             :incflag
              lda             :ch
              cmp             oldch
              blt             :i1
              jmp             :xit
:i1           inx
              cpx             pos
              blt             :lb
              beq             :lb
              jmp             :xit
:lb           cpx             linebuff
              blt             :ok
              beq             :ok
              jmp             :xit
:ok           lda             linebuff,x
              cmp             #$A0
              beq             :tab
              and             #$7F
              cmp             #';'
              beq             :comment
              cmp             #$09
              beq             :tab
              cmp             #$27
              beq             :literal
              cmp             #$22
              beq             :literal
:ora
:space
:incch        inc             :ch
              jmp             :loop
:literal      pha
              lda             #$80
              eor             :litflag
              sta             :litflag
              pla
              jmp             :ora
:comment      bit             :litflag
              bmi             :cjmp
              dex
              lda             linebuff,x
              and             #$7F
              cmp             #$20
              jeq             :docomment
              cmp             #$09
              jeq             :docomment
              inx
              lda             #';'
:cjmp         jmp             :ora
:tab          cpx             pos
              blt             :tab1
              bit             :litflag
              bmi             :tab1
              inx
              cpx             linebuff
              beq             :chkcomm
              bge             :tab2
:chkcomm      lda             linebuff,x
              dex
              and             #$7F
              cmp             #';'
              bne             :tab1
              sec
              ror             :incflag
              jmp             :docomment
:tab2         dex
:tab1         ldy             :tabct
              cpy             #$08
              bge             :space
              inc             :tabct
              lda             tabs,y
              beq             :space
              cmp             :ch
              blt             :space
              beq             :space
              sta             :ch
              jmp             :loop

:xit          stx             pos1
              stx             pos
              rep             $30
              lda             :ch
              and             #$00FF
              cmp             #right
              blt             :s
              lda             #right-1
:s            sta             termch
              lda             termcv
              jsl             setch
              plp
              ply
              plx
              pla
              rts
              mx              %11

:docomment    phx
              ldx             #$07
:xloop        lda             tabs,x
              beq             :dext
              cmp             :ch
              blt             :space1
              beq             :space1
              sta             :ch
              sta             aval
              jmp             :cplx
:space1       plx
              phx
              beq             :cplx
              lda             linebuff,x
              and             #$7F
              cmp             #$20
              beq             :cplx1
              cmp             #$09
              bne             :dcinx
:cplx1        bit             :incflag
              bpl             :cplx
:dcinx        inc             :ch
              jmp             :cplx
:dext         dex
              bpl             :xloop
:cplx         plx

:normal       lda             :ch
              cmp             oldch
              blt             :norm1
              jmp             :xit
:norm1        inx
              cpx             pos
              blt             :ok3
              beq             :ok3
              jmp             :xit
:ok3          lda             linebuff,x
              and             #$7F
              inc             :ch
              jmp             :normal

:ch           ds              2
:tabct        ds              2
:tabval       ds              2
:schar        ds              2
:litflag      ds              2
:incflag      ds              2

oldch         ds              2

tabs          dfb             12,18,30,0,0,0,0,0,0,0,0,0,0   ;no tabs >= right
tabs1         dfb             12,18,30,0,0,0,0,0,0,0,0,0,0   ;no tabs >= right
              asc             'TABS'
dtabs         dfb             12,18,30,0,0,0,0,0,0,0,0,0,0   ;no tabs >= right
tabstemp      ds              16,0

*------------------------------------------------------
getkey        php
              rep             $30
              stz             emod
              lda             termch
              tay
              jsl             pickchar
              sta             :char
              stz             :on
:loop         jsr             :invert
              lda             #$04
              sta             :ct1
:key2         lda             #$80
              sta             :ct
:key
              do              mouse
              jsr             mousekey                       ;optional mouse control
              fin

              bmi             :xit
              jsl             keyscan
              bpl             :dec
              cmp             #$89                           ;tab?
              bne             :xit
              lda             #$a0
              jmp             :xit
:dec          rep             $20
              dec             :ct
              bne             :key
              bit             emstarted
              bmi             :loop
              dec             :ct1
              bne             :key2
              jmp             :loop
:xit          pha
              lda             termch
              tay
              lda             :char
              jsl             storchar
              pla
              plp
              rts
:invert       bit             :on
              bpl             :block
              lda             termch
              tay
              lda             :char
              bit             selecting
              bmi             :s1
              jsl             storchar
:s1           stz             :on
              rts
:block        lda             cursor
              ora             #$80
              cmp             #"_"
              bne             :block1
              lda             termch
              tay
              lda             #"_"
              bit             selecting
              bmi             :s2
              jsl             storchar
:s2           sec
              ror             :on
              rts
:block1       bit             selecting
              bmi             :s3
              jsl             invert
:s3           sec
              ror             :on
              rts

:char         ds              2
:ct           ds              2
:on           ds              2
:ct1          ds              2

*------------------------------------------------------
initmouse
              do              mouse                          ;no mouse at this time!
              php
              rep             $30
              bit             emstarted
              bpl             :nomouse
              pea             $80
              pea             $80
              tll             $1e03
              plp
              rts
:nomouse      pea             $80
              pea             $80
              tll             $1e03
              plp
              rts

mousekey      php
              rep             $30
              stz             mousecr
              pha
              pha
              pha
              tll             $1703
              pla
              sta             mousestat
              pla
              sta             mouseypos
              pla
              sta             mousexpos
              jcs             :nomouse
:x            lda             mousexpos
              cmp             #$70
              blt             :left
              cmp             #$90
              bge             :right
              lda             mouseypos
              cmp             #$70
              blt             :up
              cmp             #$90
              bge             :down
              lda             mousestat
              bit             #$8000
              bne             :mdown0
* stz mouselast
              jmp             :nomouse
:mdown0       sep             $20
              ldal            $e0c030
              rep             $20
              lda             mouselast
              beq             :nomouse
              and             #$7f
              ora             #$80
              jmp             :keyxit
:left         lda             #$08+$80
              stz             mouselast
              jmp             :keyxit
:right        lda             #$15+$80
              stz             mouselast
              jmp             :keyxit
:up           lda             #$0b+$80
              sta             mouselast
              jmp             :keyxit
:down         lda             #$0a+$80
              sta             mouselast
              jmp             :keyxit
:keyxit       and             #$ff
              pha
              lda             mousestat
              bmi             :pla
* jsr initmouse
:pla          pla
:kx1          and             #$ff
              plp
              sep             $80
              rts
:nomouse
              pha
              lda             mousestat
              bmi             :pla1
* jsr initmouse
:pla1         pla
              plp
              rep             $80
              rts

mouseypos     ds              2
mousexpos     ds              2
mousestat     ds              2
mouselast     ds              2
mousecr       ds              2
mousecrchar   ds              2

              else
              rts                                            ;--- no mouse control ---
              fin
*------------------------------------------------------
showcv        php
              rep             $30
              lda             andflag
              pha
              lda             orflag
              pha
              stz             orflag
              lda             #$7f
              sta             andflag
              psl             #linenum
              pea             #$0000                         ;was 8000
              jsl             printdec
              pla
              sta             orflag
              pla
              sta             andflag
              plp
              rts

showch        php
              rep             $30
              lda             termch
              pha
              inc
              sta             termch
              lda             andflag
              pha
              lda             orflag
              pha
              stz             orflag
              lda             #$7f
              sta             andflag
:psl          psl             #termch
              pea             $0000
              jsl             printdec
              pla
              sta             orflag
              pla
              sta             andflag
              pla
              sta             termch
              plp
              rts

print         php
              phb
              phk
              plb
              sep             $30
              lda             termch
              sta             :ch
              lda             termcv
              sta             :cv
              lda             5,s                            ; get bank of data
              pha
              plb
              ldy             #$01                           ; add 1 to return address
              lda             (3,s),y
              sta             termch
              iny
              lda             (3,s),y
              sta             termcv
              iny
              sep             $30
              jsl             setch
              ldy             #$03
:loop         lda             (3,s),y                        ; get a character to print
              beq             :fix                           ; 0 = end of string
              phy
              ldy             termch
              pha
              and             #$7f
              cmp             #'N'&$1f
              beq             :normal
              cmp             #'O'&$1f
              bne             :pla
              stz             orflag
              lda             #$7f
              sta             andflag
              jmp             :pla1
:normal       lda             #$7f
              sta             andflag
              lda             #$80
              sta             orflag
:pla1         pla
              jmp             :ply
:pla          pla
              and             andflag
              ora             orflag
              cmp             #$40
              blt             :s
              cmp             #$60
              bge             :s
              sec
              sbc             #$40
:s            jsl             storchar                       ; print ascii character
              inc             termch
:ply          ply
              iny                                            ; y = y + 1
              bra             :loop                          ; next character

:fix          rep             $30
              tya
              sta             :len
              lda             3,s                            ; get low word of return address
              clc
              adc             :len                           ; add to length of string
              sta             3,s                            ; put back in place
              sep             $30
              lda             :cv
              sta             termcv
              lda             :ch
              sta             termch
              jsl             setch
              plb
              plp
              rtl

:len          hex             0000
:ch           ds              2
:cv           ds              2

*------------------------------------------------------
editscreen    php
              sep             $30
              stz             mych
              lda             #$17
              sta             mycv
              jsl             textbascalc
              ldy             #$00
]lup          lda             #' '
              jsr             textstore
              iny
              cpy             #80
              blt             ]lup

              jsr             drawtabs
              jsr             drawbottom
              jsr             drawcpos
              jsr             drawmem

              plp
              rts

drawbottom    php
              sep             $30
              lda             termch
              pha
              lda             termcv
              pha
              jsr             drawfname
              jsr             drawname
              jsr             drawcpos
              jsr             drawscroll
              pla
              sta             termcv
              pla
              sta             termch
              jsl             setch
              plp
              rts

drawscroll    rts                                            ;lda #$02
              sta             termcv
              jsl             setch
              ldy             #right
              lda             #$D2-$80
              jsl             storchar
]lup          lda             termcv
              inc
              cmp             #21
              bge             :end
              sta             termcv
              jsl             setch
              ldy             #right
              lda             #$D6-$80
              jsl             storchar
              jmp             ]lup
:end          sta             termcv
              jsl             setch
              lda             #$D1-$80
              ldy             #right
              jsl             storchar
              rts

showpath      rts                                            ;php
              sep             $30
              jsl             print
              hex             0000
              asc             "File:                  ",00
              stz             mycv
              lda             #$06
              sta             mych
              jsl             textbascalc
              rep             $30
              lda             getname
              and             #$00FF
              bne             :n
              psl             #:nonestr
              jmp             :d
:n            psl             #getname
:d            jsl             drawstr
              plp
              rts
:nonestr      str             'None'
              mx              %11


drawfname     rts                                            ;php
              sep             $30
              jsl             print
              hex             0000
              asc             "File:                  ",00
              stz             mycv
              lda             #$06
              sta             mych
              jsl             textbascalc
              rep             $30
              lda             efilename
              and             #$00FF
              bne             :n
              psl             #:nonestr
              jmp             :d
:n            psl             #efilename
:d            jsl             drawstr
              plp
              rts
:nonestr      str             'None'
              mx              %11

drawname      rts                                            ;php
              jsl             print
              hex             1e00
              asc             "***  QuickEDIT  ***",00
              plp
drawesc       rts                                            ;php
              jsl             print
              hex             3f00
              asc             "Escape: CDA Menu",00
              plp
              rts

drawesccan    rts                                            ;php
              sep             $30
              jsl             print
              hex             3c00
              asc             "       Escape: Edit",00
              plp
              rts

drawesccan1   rts                                            ;php
              sep             $30
              jsl             print
              hex             3c00
              asc             "     Escape: Cancel",00
              plp
              rts

drawcpos      php
              rep             $30
              lda             #$7f
              sta             andflag
              stz             orflag

              lda             dirty
              bne             :plus
              jsl             print
              hex             0017
              asc             " Line:",00
              jmp             :sep
:plus         jsl             print
              hex             0017
              asc             "+Line:",00
:sep
              sep             $20
              lda             #$06
              sta             mych
              lda             #23
              sta             mycv
              rep             $20
              jsl             textbascalc
              jsr             showcv
              sep             $20
              lda             mych
              sta             :ch
              lda             mycv
              sta             :ch+1
              rep             $20
              jsl             print
:ch           hex             0000
              asc             "  Col:",00
              lda             :ch
              clc
              adc             #06
              sta             mych
              jsl             textbascalc
              jsr             showch
              lda             #' '
              jsl             drawchar
              lda             #' '
              jsl             drawchar
              lda             #' '
              jsl             drawchar

              do              0
              lda             selecting
              jsl             tprbytel
              lda             #' '
              jsl             drawchar
              lda             selectflag
              jsl             prbyte
              lda             #' '
              jsl             drawchar
              lda             selstart
              jsl             tprbytel
              lda             #' '
              jsl             drawchar
              lda             selend
              jsl             tprbytel

              lda             #' '
              jsl             drawchar
              lda             flen
              jsl             tprbytel

              lda             #' '
              jsl             drawchar
              lda             #' '
              jsl             drawchar
              lda             #' '
              jsl             drawchar
              fin

              lda             #$80
              sta             orflag
              plp
              rts

drawmem       php
              rep             $30
              stz             orflag
              lda             #$0000
              sec
              sbc             flen
              sta             :size
              lda             #$01
              sbc             #$00
              sta             :size+2
              lup             10
              lsr             :size+$2
              ror             :size
              --^
              psl             :size
              psl             #:str
              pea             $04
              pea             $00
              tll             $270B
              sep             $30
              ldy             #$00
]lup          lda             :str,y
              ora             #$80
              sta             :str,y
              iny
              cpy             #$07
              blt             ]lup

              jsl             print
              hex             4317
:str          ds              4,0
              asc             "K Avail.",00
              lda             #$80
              sta             orflag
              plp
              rts
:size         ds              4

drawtabs      php
              sep             $30
              lda             termch
              pha
              lda             termcv
              pha
              stz             termch
              lda             #$16                           ;#$01
              sta             termcv
              jsl             setch
              ldy             #$00
              lda             #'-'
              jsl             storchar
              ldy             #$01
]lup          sty             :ct
              ldx             #$00
:which        lda             tabs,x
              beq             :inx
              cmp             :ct
              beq             :yes
:inx          inx
              cpx             #$08
              blt             :which
              lda             #'-'
              jmp             :ldy
:yes          lda             #'|'
:ldy          ldy             :ct
              jsl             storchar
              ldy             :ct
              iny
              cpy             #right
              blt             ]lup
              ldy             #right-1
              lda             #'-'
              jsl             storchar
              pla
              sta             termcv
              pla
              sta             termch
              jsl             setch
              plp
              rts
:ct           ds              2
              mx              %00

              do              debug
showinfo      php
              rep             $30
              sep             $20
              stz             mych
              lda             #23
              sta             mycv
              rep             $20
              jsl             textbascalc
              lda             flen
              jsl             tprbytel
              lda             #' '
              jsl             drawchar
              lda             linebuff
              and             #$00FF
              jsl             prbyte
              lda             oldlen
              jsl             prbyte
              lda             #' '
              jsl             drawchar
              lda             position
              jsl             tprbytel
              lda             #' '
              jsl             drawchar
              lda             pos
              jsl             prbyte
              lda             pos1
              jsl             prbyte

              lda             #' '
              jsl             drawchar

              lda             aval
              jsl             tprbytel
* lda xval
* jsl tprbytel
* lda yval
* jsl tprbytel

              jsl             setch
              plp
              rts
              fin

***** RAM based TEXT driver for editor *****
* (faster than GS text tools...but still compatible with them!)

textdriver
              jmp             textinit                       ;needed entry vectors
              jmp             textread
              jmp             textwrite
              jmp             textstatus
              jmp             textcontrol

textinit      php
              phb
              phd
              phk
              plb
              rep             $30
              lda             editdp
              tcd
              stz             mych
              stz             mycv
              lda             mycv
              asl
              tax
              lda             scrtbl,x
              sta             base
              jsl             clrscreen
              pld
              plb
              plp
              rtl

textwrite     php
              phb
              phd
              phk
              plb
              rep             $30
              lda             editdp
              tcd
              sep             $20
              sta             :char
              and             #$7F
              cmp             #$20
              bge             :normal
              jmp             :control
:normal       lda             mych
              and             #$00FF
              tay
              lda             :char
              and             andflag
              ora             orflag
              jsr             textstore
              inc             mych
              lda             mych
              cmp             #80
              blt             :r
              stz             mych
              inc             mycv
              lda             mycv
              cmp             #24
              blt             :r
              lda             #23
              sta             mycv
              rep             $30
              jsl             scroll
              lda             mycv
              asl
              tax
              lda             scrtbl,x
              sta             base
:r            pld
              plb
              plp
              rtl

              mx              %10
:control      cmp             #$0D
              beq             :cr
              jmp             :r
:cr
              stz             mych
              sep             $20
              inc             mycv
              lda             mycv
              cmp             #24
              blt             :crn
              lda             #23
              sta             mycv
              rep             $30
              jsl             scroll
:crn          rep             $30
              lda             mycv
              and             #$00FF
              asl
              tax
              lda             scrtbl,x
              sta             base
              jmp             :r
:char         ds              2
:basl         ds              2

andflag       dw              $7f
orflag        dw              $80

textread      rtl
textcontrol   rtl
textstatus    php
              rep             $30
              lda             #$00
              plp
              clc
              rtl

textstore     phy
              php
              phb
              rep             $30
              sty             :y
              sei
              ldy             basl
              phy
              ldy             base
              sty             basl
              sep             $30
              ldy             :y
              pea             $0000
              plb
              plb
              pha                                            ;save the character
              tya                                            ;get character position
              lsr                                            ;divide by 2
              tay                                            ;restore screen pos
              bcs             :storeit                       ;if so, then ok
              pea             $0101
              plb
              plb
:storeit      pla                                            ;get char to store
              cmp             #$40
              blt             :ok
              cmp             #$60
              bge             :ok
              sec
              sbc             #$40
:ok           sta             (basl),y                       ;put char on screen
              rep             $30
              ply
              sty             basl
              plb
              plp
              ply
              rts                                            ;return

:y            ds              2

textbascalc
              phx
              php
              rep             $30
              lda             mycv
              and             #$00FF
              asl
              tax
              lda             scrtbl,x
              sta             base
              plp
              plx
              rtl

*-----------------------------------------------*
* Name     : BASCALC                            *
* Function : CALC BASE ADDR FOR SCREEN LINE     *
* Input    : AC=CV                              *
* Output   : BASL/BASH                          *
* Volatile : NOTHING                            *
* Calls    : NONE                               *
*-----------------------------------------------*

bascalc
              pha
              phx
              php
              rep             $30
              and             #$00FF
              asl
              tax                                            ;get index for line #
              lda             scrtbl,x                       ;get l.o. byte
              sta             basl                           ;store in basl
              plp                                            ;restore interupts
              plx
              pla                                            ;restore a-reg
              rtl                                            ;return to caller
              mx              %11

*-----------------------------------------------*
* Name     : STORCHAR                           *
* Function : STORE A CHAR ON SCREEN             *
* Input    : AC=CHAR                            *
*             Y=CH POS                          *
* Output   : CHAR ON SCREEN                     *
* Volatile : NOTHING                            *
* Calls    : NONE                               *
*-----------------------------------------------*

storchar
              phb
              phx
              phy
              php
              sep             $30
              pea             $0000
              plb
              plb
              pha                                            ;save the character
              tya                                            ;get character position
              lsr                                            ;divide by 2
              tay                                            ;restore screen pos
              bcs             :storeit                       ;if so, then ok
              pea             $0101
              plb
              plb
:storeit      pla                                            ;get char to store
* andl andflag
* oral orflag
              sta             (basl),y                       ;put char on screen
              plp
              ply
              plx
              plb
              rtl                                            ;return

storchar1
              phb
              phx
              phy
              php
              sep             $30
              pea             $0000
              plb
              plb
              pha                                            ;save the character
              tya                                            ;get character position
              lsr                                            ;divide by 2
              tay                                            ;restore screen pos
              bcs             :storeit                       ;if so, then ok
              pea             $0101
              plb
              plb
:storeit      pla                                            ;get char to store
              cmp             #$4d+$80
              beq             :sta2
              cmp             #$46+$80
              beq             :sta2
              cmp             #$40
              blt             :sta1
              cmp             #$5f+1
              bge             :sta1
:sec          sec
              sbc             #$40
              bra             :sta1
:sta2         and             #$7f
              bra             :sta
:sta1         ora             selectflag
:sta          sta             (basl),y                       ;put char on screen
              plp
              ply
              plx
              plb
              rtl                                            ;return

*-----------------------------------------------*
* Name     : PICKCHAR                           *
* Function : GET A CHAR FROM SCREEN             *
* Input    : Y=CH POSITION                      *
* Output   : AC=CHAR                            *
* Volatile : NOTHING                            *
* Calls    : NONE                               *
*-----------------------------------------------*

pickchar
              phx
              phy
              php
              phb
              sep             $30
              pea             $0000
              plb
              plb
              tya                                            ;get character position
              lsr                                            ;divide by 2
              tay                                            ;restore screen pos
              bcs             :pickit                        ;if so, then ok
              pea             $0101
              plb
              plb
:pickit       lda             (basl),y                       ;put char on screen
              plb
              plp
              ply
              plx
              rtl                                            ;return

*-----------------------------------------------*
* Name     : SETCH                              *
* Function : MOVE CURSOR TO CH/CV               *
* Input    : CH/CV                              *
* Output   : CURSOR POSITION                    *
* Volatile : NOTHING                            *
* Calls    : NONE                               *
*-----------------------------------------------*

setch
              pha                                            ;save the a-reg
              php
              sep             $30
              lda             termch                         ;get our ch value
              stal            $57B                           ;store in 80 col ch
              stal            $24
:chcont       lda             termcv                         ;get our cv value
              stal            $25                            ;store in monitor cv
              stal            $5FB                           ;store in 80 col cv
              jsl             bascalc                        ;calculate base address
              plp
              pla                                            ;restore a-reg
              rtl                                            ;return

*-----------------------------------------------*
* Name     : INVERT                             *
* Function : INVERT THE CHAR AT CH/CV           *
* Input    : NOTHING                            *
* Output   : CHAR AT CH/CV INVERTED             *
* Volatile : NOTHING                            *
* Calls    : PICKCHAR, STORCHAR                 *
*-----------------------------------------------*

invert
              phb
              pha                                            ;save the a-reg
              phy                                            ;save the y-reg
              phx
              php
              sep             $30
              pea             $0000
              plb
              plb
              lda             termch
              tay
              jsl             pickchar                       ;get char at cursor
              cmp             #$46
              beq             :cr1
              cmp             #$4D
              beq             :cr
              cmp             #$80
              bge             :inv
              cmp             #$20
              bge             :normal
              clc
              adc             #$40
:normal       ora             #$80                           ;convert to normal char
              bne             :stuffit
:inv          and             #$7F                           ;convert to inverse char
              cmp             #$60
              bge             :stuffit
              cmp             #$40
              blt             :stuffit
              sec
              sbc             #$40
:stuffit      jsl             storchar                       ;put it back
              plp
              plx
              ply                                            ;get y value
              pla                                            ;restore a-reg
              plb
              rtl                                            ;return

:cr           lda             #$46
              bra             :stuffit
:cr1          lda             #$4D
              bra             :stuffit

*======================================================
scroll                                                       ;fast scroll routine
              phy
              php
              phb
              rep             $30
              ldy             #$26                           ;get ready for each column
:start        pea             $0101
              plb
              plb
              lda             $480,y
              sta             $400,y
              lda             $500,y
              sta             $480,y
              lda             $580,Y                         ;scroll one column
              sta             $500,Y
              lda             $600,Y
              sta             $580,Y
              lda             $680,Y
              sta             $600,Y
              lda             $700,Y
              sta             $680,Y
              lda             $780,Y
              sta             $700,Y
              lda             $428,Y
              sta             $780,Y
              lda             $4A8,Y
              sta             $428,Y
              lda             $528,Y
              sta             $4A8,Y
              lda             $5A8,Y
              sta             $528,Y
              lda             $628,Y
              sta             $5A8,Y
              lda             $6A8,Y
              sta             $628,Y
              lda             $728,Y
              sta             $6A8,Y
              lda             $7A8,Y
              sta             $728,Y
              lda             $450,Y
              sta             $7A8,Y
              lda             $4D0,Y
              sta             $450,Y
              lda             $550,Y
              sta             $4D0,Y
              lda             $5D0,Y
              sta             $550,Y
              lda             $650,Y
              sta             $5D0,Y
              lda             $6D0,Y
              sta             $650,Y
              lda             selecting
              bmi             :inv1
              pea             #$A0A0
              pla
              bra             :sta1
:inv1         pea             #$2020
              pla
:sta1         sta             $6D0,Y
              pea             $0000
              plb
              plb
:lda2
              lda             $480,y
              sta             $400,y
              lda             $500,y
              sta             $480,y
              lda             $580,Y                         ;scroll an odd column
              sta             $500,Y
              lda             $600,Y
              sta             $580,Y
              lda             $680,Y
              sta             $600,Y
              lda             $700,Y
              sta             $680,Y
              lda             $780,Y
              sta             $700,Y
              lda             $428,Y
              sta             $780,Y
              lda             $4A8,Y
              sta             $428,Y
              lda             $528,Y
              sta             $4A8,Y
              lda             $5A8,Y
              sta             $528,Y
              lda             $628,Y
              sta             $5A8,Y
              lda             $6A8,Y
              sta             $628,Y
              lda             $728,Y
              sta             $6A8,Y
              lda             $7A8,Y
              sta             $728,Y
              lda             $450,Y
              sta             $7A8,Y
              lda             $4D0,Y
              sta             $450,Y
              lda             $550,Y
              sta             $4D0,Y
              lda             $5D0,Y
              sta             $550,Y
              lda             $650,Y
              sta             $5D0,Y
              lda             $6D0,Y
              sta             $650,Y
              lda             $750,Y
              lda             selecting
              bmi             :inv2
              pea             #$A0A0
              pla
              bra             :sta2
:inv2         pea             #$2020
              pla
:sta2         sta             $6D0,Y
              dey                                            ;decrement index
              dey
              bmi             :exit                          ;if not done with screen..
              brl             :start                         ;continue
:exit         plb
              plp                                            ;restore flags
              ply
              rtl                                            ;and return

*------------------------------------------------------
bscroll                                                      ;fast back scroll routine
              phy
              php
              phb
              rep             $30
              ldy             #$26                           ;get ready for each column
:start        pea             $0101
              plb
              plb
              lda             $650,Y                         ;scroll one column
              sta             $6D0,Y
              lda             $5D0,Y
              sta             $650,Y
              lda             $550,Y
              sta             $5D0,Y
              lda             $4D0,Y
              sta             $550,Y
              lda             $450,Y
              sta             $4D0,Y
              lda             $7A8,Y
              sta             $450,Y
              lda             $728,Y
              sta             $7A8,Y
              lda             $6A8,Y
              sta             $728,Y
              lda             $628,Y
              sta             $6A8,Y
              lda             $5A8,Y
              sta             $628,Y
              lda             $528,Y
              sta             $5A8,Y
              lda             $4A8,Y
              sta             $528,Y
              lda             $428,Y
              sta             $4A8,Y
              lda             $780,Y
              sta             $428,Y
              lda             $700,Y
              sta             $780,Y
              lda             $680,Y
              sta             $700,Y
              lda             $600,Y
              sta             $680,Y
              lda             $580,Y
              sta             $600,Y
              lda             $500,Y
              sta             $580,Y
              lda             $480,Y
              sta             $500,y
              lda             $400,y
              sta             $480,y
              lda             selecting
              bmi             :inv1
              pea             #$A0A0
              pla
              bra             :sta1
:inv1         pea             #$2020
              pla
:sta1         sta             $400,Y
              pea             $0000
              plb
              plb
:lda2
              lda             $650,Y                         ;scroll one column
              sta             $6D0,Y
              lda             $5D0,Y
              sta             $650,Y
              lda             $550,Y
              sta             $5D0,Y
              lda             $4D0,Y
              sta             $550,Y
              lda             $450,Y
              sta             $4D0,Y
              lda             $7A8,Y
              sta             $450,Y
              lda             $728,Y
              sta             $7A8,Y
              lda             $6A8,Y
              sta             $728,Y
              lda             $628,Y
              sta             $6A8,Y
              lda             $5A8,Y
              sta             $628,Y
              lda             $528,Y
              sta             $5A8,Y
              lda             $4A8,Y
              sta             $528,Y
              lda             $428,Y
              sta             $4A8,Y
              lda             $780,Y
              sta             $428,Y
              lda             $700,Y
              sta             $780,Y
              lda             $680,Y
              sta             $700,Y
              lda             $600,Y
              sta             $680,Y
              lda             $580,Y
              sta             $600,Y
              lda             $500,Y
              sta             $580,Y
              lda             $480,Y
              sta             $500,y
              lda             $400,y
              sta             $480,y
              lda             selecting
              bmi             :inv2
              pea             #$A0A0
              pla
              bra             :sta2
:inv2         pea             #$2020
              pla
:sta2         sta             $400,Y
              dey                                            ;decrement index
              dey
              bmi             :exit                          ;if not done with screen..
              brl             :start                         ;continue
:exit         plb
              plp                                            ;restore flags
              ply
              rtl                                            ;and return

*======================================================
clrscreen
              phy
              php
              phb
              rep             $30
              ldy             #$26                           ;get ready for each column
:start        pea             $0101
              plb
              plb
              lda             #$A0A0
              sta             $7D0,Y
              sta             $750,Y
              sta             $6D0,Y
              sta             $650,Y
              sta             $5D0,Y
              sta             $550,Y
              sta             $4D0,Y
              sta             $450,Y
              sta             $7A8,Y
              sta             $728,Y
              sta             $6A8,Y
              sta             $628,Y
              sta             $5A8,Y
              sta             $528,Y
              sta             $4A8,Y
              sta             $428,Y
              sta             $780,Y
              sta             $700,Y
              sta             $680,Y
              sta             $600,Y
              sta             $580,Y
              sta             $500,Y
              sta             $480,Y
              sta             $400,Y                         ;clear it
              pea             #$0000
              plb
              plb
              sta             $7D0,Y
              sta             $750,Y
              sta             $6D0,Y
              sta             $650,Y
              sta             $5D0,Y
              sta             $550,Y
              sta             $4D0,Y
              sta             $450,Y
              sta             $7A8,Y
              sta             $728,Y
              sta             $6A8,Y
              sta             $628,Y
              sta             $5A8,Y
              sta             $528,Y
              sta             $4A8,Y
              sta             $428,Y
              sta             $780,Y
              sta             $700,Y
              sta             $680,Y
              sta             $600,Y
              sta             $580,Y
              sta             $500,Y
              sta             $480,Y
              sta             $400,Y                         ;clear it
              dey                                            ;decrement index
              dey
              bmi             :exit                          ;if not done with screen..
              brl             :start                         ;continue
:exit         plb
              plp                                            ;restore flags
              ply
              rtl                                            ;and return

              put             edit.apw
              put             edit.types

*======================================================
* Variable storage

rtl           rtl
asm           rtl

cursor        dw              "_"

              dum             *                              ;reseved space in linker!

automode      ds              2
asmpath       ds              256

glabstr       ds              30

editdp        ds              2

findstr       ds              32
replacestr    ds              32

linebuff      ds              275

boxbuff       ds              20*60                          ;20 lines by 60 chars

              dend

              ent             cursor
              ent             linenum

              sav             obj/edit.l

