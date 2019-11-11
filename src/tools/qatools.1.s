storchar        php
                phd                                         ;save everything
                rep             $30
                phx
                phy
                pha
                pha
                tsc
                inc
                tcd                                         ;make 4 bytes of DP
                lda             basl
                sta             0                           ;save our offset
                sep             $30
                cpy             #80
                bge             :bad
                ldx             #^mainbank
                tya
                lsr
                tay
                bcs             :bank0
                ldx             #^auxbank
:bank0          lda             2                           ;get the char back
                stx             2                           ;save the bank byte
                sta             [0],y                       ;
:bad            rep             $30
                lda             2
                plx                                         ;remove the ptr
                plx
                ply
                plx
                pld                                         ;restore the DP
                plp                                         ;and P
                rts

*======================================================
* Get a character from screen at location in Y reg from left margin

pickchar        php
                phd                                         ;save everything
                rep             $30
                phx
                phy
                pha
                pha
                tsc
                inc
                tcd                                         ;make 4 bytes of DP
                lda             basl
                sta             0                           ;save our offset
                sep             $30
                cpy             #80
                bge             :bad
                ldx             #^mainbank
                tya
                lsr
                tay
                bcs             :bank0
                ldx             #^auxbank
:bank0          stx             2                           ;save the bank byte
                lda             [0],y                       ;
:bad            rep             $30
                and             #$FF
                plx                                         ;remove the ptr
                plx
                ply                                         ;restore the registers
                plx
                pld                                         ;restore the DP
                plp                                         ;and P
                rts

clearwindow
                bit             fullwindow
                jmi             :port
                lda             #$A0A0
                ldx             #40-2
]lup            stal            $400+mainbank,x
                stal            $400+auxbank,x
                stal            $480+mainbank,x
                stal            $480+auxbank,x
                stal            $500+mainbank,x
                stal            $500+auxbank,x
                stal            $580+mainbank,x
                stal            $580+auxbank,x
                stal            $600+mainbank,x
                stal            $600+auxbank,x
                stal            $680+mainbank,x
                stal            $680+auxbank,x
                stal            $700+mainbank,x
                stal            $700+auxbank,x
                stal            $780+mainbank,x
                stal            $780+auxbank,x
                stal            $428+mainbank,x
                stal            $428+auxbank,x
                stal            $4a8+mainbank,x
                stal            $4a8+auxbank,x
                stal            $528+mainbank,x
                stal            $528+auxbank,x
                stal            $5a8+mainbank,x
                stal            $5a8+auxbank,x
                stal            $628+mainbank,x
                stal            $628+auxbank,x
                stal            $6a8+mainbank,x
                stal            $6a8+auxbank,x
                stal            $728+mainbank,x
                stal            $728+auxbank,x
                stal            $7a8+mainbank,x
                stal            $7a8+auxbank,x
                stal            $450+mainbank,x
                stal            $450+auxbank,x
                stal            $4d0+mainbank,x
                stal            $4d0+auxbank,x
                stal            $550+mainbank,x
                stal            $550+auxbank,x
                stal            $5d0+mainbank,x
                stal            $5d0+auxbank,x
                stal            $650+mainbank,x
                stal            $650+auxbank,x
                stal            $6d0+mainbank,x
                stal            $6d0+auxbank,x
                stal            $750+mainbank,x
                stal            $750+auxbank,x
                stal            $7d0+mainbank,x
                stal            $7d0+auxbank,x
                dex
                dex
                jpl             ]lup
                rts

:port           phd                                         ;save the DP
                pha                                         ;make some room on the stack
                pha
                tsc                                         ;to use as DP
                inc
                tcd
                lda             wintop                      ;get the topline
                sta             :ct                         ;save it as a counter
                lda             winwidth                    ;get the right margin
                beq             :done
                cmp             #80+1                       ;too big?
                blt             :1
                lda             #80                         ;force to right side
:1              sta             :width
]lup            rep             $30
                lda             :ct                         ;what line are we on?
                cmp             winbot
                blt             :ok                         ;done yet?
                bne             :done
:ok             asl
                tax
                lda             table,x                     ;get the base offset
                clc
                adc             winleft                     ;add with left margin
                sta             0                           ;and save in our temp DP
                sep             $30                         ;8 bit now for speed
                ldy             #0                          ;start at 0
                lda             #' '                        ;space char
]lup1           ldx             #^mainbank                  ;default to bank1
                xba
                tya
                lsr
                bcs             :bank0
                ldx             #^auxbank
:bank0          stx             2                           ;save in bank byte of ptr
                xba
                sta             [0],y
                iny
                cpy             :width
                blt             ]lup
                inc             :ct
                bra             ]lup
:done           rep             $30
                pla
                pla                                         ;pull off ptr from stack
                pld                                         ;retore dp
                rts

:ct             ds              2
:width          ds              2


scrollup                                                    ;ent ;fast scroll routine
                php
                phb
                rep             $30
                phy
                ldy             #40-2                       ;get ready for each column
:start          pea             $0101
                plb
                plb
                lda             $480,y
                sta             $400,y
                lda             $500,y
                sta             $480,y
                lda             $580,Y                      ;scroll one column
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
                sta             $6D0,Y
                lda             $7D0,y
                sta             $750,y
                lda             #$A0A0
                sta             $7D0,Y

                pea             $0000
                plb
                plb
:lda2
                lda             $480,y
                sta             $400,y
                lda             $500,y
                sta             $480,y
                lda             $580,Y                      ;scroll an odd column
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
                sta             $6D0,Y
                lda             $7D0,y
                sta             $750,y
                lda             #$A0A0
                sta             $7D0,Y
                dey                                         ;decrement index
                dey
                bmi             :exit                       ;if not done with screen..
                brl             :start                      ;continue
:exit           ply
                plb
                plp                                         ;restore flags
                rts                                         ;and return

table           dw              $400
                dw              $480
                dw              $500
                dw              $580
                dw              $600
                dw              $680
                dw              $700
                dw              $780
                dw              $428
                dw              $4a8
                dw              $528
                dw              $5a8
                dw              $628
                dw              $6a8
                dw              $728
                dw              $7a8
                dw              $450
                dw              $4d0
                dw              $550
                dw              $5d0
                dw              $650
                dw              $6d0
                dw              $750
                dw              $7d0

*======================================================
printchar
                php
                sep             $30
                and             #$7f
                xba
                lda             charflag+1
                and             #%1110_0000
                beq             :print
                cmp             #%1110_0000
                beq             :print
                brl             :multiple
:print
                lda             charflag+1                  ;printing time/version/justify
                and             #%000_0111
                beq             :p1
                brl             printTVJ                    ; yes- handle it!
:p1
                lda             charflag
                and             #%111
                bne             :gotoxy
                xba
                cmp             #' '
                jlt             :control
                bit             charflag
                bvs             :mouse
                bmi             :ora
                cmp             #'A'                        ;inverse starts here
                blt             :jsr
                cmp             #'Z'+1
                bge             :jsr
                sec
                sbc             #$40                        ;convert to inverse uppercase
                bra             :jsr
:ora            ora             #$80
                bra             :jsr
:mouse          and             #$1f
                ora             #$40                        ;convert to mouse text
:jsr            xba
                lda             cursx
                clc
                adc             winleft
                cmp             #80
                bge             :cr
                tay
                xba
                jsr             storchar
                inc             cursx
                lda             cursx
                cmp             winwidth
                blt             :xit

:cr
                stz             cursx
:lf             inc             cursy
                lda             cursy
                cmp             winbot
                blt             :update
                beq             :update
                jsr             scrollup
                lda             winbot
                sta             cursy
:update         rep             $30
                and             #$7f
                asl
                tay
                lda             table,y
                sta             basl
                sep             $30
:xit            plp
                rts

                mx              %11
:gotoxy         bit             #%100
                bne             :tabx
                and             #$03
                cmp             #$01
                beq             :x
:y              xba
:y1
                sec
                sbc             #32                         ;subtract out space
                sta             cursy
                lda             :xtemp
                sec
                sbc             #32                         ; because zero is EOB
                sta             cursx
                lda             #$07
                trb             charflag
                jsr             setcurs
                brl             :xit
:x              lda             #$03
                tsb             charflag
                xba
:x1             sta             :xtemp
                brl             :xit
:tabx           xba
                sta             cursx
                lda             #$7
                trb             charflag
                jsr             setcurs
                brl             :xit

:xtemp          ds              2

:control        rep             $30
                and             #$1f
                pha
                cmp             #$0d
                beq             :cr2
                cmp             #$0a
                beq             :lf2
                stz             outflag
:c1             pla
                asl
                tax
                jsr             (:tbl,x)
                plp
                rts

:cr2            lda             #$80
                tsb             outflag
                bra             :c1
:lf2            lda             #$40
                tsb             outflag
                bra             :c1

                mx              %11
:multiple       cmp             #%1000_0000
                beq             :m2
:m3             xba
                sta             :outchar
                lda             #%1110_0000
                tsb             charflag+1
:ml             lda             :outcount
                beq             :moff
                lda             :outchar
                jsr             printchar
                dec             :outcount
                bra             :ml
:moff           lda             #%1110_0000
                trb             charflag+1
                stz             :outcount
                stz             :outchar
                brl             :xit
:m2             xba
                sta             :outcount
                lda             #%1100_0000
                tsb             charflag+1
                brl             :xit

:outcount       ds              2
:outchar        ds              2

:tbl            da              nil                         ;0
                da              savex                       ;^A
                da              savey                       ;^B
                da              restorex                    ;^C
                da              restorey                    ;^D
                da              nil                         ;^E
                da              nil                         ;^F
                da              bell                        ;^G
                da              backspace                   ;^H
                da              tab2                        ;^I
                da              linefeed                    ;^J
                da              clreos                      ;^K
                da              formfeed                    ;^L
                da              textcr                      ;^M
                da              normal                      ;^N
                da              inverse                     ;^0
                da              savexy                      ;^P
                da              nil                         ;^Q
                da              nil                         ;^R
                da              nil                         ;^S
                da              restorexy                   ;^T
                da              printmult                   ;^U
                da              scrollup                    ;^V
                da              nil                         ;^W
                da              mouseoff                    ;^X
                da              home                        ;^Y
                da              clrline                     ;^Z
                da              mouseon                     ;^[ $1B
                da              nil                         ;^\ $1C
                da              clreoln                     ;^] $1D
                da              gotoxy                      ;^^ $1E
                da              upone                       ;^_ $1F

upone           php
                rep             $30
                lda             cursy
                beq             :plp
                dec
                sta             cursy
                jsr             setcurs
:plp            plp
                rts

backspace       php
                rep             $30
                lda             cursx
                beq             :plp
                dec
                sta             cursx
                jsr             setcurs
:plp            plp
                rts

bell            php
                rep             $30
                tll             $2c03
                plp
                rts

*======================================================
* Return the quit/launch information we have obtained

QAGetLaunch
                dum             $00
]rtl            ds              6                           ;these are passed on stack
]newstack       =               *-6                         ;must be at end of passed params
]flags          ds              2
]pathptr        ds              4
                dend

                mx              %00
                tsc
                sec
                sbc             #]rtl
                tcs
                phd
                inc
                tcd
                phb
                phk
                plb
                lda             #launchpath
                sta             ]pathptr
                lda             #^launchpath
                sta             ]pathptr+2
                lda             launchflags
                sta             ]flags
                lda             #0
:xit            rep             $30
                tax
                lda             ]rtl+4
                sta             ]newstack+4
                lda             ]rtl+2
                sta             ]newstack+2
                lda             ]rtl
                sta             ]newstack
                plb
                pld
                tsc
                clc
                adc             #]newstack
                tcs
                txa
                brl             errxit

*======================================================
* Tell the controlling program how we wish to exit...

QASetLaunch
                dum             $00
]rtl            ds              6                           ;these are passed on stack
]flags          ds              2
]pathptr        ds              4
]newstack       =               *-6                         ;must be at end of passed params
                dend

                mx              %00
                tsc
                sec
                sbc             #]rtl
                tcs
                phd
                inc
                tcd
                phb
                phk
                plb
                lda             ]flags
                sta             launchflags
                lda             []pathptr]
                and             #$ff
                tay
                sep             $20
]lup            lda             []pathptr],y
                sta             launchpath,y
                dey
                bpl             ]lup
                rep             $20
                lda             #0
:xit            rep             $30
                tax
                lda             ]rtl+4
                sta             ]newstack+4
                lda             ]rtl+2
                sta             ]newstack+2
                lda             ]rtl
                sta             ]newstack
                plb
                pld
                tsc
                clc
                adc             #]newstack
                tcs
                txa
                brl             errxit

mygetline
                dum             $00
]rtl            ds              6                           ;these are passed on stack
]abortptr       ds              4
]cursor         ds              2
]cursors        ds              2
]startpos       ds              2
]maxlen         ds              2
]prompt         ds              4
]lineptr        ds              4
]newstack       =               *-6                         ;must be at end of passed params
]cursout        ds              2
]endpos         ds              2
]endkey         ds              2
                dend

                mx              %00
                lda             ]cursor
                sep             $20
                sta             cursor
                xba
                sta             fillchar
                rep             $20
                lda             ]cursors
                sep             $20
                sta             insert
                xba
                sta             overstrike
                rep             $20
                stz             curpos
                lda             ]maxlen
                cmp             #80
                blt             :max
                lda             #80
:max            sta             ]maxlen
                lda             cursx
                sta             startx
                lda             []prompt]
                and             #$FF
                clc
                adc             cursx
                sta             startpos                    ;save starting position
restore         rep             $30
                lda             []lineptr]                  ;get length
                and             #$FF
                tay                                         ;length in Y
                sep             $20
                sta             tempbuff
                lda             ]startpos
                cmp             tempbuff
                blt             :scp
                lda             tempbuff
:scp            sta             curpos                      ;save current position
                lda             tempbuff
                beq             prtnew
:1              lda             []lineptr],y                ;get a character
                sta             tempbuff,y                  ;copy bytes over
                dey
                bne             :1                          ;copy the string over
prtnew          rep             $30
                lda             startx
                sta             cursx
                ldx             ]prompt+2
                lda             ]prompt
                jsl             pstr
                lda             startpos
                sta             cursx                       ;move cursor over again
                ldx             #^tempbuff
                lda             #tempbuff                   ;get my buffer
                jsl             pstr
                sep             $20
                lda             ]maxlen
                sec
                sbc             tempbuff                    ;get remaining length
                rep             $20
                and             #$FF
                tax                                         ;amount of spaces
                sep             $20                         ;use short
                bcc             :spconly
                beq             :spconly
:9              ldy             cursx
:91             lda             fillchar                    ;get fill char
                phy
                phx
                jsr             storchar                    ;add the fill character
                plx
                ply
                iny
                dex
                bne             :91
:spconly        lda             #" "                        ;add space at the end
                ldy             cursx
                jsr             storchar
*-------------------------------------------------
newpos          rep             $30
                lda             curpos
                clc
                adc             startpos                    ;add starting x-pos
                sta             cursx                       ;position cursor
newkey          rep             $30
                jsr             getkey
                and             #%11010000_11111111
                cmp             #$FF                        ;char?
                bge             :find
                cmp             #" "                        ;space?
                bge             tochar                      ;its a character!
:find           ldx             i_Cmds                      ;get # cmds *2
:cmdloop        cmp             cmds,x                      ;found it yet?
                beq             gotcmd                      ;yep-->handle command
                dex
                dex
                bpl             :cmdloop                    ;keep trying

* Check the 'Abort' list:

                pha                                         ;save character
                lda             []abortptr]                 ;get # abort chars
                beq             :noabrt
                asl                                         ;x2
                tay
                pla
:lp             cmp             []abortptr],y
                beq             iabort                      ;abort the mission
                dey
                dey
                bne             :lp
                pha
:noabrt         pla                                         ;restore keypress

* See if 'regular' character:

                and             #%00_000000_11111111
                cmp             #$8D                        ;enter?
                beq             irtn
                cmp             #" "
                blt             badchar                     ;no more cntrl chars
                cmp             #"@"                        ;regular keypad?
                bge             badchar
tochar          brl             char                        ;take the character
badchar         rep             $30
                bra             newkey
gotcmd          jmp             (cmdadrs,x)                 ;jump to the command

* Commands:

*-------------------------------------------------
oar             brl             restore                     ;restore old value
*-------------------------------------------------
irtn            sta             ]endkey
                lda             curpos
                sta             ]endpos
                lda             cursor
                and             #$ff
                sta             ]cursout
                lda             tempbuff
                and             #$FF
                cmp             ]maxlen
                blt             :tay0
                lda             ]maxlen
:tay0           tay
                sep             $20
                sta             []lineptr]
                beq             :x0
:lp             lda             tempbuff,y
                and             #$7f
                sta             []lineptr],y
                dey
                bne             :lp
:x0             rep             $20
                clc                                         ;flag all is well
                rtl
*-------------------------------------------------
iabort          pha
                lda             curpos
                sta             ]endpos
                lda             cursor
                and             #$ff
                sta             ]cursout
                lda             tempbuff
                and             #$FF
                cmp             ]maxlen
                blt             :tay1
                lda             ]maxlen
:tay1           tay
                sep             $20
                sta             []lineptr]
                beq             :x1
:lp             lda             tempbuff,y
                and             #$7F
                sta             []lineptr],y
                dey
                bne             :lp
:x1             rep             $20
                plx
                stx             ]endkey
                clc                                         ;flag abort exit
                rtl
*-------------------------------------------------
                mx              %00
iesc            sta             ]endkey
                lda             curpos
                sta             ]endpos
                lda             cursor
                and             #$ff
                sta             ]cursout
                sec                                         ;flag abort
                rtl                                         ;and leave here
*-------------------------------------------------
                mx              %00
ileft           lda             curpos                      ;current position
                jeq             badchar                     ;cannot move left
:1              dec             curpos                      ;move cursor over
                brl             newpos                      ;do new position
*-------------------------------------------------
                mx              %00
iright          lda             curpos                      ;get current spot
                sep             $20
                cmp             tempbuff                    ;maxed out?
                jge             badchar                     ;yep-->no good
                inc             curpos
                brl             newpos                      ;do new position
*-------------------------------------------------
                mx              %00
oay             lda             curpos                      ;get current position
                sep             $20
                sta             tempbuff                    ;set length at this value
                brl             prtnew                      ;print new string
*-------------------------------------------------
                mx              %00
oax             sep             $20
                stz             tempbuff
                rep             $30
                stz             curpos                      ;also set position
                brl             prtnew                      ;print new value
*-------------------------------------------------
                mx              %00
oae             sep             $20
                lda             overstrike
                cmp             cursor
                bne             :fin
                lda             insert
:fin            sta             cursor                      ;save new cursor
                rep             $20
                brl             newkey                      ;get new keypres
*-------------------------------------------------
                mx              %00
del             lda             curpos
                bne             :ok
                brl             badchar                     ;cannot delete left if @ start
:ok             tay                                         ;offset
                sep             $30
:1              lda             tempbuff+1,y
                sta             tempbuff,y
                iny
                cpy             tempbuff                    ;at end yet?
                blt             :1
                dec             tempbuff                    ;1 less char
                dec             curpos
                rep             $30
                brl             prtnew                      ;move left 1 spot
*-------------------------------------------------
oadel           sep             $20
                lda             curpos
                cmp             tempbuff
                blt             :ok
                brl             badchar                     ;cannot delete right
:ok             inc             curpos                      ;move right 1
                bra             del                         ;then delete left
                mx              %00
*-------------------------------------------------
oaleft          stz             curpos                      ;move to begining
                brl             newpos                      ;at a new position
*-------------------------------------------------
oaright         lda             tempbuff
                and             #$FF
                sta             curpos                      ;move to the far right
                brl             newpos
*-------------------------------------------------
char            pha                                         ;save character
                lda             curpos                      ;get current position
                sep             $20
                cmp             tempbuff
                rep             $20
                blt             :notend                     ;not at the end

* Cursor is at end of line:

                cmp             ]maxlen                     ;is line full?
                blt             :ok
                pla
                brl             badchar                     ;line is full/no good
:ok             ldy             curpos
                pla
                sep             $20                         ;use short A
                sta             tempbuff+1,y                ;save value
                inc             curpos                      ;move to next position
                inc             tempbuff                    ;bump up the counter
                rep             $20
                brl             prtnew                      ;print a new line

* Cursor is not at the end:

:notend         sep             $20
                lda             overstrike
                cmp             cursor                      ;in overstrike mode??
                beq             :putit                      ;yep-->just put it in there
                lda             tempbuff
                and             #$FF
                cmp             ]maxlen                     ;are we maxed?
                blt             :ok2
                rep             %00100000                   ;back to long
                pla
                brl             badchar                     ;bad input
                mx              %10                         ;assembler knows short
:ok2            lda             tempbuff                    ;get current length
                and             #$ff
                tay
:lp             lda             tempbuff+1,y                ;get position
                sta             tempbuff+2,y                ;move it up
                cpy             curpos
                beq             :dne
                dey
                bra             :lp
:dne            inc             tempbuff                    ;bump up the buffer
                rep             $20
                pla
                sep             $20
                sta             tempbuff+1,y                ;insert the value
                inc             curpos                      ;move cursor over
                rep             $20
                brl             prtnew
*-------------------------------------------------
                mx              %10                         ;enters short
:putit          ldy             curpos
                rep             $20
                pla
                sep             $20
                sta             tempbuff+1,y                ;save new char
                inc             curpos
                rep             $20
                brl             prtnew                      ;now move right 1 spot
*-------------------------------------------------
i_Cmds          dw              #54                         ;27 commands

cmds            dw              $008D                       ;return
                dw              $009B                       ;esc
                dw              $0088                       ;left arrow
                dw              $0095                       ;right arrow
                dw              $0092                       ;cntrl-R, replace
                dw              $0098                       ;cntrl-X, clear
                dw              $1098                       ;keypad cntrl-X
                dw              $0099                       ;cntrl-Y, clr EOL
                dw              $0085                       ;cntrl-E, toggle
                dw              $00FF                       ;delete key
                dw              $80FF                       ;oa-delete
                dw              $10F5                       ;keypad del
                dw              $8088                       ;oa-left
                dw              $10F3                       ;keypad home
                dw              $8095                       ;oa-right
                dw              $10F7                       ;keypad end
                dw              $80D2
                dw              $80F2                       ;oa-R,r
                dw              $80C5
                dw              $80E5                       ;oa-E,e
                dw              $80D8
                dw              $80F8                       ;oa-X,x
                dw              $80D9
                dw              $80F9                       ;oa-Y,y
                dw              $80C4
                dw              $80E4                       ;oa-Dd,cntrl-D
                dw              $0084

cmdadrs         dw              irtn
                dw              iesc
                dw              ileft
                dw              iright
                dw              oar
                dw              oax
                dw              oax
                dw              oay
                dw              oae
                dw              del
                dw              oadel
                dw              oadel
                dw              oaleft
                dw              oaleft
                dw              oaright
                dw              oaright
                dw              oar
                dw              oar
                dw              oae
                dw              oae
                dw              oax
                dw              oax
                dw              oay
                dw              oay
                dw              oadel
                dw              oadel
                dw              oadel

cursor          dw              #"_"
insert          dw              #"_"
overstrike      dw              ' '
fillchar        dw              'I'

getkey
                php
                rep             $30
                ldy             cursx
                jsr             pickchar
                and             #$FF
                sta             :screenchar
                stz             :on
                jsr             :invert
:keyl           ldx             #380*2
:keyl1          phx
                pha
                _QAKeyAvail
                pla
                bne             :read
                _QARun                                      ;send a run command to utilities
                plx
                dex
                bne             :keyl1
                jsr             :invert
                bra             :keyl
:read
                plx
                ldy             cursx
                lda             :screenchar
                jsr             storchar
                pha
                _QAGetChar
                pla
                plp
                rts
:invert
                php
                sep             $30
                bit             :on
                bpl             :curson
                lda             :screenchar
                ldy             cursx
                jsr             storchar
                stz             :on
                plp
                rts
:curson
                ldy             cursx
                lda             cursor
                cmp             overstrike
                beq             :cover
                lda             cursor
                jsr             storchar
                sec
                ror             :on
                brl             :ixit
:cover
                lda             :screenchar
                cmp             #'A'
                blt             :c0
                cmp             #'Z'+1
                bge             :c0
                lda             overstrike
                bra             :cover1
:c0
                and             #$7f
                cmp             #'A'
                blt             :cover1
                cmp             #'Z'+1
                bge             :cover1
                sec
                sbc             #$40
:cover1         jsr             storchar
                sec
                ror             :on
:ixit           plp
                rts

:screenchar     ds              2
:on             ds              2

qagetline
                dum             $00
]rtl            ds              6                           ;these are passed on stack
]abortptr       ds              4
]cursors        ds              2
]cursor         ds              2
]startpos       ds              2
]maxlen         ds              2
]prompt         ds              4
]lineptr        ds              4
]newstack       =               *-6                         ;must be at end of passed params
]cursout        ds              2
]endpos         ds              2
]endkey         ds              2
                dend

                mx              %00
                tsc
                sec
                sbc             #]rtl
                tcs
                phd
                inc
                tcd
                phb
                phk
                plb
                ldx             #0
                tdc
                jsl             {vgetline*4}+vectortbl-4
                bcs             :xit
                lda             #0
:xit            rep             $30
                tax
                lda             ]rtl+4
                sta             ]newstack+4
                lda             ]rtl+2
                sta             ]newstack+2
                lda             ]rtl
                sta             ]newstack
                plb
                pld
                tsc
                clc
                adc             #]newstack
                tcs
                txa
                brl             errxit


* FLAGS word defined as:
*   b15            - value is signed
*   b14.b13        - %0x  value is not justified
*                  - %10  value is left justifed (leading spaces)
*                  - %01  value is right justified (trailing spaces)
*   b12            - print leading 0's
*   b11            - print leading $ (QADrawHEX only)


qadrawhex
                dum             $00
]zp             ds              2
]negflag        ds              2
]rtl            ds              6                           ;these are passed on stack
]fieldsize      ds              2
]flags          ds              2
]int            ds              4
]newstack       =               *-6                         ;must be at end of passed params
                dend

                mx              %00

                tsc
                sec
                sbc             #]rtl
                tcs
                phd
                inc
                tcd
                phb
                phk
                plb

                stz             hdstr
                stz             hdfinalstr
                stz             ]negflag
                stz             ]zp
                lda             ]fieldsize
                cmp             #$10
                blt             :and
                lda             #$0f
:and            and             #$0f
                sta             ]fieldsize

                lda             ]flags
                bpl             :noneg
                lda             ]int+2
                bpl             :noneg
                lda             ]int+2
                eor             #-1
                tax
                lda             ]int
                eor             #-1
                inc
                sta             ]int
                bne             :neg
                inx
:neg            stx             ]int+2
                lda             #-1
                sta             ]negflag
:noneg          psl             ]int
                psl             #hdstr+1
                pea             hexlen
                tll             $230b                       ;_Long2Hex
                brl             :normal
:print          rep             $30
                lda             ]flags
                psl             #hdfinalstr
                _QADrawstring
:noerr          rep             $30
                lda             #0
:xit            rep             $30
                tax
                lda             ]rtl+4
                sta             ]newstack+4
                lda             ]rtl+2
                sta             ]newstack+2
                lda             ]rtl
                sta             ]newstack
                plb
                pld
                tsc
                clc
                adc             #]newstack
                tcs
                txa
                brl             errxit


:normal         sep             $30
                ldx             #0
                bit             ]negflag
                bpl             :nn1
                lda             #'-'
                sta             hdfinalstr+1,x
                inx
:nn1            lda             ]flags+1
                bit             #$08
                beq             :nn2
                lda             #'$'
                sta             hdfinalstr+1,x
                inx
:nn2            ldy             #0
]lup            lda             hdstr+1,y
                and             #$7f
                cmp             #' '
                beq             :s
                cmp             #'0'
                bne             :p
:zero           xba
                lda             ]zp
                bne             :p1
                lda             ]flags+1
                bit             #$10
                beq             :nnext
                lda             #'0'
                inc             ]zp+1
                bra             :p2
:s              lda             #'0'
                bra             :zero
:p1             xba
:p              sta             ]zp
:p2             sta             hdfinalstr+1,x
                inx
:nnext          iny
                cpy             #hexlen
                blt             ]lup
                stx             hdfinalstr
                cpx             #0
                bne             :f
                lda             #'0'
                sta             hdfinalstr+1
                inc             hdfinalstr
:f
                lda             ]flags+1
                bit             #$40
                bne             :justify
                brl             :print
:justify        lda             ]fieldsize
                jeq             :noerr
                lda             hdfinalstr
                sec
                sbc             ]zp+1                       ;subtract out any leading zeros
                cmp             ]fieldsize
                blt             :just
                beq             :just

                ldy             ]fieldsize                  ;if it won't fit print #'s
                lda             #'#'
]lup            sta             hdfinalstr,y
                dey
                bne             ]lup
                lda             ]fieldsize
                sta             hdfinalstr
                brl             :print


:just           lda             hdfinalstr
                sec
                sbc             ]fieldsize
                bcc             :just1
                beq             :just1
                tay                                         ;y now holds "over" len
                ldx             #0
                lda             hdfinalstr+1
                and             #$7f
                cmp             #'-'
                bne             :nots1
                iny
                inx
                lda             hdfinalstr+2
                and             #$7f
:nots1          cmp             #'$'
                bne             :nots
                iny
                inx
:nots           lda             hdfinalstr+1,y
                sta             hdfinalstr+1,x
                iny
                inx
                cpy             hdfinalstr
                blt             :nots
                lda             ]fieldsize
                sta             hdfinalstr

:just1          lda             ]flags+1
                bit             #$20
                bne             :left
                lda             ]fieldsize
                sec
                sbc             hdfinalstr
                beq             :j2
                jsr             DrawSpaces
:j2             brl             :print

:left           rep             $30
                psl             #hdfinalstr
                _QADrawString
                sep             $30
                lda             ]fieldsize
                sec
                sbc             hdfinalstr
                beq             :sxit
                jsr             DrawSpaces
:sxit           brl             :noerr

*======================================================
* Draw a decimal value in ASCII to output device

QADrawDec
                dum             $00
]zp             ds              2
]negflag        ds              2
]rtl            ds              6                           ;these are passed on stack
]fieldsize      ds              2
]flags          ds              2
]int            ds              4
]newstack       =               *-6                         ;must be at end of passed params
                dend

                mx              %00

                tsc
                sec
                sbc             #]rtl
                tcs
                phd
                inc
                tcd
                phb
                phk
                plb

                stz             hdstr
                stz             hdfinalstr
                stz             ]negflag
                stz             ]zp
                lda             ]fieldsize
                cmp             #$10
                blt             :and
                lda             #$0f
:and            and             #$0f
                sta             ]fieldsize

                lda             ]flags
                bpl             :noneg
                lda             ]int+2
                bpl             :noneg
                lda             ]int+2
                eor             #-1
                tax
                lda             ]int
                eor             #-1
                inc
                sta             ]int
                bne             :neg
                inx
:neg            stx             ]int+2
                lda             #-1
                sta             ]negflag
:noneg          psl             ]int
                psl             #hdstr+1
                pea             declen
                pea             0
                tll             $270b                       ;_Long2DEC
                brl             :normal
:print          rep             $30
                psl             #hdfinalstr
                _QADrawstring
:noerr          rep             $30
                lda             #0
:xit            rep             $30
                tax
                lda             ]rtl+4
                sta             ]newstack+4
                lda             ]rtl+2
                sta             ]newstack+2
                lda             ]rtl
                sta             ]newstack
                plb
                pld
                tsc
                clc
                adc             #]newstack
                tcs
                txa
                brl             errxit
:normal
                sep             $30
                ldx             #0
                bit             ]negflag
                bpl             :nn1
                lda             #'-'
                sta             hdfinalstr+1,x
                inx
:nn1            ldy             #0
]lup            lda             hdstr+1,y
                and             #$7f
                cmp             #' '
                beq             :s
                cmp             #'0'
                bne             :p
:zero           xba
                lda             ]zp
                bne             :p1
                lda             ]flags+1
                bit             #$10
                beq             :nnext
                lda             #'0'
                inc             ]zp+1
                bra             :p2
:s              lda             #'0'
                bra             :zero
:p1             xba
:p              sta             ]zp
:p2             sta             hdfinalstr+1,x
                inx
:nnext          iny
                cpy             #declen
                blt             ]lup
                stx             hdfinalstr
                cpx             #0
                bne             :f
                lda             #'0'
                sta             hdfinalstr+1
                inc             hdfinalstr
:f
                lda             ]flags+1
                bit             #$40
                bne             :justify
                brl             :print
:justify        lda             ]fieldsize
                jeq             :noerr
                lda             hdfinalstr
                sec
                sbc             ]zp+1                       ;subtract out any leading zeros
                cmp             ]fieldsize
                blt             :just
                beq             :just

                ldy             ]fieldsize                  ;if it won't fit print #'s
                lda             #'#'
]lup            sta             hdfinalstr,y
                dey
                bne             ]lup
                lda             ]fieldsize
                sta             hdfinalstr
                brl             :print
:just
                lda             hdfinalstr
                sec
                sbc             ]fieldsize
                bcc             :just1
                beq             :just1
                tay                                         ;y now holds "over" len
                ldx             #0
                lda             hdfinalstr+1
                and             #$7f
                cmp             #'-'
                bne             :nots
                iny
                inx
:nots           lda             hdfinalstr+1,y
                sta             hdfinalstr+1,x
                iny
                inx
                cpy             hdfinalstr
                blt             :nots
                lda             ]fieldsize
                sta             hdfinalstr
:just1
                lda             ]flags+1
                bit             #$20
                bne             :left
                lda             ]fieldsize
                sec
                sbc             hdfinalstr
                beq             :j2
                jsr             DrawSpaces                  ;print some spaces
:j2             brl             :print

:left           rep             $30
                psl             #hdfinalstr
                _QADrawString
                sep             $30
                lda             ]fieldsize
                sec
                sbc             hdfinalstr
                beq             :sxit
                jsr             DrawSpaces
:sxit           brl             :noerr

*======================================================
* Print date and/or time to screen, w/option read of clock

* Flags: 0= time, 1= date, 2= ASCII string, 3= read clock
*        (if not 'ASCII' & 'readclock' use ReadASCIITime)

QADateTime
                dum             $00
]temp           ds              2
]rtl            ds              6                           ;these are passed on stack
]flags          ds              2
]date           ds              4
]newstack       =               *-6                         ;must be at end of passed params
                dend

                mx              %00
                tsc
                sec
                sbc             #]rtl
                tcs
                phd
                inc
                tcd
                phb
                phk
                plb

                lda             ]flags                      ;anything to print?
                beq             :gxit
                and             #%0011
                lda             ]flags                      ;read GS clock?
                and             #%1000
                beq             :no
                lda             ]flags
                and             #%0100                      ;hex or ascii?
                beq             :hex
                ~ReadASCIITime  #tempbuff
                sep             #$30
                stz             tempbuff+8
                rep             #$30
                stz             tempbuff+17                 ;end of date/time fields
                lda             ]flags
                and             #%0010                      ;show date?
                beq             :asciitime
                ~QADrawCString  #tempbuff                   ; yes
                jsl             DrawSpace
:asciitime
                lda             ]flags
                and             #%0001                      ;show time?
                beq             :gxit
                ~QADrawCString  #tempbuff+9                 ; yes
:gxit           bra             :xit
:hex
                ~ReadTimeHex                                ;get time in hex
                ldx             #4
                ldy             #0
]loop           pla
                sta             []date],y                   ;save data to user's buffer
                iny
                iny
                dex
                bne             ]loop                       ; & fall into print routine!
:no
                lda             ]flags                      ;show date?
                and             #%0010
                beq             :time
                ldy             #4
                lda             []date],y                   ;print day
                inc
                jsr             sNumDraw

                ldy             #4
                lda             []date],y
                xba
                and             #$ff
                asl
                sta             ]temp                       ;print month w/seperators
                asl
                adc             ]temp
                adc             #ftmonths
                pea             #^ftmonths
                pha
                _QADrawString

                ldy             #2
                lda             []date],y                   ;print year
                xba
                jsr             zNumDraw

                jsl             DrawSpace
:time
                lda             ]flags                      ;show time?
                and             #%0001
                beq             :done
                ldy             #2
                lda             []date],y
                jsr             sNumDraw
                lda             #':'
                jsl             {vprintchar*4}+vectortbl-4  ;print time
                lda             []date]
                xba
                jsr             zNumDraw
:done
                lda             #0
:xit
                tax
                lda             ]rtl+4
                sta             ]newstack+4
                lda             ]rtl+2
                sta             ]newstack+2
                lda             ]rtl
                sta             ]newstack
                plb
                pld
                tsc
                clc
                adc             #]newstack
                tcs
                txa
                brl             errxit

ftmonths
                str             '-Jan-'
                str             '-Feb-'
                str             '-Mar-'
                str             '-Apr-'
                str             '-May-'
                str             '-Jun-'
                str             '-Jul-'
                str             '-Aug-'
                str             '-Sep-'
                str             '-Oct-'
                str             '-Nov-'
                str             '-Dec-'

zNumDraw
                ldx             #%0101_0000_0000_0000
                bra             NumDraw
sNumDraw
                ldx             #%0100_0000_0000_0000
NumDraw
                pea             #0
                and             #$FF                        ;only a byte!
                pha
                phx
                pea             #2
                _QADrawDec
                rts

*------------------------------------------------------
QADrawCR
                jsl             DrawCR
                brl             noerror

QADrawSpace
                jsl             DrawSpace
                brl             noerror

DrawSpaces
                php
                rep             $30                         ;insure 16 bit
                pea             32
                and             #$FF
                pha                                         ;count
                _QADrawCharX
                plp
                rts

*======================================================
* Text driver stuff, patched into text tools so that
* we can support Merlin and APW EXE commands

TTDevice
                brl             inittt
                brl             readtt
                brl             writett
                brl             statustt
                brl             controltt
TTErrDevice
                brl             inittt
                brl             readtt
                brl             writett1
                brl             statustt
                brl             controltt

inittt          rtl
statustt        rtl
controltt       rtl

readtt
                pha
                _QAKeyAvail
                pla
                beq             readtt
                pha
                _QAGetChar
                pla
                and             #$ff
                rtl
DrawCR
                lda             #13
                bra             writett
DrawSpace
                lda             #' '
writett
                phb
                phk
                plb
                jsl             {vprintchar*4}+vectortbl-4
                plb
                rtl
writett1
                phb
                phk
                plb
                jsl             {verrchar*4}+vectortbl-4
                plb
                rtl

*======================================================
* Print a version number to the screen in Apple format

* Format of parameter: aaaaaaaa_ccccdddd_eeeeeeee_ffffffff

* a=major version, c=minor version, d=revision
* e = alpha, beta, etc. ASCII letter (0 = null), f=delta version

* $01006410 = v1.00d16

QAPrintVersion
                dum             $00
]rtl            ds              6                           ;these are passed on stack
]version        ds              4
]newstack       =               *-6                         ;must be at end of passed params
                dend

                mx              %00
                tsc
                sec
                sbc             #]rtl
                tcs
                phd
                inc
                tcd
                phb
                phk
                plb

                lda             ]version+2
                xba                                         ;draw major version
                and             #$FF
                pea             #0
                pha
                pea             #0
                pea             #2
                _QADrawDec

                lda             #'.'
                jsl             {vprintchar*4}+vectortbl-4
                lda             ]version+2
                pha
                _QAPrByte                                   ;show minor version/revision numbers

                lda             ]version
                beq             :done                       ;is there a delta?
                xba
                and             #$7F                        ; yes- print ASCII part
                jsl             {vprintchar*4}+vectortbl-4
                lda             ]version
                and             #$FF                        ;print delta version
                pea             #0
                pha
                pea             #0
                pea             #3
                _QADrawDec
:done
                lda             #0
:xit
                tax
                lda             ]rtl+4
                sta             ]newstack+4
                lda             ]rtl+2
                sta             ]newstack+2
                lda             ]rtl
                sta             ]newstack
                plb
                pld
                tsc
                clc
                adc             #]newstack
                tcs
                txa
                brl             errxit

*======================================================
* Got a time control code (^R)--set to print time/date

pTime
                rts
pVersion
                rts

*======================================================
* Print Time/Version/Set Justification
* Code: 1=Time Code, 2=Version byte
*

PrintTVJ
                php
                sep             #$30                        ;back to 8 bit
                lsr
                lsr                                         ;position bits to get 1-7
                lsr
                dec
                asl                                         ;get index
                tax
                jsr             (:tbl,x)                    ; & pass control to routine
                plp
                rts
:tbl
                da              sTime
                da              gTime
                da              sVersion
                da              gVersion
                da              sJustify
                da              gJustify
                da              pJString

*------------------------------------------------------
* Want to print the time as part of our stuff

sTime
gTime
sVersion
gVersion
sJustify
gJustify
pJString
                rts

*======================================================
* Read a directory and return filenames which match the
* current wildcard value.  Must have called InitWildCard

QAReadDir
                dum             $00
]temp           ds              4
]curptr         ds              4
]zp             ds              4
]ptr            ds              4
]rtl            ds              6                           ;these are passed on stack
]flags          ds              2
]hook           ds              4
]path           ds              4
]newstack       =               *-6                         ;must be at end of passed params
                dend

                mx              %00
                tsc
                sec
                sbc             #]rtl
                tcs
                phd
                inc
                tcd
                phb
                phk
                plb

                lda             :level
                beq             :allok
                lda             #qaalreadyactive
                jmp             :xit1
:allok          stz             :level
                lda             #tpfx
                sta             pptr
                lda             #^tpfx
                sta             pptr+2
                lda             #256
                sta             tpfx
                lda             #2
                sta             spfx
                jsl             $e100a8
                dw              $200A
                adrl            spfx
                bcc             :e1
                jmp             :xit

:e1             lda             []path]
                beq             :stz                        ;could do a getpfx here
                tay
                iny
                sep             $20
                lda             []path],y
                and             #$7f
                cmp             #'/'
                beq             :chop
                cmp             #':'
                bne             :stz
:chop           rep             $30
                lda             []path]
                dec
                sta             []path]
:stz            rep             $30
                lda             []path]
                tax
                ldy             #$01
                sep             $20
]syntax         iny
                lda             []path],y
                and             #$7f
                cmp             #'/'
                bne             :s1
                lda             #':'
:s1             sta             []path],y
                dex
                bne             ]syntax
                rep             $30
                jsr             :newdir
                jcs             :xit
:main           rep             $30
                lda             :level
                jeq             :done
                dec
                asl
                asl
                asl
                tax
                lda             dhandles+4,x
                sta             ]curptr
                lda             dhandles+6,x
                sta             ]curptr+2
                ldy             #:count
                lda             []curptr],y
                jeq             :backup
                lda             #:dirparms
                clc
                adc             ]curptr
                sta             :entp
                lda             #$00
                adc             ]curptr+2
                sta             :entp+2
                jsl             $e100a8
                dw              $201c
:entp           adrl            0
                jcs             :xit
                ldy             #:count
                lda             []curptr],y
                dec
                sta             []curptr],y

:go             ldy             #:filetype
                lda             []curptr],y
                cmp             #$0f
                bne             :file
                lda             ]flags
* bit #$01 ;nesting enabled?
* beq :next
                bit             #$02
                beq             :nwc0
                jsr             :wildcard
                bcc             :nwc
:nwc0           lda             :level
                and             #$ff
                ora             #$8000
                bra             :cl2
:nwc            lda             :level
                and             #$ff
:cl2            ora             #$0100
                jmp             :c
:file           lda             ]flags
                bit             #$02
                beq             :file1
                jsr             :wildcard                   ;does the file match wildcard
                bcs             :file1
                lda             :level
                and             #$ff
                bra             :c
:file1          lda             :level
                and             #$ff
                ora             #$8000
:c              jsr             :call
                jcs             :xit
:next
                ldy             #:filetype
                lda             []curptr],y
                cmp             #$0f
                jne             :main

                lda             ]flags
                bit             #$0001                      ;are subdirectories enabled?
                bne             :new
* beq :m1
* bit #$02 ;should we check to see if this DIR should be
* beq :new ;opened?
* jsr :wildcard
* bcs :new
:m1             brl             :main
:new            jsr             :newdir
                jcs             :xit
                brl             :main
:backup         lda             :level
                jeq             :done
                dec
                sta             :level
                asl
                asl
                asl
                tax
                lda             dhandles+4,x
                sta             ]curptr
                lda             dhandles+6,x
                sta             ]curptr+2

                lda             #:clsparms
                clc
                adc             ]curptr
                sta             :cp2
                lda             #$00
                adc             ]curptr+2
                sta             :cp2+2

                jsl             $e100a8
                dw              $2014
:cp2            adrl            0
                lda             :level
                asl
                asl
                asl
                tax
                lda             dhandles+2,x
                pha
                lda             dhandles,x
                pha
                _Disposehandle

                lda             :level
                beq             :done
                dec
                asl
                asl
                asl
                tax
                lda             dhandles+4,x
                sta             ]curptr
                lda             dhandles+6,x
                sta             ]curptr+2

                lda             ]curptr
                clc
                adc             #:filename
                sta             pptr
                lda             ]curptr+2
                adc             #^:filename
                sta             pptr+2

                jsl             prodos
                dw              $2009
                adrl            spfx
                bcc             :bdone
                jmp             :xit

:bdone          lda             ]flags
                bit             #$02                        ;wildcards?
                beq             :nwc2
                jsr             :wildcard
                bcc             :nwc1
:nwc2           lda             :level
                and             #$ff
                ora             #$8000
                bra             :cl1
:nwc1           lda             :level
                and             #$FF
:cl1            ora             #$0200                      ;closing a dir
                jsr             :call
                bcs             :xit
:chk            lda             :level
                beq             :done
                jmp             :main
:done           rep             $30
                lda             #$00
:xit            rep             $30
                pha
:clup           lda             :level
                beq             :nocls
                dec
                asl
                asl
                asl
                tax
                lda             dhandles+4,x
                sta             ]curptr
                lda             dhandles+6,x
                sta             ]curptr+2
                lda             #:clsparms
                clc
                adc             ]curptr
                sta             :cp
                lda             #$00
                adc             ]curptr+2
                sta             :cp+2
                jsl             $e100a8
                dw              $2014
:cp             adrl            0
                lda             :level
                dec
                sta             :level
                asl
                asl
                asl
                tax
                lda             dhandles+2,x
                pha
                lda             dhandles,x
                pha
                _Disposehandle
                brl             :clup
:nocls          pla
:xit1           rep             $30
                pha

                lda             #tpfx+2
                sta             pptr
                lda             #^tpfx+2
                sta             pptr+2

                jsl             prodos
                dw              $2009
                adrl            spfx

                lda             #$ffff
                sta             wcauxmask
                sta             wcauxmask+2
                sta             wcftypemask
                lda             #$00
                sta             wcaux
                sta             wcaux+2
                sta             wcftype
                sta             wcstring

                pla
                tax
                lda             ]rtl+4
                sta             ]newstack+4
                lda             ]rtl+2
                sta             ]newstack+2
                lda             ]rtl
                sta             ]newstack
                plb
                pld
                tsc
                clc
                adc             #]newstack
                tcs
                txa
                jmp             errxit

:newdir         php
                rep             $30
                stz             :ndhdl
                stz             :ndhdl+2
                psl             #$00
                lda             :level
                jeq             :first
                psl             #$00
                dec
                asl
                asl
                asl
                tax
                lda             dhandles+4,x
                sta             ]curptr
                lda             dhandles+6,x
                sta             ]curptr+2
                lda             dhandles+2,x
                pha
                lda             dhandles,x
                pha
                _GetHandleSize
                ldy             #:namelen
                lda             []curptr],y
                clc
                adc             1,s
                sta             1,s
                bcc             :nd0
                lda             3,s
                adc             #$00
                sta             3,s
:nd0            lda             1,s
                inc
                sta             1,s
                bne             :nd00
                lda             3,s
                inc
                sta             3,s
:nd00           ldal            userid
                ora             #$A00
                pha
                pea             $C000
                psl             #$00
                _NewHandle
                plx
                ply
                jcs             :nderr
                jmp             :deref
:first          ldx             #$00
                lda             #recsize
                clc
                adc             []path]
                bcc             :nd2
                inx
:nd2            phx
                pha
                ldal            userid
                ora             #$A00
                pha
                pea             $C000
                psl             #$00
                _NewHandle
                plx
                ply
                jcs             :nderr
:deref          sty             :ndhdl+2
                sty             ]zp+2
                stx             :ndhdl
                stx             ]zp
                ldy             #$02
                lda             []zp]
                tax
                lda             []zp],y
                sta             ]zp+2
                stx             ]zp
                psl             #$00
                psl             :ndhdl
                _GetHandleSize
                pll             :size
                lda             #$00
                tay
                sep             $20
]lup            sta             []zp],y
                iny
                cpy             :size
                blt             ]lup
                rep             $30

                lda             :level
                beq             :first1
                dec
                asl
                asl
                asl
                tax
                lda             dhandles+4,x
                sta             ]temp
                lda             dhandles+6,x
                sta             ]temp+2
                ldy             #:filename
                lda             []temp],y
                inc
                inc
                sta             :ct
]lup            sep             $20
                lda             []temp],y
                sta             []zp],y
                iny
                rep             $30
                dec             :ct
                bne             ]lup
                lda             #':'
                sep             $20
                sta             []zp],y
                iny
                tyx
                rep             $20
                ldy             #:namelen
                lda             []temp],y
                beq             :d2
                sta             :ct
                ldy             #:buffer
]l              sep             $20
                lda             []temp],y
                phy
                txy
                sta             []zp],y
                ply
                iny
                inx
                rep             $20
                dec             :ct
                bne             ]l

:d2             rep             $30
                txa
                sec
                sbc             #:filename+2
                ldy             #:filename
                sta             []zp],y

                jmp             :f1
:first1         rep             $30
                ldy             #$02
                lda             []path],y
                and             #$7f
                cmp             #':'
                beq             :full
                cmp             #'/'
                beq             :full


:full           lda             []path]
                inc
                inc
                sta             :ct
                ldx             #:filename
                ldy             #$00
]lup            sep             $20
                lda             []path],y
                phy
                txy
                sta             []zp],y
                ply
                inx
                iny
                rep             $30
                dec             :ct
                bne             ]lup
:f1             rep             $30

                lda             ]zp
                clc
                adc             #:filename
                sta             pptr
                lda             ]zp+2
                adc             #$00
                sta             pptr+2

                jsl             prodos
                dw              $2009
                adrl            spfx
                bcc             :l1

                jmp             :nderr
:l1             ldy             #:oparms
                lda             #$04
                sta             []zp],y
                ldy             #:request
                lda             #$01
                sta             []zp],y
                ldy             #:dirparms
                lda             #17
                sta             []zp],y
                ldy             #:fstid
                lda             #$01
                sta             []zp],y
                ldy             #:clsparms
                lda             #$01
                sta             []zp],y
                ldy             #:dirbuf
                lda             #65
                sta             []zp],y
                lda             ]zp
                clc
                adc             #:dirbuf
                pha
                lda             ]zp+2
                adc             #$00
                ldy             #:bufptr+2
                sta             []zp],y
                dey
                dey
                pla
                sta             []zp],y

                lda             ]zp
                clc
                adc             #:filename
                pha
                lda             ]zp+2
                adc             #$00
                ldy             #:ptr1+2
                sta             []zp],y
                dey
                dey
                pla
                sta             []zp],y
                lda             ]zp
                sta             ]curptr
                lda             ]zp+2
                sta             ]curptr+2

                lda             #:oparms
                clc
                adc             ]curptr
                sta             :p1
                lda             #$00
                adc             ]curptr+2
                sta             :p1+2

                lda             #:dirparms
                clc
                adc             ]curptr
                sta             :p2
                lda             #$00
                adc             ]curptr+2
                sta             :p2+2

                jsl             $e100a8
                dw              $2010
:p1             adrl            0
                jcs             :nderr

                ldy             #:oref
                lda             []curptr],y
                ldy             #:dirref
                sta             []curptr],y
                ldy             #:clsref
                sta             []curptr],y

                jsl             $e100a8
                dw              $201c
:p2             adrl            0
                jcs             :nderr
                ldy             #:entnum
                lda             []curptr],y
                ldy             #:count
                sta             []curptr],y
                ldy             #:base
                lda             #$01
                sta             []curptr],y
                ldy             #:displace
                sta             []curptr],y

                lda             :level
                asl
                asl
                asl
                tax
                lda             :ndhdl
                sta             dhandles,x
                lda             :ndhdl+2
                sta             dhandles+2,x
                lda             ]curptr
                sta             dhandles+4,x
                lda             ]curptr+2
                sta             dhandles+6,x
                inc             :level
                plp
                clc
                rts
:nderr          rep             $30
                pha
                lda             :ndhdl
                ora             :ndhdl+2
                beq             :nde1
                psl             :ndhdl
                _disposehandle
                stz             :ndhdl
                stz             :ndhdl+2
:nde1           pla
                plp
                sec
                rts
:ndhdl          ds              4

:call           php
                rep             $30
                sta             :temp
                lda             ]hook
                ora             ]hook+2
                jeq             :cclc
                lda             ]hook
                sta             :jsl1+1
                lda             ]hook+2
                sep             $20
                sta             :jsl1+3
                rep             $20
                phd
                phb
                lda             #:dirparms
                clc
                adc             ]curptr
                tay
                lda             #$00
                adc             ]curptr+2
                tax
                tya
                ldy             :temp
:jsl1           jsl             $FFFFFF
                php
                clc
                xce
                rep             $30
                plp
                plb
                pld
                bcc             :cclc
                plp
                sec
                rts
:cclc           plp
                clc
                rts
:temp           ds              2

:wildcard                                                   ;carry = C no wildcard match
;      = S wildcard matches
                php
                rep             $30
                lda             #$ffff
                sta             :wc                         ;default to valid
                lda             wcstring
                and             #$ff
                jeq             :ftype
                sta             :wclen
                ldy             #:namelen
                lda             []curptr],y
                jeq             :noname
                sta             :nlen
                iny
                iny                                         ;point y to first char of name
                ldx             #$01                        ;point x to first char of WC
                sep             $20
]look           lda             wcstring,x
                and             #$7f
                cmp             #'a'
                blt             :1
                cmp             #'z'+1
                bge             :1
                and             #$5f
:1              cmp             #'='
                beq             :chars
                cmp             #'?'
                beq             :nextxy                     ;any char is valid
                sta             :cmp
                lda             []curptr],y
                and             #$7f
                cmp             #'a'
                blt             :2
                cmp             #'z'+1
                bge             :2
                and             #$5f
:2              cmp             :cmp
                beq             :nextxy
                jmp             :noname
:chars          inx
                dec             :wclen
                beq             :ftype                      ;is wildcard done?
                lda             wcstring,x
                and             #$7f
                cmp             #'a'
                blt             :3
                cmp             #'z'+1
                bge             :3
                and             #$5f
:3              sta             :cmp
                bra             :n
]equ            iny
                dec             :nlen
                beq             :noname
:n              lda             []curptr],y
                and             #$7f
                cmp             #'a'
                blt             :4
                cmp             #'z'+1
                bge             :4
                and             #$5f
:4              cmp             :cmp
                bne             ]equ                        ;keep looping until char found
:nextxy         inx
                dec             :wclen
:nexty          iny
                dec             :nlen
                jmp             :chklen
:nextx          inx
                dec             :wclen
:chklen         lda             :nlen
                ora             :wclen
                beq             :ftype
                jmp             ]look
                                                            ;check here for string match
:noname         rep             $30
                stz             :wc
:ftype          rep             $30
                lda             wcftypemask
                beq             :tryaux
                ldy             #:filetype
                lda             []curptr],y
                and             wcftypemask
                cmp             wcftype
                beq             :tryaux
                stz             :wc
:tryaux         lda             wcauxmask
                ora             wcauxmask+2
                beq             :wcchk
                ldy             #:aux
                lda             []curptr],y
                and             wcauxmask
                cmp             wcaux
                bne             :zero
                iny
                iny
                lda             []curptr],y
                and             wcauxmask+2
                cmp             wcaux+2
                beq             :wcchk
:zero           stz             :wc
:wcchk          lda             :wc
                bne             :wcsec
:wcclc          plp                                         ;wildcard doesn't match
                clc
                rts
:wcsec          plp                                         ;wild card matches
                sec
                rts

:wc             ds              2
:wclen          ds              2
:nlen           ds              2
:cmp            ds              2
*===============================
:ct             ds              2
:size           ds              4
:level          ds              2

                dum             0

:count          ds              2

:oparms         dw              4                           ;parms for open
:oref           dw              0
:ptr1           adrl            :filename
:request        dw              $0001                       ;read only
                dw              0                           ;data fork

:dirparms                                                   ;parms for getdirentry
                dw              17
:dirref         dw              0                           ;ref #
:flags          dw              0                           ;reserved
:base           dw              0
:displace       dw              0
:bufptr         adrl            :dirbuf
:entnum         dw              0                           ;entry number in DIR
:filetype       dw              0                           ;filetype
:eof            adrl            0                           ;eof
:blocks         adrl            0                           ;block count
:cdate          ds              8                           ;create date
:mdate          ds              8                           ;mod date
:access         da              0                           ;access
:aux            adrl            0                           ;auxtype
:fstid          dw              1                           ;file system id
:oplist         adrl            0
:reof           adrl            0
:rblks          adrl            0

:clsparms       dw              1
:clsref         ds              2

:dirbuf         dw              65                          ;buff size for getdirentry
:namelen        dw              0                           ;filename length for "
:buffer         ds              65                          ;filename put here

:filename       ds              2

recsize         =               *
                dend

*======================================================
QAInitWildCard

                dum             $00
]rtl            ds              6                           ;these are passed on stack
]auxmask        ds              4
]ftmask         ds              2
]aux            ds              4
]ft             ds              2
]wcstr          ds              4
]newstack       =               *-6                         ;must be at end of passed params
                dend

                mx              %00
                tsc
                sec
                sbc             #]rtl
                tcs
                phd
                inc
                tcd
                phb
                phk
                plb
                lda             ]ft
                sta             wcftype
                lda             ]aux
                sta             wcaux
                lda             ]aux+2
                sta             wcaux+2
                lda             ]ftmask
                sta             wcftypemask
                lda             ]auxmask
                sta             wcauxmask
                lda             ]auxmask+2
                sta             wcauxmask+2
                sep             $30
                lda             []wcstr]
                cmp             #15
                blt             :ok
                lda             #15
:ok             sta             wcstring
                tay
                beq             :done
]l              lda             []wcstr],y
                and             #$7f
                cmp             #'a'
                blt             :sta
                cmp             #'z'+1
                bge             :sta
                and             #$5f
:sta            sta             wcstring,y
                dey
                bne             ]l
:done           rep             $30
                lda             #$00
:xit            rep             $30
                tax
                lda             ]rtl+4
                sta             ]newstack+4
                lda             ]rtl+2
                sta             ]newstack+2
                lda             ]rtl
                sta             ]newstack
                plb
                pld
                tsc
                clc
                adc             #]newstack
                tcs
                txa
                jmp             errxit

*======================================================
* Trap some GS/OS vectors so we can safely work!

SetVects        php
                sei
                rep             $30
                ldal            $E100A8
                sta             GSOSVect1
                ldal            $E100A8+2
                sta             GSOSVect1+2
                ldal            $E100B0
                sta             GSOSVect2
                ldal            $E100B0+2
                sta             GSOSVect2+2
                lda             #P16Quit
                stal            $E100A8+1
                lda             #^P16Quit
                sep             $20
                stal            $E100A8+3
                rep             $30
                lda             #p16quit1
                stal            $E100B0+1
                lda             #^P16Quit
                sep             $20
                stal            $E100B0+3
                rep             $30
                plp
                rts

RestoreVects
                php
                sei
                rep             $30
                lda             GSOSVect1
                stal            $E100A8
                lda             GSOSVect1+2
                stal            $E100A8+2
                lda             GSOSVect2
                stal            $E100B0
                lda             GSOSVect2+2
                stal            $E100B0+2
                plp
                rts

P16QHandle      clc
                xce
                phk
                plb
                rep             $30
                lda             stack
                tcs
                ldx             #$00
                lda             #$00
                clc
                jmp             (return,x)

P16Quit         phb                                         ;save the environment
                phk
                plb
                sty             p16y                        ;save the Y reg
                php
                sep             $20
                lda             $05,s                       ;get bank of call
                pha
                plb                                         ;set to current bank
                ldy             #$01
                lda             ($03,s),y                   ;read the command num of p16 call
                cmp             #$29                        ;is it QUIT?
                beq             p16qhandle                  ;yes, so shutdown/restore everything
                plp                                         ;if not restore what we changed
                phk
                plb
                ldy             p16y                        ;restore the Y
                plb                                         ;and the bank
GSOSVect1
                jml             $FFFFFF                     ;jump to P16 entry vector

p16quit1        phb                                         ;save the current bank
                phk
                plb                                         ;set to our bank
                php                                         ;save the processor
                sep             $20
                lda             $06,s                       ;get command num from stack
                cmp             #$29                        ;quit?
                beq             p16qhandle                  ;yes so restore/shutdown external
                plp                                         ;restore what we changed and call
                plb                                         ;old P16 vector
GSOSVect2
                jml             $FFFFFF

*======================================================
* Draw a box on the screen, saving what is underneath it

QADrawBox
                dum             $00
]cx             ds              2
]cy             ds              2
]top            ds              2
]left           ds              2
]bottom         ds              2
]right          ds              2
]size           ds              4
]ptr            ds              4
]tempy          ds              2
]rtl            ds              6                           ;these are passed on stack
]height         ds              2
]width          ds              2
]y              ds              2
]x              ds              2
]newstack       =               *-6                         ;must be at end of passed params
]bufhdl         ds              4
                dend

                mx              %00
                tsc
                sec
                sbc             #]rtl
                tcs
                phd
                inc
                tcd
                phb
                phk
                plb
                stz             ]bufhdl
                stz             ]bufhdl+2
                lda             cursx
                sta             ]cx
                lda             cursy
                sta             ]cy
                lda             ]x
                clc
                adc             ]width
                cmp             #80
                blt             :1
                sec
                sbc             #80
                sec
                sbc             ]width
                eor             #$FFFF
                inc
                sta             ]width
:1              lda             ]y
                clc
                adc             ]height
                cmp             #24
                blt             :2
                sec
                sbc             #24
                sec
                sbc             ]height
                eor             #$FFFF
                inc
                sta             ]height
:2              psl             #$00
                pei             ]width
                pei             ]height
                tll             $090B                       ;_Multiply
                lda             1,s
                clc
                adc             #8
                sta             1,s
                lda             3,s
                adc             #0
                sta             3,s
                pll             ]size

                psl             #$00
                psl             ]size
                ldal            userid
                ora             #$A00
                pha
                pea             $8000
                psl             #$00
                _NewHandle
                plx
                ply
                jcs             :xit
                stx             ]bufhdl
                sty             ]bufhdl+2
                ldy             #$02
                lda             []bufhdl]
                sta             ]ptr
                lda             []bufhdl],y
                sta             ]ptr+2
                lda             ]x
                sta             []ptr]
                ldy             #$02
                lda             ]y
                sta             []ptr],y
                ldy             #$04
                lda             ]width
                sta             []ptr],y
                ldy             #$06
                lda             ]height
                sta             []ptr],y

                lda             ]x
                sta             cursx
                lda             ]y
                sta             cursy

                lda             ]x
                sta             ]left
                clc
                adc             ]width
                dec
                sta             ]right
                lda             ]y
                sta             ]top
                clc
                adc             ]height
                dec
                sta             ]bottom
                ldy             #$08
                sty             ]tempy
]l1             rep             $30
                lda             cursx
                pha
                lda             cursy
                pha
                _QAGotoXY
                sep             $30
                lda             ]height
                beq             :noerr
                ldx             ]width
                ldy             ]left
]l2             cpx             #$00
                beq             :next
                phy
                jsr             pickchar
                rep             $10
                ldy             ]tempy
                sta             []ptr],y
                rep             $20
                inc             ]tempy
                sep             $30
                ply
                lda             cursy
                cmp             ]top
                beq             :t
                cmp             ]bottom
                beq             :b
                cpy             ]left
                beq             :l
                cpy             ]right
                beq             :r
                bra             :spc
:t              cpy             ]left
                beq             :spc
                cpy             ]right
                beq             :spc
                lda             #$5f.$80
                bra             :sta
:b              cpy             ]left
                beq             :spc
                cpy             ]right
                beq             :spc
                lda             #$4c
                bra             :sta
:r              lda             #$5f
                bra             :sta
:l              lda             #$5a
                bra             :sta
:spc            lda             #$a0
:sta            phy
                jsr             storchar
                ply
                iny
                dex
                bne             ]l2
:next           inc             cursy
                dec             ]height
                bne             ]l1

:noerr          rep             $30
                lda             #$00
:xit            rep             $30
                pha
                lda             ]cx
                sta             cursx
                lda             ]cy
                sta             cursy
                lda             cursx
                pha
                lda             cursy
                pha
                _QAGotoXY
                lda             ]bufhdl+2
                ora             ]bufhdl
                beq             :pla
                psl             ]bufhdl
                _HUnlock
:pla            pla
                tax
                lda             ]rtl+4
                sta             ]newstack+4
                lda             ]rtl+2
                sta             ]newstack+2
                lda             ]rtl
                sta             ]newstack
                plb
                pld
                tsc
                clc
                adc             #]newstack
                tcs
                txa
                jmp             errxit

*======================================================
* Restore a box on the screen, with what was originally there

QAEraseBox
                dum             $00
]cx             ds              2
]cy             ds              2
]top            ds              2
]left           ds              2
]bottom         ds              2
]right          ds              2
]ptr            ds              4
]tempy          ds              2
]x              ds              2
]y              ds              2
]width          ds              2
]height         ds              2
]rtl            ds              6                           ;these are passed on stack
]bufhdl         ds              4
]newstack       =               *-6                         ;must be at end of passed params
                dend

                mx              %00
                tsc
                sec
                sbc             #]rtl
                tcs
                phd
                inc
                tcd
                phb
                phk
                plb
                lda             cursx
                sta             ]cx
                lda             cursy
                sta             ]cy
                psl             ]bufhdl
                _Hlock
                jcs             :xit
                ldy             #$02
                lda             []bufhdl]
                sta             ]ptr
                lda             []bufhdl],y
                sta             ]ptr+2

                lda             []ptr]
                sta             ]x
                ldy             #$02
                lda             []ptr],y
                sta             ]y
                ldy             #$04
                lda             []ptr],y
                sta             ]width
                ldy             #$06
                lda             []ptr],y
                sta             ]height

                lda             ]x
                sta             cursx
                lda             ]y
                sta             cursy

                lda             ]x
                sta             ]left
                clc
                adc             ]width
                dec
                sta             ]right
                lda             ]y
                sta             ]top
                clc
                adc             ]height
                dec
                sta             ]bottom
                ldy             #$08
                sty             ]tempy
]l1             rep             $30
                lda             cursx
                pha
                lda             cursy
                pha
                _QAGotoXY
                sep             $30
                lda             ]height
                beq             :noerr
                ldx             ]width
                ldy             ]left
]l2             cpx             #$00
                beq             :next
                phy
                rep             $10
                ldy             ]tempy
                lda             []ptr],y
                sep             $30
                ply
                jsr             storchar
                rep             $20
                inc             ]tempy
                sep             $30
                iny
                dex
                bne             ]l2
:next           inc             cursy
                dec             ]height
                bne             ]l1

:noerr          rep             $30
                lda             #$00
:xit            rep             $30
                pha
                lda             ]cx
                sta             cursx
                lda             ]cy
                sta             cursy
                lda             cursx
                pha
                lda             cursy
                pha
                _QAGotoXY
                lda             ]bufhdl+2
                ora             ]bufhdl
                beq             :pla
                psl             ]bufhdl
                _HUnlock
:pla            pla
                tax
                lda             ]rtl+4
                sta             ]newstack+4
                lda             ]rtl+2
                sta             ]newstack+2
                lda             ]rtl
                sta             ]newstack
                plb
                pld
                tsc
                clc
                adc             #]newstack
                tcs
                txa
                jmp             errxit

*======================================================
* Convert a string from/to GS/OS class 1 to PString format

QAConvertStr

                dum             $00
]maxlen         ds              2
]rtl            ds              6                           ;these are passed on stack
]cmdcode        ds              2
]buffptr        ds              4
]textptr        ds              4
]newstack       =               *-6                         ;must be at end of passed params
]rtncode        ds              2
                dend

                mx              %00
                tsc
                sec
                sbc             #]rtl
                tcs
                phd
                inc
                tcd
                phb
                phk
                plb

:noerr          rep             $30
                lda             #$0000
:xit            rep             $30
                tax
                lda             ]rtl+4
                sta             ]newstack+4
                lda             ]rtl+2
                sta             ]newstack+2
                lda             ]rtl
                sta             ]newstack
                plb
                pld
                tsc
                clc
                adc             #]newstack
                tcs
                txa
                jmp             errxit

*======================================================
* Return the address of the current keypress handler

QAGetKeyAdrs
                mx              %00
                lda             #keyaddress
                sta             7,s
                lda             #^keyaddress
                sta             9,s
                brl             noerror

InstallKey
                php
                phb
                phk
                plb
                sei
                rep             $30
                stz             keyintsactive

                psl             #$00
                pea             $000f                       ;keyboard vector
                tll             $1103                       ;getvector
                pla
                sta             eventkey+1
                pla
                sep             $20
                sta             eventkey+3
                rep             $30
                pea             $000f
                psl             #keyhandler
                tll             $1003                       ;set vector

                pea             $00
                tll             $0606
                pla
                bcs             :noem
                beq             :noem
                lda             #$FFFF
                sta             emactive
                bra             :xit
:noem
                sep             $20
                ldal            $e0c027
                pha
                and             #%00000100
                sta             keyintsactive
                pla
                ora             #%00000100
                stal            $e0c027
                rep             $30
:xit
                plb
                plp
                rts

*======================================================
* Remove our key handler from the event vector

RemoveKey
                php
                phb
                phk
                plb
                rep             $30
                sei
                pea             $000f
                lda             eventkey+3
                and             #$ff
                pha
                lda             eventkey
                pha
                tll             $1003                       ;set vector

                lda             emactive
                stz             emactive
* cmp #$00
                bne             :xit
                lda             keyintsactive
                bne             :xit
                sep             $20
                ldal            $e0c027
                and             #%00000100!$ffff
                stal            $e0c027
                rep             $20
                stz             keyintsactive
:xit            plb
                plp
                rts

*======================================================
* This routine is called by the event manager to handle
* any keyboard events it recieves.  8 BIT EMULATION MODE!

                mx              %11
KeyHandler
                php
                phb
                phk
                plb
                pha
                ldal            $e0c000
                stal            keyaddress
                ldal            $e0c025
                stal            keyaddress+1
                ldal            emactive
                bmi             :ekey
                ldal            $e0c010
:clc            pla
                plb
                plp
                clc
                rtl
:ekey
                pla
                plb
                plp
eventkey
                jml             $FFFFF

*======================================================
* Find the next word in a string of text. < SPC = EOL (TAB = SPC)
* ENTRY: Pointer to text, current index , max length (64K)
*  EXIT: Start of word, End of word+1 (BCS = err, A = BMI if at EOF)

QAGetWord
                dum             $00
]rtl            ds              6                           ;these are passed on stack
]maxlen         ds              2                           ;max length of text
]index          ds              2                           ;starting index in text
]TxtPtr         ds              4                           ;pointer to text
]newstack       =               *-6                         ;must be at end of passed parms
]EndWord        ds              2                           ;end of word
]BegWord        ds              2                           ;start of word (index into text)
                dend

                mx              %00
                tsc
                phd
                inc
                tcd
                phb
                phk
                plb

                stz             ]BegWord                    ;assume error
                stz             ]EndWord

                ldy             ]index                      ;get index into text
                dey
]loop
                iny
                cpy             ]maxlen                     ;past eof?
                bge             :eof
                lda             []TxtPtr],y                 ;get a char
                and             #$7F
                cmp             #8                          ;tabs = spaces
                beq             ]loop
                cmp             #' '                        ;must be a space or greater
                blt             :xit
                beq             ]loop                       ;flush spaces
                sty             ]BegWord
]loop
                iny
                cpy             ]maxlen                     ;past eof?
                bge             :eof
                lda             []TxtPtr],y                 ;get a char
                and             #$7F
                cmp             #' '+1                      ;skip to next space or EOL
                bge             ]loop
                sty             ]EndWord
                lda             #0
                bra             :xit                        ;skip error
:eof
                lda             #qaeof                      ;reached EOF!
:xit
                tax
                lda             ]rtl+4
                sta             ]newstack+4
                lda             ]rtl+2
                sta             ]newstack+2
                lda             ]rtl
                sta             ]newstack
                plb
                pld
                tsc
                clc
                adc             #]newstack
                tcs
                txa
                brl             errxit

*======================================================
* Find the end of the current line of text (EOL)
* ENTRY: Pointer to text, current index , max length (64K)
*  EXIT: Index to start of next line (BCS = reached EOF)

QANextLine
                dum             $00
]rtl            ds              6                           ;these are passed on stack
]maxlen         ds              2                           ;max length of text
]index          ds              2                           ;starting index in text
]TxtPtr         ds              4                           ;pointer to text
]newstack       =               *-6                         ;must be at end of passed parms
]newline        ds              2                           ;start of word (index into text)
                dend

                mx              %00
                tsc
                phd
                inc
                tcd
                phb
                phk
                plb
                dec             ]maxlen

                ldy             ]index                      ;get index into text
                dey
]loop
                iny
                cpy             ]maxlen                     ;past eof?
                bge             :eof
                lda             []TxtPtr],y                 ;get a char
                and             #$7F
                cmp             #8                          ;tabs = spaces
                beq             ]loop
                cmp             #' '                        ;must be a space or greater
                bge             ]loop
                iny
                sty             ]newline                    ;save index to start of next line
                lda             #0
                bra             :xit
:eof
                lda             #qaeof                      ;reached EOF!
:xit
                tax
                lda             ]rtl+4
                sta             ]newstack+4
                lda             ]rtl+2
                sta             ]newstack+2
                lda             ]rtl
                sta             ]newstack
                plb
                pld
                tsc
                clc
                adc             #]newstack
                tcs
                txa
                brl             errxit

