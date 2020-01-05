             lst   off
             cas   in
             tr    on
             exp   only

             rel
             xc
             xc
             mx    %00                ; make sure we're in 16-bit mode!


doexpress    =     $01

             use   ../macros/builtin.macs
             use   ../macros/qatools.macs
             use   ../data/qa.equates

             use   link.macs


             brl   start

             put   link.vars

userid       ds    2                  ;my userid
linkdp       ds    2
filename     ds    130,0
quickname    ds    130,0
txttypes     hex   0204B0
lnktype      hex   01f8

start        php
             phb
             phd
             phk
             plb
             rep   $30
             sta   userid
             tdc
             sta   linkdp
             pea   0
             _QAStatus
             pla
             bne   :ok
             pld
             plb
             plp
             rep   $30
             jsl   prodos
             dw    $29
             adrl  :quit
:quit        adrl  $00
             dw    $00

:ok          rep   $30
             stz   prodoserr
             stz   quicklink

             pea   0
             psl   #$00
             lda   userid
             pha
             _QAGetMessagebyID
             pla
             sta   subtype
             pla
             sta   subtype+2
             pla
             sta   message
             stz   filename
             lda   message
             beq   :xit1
             cmp   #maxlmessage
             blt   :call
             lda   #$FFFF
             jmp   :xit
:call        dec
             asl
             tax
             jsr   (:tbl,x)
             bra   :xit
:bad         lda   #$FFFF
             bra   :xit
:xit1        lda   #$00
:xit         rep   $30
             pha
             lda   userid
             ora   #linkmemid
             pha
             _disposeall
             pla
             pld
             plb
             plp
             cmpl  :one
             rtl
:one         dw    $01

:tbl         dw    cmdline
             dw    txtfile
             dw    fromhandle
             dw    doquicklink
             dw    project1
             dw    project2

project1     php
             rep   $30
             lda   #$46
             plp
             cmp   :one
             rts
:one         dw    1
project2     php
             rep   $30
             lda   #$46
             plp
             cmp   :one
             rts
:one         dw    1


fromhandle   php
             rep   $30
             psl   #linkstr
             _QADrawString
             lda   #'.'
             jsr   drawchar
             lda   #$0d
             jsr   drawchar
             ldx   subtype
             ldy   subtype+2
             jsl   link
             bcc   :clc
:sec         rep   $30
             plp
             sec
             rts
:clc         rep   $30
             lda   #$00
             plp
             clc
             rts

txtfile      php
             rep   $30
             psl   #asmpath
             _QAGetPath
             lda   asmpath
             and   #$ff
             jeq   :notfound
             tay
             sep   $20
]lup         lda   asmpath,y
             tyx
             and   #$7f
             sta   filename,x
             dey
             bpl   ]lup
             lda   filename
             cmp   #62
             bge   :nosufx
             tax
             lda   filename,x
             cmp   #'/'
             beq   :nosufx
             cmp   #':'
             beq   :nosufx

             inc   filename
             inc   filename
             inx
             lda   #'.'
             sta   filename,x
             inx
             lda   #'S'
             sta   filename,x

:nosufx      rep   $30
             psl   #$00
             psl   #filename
             psl   #$00               ;filepos
             psl   #-1                ;whole file
             psl   #txttypes
             lda   userid
             ora   #linkmemid
             pha
             psl   #$00
             pea   $8000
             _QALoadfile
             plx
             ply
             jcs   :sec
             phx
             phy
             psl   #linkstr
             _QADrawString
             lda   #' '
             jsr   drawchar
             psl   #filename
             _QADrawString
             lda   #$0d
             jsr   drawchar
             ply
             plx
             jsl   link
             bcc   :clc
             jmp   :sec
:notfound    rep   $30
             lda   #$46
:sec         rep   $30
             plp
             sec
             rts
:clc         rep   $30
             lda   #$0000
             plp
             clc
             rts

doquicklink  php
             rep   $30
             lda   subtype
             ora   subtype+2
             bne   :file
             psl   #$00
             psl   #qtextend-qtext
             lda   userid
             ora   #linkmemid
             pha
             pea   $8000
             psl   #$00
             _Newhandle
             plx
             ply
             jcs   :sec
             phy
             phx

             psl   #qtext
             phy
             phx
             psl   #qtextend-qtext
             tll   $2802              ;_PtrToHand
             psl   #quickname
             _QAGetPath
             lda   #^quickname
             sta   subtype+2
             lda   #quickname
             sta   subtype
             jmp   :go1

:file        sep   $30
             ldx   :fname
]lup         lda   :fname,x
             sta   filename,x
             dex
             bpl   ]lup
             rep   $30

             psl   #$00
             psl   #filename
             psl   #$00               ;filepos
             psl   #-1                ;whole file
             psl   #txttypes
             lda   userid
             ora   #linkmemid
             pha
             psl   #$00
             pea   $8000
             _QALoadfile
             plx
             ply
             bcc   :go
             cmp   #$46
             beq   :next
             jmp   :sec

:next        sep   $30
             ldx   :fname1
]lup         lda   :fname1,x
             sta   filename,x
             dex
             bpl   ]lup
             rep   $30
             psl   #$00
             psl   #filename
             psl   #$00               ;filepos
             psl   #-1                ;whole file
             psl   #txttypes
             lda   userid
             ora   #linkmemid
             pha
             psl   #$00
             pea   $8000
             _QALoadfile
             plx
             ply
             jcs   :sec

:go          phx
             phy
:go1         psl   #:quickstr
             _QADrawString
             lda   #$FFFF
             sta   quicklink
             psl   #:zero
             _QASetObjPath
             ply
             plx
             jsl   link
             bcc   :clc
             jmp   :sec
:notfound    rep   $30
             lda   #$46
:sec         rep   $30
             plp
             sec
             rts
:clc         rep   $30
             lda   #$0000
             plp
             clc
             rts
:fname       str   'QuickLINK.S'
:fname1      str   '1:QASYSTEM:QuickLINK.S'
:quickstr    str   0d,'Linking.',0d
:zero        hex   0000

qtext        asc   ' OVR ALL',0D
             asc   ' ASM ',5D,'1',0D
             asc   ' LNK ',5D,'2',0D
             asc   ' SAV ',5D,'3',0D
qtextend

cmdline      php
             rep   $30
             psl   #asmpath
             pea   80
             _QAGetCmdLine
             ldy   #$01
             sep   $30
             lda   asmpath
             beq   :notfound
]lup         lda   asmpath,y
             and   #$7f
             cmp   #' '
             blt   :notfound
             bne   :p1
             iny
             jmp   ]lup
:p1          iny
]lup         lda   asmpath,y
             and   #$7f
             cmp   #' '
             blt   :notfound
             beq   :p2
             iny
             jmp   ]lup
:p2          iny
]lup         lda   asmpath,y
             and   #$7f
             cmp   #' '
             blt   :notfound
             bne   :ok
             iny
             jmp   ]lup
:ok          ldx   #$00
             sta   filename+1,x
]get         inx
             iny
             lda   asmpath,y
             and   #$7f
             cmp   #' '+1
             blt   :set
             sta   filename+1,x
             jmp   ]get
:notfound    jmp   :nf1
:set         txa
             sta   filename
             rep   $30
             lda   filename
             and   #$ff
             cmp   #62
             bge   :nosuff
             tax
             lda   filename,x
             and   #$7f
             cmp   #'/'
             beq   :nosuff
             cmp   #':'
             beq   :nosuff
             inx
             lda   #'.S'
             sta   filename,x
             inx
             txa
             sep   $20
             sta   filename

:nosuff      rep   $30
             psl   #$00
             psl   #filename
             psl   #$00               ;filepos
             psl   #-1                ;whole file
             psl   #txttypes
             lda   userid
             ora   #linkmemid
             pha
             psl   #$00
             pea   $8000
             _QALoadfile
             plx
             ply
             jcs   :xit
             phy
             phx
             psl   #linkstr
             _QADrawString
             lda   #' '
             jsr   drawchar
             psl   #filename
             _QADrawString
             lda   #$0d
             jsr   drawchar
             plx
             ply
             jsl   link
             bcs   :xit
             jmp   :clc
:nf1         rep   $30
             lda   #$46
             jmp   :xit
:clc         rep   $30
             lda   #$0000
:xit         rep   $30
             plp
             cmp   :one
             rts
:one         dw    $01

linkstr      str   0d,'Linking'


prbytel
             php
             rep   $30
             pha
             phx
             phy
             pha
             _QAPrbytel
             ply
             plx
             pla
             plp
             rts

prbyte
             php
             rep   $30
             pha
             phx
             phy
             pha
             _QAPrbyte
             ply
             plx
             pla
             plp
             rts


drawchar     phx
             phy
             pha
             php
             rep   $30
             and   #$7f
             pha
             _QADrawChar
:plp         plp
             pla
             ply
             plx
             rts


             put   linker.1
             put   linker.2
             put   link.eval
             do    doexpress
             put   link.express
             fin
             put   link.errors

tempbuff     ds    130

             lst
             chk
             lst   off

             typ   exe
             sav   qlinkgs.l

