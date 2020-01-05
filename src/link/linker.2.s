                mx          %00
rezop           lda         passnum
                bne         :ok
                clc
                rts
:ok             lda         rezpath
                beq         :ok0
                lda         #illegalcmd
                sec
                rts
:ok0            lda         #$00
                jsr         getpath
                bcc         :ok1
                rts
:ok1            sep         $30
                ldx         asmpath
]lup            lda         asmpath,x
                sta         rezpath+1,x
                dex
                bpl         ]lup
                rep         $30
                lda         rezpath
                xba
                and         #$FF
                sta         rezpath
                clc
                rts

rezbuffsize     =           $1000

writerez        php
                rep         $30
                lda         linkversion
                beq         :clc
                lda         rezpath
                beq         :clc
                xba
                sta         rezpath
                lda         filename
                and         #$FF
                beq         :clc                      ;no SAV was done
                psl         #:str
                _QADrawString
                psl         #rezpath+1
                _QADrawString
                lda         #$0d
                jsr         drawchar
                lda         #$0d
                jsr         drawchar
                lda         rezpath
                xba
                sta         rezpath
                jsr         writerez1
:clc            plp
                clc
                rts
:str            str         'Importing RESOURCES from: '

writerez1       php
                sep         $30
                ldx         filename
]lup            lda         filename,x
                sta         asmpath+1,x
                dex
                bpl         ]lup
                rep         $30
                stz         :outref
                stz         :rezref
                stz         :handle
                stz         :handle+2
                lda         asmpath
                xba
                and         #$ff
                sta         asmpath
                stz         :outtype
                stz         :outaux
                stz         :outaux+2
                stz         :outstor
                stz         :outacc
                jsl         prodos
                dw          $2006                     ;GSOS Open
                adrl        :outinfo
                jcs         :err
                lda         :outstor
                cmp         #$0005
                beq         :copy
                psl         :outaux
                lda         :outtype
                pha
                lda         :outacc
                pha
                psl         #asmpath
                _CreateResourceFile
                jcs         :err
:copy           psl         #$00
                psl         #rezbuffsize
                lda         userid
                ora         #linkmemid
                pha
                pea         $8000
                psl         #$00
                _NewHandle
                plx
                ply
                jcs         :err
                sty         :handle+2
                sty         zpage+2
                stx         :handle
                stx         zpage
                ldy         #$02
                lda         [zpage]
                sta         :buffer1
                lda         [zpage],y
                sta         :buffer1+2
                jsl         prodos
                dw          $2010
                adrl        :rezopen
                jcs         :err
                jsl         prodos
                dw          $2010
                adrl        :outopen
                jcs         :err
                lda         :outref
                sta         :eofref
                jsl         prodos
                dw          $2018
                adrl        :eofparm
                jcs         :err
:loop           lda         #rezbuffsize
                sta         :request1
                stz         :request1+2
                stz         :transfer1
                stz         :transfer1+2
                lda         :rezref
                sta         :readref
                jsl         prodos
                dw          $2012
                adrl        :readparm
                bcc         :write
                cmp         #$4c
                jne         :err
                lda         :transfer1
                ora         :transfer1+2
                beq         :noerr
:write          lda         :transfer1
                sta         :request1
                lda         :transfer1+2
                sta         :request1+2
                stz         :transfer1
                stz         :transfer1+2
                lda         :outref
                sta         :readref
                jsl         prodos
                dw          $2013
                adrl        :readparm
                jcs         :err
                jmp         :loop
:noerr          lda         #$00
:err            pha
                cmp         #$00
                beq         :close
                sta         prodoserr
                lda         #doserror
                jsr         linkerror
                stz         prodoserr
:close          lda         :outref
                beq         :c1
                sta         :closeref
                jsl         prodos
                dw          $2014
                adrl        :closeparm
:c1             lda         :rezref
                beq         :pla
                sta         :closeref
                jsl         prodos
                dw          $2014
                adrl        :closeparm
:pla            lda         :handle
                ora         :handle+2
                beq         :pla1
                psl         :handle
                _DisposeHandle
                stz         :handle
                stz         :handle+2
:pla1           pla
                plp
                cmp         one
                rts

:handle         ds          4
:eofparm        dw          3
:eofref         dw          0
                dw          0
                adrl        0
:readparm       dw          4
:readref        dw          0
:buffer1        adrl        0
:request1       adrl        0
:transfer1      adrl        0

:rezopen        dw          4
:rezref         dw          0
                adrl        rezpath
                dw          1                         ;read only
                dw          1                         ;resource fork
:outopen        dw          4
:outref         dw          0
                adrl        asmpath
                dw          0                         ;read write
                dw          1

:outinfo        dw          5
                adrl        asmpath
:outacc         dw          0
:outtype        dw          0
:outaux         adrl        0
:outstor        dw          0

:closeparm      dw          1
:closeref       ds          2

express         php
                rep         $30
                lda         linkversion
                beq         :clc
                bit         zipflag
                bpl         :clc
                psl         #:str
                _QADrawString
                psl         #filename
                _QADrawString
                psl         #:str1
                _QADrawString
                do          doexpress
                jsr         writeexp
                fin
:clc            plp
                clc
                rts
:str            str         'Expressing: '
:str1           str         '....'



setomf1         php
                rep         $30
                lda         resspc
                sta         resspc1
                lda         resspc+2
                sta         resspc1+2
                lda         seglength
                sta         seglength1
                lda         seglength+2
                sta         seglength1+2
                lda         org
                sta         org1
                lda         org+2
                sta         org1+2
                lda         align
                sta         align1
                lda         align+2
                sta         align1+2


                lda         lconst+1
                sta         lconst1+1
                lda         lconst+3
                sta         lconst1+3

                lda         segnum
                sta         segnum1
                lda         kind
                sep         $20
                sta         kind1
                ldx         #$00
]lup            lda         dispname,x
                sta         dispname1,x
                inx
                cpx         #namelen*2+4
                blt         ]lup

                rep         $20
                lda         bytecnt
                sta         :count
                lda         bytecnt+2
                sta         :count+2
                lda         :count
                and         #$1ff
                sta         extrabytes
                lup         9
                lsr         :count+2
                ror         :count
                --^
                lda         extrabytes
                beq         :noinc
                inc         :count
                bne         :noinc
                inc         :count+2
:noinc          lda         :count
                sta         blkcount
                lda         :count+2
                sta         blkcount+2

                plp
                rts
:count          ds          4

jumpentry       php
                rep         $30
                phy
                phx
                lda         linkversion
                jeq         :clc

                lda         segmenthdl+2
                sta         segmentptr+2
                lda         segmenthdl
                sta         segmentptr
                ldy         #$02
                lda         [segmentptr]
                tax
                lda         [segmentptr],y
                sta         segmentptr+2
                stx         segmentptr
                lda         foundlable+24
                asl
                asl
                asl
                asl
                asl
                asl
                clc
                adc         #kindfield
                tay
                lda         [segmentptr],y
                ldx         omfversion
                cpx         #$02
                blt         :80
                bit         #$8000
                beq         :clc
                jmp         :enter
:80             bit         #$80
                beq         :clc
:enter          jsr         newjmpentry
                bcs         :sec
                psl         jmphdl
                _HLock
                lda         interseg
                and         #$7fff
                sta         jseg
                lda         omfoff2
                sta         joffset
                lda         omfoff2+2
                sta         joffset+2
                ldy         jmplength
                ldx         #$00
                sep         $20
]lup            lda         jmptblrec,x
                sta         [jmpptr],y
                inx
                iny
                cpx         #jmptblend-jmptblrec
                blt         ]lup
                rep         $20
                lda         jmplength
                sty         jmplength
                ldx         omfversion
                cpx         #$03
                bge         :noadd
                clc
                adc         #$08
:noadd          clc
                adc         #jjsl-jmptblrec
                sta         omfoff2
                lda         maxsegnum
                ora         #$8000
                sta         interseg
                sec
                ror         dynamic
:clc            psl         jmphdl
                _HUnlock
                plx
                ply
                plp
                clc
                rts
:sec            pha
                lda         jmphdl
                ora         jmphdl+2
                beq         :sec1
                psl         jmphdl
                _HUnlock
:sec1           pla
                plx
                ply
                plp
                clc
                rts

jmptblrec
                dw          $00                       ;userid
                dw          $01                       ;load file number
jseg            dw          $00
joffset         adrl        $00
jjsl            jsl         $00000000
jmptblend

newjmpentry     php
                rep         $30
                lda         jmphdl
                ora         jmphdl+2
                bne         :resize
                psl         #$00
                psl         #jmptblend-jmptblrec
                lda         userid
                ora         #linkmemid
                pha
                pea         $8000
                psl         #$00
                _NewHandle
                plx
                ply
                jcs         :err
                sty         jmphdl+2
                stx         jmphdl
                sty         jmpptr+2
                stx         jmpptr
                ldy         #$02
                lda         [jmpptr]
                tax
                lda         [jmpptr],y
                sta         jmpptr+2
                stx         jmpptr
                jmp         :clc
:resize         psl         jmphdl
                _HUnlock
                psl         #$00
                psl         jmphdl
                _GetHandleSize
                pll         :size
                lda         :size
                clc
                adc         #jmptblend-jmptblrec
                sta         :size
                lda         :size+2
                adc         #^jmptblend-jmptblrec
                sta         :size+2
                lda         :size+2
                bne         :toobig
                psl         :size
                psl         jmphdl
                _SetHandleSize
                bcs         :err
                psl         jmphdl
                _HLock
                ldy         #$02
                lda         [jmphdl]
                sta         jmpptr
                lda         [jmphdl],y
                sta         jmpptr+2
                jmp         :clc
:toobig         lda         #jmptblfull
                jmp         :err
:clc            plp
                clc
                rts
:err            plp
                sec
                rts
:size           ds          4

writejmpseg     php
                rep         $30

                lda         linkversion
                jeq         :clc
                bit         outfileopen
                jpl         :clc
                lda         jmplength
                jeq         :clc
                lda         jmphdl
                ora         jmphdl+2
                jeq         :clc
                lda         closefile
                sta         :write

                jsr         dosegname
                sep         $30
                ldx         #$01
]lup            lda         :jmpname,x
                sta         segname-1,x
                inx
                cpx         :jmpname
                blt         ]lup
                beq         ]lup
]lup            cpx         #namelen
                bge         :setup
                lda         #$20
                sta         segname-1,x
                inx
                bra         ]lup
:setup          rep         $30
                stz         align
                stz         align+2
                stz         resspc
                stz         resspc+2
                stz         org
                stz         org+2
                lda         #$1002
                sta         kind

                lda         #zeros
                sta         :buffer
                lda         #^zeros
                sta         :buffer+2

                lda         extrabytes
                beq         :write1
                lda         #$200
                sec
                sbc         extrabytes
                sta         extrabytes

                lda         extrabytes
                sta         :request
                stz         :request+2

                lda         :request
                clc
                adc         totalbytes
                sta         totalbytes
                lda         :request+2
                adc         totalbytes+2
                sta         totalbytes+2
                stz         extrabytes
                jsl         prodos
                dw          $13
                adrl        :write
                jcs         :doserr

:write1         lda         jmplength
                sta         lconst+1
                sta         seglength
                stz         lconst+3
                stz         seglength+2
                lda         omfversion
                cmp         #$03
                bge         :noadd
                lda         lconst+1
                clc
                adc         #$08
                sta         lconst+1
                sta         seglength
                bcc         :noadd
                inc         lconst+3
                inc         seglength+2
:noadd          lda         lconst+1
                clc
                adc         #$04
                sta         lconst+1
                sta         seglength
                bcc         :noadd2
                inc         lconst+3
                inc         seglength+2
:noadd2         lda         seghdrlen
                clc
                adc         lconst+1
                sta         bytecnt
                lda         #$00
                adc         lconst+3
                sta         bytecnt+2
                lda         bytecnt
                clc
                adc         #$06                      ;1 byte $00 (end), 5 for lconst ($f2)
                sta         bytecnt
                bcc         :noadd1
                inc         bytecnt+2
:noadd1         jsr         showjmplen
                lda         maxsegnum
                sta         segnum
                lda         #segheader
                sta         :buffer
                lda         #^segheader
                sta         :buffer+2

                stz         :request+2
                lda         seghdrlen
                clc
                adc         #$05
                sta         :request
                bcc         :n1
                inc         :request+2

:n1             lda         omfversion
                cmp         #$02
                bge         :writehdr
                lda         #omfheader1
                sta         :buffer
                lda         #^omfheader1
                sta         :buffer+2
                jsr         setomf1
:writehdr
                lda         :request
                clc
                adc         totalbytes
                sta         totalbytes
                lda         :request+2
                adc         totalbytes+2
                sta         totalbytes+2

                jsl         prodos
                dw          $13
                adrl        :write
                jcs         :doserr

                lda         omfversion
                cmp         #$03
                bge         :omf3

                lda         #zeros
                sta         :buffer
                lda         #^zeros
                sta         :buffer+2
                stz         :request+2
                lda         #$08
                sta         :request

                lda         :request
                clc
                adc         totalbytes
                sta         totalbytes
                lda         :request+2
                adc         totalbytes+2
                sta         totalbytes+2

                jsl         prodos
                dw          $13
                adrl        :write
                jcs         :doserr

:omf3
                psl         jmphdl
                _HLock
                lda         jmphdl
                sta         jmpptr
                lda         jmphdl+2
                sta         jmpptr+2
                lda         [jmpptr]
                sta         :buffer
                ldy         #$02
                lda         [jmpptr],y
                sta         :buffer+2
                psl         #$00
                psl         jmphdl
                _GetHandleSize
                pll         :request

                lda         :request
                clc
                adc         totalbytes
                sta         totalbytes
                lda         :request+2
                adc         totalbytes+2
                sta         totalbytes+2

                jsl         prodos
                dw          $13
                adrl        :write
                jcs         :doserr

                lda         #zeros
                sta         :buffer
                lda         #^zeros
                sta         :buffer+2
                stz         :request+2
                lda         #$05
                sta         :request

                lda         :request
                clc
                adc         totalbytes
                sta         totalbytes
                lda         :request+2
                adc         totalbytes+2
                sta         totalbytes+2
                jsl         prodos
                dw          $13
                adrl        :write
                jcs         :doserr

                lda         :write
                sta         :eof
                _getmark    :eof
                _seteof     :eof
:clc            plp
                clc
                rts
:sec            plp
                sec
                rts
:doserr         sta         prodoserr
                lda         #doserror
                jmp         :sec
:jmpname        str         'SEGJPTABLE'
:eof            dw          $00
                adrl        $00
:write          dw          $00
:buffer         ds          4
:request        ds          4
                ds          4


isegwarning     php
                rep         $30
                lda         linkversion
                jeq         :xit
                lda         segnum
                cmp         extseg
                jeq         :xit
                lda         segmenthdl+2
                sta         segmentptr+2
                lda         segmenthdl
                sta         segmentptr
                ldy         #$02
                lda         [segmentptr]
                tax
                lda         [segmentptr],y
                sta         segmentptr+2
                stx         segmentptr
                lda         extseg
                asl
                asl
                asl
                asl
                asl
                asl
                clc
                adc         #kindfield
                tay
                lda         [segmentptr],y
                ldx         omfversion
                cpx         #$02
                blt         :80
                bit         #$8000
                beq         :xit
                jmp         :err
:80             bit         #$0080
                beq         :xit
:err            rep         $30
                pea         0
                _QAGetWindow
                pea         $ffff
                _QASetWindow
                psl         #:str
                _QADrawString
                lda         omfoff1
                jsr         prbytel
                lda         #$0d
                jsr         drawchar
                lda         #$0d
                jsr         drawchar
                _QAIncTotalErrs
                _QASetWindow
:xit            plp
                rts
:str            str         0d,'Illegal reference to a dynamic segment at $'


caselable       php
:doit           sep         $30
                ldx         labstr
                beq         :xit
]loop           ldy         labstr,x
                lda         converttable1,y
                sta         labstr,x
                dex
                bne         ]loop
:xit            plp
                rts

findlable
]ct             equ         workspace
]offset         equ         ]ct+$2
]pos            equ         ]offset+$2
]pos1           equ         ]pos+$2
]len1           equ         ]pos1+$2
]len2           equ         ]len1+$2
*]eval equ ]len2+2

:entry          php
                rep         $30
:normal         bit         caseflag
* bpl :macentry
                jsr         caselable
:macentry       stz         labtype
                lda         lablect
                beq         :notfound
                lda         labstr
                and         #$000F
                beq         :notfound
                sta         ]len1
                lda         labstr+$1
                and         #$7F
                jmp         :global
:global         asl
                tax
                lda         globaltbl,x
                bmi         :notfound
                sta         ]pos
:gloop
]lup            lda         ]pos
                asl
                asl
                tay
                lda         [lableptr1],y
                sta         lableptr
                iny
                iny
                lda         [lableptr1],y
                sta         lableptr+2
                stz         ]offset
                ldy         #$00
                lda         [lableptr],y
                and         #$0F
                sta         ]len2
                sep         $20
                iny
                iny
                ldx         #$02                      ;start at byte 2
]lup1           cpx         #$10
                bge         :movefound
                cpx         ]len1
                blt         :1
                beq         :1
                jmp         :goleft1
:notfound       plp
                clc
                rts
:1              cpx         ]len2
                blt         :2
                beq         :2
                jmp         :goright
:2              lda         labstr,x
                cmp         [lableptr],y
                bne         :next
                iny
                inx
                jmp         ]lup1
:next           blt         :goleft
                jmp         :goright
:goleft1        lda         ]len1
                cmp         ]len2
                beq         :movefound
:goleft         rep         $30
                ldy         #18                       ;leftptr
                lda         [lableptr],y
                bmi         :notfound
                sta         ]pos
                jmp         ]lup
:goright        rep         $30
                ldy         #20                       ;leftptr
                lda         [lableptr],y
                bmi         :notfound
                sta         ]pos
                jmp         ]lup

:movefound      rep         $30
                lda         ]pos
                asl
                asl
                tay
                lda         [lableptr1],y
                sta         lableptr
                iny
                iny
                lda         [lableptr1],y
                sta         lableptr+2
                ldy         #26
                lda         [lableptr],y
                bit         #linkequbit
                beq         :ldy
                bit         #linkequvalid
                bne         :ldy
                jmp         :notfound
:ldy            ldy         #$00
                ldx         #$00
]lup            lda         [lableptr],y
                sta         foundlable,x
                inx
                inx
                iny
                iny
                cpx         #32
                blt         ]lup
:mfplp          plp
                sec
                rts

insertlable
]ct             equ         workspace
]offset         equ         ]ct+$2
]pos            equ         ]offset+$2
]pos1           equ         ]pos+$2
]len1           equ         ]pos1+$2
]len2           equ         ]len1+$2

:entry          php
                rep         $30
                sta         labtype
                lda         lablect
                cmp         #maxlinklab               ;max number of lables
                blt         :ne1
                lda         #symfull                  ;symtable full
                jmp         :error
:ne1            jsr         caselable
:ne11           lda         labstr
                and         #$FF
                bne         :ne2
                lda         #badlable
                jmp         :error
:ne2
:ne22           sta         ]len1
                lda         labstr+$1                 ;first byte of string
                and         #$7F
:asl01          asl
                tax
                lda         globaltbl,x
                bpl         :start
                lda         #$FFFF
                sta         ]pos                      ;no previous
                lda         lablect
                sta         globaltbl,x
:save           rep         $30
                jsr         :saveit
:nosave         lda         #$00
                plp
                clc
                rts
:start          sta         ]pos
]lup            lda         ]pos
                asl
                asl
                tay
                lda         [lableptr1],y
                sta         lableptr
                iny
                iny
                lda         [lableptr1],y
                sta         lableptr+2
                stz         ]offset
                ldy         #$00
                sep         $20
                lda         [lableptr],y
                sta         ]len2
                iny
                iny
                ldx         #$02                      ;start at byte 2
]lup1           cpx         #$10
                jeq         :error
                cpx         ]len1
                blt         :1
                beq         :1
                jmp         :goleft1
:1              cpx         ]len2
                blt         :2
                beq         :2
                jmp         :goright
:2              lda         [lableptr],y
                cmp         labstr,x
                bne         :next
                iny
                inx
                jmp         ]lup1
:next           rep         $30
                blt         :goright
                jmp         :goleft
:goleft1        rep         $30
                lda         ]len1
                cmp         ]len2
                bne         :goleft
:replace        ldy         #26                       #26
                lda         [lableptr],y
                bit         #linkequbit
                beq         :duperr
                bit         #linkequvalid
                beq         :ora

:duperr         sep         $30
                ldx         #$00
]mov            lda         labstr,x
                sta         errlable,x
                inx
                cpx         #16
                blt         ]mov
                rep         $30
                lda         labtype
                bit         #linkentrybit
                bne         :dup
                lda         #duplable
                plp
                sec
                rts
:dup            lda         #dupentry
                plp
                sec
                rts
:ora            ora         #linkequvalid.$8000
                sta         [lableptr],y
                iny
                iny
                lda         labval                    ;replace equate
                sta         [lableptr],y
                iny
                iny
                lda         labval+$2
                sta         [lableptr],y
                ldy         #$00
]test           lda         [lableptr],y
                tyx
                sta         foundlable,x
                iny
                iny
                cpy         #32
                blt         ]test
                jmp         :nosave
:goleft         rep         $30
                ldy         #18                       ;leftptr
                lda         [lableptr],y
                bpl         :p1
                lda         lablect
                sta         [lableptr],y
                jmp         :save
:p1             sta         ]pos
                jmp         ]lup
:goright        rep         $30
                ldy         #20                       ;leftptr
                lda         [lableptr],y
                bpl         :p2
                lda         lablect
                sta         [lableptr],y
                jmp         :save
:p2             sta         ]pos
                jmp         ]lup
:error          plp
                sec
                rts
:saveit         sta         labnum
                pha
                lda         ]pos
                sta         labprev
                lda         labtype
                ora         #$8000
                sta         labtype
:si1            lda         #$FFFF
                sta         lableft
                sta         labright
                sta         lablocal
                pla
                sta         ]pos                      ;for movefound
                asl
                asl
                tay
                lda         nextlableptr
                sta         [lableptr1],y
                sta         lableptr
                iny
                iny
                lda         nextlableptr+2
                sta         [lableptr1],y
                sta         lableptr+2
                ldx         #$00
]test           lda         labstr,x
                txy
                sta         [lableptr],y
                sta         foundlable,x
                inx
                inx
                cpx         #32
                blt         ]test
                jsr         inclablect
                rts

drawlabstr      php
                rep         $30
                lda         labstr
                and         #$0f
                beq         :cr
                tay
                ldx         #$01
]l              lda         labstr,x
                phx
                phy
                jsr         drawchar
                ply
                plx
                inx
                dey
                bne         ]l
:cr             lda         #$0d
                jsr         drawchar
                plp
                rts



insertlableasm
]ct             equ         workspace
]offset         equ         ]ct+$2
]pos            equ         ]offset+$2
]pos1           equ         ]pos+$2
]len1           equ         ]pos1+$2
]len2           equ         ]len1+$2

:entry          php
                rep         $30
                sta         labtype

                jsr         caselable                 ;*** check case sensitivity flag

                lda         asmlablect
                cmp         #maxsymbols               ;max number of lables
                blt         :ne1
                lda         #symfull                  ;symtable full
                jmp         :error
:ne1            lda         labstr
                and         #$FF
                bne         :ne2
                lda         #badlable
                jmp         :error
:ne2
:ne22           sta         ]len1
                lda         labstr+$1                 ;first byte of string
                and         #$7F
:global         cmp         #']'
                bne         :asl01
                pha
                lda         labtype
                ora         #$02
                sta         labtype
                pla
:asl01          asl
                tax
                lda         symtable,x
                bpl         :start
                lda         #$FFFF
                sta         ]pos                      ;no previous
                lda         asmlablect
                sta         symtable,x
:save           rep         $30
                jsr         :saveit
                bcc         :nosave
                plp
                sec
                rts
:nosave         lda         #$00
                plp
                clc
                rts
:start          sta         ]pos
]lup            lda         ]pos
                asl
                asl
                tay
                lda         [lasmptr1],y
                sta         lasmptr
                iny
                iny
                lda         [lasmptr1],y
                sta         lasmptr+2
                stz         ]offset
                ldy         #$00
                sep         $20
                lda         [lasmptr],y
                sta         ]len2
                iny
                iny
                ldx         #$02                      ;start at byte 2
]lup1           cpx         #$10
                jeq         :error
                cpx         ]len1
                blt         :1
                beq         :1
                jmp         :goleft1
:1              cpx         ]len2
                blt         :2
                beq         :2
                jmp         :goright
:2              lda         [lasmptr],y
                cmp         labstr,x
                bne         :next
                iny
                inx
                jmp         ]lup1
:next           rep         $30
                blt         :goright
                jmp         :goleft
:goleft1        rep         $30
                lda         ]len1
                cmp         ]len2
                bne         :goleft
:replace        ldy         #26                       ;offset to equ type
                lda         labtype
                ora         #$8008
                sta         [lasmptr],y
                iny
                iny
                lda         labval                    ;replace equate
                sta         [lasmptr],y
                iny
                iny
                lda         labval+$2
                sta         [lasmptr],y
                ldx         #$00
                ldy         #$00
]test           lda         [lasmptr],y
                sta         foundlable,x
                inx
                inx
                iny
                iny
                cpx         #32
                blt         ]test
                jmp         :nosave
:goleft         rep         $30
                ldy         #18                       ;leftptr
                lda         [lasmptr],y
                bpl         :p1
                lda         asmlablect
                sta         [lasmptr],y
                jmp         :save
:p1             sta         ]pos
                jmp         ]lup
:goright        rep         $30
                ldy         #20                       ;leftptr
                lda         [lasmptr],y
                bpl         :p2
                lda         asmlablect
                sta         [lasmptr],y
                jmp         :save
:p2             sta         ]pos
                jmp         ]lup
:error          plp
                sec
                rts
:saveit         sta         labnum
                pha
                lda         ]pos
                sta         labprev
                lda         labtype
                ora         #$8008                    ;absolute/equated lable
                sta         labtype
:si1            lda         #$FFFF
                sta         lableft
                sta         labright
                sta         lablocal
                pla
                sta         ]pos                      ;for movefound
                asl
                asl
                tay
                lda         asmnextlable
                sta         [lasmptr1],y
                sta         lasmptr
                iny
                iny
                lda         asmnextlable+2
                sta         [lasmptr1],y
                sta         lasmptr+2
                ldy         #$00
                ldx         #$00
]test           lda         labstr,x
                sta         [lasmptr],y
                sta         foundlable,x
                inx
                inx
                iny
                iny
                cpx         #32
                blt         ]test
                jsr         incasmlablect
                rts

traverse        php
                rep         $30
                sta         twhich
                asl
                tax
                lda         :tbl,x
                sta         :jsr+1
                stz         tct

                lda         #$00
                sta         :main
                sta         :recurslev
:loop           lda         :main
                asl
                tax
                lda         globaltbl,x
                jmi         :next
                pha
                jsr         :showtree
:next           inc         :main
                lda         :main
                cmp         #128
                blt         :loop
                lda         twhich
                cmp         #$02
                blt         :p
                cmp         #$04
                bge         :p
                lda         tct
                beq         :p1
                lda         #$0d
                jsr         drawchar
:p1             lda         #$0d
                jsr         drawchar
:p              plp
                rts
:main           ds          2
:recurslev      ds          2
:treechar       ds          2
:which          ds          2

:showtree       inc         :recurslev
                lda         lableptr+2
                pha
                lda         lableptr
                pha
                lda         7,s
                asl
                asl
                tay
                lda         [lableptr1],y
                sta         lableptr
                iny
                iny
                lda         [lableptr1],y
                sta         lableptr+2
                ldy         #18
                lda         #'R'
                sta         :char
                lda         [lableptr],y
                bmi         :next2
                pha
                jsr         :showtree
                lda         #'L'
                sta         :char
:next2          jsr         :print
                lda         #'R'
                sta         :char
                ldy         #20
                lda         [lableptr],y
                bmi         :done
                pha
                jsr         :showtree
:done           pla
                sta         lableptr
                pla
                sta         lableptr+2
                pla
                plx
                pha
                dec         :recurslev
                rts

:print          ldx         #$00
]lup            txy
                lda         [lableptr],y
                sta         labstr,x
                inx
                inx
                cpx         #32
                blt         ]lup
:jsr            jsr         $ffff
                sep         $20
:but            ldal        $e0c061
                bmi         :but
                rep         $20
                rts

:char           ds          2
:len            ds          2
:offset         ds          2
:bytes          ds          2

:tbl            dw          clrlocals
                dw          move2asm
                dw          showsyms
                dw          showents
                dw          rts
                dw          rts

rts             clc
                rts

showents        lda         labtype
                bit         #linkentrybit
                bne         showsyms
                rts

showsyms        ldx         tct
                beq         :lab
                lda         :tbl,x
                and         #$ff
                pha
                _QATabToCol
:lab            lda         twhich
                cmp         #$03
                bne         :lab1
                lda         labtype
                bit         #linkentused
                bne         :lab1
                lda         #'?'
                jsr         drawchar
:lab1           lda         labstr
                and         #$ff
                tay
                ldx         #$01
]lup            cpy         #$00
                beq         :done
                lda         labstr,x
                and         #$7f
                phy
                phx
                jsr         drawchar
                plx
                ply
                inx
                dey
                jmp         ]lup
:done           lda         #' '
                jsr         drawchar
                lda         #'='
                jsr         drawchar
                lda         #'$'
                jsr         drawchar

                lda         labval+2
                xba
                and         #$ff
                beq         :d1
                jsr         prbyte
:d1             lda         labval+2
                and         #$ff
                beq         :d2
                jsr         prbyte
:d2             lda         labval
                jsr         prbytel
                inc         tct
                lda         tct
                cmp         #$03
                blt         :r
                lda         #$0d
                jsr         drawchar
                stz         tct
:r              rts

:tbl            dfb         0,25,50

tct             ds          2
twhich          ds          2

move2asm        lda         linksymhdl
                sta         lasmptr1
                lda         linksymhdl+2
                sta         lasmptr1+2
                ldy         #$02
                lda         [lasmptr1]
                tax
                lda         [lasmptr1],y
                sta         lasmptr1+2
                stx         lasmptr1
                lda         labtype
                bit         #linkgeqbit
                bne         :insert
                and         #linkequbit.linkequvalid
                cmp         #linkequbit.linkequvalid
                beq         :insert
                rts
:insert         lda         #absolutebit.linkerbit
                sta         labtype
                jsr         insertlableasm
clrlocals
                ldy         #26
                lda         [lableptr],y
                and         #linkequvalid!$FFFF
                sta         [lableptr],y
                rts


newsegment      php
                rep         $30
                lda         segnum
                cmp         #maxsegs
                blt         :ok
                lda         #maxsegments
:sec            plp
                sec
                rts
:ok             inc         segnum
                inc         maxsegnum
                lda         segmenthdl
                ora         segmenthdl+2
                bne         :resize
                psl         #$00
                pea         $0000
                lda         segnum
                inc
                asl
                asl
                asl
                asl
                asl
                asl
                pha
                ldal        userid
                ora         #linkmemid+$200
                pha
                pea         $00
                psl         #$00
                _NewHandle
                plx
                ply
                jcs         :sec1
                stx         segmenthdl
                sty         segmenthdl+2
:resize         psl         segmenthdl
                _HUnlock
                pea         $00
                lda         segnum
                inc
                asl
                asl
                asl
                asl
                asl
                asl
                pha
                psl         segmenthdl
                _SetHandleSize
                jcs         :sec1
                psl         segmenthdl
                _HLock
                lda         segmenthdl
                sta         segmentptr
                lda         segmenthdl+2
                sta         segmentptr+2
                ldy         #$02
                lda         [segmentptr]
                tax
                lda         [segmentptr],y
                sta         segmentptr+2
                stx         segmentptr
                lda         segnum
                asl
                asl
                asl
                asl
                asl
                asl
                tay
                sty         :offset
                ldx         #$00
                lda         #$00
]lup            sta         [segmentptr],y
                inx
                inx
                iny
                iny
                cpx         #64
                blt         ]lup

                lda         :offset
                clc
                adc         #kindfield
                tay
                lda         #$1000                    ;init kind to $1000
                sta         [segmentptr],y

                plp
                clc
                rts
:sec1           rep         $30
                psl         segmenthdl
                _HLock
                lda         #outofmem
                plp
                sec
                rts
:offset         ds          2

inclablect      php
                rep         $30
                inc         lablect
                lda         lablect
                and         #%11111111
                bne         :normal
                psl         #$00
                psl         #$2000
                ldal        userid
                ora         #linkmemid
                pha
                pea         $8004                     ;page aligned/locked
                psl         #$00
                _NewHandle
                plx
                ply
                jcs         :sec
                sei
                pei         0
                pei         2
                stx         0
                sty         2
                ldy         #$02
                lda         [0]
                sta         nextlableptr
                lda         [0],y
                sta         nextlableptr+2
                pla
                sta         2
                pla
                sta         0
                plp
                clc
                rts
:normal         lda         nextlableptr
                clc
                adc         #32
                sta         nextlableptr
                bcc         :rts
                inc         nextlableptr+2
:rts            plp
                clc
                rts
:sec            lda         #symfull
                plp
                sec
                rts

incasmlablect   php
                rep         $30
                inc         asmlablect
                lda         asmlablect
                and         #%11111111
                bne         :normal
                psl         #$00
                psl         #$2000
                lda         userid
                ora         #linkmemid+$100
                pha
                pea         $8004                     ;page aligned/locked
                psl         #$00
                _NewHandle
                plx
                ply
                jcs         :sec
                sei
                pei         0
                pei         2
                stx         0
                sty         2
                ldy         #$02
                lda         [0]
                sta         asmnextlable
                lda         [0],y
                sta         asmnextlable+2
                pla
                sta         2
                pla
                sta         0
                plp
                clc
                rts
:normal         lda         asmnextlable
                clc
                adc         #32
                sta         asmnextlable
                bcc         :rts
                inc         asmnextlable+2
:rts            plp
                clc
                rts
:sec            lda         #symfull
                plp
                sec
                rts

getpath         php
                rep         $30
                and         #$FF
                sta         :sflag
                stz         asmpath
                stz         asmpath+2
                sep         $30
                ldy         #$00
]flush          lda         (lineptr),y
                and         #$7f
                cmp         #' '
                blt         :bad
                bne         :first
                iny
                jmp         ]flush
:first          cmp         #'.'
                jeq         :backup
                jmp         :ok
:bad            pea         #badoperand
                jmp         :error
:ok             ldx         #$00
:return         sep         $30
:save           lda         (lineptr),y
                and         #$7f
                cmp         #' '+1
                blt         :done
                cmp         #'/'
                bne         :cmp
                lda         #':'
:cmp            cmp         #'a'
                blt         :store
                cmp         #'z'+1
                bge         :store
                and         #$5f
:store          cpx         #128
                bge         :inx

                cmp         #'A'
                blt         :sta1
                cmp         #'Z'+1
                bge         :sta1
                ora         #$20
:sta1
                sta         asmpath+1,x
:inx            inx
                iny
                jmp         :save
:done           cpx         #64
                blt         :len
                ldx         #64
:len            stx         asmpath
                lda         :sflag
                beq         :plp
                lda         asmpath
                cmp         #63
                bge         :plp
                tax
                lda         asmpath,x
                and         #$7f
                cmp         #'/'
                beq         :plp
                lda         asmpath
                inc
                inc
                sta         asmpath
                lda         #'.'
                sta         asmpath+1,x
                inx
                lda         #'S'
                sta         asmpath+1,x
:plp            sep         $30
                lda         asmpath
                beq         :syn
                plp
                clc
                rts
:syn            rep         $30
                lda         #syntax
                plp
                sec
                rts
                mx          %11

:backup         stz         :level
:loop           sty         :y
                iny
                lda         (lineptr),y
                and         #$7f
                cmp         #' '+1
                blt         :pfx
                cmp         #'.'
                bne         :pfx
                iny
                lda         (lineptr),y
                and         #$7f
                cmp         #' '+1
                blt         :pfx
                cmp         #'/'
                bne         :pfx
                inc         :level
                iny
                sty         :y
                lda         (lineptr),y
                and         #$7f
                cmp         #'.'
                beq         :loop
:pfx            ldx         #$00
                lda         :level
                beq         :noexp
                rep         $30
                stz         asmpath
                _getprefix  :pfxparm
                sep         $30
                ldx         asmpath
                beq         :noexp
]lup            lda         asmpath,x
                and         #$7f
                cmp         #'/'
                bne         :store1
                lda         #':'
:store1         sta         asmpath,x
                dex
                bne         ]lup
                ldx         asmpath
                lda         asmpath,x
                cmp         #':'
                bne         :exp
                dex
:exp            cpx         #$00
                beq         :noexp
                lda         asmpath,x
                cmp         #':'
                bne         :dex
                dec         :level
                beq         :noexp
:dex            dex
                jmp         :exp
:noexp          stx         asmpath
                ldy         :y
                jmp         :return
:xit            pea         $00
:error          rep         $30
                pla
                plp
                cmp         :one
                rtl
:one            ds          2
:temp           ds          2
:level          ds          2
:y              ds          2
:sflag          ds          2,0
:pfxparm        dw          $00
                adrl        asmpath




converttable
                hex         0D0D0D0D0D0D0D0D0D200D0D0D0D0D0D
                hex         0D0D0D0D0D0D0D0D0D0D0D0D0D0D0D0D
                asc         ' !"#$%&'
                hex         27                        ;the ' character
                asc         '()*+,-./'
                asc         '0123456789'
                asc         ':;<=>?@'
                asc         'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
                asc         '[\]^_`'
                asc         'abcdefghijklmnopqrstuvwxyz'
                asc         '{|}~ '                   ;DEL is last character
                hex         0D0D0D0D0D0D0D0D0D200D0D0D0D0D0D
                hex         0D0D0D0D0D0D0D0D0D0D0D0D0D0D0D0D
                asc         ' !"#$%&'
                hex         27                        ;the ' character
                asc         '()*+,-./'
                asc         '0123456789'
                asc         ':;<=>?@'
                asc         'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
                asc         '[\]^_`'
                asc         'abcdefghijklmnopqrstuvwxyz'
                asc         '{|}~ '                   ;DEL is last character
converttable1
                hex         20202020202020202020202020202020
                hex         20202020202020202020202020202020
                asc         ' !"#$%&'
                hex         27                        ;the ' character
                asc         '()*+,-./'
                asc         '0123456789'
                asc         ':;<=>?@'
                asc         'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
                asc         '[\]^_`'
                asc         'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
                asc         '{|}~ '                   ;DEL is last character
                hex         20202020202020202020202020202020
                hex         20202020202020202020202020202020
                asc         ' !"#$%&'
                hex         27                        ;the ' character
                asc         '()*+,-./'
                asc         '0123456789'
                asc         ':;<=>?@'
                asc         'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
                asc         '[\]^_`'
                asc         'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
                asc         '{|}~ '                   ;DEL is last character


numfiles        ds          2
files           ds          maxfiles*32

symtable        ds          256,0
globaltbl       ds          256,0

