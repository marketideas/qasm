
getpath      php
             sep           $30
             sta           :sflag
             stz           pathname
             stz           pathname+1
             ldy           #$00
]flush       lda           [lineptr],y
             and           #$7f
             cmp           #' '
             blt           :bad
             bne           :first
             iny
             jmp           ]flush
:first       cmp           #'.'
             beq           :backup
             jmp           :ok
:bad         pea           #badoperand
             jmp           :error
:ok          ldx           #$00
:return      sep           $30
:save        lda           [lineptr],y
             and           #$7f
             cmp           #' '+1
             blt           :done
             cmp           #'/'
             bne           :cmp
             lda           #':'
:cmp
:store       cpx           #128
             bge           :inx
             sta           pathname+1,x
:inx         inx
             iny
             jmp           :save
:done        cpx           #64
             blt           :len
             ldx           #64
:len         stx           pathname
             lda           :sflag
             beq           :plp
             lda           pathname
             cmp           #63
             bge           :plp
             tax
             lda           pathname,x
             and           #$7f
             cmp           #'/'
             beq           :plp
             cmp           #':'
             beq           :plp
:ap          lda           pathname
             inc
             inc
             sta           pathname
             lda           #'.'
             sta           pathname+1,x
             inx
             lda           #'S'
             sta           pathname+1,x
:plp         sep           $30
             lda           pathname
             beq           :syn
             plp
             clc
             rts
:syn         rep           $30
             lda           #badoperand
             plp
             sec
             rts
             mx            %11

:backup      stz           :level
:loop        sty           :y
             iny
             lda           [lineptr],y
             and           #$7f
             cmp           #' '+1
             blt           :pfx
             cmp           #'.'
             bne           :pfx
             iny
             lda           [lineptr],y
             and           #$7f
             cmp           #' '+1
             blt           :pfx
             cmp           #'/'
             beq           :i
             cmp           #':'
             bne           :pfx
:i           inc           :level
             iny
             sty           :y
             lda           [lineptr],y
             and           #$7f
             cmp           #'.'
             beq           :loop
:pfx         ldx           #$00
             lda           :level
             beq           :noexp
             rep           $30
             stz           pathname
             _getprefix    :pfxparm
             sep           $30
             ldx           pathname
             beq           :noexp
]lup         lda           pathname,x
             and           #$7f
             cmp           #'/'
             bne           :store1
             lda           #':'
:store1      sta           pathname,x
             dex
             bne           ]lup
             ldx           pathname
             lda           pathname,x
             cmp           #':'
             bne           :exp
             dex
:exp         cpx           #$00
             beq           :noexp
             lda           pathname,x
             cmp           #':'
             bne           :dex
             dec           :level
             beq           :noexp
:dex         dex
             jmp           :exp
:noexp       stx           pathname
             ldy           :y
             jmp           :return
:xit         pea           $00
:error       rep           $30
             pla
             plp
             cmp           :one
             rtl
:one         ds            2
:temp        ds            2
:level       ds            2
:y           ds            2
:sflag       ds            2,0
:pfxparm     dw            $00
             adrl          pathname
pathname     ds            130,0
             mx            %00


dskop        php
             rep           $30
             lda           passnum
             bne           :pass2
             lda           #dskflag
             bit           modeflag
             bne           :nosize
             tsb           modeflag
             lda           objhdl
             ora           objhdl+2
             beq           :nosize
             lda           objhdl+2
             pha
             lda           objhdl
             pha
             _HUnlock
             psl           #dskobjsize+1
             lda           objhdl+2
             pha
             lda           objhdl
             pha
             _SetHandleSize
             lda           #dskobjsize
             sta           objsize
             lda           objhdl+2
             sta           workspace+2
             pha
             lda           objhdl
             sta           workspace
             pha
             _HLock
             ldy           #$02
             lda           [workspace]
             sta           objzpptr
             lda           [workspace],y
             sta           objzpptr+2

:nosize      lda           objptr
             sta           orgval
             sta           oldobj
             lda           objptr+2
             and           #$7fff
             sta           orgval+2
             sta           oldobj+2
             stz           reloffset
             stz           relct
             stz           objoffset
             stz           objoffset+2
             stz           oldoffset
             stz           oldoffset+2
             stz           objct
             plp
             clc
             rts

:pass2       lda           dskopen
             beq           :newfile
             jsr           closedsk
             jcs           :gsoserr
:newfile     lda           #$00
             jsr           getpath
             bcc           :ok
             plp
             sec
             rts
:ok          psl           #pathname
             _QASetObjPath
             sep           $30
             ldx           pathname
             stx           dskpath
]lup         lda           pathname,x
             sta           dskpath,x
             dex
             bne           ]lup
             rep           $30
             jsr           settypes
             _getfileinfo  dskinfo
             bcc           :test
             jsr           settypes
             _create       dskcreate
             jcs           :gsoserr
:test        lda           dsktype
             cmp           dskctype
             jne           :mismatch
             _open         dskopen
             jcs           :gsoserr
             lda           dskopen
             jsr           writedsk
             bcs           :gsoserr
             lda           objptr
             sta           orgval
             sta           oldobj
             lda           objptr+2
             and           #$7fff
             sta           orgval+2
             sta           oldobj+2
             stz           reloffset
             stz           relct
             stz           objoffset
             stz           objoffset+2
             stz           oldoffset
             stz           oldoffset+2
             stz           objct
             plp
             clc
             rts

:mismatch    lda           #filemismatch
:gsoserr     sta           prodoserr
             lda           #doserror
             plp
             sec
             rts

settypes     php
             rep           $30
             ldy           #$f8
             lda           #relflag
             bit           modeflag
             bne           :rel
             lda           objtype
             and           #$ff
             tay
:rel         sty           dskctype
             sty           dsktype
             cpy           #$06
             bne           :zeroaux
             lda           orgval
             sta           dskaux
             sta           dskcaux
             stz           dskaux+2
             stz           dskcaux+2
             jmp           :time
:zeroaux     stz           dskaux
             stz           dskaux+2
             stz           dskcaux
             stz           dskcaux+2
:time        stz           dskctime
             stz           dskctime+2
             plp
             rts

settypes1    php
             rep           $30
             ldy           #$f8
             lda           #relflag
             bit           modeflag
             bne           :rel
             lda           objtype
             and           #$ff
             tay
:rel         sty           dskctype
             sty           dsktype
             cpy           #$06
             bne           :zeroaux
             lda           orgval
             sta           dskaux
             sta           dskcaux
             stz           dskaux+2
             stz           dskcaux+2
             jmp           :plp
:zeroaux     stz           dskaux
             stz           dskaux+2
             stz           dskcaux
             stz           dskcaux+2
:plp         plp
             rts


savop        php
             rep           $30
             stz           :openflag
             lda           modeflag
             bit           #dskflag
             beq           :pass
             lda           #badopcode
             plp
             sec
             rts
:pass        lda           passnum
             bne           :sav
             jmp           :all
:sav         lda           errorct
             beq           :path
:badsav      rep           $30
             lda           #badsav
             plp
             sec
             rts
:path        lda           #$00                                      ;no append '.S'
             jsr           getpath
             bcc           :ok
             plp
             sec
             rts
:ok          psl           #pathname
             _QASetObjPath
             lda           objzpptr
             sta           :where
             lda           objzpptr+2
             sta           :where+2
             lda           objct
             sta           :request
                                                                     ;*** beq :badsav
             stz           :request+2
             stz           :openparm
             stz           :closeparm
:info        _getfileinfo  :infoparm
             bcc           :test
             cmp           #$46
             jne           :mlierr
             lda           #relflag
             bit           modeflag
             beq           :notrel1
             lda           #$f8
             sta           :cftype
             sta           :ftype
             lda           objct
             sta           :cauxtype
             sta           :auxtype
             stz           :cauxtype+2
             jmp           :create
:notrel1     lda           orgval
             sta           :cauxtype
             sta           :auxtype
             stz           :cauxtype+2
             lda           objtype
             sta           :cftype
             sta           :ftype
:create      stz           :ctime
             stz           :ctime+2
             _create       :createparm
             jcs           :mlierr
             jmp           :open
:test        lda           #relflag
             bit           modeflag
             beq           :notrel
             lda           #$f8
             cmp           :ftype
             bne           :mismatch
             sta           :ftype
             lda           objct
             sta           :auxtype
             stz           :auxtype+2
             jmp           :set
:notrel      lda           orgval
             sta           :auxtype
             stz           :auxtype+2
             lda           objtype
             cmp           :ftype
             bne           :mismatch
             sta           :ftype
             jmp           :set
:mismatch    lda           #filemismatch
             jmp           :mlierr
:set         _setfileinfo  :infoparm
             jcs           :mlierr
:open        _open         :openparm
             jcs           :mlierr
             sec
             ror           :openflag
             lda           :openparm
             sta           :closeparm
             sta           :eofparm
             sta           :writeparm
             _write        :writeparm
             bcs           :mlierr
             lda           #relflag
             bit           modeflag
             beq           :seof
             lda           :openparm
             jsr           writerel
             bcs           :mlierr
:seof        _getmark      :eofparm
             _seteof       :eofparm
             bcs           :mlierr
             jsr           :show
:all         rep           $30
* lda #relflag
* bit modeflag
* beq :a1
* jsr endop
:a1          stz           objoffset
             stz           objoffset+2
             stz           oldoffset
             stz           oldoffset+2
             stz           relct
             stz           reloffset
             lda           objptr
             sta           orgval
             sta           oldobj
             lda           objptr+2
             sta           orgval+2
             sta           oldobj+2
             lda           #$8000
             trb           orgval+2

:done        lda           #$0000
:mlierr      pha
             bit           :openflag
             bpl           :err1
             _close        :closeparm
:err1        pla
             sta           prodoserr
             cmp           :one
             bcc           :plp
             lda           #doserror
:plp         plp
             cmp           :one
             rts
:one         dw            $01
:openflag    ds            2
:createflag  ds            2

:infoparm    adrl          pathname
             dw            $00
:ftype       dw            $00
:auxtype     ds            18

:createparm  adrl          pathname
             dw            $e3
:cftype      dw            $00
:cauxtype    adrl          $00
             dw            $01
:ctime       adrl          $0000

:openparm    dw            $00
             adrl          pathname
             adrl          $00

:eofparm     dw            $00
             adrl          $00

:writeparm   dw            $00
:where       adrl          $00
:request     adrl          $00
             adrl          $00

:closeparm   dw            $00
:str1        str           'Object saved as '
:str2        str           ',A$'
:str3        str           ',L$'

:show        php
             rep           $30
             lda           #$8000
             trb           listflag
             lda           #$0d
             jsr           drawchar
             psl           #:str1
             _QADrawString
             psl           #pathname
             _QADrawString
             psl           #:str2
             _QADrawString
             lda           :auxtype
             jsr           prbytel
             psl           #:str3
             _QADrawString
             ldy           #$00
             lda           :eofparm+5
             and           #$ff
             beq           :s1
             jsr           prbyte
             iny
:s1          lda           :eofparm+4
             and           #$ff
             bne           :s2
             cpy           #$00
             beq           :s3
:s2          jsr           prbyte
:s3          lda           :eofparm+2
             jsr           prbytel
             lda           #','
             jsr           drawchar
             lda           :ftype
             pha
             psl           #:typ
             _QAConvertTyp2Txt
             psl           #:typ
             _QADrawString
             lda           #$0d
             jsr           drawchar
             plp
             rts
:typ         ds            4

writerel     php                                                     ;must enter with file open...
             rep           $30                                       ;at EOF AND with A holding file
             sta           :writeparm                                ;reference number
             lda           #relflag
             bit           modeflag
             bne           :ok
:clc         plp
             clc
             rts

:ok          lda           relct
             sta           :request
             stz           :request+$2
             lda           relptr
             sta           :where
             lda           relptr+$2
             sta           :where+$2
             jsl           prodos
             dw            $13                                       ;WRITE
             adrl          :writeparm
             jcs           :perr
             lda           :request
             clc
             adc           totbytes
             sta           totbytes
             lda           :request+2
             adc           totbytes+2
             sta           totbytes+2

:checkerr    stz           relct
             lda           errvalid
             beq           :ds
             ldy           relct
             sep           $20
             lda           #%11101111                                ;err link opcode
             sta           [relptr],y
             rep           $20
             iny
             lda           erraddress
             sta           [relptr],y
             iny
             iny
             sep           $20
             lda           erraddress+2
             sta           [relptr],y
             rep           $20
             iny
             sty           relct
             stz           errvalid
             stz           erraddress
             stz           erraddress+2

:ds          lda           dsfill
             beq           :rellast
             ldy           relct
             lda           #$00cf
             sta           [relptr],y
             iny
             lda           dsoffset
             sta           [relptr],y
             iny
             iny
             lda           dsfill
             sep           $20
             sta           [relptr],y
             rep           $20
             iny
             sty           relct
             stz           dsfill
             stz           dsoffset

:rellast     ldy           relct
             lda           #$00
             sta           [relptr],y
             iny
             sty           :request
             stz           relct

             jsl           prodos
             dw            $13                                       ;WRITE
             adrl          :writeparm
             jcs           :perr
             lda           :request
             clc
             adc           totbytes
             sta           totbytes
             lda           :request+2
             adc           totbytes+2
             sta           totbytes+2

:lables      jsr           :rellables
             jcs           :perr
             lda           #$00
             sta           :buffer
             lda           #$01
             sta           :request
             stz           :request+2

             lda           :request
             clc
             adc           totbytes
             sta           totbytes
             lda           :request+2
             adc           totbytes+2
             sta           totbytes+2

             jsl           prodos
             dw            $13                                       ;WRITE
             adrl          :writeparm
             jcs           :perr
             stz           relct
             plp
             clc
             rts

:perr        sta           prodoserr
             stz           relct
             lda           #doserror
             plp
             sec
             rts

:writeparm
             ds            2
:where       ds            4
:request     ds            4
             ds            4

:rellables   php
             rep           $30
             stz           :errcode
             stz           :request+$2
             lda           #:buffer
             sta           :where
             lda           #^:buffer
             sta           :where+2
             lda           #$00
             sta           :main
:loop        lda           :errcode
             bne           :relerr
             lda           :main
             cmp           lablect
             blt           :doit
:relerr      lda           :errcode
             plp
             cmp           :one
             rts
:doit        asl
             asl
             tay
             lda           [lableptr1],y
             sta           lableptr
             iny
             iny
             lda           [lableptr1],y
             sta           lableptr+2

             ldy           #$00
             stz           :offset
             lda           [lableptr]
             and           #label_mask
             bne           :stalen
             inc           :main
             jmp           :loop
:stalen      sta           :len
             clc
             adc           #4
             sta           :request
             ldy           #o_labtype
             lda           [lableptr],y
             bit           #entrybit.externalbit
             jeq           :rts
             bit           #variablebit.localbit.macrobit.macvarbit
             jne           :rts
             sep           $20
             ldx           #$00
             ldy           #$01
]lup         lda           [lableptr],y
             and           #$7f
:sta         sta           :buffer+1,x
             iny
             inx
             cpx           :len
             blt           ]lup

             rep           $30
             ldy           #o_labtype
             lda           [lableptr],y
             bit           #entrybit
             bne           :ent1
             bit           #usedbit
             beq           :rts
:ent1        lda           [lableptr],y
             pha
             bit           #externalbit
             beq           :ent
             lda           #$80
             tsb           :len
:ent         lda           1,s
             and           #entrybit
             beq           :abs
             lda           #$40
             tsb           :len
:abs         pla
             bpl           :value
             lda           #$20
             tsb           :len
:value       ldy           #o_labval
             lda           :len
             and           #%00011111
             tax
             lda           [lableptr],y
             sta           :buffer+1,x
             iny
             iny
             lda           [lableptr],y
             sta           :buffer+3,x
             sep           $20
             lda           :len
             sta           :buffer
             rep           $20
             and           #$80
             beq           :writeit
             ldy           #o_labprev
             lda           [lableptr],y
             and           #$00ff
             ora           :buffer+1,x
             sta           :buffer+1,x

:writeit     lda           :request
             clc
             adc           totbytes
             sta           totbytes
             lda           :request+2
             adc           totbytes+2
             sta           totbytes+2
             jsl           prodos
             dw            $13                                       ;WRITE
             adrl          :writeparm
             bcc           :rts
             sta           :errcode
:rts         inc           :main
             jmp           :loop

:len         ds            2
:offset      ds            2
:errcode     ds            2
:one         dw            $01
:main        ds            2
:buffer      ds            28,0


putop        php
             sep           $30
             lda           #putflag.useflag
             bit           modeflag
             beq           :level
:badput      pea           #badput
             jmp           :err
:level       lda           putlevel
             cmp           #maxput
             bge           :badput
:ok          rep           $30
             lda           macflag
             bit           #%01100000
             bne           :badput

             lda           putlevel
             asl
             asl
             asl
             asl
             tax
             lda           putbuffer,x
             ora           putbuffer+2,x
             jne           :valid
             lda           #$FFFF
             jsr           getpath
             bcc           :ok2
             plp
             sec
             rts
:ok2         lda           #putid
             sta           loadid
             stz           :purgeflag
:load
             jsr           showfile

             psl           #$00
             psl           #pathname
             psl           #$00                                      ;filepos
             psl           #-1                                       ;whole file
             psl           #txttypes
             lda           userid
             ora           #asmmemid
             pha
             psl           #$00
             pea           $8000
             _QALoadfile
             plx
             ply
             bcc           :loaded
             bit           :purgeflag
             jmi           :memerr
             lda           userid
             ora           #putid
             pha
             _DisposeAll
             sec
             ror           :purgeflag
             lda           #$0000
             tax
]lup         sta           putbuffer,x
             inx
             inx
             cpx           #maxput*16
             blt           ]lup
             jmp           :load
:loaded      phy
             phx
             lda           putlevel
             asl
             asl
             asl
             asl
             tax
             pla
             sta           putbuffer,x
             pla
             sta           putbuffer+2,x
:valid       lda           putlevel
             asl
             asl
             asl
             asl
             tax
             phx
             lda           putbuffer,x
             sta           workspace
             pha
             lda           putbuffer+2,x
             sta           workspace+2
             pha
             _HLock
             plx
             lda           fileptr
             sta           putbuffer+4,x
             lda           fileptr+2
             sta           putbuffer+6,x
             lda           flen
             sta           putbuffer+8,x
             lda           flen+2
             sta           putbuffer+10,x
             lda           lastlen
             sta           putbuffer+12,x
             lda           linenum
             sta           tlinenum

* lda #$0001
* sta linenum
             stz           lastlen
             psl           #$00
             pei           workspace+2
             pei           workspace
             _GetHandleSize
             plx
             ply
             cpx           #$00
             bne           :dex
             dey
:dex         dex
             stx           flen
             sty           flen+2

             ldy           #$02
             lda           [workspace]
             sta           fileptr
             lda           [workspace],y
             sta           fileptr+2
             lda           #putflag
             tsb           putuse
             inc           putlevel
             plp
             clc
             rts
:memerr      rep           $30
             sta           prodoserr
             pea           #doserror
:err         rep           $30
             pla
             plp
             cmp           :one
             rts
:one         dw            $01
:purgeflag   ds            2

             mx            %00
libop        lda           passnum
             jeq           useop
             inc           uselevel
             clc
             rts

useop        php
             sep           $30
             lda           #putflag.useflag
             bit           modeflag
             beq           :level
:badput      pea           #badput
             jmp           :err
:level       lda           uselevel
             cmp           #maxput
             bge           :badput
:ok          rep           $30
             lda           macflag
             bit           #%01100000
             bne           :badput
             lda           uselevel
             asl
             asl
             asl
             asl
             tax
             lda           usebuffer,x
             ora           usebuffer+2,x
             bne           :valid
             lda           #$FFFF
             jsr           getpath
             bcc           :ok2
             plp
             sec
             rts
:ok2         lda           #useid
             sta           loadid
             jsr           showfile

             psl           #$00
             psl           #pathname
             psl           #$00                                      ;filepos
             psl           #-1                                       ;whole file
             psl           #txttypes
             lda           userid
             ora           #asmmemid
             pha
             psl           #$00
             pea           $8000
             _QALoadfile
             plx                                                     ;pull off handle
             ply
             jcs           :memerr
:loaded      phy
             phx
             lda           uselevel
             asl
             asl
             asl
             asl
             tax
             pla
             sta           usebuffer,x
             pla
             sta           usebuffer+2,x
:valid       lda           uselevel
             asl
             asl
             asl
             asl
             tax
             phx
             lda           usebuffer,x
             sta           workspace
             pha
             lda           usebuffer+2,x
             sta           workspace+2
             pha
             _HLock
             plx
             lda           fileptr
             sta           usebuffer+4,x
             lda           fileptr+2
             sta           usebuffer+6,x
             lda           flen
             sta           usebuffer+8,x
             lda           flen+2
             sta           usebuffer+10,x
             lda           lastlen
             sta           usebuffer+12,x
             lda           linenum
             sta           tlinenum

* lda #$0001
* sta linenum
             stz           lastlen
             psl           #$00
             pei           workspace+2
             pei           workspace
             _GetHandleSize
             plx
             ply
             cpx           #$00
             bne           :dex
             dey
:dex         dex
             stx           flen
             sty           flen+2
             ldy           #$02
             lda           [workspace]
             sta           fileptr
             lda           [workspace],y
             sta           fileptr+2
             lda           #useflag
             tsb           putuse
             inc           uselevel
             plp
             clc
             rts
:memerr      rep           $30
             sta           prodoserr
             pea           #doserror
:err         rep           $30
             pla
             plp
             cmp           :one
             rts
:one         dw            $01

showfile
             rts
             php
             rep           $30
             psl           #:str
             _QADrawString
             psl           #pathname
             _QADrawString
             lda           #$0d
             jsr           drawchar
             plp
             rts
:str         str           'Reading: '

putuseend    php
             rep           $30
             lda           modeflag
             bit           #putflag
             bne           :put
             bit           #useflag
             bne           :use
             plp
             rts
:put         jsr           putend
             plp
             rts
:use         jsr           useend
             plp
             rts


putend       php
             rep           $30
             lda           putlevel
             bne           :dec
             plp
             rts
:dec         dec
             asl
             asl
             asl
             asl
             tax
             lda           putbuffer,x
             sta           workspace
             lda           putbuffer+2,x
             sta           workspace+2
             phx
             pei           workspace+2
             pei           workspace
             _HUnlock
             plx
             lda           putbuffer+4,x
             sta           fileptr
             lda           putbuffer+6,x
             sta           fileptr+2
             lda           putbuffer+8,x
             sta           flen
             lda           putbuffer+10,x
             sta           flen+2
             lda           putbuffer+12,x
             sta           lastlen
             lda           tlinenum
             sta           linenum
             lda           #putflag
             trb           modeflag
             lda           doneflag
             beq           :plp
             stz           doneflag
:plp         plp
             rts

useend       php
             rep           $30
             lda           uselevel
             bne           :dec
             plp
             rts
:dec         dec
             asl
             asl
             asl
             asl
             tax
             lda           usebuffer+4,x
             sta           fileptr
             lda           usebuffer+6,x
             sta           fileptr+2
             lda           usebuffer+8,x
             sta           flen
             lda           usebuffer+10,x
             sta           flen+2
             lda           usebuffer+12,x
             sta           lastlen
             lda           tlinenum
             sta           linenum
             lda           #useflag
             trb           modeflag
             lda           doneflag
             beq           :plp
             stz           doneflag
:plp         plp
             rts


putbuffer    ds            maxput*16,0
usebuffer    ds            maxput*16,0

closedsk     php
             rep           $30
             lda           dskopen
             jeq           :clc
             sta           dskclose
             sta           dskeofparm
             jsr           writedsk
             jcs           :closeerr
             _getmark      dskeofparm
             lda           dskeof
             sta           :temp
             lda           dskopen
             jsr           writerel
             bcs           :closeerr
             _getmark      dskeofparm
             _seteof       dskeofparm
             _close        dskclose
             stz           dskopen
             bcc           :info
             stz           dskclose
             pha
             _close        dskclose
             pla
             jmp           :sec
:info        lda           errorct
             beq           :info1
* _delete dskdelete
* jmp :clc
:info1       _getfileinfo  dskinfo
             bcs           :sec
             jsr           settypes1
             lda           #relflag
             bit           modeflag
             beq           :set
             lda           :temp
             sta           dskaux
             stz           dskaux+2
:set         _setfileinfo  dskinfo
             bcs           :sec
             jmp           :clc
:closeerr    pha
             stz           dskclose
             _close        dskclose
             stz           dskopen
             pla
:sec         stz           dskpath
             plp
             sec
             rts
:clc         stz           dskpath
             plp
             clc
             rts
:temp        ds            2
:str         str           'Closing file.'

writedsk     phx
             phy
             php
             rep           $30
             lda           dskopen
             beq           :nowrt
             sta           dskwrite
             lda           objct
             beq           :nowrt
             sta           dskreq
             stz           dskreq+2
             lda           objzpptr
             sta           dskbuff
             lda           objzpptr+2
             sta           dskbuff+2
             _write        dskwrite
             jcs           :dskerr
:nowrt       stz           objfull
             stz           objct
             pea           #$0000
             jmp           :xit
:dskerr      pha
             stz           objfull
             stz           objct
             jmp           :xit
:xit         pla
             plp
             ply
             plx
             cmp           :one
             rts
:one         dw            $01

