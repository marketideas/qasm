dskerror    php
            rep   $30
            sta   prodoserr
            lda   #doserror
            jsr   asmerror
            plp
            rts

asmerror    php
            rep   $30
            sta   :errcode
            _QAIncTotalErrs
            pea   0
            _QAGetWindow
            pea   $ffff
            _QASetWindow
            ldx   #$00
]lup        lda   errtbl,x
            beq   :unknown
            cmp   :errcode
            beq   :found
            inx
            inx
            inx
            inx
            jmp   ]lup
:unknown    psl   #unknownstr
            jmp   :draw
:found      inx
            inx
            phk
            phk
            pla
            and   #$00ff
            pha
            lda   errtbl,x
            pha
:draw       _QADrawErrstring

            jsr   :gsos

            psl   #textstr
            _QADrawErrString
            lda   modeflag
            bit   #putflag.useflag
            beq   :line
            lda   tlinenum
            ldx   #$00
            jsr   printdec
            lda   #' '
            jsr   drawchar
            lda   #'>'
            jsr   drawchar
:line       lda   linenum
            ldx   #$00
            jsr   printdec
:period     lda   #'.'
            jsr   drawchar
            lda   #$0d
            jsr   drawchar
            _QASetWindow
            plp
            rts
:errcode    ds    2

:gsos       php
            rep   $30
            lda   :errcode
            cmp   #doserror
            jne   :xit
            ldx   #$00
]lup        lda   gstbl,x
            beq   :gsnfound
            cmp   prodoserr
            beq   :gfound
            inx
            inx
            inx
            inx
            jmp   ]lup
:gfound     inx
            inx
            lda   gstbl,x
            tax
            phk
            phk
            pla
            and   #$00ff
            pha
            phx
            lda   #$20
            jsr   drawchar
            _QADrawErrString
            jmp   :xit
:gsnfound   psl   #dosstr
            lda   #$20
            jsr   drawchar
            _QADrawErrString
            lda   prodoserr
            jsr   prbytel
:xit        plp
            rts

gstbl       dw    $07,gstr1
            dw    $10,gstr16
            dw    $11,gstr16
            dw    $27,gstr2
            dw    $28,gstr3
            dw    $2b,gstr4
            dw    $2e,gstr5
            dw    $2f,gstr6
            dw    $40,gstr7
            dw    $44,gstr8
            dw    $45,gstr9
            dw    $46,gstr10
            dw    $47,gstr11
            dw    $48,gstr12
            dw    $49,gstr12
            dw    $4e,gstr13
            dw    $50,gstr13
            dw    $51,gstr17
            dw    $52,gstr19
            dw    $57,gstr18
            dw    $201,gstr14

            dw    filemismatch,gstr15  ;error $5C
            dw    badsav,str25
            dw    $0000,$0000

errtbl      dw    badlable,str2
            dw    undeflable,str3
            dw    duplable,str4
            dw    misalignment,str5
            dw    badoperand,str6
            dw    notmacro,str7
            dw    badopchar,str8
            dw    badconditional,str9
            dw    badaddress,str10
            dw    badbranch,str11
            dw    forwardref,str12
            dw    twoexternals,str13
            dw    badrelative,str14
            dw    saneerror,str29
            dw    evaltoocomplex,str30

            dw    objectfull,str15
            dw    symfull,str16
            dw    memfull,str17
            dw    badput,str18
            dw    doserror,str19
            dw    relfull,str20
            dw    usererror,str21
            dw    macrofull,str22
            dw    badmacro,str23
            dw    nesterror,str24
            dw    badsav,str25
            dw    badopcode,str26
            dw    $201,str27
            dw    badinput,str28
            dw    relfilefull,str31

            dw    $0000,$0000


str2        str   'Bad label'
str3        str   'Undefined label'
str4        str   'Duplicate label'
str5        str   'Misalignment'
str6        str   'Bad operand'
str7        str   'Not a macro'
str8        str   'Illegal char in operand'
str9        str   'Bad conditional'
str10       str   'Bad address mode'
str11       str   'Bad branch'
str12       str   'Illegal forward reference'
str13       str   'Two externals'
str14       str   'Illegal relative address'
str15       str   'Object space overflow'
str16       str   'Symbol table full'
str17       str   'Memory full'
str18       str   'Bad PUT/USE'
str19       str   'GS/OS error:'
str20       str   'Relocation dictionary full'
str21       str   'Break'
str22       str   'Macro table full'
str23       str   'Bad macro'
str24       str   'Nesting error'
str25       str   'Bad SAV/DSK'
str26       str   'Bad opcode'
str27       str   'Out of Memory'
str28       str   'Bad input'
str29       str   'SANE error'
str30       str   'Expression too complex'
str31       str   'REL file too large'

gstr1       str   'GS/OS is busy'
gstr2       str   'I/O error'
gstr3       str   'No device connected'
gstr4       str   'Write protected'
gstr5       str   'Disk switched'
gstr6       str   'No disk in drive'
gstr7       str   'Invalid pathname'
gstr8       str   'Directory not found'
gstr9       str   'Volume not found'
gstr10      str   'File not found'
gstr11      str   'Duplicate filename'
gstr12      str   'Disk full'
gstr13      str   'File locked'
gstr14      str   'Memory manager: Unable to allocate memory'
gstr15      str   'File type mismatch'
gstr16      str   'Device not found'
gstr17      str   'Volume damaged'
gstr18      str   'Duplicate volume online'
gstr19      str   'Not ProDOS (GS/OS) volume'
unknownstr  str   'Unknown error'
codestr     str   ' Code=$'
textstr     str   ' in line: '
dosstr      str   'GS/OS Error: '

