dskerror    php
            rep   $30
            sta   prodoserr
            lda   #doserror
            jsr   linkerror
            plp
            rts

linkerror   php
            rep   $30
            sta   :errcode
            pea   0
            _QAGetWindow
            pea   $FFFF
            _QASetWindow

            _QAIncTotalErrs
            cmp   #constraint
            jeq   :xit
            cmp   #notresolved
            jeq   :xit
:ldx        ldx   #$00
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
:draw       lda   #$0d
            jsr   drawchar
            _QADrawString
            psl   #textstr
            _QADrawString
:line       pea   0
            lda   linenum
            pha
            pea   0
            pea   0
            _QADrawDec

            lda   :errcode
            cmp   #doserror
            jne   :period
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
            _QADrawString
            jmp   :period
:gsnfound   psl   #dosstr
            lda   #$20
            jsr   drawchar
            _QADrawErrString
            lda   prodoserr
            jsr   prbytel
:period     lda   #'.'
            jsr   drawchar
* psl #codestr
* _QADrawErrString
* lda :errcode
* jsr prbyte
            lda   #$0d
            jsr   drawchar

:xit        rep   $30
            _QASetWindow
            plp
            rts
:errcode    ds    2

gstbl       dw    $07,gstr1
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
            dw    $4e,gstr13
            dw    $201,gstr14
            dw    mismatch,gstr15  ;error $5C
            dw    $0000,$0000


errtbl      dw    syntax,str1
            dw    badasmcmd,str2
            dw    badcmd,str3
            dw    badlable,str4
            dw    outofmem,str5
            dw    undeflable,str6
            dw    badoperand,str7
            dw    badrelative,str8
            dw    symfull,str9
            dw    baddictionary,str10
            dw    badexternal,str11
            dw    extnotzp,str12
            dw    maxsegments,str13
            dw    relfull,str14
            dw    dupentry,str15
            dw    maxfileserr,str16
            dw    onesave,str17
            dw    badvalue,str18
            dw    doserror,str19
            dw    badalignop,str20
            dw    jmptblfull,str21
            dw    baddsop,str22
            dw    illegalcmd,str23
            dw    filetoolarge,str24
            dw    nesterror,str25
            dw    forwardref,str26

            dw    $0000,$0000

str1        str   'Syntax'
str2        str   'Bad ASM command'
str3        str   'Unrecognized command'
str4        str   'Bad label'
str5        str   'Out of memory'
str6        str   'Undefined label'
str7        str   'Bad operand'
str8        str   'Bad relative address'
str9        str   'Symbol table full'
str10       str   'Bad dictionary entry'
str11       str   'Bad external lable'
str12       str   'External not direct page'
str13       str   'Too many segments'
str14       str   'Relocation dictionary full'
str15       str   'Duplicate ENTry'
str16       str   'Too many files'
str17       str   'Only one SAV allowed'
str18       str   'Bad value'
str19       str   'GS/OS error'
str20       str   'Bad ALIGN'
str21       str   'Jump table full'
str22       str   'Unable to reserve DS space'
str23       str   'Illegal command'
str24       str   'File too large'
str25       str   'Conditional nesting level error'
str26       str   'Illegal forward reference'


gstr1       str   '<GS/OS is busy>'
gstr2       str   '<I/O error>'
gstr3       str   '<No device connected>'
gstr4       str   '<Write protected>'
gstr5       str   '<Disk switched>'
gstr6       str   '<No disk in drive>'
gstr7       str   '<Invalid pathname>'
gstr8       str   '<Directory not found>'
gstr9       str   '<Volume not found>'
gstr10      str   '<File not found>'
gstr11      str   '<Duplicate filename>'
gstr12      str   '<Disk full>'
gstr13      str   '<File locked>'
gstr14      str   '<Memory manager: Unable to allocate memory>'
gstr15      str   '<File type mismatch>'
unknownstr  str   '<Unknown error>'
codestr     str   ' Code=$'
textstr     str   ' in line: '
dosstr      str   'GS/OS Code #'

