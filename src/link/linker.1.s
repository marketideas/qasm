

link            php
                rep       $30
                stz       cancelflag
                sty       filehandle+2
                stx       filehandle
                pha
                pha
                phy
                phx
                _GetHandleSize
                plx
                ply
                jcs       :err

                stx       filelen
                sty       filelen+2

                ldy       #$04
                lda       [filehandle],y
                and       #$7fff                    ;
                sta       [filehandle],y

                jsr       :getmemory
                jcs       :err

                ldy       #$04
                lda       [filehandle],y
                ora       #$8000
                sta       [filehandle],y


                jsl       linker
                bcc       :noerr
                jmp       :err
:noerr          jsr       :disposemem
                rep       $30
                lda       #$00
                plp
                clc
                rtl
:err            rep       $30
                sta       :errcode
                jsr       :disposemem
                plp
                lda       :errcode
                sec
                rtl
:errcode        ds        2

:getmemory      clc
                rts

:disposemem     php
                rep       $30
                lda       userid
                ora       #linkmemid
                pha
                _DisposeAll
                lda       userid
                ora       #linkmemid+$100
                pha
                _DisposeAll
                lda       userid
                ora       #linkmemid+$200
                pha
                _DisposeAll

:dxit           plp
                rts

prodoserr       ds        2
ovrflag         ds        2
ovrallflag      ds        2
info            adrl      asmpath
                ds        2
ftype           ds        2
aux             ds        4
                ds        14


linker          php
                rep       $30
                jsr       initvars
                psl       #$00
                psl       #$10000+$8                ;8 bytes for relocation overflow
                lda       userid
                ora       #linkmemid
                pha
                pea       $8000
                psl       #$00
                _NewHandle
                plx
                ply
                jcs       :memerr
                txa
                sta       linksymhdl
                tya
                sta       linksymhdl+2

                psl       #$00
                psl       #maxlinklab*4
                ldal      userid
                ora       #linkmemid
                pha
                pea       $8000
                psl       #$00
                _NewHandle
                plx
                ply
                jcs       :memerr
                sty       globalhdl+2
                sty       workspace+2
                stx       globalhdl
                stx       workspace
                ldy       #$02
                lda       [workspace]
                sta       lableptr1
                lda       [workspace],y
                sta       lableptr1+2
                lda       #$ffff
                sta       lablect
                jsr       inclablect
                bcs       :memerr
                jsr       newsegment
                bcs       :memerr
                jmp       :ready
:memerr         rep       $30
                pha
                jsr       disposemem
                pla
                plp
                sec
                rtl
:ready          rep       $30
                _QAInitTotalErrs
:passloop       rep       $30
                stz       linkaddress
                stz       linkaddress+$2
                stz       ovrflag
                stz       ovrallflag
                stz       prodoserr
                stz       savcount
                stz       linenum
                stz       domask
                stz       dolevel
                stz       modeflag
                lda       #$01
                sta       segnum

                ldy       #$02
                lda       [filehandle]
                sta       fileptr
                lda       [filehandle],y
                sta       fileptr+$2
                lda       filelen
                sta       flen
                lda       filelen+$2
                sta       flen+$2
                stz       doneflag
                lda       flen
                ora       flen+$2
                bne       :loop
                jmp       :done                     ;if file is 0 bytes

:loop           rep       $30
                pea       0
                _QAGetCancelFlag
                pla
                beq       :n
                lda       #$ffff
                sta       cancelflag
:n              lda       numfiles
                cmp       #maxfiles
                blt       :loop1
                lda       #maxfileserr
                jmp       :lineerr
:loop1          ldy       #$00
                sty       linebuff
                jsr       readkey
                bcc       :bit
                and       #$7f
                cmp       #$1b
                jeq       :xitclc
                cmp       #'C'&$1f
                jeq       :xitclc
:bit            bit       cancelflag
                jmi       :xitclc
                lda       doneflag
                beq       :sep
                jmp       :done
:sep            sep       $30
                ldy       #$00
                tyx
]getline        lda       [fileptr],y
                phx
                tax
                ldal      converttable,x
                plx
                sta       linebuff+$1,x
                bit       quicklink
                bpl       :iny
                cmp       #']'
                bne       :iny
                pha
                phy
                iny
                lda       [fileptr],y
                and       #$7f
                cmp       #'1'
                beq       :path
                cmp       #'2'
                beq       :object
                cmp       #'3'
                bne       :iply
                bra       :object1
:path           lda       [subtype]
                beq       :iply
                ldy       #$01
]n              lda       [subtype],y
                sta       linebuff+1,x
                iny
                inx
                tya
                cmp       [subtype]
                blt       ]n
                beq       ]n
                dex
                lda       1,s
                inc
                sta       1,s
                bra       :iply
:object1        lda       #$02
                sta       :sbc+1
                bra       :p1
:object         lda       #$00
                sta       :sbc+1
:p1             phx
                rep       $30
                psl       #asmpath
                _QAGetObjPath
                sep       $30
                plx
                lda       asmpath
                beq       :iply
                sec
:sbc            sbc       #$00
                bcc       :iply
                sta       asmpath
                ldy       #$01
]n              lda       asmpath,y
                sta       linebuff+1,x
                iny
                inx
                cpy       asmpath
                blt       ]n
                beq       ]n
                dex
                lda       1,s
                inc
                sta       1,s
:iply           ply
                pla
:iny            iny
                inx
                cmp       #$0D
                beq       :parsed
:cpy            cpx       #80
                jlt       ]getline
                lda       #$0D
                sta       linebuff+$1,x
                rep       $10
]eoln           lda       [fileptr],y
                iny
                and       #$7F
                cmp       #$0D
                bne       ]eoln
:parsed         rep       $30
                txa
                cmp       #80
                blt       :stalen
                lda       #80
:stalen         sep       $20
                sta       linebuff
                sta       linelen
                rep       $30
                tya
                sta       zpage
                clc
                adc       fileptr
                sta       fileptr
                lda       #$00
                adc       fileptr+$2
                sta       fileptr+$2
                lda       flen
                sec
                sbc       zpage
                sta       flen
                lda       #$00
                sbc       flen+$2
                sta       flen+$2
                bcc       :fdone
                lda       flen
                ora       flen+$2
                bne       :doline
:fdone          lda       #$FFFF
                sta       doneflag
:doline         inc       linenum
                jsr       linkline
                bcs       :lineerr
                jmp       :loop                     ;do another line
:done           rep       $30
                bit       passnum
                bmi       :xitclc
                sec
                ror       passnum
                jmp       :passloop
:lineerr        pha
                jsr       linkerror
                pla
                tax
                and       #$80
                jeq       :loop
                txa
* jmp :xit
:xitclc         rep       $30
                lda       #$00
:xit            rep       $30
                pha
                bit       outfileopen
                bpl       :x3
                lda       1,s
                cmp       #$00
                bne       :close
                jsr       writejmpseg
                bcc       :close
                sta       1,s
:close          jsl       prodos
                dw        $14
                adrl      closefile
:x3             pea       0
                _QAGetTotalErrs
                pla
                sta       totalerrs
                bit       cancelflag
                bmi       :x5
                lda       totalerrs
                bne       :x4
                lda       #$0d
                jsr       drawchar
                jsr       express
                jsr       writerez
                lda       totalbytes
                ora       totalbytes+2
                beq       :xnosave
                lda       linkversion
                beq       :x4
                psl       #filename
                _QADrawString
                psl       #:savstr
                _QADrawString
                jmp       :savout
:xnosave        psl       #:nosavstr
                _QADrawString
:savout         lda       #$0d
                jsr       drawchar
:x4             jsr       showendstr
:x5             jsr       disposemem
                rep       $30
                lda       cancelflag
                beq       :x6
                pea       $ffff
                _QASetCancelflag
:x6             pla
                plp
                cmpl      :one
                rtl

:one            dw        $01
:doneflag       ds        2
:savstr         str       ' saved.'
:nosavstr       str       'No object code saved.'

doneflag        ds        2
linelen         ds        2
linebuff        ds        128,0
opcode          ds        36,0
opcodeword      ds        2
jsrptr          ds        2

linkline        php
                rep       $30
                ldy       #$00
                ldx       #$00
                sep       $20
                stz       newlable
                lda       linebuff
                jeq       :done
                lda       linebuff+1
                and       #$7f
                cmp       #'*'
                jeq       :done
                cmp       #';'
                jeq       :done
                cmp       #' '
                blt       :done
                beq       :ldy
                sta       newlable+1
                ldy       #$01
                ldx       #$01
]lup            iny
                lda       linebuff,y
                and       #$7f
                cmp       #' '
                blt       :done
                beq       :lable
                cpx       #lab_size
                bge       :nosta
                sta       newlable+1,x
:nosta          inx
                jmp       ]lup
:lable          txa
                cmp       #lab_size
                blt       :l1
                lda       #lab_size
:l1             sta       newlable
                jmp       :op

:ldy            ldy       #$01
:op
]lup            lda       linebuff,y
                iny
                and       #$7f
                cmp       #';'
                beq       :done
                cmp       #' '
                blt       :done
                beq       ]lup

                rep       $20
                dey
                tyx
                jsr       getopcode
                bcc       :done
:err            plp
                sec
                rts
:done           plp
                clc
                rts

getopcode
                php
                rep       $30
                lda       #$ffff
                sta       jsrptr
                stz       opcode
                stz       opcodeword
                sep       $20
]lup            cpx       linelen
                blt       :get
                beq       :get
                jmp       :noop
:get            lda       linebuff,x
                and       #$7F
                inx
                cmp       #' '
                beq       ]lup
                cmp       #$0D
                beq       :noop
                cmp       #';'
                beq       :noop
                jmp       :doop
:noop           rep       $30
                lda       #$00
                plp
                clc
                rts
:doop           rep       $30
                dex
                ldy       #$00
]lup            lda       linebuff,x
                and       #$7F
                cmp       #' '+$1
                blt       :done
                cmp       #';'
                beq       :done
                cpy       #32
                bge       :phx
                ora       #$2000                    ;high byte
                sta       opcode+$1,Y
:phx            inx
                iny
                cpx       linelen
                blt       ]lup
                beq       ]lup
                dex
:done           lda       #$2020                    ;truncate to 3 bytes max
                sta       opcode+$1,Y
                sta       opcode+4
                tya
                sep       $20
                cmp       #4
                bcc       :3
                lda       #3
:3              sta       opcode
]flush          lda       linebuff,x
                cmp       #' '
                bne       :tya
                inx
                bra       ]flush
:tya            rep       $30
                txa
                clc
                adc       #linebuff
                sta       lineptr
                jsr       doopcodes
                bcc       :op                       ;if invalid check macros
                jmp       :err
:op             sta       opcodeword
                ldy       #tblend
                jsr       chkops
                bcs       :err
:enter          clc
                lda       jsrptr
                sta       :jsr+$1
                lda       #doflag
                bit       modeflag
                beq       :jsr
                lda       opcodeword
                hex       c9
                usr       'DO  '
                beq       :jsr
                hex       c9
                usr       'FIN '
                beq       :jsr
                hex       c9
                usr       'ELS '
                bne       :noerr
:jsr            jsr       $FFFF
:errchk         bcs       :operr
                jmp       :noerr
:operr          plp
                sec
                rts
:noerr          lda       #$00
                plp
                clc
                rts
:err            rep       $30
                lda       #syntax
:errout         plp
                cmpl      :one
                rts
:one            dw        $01



doopcodes

]op             equ       workspace

                php
                rep       $30
                lda       opcode
                and       #$00FF
                beq       :bad
                cmp       #$05
                blt       :stz
:bad            lda       #syntax
                plp
                sec
                rts
:stz            lda       opcode+$1
                xba
                sep       $30
                asl
                asl
                asl
                rep       $20
                asl
                asl
                asl
                sta       ]op
                lda       opcode+$4
                and       #$5F5F
                tax
                beq       :clc
                cmp       #'K'
                beq       :rep
:clc            clc
:rep            rep       $30
                lda       opcode+$3
                and       #$1F
                rol
                tsb       ]op
                lda       ]op
                plp
                clc
                rts


chkops          rep       $30
                lda       opcodeword
:find           dey
                dey
                dey
                dey
                dey
                dey
                cmp       $0000,Y
                bcc       :find
                bne       :rts
                lda       $0002,Y
                sta       jsrptr
                cmp       #$FFFF
:rts            rts

                mx        %00
cmdop           php
                rep       $30
                ldy       #$00
                sep       $20
]lup            lda       (lineptr),y
                and       #$7f
                cmp       #' '
                blt       :done
                sta       tempbuff+1,y
                iny
                bra       ]lup
:done           lda       #$0d
                sta       tempbuff+1,y
                iny
                tya
                sta       tempbuff
                rep       $30
                pha
                pha
                psl       #tempbuff
                _QAParseCmdLine
                plx
                stx       :type
                plx
                stx       :id
                bcs       :error
                lda       :type
                cmp       #$03                      ;internal command?
                beq       :exec
                cmp       #$04                      ;external command?
                bne       :bad
:exec           lda       :type
                pha
                lda       :id
                pha
                _QAExecCommand
                bcs       :error
                lda       #$00
:error          cmp       #$00
                beq       :clc
:bad            lda       #badcmd
                plp
                sec
                rts
:clc            plp
                clc
                rts
:type           ds        2
:id             ds        2

                mx        %00
doop            stz       lvalue
                stz       lvalue+2
                lda       domask
                bpl       :ok
                lda       #nesterror
                sec
                rts
:ok             lda       dolevel
                bne       :set
                jsr       checkdo
                bcc       :set
                ldx       #$00
                jsr       eval
                bcc       :set
                cmp       #undeflable
                bne       :err
                lda       #forwardref
:err            sec
                rts
:set            lda       domask
                bne       :shift0
:shift1         sec
                rol       domask
                jmp       :test
:shift0         asl       domask
:test           lda       lvalue
                ora       lvalue+2
                beq       :dooff
                lda       domask
                trb       dolevel
                jmp       condout
:dooff          lda       domask
                tsb       dolevel
                jmp       condout

elsop           lda       domask
                eor       dolevel
                sta       dolevel
                jmp       condout

finop           lda       domask
                trb       dolevel
                lsr       domask
                jmp       condout

condout         lda       dolevel
                beq       :on
                lda       #doflag
                tsb       modeflag
                bra       :clc
:on             lda       #doflag
                trb       modeflag
:clc            clc
                rts

checkdo         php
                rep       $30
                stz       lvalue
                stz       lvalue+2
                sep       $20
                ldy       #$00
]lup            lda       (lineptr),y
                and       #$7f
                cmp       #' '
                jlt       :sec
                bne       :first
                iny
                bra       ]lup
:first          and       #$5f
                cmp       #'P'
                beq       :pass
                cmp       #'E'
                jne       :sec
:chkerr         iny
                lda       (lineptr),y
                and       #$5f
                cmp       #'R'
                jne       :sec
                iny
                lda       (lineptr),y
                and       #$5f
                cmp       #'R'
                jne       :sec
                iny
                lda       (lineptr),y
                and       #$7f
                cmp       #' '+1
                jge       :sec
                rep       $30
                pea       0
                _QAReadTotalErrs
                pla
                sta       lvalue
                jmp       :clc

                mx        %10
:pass           iny
                lda       (lineptr),y
                and       #$5f
                cmp       #'A'
                bne       :sec
                iny
                lda       (lineptr),y
                and       #$5f
                cmp       #'S'
                bne       :sec
                iny
                lda       (lineptr),y
                and       #$5f
                cmp       #'S'
                bne       :sec
                iny
                lda       (lineptr),y
                and       #$7f
                cmp       #' '+1
                bge       :sec
                lda       passnum+1                 ;we're in 8 bit A here
                bne       :2
                lda       #$00
                sta       lvalue
                jmp       :clc
:2              lda       #$01
                sta       lvalue
                jmp       :clc
:sec            plp
                sec
                rts
:clc            plp
                clc
                rts
                mx        %00

optbl           dw        $0000,$FFFF,$FFFF
                opc       'ADR ';adrop;0
                opc       'ALI ';aliop;0
                opc       'ASM ';asmop;0
                opc       'AUX ';adrop;0
* opc 'BRK ';brkop;0
                opc       'CMD ';cmdop;0
                opc       'DAT ';datop;0
                opc       'DO  ';doop;0
                opc       'DS  ';dsop;0
                opc       'ELS ';elsop;0
                opc       'END ';endop;0
                opc       'ENT ';entop;0
                opc       'EQU ';equop;0
                opc       'EXT ';extop;0
                opc       'FAS ';rtsop;0
                opc       'FIN ';finop;0
                opc       'GEQ ';geqop;0
                opc       'IF  ';ifop;0
                opc       'IMP ';impop;0
                opc       'KBD ';kbdop;0
                opc       'KIN ';kndop;0
                opc       'KND ';kndop;0
                opc       'LEN ';lenop;0
* opc 'LIB ';libop;0
                opc       'LIN ';lnkop;0
                opc       'LKV ';lkvop;0
                opc       'LNK ';lnkop;0
                opc       'NOL ';nolop;0
                opc       'ORG ';orgop;0
                opc       'OVR ';ovrop;0
                opc       'PFX ';pfxop;0
                opc       'POS ';posop;0
                opc       'PUT ';putop;0
                opc       'REZ ';rezop;0
                opc       'SAV ';savop;0
                opc       'TYP ';typop;0
                opc       'VER ';verop;0
                opc       'ZIP ';zipop;0
                opc       '=   ';equ1op;0
tblend          dw        $FFFF,$FFFF,$FFFF
                mx        %00

rtsop           clc
                rts

asmop           bit       passnum
                bpl       :pass0
                clc
                rts
:pass0          bit       lnkflag
                bpl       :pass00
                lda       #badasmcmd
                sec
                rts
:pass00         rep       $30
                jsr       purgeasm
                jsr       getglobals
                bcc       :d1
                rts
:d1             lda       #$FFFF
                jsr       getpath
                bcc       :setmode
                rts
:setmode        stz       :errcode
                lda       ovrflag
                ora       ovrallflag
                bne       :doit

                jsl       prodos
                dw        $06
                adrl      info
                jcs       :doserr
                lda       ftype
                cmp       #$04
                jne       :mismatch
                lda       aux
                and       #$01
                jne       :clc
                lda       aux
                ora       #$01
                sta       aux
                jsl       prodos
                dw        $05
                adrl      info
:doit           lda       asmlablect
                sta       linksymnum
                lda       asmnextlable
                sta       linknextlbl
                lda       asmnextlable+2
                sta       linknextlbl+2

                psl       linksymtbl
                psl       linksymhdl
                lda       asmlablect
                pha
                psl       asmnextlable
                _QASetSymTable

                lda       linktype
                pha
                _QASetObjType
                stz       :errcode
                psl       #asmpath
                _QASetPath
                pea       #afromname
                psl       #$00
                _QACompile
                php
                pha
                psl       #$00
                psl       #$00
                pea       0
                psl       #$00
                _QASetSymTable
                pla
                plp
                tay
                bcc       :kq
                cpy       #$0000
                beq       :kq
                sty       prodoserr
                lda       #doserror
                sta       :errcode
:kq             pea       0
                _QAGetObjType
                pla
                sta       linktype
                jsr       purgeasm
                lda       :errcode
:memerr         rep       $30
                pha
                lda       #$00
                sta       asmpath
                sta       ovrflag
                pla
                jmp       :err
:doserr         sta       prodoserr
                stz       asmpath
                stz       ovrflag
                lda       #doserror
:err            cmpl      :one
                rts
:one            dw        $01
:clc            rep       $30
                lda       #$00
                sta       asmpath
                sta       ovrflag
                clc
                rts
:mismatch       lda       #$00
                sta       asmpath
                sta       ovrflag
                lda       #mismatch
                sta       prodoserr
                lda       #doserror
                sec
                rts
:errcode        ds        2

                mx        %00
entop           lda       passnum
                bne       :ok
                clc
                rts
:ok             psl       #:str
                _QADrawString
                lda       #$03                      ;show entries
                jsr       traverse
                rep       $31
                rts
:str            str       0d,'Entry Labels:',0d,0d

                mx        %00
datop           lda       passnum
                bne       :ok
                clc
                rts
:ok             psl       #:date+1
                _ReadAsciiTime
                psl       #:date
                _QADrawString
                lda       #$0d
                jsr       drawchar
                clc
                rts
:date           dfb       20
                ds        20,0
                mx        %00

endop           lda       #$ffff
                sta       doneflag
                clc
                rts

equop           bit       passnum
                bpl       :equ
                clc
                rts
:equ            ldx       #$00
                jsr       eval
                bcc       :ok
                rts
:ok             lda       lvalue
                sta       labval
                lda       lvalue+2
                sta       labval+2
                lda       newlable
                and       #$ff
                beq       :badlable
                cmp       #lab_size
                blt       :tx1
                lda       #lab_size
:tx1            tax
                sep       $20
                sta       labstr
]lup            lda       newlable,x
                sta       labstr,x
                dex
                bne       ]lup
                lda       newlable+1
                and       #$7f
                cmp       #':'+1
                blt       :badlable
                cmp       #']'
                beq       :badlable
                rep       $20
                lda       #linkequbit.linkequvalid
                jsr       insertlable
                rts
:badlable       rep       $30
                lda       #badlable.$80
                sec
                rts

equ1op          bit       passnum
                bpl       :equ
                clc
                rts
:equ            ldx       #$00
                jsr       eval
                bcc       :ok
                rts
:ok             lda       lvalue
                sta       labval
                lda       lvalue+2
                sta       labval+2
                lda       newlable
                and       #$ff
                beq       :badlable
                cmp       #lab_size
                blt       :tx1
                lda       #lab_size
:tx1
                tax
                sep       $20
                sta       labstr
]lup            lda       newlable,x
                sta       labstr,x
                dex
                bne       ]lup
                lda       newlable+1
                and       #$7f
                cmp       #':'+1
                blt       :badlable
                cmp       #']'
                beq       :badlable
                rep       $20
                lda       #linkequ1bit
                jsr       insertlable
                rts
:badlable       rep       $30
                lda       #badlable.$80
                sec
                rts

zipop           lda       passnum
                beq       :ok
                clc
                rts
:ok             lda       lnkflag
                beq       :ok1
                lda       #illegalcmd
                sec
                rts
:ok1            sec
                ror       zipflag
* jsr newsegment
                clc
                rts                                 ;return error from newsegment

posop                                               ;I don't know what these do
lenop           clc                                 ;or how Merlin uses them so....?????
                rts

extop           bit       passnum
                bpl       :equ
                clc
                rts
:equ            lda       newlable
                and       #$ff
                bne       :equ1
                clc
                rts
:equ1           clc
                rts
                do        0
                ldx       #$00
                jsr       eval
                bcc       :ok
                rts
:ok             lda       lvalue
                sta       labval
                lda       lvalue+2
                sta       labval+2
                lda       newlable
                and       #$ff
                beq       :badlable
                cmp       #lab_size
                blt       :tx1
                lda       #lab_size
:tx1
                tax
                sep       $20
                sta       labstr
]lup            lda       newlable,x
                sta       labstr,x
                dex
                bne       ]lup
                lda       newlable+1
                and       #$7f
                cmp       #':'+1
                blt       :badlable
                cmp       #']'
                beq       :badlable
                rep       $20
                lda       #linkgeqbit
                jsr       insertlable
                rts
:badlable       rep       $30
                lda       #badlable.$80
                sec
                rts
                fin

geqop           bit       passnum
                bpl       :equ
                clc
                rts
:equ            ldx       #$00
                jsr       eval
                bcc       :ok
                rts
:ok             lda       lvalue
                sta       labval
                lda       lvalue+2
                sta       labval+2
                lda       newlable
                and       #$ff
                beq       :badlable
                cmp       #lab_size
                blt       :tx1
                lda       #lab_size
:tx1
                tax
                sep       $20
                sta       labstr
]lup            lda       newlable,x
                sta       labstr,x
                dex
                bne       ]lup
                lda       newlable+1
                and       #$7f
                cmp       #':'+1
                blt       :badlable
                cmp       #']'
                beq       :badlable
                rep       $20
                lda       #linkgeqbit
                jsr       insertlable
                rts
:badlable       rep       $30
                lda       #badlable.$80
                sec
                rts

kbdop           bit       passnum
                bpl       :equ
                clc
                rts
:equ            ldx       #$00
                jsr       eval
                bcc       :ok
                rts
:ok             lda       lvalue
                sta       labval
                lda       lvalue+2
                sta       labval+2
                lda       newlable
                and       #$ff
                beq       :badlable
                cmp       #lab_size
                blt       :tx1
                lda       #lab_size
:tx1
                tax
                sep       $20
                sta       labstr
]lup            lda       newlable,x
                sta       labstr,x
                dex
                bne       ]lup
                lda       newlable+1
                and       #$7f
                cmp       #':'+1
                blt       :badlable
                cmp       #']'
                beq       :badlable
                rep       $20
                lda       #linkgeqbit
                jsr       insertlable
                rts
:badlable       rep       $30
                lda       #badlable.$80
                sec
                rts


dsop            lda       passnum
                bne       :clc
                ldx       #$00
                jsr       eval
                bcc       :ok
                rts
:clc            clc
                rts
:ok             lda       segmenthdl+2
                sta       segmentptr+2
                lda       segmenthdl
                sta       segmentptr
                ldy       #$02
                lda       [segmentptr]
                tax
                lda       [segmentptr],y
                sta       segmentptr+2
                stx       segmentptr
                lda       segnum
                asl
                asl
                asl
                asl
                asl
                asl
                clc
                adc       #dsfield
                tay
                lda       lvalue
                sta       [segmentptr],y
                iny
                iny
                lda       lvalue+2
                sta       [segmentptr],y
                clc
                rts


kndop           lda       passnum
                bne       :clc
                ldx       #$00
                jsr       eval
                bcc       :ok
                rts
:clc            clc
                rts
:ok             lda       segmenthdl+2
                sta       segmentptr+2
                lda       segmenthdl
                sta       segmentptr
                ldy       #$02
                lda       [segmentptr]
                tax
                lda       [segmentptr],y
                sta       segmentptr+2
                stx       segmentptr
                lda       segnum
                asl
                asl
                asl
                asl
                asl
                asl
                clc
                adc       #kindfield
                tay
                lda       lvalue
                ldx       omfversion
                cpx       #$01
                bne       :omf2
                and       #$ff
:omf2           sta       [segmentptr],y
                clc
                rts

aliop           lda       passnum
                bne       :clc
                ldx       #$00
                jsr       eval
                bcc       :ok
                rts
:clc            clc
                rts
:ok             lda       lvalue
                beq       :10000
                cmp       #$100
                beq       :100
:bad            lda       #badalignop
                sec
                rts
:10000          lda       lvalue+2
                cmp       #$0001
                bne       :bad
                jmp       :ok1
:100            lda       lvalue+2
                bne       :bad
:ok1            lda       segmenthdl+2
                sta       segmentptr+2
                lda       segmenthdl
                sta       segmentptr
                ldy       #$02
                lda       [segmentptr]
                tax
                lda       [segmentptr],y
                sta       segmentptr+2
                stx       segmentptr
                lda       segnum
                asl
                asl
                asl
                asl
                asl
                asl
                clc
                adc       #alignfield
                tay
                lda       lvalue
                sta       [segmentptr],y
                iny
                iny
                lda       lvalue+2
                sta       [segmentptr],y
                clc
                rts



libop           clc
                rts

                mx        %00
impop           sec
                ror       lnkflag
                bit       passnum
                bpl       :pass0
                clc
                rts
:pass0          rep       $30
                lda       #$00
                jsr       getpath
                bcc       :setmode
                rts
:setmode        jsl       prodos
                dw        $06
                adrl      info
                jcs       :doserr
                lda       ftype
                cmp       #$f8
                jeq       :mismatch                 ;can't import REL files

                psl       #:str
                _QADrawString
                psl       #asmpath
                _QADrawString
                lda       #$0d
                jsr       drawchar
                lda       aux
                sta       :aux
                psl       #$00
                psl       #asmpath
                psl       #$00                      ;filepos
                psl       #-1                       ;whole file
                psl       #:alltypes
                lda       userid
                ora       #linkmemid
                pha
                psl       #$00
                pea       $8000
                _QALoadfile
                plx
                ply
                jcs       :doserr
                lda       numfiles
                asl
                asl
                asl
                asl
                asl
                phx
                tax
                stx       :offset
                pla
                sta       files,x
                sta       :handle
                tya
                sta       files+2,x
                sta       :handle+2
                psl       #$00
                psl       :handle
                _GetHandleSize
                pll       :aux
                lda       :aux+2
                jne       :toolarge
                lda       :aux
                cmp       #$FFFE
                jge       :toolarge
                inc       :aux
                inc       :aux
                psl       :handle
                _HUnlock
                psl       :aux
                psl       :handle
                _SetHandleSize
                jcs       :doserr
                psl       :handle
                _HLock
                dec       :aux
                dec       :aux
                lda       :handle
                sta       workspace
                lda       :handle+2
                sta       workspace+2
                ldy       #$02
                lda       [workspace]
                tax
                lda       [workspace],y
                sta       workspace+2
                stx       workspace

                lda       #$00
                ldy       :aux
                sta       [workspace],y

                ldx       :offset
                lda       reloffset
                sta       files+4,x
                lda       reloffset+2
                sta       files+6,x
                lda       :aux
                sta       files+8,x
                lda       segnum
                sta       files+10,x
                psl       :handle
                _HLock
                lda       :aux
                clc
                adc       reloffset
                sta       :rel
                lda       #$00
                adc       reloffset+2
                sta       :rel+2
:b              jsr       :makeentry
                bcc       :r1
                jmp       :err
:r1             rep       $30
                php
                pha
                inc       numfiles
                lda       :aux
                clc
                adc       reloffset
                sta       reloffset
                lda       #$00
                adc       reloffset+2
                sta       reloffset+2
:l              psl       :handle
                _HUnlock
                lda       #$00
                sta       asmpath
                pla
                plp
                rts
:memerr         rep       $30
                jmp       :doserr
:none           rep       $30
                lda       #$00
                sta       asmpath
                clc
                rts
:mismatch       rep       $30
                lda       #$00
                sta       asmpath
                lda       #mismatch
                sta       prodoserr
                lda       #doserror
                sec
                rts
:toolarge       rep       $30
                lda       #filetoolarge
                jmp       :err
:doserr         rep       $30
                sta       prodoserr
                lda       #$00
                sta       asmpath
                lda       #doserror
:err            sec
                rts
:aux            ds        4
:rel            ds        4
:handle         ds        4
:offset         ds        2
:str            str       'Importing File: '
:alltypes       hex       00

:makeentry      php
                sep       $30
                ldx       asmpath
                lda       asmpath,x
                and       #$7f
                cmp       #':'
                bne       :loop1
                dex
:loop1          lda       asmpath,x
                and       #$7f
                cmp       #':'
                beq       :end
                dex
                bne       :loop1
:end            inx
                txy
                ldx       #$00
:loop2          lda       asmpath,y
                and       #$7f
                cmp       #':'
                beq       :set
                cpx       #lab_size+1
                bge       :inx
                cmp       #'.'
                bne       :sta
                lda       #'_'
:sta            sta       labstr+1,x
:inx            inx
                iny
                cpy       asmpath
                blt       :loop2
                beq       :loop2
:set            txa
                cmp       #lab_size
                blt       :set1
                lda       #lab_size
:set1           sta       labstr
                rep       $30
                lda       reloffset
                sta       labval
                lda       reloffset+2
                sta       labval+2
                lda       #linkentrybit
                jsr       insertlable
                bcs       :sec
                ldy       #o_lablocal
                lda       segnum
                sta       [lableptr],y
                plp
                clc
                rts
:sec            plp
                sec
                rts

                mx        %00
lnkop           sec
                ror       lnkflag
                bit       passnum
                bpl       :pass0
                clc
                rts
:pass0          rep       $30
                stz       :errvalid
                stz       :erraddress
                stz       :erraddress+2
                stz       :dsvalid

                lda       #$00
                jsr       getpath
                bcc       :setmode
                rts
:setmode        jsl       prodos
                dw        $06
                adrl      info
                jcs       :doserr
                lda       ftype
                cmp       #$f8
                jne       :mismatch

                psl       #:str
                _QADrawString
                psl       #asmpath
                _QADrawString
                lda       #$0d
                jsr       drawchar
                lda       aux
                sta       :aux

                psl       #$00
                psl       #asmpath
                psl       #$00                      ;filepos
                psl       #-1                       ;whole file
                psl       #lnktype
                lda       userid
                ora       #linkmemid
                pha
                psl       #$00
                pea       $8000
                _QALoadfile
                plx
                ply
                jcs       :doserr



                lda       numfiles
                asl
                asl
                asl
                asl
                asl
                phx
                tax
                stx       :offset
                pla
                sta       files,x
                sta       :handle
                tya
                sta       files+2,x
                sta       :handle+2
                lda       reloffset
                sta       files+4,x
                lda       reloffset+2
                sta       files+6,x
                lda       :aux
                sta       files+8,x
                lda       segnum
                sta       files+10,x
                psl       :handle
                _HLock
                lda       :aux
                clc
                adc       reloffset
                sta       :rel
                lda       #$00
                adc       reloffset+2
                sta       :rel+2
                jsr       :dsfill
                bcc       :b
                jmp       :err
:b              jsr       buildentries
                rep       $30
                php
                pha
                inc       numfiles
                lda       :aux
                clc
                adc       reloffset
                sta       reloffset
                lda       #$00
                adc       reloffset+2
                sta       reloffset+2
                bit       :errvalid
                bpl       :l
                lda       :rel+2
                cmp       :erraddress+2
                blt       :l
                bne       :constr
                lda       :rel
                cmp       :erraddress
                blt       :l
                beq       :l
:constr         jsr       :constrainterr
                lda       #constraint
                sta       1,s
                lda       #$01
                lda       3,s
                ora       #$01
                sta       3,s
:l              psl       :handle
                _HUnlock
                lda       #$00
                sta       asmpath
                pla
                plp
                rts
:memerr         rep       $30
                jmp       :doserr
:none           rep       $30
                lda       #$00
                sta       asmpath
                clc
                rts
:mismatch       rep       $30
                lda       #$00
                sta       asmpath
                lda       #mismatch
                sta       prodoserr
                lda       #doserror
                sec
                rts
:doserr         rep       $30
                sta       prodoserr
                lda       #$00
                sta       asmpath
                lda       #doserror
:err            sec
                rts

:aux            ds        2
:rel            ds        4
:handle         ds        4
:offset         ds        2
:str            str       'Loading File: '
:dsvalid        ds        2
:errvalid       ds        2
:erraddress     ds        4
:dsy            ds        2

:dsfill         php
                rep       $30
                stz       :dsvalid
                stz       :errvalid
                lda       :handle
                sta       workspace
                lda       :handle+2
                sta       workspace+2
                ldy       #$02
                lda       [workspace]
                tax
                lda       [workspace],y
                sta       workspace+2
                stx       workspace
                lda       :aux
                clc
                adc       workspace
                sta       workspace
                bcc       :1
                inc       workspace+2
:1              ldy       #$00
:loop           lda       [workspace],y
                and       #$f0
                beq       :check
                cmp       #$f0
                jeq       :8
                cmp       #%11000000                ;DS?
                beq       :ds
                cmp       #%11100000                ;ERR?
                beq       :dserr
                jmp       :4
:ds             bit       :dsvalid
                jmi       :4
                sty       :dsy
                sec
                ror       :dsvalid
                jmp       :4
:dserr          iny
                lda       [workspace],y
                sta       :temp
                iny
                iny
                lda       [workspace],y
                and       #$ff
                sta       :temp+2
                bit       :errvalid
                bpl       :first
                lda       :erraddress+2
                cmp       :temp+2
                blt       :finy
                bne       :first
                lda       :erraddress
                cmp       :temp
                blt       :finy
:first          sec
                ror       :errvalid
                lda       :temp
                sta       :erraddress
                lda       :temp+2
                sta       :erraddress+2
:finy           iny
                jmp       :loop

:check
                bit       :dsvalid
                jpl       :xit
                ldy       :dsy
                lda       :aux
                and       #$FF
                eor       #$FF
                inc
                cmp       #$100
                blt       :smore
                jmp       :xit
:smore          sta       :more
                iny
                iny
                iny
                lda       [workspace],y
                and       #$ff
                sta       :byte
                psl       :handle
                _HUnlock
                psl       #$00
                psl       :handle
                _GetHandleSize
                pll       :size
                lda       :more
                clc
                adc       :size
                sta       :size
                bcc       :l1
                inc       :size+2
:l1             psl       :size
                psl       :handle
                _SetHandleSize
                php
                pha
                psl       :handle
                _HLock
                pla
                plp
                bcc       :deref
                lda       #baddsop
                plp
                sec
                rts
:deref          lda       :handle
                sta       workspace
                lda       :handle+2
                sta       workspace+2
                ldy       #$02
                lda       [workspace]
                tax
                lda       [workspace],y
                sta       workspace+2
                stx       workspace

                lda       :aux
                clc
                adc       workspace
                sta       :src
                lda       #$00
                adc       workspace+2
                sta       :src+2
                lda       :src
                clc
                adc       :more
                sta       :dest
                lda       :src+2
                adc       #$00
                sta       :dest+2
                psl       :src
                psl       :dest
                pea       $00
                lda       :more
                pha
                _BlockMove
                ldy       :aux
                ldx       #$00
                sep       $20
                lda       :byte
]lup            sta       [workspace],y
                iny
                inx
                cpx       :more
                blt       ]lup
                rep       $20
                jmp       :set
:4              tya
                clc
                adc       #$04
                tay
                jmp       :loop
:8              tya
                clc
                adc       #$08
                tay
                jmp       :loop
:set            lda       :aux
                clc
                adc       :more
                bcc       :fine
                lda       #baddsop
                plp
                sec
                rts
:fine           sta       :aux
                ldx       :offset
                sta       files+8,x
:xit            plp
                clc
                rts
:size           ds        4
:more           ds        2
:src            ds        4
:dest           ds        4
:byte           ds        2
:temp           ds        4

:constrainterr  php
                rep       $30
                pea       0
                _QAGetWindow
                pea       $ffff
                _QASetwindow
                psl       #:cstr
                _QADrawString
                lda       :erraddress+$2
                and       #$ff
                beq       :c1
                jsr       prbyte
:c1             lda       :erraddress
                jsr       prbytel
                psl       #:cstr1
                _QADrawString
                lda       :rel
                sec
                sbc       :erraddress
                sta       :ctemp
                lda       :rel+2
                sbc       :erraddress+2
                sta       :ctemp+2
                and       #$ff
                beq       :c2
                jsr       prbyte
:c2             lda       :ctemp
                jsr       prbytel
                lda       #$0d
                jsr       drawchar
                _QASetWindow
                plp
                rts
:cstr           str       0d,'Constraint at $'
:cstr1          str       '.  Excess = $'
:ctemp          ds        4



buildentries
                php
                rep       $30
                lda       numfiles
                asl
                asl
                asl
                asl
                asl
                tax
                phx
                lda       files+2,x
                sta       tempptr+2
                lda       files,x
                sta       tempptr
                ldy       #$02
                lda       [tempptr]
                tax
                lda       [tempptr],y
                sta       tempptr+2
                stx       tempptr
                plx
                lda       files+4,x
                sta       :offset
                sta       reloffset
                lda       files+6,x
                sta       reloffset+2
                sta       :offset+2

                lda       files+8,x
                clc
                adc       tempptr
                sta       tempptr1
                lda       #$00
                adc       tempptr+2
                sta       tempptr1+2
]lup            lda       [tempptr1]
                and       #$ff
                beq       :syms
                and       #$f0
                cmp       #$f0
                beq       :8
                lda       #$04
                clc
                adc       tempptr1
                sta       tempptr1
                lda       #$00
                adc       tempptr1+2
                sta       tempptr1+2
                jmp       ]lup
:8              lda       #$04
                clc
                adc       tempptr1
                sta       tempptr1
                lda       #$00
                adc       tempptr1+2
                sta       tempptr1+2
                jmp       ]lup
:syms           inc       tempptr1
                bne       :s1
                inc       tempptr1+2
:s1             lda       [tempptr1]
                and       #$ff
                jeq       :done
                pha
                and       #$80
                jne       :next
                lda       1,s
                and       #$40
                jeq       :next                     ;not an entry
                lda       1,s
                and       #%00011111
                inc
                tay
                phy
                lda       [tempptr1],y
                sta       labval
                iny
                iny
                lda       [tempptr1],y
                and       #$00ff
                sta       labval+2
                lda       3,s
                and       #%00100000
                bne       :abs

                lda       labval
                sec
                sbc       #$8000
                sta       labval
                lda       labval+2
                sbc       #$00
                sta       labval+2
                lda       labval
                clc
                adc       :offset
                sta       labval
                lda       labval+2
                adc       :offset+2
                sta       labval+2
                lda       1,s
                tay
                lda       labval
                sta       [tempptr1],y
                iny
                iny
                sep       $20
                lda       labval+2
                sta       [tempptr1],y
                rep       $20
:abs            ply
                lda       1,s
                and       #%00011111
                cmp       #lab_size
                blt       :tx1
                lda       #lab_size
:tx1
                tay
                tax
                sep       $20
                sta       labstr
                beq       :in
]lup            lda       [tempptr1],y
                sta       labstr,x
                dey
                dex
                bne       ]lup
:in             rep       $20
                lda       1,s
                and       #%00100000
                beq       :rel
                lda       #linkentrybit.linkabsbit
                jmp       :ins
:rel            lda       #linkentrybit
:ins            jsr       insertlable
                bcc       :ok2
                plx                                 ;remove junk from stack
                plp
                sec
                rts
:ok2            ldy       #o_lablocal
                lda       segnum
                sta       [lableptr],y
:next           pla
                and       #%00011111
                clc
                adc       #4
                clc
                adc       tempptr1
                sta       tempptr1
                lda       #$00
                adc       tempptr1+2
                sta       tempptr1+2
                jmp       :s1

:done           plp
                clc
                rts

:offset         ds        4

buildfinal
                php
                rep       $30
                bit       cancelflag
                jmi       :cancel
                asl
                asl
                asl
                asl
                asl
                tax
                lda       files+10,x
                cmp       segnum
                beq       :phx
                plp
                clc
                rts
:phx            phx
                lda       files,x
                sta       tempptr
                sta       :handle
                lda       files+2,x
                sta       tempptr+2
                sta       :handle+2
                pha
                lda       tempptr
                pha
                _HLock
                ldy       #$02
                lda       [tempptr]
                tax
                lda       [tempptr],y
                sta       tempptr+2
                stx       tempptr
                plx
                lda       files+4,x
                sta       :offset
                sta       reloffset
                lda       files+6,x
                sta       reloffset+2

                phx
                psl       #:str
                _QADrawString
                lda       reloffset+2
                xba
                and       #$ff
                beq       :l1
                jsr       prbyte
:l1             lda       reloffset+2
                and       #$ff
                beq       :l2
                jsr       prbyte
:l2             lda       reloffset
                jsr       prbytel
                lda       #$a0
                jsr       drawchar
                lda       #$0d
                jsr       drawchar
                plx


                lda       files+8,x
                clc
                adc       tempptr
                sta       tempptr1
                lda       #$00
                adc       tempptr+2
                sta       tempptr1+2
                stz       omfok
                jsr       checkorg
                bcs       :o1
                lda       #$ffff
                sta       omfok
:o1             ldy       #$00
]lup            sep       $20
                lda       [tempptr1],y
                beq       :found
                and       #$f0
                cmp       #$f0
                beq       :81
                rep       $20
                tya
                clc
                adc       #$04
                tay
                jmp       ]lup
:81             rep       $20
                tya
                clc
                adc       #$08
                tay
                jmp       ]lup
:found          rep       $30
                iny
                tya
                clc
                adc       tempptr1
                sta       tempptr2
                lda       tempptr1+2
                adc       #$0
                sta       tempptr2+2
]lup            rep       $30
                bit       cancelflag
                jmi       :cancel
                lda       rellength+2
                beq       :f1
                lda       #relfull
                plp
                sec
                rts
:f1             lda       [tempptr1]
                and       #$ff
                beq       :syms
                tax
                jsr       readkey
                bcc       :tx
                and       #$7f
                cmp       #$1b
                jeq       :cancel
                cmp       #'C'&$1f
                jeq       :cancel
:tx             txa
                pha
                jsr       relocatefinal
                bcc       :pla
                pha
                jsr       linkerror
                pla
:pla            pla
                and       #$f0
                cmp       #$f0
                beq       :8
                lda       #$04
                clc
                adc       tempptr1
                sta       tempptr1
                lda       #$00
                adc       tempptr1+2
                sta       tempptr1+2
                jmp       ]lup
:8              lda       #$04
                clc
                adc       tempptr1
                sta       tempptr1
                lda       #$00
                adc       tempptr1+2
                sta       tempptr1+2
                jmp       ]lup
:cancel         rep       $30
                sec
                ror       cancelflag
:syms           rep       $30
                psl       :handle
                _HUnlock
:done1          rep       $30
                plp
                clc
                rts
:handle         ds        4
:offset         ds        2

:str            str       'Linking at $'

insertomf       php
                rep       $30
                lda       linkversion
                beq       :clc
                bit       omfok
                bpl       :clc
                lda       omflength
                bne       :1
:clc            plp
                clc
                rts
:1              ldy       rellength
                sep       $20
                lda       omfcode
                sta       [relptr],y

                do        omfprint
                phy
                jsr       prbyte
                ply
                fin

                iny
                lda       omfbytes
                sta       [relptr],y

                do        omfprint
                phy
                jsr       prbyte
                ply
                fin

                iny
                lda       omfshift
                sta       [relptr],y

                do        omfprint
                phy
                jsr       prbyte
                lda       #$a0
                jsr       drawchar
                ply
                fin

                iny
                rep       $20
                lda       omfoff1
                sta       [relptr],y

                do        omfprint
                phy
                jsr       prbytel
                lda       #$a0
                jsr       drawchar
                ply
                fin

                iny
                iny
                lda       omfcode
                cmp       #$f5
                beq       :f5
                sep       $20
                lda       interseg
                sta       [relptr],y
                rep       $30

                do        omfprint
                phy
                jsr       prbyte
                lda       #$a0
                jsr       drawchar
                ply
                fin

                iny
:f5
                lda       omfoff2
                sta       [relptr],y

                do        omfprint
                phy
                jsr       prbytel
                ply
                fin

                lda       omflength
                clc
                adc       rellength
                sta       rellength
                bcc       :3
                inc       rellength+2
:3
                do        omfprint
                pha
                lda       #$a0
                jsr       drawchar
                pla
                jsr       prbytel
                lda       #$0d
                jsr       drawchar
                sep       $20
:b              ldal      $e0c061
                bmi       :b
                fin

                rep       $20
                plp
                clc
                rts
:offset         ds        2

relocatefinal
                php
                rep       $30
                stz       interseg
                stz       omflength
                and       #$f0
                sta       :cmd
                cmp       #%11110000
                jeq       :long
                and       #%11100000
                jeq       :byte1
                cmp       #%10000000
                jeq       :byte2
                cmp       #%10100000
                jeq       :rev2
                cmp       #%01000000
                jeq       :byte1hi
                cmp       #%00100000
                jeq       :byte3
                jmp       :clc
:baddict        rep       $30
                lda       #baddictionary
                plp
                sec
                rts
:byte2          lda       :cmd
                and       #%00010000
                beq       :b21
                jmp       :byte2ext                 ;get value here
:b21            ldy       #$01
                lda       [tempptr1],y
                tay
                clc
                adc       reloffset
                sta       omfoff1
                lda       [tempptr],y
                sec
                sbc       #$8000
                clc
                adc       reloffset
                sta       [tempptr],y
                sta       omfoff2
                stz       omfshift
                lda       #$f5
                sta       omfcode
                lda       #$02
                sta       omfbytes
                lda       #$07
                sta       omflength
                jsr       insertomf
                jcc       :clc
                jmp       :sec

:byte2ext       lda       :cmd
                and       #%00010000
                jeq       :clc
                ldy       #$03
                lda       [tempptr1],y
                and       #$ff
                jsr       getexternal
                jcs       :sec
                ldy       #$01
                lda       [tempptr1],y
                tay
                clc
                adc       reloffset
                sta       omfoff1
                lda       [tempptr],y
                sec
                sbc       #$8000
                clc
                adc       foundlable+o_labval
                sta       [tempptr],y
                sta       omfoff2
                lda       foundlable+o_labtype
                and       #linkabsbit
                jne       :clc
                lda       #$02
                sta       omfbytes
                stz       omfshift
                bit       interseg
                bmi       :interseg1
                lda       #$f5
                sta       omfcode
                lda       #$07
                sta       omflength
                jmp       :ins1
:interseg1      lda       #$f6
                sta       omfcode
                lda       #$08
                sta       omflength
                jsr       isegwarning
:ins1           jsr       insertomf
                jmp       :clc

:rev2           lda       :cmd
                and       #%00010000
                beq       :b22
                jmp       :rev2ext                  ;get value here
:b22            ldy       #$01
                lda       [tempptr1],y
                tay
                clc
                adc       reloffset
                sta       omfoff1
                lda       [tempptr],y
                xba
                sec
                sbc       #$8000
                clc
                adc       reloffset
                sta       omfoff2
                xba
                sta       [tempptr],y
                lda       #-8
                sta       omfshift
                lda       #$01
                sta       omfbytes
                lda       #$f5
                sta       omfcode
                lda       #$07
                sta       omflength
                jsr       insertomf
                lda       rellength+2
                jne       :clc
                stz       omfshift
                lda       #$01
                sta       omfbytes
                lda       #$f5
                sta       omfcode
                lda       #$07
                sta       omflength
                inc       omfoff1
                jsr       insertomf
                jmp       :clc
:rev2ext        lda       :cmd
                and       #%00010000
                jeq       :clc
                ldy       #$03
                lda       [tempptr1],y
                and       #$ff
                jsr       getexternal
                jcs       :sec
                ldy       #$01
                lda       [tempptr1],y
                tay
                clc
                adc       reloffset
                sta       omfoff1
                lda       [tempptr],y
                xba
                sec
                sbc       #$8000
                clc
                adc       foundlable+o_labval
                sta       omfoff2
                xba
                sta       [tempptr],y

                lda       foundlable+o_labtype
                and       #linkabsbit
                jne       :clc

                bit       interseg
                bmi       :interseg2

                lda       #-8
                sta       omfshift
                lda       #$01
                sta       omfbytes
                lda       #$f5
                sta       omfcode
                lda       #$07
                sta       omflength
                jsr       insertomf
                lda       rellength+2
                jne       :clc
                stz       omfshift
                lda       #$01
                sta       omfbytes
                lda       #$f5
                sta       omfcode
                lda       #$07
                sta       omflength
                inc       omfoff1
                jsr       insertomf
                jmp       :clc
:interseg2
                lda       #-8
                sta       omfshift
                lda       #$01
                sta       omfbytes
                lda       #$f6
                sta       omfcode
                lda       #$08
                sta       omflength
                jsr       isegwarning
                jsr       insertomf
                lda       rellength+2
                jne       :clc
                stz       omfshift
                lda       #$01
                sta       omfbytes
                lda       #$f6
                sta       omfcode
                lda       #$08
                sta       omflength
                inc       omfoff1
                jsr       isegwarning
                jsr       insertomf
                jmp       :clc

:byte3          lda       :cmd
                and       #%00010000
                beq       :b25
                jmp       :byte3ext                 ;get value here
:b25            ldy       #$01
                lda       [tempptr1],y
                tay
                clc
                adc       reloffset
                sta       omfoff1
                lda       [tempptr],y
                sta       :lowbyte
                iny
                iny
                lda       [tempptr],y
                and       #$ff
                sta       :lowbyte+2
                dey
                dey
                lda       :lowbyte
                sec
                sbc       #$8000
                sta       :lowbyte
                lda       :lowbyte+2
                sbc       #$00
                sta       :lowbyte+2
                lda       :lowbyte
                clc
                adc       reloffset
                sta       omfoff2
                sta       [tempptr],y
                iny
                iny
                lda       :lowbyte+2
                adc       reloffset+2               ;***
                sep       $20
                sta       [tempptr],y
                rep       $20
                lda       #$f5
                sta       omfcode
                stz       omfshift
                lda       #$03
                sta       omfbytes
                lda       #$07
                sta       omflength
                jsr       insertomf
                jmp       :clc
:byte3ext       lda       :cmd
                and       #%00010000
                jeq       :clc
                ldy       #$03
                lda       [tempptr1],y
                and       #$ff
                jsr       getexternal
                jcs       :sec
                ldy       #$01
                lda       [tempptr1],y
                tay
                clc
                adc       reloffset
                sta       omfoff1
                lda       [tempptr],y
                sec
                sbc       #$8000
                sta       :lowbyte
                php
                iny
                iny
                lda       [tempptr],y
                and       #$ff
                plp
                sbc       #$00
                sta       :lowbyte+2
                dey
                dey
                lda       :lowbyte
                clc
                adc       foundlable+o_labval
                sta       omfoff2
                sty       :omfy
                sta       [tempptr],y
                iny
                iny
                lda       :lowbyte+2
                adc       foundlable+o_labval+2
                sep       $20
                sta       [tempptr],y
                rep       $20
                lda       foundlable+o_labtype
                and       #linkabsbit                    ;absolute lable?
                jne       :clc

                bit       interseg
                bmi       :interseg3
                lda       #$f5
                sta       omfcode
                lda       #$03
                sta       omfbytes
                stz       omfshift
                lda       #$07
                sta       omflength
                jsr       insertomf
                jmp       :clc
:interseg3      stz       dynamic
                lda       #$f6
                sta       omfcode
                lda       #$03
                sta       omfbytes
                stz       omfshift
                lda       #$08
                sta       omflength
                ldy       #$01
                lda       [tempptr1],y
                tay
                iny
                iny
                jsr       jumpentry
                jcs       :sec
                phy
                bit       dynamic
                bpl       :isep
                ldy       :omfy
                lda       omfoff2
                sta       [tempptr],y
                dey
                lda       [tempptr],y
                and       #$ff
                cmp       #$22                      ;is it a jsl??
                beq       :isep
                jsr       isegwarning
:isep           lda       interseg
                ply
                sep       $20
                sta       [tempptr],y               ;save the segment number in object code
                rep       $20
                jsr       insertomf
                jmp       :clc
:omfy           ds        2

:byte1          lda       :cmd
                and       #%00010000
                beq       :b23
                jmp       :byte1ext                 ;get value here
:b23            ldy       #$01
                lda       [tempptr1],y
                tay
                clc
                adc       reloffset
                sta       omfoff1
                lda       [tempptr],y
                and       #$ff
                clc
                adc       reloffset
                sep       $20
                sta       [tempptr],y
                rep       $20
                sta       omfoff2
                stz       omfshift
                lda       #$07
                sta       omflength
                lda       #$01
                sta       omfbytes
                lda       #$f5
                sta       omfcode
                jsr       insertomf
                jmp       :clc

:byte1ext       lda       :cmd
                and       #%00010000
                jeq       :clc
                ldy       #$03
                lda       [tempptr1],y
                and       #$ff
                jsr       getexternal
                jcs       :sec
                ldy       #$01
                lda       [tempptr1],y
                tay
                clc
                adc       reloffset
                sta       omfoff1
                lda       [tempptr],y
                and       #$ff
                clc
                adc       foundlable+o_labval
                sta       omfoff2
                sep       $20
                sta       [tempptr],y
                rep       $20
                lda       foundlable+o_labtype
                and       #linkabsbit
                jne       :clc

                bit       interseg
                bmi       :interseg4
                stz       omfshift
                lda       #$07
                sta       omflength
                lda       #$01
                sta       omfbytes
                lda       #$f5
                sta       omfcode
                jsr       insertomf
                jmp       :clc
:interseg4      stz       omfshift
                lda       #$08
                sta       omflength
                lda       #$01
                sta       omfbytes
                lda       #$f6
                sta       omfcode
                jsr       isegwarning
                jsr       insertomf
                jmp       :clc

:byte1hi        lda       :cmd
                and       #%00010000
                beq       :b24
                jmp       :baddict                  ;get value here
:b24            ldy       #$03
                lda       [tempptr1],y
                and       #$ff
                sta       :lowbyte
                ldy       #$01
                lda       [tempptr1],y
                tay
                clc
                adc       reloffset
                sta       omfoff1
                lda       [tempptr],y
                and       #$ff
                xba
                ora       :lowbyte
                sec
                sbc       #$8000
                clc
                adc       reloffset
                sta       omfoff2
                xba
                sep       $20
                sta       [tempptr],y
                rep       $20
                lda       #$f5
                sta       omfcode
                lda       #$07
                sta       omflength
                lda       #-8
                sta       omfshift
                lda       #$01
                sta       omfbytes
                jsr       insertomf
                jmp       :clc
:byte1hiext     lda       :cmd
                and       #%00010000
                jeq       :clc
:b1hi           rep       $30
                ldy       #$05
                lda       [tempptr1],y
                sta       :lowbyte
                ldy       #$03
                lda       [tempptr1],y
                and       #$ff
                jsr       getexternal
                jcs       :sec
                ldy       #$01
                lda       [tempptr1],y
                tay
                clc
                adc       reloffset
                sta       omfoff1
* lda [tempptr],y
* and #$ff
* xba
* ora :lowbyte
                lda       :lowbyte
                sec
                sbc       #$8000
                clc
                adc       foundlable+o_labval
                sta       omfoff2
                xba
                sep       $20
                sta       [tempptr],y
                rep       $20
                lda       foundlable+o_labtype
                and       #linkabsbit
                jne       :clc

                bit       interseg
                bmi       :interseg5
                lda       #$f5
                sta       omfcode
                lda       #$07
                sta       omflength
                lda       #-8
                sta       omfshift
                lda       #$01
                sta       omfbytes
                jsr       insertomf
                jmp       :clc
:interseg5      lda       #$f6
                sta       omfcode
                lda       #$08
                sta       omflength
                lda       #-8
                sta       omfshift
                lda       #$01
                sta       omfbytes
                jsr       isegwarning
                jsr       insertomf
                jmp       :clc

:long           ldy       #$04
                lda       [tempptr1],y
                and       #$ff
                sta       :cmd
                cmp       #%11010000
                beq       :la1
                cmp       #%11010001
                jeq       :la2
                cmp       #%11010111
                jeq       :la5
                cmp       #%11010100
                jeq       :la3
                cmp       #%11010101
                jeq       :la4
                lda       #baddictionary
                jmp       :sec

:la1            ldy       #$05
                lda       [tempptr1],y
                sta       :lowbyte
                iny
                iny
                lda       [tempptr1],y
                and       #$ff
                sta       :lowbyte+2
                lda       :lowbyte
                sec
                sbc       #$8000
                sta       :lowbyte
                lda       :lowbyte+2
                sbc       #$00
                sta       :lowbyte+2
                lda       reloffset
                clc
                adc       :lowbyte
                sta       :lowbyte
                sta       omfoff2
                lda       reloffset+2
                adc       :lowbyte+2
                sta       :lowbyte+2
                ldy       #$01
                lda       [tempptr1],y
                tay
                clc
                adc       reloffset
                sta       omfoff1
                lda       :lowbyte+2
                sep       $20
                sta       [tempptr],y
                rep       $20
                lda       #$f5
                sta       omfcode
                lda       #$07
                sta       omflength
                lda       #$01
                sta       omfbytes
                lda       #-16
                sta       omfshift
                jsr       insertomf
                jmp       :clc
:la2            ldy       #$05
                lda       [tempptr1],y
                sta       :lowbyte
                iny
                iny
                lda       [tempptr1],y
                and       #$ff
                sta       :lowbyte+2
                lda       :lowbyte
                sec
                sbc       #$8000
                sta       :lowbyte
                lda       :lowbyte+2
                sbc       #$00
                sta       :lowbyte+2
                lda       reloffset
                clc
                adc       :lowbyte
                sta       :lowbyte
                sta       omfoff2
                lda       reloffset+2
                adc       :lowbyte+2
                sta       :lowbyte+2
                ldy       #$01
                lda       [tempptr1],y
                tay
                clc
                adc       reloffset
                sta       omfoff1
                lda       :lowbyte+1
                sta       [tempptr],y

                lda       #$f5
                sta       omfcode
                lda       #$07
                sta       omflength
                lda       #$02
                sta       omfbytes
                lda       #-8
                sta       omfshift
                jsr       insertomf
                jmp       :clc

:la3            ldy       #$03
                lda       [tempptr1],y
                and       #$ff
                jsr       getexternal
                jcs       :sec
                ldy       #$05
                lda       [tempptr1],y
                sec
                sbc       #$8000
                sta       :lowbyte
                iny
                iny
                lda       [tempptr1],y
                and       #$ff
                sbc       #$00
                sta       :lowbyte+2
                ldy       #$01
                lda       [tempptr1],y
                tay
                clc
                adc       reloffset
                sta       omfoff1
                lda       foundlable+o_labval
                clc
                adc       :lowbyte
                sta       omfoff2
                lda       foundlable+o_labval+2
                adc       :lowbyte+2
                sep       $20
                sta       [tempptr],y
                rep       $20
                lda       foundlable+o_labtype
                and       #linkabsbit
                jne       :clc

                lda       #$f5
                sta       omfcode
                lda       #$07
                sta       omflength
                lda       #$01
                sta       omfbytes
                lda       #-16
                sta       omfshift
                bit       interseg
                bpl       :ok3
                inc       omfcode
                inc       omflength
                jsr       isegwarning
:ok3            jsr       insertomf
                jmp       :clc

:la4            ldy       #$03
                lda       [tempptr1],y
                and       #$ff
                jsr       getexternal
                jcs       :sec

                ldy       #$05
                lda       [tempptr1],y
                sec
                sbc       #$8000
                sta       :lowbyte
                iny
                iny
                lda       [tempptr1],y
                and       #$ff
                sbc       #$00
                sta       :lowbyte+2

                ldy       #$01
                lda       [tempptr1],y
                tay
                clc
                adc       reloffset
                sta       omfoff1
                lda       foundlable+o_labval
                clc
                adc       :lowbyte
                sta       :lowbyte
                sta       omfoff2
                lda       foundlable+o_labval+2
                adc       :lowbyte+2
                sta       :lowbyte+2
                lda       :lowbyte+1
                sta       [tempptr],y

                lda       foundlable+o_labtype
                and       #linkabsbit
                jne       :clc

                lda       #$f5
                sta       omfcode
                lda       #$07
                sta       omflength
                lda       #$02
                sta       omfbytes
                lda       #-8
                sta       omfshift
                bit       interseg
                bpl       :ok4
                inc       omfcode ; $f6
                inc       omflength
                jsr       isegwarning
:ok4            jsr       insertomf
                jmp       :clc

:la5            jmp       :b1hi

:clc            plp
                clc
                rts
:sec            plp
                sec
                rts
:cmd            ds        2
:lowbyte        ds        4


getexternal     php
                rep       $30
                and       #$ff
                sta       :refnum
                stz       :zpage
                lda       segnum
                sta       extseg

                ldy       #$00
]lup            sep       $20
                sty       :offset
                lda       [tempptr2],y
                beq       :notfound
                bpl       :next
                rep       $20
                and       #%00011111
                pha
                tya
                clc
                adc       1,s
                inc
                plx
                tay
                lda       [tempptr2],y
                and       #$ff
                cmp       :refnum
                beq       :found
:next           rep       $20
                ldy       :offset
                lda       [tempptr2],y
                and       #%00011111
                clc
                adc       #4
                clc
                adc       :offset
                tay
                jmp       ]lup
:notfound       rep       $20
                lda       labstr
                and       #label_mask
                tay
                ldx       #$01
]lup            sep       $20
                lda       labstr,x
                phx
                phy
                jsr       drawchar
                ply
                plx
                inx
                dey
                bne       ]lup
                rep       $20
                psl       #:notres
                _QADrawString
                ldy       #$01
                lda       [tempptr1],y
                clc
                adc       reloffset
                pha
                lda       #$00
                adc       reloffset+2
                and       #$ff
                beq       :e1
                jsr       prbyte
:e1             pla
                jsr       prbytel
                lda       #$0d
                jsr       drawchar

:notfound1      rep       $20
                lda       #notresolved
                plp
                sec
                rts
:found          sep       $20
                iny
                lda       [tempptr2],y
                cmp       #$01
                bge       :f1
                sec
                ror       :zpage+1
:f1             rep       $20
                ldy       :offset
                lda       [tempptr2],y
                and       #%00011111
                cmp       #lab_size
                blt       :tx1
                lda       #lab_size
:tx1
                sta       :offset
                ldx       #$00
                iny
                sep       $20
                sta       labstr
]lup            cpx       :offset
                beq       :search
                lda       [tempptr2],y
                and       #$7f
                sta       labstr+1,x
                inx
                iny
                jmp       ]lup
:search         rep       $20
                stz       :cased
:find           jsr       findlable
                bcs       :itsfound
                bit       :cased
                jmi       :notfound
                jsr       caselable
                sec
                ror       :cased
                jmp       :find
:itsfound       ldy       #o_labtype
                lda       [lableptr],y
                ora       #linkentused
                sta       [lableptr],y
:itsfound2      lda       foundlable+o_labtype
                bit       #linkentrybit
                jeq       :notfound
                lda       foundlable+o_lablocal             ;get lable's seg number
                sta       extseg
                cmp       segnum
                beq       :bit
                sec
                ror       interseg                  ;indicate an intersegment call
                sep       $20
                sta       interseg
                rep       $20
:bit            bit       :zpage
                bpl       :clc
                lda       foundlable+o_labval+1
                beq       :clc
                lda       #extnotzp
                plp
                sec
                rts
:clc            plp
                clc
                rts

:refnum         ds        2
:zpage          ds        2
:offset         ds        2
:cased          ds        2
:notres         str       ' not resolved at $'

                mx        %00
lkvop           bit       passnum
                bpl       :ver
                clc
                rts
:ver            bit       lkvchg
                bpl       :ver1
                clc
                rts
:ver1           ldx       #$00
                jsr       eval
                bcc       :ok
                rts
:ok             lda       lvalue
                cmp       #$03
                blt       :ok1
:bad            lda       #badvalue
                sec
                rts
:ok1            and       #$ff
                sta       linkversion
                sec
                ror       lkvchg
                cmp       #$00                      ;absolute linker?
                bne       :clc
                lda       #$06                      ;BIN type
                sta       linktype
:clc            clc
                rts

nolop           php
                rep       $30
                do        oldshell
                lda       #$00
                ldx       goffset
                sta       linklstflag,x
                fin
                plp
                clc
                rts

checkorg        php
                rep       $30
                lda       linkversion
                jeq       :sec
                lda       segmenthdl+2
                sta       segmentptr+2
                lda       segmenthdl
                sta       segmentptr
                ldy       #$02
                lda       [segmentptr]
                tax
                lda       [segmentptr],y
                sta       segmentptr+2
                stx       segmentptr
                lda       segnum
                asl
                asl
                asl
                asl
                asl
                asl
                clc
                adc       #orgfield
                tay
                lda       [segmentptr],y
                iny
                iny
                ora       [segmentptr],y
                bne       :sec
                plp
                clc
                rts
:sec            plp
                sec
                rts


orgop           ldx       #$00
                jsr       eval
                bcc       :ok
                rts
:ok             lda       linkversion
                jeq       :abs
                lda       segmenthdl+2
                sta       segmentptr+2
                lda       segmenthdl
                sta       segmentptr
                ldy       #$02
                lda       [segmentptr]
                tax
                lda       [segmentptr],y
                sta       segmentptr+2
                stx       segmentptr
                lda       segnum
                asl
                asl
                asl
                asl
                asl
                asl
                clc
                adc       #orgfield
                tay
                lda       lvalue
                sta       [segmentptr],y
                iny
                iny
                lda       lvalue+2
                sta       [segmentptr],y
* clc
* rts
:abs            lda       lvalue
                sta       reloffset
                sta       orgval
                lda       lvalue+2
                sta       reloffset+2
                sta       orgval+2
                clc
                rts

adrop           ldx       #$00
                jsr       eval
                bcc       :ok
                rts
:ok             lda       lvalue
                sta       orgval
                sta       adrval
                lda       lvalue+2
                sta       orgval+2
                sta       adrval+2
                clc
                rts



ovrop           ldy       #$00
]lup            lda       (lineptr),y
                iny
                and       #$7f
                cmp       #' '
                blt       :one
                beq       ]lup
                and       #$5f
                cmp       #'A'
                beq       :all
                cmp       #'O'
                beq       :off
                cmp       #';'
                beq       :one
                jmp       ]lup
:one            lda       #$ffff
                sta       ovrflag
                clc
                rts
:all            lda       #$ffff
                sta       ovrflag
                sta       ovrallflag
                clc
                rts
:off            lda       #$00
                sta       ovrflag
                sta       ovrallflag
                clc
                rts

pfxop           lda       #$00
                jsr       getpath
                bcc       :setpfx
                rts
:setpfx         jsl       prodos
                dw        $09                       ;setpfx
                adrl      :pfxparm
                bcc       :rts
                sta       prodoserr
                lda       #doserror
                sec
:rts            rts
:pfxparm        dw        $00
                adrl      asmpath

                mx        %00
putop           lda       #$ffff
                jsr       getpath
                bcc       :setmode
                rts
:setmode        rep       $30
                jsl       prodos
                dw        $06
                adrl      info
                jcs       :err
                lda       ftype
                cmp       #$04
                bne       :mismatch
                lda       aux
                and       #$01
                bne       :clc
                lda       #$ffff
                sta       ovrflag
                lda       aux
                ora       #$01
                sta       aux
                jsl       prodos
                dw        $05
                adrl      info
                lda       #$00
                sta       asmpath
                clc
                rts
:clc            lda       #$00
                sta       asmpath
                clc
                rts
:mismatch       lda       #$00
                sta       asmpath
                lda       #mismatch
:err            rep       $30
                sta       prodoserr
                lda       #doserror
                sec
                rts

ifop            lda       #$ffff
                jsr       getpath
                bcc       :setmode
                rts
:setmode        rep       $30
                jsl       prodos
                dw        $06
                adrl      info
                jcs       :err
                lda       ftype
                cmp       #$04
                bne       :mismatch
                lda       aux
                and       #$01
                bne       :clc
                lda       #$ffff
                sta       ovrallflag
                lda       aux
                ora       #$01
                sta       aux
                jsl       prodos
                dw        $05
                adrl      info
                lda       #$00
                sta       asmpath
                clc
                rts
:clc            lda       #$00
                sta       asmpath
                clc
                rts
:mismatch       lda       #$00
                sta       asmpath
                lda       #mismatch
:err            rep       $30
                sta       prodoserr
                lda       #doserror
                sec
                rts


savop           lda       #$00
                sta       asmpath
                lda       linkversion
                bne       :gslink
* lda savcount
* beq :gslink
* lda #onesave
* sec
* rts
:gslink         inc       savcount
                lda       #$0000
                jsr       getpath
                bcc       :goodfile
                rts
:goodfile       bit       passnum
                bmi       :pass1
                stz       reloffset
                stz       reloffset+2
                jsr       newsegment
                rts
:clc            clc
                rts
:pass1          stz       reloffset
                stz       reloffset+2
                stz       :ct
                stz       rellength
                stz       rellength+2

                psl       #:str
                _QADrawString
                lda       linksymhdl
                sta       relptr
                lda       linksymhdl+2
                sta       relptr+2
                ldy       #$02
                lda       [relptr]
                tax
                lda       [relptr],y
                sta       relptr+2
                stx       relptr
]lup            jsr       readkey
                bcc       :k1
                and       #$7f
                cmp       #$1b
                beq       :can
                cmp       #'C'&$1f
                bne       :k1
:can            sec
                ror       cancelflag
                jmp       :clc2
:k1
]lup1           lda       :ct
                cmp       numfiles
                beq       :clc1
                jsr       buildfinal
                bcc       :inc
                rts
:inc            inc       :ct
                jmp       ]lup
:clc1           jsr       dosegname
                bit       cancelflag
                bmi       :cancel
                jsr       checkorg
                bcs       :sav
                jsr       compress
                bcc       :sav
                jmp       :ssxit
:sav            jsr       readkey
                bcc       :can1
                cmp       #$1b
                beq       :cancel
                cmp       #'C'&$1f
                beq       :cancel
:can1           bit       cancelflag
                bmi       :cancel
                jsr       saveseg
                bcc       :clc2
                inc       segnum
                jmp       :ssxit
:clc2           inc       segnum
                clc
                jmp       :ssxit
:cancel         sec
                ror       cancelflag
                lda       #$00
:ssxit          pha
                php
                rep       $30
                lda       compresshdl
                ora       compresshdl+2
                beq       :plp
                psl       compresshdl
                _DisposeHandle
                stz       compresshdl
                stz       compresshdl+2
:plp            plp
                pla
                rts

:ct             ds        2
:str            hex       010d

compress        php
                rep       $30
                lda       omfversion
                cmp       #$02
                blt       :clc
                stz       compresshdl
                stz       compresshdl+2
                lda       rellength
                bne       :ok
:clc            plp
                clc
                rts
:ok
                lda       lablen
                xba
                and       #$00ff
                sta       :len
                psl       #:str
                _QADrawString
                ldx       #$00
]lup            lda       segname,x
                phx
                jsr       drawchar
                plx
                inx
                cpx       :len
                blt       ]lup
                lda       #$0d
                jsr       drawchar
                ldy       rellength
                lda       #$00
                sep       $20
                sta       [relptr],y
                rep       $20

                psl       #$00
                lda       rellength
                clc
                adc       #$10
                bcc       :pea00
                pea       $01
                jmp       :pea02
:pea00          pea       $00
:pea02          pha
                ldal      userid
                ora       #linkmemid
                pha
                pea       $8000
                psl       #$00
                _NewHandle
                plx
                ply
                jcs       :badcompress
                stx       cptr
                stx       compresshdl
                sty       cptr+2
                sty       compresshdl+2
                ldy       #$02
                lda       [cptr]
                tax
                lda       [cptr],y
                sta       cptr+2
                stx       cptr
                stz       clength
                jsr       super02
                jsr       super03
                jsr       superiseg1
                jsr       superisegn
                jsr       comflush
                lda       clength
                sta       rellength
                plp
                clc
                rts

:badcompress    rep       $30
                jsr       prbytel
                psl       #:badstr
                _QADrawString
                plp
                clc
                rts

:len            ds        4
:str            str       'Compressing Segment: '
:badstr         str       'Unable to compress...'

super02         php
                rep       $30
                lda       relptr
                sta       cptr1
                lda       relptr+2
                sta       cptr1+2
                lda       #$01
                sta       :bytes
                stz       :patches
                lda       #$FF00
                sta       :page                     ;bug here when first patch is in
;page $FF of segment
                lda       clength
                sta       :oldclen
                clc
                adc       #$06
                sta       :countbyte
                stz       :count
                inc
                sta       :pos

:s1             ldy       #$00
                lda       [cptr1],y
                and       #$ff
                sta       :cmd
                ldx       :pos
                ldy       #$00
                lda       [cptr1],y
                and       #$ff
                jeq       :donef5
                lda       [cptr1],y
                cmp       #$02F5                    ;super 2 type
                jne       :next1
                iny
                iny
                lda       [cptr1],y
                and       #$ff
                bne       :next1                    ;shift must be zero

                phy
                dey
                dey
                sep       $20
                lda       #$05
                sta       [cptr1],y
                rep       $20
                ply

                iny
                lda       [cptr1],y
                and       #$ff00
                cmp       :page
                beq       :save
                sec
                sbc       :page
                xba
                ora       #$80
                pha
                phy
                ldy       :countbyte
                lda       :count
                bne       :p
                dex
                dec       :bytes
                jmp       :r
:p              dec
                sep       $20
                sta       [cptr],y
:r              rep       $20
                ply
                pla
                phy
                dec
                cmp       #$80
                beq       :rep
                txy
                sep       $20
                sta       [cptr],y
                inx
                rep       $20
                inc       :bytes
:rep            rep       $20
                stz       :count
                stx       :countbyte
                inx
                inc       :bytes
                ply
:save           inc       :count
                lda       [cptr1],y
                pha
                and       #$ff00
                sta       :page
                pla
                phy
                txy
                sep       $20
                sta       [cptr],y
                rep       $20
                inx
                inc       :bytes
                inc       :patches
                ply
                stx       :pos
:next1          lda       :cmd
                cmp       #$f6
                beq       :8
                cmp       #$06
                beq       :8
                lda       #$07
                jmp       :adc
:8              lda       #$08
:adc            clc
                adc       cptr1
                sta       cptr1
                bcc       :next2
                inc       cptr1+2
:next2          jmp       :s1
:donef5         ldy       :countbyte
                lda       :count
                dec
                sep       $20
                sta       [cptr],y
                rep       $20
                lda       :patches
                bne       :insert
                plp
                rts
:insert         ldy       :oldclen
                lda       #$f7
                sep       $20
                sta       [cptr],y
                rep       $20
                iny
                lda       :bytes
                inc                                 ;to count for super "type" byte
                sta       [cptr],y
                iny
                iny
                lda       #$00
                sta       [cptr],y
                iny
                iny
                sep       $20
                lda       #$00
                sta       [cptr],y
                rep       $20
                lda       :bytes
                clc
                adc       #$06
                clc
                adc       :oldclen
                sta       clength
                plp
                rts
:oldclen        ds        2
:bytes          ds        2
:len            ds        2
:pos            ds        2
:length         ds        4
:page           ds        2
:cmd            ds        2
:countbyte      ds        2
:count          ds        2
:patches        ds        2

super03         php
                rep       $30
                lda       relptr
                sta       cptr1
                lda       relptr+2
                sta       cptr1+2
                lda       #$01
                sta       :bytes
                stz       :patches
                lda       #$FF00
                sta       :page                     ;bug here when first patch is in
;page $FF of segment
                lda       clength
                sta       :oldclen
                clc
                adc       #$06
                sta       :countbyte
                stz       :count
                inc
                sta       :pos

:s1             ldy       #$00
                lda       [cptr1],y
                and       #$ff
                sta       :cmd
                ldx       :pos
                ldy       #$00
                lda       [cptr1],y
                and       #$ff
                jeq       :donef5
                lda       [cptr1],y
                cmp       #$03F5                    ;super 2 type
                jne       :next1
                iny
                iny
                lda       [cptr1],y
                and       #$ff
                bne       :next1                    ;shift must be zero

                phy
                dey
                dey
                sep       $20
                lda       #$05
                sta       [cptr1],y
                rep       $20
                ply

                iny
                lda       [cptr1],y
                and       #$ff00
                cmp       :page
                beq       :save
                sec
                sbc       :page
                xba
                ora       #$80
                pha
                phy
                ldy       :countbyte
                lda       :count
                bne       :p
                dex
                dec       :bytes
                jmp       :r
:p              dec
                sep       $20
                sta       [cptr],y
:r              rep       $20
                ply
                pla
                phy
                dec
                cmp       #$80
                beq       :rep
                txy
                sep       $20
                sta       [cptr],y
                inx
                rep       $20
                inc       :bytes
:rep            rep       $20
                stz       :count
                stx       :countbyte
                inx
                inc       :bytes
                ply
:save           inc       :count
                lda       [cptr1],y
                pha
                and       #$ff00
                sta       :page
                pla
                phy
                txy
                sep       $20
                sta       [cptr],y
                rep       $20
                inx
                inc       :bytes
                inc       :patches
                ply
                stx       :pos
:next1          lda       :cmd
                cmp       #$f6
                beq       :8
                cmp       #$06
                beq       :8
                lda       #$07
                jmp       :adc
:8              lda       #$08
:adc            clc
                adc       cptr1
                sta       cptr1
                bcc       :next2
                inc       cptr1+2
:next2          jmp       :s1
:donef5         ldy       :countbyte
                lda       :count
                dec
                sep       $20
                sta       [cptr],y
                rep       $20
                lda       :patches
                bne       :insert
                plp
                rts
:insert         ldy       :oldclen
                lda       #$f7
                sep       $20
                sta       [cptr],y
                rep       $20
                iny
                lda       :bytes
                inc                                 ;to count for super "type" byte
                sta       [cptr],y
                iny
                iny
                lda       #$00
                sta       [cptr],y
                iny
                iny
                sep       $20
                lda       #$01                      ;super reloc3
                sta       [cptr],y
                rep       $20
                lda       :bytes
                clc
                adc       #$06
                clc
                adc       :oldclen
                sta       clength
                plp
                rts
:oldclen        ds        2
:bytes          ds        2
:len            ds        2
:pos            ds        2
:length         ds        4
:page           ds        2
:cmd            ds        2
:countbyte      ds        2
:count          ds        2
:patches        ds        2

superiseg1      php
                rep       $30
                lda       relptr
                sta       cptr1
                lda       relptr+2
                sta       cptr1+2
                lda       #$01
                sta       :bytes
                stz       :patches
                lda       #$FF00
                sta       :page                     ;bug here when first patch is in
;page $FF of segment
                lda       clength
                sta       :oldclen
                clc
                adc       #$06
                sta       :countbyte
                stz       :count
                inc
                sta       :pos

:s1             ldy       #$00
                lda       [cptr1],y
                and       #$ff
                sta       :cmd
                ldx       :pos
                ldy       #$00
                lda       [cptr1],y
                and       #$ff
                jeq       :donef5
                lda       [cptr1],y
                cmp       #$03F6                    ;super 2 type
                jne       :next1
                iny
                iny
                lda       [cptr1],y
                and       #$ff
                jne       :next1                    ;shift must be zero

                sep       $20
                lda       #$06
                sta       [cptr1]
                rep       $20

                iny
                lda       [cptr1],y
                and       #$ff00
                cmp       :page
                beq       :save
                sec
                sbc       :page
                xba
                ora       #$80
                pha
                phy
                ldy       :countbyte
                lda       :count
                bne       :p
                dex
                dec       :bytes
                jmp       :r
:p              dec
                sep       $20
                sta       [cptr],y
:r              rep       $20
                ply
                pla
                phy
                dec
                cmp       #$80
                beq       :rep
                txy
                sep       $20
                sta       [cptr],y
                inx
                rep       $20
                inc       :bytes
:rep            rep       $20
                stz       :count
                stx       :countbyte
                inx
                inc       :bytes
                ply
:save           inc       :count
                lda       [cptr1],y
                pha
                and       #$ff00
                sta       :page
                pla
                phy
                txy
                sep       $20
                sta       [cptr],y
                rep       $20
                inx
                inc       :bytes
                inc       :patches
                ply
                stx       :pos
:next1          lda       :cmd
                cmp       #$f6
                beq       :8
                cmp       #$06
                beq       :8
                lda       #$07
                jmp       :adc
:8              lda       #$08
:adc            clc
                adc       cptr1
                sta       cptr1
                bcc       :next2
                inc       cptr1+2
:next2          jmp       :s1
:donef5         ldy       :countbyte
                lda       :count
                dec
                sep       $20
                sta       [cptr],y
                rep       $20
                lda       :patches
                bne       :insert
                plp
                rts
:insert         ldy       :oldclen
                lda       #$f7
                sep       $20
                sta       [cptr],y
                rep       $20
                iny
                lda       :bytes
                inc                                 ;to count for super "type" byte
                sta       [cptr],y
                iny
                iny
                lda       #$00
                sta       [cptr],y
                iny
                iny
                sep       $20
                lda       #$02                      ;super interseg1
                sta       [cptr],y
                rep       $20
                lda       :bytes
                clc
                adc       #$06
                clc
                adc       :oldclen
                sta       clength
                plp
                rts
:oldclen        ds        2
:bytes          ds        2
:len            ds        2
:pos            ds        2
:length         ds        4
:page           ds        2
:cmd            ds        2
:countbyte      ds        2
:count          ds        2
:patches        ds        2

superisegn      php
                rep       $30
                lda       #12
                sta       :subval
                stz       :findval
                lda       #13
                sta       :currentseg
:main           rep       $30
                lda       :currentseg
                sec
                sbc       :subval
                sta       :thisseg
                lda       relptr
                sta       cptr1
                lda       relptr+2
                sta       cptr1+2
                lda       #$01
                sta       :bytes
                stz       :patches
                lda       #$FF00
                sta       :page                     ;bug here when first patch is in
;page $FF of segment
                lda       clength
                sta       :oldclen
                clc
                adc       #$06
                sta       :countbyte
                stz       :count
                inc
                sta       :pos

:s1             ldy       #$00
                lda       [cptr1],y
                and       #$ff
                sta       :cmd
                ldx       :pos
                ldy       #$00
                lda       [cptr1],y
                and       #$ff
                jeq       :donef5
                lda       [cptr1],y
                cmp       #$02F6                    ;super 2 type
                jne       :next1
                iny
                iny
                lda       [cptr1],y
                and       #$ff
                cmp       :findval
                jne       :next1                    ;shift must be zero
                iny
                iny
                iny
                lda       [cptr1],y
                and       #$ff
                cmp       :thisseg
                jne       :next1
                dey
                dey
                dey
                phy
                dey
                dey
                sep       $20
                lda       #$06
                sta       [cptr1],y
                rep       $20
                ply

                iny
                lda       [cptr1],y
                and       #$ff00
                cmp       :page
                beq       :save
                sec
                sbc       :page
                xba
                ora       #$80
                pha
                phy
                ldy       :countbyte
                lda       :count
                bne       :p
                dex
                dec       :bytes
                jmp       :r
:p              dec
                sep       $20
                sta       [cptr],y
:r              rep       $20
                ply
                pla
                phy
                dec
                cmp       #$80
                beq       :rep
                txy
                sep       $20
                sta       [cptr],y
                inx
                rep       $20
                inc       :bytes
:rep            rep       $20
                stz       :count
                stx       :countbyte
                inx
                inc       :bytes
                ply
:save           inc       :count
                lda       [cptr1],y
                pha
                and       #$ff00
                sta       :page
                pla
                phy
                txy
                sep       $20
                sta       [cptr],y
                rep       $20
                inx
                inc       :bytes
                inc       :patches

                ply
                stx       :pos
:next1          lda       :cmd
                cmp       #$f6
                beq       :8
                cmp       #$06
                beq       :8
                lda       #$07
                jmp       :adc
:8              lda       #$08
:adc            clc
                adc       cptr1
                sta       cptr1
                bcc       :next2
                inc       cptr1+2
:next2          jmp       :s1
:donef5         ldy       :countbyte
                lda       :count
                dec
                sep       $20
                sta       [cptr],y
                rep       $20
                lda       :patches
                bne       :insert
                plp
                rts
:insert         ldy       :oldclen
                lda       #$f7
                sep       $20
                sta       [cptr],y
                rep       $20
                iny
                lda       :bytes
                inc                                 ;to count for super "type" byte
                sta       [cptr],y
                iny
                iny
                lda       #$00
                sta       [cptr],y
                iny
                iny
                sep       $20
                lda       :currentseg               ;super intersegN
                inc                                 ;type byte is 1+n
                sta       [cptr],y
                rep       $20
                lda       :bytes
                clc
                adc       #$06
                clc
                adc       :oldclen
                sta       clength
                inc       :currentseg
                lda       :currentseg
                cmp       #25
                jlt       :main
                pha
                lda       #$f0
                sta       :findval
                lda       #24
                sta       :subval
                pla
                cmp       #37
                jlt       :main
                plp
                rts
:oldclen        ds        2
:bytes          ds        2
:len            ds        2
:pos            ds        2
:length         ds        4
:page           ds        2
:cmd            ds        2
:countbyte      ds        2
:count          ds        2
:patches        ds        2
:currentseg     ds        2
:findval        ds        2
:subval         ds        2
:thisseg        ds        2

comflush        php
                rep       $30
                lda       relptr
                sta       cptr1
                lda       relptr+2
                sta       cptr1+2
]lup            ldy       #$00
                lda       [cptr1],y
                and       #$ff
                jeq       :xit
                sta       :cmd
                cmp       #$f6
                beq       :sta
                cmp       #$f5
                beq       :sta
                cmp       #$05
                jeq       :05
                cmp       #$06
                jeq       :06
:sta            ldx       clength
                lda       [cptr1],y
                phy
                txy
                sta       [cptr],y
                ply
                iny
                iny
                inx
                inx
                lda       [cptr1],y
                phy
                txy
                sta       [cptr],y
                ply
                iny
                iny
                inx
                inx
                lda       [cptr1],y
                phy
                txy
                sta       [cptr],y
                ply
                iny
                iny
                inx
                inx

                lda       :cmd
                cmp       #$f6
                beq       :f6
                sep       $20
                lda       [cptr1],y
                phy
                txy
                sta       [cptr],y
                ply
                iny
                inx
                jmp       :sta1

:f6             lda       [cptr1],y
                phy
                txy
                sta       [cptr],y
                ply
                inx
                inx
:sta1           rep       $30
                stx       clength
                stx       rellength
                lda       :cmd
                cmp       #$f6
                beq       :06
:05             lda       cptr1
                clc
                adc       #$07
                sta       cptr1
                jmp       :08
:06             lda       cptr1
                clc
                adc       #$08
                sta       cptr1
:08             bcc       :09
                inc       cptr1+2
:09             jmp       ]lup
:xit
                ldy       #$00
                lda       relptr
                sta       cptr1
                lda       relptr+2
                sta       cptr1+2
                sep       $20
]lup            lda       [cptr],y
                sta       [cptr1],y
                iny
                cpy       clength
                blt       ]lup
                rep       $30

                plp
                rts

:cmd            ds        2

showcodelen
                php
                rep       $30

                psl       #:str
                _QADrawString

                lda       segnum
                jsr       prbyte

                psl       #:str1
                _QADrawString

                lda       seglength
                jsr       prbytel

                lda       #$0d
                jsr       drawchar
                plp
                clc
                rts
:str            str       'Code length of segment '
:str1           str       ' = $'
:len            ds        2

showjmplen
                php
                rep       $30

                psl       #:str
                _QADrawString

                lda       bytecnt+2
                xba
                and       #$ff
                beq       :1
                jsr       prbyte
:1              lda       bytecnt+2
                and       #$ff
                beq       :2
                jsr       prbyte
:2              lda       bytecnt
                xba
                and       #$ff
                beq       :3
                jsr       prbyte
:3              lda       bytecnt
                and       #$ff
                jsr       prbyte

                lda       #$0d
                jsr       drawchar
                plp
                clc
                rts
:str            str       0d,'Jump table segment length = $'


dosegname       php
                rep       $30
                stz       :segflag
                lda       segnum
                cmp       #$01
                beq       :ldy
                lda       #$ffff
                sta       :segflag
:ldy            ldy       #$00
                sep       $20
                lda       #' '
]lup            sta       segname,y
                bit       :segflag
                bmi       :i1
                sta       loadname,y
:i1             iny
                cpy       #10
                blt       ]lup
                rep       $20
                lda       asmpath
                and       #$ff
                sta       :length
                tax
                lda       asmpath,x
                and       #$7f
                cmp       #':'
                bne       :chklen
                dec       :length
:chklen         lda       :length
                bne       :ldx
                jmp       :segment
:ldx            ldx       #$01
                ldy       #$00
                sep       $20
]lup            cpx       :length
                blt       :1
                beq       :1
                jmp       :segment
:1              lda       asmpath,x
                and       #$7f
                cmp       #' '+1
                blt       :segment
                cmp       #':'
                bne       :sta
                ldy       #$00
                lda       #' '
]clr            sta       segname,y
                bit       :segflag
                bmi       :iny
                sta       loadname,y
:iny            iny
                cpy       #10
                blt       ]clr
                ldy       #$00
                inx
                jmp       ]lup
:sta            cpy       #10
                bge       :sta1
:sta2           sta       segname,y
                bit       :segflag
                bmi       :sta1
                sta       loadname,y
:sta1           iny
                inx
                jmp       ]lup
:segment
                rep       $30
                plp
                rts
:length         ds        2
:segflag        ds        2

saveseg         php
                rep       $30
                lda       linksymhdl
                sta       workspace
                lda       linksymhdl+2
                sta       workspace+2
                ldy       #$02
                lda       [workspace]
                sta       relptr
                lda       [workspace],y
                sta       relptr+2
                stz       bytecnt
                stz       bytecnt+2
                stz       seglength
                stz       seglength+2
                lda       seghdrlen
                sta       bytecnt
                stz       :ct
]lup            lda       :ct
                cmp       numfiles
                beq       :bytes
                asl
                asl
                asl
                asl
                asl
                tax
                lda       files+10,x
                cmp       segnum
                bne       :next
                lda       files+8,x
                clc
                adc       seglength
                sta       seglength
                bcc       :next
                inc       seglength+2
:next           inc       :ct
                jmp       ]lup
:bytes          ldy       rellength
                inc       rellength
                lda       #$00
                sep       $20
                sta       [relptr],y
                rep       $20
:23             lda       rellength
                clc
                adc       bytecnt
                sta       bytecnt
                bcc       :3
                inc       bytecnt+2
:3              lda       seglength
                clc
                adc       bytecnt
                sta       bytecnt
                lda       seglength+2
                adc       bytecnt+2
                sta       bytecnt+2

                bit       outfileopen
                jmi       :writeit
                lda       asmpath
                and       #$00ff
                tax
                sep       $20
]lup            lda       asmpath,x
                sta       filename,x
                dex
                bpl       ]lup
                rep       $20
                lda       linktype
                sta       :ftype
                stz       :auxtype
                stz       :auxtype+2
                lda       linkversion
                bne       :omf
                lda       orgval
                sta       :auxtype
                jmp       :i
:omf            lda       adrval
                sta       :auxtype
:i
                jsl       prodos
                dw        $06
                adrl      :finfo
                bcs       :createit
                lda       :ftype1
                cmp       linktype
                beq       :setinfo
                lda       #mismatch
                jmp       :gsoserr

:createit       jsl       prodos
                dw        $01
                adrl      :create
                bcc       :op

:setinfo        lda       linktype
                sta       :ftype1

                stz       :auxtype1
                stz       :auxtype1+2
                lda       linkversion
                bne       :omf1
                lda       orgval
                sta       :auxtype1
                jmp       :i1
:omf1           lda       adrval
                sta       :auxtype1
:i1
                jsl       prodos
                dw        $05
                adrl      :finfo
                jcs       :gsoserr

:op             jsl       prodos
                dw        $10
                adrl      :open
                jcs       :gsoserr
                lda       :open
                sta       :eof
                sta       :write
                sta       closefile
                sec
                ror       outfileopen

:writeit        lda       linkversion
                jeq       :abs

                lda       extrabytes
                beq       :write1
                lda       #$200
                sec
                sbc       extrabytes
                sta       extrabytes

                lda       #zeros
                sta       :buffer
                lda       #^zeros
                sta       :buffer+2
                lda       extrabytes
                sta       :request
                stz       :request+2

                lda       extrabytes
                clc
                adc       totalbytes
                sta       totalbytes
                bcc       :tb1
                inc       totalbytes+2
:tb1            stz       extrabytes
                jsl       prodos
                dw        $13
                adrl      :write
                jcs       :gsoserr

:write1         lda       seglength
                sta       lconst+1
                lda       seglength+2
                sta       lconst+3

                jsr       setfields

                lda       #^segheader
                sta       :buffer+2
                lda       #segheader
                sta       :buffer
                lda       bytecnt
                clc
                adc       #5
                sta       bytecnt
                bcc       :6
                inc       bytecnt+2
:6              lda       seghdrlen
                clc
                adc       #$05
                sta       :request
                stz       :request+2
                jsr       showcodelen
                lda       :request
                clc
                adc       totalbytes
                sta       totalbytes
                lda       :request+2
                adc       totalbytes+2
                sta       totalbytes+2
                lda       omfversion
                cmp       #$02
                bge       :p16
                lda       #^omfheader1
                sta       :buffer+2
                lda       #omfheader1
                sta       :buffer
                jsr       setomf1
:p16            jsl       prodos
                dw        $13
                adrl      :write
                jcs       :gsoserr

:abs
                stz       :ct
]lup            lda       :ct
                cmp       numfiles
                jeq       :dictionary
                asl
                asl
                asl
                asl
                asl
                tax
                lda       files+10,x
                cmp       segnum
                jne       :next1
                lda       files+8,x
                sta       :request
                stz       :request+2
                lda       files,x
                sta       :handle
                sta       workspace
                lda       files+2,x
                sta       :handle+2
                sta       workspace+2
                psl       :handle
                _HLock
                ldy       #$02
                lda       [workspace]
                sta       :buffer
                lda       [workspace],y
                sta       :buffer+2

                lda       :request
                clc
                adc       totalbytes
                sta       totalbytes
                lda       :request+2
                adc       totalbytes+2
                sta       totalbytes+2

                jsl       prodos
                dw        $13
                adrl      :write

                php
                pha
                phx
                _getmark  :eof
                _seteof   :eof
                psl       :handle
                _HUnlock
                psl       :handle
                _DisposeHandle
                plx
                pla
                plp
                jcs       :gsoserr

:next1          inc       :ct
                jmp       ]lup

:dictionary     lda       linkversion
                jeq       :abs1
                lda       rellength
                sta       :request
                stz       :request+2
                lda       relptr
                sta       :buffer
                lda       relptr+2
                sta       :buffer+2

                lda       :request
                clc
                adc       totalbytes
                sta       totalbytes
                lda       :request+2
                adc       totalbytes+2
                sta       totalbytes+2

                jsl       prodos
                dw        $13
                adrl      :write
                jcs       :gsoserr

                plp
                clc
                rts
:abs1           jsl       prodos
                dw        $14
                adrl      closefile
                stz       outfileopen
                stz       closefile
                lda       linkversion
                bne       :gsplp
                lda       #$0d
                jsr       drawchar
                psl       #asmpath
                _QADrawString
                psl       #:savstr
                _QADrawString
:gsplp          plp
                clc
                rts
:gsoserr        rep       $30
                sta       prodoserr
                jsl       prodos
                dw        $14
                adrl      closefile
                stz       outfileopen
                lda       #doserror
                plp
                sec
                rts

:savstr         str       ' saved.'
:mystr          str       'Rel length $'
:handle         ds        4
:ct             ds        2
:open           dw        $00
                adrl      asmpath
                adrl      $00
:eof            dw        $00
                adrl      $00
:create         adrl      asmpath
                dw        $e3
:ftype          dw        $b3                       ;exe for now
:auxtype        adrl      $00
                dw        $01
                adrl      $00
:write          dw        $00
:buffer         adrl      $00
:request        adrl      $00
                adrl      $00
:finfo          adrl      asmpath
                ds        2,0
:ftype1         ds        2
:auxtype1       ds        4,0
                ds        16,0

closefile       dw        $00


setfields       php
                rep       $30
                lda       segmenthdl+2
                sta       segmentptr+2
                lda       segmenthdl
                sta       segmentptr
                ldy       #$02
                lda       [segmentptr]
                tax
                lda       [segmentptr],y
                sta       segmentptr+2
                stx       segmentptr
                lda       segnum
                asl
                asl
                asl
                asl
                asl
                asl
                sta       :offset
                clc
                adc       #kindfield
                tay
                lda       [segmentptr],y
                sta       kind
                lda       :offset
                clc
                adc       #dsfield
                tay
                lda       [segmentptr],y
                sta       resspc
                iny
                iny
                lda       [segmentptr],y
                sta       resspc+2
                lda       resspc
                clc
                adc       seglength
                sta       seglength
                lda       resspc+2
                adc       seglength+2
                sta       seglength+2

                lda       :offset
                clc
                adc       #orgfield
                tay
                lda       [segmentptr],y
                sta       org
                iny
                iny
                lda       [segmentptr],y
                sta       org+2

                lda       :offset
                clc
                adc       #alignfield
                tay
                lda       [segmentptr],y
                sta       align
                iny
                iny
                lda       [segmentptr],y
                sta       align+2

:xit            plp
                rts
:offset         ds        2

                mx        %00
typop           ldy       #$00
]lup            lda       (lineptr),y
                and       #$7f
                cmp       #' '
                blt       :bad
                bne       :start
                iny
                jmp       ]lup
:start          jsr       :check
                rep       $30
                bcc       :eval
                sta       lvalue
                jmp       :ok1
:eval           ldx       #$00
                jsr       eval
                bcc       :ok1
:bad            lda       #badoperand
                jmp       :sec1
:sec1           sec
                rts
:ok1            lda       lvalue
                and       #$00FF
                sta       linktype
                clc
                rts

:check          sep       $30
                and       #$7f
                cmp       #'a'
                blt       :c0
                cmp       #'z'+1
                bge       :c0
                and       #$5f
:c0             sta       :typ+1
                iny
                lda       (lineptr),y
                and       #$7f
                cmp       #' '+1
                blt       :chkbad
                cmp       #'a'
                blt       :c1
                cmp       #'z'+1
                bge       :c1
                and       #$5f
:c1             sta       :typ+2
                iny
                lda       (lineptr),y
                and       #$7f
                cmp       #' '+1
                blt       :chkbad
                cmp       #'a'
                blt       :c2
                cmp       #'z'+1
                bge       :c2
                and       #$5f
:c2             sta       :typ+3
                lda       #$03
                sta       :typ
                rep       $30
                pea       0
                psl       #:typ
                _QAConvertTxt2Typ
                ply
                bcc       :found
:chkbad         rep       $20
                clc
                rts
:found          rep       $20
                tya
                sec
                rts
:typ            ds        5


verop           bit       passnum
                bpl       :ver
                clc
                rts
:ver            bit       verchg
                bpl       :ver1
                clc
                rts
:ver1           ldx       #$00
                jsr       eval
                bcc       :ok
                rts
:ok             lda       lvalue
                beq       :bad
                cmp       #$03
                blt       :ok1
:bad            lda       #badvalue
                sec
                rts
:ok1            and       #$ff
                sta       omfversion
                sec
                ror       verchg
                clc
                rts

showendstr      php
                rep       $30
                lda       cancelflag
                jmi       :plp

                lda       linkversion
                bne       :gs
                psl       #:absstr
                _QADrawString
                jmp       :all

:gs             psl       #:gsstr
                _QADrawString
                pea       0
                lda       omfversion
                pha
                pea       0
                pea       0
                _QADrawDec
                jsr       :comma

:all            psl       totalbytes
                pea       0
                pea       0
                _QADrawDec

                psl       #:str2
                _QADrawString

                pea       0
                lda       totalerrs
                pha
                pea       0
                pea       0
                _QADrawDec

:end            lda       #$0d
                jsr       drawchar
                jsr       drawchar

                jsr       calctime

:plp            plp
                rts
:absstr         str       0d,'End of absolute linker command file, '
:gsstr          str       0d,'End of GS-linker command file, OMF version '
:str2           str       ' bytes, errors: '

:comma          php
                rep       $30
                lda       #','
                jsr       drawchar
                lda       #' '
                jsr       drawchar
                plp
                rts
calctime        php
                rep       $30
                pha
                pha
                pha
                _QAEndTiming
                pla
                sta       :hours
                pla
                sta       :minutes
                pla
                sta       :seconds

                stz       :flag

                psl       #:str1
                _QADrawString

                lda       :hours
                beq       :mins
                pea       0
                lda       :hours
                pha
                pea       0
                pea       0
                _QADrawDec

                psl       #:str2
                _QADrawString
                lda       :hours
                jsr       :plural
                inc       :flag
:mins           lda       :minutes
                beq       :secs
                lda       :flag
                beq       :m1
                jsr       :spc
:m1             pea       0
                lda       :minutes
                pha
                pea       0
                pea       0
                _QADrawDec

                psl       #:str3
                _QADrawString
                lda       :minutes
                jsr       :plural
                inc       :flag
:secs           lda       :flag
                beq       :s0
                lda       :seconds
                beq       :end
                jsr       :spc
                jmp       :s1
:s0             lda       :seconds
                bne       :s1
                lda       #'<'
                jsr       drawchar
                lda       #$20
                jsr       drawchar
                inc       :seconds
:s1             pea       0
                lda       :seconds
                pha
                pea       0
                pea       0
                _QADrawDec

                psl       #:str4
                _QADrawString
                lda       :seconds
                jsr       :plural
:end            lda       #'.'
                jsr       drawchar
                lda       #$0d
                jsr       drawchar
                jsr       drawchar
                plp
                rts
:plural         php
                rep       $30
                cmp       #$01
                beq       :c
                lda       #'s'
                jsr       drawchar
:c              plp
                rts
:spc            php
                rep       $30
                lda       #','
                jsr       drawchar
                lda       #' '
                jsr       drawchar
                plp
                rts

:flag           ds        2
:hours          ds        2
:minutes        ds        2
:seconds        ds        2
:str1           str       'Elapsed time (total) = '
:str2           str       ' hour'
:str3           str       ' minute'
:str4           str       ' second'


                mx        %00
purgeasm        php
                rep       $30
                lda       userid
                ora       #linkmemid+$100
                pha
                _Disposeall
                plp
                rts

getglobals      php
                rep       $30

:reset          lda       #$ffff
                sta       asmlablect
                jsr       incasmlablect
                bcc       :ok
                plp
                sec
                rts
:ok             lda       #^symtable
                sta       linksymtbl+2
                lda       #symtable
                sta       linksymtbl

                lda       linksymhdl
                sta       workspace
                lda       linksymhdl+2
                sta       workspace+2

                lda       [workspace]
                tax
                ldy       #$02
                lda       [workspace],y
                sta       workspace+2
                stx       workspace
                lda       #$0000
                tay
]lup            sta       [workspace],y
                iny
                iny
                cpy       #maxsymbols*4
                blt       ]lup

                lda       #$ffff
                ldx       #$00
]lup            sta       symtable,x
                inx
                inx
                cpx       #128*2
                blt       ]lup

                lda       #$01                      ;move lables to asm
                jsr       traverse
                plp
                clc
                rts

initvars        php
                rep       $30
                lda       #$b3
                sta       linktype
                stz       rezpath
                stz       filename
                stz       zipflag
                stz       objok
                stz       orgval
                stz       orgval+2
                stz       adrval
                stz       adrval+2
                stz       outfileopen
                stz       segmentptr
                stz       segmentptr+2
                stz       segmenthdl
                stz       segmenthdl+2
                stz       jmphdl
                stz       jmphdl+2
                stz       jmpptr
                stz       jmpptr+2
                stz       jmplength
                stz       segnum
                stz       maxsegnum
                stz       lableptr
                stz       lableptr+2
                stz       lableptr1
                stz       lableptr1+2
                stz       cancelflag
                stz       totalerrs
                stz       lnkflag
                stz       passnum
                stz       numfiles
                stz       asmlablect
                stz       caseflag
                stz       reloffset
                stz       reloffset+2
                stz       omfok
                stz       linksymnum
                stz       linksymtbl
                stz       linksymtbl+2
                stz       linksymhdl
                stz       linksymhdl+2
                do        oldshell
                lda       #$ffff
                sta       linklstflag,x
                fin
                stz       globalhdl
                stz       globalhdl+2
                stz       verchg
                stz       lkvchg
                lda       #$01
                sta       linkversion
                lda       #$02
                sta       omfversion
                stz       totalbytes
                stz       totalbytes+2
                stz       savcount
                lda       #$ffff
                sta       dynamic
                ldx       #$00
                lda       #$ffff
]lup            sta       globaltbl,x
                sta       symtable,x
                inx
                inx
                cpx       #256
                blt       ]lup

                _QAStartTiming

                plp
                rts
:s              ds        2


disposemem      php
                rep       $30
                lda       userid
                ora       #linkmemid
                pha
                _DisposeAll
                lda       userid
                ora       #linkmemid+$100
                pha
                _DisposeAll
                lda       userid
                ora       #linkmemid+$200
                pha
                _DisposeAll
                stz       linksymhdl
                stz       linksymhdl+2
                stz       globalhdl
                stz       globalhdl+2
                stz       segmenthdl
                stz       segmenthdl+2
                plp
                rts

readkey         php
                rep       $30
                phx
                phy
                pea       0
                _QAKeyAvail
                pla
                beq       :clc
                pha
                _QAGetChar
                pla
                and       #$7f
                ply
                plx
                plp
                sec
                rts
:clc            ply
                plx
                plp
                clc
                rts

zeros           ds        512,0

