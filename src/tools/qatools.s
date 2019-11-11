                 lst            off
                 tr             on
                 exp            off
                 cas            in
*======================================================
* The toolbox used by QuickASM to make things fast
* and cool for itself and user written tools!

* Written by Shawn Quick and Lane Roath
* Copyright (c) 1990 QuickSoft & Ideas From the Deep
*------------------------------------------------------
* 15-Mar-90 0.30 :GetWord, InitWildCard, ReadDir
* 05-Feb-90 0.20 :DateTime,CR,Space,Version, optimization
* 01-Feb-90 0.10 :first usable version
*======================================================

                 xc
                 xc
                 mx             %00
                 rel

Class1           =              $0000                       ;class 0

                 lst            off
                 use            2/data/qa.equates
                 use            tool.macs
                 lst            rtn

mainbank         =              $000000                     ;some local equates
auxbank          =              $010000

hexlen           =              8
declen           =              10
maxlevels        =              30                          ;allow 30 levels of directory nesting

*======================================================
* The routine table required of any toolbox

tooltbl          adrl           {:tblend-tooltbl}/4
                 adrl           qabootinit-1                ;   $01 _QABootInit()
                 adrl           qastartup-1                 ;   $02 _QAStartup(userid,modeflags/4)
                 adrl           qashutdown-1                ;   $03 _QAShutdown()
                 adrl           qaversion-1                 ;   $04 _QAVersion():versionnum
                 adrl           qareset-1                   ;   $05 _QAReset()
                 adrl           qastatus-1                  ;   $06 _QAStatus():statflag
                 adrl           reserved-1                  ;   $07
                 adrl           reserved-1                  ;   $08
                 adrl           qadrawchar-1                ;   $09 _QADrawChar(char)
                 adrl           qadrawstring-1              ;   $0A _QADrawString(@strptr)
                 adrl           qaprbyte-1                  ;   $0B _QAPrByte(hexbyte)
                 adrl           qaprbytel-1                 ;   $0C _QAPrBytel(hexval/4)
                 adrl           qadrawdec-1                 ;   $0D _QADrawDec(longint/4,flags,fieldsize)
                 adrl           qakeyavail-1                ;   $0E _QAKeyAvail():availflag
                 adrl           qagetchar-1                 ;   $0F _QAGetChar():char (char in low/mod in high)
                 adrl           qagetline-1                 ;   $10 _QAGetLine(@linestr,@promptptr,maxlen)
                 adrl           qasetparmhdl-1              ;   $11 _QASetParmHdl(parmhandle)
                 adrl           qagetparmhdl-1              ;   $12 _QAGetParmHdl:parmhandle
                 adrl           qasetcmdhdl-1               ;   $13 _QASetCmdHdl(commandhandle,numcmds)
                 adrl           qagetcmdhdl-1               ;   $14 _QAGetCmdHdl:commandhandle,numcmds
                 adrl           qareadtotalerrs-1           ;$15 _QAReadTotalErrs():totalerrs
                 adrl           qagetmodeflags-1            ; $16 _QAGetModeFlags():modeflags/4
                 adrl           qasetmodeflags-1            ; $17 _QASetModeFlags(modeflags/4)
                 adrl           qaloadfile-1                ;   $18 _QALoadfile(@filename,filepos/4,length/4,@typelist,userid,address/4,memattrib):filehandle/4
                 adrl           qasavefile-1                ;   $19 _QASavefile(filehandle/4,@filename,filetype,auxtype/4)
                 adrl           qasetcmdline-1              ;   $1A _QASetCmdLine(@strptr)
                 adrl           qagetcmdline-1              ;   $1B _QAGetCmdLine(@strptr,maxlen)
                 adrl           qaparseline-1               ;   $1C _QAParseCmdLine(@strptr):cmdid,cmdtype
                 adrl           qagetquitflag-1             ;  $1D _QAGetQuitFlag():quitflag
                 adrl           qasetquitflag-1             ;  $1E _QASetQuitFlag(quitflag):
                 adrl           qasetcmdtbl-1               ;    $1F _QASetCmdTbl(@cmdtbl)
                 adrl           qagetcmdtbl-1               ;    $20 _QAGetCmdTbl():@cmdtbl
                 adrl           qaexeccmd-1                 ;      $21 _QAExecCommand(cmdtype,cmdid)
                 adrl           qagetmessbyid-1             ;  $22 _QAGetMessagebyID(userid):message,subtype/4
                 adrl           qarun-1                     ;       $23 _QARun()
                 adrl           qadispose-1                 ;      $24 _QADispose()
                 adrl           qashutdownid-1              ;   $25 _QAShutdownID(userid)
                 adrl           qacompile-1                 ;      $26 _QACompile(message,subtype/4)
                 adrl           qalink-1                    ;       $27 _QALink(message,subtype/4)
                 adrl           qacompileactive-1           ;$28 _QACompilerActive():activeflag
                 adrl           qalinkactive-1              ;   $29 _QALinkerActvie():activeflag
                 adrl           qagetcompileid-1            ; $2A _QAGetCompileID():compileid
                 adrl           qasetcompileid-1            ; $2B _QASetCompileID(compileid)
                 adrl           qagetlinkid-1               ;    $2C _QAGetLinkID():linkid
                 adrl           qasetlinkid-1               ;    $2D _QASetLinkID(linkid)
                 adrl           qagetvector-1               ;    $2E _QAGetVector(vect#):@address
                 adrl           qasetvector-1               ;    $2F _QASetVector(vect#,@address)
                 adrl           qaresetvectors-1            ; $30 _QAResetVectors()
                 adrl           qaevent-1                   ; $31 _QAEvent(@eventrecord,taskflag)
                 adrl           qagetcmdrecsize-1           ;$32 _QAGetCmdRecSize():recordsize
                 adrl           qatabtocol-1                ;     $33 _QATabtoCol(columnnum)
                 adrl           qaerrormsg-1                ;     $34 _QAErrorMsg(ErrorCode)
                 adrl           qabargraph-1                ;     $35 _QABarGraph(percent,@Message)
                 adrl           qaconvertpath-1             ;  $36 _QAConvertPath(@oldpath,@newpath,appendchar)
                 adrl           qatyp2txt-1                 ;      $37 _QAConvertTyp2Txt(filetype,@typestr)
                 adrl           qatxt2typ-1                 ;      $38 _QAConvertTxt2Typ(@typestr):type
                 adrl           qareaddir-1                 ;      $39 _QAReadDir(@pathname,@doroutine,flags)
                 adrl           qainitwildcard-1            ; $3A _QAInitWildcard(@wcstr,ft,aux/4,ftmask,auxmask/4)
                 adrl           notdefined-1                ;     $3B _QAUndefined()
                 adrl           qainittotalerrs-1           ;$3C _QAInitTotalErrs()
                 adrl           qainctotalerrs-1            ; $3D _QAIncTotalErrs()
                 adrl           qagettotalerrs-1            ; $3E _QAGetTotalErrs():totalerrs
                 adrl           qagetcancelflag-1           ;$3F _QAGetCancelFlag():cancelflag
                 adrl           qasetcancelflag-1           ;$40 _QASetCancelFlag(cancelflag)
                 adrl           qastarttiming-1             ;  $41 _QAStartTiming()
                 adrl           qaendtiming-1               ;    $42 _QAEndTiming:hours,minutes,seconds
                 adrl           qagetsymtbl-1               ;    $43 _QAGetSymTable():@table,symhandle/4,numlabels,nextptr/4
                 adrl           qasetsymtbl-1               ;    $44 _QASetSymTable(@table,symhandle/4,numlabels,nextptr/4)
                 adrl           qasetname-1                 ;      $45 _QASetPath(@pathname)
                 adrl           qagetname-1                 ;      $46 _QAGetPath(@pathname)
                 adrl           qagetobjtype-1              ;   $47 _QAGetObjType():type
                 adrl           qasetobjtype-1              ;   $48 _QASetObjType(type)
                 adrl           qagetobjname-1              ;   $49 _QAGetObjPath(@pathname)
                 adrl           qasetobjname-1              ;   $4A _QASetObjPath(@pathname)
                 adrl           notdefined-1                ;     $4B _QACallUSR(opcode,@operand):handled
                 adrl           notdefined-1                ;     $4C _QACallUser(rngstart,rngend,texthandle/4,textlen/4)
                 adrl           notdefined-1                ;     $4D _QAGoEVAL(@operand,offset):value/4
                 adrl           notdefined-1                ;     $4E _QAGoPutByte(byte)
                 adrl           notdefined-1                ;     $4F _QAGoPutOpcode(opcodebyte)
                 adrl           notdefined-1                ;     $50 _QAGoRelcorrect()
                 adrl           qadrawerrchar-1             ;$51 _QADrawErrChar(char)
                 adrl           qadrawerrstring-1           ;$52 _QADrawErrString(@strptr)
                 adrl           qagetwindow-1               ;    $53 _QAGetWindow():windowtype
                 adrl           qasetwindow-1               ;    $54 _QASetWindow(windowtype)
                 adrl           qagetshellid-1              ;   $55 _QAGetShellID():userid
                 adrl           qasetshellid-1              ;   $56 _QASetShellID(userid)
                 adrl           qagotoxy-1                  ;       $57 _QAGotoXY(x,y)
                 adrl           qagetxy-1                   ;       $58 _QAGetXY():X,Y
                 adrl           qaprnib-1                   ;       $59 _QAPrNibble(nibval)
                 adrl           qadrawhex-1                 ;      $5A _QADrawHex(hexval/4,flags,fieldsize)
                 adrl           qadrawblock-1               ;    $5B _QADrawBlock(@CBlock)
                 adrl           qadrawerrblock-1            ; $5C _QADrawErrBlock(@CBlock)
                 adrl           qadrawmultchar-1            ; $5D _QADrawCharX(char,count)
                 adrl           qadrawmultechar-1           ;$5E _QADrawECharX(char,count)
                 adrl           qagetlaunch-1               ;    $5F _QAGetLaunch():@path,flags
                 adrl           qasetlaunch-1               ;    $60 _QASetLaunch(@path,flags)
                 adrl           QAGetWord-1                 ;      $61 _QAGetWord(@Text,Offset,MaxLen):BegOffset,EndOffset
                 adrl           QADateTime-1                ;     $62 _QAPrintDate(Flags,@DateTime)
                 adrl           QADrawCR-1                  ;      $63 _QADrawCR()
                 adrl           QADrawSpace-1               ;    $64 _QADrawSpace()
                 adrl           QAPrintVersion-1            ; $65 _QAPrintVersion(Version/4)
                 adrl           qadrawbox-1                 ;      $66 _QADrawBox(x,y,width,height):buffhdl
                 adrl           qaerasebox-1                ;     $67 _QAEraseBox(buffhdl)
                 adrl           qaconvertstr-1              ;   $68 _QAConvertString(@string/class.1,@buffer/class.1,cmdcode):rtncode
                 adrl           qadrawstrl-1                ;    $69 _QADrawStringL(@string/class.1)
                 adrl           qadrawerrstrl-1             ; $6A _QADrawErrStringL(@strptr/class.1)
                 adrl           qagetkeyadrs-1              ;  $6B _QAGetKeyAddress():keyaddress/4
                 adrl           QANextLine-1                ;     $6C _QANextLine(@Text,Offset,MaxLen):NewLineOffset
                 adrl           QAClearKey-1                ;     $6D _QAClearKey()
                 adrl           QAParseWord-1               ;    $6E _QAParseWord(???):???
:tblend

*======================================================
* Vector Tables: patched by graphics shell, etc...

vectortbl
                 jml            pchar                       ; #1  _QADrawChar
                 jml            pstr                        ; #2  _QADrawString
                 jml            pechar                      ; #3  _QADrawErrChar
                 jml            pestr                       ; #4  _QADrawErrString
                 jml            pblk                        ; #5  _QADrawCStr
                 jml            peblk                       ; #6  _QADrawECStr
                 jml            putop                       ; #7  _QAPutOpcode
                 jml            putbyte                     ; #8  _QAPutByte
                 jml            eval                        ; #9  _QAEval
                 jml            relcorrect                  ; #10 _QARelCorrect
                 jml            mykeyavail                  ; #11 _QAKeyAvail
                 jml            mygetchar                   ; #12 _QAGetChar
                 jml            mygetline                   ; #13 _QAGetLine
                 jml            mytabtocol
                 jml            rtl
                 jml            rtl
                 jml            rtl
                 jml            rtl
                 jml            rtl
                 jml            pstrl
                 jml            pestrl
                 adrl           0                           ;NOT a Vector but a HANDLE

vectortbl1                                                  ;--- copy of ORIGINAL for restoration ---
                 jml            pchar
                 jml            pstr
                 jml            pechar
                 jml            pestr
                 jml            pblk
                 jml            peblk
                 jml            putop
                 jml            putbyte
                 jml            eval
                 jml            relcorrect
                 jml            mykeyavail
                 jml            mygetchar
                 jml            mygetline
                 jml            mytabtocol
                 jml            rtl
                 jml            rtl
                 jml            rtl
                 jml            rtl
                 jml            rtl
                 jml            pstrl
                 jml            pestrl
                 adrl           0                           ;NOT a Vector but a HANDLE
vectend

*======================================================
* Common exit routines to set carry & processor status

noerror          rep            $30
                 lda            #0
errxit           rep            $30
                 cmp            #1
                 rtl

                 mx             %00
qabootinit       phb
                 phd
                 phk
                 plb
                 stz            started
                 pea            #userorsys
                 pea            #toolnum
                 pea            0
                 pea            0
                 tll            $0d01                       ;_setwap
                 psl            #0
                 psl            #qabootinit
                 tll            $1A02                       ;_Findhandle
                 tsc
                 inc
                 tcd
                 lda            0
                 ora            2
                 beq            :err
                 ldy            #$06
                 lda            [0],y
                 sta            userid
                 pla
                 pla
                 jsr            initvars
                 pld
                 plb
                 brl            noerror
:err             plx
                 plx
                 pld
                 plb
                 lda            #$FF
                 brl            errxit

qastartup
                 dum            0
]rtl             ds             6                           ;these are passed on stack
]modeflag        ds             4
]userid          ds             2
]newstack        =              *-6                         ;must be at end of passed params
                 dend

                 mx             %00
                 tsc
                 sec
                 sbc            #]rtl
                 tcs
                 phd
                 inc
                 tcd
                 phb
                 phk
                 plb

                 jsr            initvars                    ;insure vars inited
                 jsr            InitASK

                 lda            ]modeflag
                 sta            modeflags
                 lda            ]modeflag+2
                 sta            modeflags+2                 ;set parms passed
                 lda            ]userid
                 sta            initid
                 jsr            ttinitscreen
                 dec            started                     ;show we are started

:noerr1          lda            #0
:xit             rep            $30
                 tax
                 lda            ]rtl+4
                 sta            ]newstack+4
                 lda            ]rtl+2
                 sta            ]newstack+2
                 lda            ]rtl
                 sta            ]newstack
                 plb
                 pld
                 tsc
                 clc
                 adc            #]newstack
                 tcs
                 txa
                 cmpl           :one
                 rtl
:one             dw             1
                 mx             %00

qashutdown       phb
                 phk
                 plb
                 stz            started
                 ~SetVector     #$F;EMKeyVect               ;restore event manager vectors
                 jsr            ttshutdown
                 jsr            initvars
                 plb
                 brl            noerror

qastatus         ldal           started
                 sta            7,s
                 brl            noerror

qareset          brl            noerror

qaversion        lda            #versionnum
                 sta            7,s
                 brl            noerror

reserved
notdefined       lda            #qanotstarted               ;not defined error
                 brl            errxit

initvars
                 lda            cmdhandle
                 ora            cmdhandle+2
                 beq            :1
                 psl            cmdhandle
                 _disposehandle                             ;do this before total clear!
:1
                 ldx            #DS_Size-2
]loop            stz            DS_Start,x
                 dex                                        ;clear all variables
                 dex
                 bpl            ]loop

                 jsl            QAResetVectors              ;insure originals are good

*------------------------------------------------------
* Init the text tool variables

ttinitvars
                 php
                 rep            $30
                 stz            outflag
                 stz            cursx
                 stz            cursy
                 stz            fullwindow
                 stz            wintop
                 stz            winleft
                 lda            #23
                 sta            winbot
                 lda            #80
                 sta            winwidth
                 lda            #$80                        ;normal, no mousetext
                 sta            charflag
                 jsr            setcurs
                 plp
                 rts

*======================================================
* Actual Tool Functions Start Here

                 mx             %00
qasetparmhdl
                 lda            7,s
                 stal           parmhandle
                 lda            9,s
                 stal           parmhandle+2
                 lda            5,s
                 sta            5+4,s
                 lda            3,s
                 sta            3+4,s
                 lda            1,s
                 sta            1+4,s
                 pla
                 pla
                 brl            noerror

qagetparmhdl
                 ldal           parmhandle
                 sta            7,s
                 ldal           parmhandle+2
                 sta            9,s
                 brl            noerror

                 mx             %00
qasetquitflag
                 lda            7,s
                 stal           quitflag
                 lda            5,s
                 sta            5+2,s
                 lda            3,s
                 sta            3+2,s
                 lda            1,s
                 sta            1+2,s
                 pla
                 brl            noerror
qagetquitflag
                 ldal           quitflag
                 sta            7,s
                 brl            noerror

                 mx             %00
qasetcancelflag
                 lda            7,s
                 stal           cancelflag
                 lda            5,s
                 sta            5+2,s
                 lda            3,s
                 sta            3+2,s
                 lda            1,s
                 sta            1+2,s
                 pla
                 brl            noerror
qagetcancelflag
                 ldal           cancelflag
                 sta            7,s
                 brl            noerror


                 mx             %00
qasetcompileid
                 lda            7,s
                 stal           compiler
                 lda            5,s
                 sta            5+2,s
                 lda            3,s
                 sta            3+2,s
                 lda            1,s
                 sta            1+2,s
                 pla
                 brl            noerror
qagetcompileid
                 ldal           compiler
                 sta            7,s
                 brl            noerror

                 mx             %00
qasetlinkid
                 lda            7,s
                 stal           linker
                 lda            5,s
                 sta            5+2,s
                 lda            3,s
                 sta            3+2,s
                 lda            1,s
                 sta            1+2,s
                 pla
                 brl            noerror
qagetlinkid
                 ldal           linker
                 sta            7,s
                 brl            noerror

qasetcmdtbl
                 lda            7,s
                 stal           cmdtbl
                 lda            9,s
                 stal           cmdtbl+2
                 lda            5,s
                 sta            5+4,s
                 lda            3,s
                 sta            3+4,s
                 lda            1,s
                 sta            1+4,s
                 pla
                 pla
                 brl            noerror

qagetcmdtbl
                 ldal           cmdtbl
                 sta            7,s
                 ldal           cmdtbl+2
                 sta            9,s
                 brl            noerror

qagetcmdrecsize
                 lda            #erecsize
                 sta            7,s
                 brl            noerror


qasetcmdhdl
                 lda            9,s
                 stal           cmdhandle
                 lda            11,s
                 stal           cmdhandle+2
                 lda            7,s
                 stal           numcmds
                 lda            5,s
                 sta            5+6,s
                 lda            3,s
                 sta            3+6,s
                 lda            1,s
                 sta            1+6,s
                 pla
                 pla
                 pla
                 brl            noerror
qagetcmdhdl
                 ldal           numcmds
                 sta            7,s
                 ldal           cmdhandle
                 sta            9,s
                 ldal           cmdhandle+2
                 sta            11,s
                 brl            noerror


qacalllang
                 dum            0
]rtl             ds             6                           ;these are passed on stack
]subtype         ds             4
]message         ds             2
]langid          ds             2
]newstack        =              *-6                         ;must be at end of passed params
                 dend

                 mx             %00
                 tsc
                 sec
                 sbc            #]rtl
                 tcs
                 phd
                 inc
                 tcd
                 phb
                 phk
                 plb
***
                 lda            #0
:xit             rep            $30
                 tax
                 lda            ]rtl+4
                 sta            ]newstack+4
                 lda            ]rtl+2
                 sta            ]newstack+2
                 lda            ]rtl
                 sta            ]newstack
                 plb
                 pld
                 tsc
                 clc
                 adc            #]newstack
                 tcs
                 txa
                 brl            errxit

QAParseWord
dummy
                 dum            0
]rtl             ds             6                           ;these are passed on stack
]newstack        =              *-6                         ;must be at end of passed params
                 dend

                 mx             %00
                 tsc
                 sec
                 sbc            #]rtl
                 tcs
                 phd
                 inc
                 tcd
                 phb
                 phk
                 plb
***

:xit             rep            $30
                 tax
                 lda            ]rtl+4
                 sta            ]newstack+4
                 lda            ]rtl+2
                 sta            ]newstack+2
                 lda            ]rtl
                 sta            ]newstack
                 plb
                 pld
                 tsc
                 clc
                 adc            #]newstack
                 tcs
                 txa
                 brl            errxit

qadrawchar
]char            =              8

                 phb
                 phk
                 plb
                 rep            $30
                 lda            windowflag
                 bne            :1
                 lda            ]char,s
                 jsl            {vprintchar*4}+vectortbl-4
                 bra            :xit
:1               lda            ]char,s
                 jsl            {verrchar*4}+vectortbl-4
:xit             plb
                 lda            5,s
                 sta            7,s
                 lda            3,s
                 sta            5,s
                 lda            1,s
                 sta            3,s
                 pla
                 brl            noerror

qadrawmultchar
]count           =              8
]char            =              10

                 phb
                 phk
                 plb
                 rep            $30
                 lda            windowflag
                 bne            :1
                 lda            ]count,s
                 beq            :xit
:0               lda            ]char,s
                 jsl            {vprintchar*4}+vectortbl-4
                 lda            ]count,s
                 dec
                 sta            ]count,s
                 bne            :0
                 bra            :xit
:1               lda            ]count
                 beq            :xit
:11              lda            ]char,s
                 jsl            {verrchar*4}+vectortbl-4
                 lda            ]count,s
                 dec
                 sta            ]count,s
                 bne            :11
:xit             plb
                 lda            5,s
                 sta            5+4,s
                 lda            3,s
                 sta            3+4,s
                 lda            1,s
                 sta            1+4,s
                 pla
                 pla
                 brl            noerror

qadrawmultechar
]count           =              8
]char            =              10

                 phb
                 phk
                 plb
                 rep            $30
                 lda            ]count,s
                 beq            :xit
:1               lda            ]char,s
                 jsl            {verrchar*4}+vectortbl-4
                 lda            ]count,s
                 dec
                 sta            ]count,s
                 bne            :1
:xit             plb
                 lda            5,s
                 sta            5+4,s
                 lda            3,s
                 sta            3+4,s
                 lda            1,s
                 sta            1+4,s
                 pla
                 pla
                 brl            noerror


qadrawstring
]strptr          =              8

                 phb
                 phk
                 plb
                 lda            ]strptr+2,s
                 tax
                 lda            ]strptr,s
                 tay
                 lda            windowflag
                 beq            :tya
                 tya
                 jsl            {verrstr*4}+vectortbl-4
                 bra            :xit
:tya             tya
                 jsl            {vprintstr*4}+vectortbl-4
:xit             plb
                 lda            5,s
                 sta            9,s
                 lda            3,s
                 sta            7,s
                 lda            1,s
                 sta            5,s
                 pla
                 pla
                 brl            noerror

qadrawerrchar
]char            =              7
                 phb
                 phk
                 plb
                 lda            ]char,s
                 jsl            {verrchar*4}+vectortbl-4
                 plb
                 lda            5,s
                 sta            7,s
                 lda            3,s
                 sta            5,s
                 lda            1,s
                 sta            3,s
                 pla
                 brl            noerror

qadrawerrstring
]strptr          =              8
                 phb
                 phk
                 plb
                 lda            ]strptr+2,s
                 tax
                 lda            ]strptr,s
                 jsl            {verrstr*4}+vectortbl-4
                 plb
                 lda            5,s
                 sta            9,s
                 lda            3,s
                 sta            7,s
                 lda            1,s
                 sta            5,s
                 pla
                 pla
                 brl            noerror

qadrawerrstrl
]strptr          =              8
                 phb
                 phk
                 plb
                 lda            ]strptr+2,s
                 tax
                 lda            ]strptr,s
                 jsl            {verrstrl*4}+vectortbl-4
                 plb
                 lda            5,s
                 sta            9,s
                 lda            3,s
                 sta            7,s
                 lda            1,s
                 sta            5,s
                 pla
                 pla
                 jmp            noerror

qadrawstrl
]strptr          =              8

                 phb
                 phk
                 plb
                 lda            ]strptr+2,s
                 tax
                 lda            ]strptr,s
                 tay
                 ldal           windowflag
                 beq            :tya
                 tya
                 jsl            {verrstrl*4}+vectortbl-4
                 bra            :xit
:tya             tya
                 jsl            {vprintstrl*4}+vectortbl-4
:xit             plb
                 lda            5,s
                 sta            9,s
                 lda            3,s
                 sta            7,s
                 lda            1,s
                 sta            5,s
                 pla
                 pla
                 jmp            noerror

qadrawblock
]strptr          =              8

                 phb
                 phk
                 plb
                 lda            ]strptr+2,s
                 tax
                 lda            ]strptr,s
                 tay
                 lda            windowflag
                 beq            :tya
                 tya
                 jsl            {verrblk*4}+vectortbl-4
                 bra            :xit
:tya             tya
                 jsl            {vprintblk*4}+vectortbl-4
:xit             plb
                 lda            5,s
                 sta            9,s
                 lda            3,s
                 sta            7,s
                 lda            1,s
                 sta            5,s
                 pla
                 pla
                 brl            noerror

qadrawerrblock
]strptr          =              8
                 phb
                 phk
                 plb
                 lda            ]strptr+2,s
                 tax
                 lda            ]strptr,s
                 jsl            {verrblk*4}+vectortbl-4
                 plb
                 lda            5,s
                 sta            9,s
                 lda            3,s
                 sta            7,s
                 lda            1,s
                 sta            5,s
                 pla
                 pla
                 brl            noerror


qatabtocol
                 lda            7,s
                 jsl            {vtabtocol*4}+vectortbl-4
                 tax
                 lda            5,s
                 sta            5+2,s
                 lda            3,s
                 sta            3+2,s
                 lda            1,s
                 sta            1+2,s
                 pla
                 txa
                 rtl

qagotoxy         lda            7,s
                 stal           cursy
                 lda            9,s
                 stal           cursx
                 phb
                 phk
                 plb
                 jsr            setcurs
                 plb
                 tax
                 lda            5,s
                 sta            5+4,s
                 lda            3,s
                 sta            3+4,s
                 lda            1,s
                 sta            1+4,s
                 pla
                 pla
                 txa
                 rtl

qagetxy          ldal           cursy
                 sta            7,s
                 ldal           cursx
                 sta            9,s
                 brl            noerror

qaprnib

]byte            =              7
                 lda            ]byte,s
                 jsr            myPrNib
                 lda            5,s
                 sta            7,s
                 lda            3,s
                 sta            5,s
                 lda            1,s
                 sta            3,s
                 pla
                 brl            noerror

qaprbyte

]byte            =              7
                 lda            ]byte,s
                 lsr
                 lsr
                 lsr
                 lsr
                 jsr            myPrNib
                 lda            ]byte,s
                 jsr            myPrNib
                 lda            5,s
                 sta            7,s
                 lda            3,s
                 sta            5,s
                 lda            1,s
                 sta            3,s
                 pla
                 brl            noerror

qaprbytel

]byte            =              7
                 lda            ]byte+1,s
                 lsr
                 lsr
                 lsr
                 lsr
                 jsr            myPrNib
                 lda            ]byte+1,s
                 jsr            myPrNib
                 lda            ]byte,s
                 lsr
                 lsr
                 lsr
                 lsr
                 jsr            myPrNib
                 lda            ]byte,s
                 jsr            myPrNib
                 lda            5,s
                 sta            7,s
                 lda            3,s
                 sta            5,s
                 lda            1,s
                 sta            3,s
                 pla
                 brl            noerror

myPrNib
                 phb
                 phk
                 plb
                 and            #$0F
                 tax
                 lda            hextbl,x
                 jsl            {vprintchar*4}+vectortbl-4
                 plb
                 rts

hextbl           asc            '0123456789ABCDEF'

*------------------------------------------------------
                 mx             %00
qakeyavail
                 lda            #0
                 sta            7,s
                 jsl            {vkeymac*4}+vectortbl-4
                 bcc            :myavail
                 sta            7,s
                 brl            noerror
:myavail
                 lda            #0
                 jsl            {vkeyavail*4}+vectortbl-4
                 rep            $30
                 bcs            :rtl
                 sta            7,s
:rtl             rtl

*------------------------------------------------------
qagetchar
                 lda            #$01
                 jsl            {vkeymac*4}+vectortbl-4
                 bcc            :myget
                 sta            7,s
                 brl            noerror
:myget           lda            #0
                 sta            7,s
                 jsl            {vgetchar*4}+vectortbl-4
                 rep            $30
                 bcs            :rtl
                 sta            7,s
:rtl             rtl

                 mx             %00

qagetmodeflags
                 ldal           modeflags
                 sta            7,s
                 ldal           modeflags+2
                 sta            9,s
                 brl            noerror

qasetmodeflags
                 lda            7,s
                 stal           modeflags
                 lda            9,s
                 stal           modeflags+2
                 lda            5,s
                 sta            9,s
                 lda            3,s
                 sta            7,s
                 lda            1,s
                 sta            5,s
                 pla
                 pla
                 brl            noerror

qalinkactive
                 ldal           linkactive
                 sta            7,s
                 brl            noerror
qacompileactive
                 ldal           compileactive
                 sta            7,s
                 brl            noerror

qaloadfile
                 dum            0

]loadzp          ds             4
]rtl             ds             3                           ;these are passed on stack
]rtl1            ds             3
]memattrib       ds             2
]loadadr         ds             4
]loadid          ds             2
]typeptr         ds             4
]length          ds             4
]filepos         ds             4
]nameptr         ds             4
]newstack        =              *-6                         ;must be at end of passed params
]loadhandle      ds             4                           ;these are returned on stack

                 dend

                 mx             %00

                 tsc
                 sec
                 sbc            #]rtl
                 tcs
                 phd
                 inc
                 tcd
                 phb
                 phk
                 plb

                 stz            :errcode                    ;init all variables
                 stz            :close
                 stz            :open
                 stz            :read
                 stz            :markparm
                 stz            :lockflag

                 stz            ]loadhandle
                 stz            ]loadhandle+2

                 lda            ]nameptr
                 sta            :pathptr
                 sta            :info
                 lda            ]nameptr+2
                 sta            :pathptr+2
                 sta            :info+2
                 lda            ]length
                 sta            :request
                 lda            ]length+2
                 sta            :request+2

                 _GSOS          _getfileinfo;:info
                 jcs            :doserror
                 sep            $30
                 lda            []typeptr]
                 beq            :all
                 tay
]lup             lda            []typeptr],y
                 cmp            :ftype
                 beq            :all
                 dey
                 bne            ]lup
                 rep            $30
                 lda            #$5C                        ;file mismatch error
                 brl            :doserror

:all             rep            $30
                 lda            ]length+2
                 and            ]length
                 cmp            #$ffff
                 bne            :norm

                 jsl            prodos
                 dw             $10
                 adrl           :open
                 jcs            :doserror

                 lda            :open
                 sta            :eof
                 jsl            prodos
                 dw             $19
                 adrl           :eof
                 jcs            :doserror
                 lda            :eof+2
                 sta            :request
                 lda            :eof+4
                 sta            :request+2

:norm            psl            #0
                 psl            :request
                 lda            ]loadid
                 pha
                 lda            ]memattrib
                 pha
                 psl            ]loadadr                    ;where do we want it?
                 tll            $0902
                 plx
                 ply
                 jcs            :doserror
                 stx            ]loadhandle
                 sty            ]loadhandle+2

                 ldy            #$04
                 lda            []loadhandle],y
                 and            #$8000
                 sta            :lockflag
                 lda            []loadhandle],y
                 ora            #$8000
                 sta            []loadhandle],y
                 ldy            #$02
                 lda            []loadhandle]
                 sta            :buffer
                 tax
                 lda            []loadhandle],y
                 sta            :buffer+2
                 sta            ]loadzp+2
                 stx            ]loadzp
:load            lda            :open
                 bne            :o
                 jsl            prodos
                 dw             $10
                 adrl           :open
                 jcs            :doserror
:o               lda            :open
                 sta            :read
                 sta            :markparm

                 lda            ]filepos
                 sta            :markparm+2
                 lda            ]filepos+2
                 sta            :markparm+4

                 jsl            prodos
                 dw             $16
                 adrl           :markparm
                 jcs            :doserror

                 jsl            prodos
                 dw             $12
                 adrl           :read
                 jcs            :doserror

                 _GSOS          _close;:open
                 stz            :open
                 jcs            :doserror

                 lda            :ftype
                 cmp            #$04
                 beq            :addcr
                 cmp            #$b0
                 bne            :noerr
:addcr           lda            :request
                 clc
                 adc            :buffer
                 sta            ]loadzp
                 lda            :request+2
                 adc            :buffer+2
                 sta            ]loadzp+2
                 lda            ]loadzp
                 bne            :d
                 dec            ]loadzp+2
:d               dec            ]loadzp
                 lda            []loadzp]
                 and            #$7f
                 cmp            #$0d
                 beq            :noerr
                 psl            ]loadhandle
                 _Hunlock
                 psl            #0
                 psl            ]loadhandle
                 _gethandlesize
                 pll            ]loadzp
                 inc            ]loadzp
                 bne            :noinc
                 inc            ]loadzp+2
:noinc           psl            ]loadzp
                 psl            ]loadhandle
                 _sethandlesize
                 bcs            :doserror
                 ldy            #$02
                 lda            []loadhandle]
                 clc
                 adc            ]loadzp
                 sta            ]loadzp
                 lda            []loadhandle],y
                 adc            ]loadzp+2
                 sta            ]loadzp+2
                 sep            $20
                 lda            #$0d
                 sta            []loadzp]
:noerr           rep            $30
                 lda            #0
:doserror        sta            :errcode
                 lda            ]loadhandle
                 ora            ]loadhandle+2
                 beq            :e1
                 lda            :errcode
                 bne            :dispose
                 ldy            #$04
                 lda            []loadhandle],y
                 and            #$7fff
                 ora            :lockflag
                 sta            []loadhandle],y
                 stz            :lockflag
                 bra            :e1
:dispose         psl            ]loadhandle
                 _disposehandle
                 stz            ]loadhandle
                 stz            ]loadhandle+2
:e1              lda            :open
                 beq            :noclose

                 jsl            prodos
                 dw             $14                         ;close the file
                 adrl           :open

:noclose         rep            $30
                 stz            :open
                 lda            :errcode
:xit             rep            $30
                 pha                                        ;save the error
                 lda            ]rtl+4
                 sta            ]newstack+4
                 lda            ]rtl+2
                 sta            ]newstack+2
                 lda            ]rtl
                 sta            ]newstack
                 pla
                 plb
                 pld
                 tax
                 tsc
                 clc
                 adc            #]newstack
                 tcs
                 txa
                 cmp            #$01
                 rtl

:errcode         ds             2
:lockflag        ds             2

:open            dw             0
:pathptr         adrl           $0000
                 adrl           0
:markparm        dw             0
:mark            adrl           0
:read            dw             0
:buffer          ds             4
:request         ds             4
                 ds             4
:close           dw             0
:eof             ds             6,0
:info            adrl           $0000
                 dw             0
:ftype           dw             0
                 ds             18,0


***
qasavefile
                 dum            0

]rtl             ds             3                           ;these are passed on stack
]rtl1            ds             3
]auxtype         ds             4
]filetype        ds             2
]nameptr         ds             4
]datahandle      ds             4
]newstack        =              *-6                         ;must be at end of passed params

                 dend

                 mx             %00

                 tsc
                 sec
                 sbc            #]rtl
                 tcs
                 phd
                 inc
                 tcd
                 phb
                 phk
                 plb

                 stz            :errcode                    ;init all variables
                 stz            :open
                 stz            :lockflag

                 lda            ]nameptr
                 sta            :pathptr
                 sta            :create
                 sta            :info
                 lda            ]nameptr+2
                 sta            :pathptr+2
                 sta            :create+2
                 sta            :info+2

                 psl            #0
                 psl            ]datahandle
                 _gethandlesize
                 plx
                 ply
                 jcs            :err
                 stx            :request
                 sty            :request+2

                 _GSOS          _getfileinfo;:info
                 bcc            :nocreate

                 lda            ]filetype
                 sta            :ctype
                 lda            ]auxtype
                 sta            :caux
                 lda            ]auxtype+2
                 sta            :caux+2
                 _GSOS          _create;:create
                 jcs            :err
                 _GSOS          _getfileinfo;:info
                 jcs            :err

:nocreate
                 lda            :ftype
                 cmp            ]filetype
                 beq            :doopen
                 lda            #$5C                        ;file mismatch error
                 brl            :err
:doopen          _GSOS          _open;:open
                 jcs            :err
                 lda            :open
                 sta            :write
                 ldy            #$04
                 lda            []datahandle],y
                 and            #$8000
                 sta            :lockflag
                 lda            []datahandle],y
                 ora            #$8000
                 sta            []datahandle],y
                 ldy            #$02
                 lda            []datahandle]
                 sta            :buffer
                 lda            []datahandle],y
                 sta            :buffer+2
                 _GSOS          _write;:write
                 php
                 pha
                 ldy            #$04
                 lda            []datahandle],y
                 and            #$7fff
                 ora            :lockflag
                 sta            []datahandle],y
                 pla
                 plp
                 bcs            :err
                 lda            :open
                 sta            :mark
                 _GSOS          _getmark;:mark
                 _GSOS          _seteof;:mark
                 _GSOS          _close;:open
                 bcs            :err
                 stz            :open
                 _GSOS          _getfileinfo;:info
                 bcs            :err
                 lda            ]auxtype
                 sta            :aux
                 lda            ]auxtype+2
                 sta            :aux+2
                 _GSOS          _setfileinfo;:info
                 bcs            :err
                 lda            #0
:err             sta            :errcode
                 lda            :open
                 beq            :noclose
                 jsl            prodos
                 dw             $14                         ;close the file
                 adrl           :open
:noclose         rep            $30
                 stz            :open
                 lda            :errcode
:xit             rep            $30
                 pha                                        ;save the error
                 lda            ]rtl+4
                 sta            ]newstack+4
                 lda            ]rtl+2
                 sta            ]newstack+2
                 lda            ]rtl
                 sta            ]newstack
                 pla
                 plb
                 pld
                 tax
                 tsc
                 clc
                 adc            #]newstack
                 tcs
                 txa
                 cmp            #$01
                 rtl

:errcode         ds             2
:lockflag        ds             2

:open            dw             0
:pathptr         adrl           $0000
                 adrl           0
:write           dw             0
:buffer          ds             4
:request         ds             4
                 ds             4
:info            adrl           $0000
                 dw             0
:ftype           dw             0
:aux             ds             18,0
:mark            ds             6
:create          adrl           0
                 dw             $e3
:ctype           dw             0
:caux            adrl           0
                 dw             $01
                 adrl           0
                 adrl           0


qagetcmdline
                 dum            0
]rtl             ds             6                           ;these are passed on stack
]maxlen          ds             2
]strptr          ds             4

]newstack        =              *-6                         ;must be at end of passed params
                 dend

                 mx             %00
                 tsc
                 sec
                 sbc            #]rtl
                 tcs
                 phd
                 inc
                 tcd
                 phb
                 phk
                 plb
                 lda            ]maxlen
                 and            #$ff
                 beq            :xit
                 sta            ]maxlen
                 sep            $30
                 lda            cmdstr
                 cmp            ]maxlen
                 blt            :ok
                 beq            :ok
                 lda            ]maxlen
:ok              tay
]lup             lda            cmdstr,y
                 sta            []strptr],y
                 dey
                 cpy            #$ff
                 bne            ]lup
:xit             rep            $30
                 tax
                 lda            ]rtl+4
                 sta            ]newstack+4
                 lda            ]rtl+2
                 sta            ]newstack+2
                 lda            ]rtl
                 sta            ]newstack
                 plb
                 pld
                 tsc
                 clc
                 adc            #]newstack
                 tcs
                 txa
                 brl            errxit


qasetcmdline
                 dum            0
]rtl             ds             6                           ;these are passed on stack
]strptr          ds             4
]newstack        =              *-6                         ;must be at end of passed params
                 dend

                 mx             %00
                 tsc
                 sec
                 sbc            #]rtl
                 tcs
                 phd
                 inc
                 tcd
                 phb
                 phk
                 plb
                 sep            $30
                 lda            []strptr]
                 bne            :move
                 sta            cmdstr
                 brl            :xit
:move            tax
                 ldy            #$01
]lup             lda            []strptr],y
                 and            #$7f
                 cmp            #' '
                 blt            :done
                 sta            cmdstr,y
                 iny
                 dey
                 dex
                 bne            ]lup
:done            lda            #$0d
                 sta            cmdstr,y
                 sty            cmdstr
                 rep            $30
                 lda            #'|'
                 jsl            {vprintchar*4}+vectortbl-4
                 psl            #cmdstr
                 _QADrawStr

:xit             rep            $30
                 tax
                 lda            ]rtl+4
                 sta            ]newstack+4
                 lda            ]rtl+2
                 sta            ]newstack+2
                 lda            ]rtl
                 sta            ]newstack
                 plb
                 pld
                 tsc
                 clc
                 adc            #]newstack
                 tcs
                 txa
                 brl            errxit

:len             ds             2
:cmd             ds             17


qaparseline
                 dum            0
]ct              ds             2
]ptr             ds             4
]rtl             ds             6                           ;these are passed on stack
]strptr          ds             4
]newstack        =              *-6                         ;must be at end of passed params
]cmdtype         ds             2
]cmdid           ds             2
                 dend

                 mx             %00
                 tsc
                 sec
                 sbc            #]rtl
                 tcs
                 phd
                 inc
                 tcd
                 phb
                 phk
                 plb
                 stz            ]cmdtype
                 stz            ]cmdid
                 sep            $30
                 lda            []strptr]
                 jeq            :xit
                 ldy            #$01
                 tax
]lup             lda            []strptr],y
                 and            #$7f
                 cmp            #' '
                 blt            :done
                 sta            cmdstr,y
                 iny
                 dex
                 bne            ]lup
:done            lda            #$0d
                 cpy            #0
                 bne            :sta
                 ldy            #$ff
:sta             sta            cmdstr,y
                 sty            cmdstr
                 ldx            #0
]lup             lda            cmdstr+1,x
                 inx
                 cmp            #' '
                 jlt            :xit
                 beq            ]lup
                 ldy            #$01
                 cmp            #'a'
                 blt            :s0
                 cmp            #'z'+1
                 bge            :s0
                 and            #$5f
:s0              sta            :cmd+1
]lup             lda            cmdstr+1,x
                 cmp            #' '+1
                 blt            :sty
                 cpy            #15
                 bge            :s1
                 cmp            #'a'
                 blt            :s00
                 cmp            #'z'+1
                 bge            :s00
                 and            #$5f
:s00             sta            :cmd+1,y
                 iny
:s1              inx
                 bra            ]lup
:run             rep            $30
                 and            #$7f
                 sta            :cmd+1
                 ldy            #$01
                 sep            $30
                 sty            :cmd
                 bra            :r1
:sty             sep            $30
                 sty            :cmd
                 lda            :cmd+1
                 cmp            #'='
                 beq            :run
                 cmp            #'-'
                 beq            :run
:r1              rep            $30
                 lda            cmdhandle
                 ora            cmdhandle+2
                 jeq            :notfound
                 psl            cmdhandle
                 _Hlock
                 lda            numcmds
                 sta            ]ct
                 lda            cmdhandle
                 sta            ]ptr
                 lda            cmdhandle+2
                 sta            ]ptr+2
                 ldy            #$02
                 lda            []ptr]
                 tax
                 lda            []ptr],y
                 sta            ]ptr+2
                 stx            ]ptr
:find            rep            $30
                 ldy            ]ct
                 beq            :notfound
                 sep            $30
                 lda            []ptr]
                 cmp            :cmd
                 bne            :next
                 tay
:fl1             lda            []ptr],y
                 cmp            :cmd,y
                 bne            :next
                 dey
                 bne            :fl1
                 brl            :found
:next            rep            $30
                 lda            ]ptr
                 clc
                 adc            #erecsize
                 sta            ]ptr
                 bcc            :dec
                 inc            ]ptr+2
:dec             dec            ]ct
                 bra            :find
:found           rep            $30
                 ldy            #eid
                 lda            []ptr],y
                 sta            ]cmdid
                 ldy            #etype
                 lda            []ptr],y
                 sta            ]cmdtype
                 lda            #0
                 brl            :xit
:notfound        rep            $30
                 lda            #qacmdnotfound
:xit             rep            $30
                 tax
                 lda            ]rtl+4
                 sta            ]newstack+4
                 lda            ]rtl+2
                 sta            ]newstack+2
                 lda            ]rtl
                 sta            ]newstack
                 plb
                 pld
                 tsc
                 clc
                 adc            #]newstack
                 tcs
                 txa
                 brl            errxit

:len             ds             2
:cmd             ds             17

qacompile                                                   ;
                 dum            0
]zp              ds             4
]zp1             ds             4
]cid             ds             2
]ctype           ds             2
]rtl             ds             6                           ;these are passed on stack
]sub             ds             4
]message         ds             2
]newstack        =              *-6                         ;must be at end of passed params
                 dend

                 mx             %00
                 tsc
                 sec
                 sbc            #]rtl
                 tcs
                 phd
                 inc
                 tcd
                 phb
                 phk
                 plb
                 lda            compileactive
                 jne            :already
                 lda            cmdtbl
                 ora            cmdtbl+2
                 jeq            :notavail
                 lda            compiler
                 jeq            :notavail
                 sta            ]cid
                 lda            #$02                        ;compiler type
                 sta            ]ctype
:loadit
                 psl            #0
                 lda            ]ctype
                 pha
                 lda            ]cid
                 pha
                 jsl            getcmdptr
                 plx
                 ply
                 jcs            :notavail
                 sty            ]zp+2
                 stx            ]zp
                 ldy            #euserid
                 lda            []zp],y
                 beq            :aload
                 ldy            #eflags
                 lda            []zp],y
                 bit            #$4000
                 beq            :aload
                 lda            ]zp
                 ldx            ]zp+2
                 jsr            shutdownid
:aload           sep            $30
                 lda            []zp]
                 tay
]lup             lda            []zp],y
                 sta            :name+2,y
                 dey
                 bne            ]lup
                 lda            []zp]
                 clc
                 adc            #$02
                 sta            :name
                 lda            #'6'
                 sta            :name+1
                 lda            #':'
                 sta            :name+2
                 rep            $30
                 ldy            #eflags
                 lda            []zp],y
                 bit            #$8000
                 beq            :initial
                 ldy            #euserid
                 lda            []zp],y
                 beq            :initial
                 pha
                 pha
                 pha
                 pha
                 pha
                 pha
                 tll            $0a11                       ;_Restart
                 plx
                 stx            :id
                 plx
                 stx            :add
                 plx
                 stx            :add+2
                 plx
                 ply
                 bcc            :cpy
:initial         rep            $30
                 pha
                 pha
                 pha
                 pha
                 pha
                 pea            0                           ;new userid
                 psl            #:name
                 pea            $FFFF                       ;don't use special mem
                 tll            $0911                       ;_InitialLoad
                 plx                                        ;userid
                 stx            :id
                 plx
                 stx            :add
                 plx
                 stx            :add+2
                 plx
                 ply
                 jcs            :xit
:cpy             cpy            #0
                 beq            :newdp
                 stx            :dp
                 stz            ]zp1
                 stz            ]zp1+2
                 bra            :ago
:newdp           psl            #0
                 psl            #$100
                 lda            :id
                 pha
                 pea            $c015
                 psl            #0
                 _newhandle
                 plx
                 ply
                 jcs            :xit
                 stx            ]zp1
                 sty            ]zp1+2
                 lda            []zp1]
                 sta            :dp
                 ldy            #$02
                 lda            []zp1]
                 tax
                 lda            []zp1],y
                 sta            ]zp1+2
                 stx            ]zp1
                 phd
                 lda            :dp
                 tcd
                 ldx            #0
]l               stz            0,x
                 inx
                 inx
                 cpx            #$100
                 blt            ]l
                 pld
:ago             lda            :add
                 sta            :ajsl+1
                 lda            :add+2
                 sep            $20
                 sta            :ajsl+3
                 rep            $20
                 ldy            #edp
                 lda            :dp
                 sta            []zp],y
                 ldy            #eaddress
                 lda            :add
                 sta            []zp],y
                 iny
                 iny
                 lda            :add+2
                 sta            []zp],y
                 ldy            #eflags
                 lda            []zp],y
                 ora            #$4000
                 sta            []zp],y
                 ldy            #emesstype
                 lda            ]message
                 sta            []zp],y
                 ldy            #emesssub
                 lda            ]sub
                 sta            []zp],y
                 iny
                 iny
                 lda            ]sub+2
                 sta            []zp],y
                 ldy            #euserid
                 lda            :id
                 sta            []zp],y
                 ldy            #edphandle
                 lda            ]zp1
                 sta            []zp],y
                 iny
                 iny
                 lda            ]zp1+2
                 sta            []zp],y

                 lda            #-1
                 sta            compileactive
                 phb
                 phd
                 lda            :dp
                 tcd
                 lda            :id
                 ldx            #0
                 txy
:ajsl            jsl            $FFFFFF
                 php
                 clc
                 xce
                 plp
                 rep            $30
                 stz            compileactive
                 pld
                 plb

                 php
                 pha
                 bcs            :sdown
                 ldy            #etype
                 lda            []zp],y
                 cmp            #$05
                 beq            :nosdown
                 ldy            #eflags
                 lda            []zp],y
                 bit            #$4000
                 beq            :nosdown
:sdown           lda            ]zp
                 ldx            ]zp+2
                 jsr            shutdownid
:nosdown         pla
                 plp
                 jcs            :xit
                 lda            #0
                 brl            :xit

:bad             rep            $30
                 lda            #qacmdnotfound
                 bra            :xit
:already         rep            $30
                 lda            #qaalreadyactive
                 bra            :xit
:notavail        rep            $30
                 lda            #qalangnotavail
:xit             rep            $30
                 tax
                 lda            ]rtl+4
                 sta            ]newstack+4
                 lda            ]rtl+2
                 sta            ]newstack+2
                 lda            ]rtl
                 sta            ]newstack
                 plb
                 pld
                 tsc
                 clc
                 adc            #]newstack
                 tcs
                 txa
                 brl            errxit

:name            ds             20
:id              ds             2
:add             ds             4
:dp              ds             2


qalink
                 dum            0
]zp              ds             4
]zp1             ds             4
]cid             ds             2
]ctype           ds             2
]rtl             ds             6                           ;these are passed on stack
]sub             ds             4
]message         ds             2
]newstack        =              *-6                         ;must be at end of passed params
                 dend

                 mx             %00
                 tsc
                 sec
                 sbc            #]rtl
                 tcs
                 phd
                 inc
                 tcd
                 phb
                 phk
                 plb
                 lda            linkactive
                 jne            :already
                 lda            cmdtbl
                 ora            cmdtbl+2
                 jeq            :notavail
                 lda            linker
                 jeq            :notavail
                 sta            ]cid
                 lda            #$01                        ;linker type
                 sta            ]ctype

:loadit          psl            #0
                 lda            ]ctype
                 pha
                 lda            ]cid
                 pha
                 jsl            getcmdptr
                 plx
                 ply
                 jcs            :notavail
                 sty            ]zp+2
                 stx            ]zp
                 ldy            #euserid
                 lda            []zp],y
                 beq            :aload
                 ldy            #eflags
                 lda            []zp],y
                 bit            #$4000
                 beq            :aload
                 lda            ]zp
                 ldx            ]zp+2
                 jsr            shutdownid
:aload           sep            $30
                 lda            []zp]
                 tay
]lup             lda            []zp],y
                 sta            :name+2,y
                 dey
                 bne            ]lup
                 lda            []zp]
                 clc
                 adc            #$02
                 sta            :name
                 lda            #'6'
                 sta            :name+1
                 lda            #':'
                 sta            :name+2
                 rep            $30
                 ldy            #eflags
                 lda            []zp],y
                 bit            #$8000
                 beq            :initial
                 ldy            #euserid
                 lda            []zp],y
                 beq            :initial
                 pha
                 pha
                 pha
                 pha
                 pha
                 pha
                 tll            $0a11                       ;_Restart
                 plx
                 stx            :id
                 plx
                 stx            :add
                 plx
                 stx            :add+2
                 plx
                 ply
                 bcc            :cpy
:initial         rep            $30
                 pha
                 pha
                 pha
                 pha
                 pha
                 pea            0                           ;new userid
                 psl            #:name
                 pea            $FFFF                       ;don't use special mem
                 tll            $0911                       ;_InitialLoad
                 plx                                        ;userid
                 stx            :id
                 plx
                 stx            :add
                 plx
                 stx            :add+2
                 plx
                 ply
                 jcs            :xit
:cpy             cpy            #0
                 beq            :newdp
                 stx            :dp
                 stz            ]zp1
                 stz            ]zp1+2
                 bra            :ago
:newdp           psl            #0
                 psl            #$100
                 lda            :id
                 pha
                 pea            $c015
                 psl            #0
                 _newhandle
                 plx
                 ply
                 jcs            :xit
                 stx            ]zp1
                 sty            ]zp1+2
                 lda            []zp1]
                 sta            :dp
                 ldy            #$02
                 lda            []zp1]
                 tax
                 lda            []zp1],y
                 sta            ]zp1+2
                 stx            ]zp1
                 phd
                 lda            :dp
                 tcd
                 ldx            #0
]l               stz            0,x
                 inx
                 inx
                 cpx            #$100
                 blt            ]l
                 pld
:ago             lda            :add
                 sta            :ajsl+1
                 lda            :add+2
                 sep            $20
                 sta            :ajsl+3
                 rep            $20
                 ldy            #edp
                 lda            :dp
                 sta            []zp],y
                 ldy            #eaddress
                 lda            :add
                 sta            []zp],y
                 iny
                 iny
                 lda            :add+2
                 sta            []zp],y
                 ldy            #eflags
                 lda            []zp],y
                 ora            #$4000
                 sta            []zp],y
                 ldy            #emesstype
                 lda            ]message
                 sta            []zp],y
                 ldy            #emesssub
                 lda            ]sub
                 sta            []zp],y
                 iny
                 iny
                 lda            ]sub+2
                 sta            []zp],y
                 ldy            #euserid
                 lda            :id
                 sta            []zp],y
                 ldy            #edphandle
                 lda            ]zp1
                 sta            []zp],y
                 iny
                 iny
                 lda            ]zp1+2
                 sta            []zp],y

                 lda            #-1
                 sta            linkactive
                 phb
                 phd
                 lda            :dp
                 tcd
                 lda            :id
                 ldx            #0
                 txy
:ajsl            jsl            $FFFFFF
                 php
                 clc
                 xce
                 plp
                 rep            $30
                 stz            linkactive
                 pld
                 plb

                 php
                 pha
                 bcs            :sdown
                 ldy            #etype
                 lda            []zp],y
                 cmp            #$05
                 beq            :nosdown
                 ldy            #eflags
                 lda            []zp],y
                 bit            #$4000
                 beq            :nosdown
:sdown           lda            ]zp
                 ldx            ]zp+2
                 jsr            shutdownid
:nosdown         pla
                 plp
                 jcs            :xit
                 lda            #0
                 brl            :xit

:bad             rep            $30
                 lda            #qacmdnotfound
                 bra            :xit
:already         rep            $30
                 lda            #qaalreadyactive
                 bra            :xit
:notavail        rep            $30
                 lda            #qalinknotavail
:xit             rep            $30
                 tax
                 lda            ]rtl+4
                 sta            ]newstack+4
                 lda            ]rtl+2
                 sta            ]newstack+2
                 lda            ]rtl
                 sta            ]newstack
                 plb
                 pld
                 tsc
                 clc
                 adc            #]newstack
                 tcs
                 txa
                 brl            errxit

:name            ds             20
:id              ds             2
:add             ds             4
:dp              ds             2




qaexeccmd
                 dum            0
]zp              ds             4
]zp1             ds             4
]zp2             ds             4
]rtl             ds             6                           ;these are passed on stack
]cmdid           ds             2
]cmdtype         ds             2
]newstack        =              *-6                         ;must be at end of passed params
                 dend

                 mx             %00
                 tsc
                 sec
                 sbc            #]rtl
                 tcs
                 phd
                 inc
                 tcd
                 phb
                 phk
                 plb
                 lda            cmdtbl
                 ora            cmdtbl+2
                 jeq            :bad
                 lda            ]cmdtype
                 cmp            #$01                        ;linker type?
                 jeq            :linker
                 cmp            #$02
                 jeq            :compiler                   ;compiler type?
                 cmp            #$03
                 jeq            :internal                   ;internal command?
                 cmp            #$04
                 jeq            :external                   ;external command?
                 cmp            #$05
                 jeq            :application
:bad             rep            $30
                 lda            #qacmdnotfound
:xit             rep            $30
                 tax
                 lda            ]rtl+4
                 sta            ]newstack+4
                 lda            ]rtl+2
                 sta            ]newstack+2
                 lda            ]rtl
                 sta            ]newstack
                 plb
                 pld
                 tsc
                 clc
                 adc            #]newstack
                 tcs
                 txa
                 brl            errxit

:linker          psl            #0
                 lda            ]cmdtype
                 pha
                 lda            ]cmdid
                 pha
                 jsl            getcmdptr
                 plx
                 ply
                 jcs            :bad
                 sty            ]zp+2
                 stx            ]zp
                 ldy            #eid
                 lda            []zp],y
                 sta            linker
                 psl            #:lstr
                 bra            :lcxit

:compiler        psl            #0
                 lda            ]cmdtype
                 pha
                 lda            ]cmdid
                 pha
                 jsl            getcmdptr
                 plx
                 ply
                 jcs            :bad
                 sty            ]zp+2
                 stx            ]zp
                 ldy            #eid
                 lda            []zp],y
                 sta            compiler
                 psl            #:cstr
:lcxit           _QADrawString
                 pei            ]zp+2
                 pei            ]zp
                 _QADrawString
                 lda            #$0d
                 jsl            {vprintchar*4}+vectortbl-4
                 lda            #0
                 brl            :xit

:lstr            str            'Current Linker now: '
:cstr            str            'Current Language now: '

:external
:application     psl            #0
                 lda            ]cmdtype
                 pha
                 lda            ]cmdid
                 pha
                 jsl            getcmdptr
                 plx
                 ply
                 jcs            :bad
                 sty            ]zp+2
                 stx            ]zp
                 ldy            #euserid
                 lda            []zp],y
                 beq            :aload
                 ldy            #eflags
                 lda            []zp],y
                 bit            #$4000
                 beq            :aload
                 lda            ]zp
                 ldx            ]zp+2
                 jsr            shutdownid
:aload           sep            $30
                 lda            []zp]
                 tay
]lup             lda            []zp],y
                 sta            :name+2,y
                 dey
                 bne            ]lup
                 lda            []zp]
                 clc
                 adc            #$02
                 sta            :name
                 lda            #'6'
                 sta            :name+1
                 lda            #':'
                 sta            :name+2
                 rep            $30
                 ldy            #eflags
                 lda            []zp],y
                 bit            #$8000
                 beq            :initial
                 ldy            #euserid
                 lda            []zp],y
                 beq            :initial
                 pha
                 pha
                 pha
                 pha
                 pha
                 pha
                 tll            $0a11                       ;_Restart
                 plx
                 stx            :id
                 plx
                 stx            :add
                 plx
                 stx            :add+2
                 plx
                 ply
                 bcc            :cpy
:initial         rep            $30
                 pha
                 pha
                 pha
                 pha
                 pha
                 pea            0                           ;new userid
                 psl            #:name
                 pea            $FFFF                       ;don't use special mem
                 tll            $0911                       ;_InitialLoad
                 plx                                        ;userid
                 stx            :id
                 plx
                 stx            :add
                 plx
                 stx            :add+2
                 plx
                 ply
                 jcs            :xit
:cpy             cpy            #0
                 beq            :newdp
                 stx            :dp
                 stz            ]zp1
                 stz            ]zp1+2
                 bra            :ago
:newdp           psl            #0
                 psl            #$100
                 lda            :id
                 pha
                 pea            $c015
                 psl            #0
                 _newhandle
                 plx
                 ply
                 jcs            :xit
                 stx            ]zp1
                 sty            ]zp1+2
                 lda            []zp1]
                 sta            :dp
                 ldy            #$02
                 lda            []zp1]
                 tax
                 lda            []zp1],y
                 sta            ]zp1+2
                 stx            ]zp1
                 phd
                 lda            :dp
                 tcd
                 ldx            #0
]l               stz            0,x
                 inx
                 inx
                 cpx            #$100
                 blt            ]l
                 pld


:ago             rep            $30
                 lda            :add
                 sta            :ajsl+1
                 sta            ]zp2
                 lda            :add+2
                 sta            ]zp2+2
                 sep            $20
                 sta            :ajsl+3
                 rep            $20
                 ldy            #edp
                 lda            :dp
                 sta            []zp],y
                 ldy            #eaddress
                 lda            :add
                 sta            []zp],y
                 iny
                 iny
                 lda            :add+2
                 sta            []zp],y
                 ldy            #eflags
                 lda            []zp],y
                 ora            #$4000
                 sta            []zp],y
                 ldy            #emesstype
                 lda            #startmess                  ;startup message
                 sta            []zp],y
                 ldy            #emesssub
                 sta            []zp],y
                 iny
                 iny
                 sta            []zp],y
                 ldy            #euserid
                 lda            :id
                 sta            []zp],y
                 ldy            #edphandle
                 lda            ]zp1
                 sta            []zp],y
                 iny
                 iny
                 lda            ]zp1+2
                 sta            []zp],y

                 psl            #cmdline-1
                 pea            128
                 _QAGetCmdLine
                 sep            $30
                 ldx            cmdline-1
                 stz            cmdline,x
                 lda            #'S'
                 sta            cmdline-1
                 rep            $30

                 do             0
                 sep            $20
                 ldy            #$03                        ;look for QUICKASM in file
                 ldx            #0
]l               lda            []zp2],y
                 and            #$5f
                 cmp            qasmstr,x
                 jne            :nr1
                 iny
                 inx
                 cpx            #$08
                 blt            ]l
                 rep            $20
                 fin

                 brl            :run
:nr1             rep            $30
                 lda            #qabadcmdfile
                 sec
                 brl            :norun

:run             rep            $30
                 phb
                 phd
                 tsc
                 sta            stack
                 lda            #:return
                 sta            return
                 jsr            setvects
                 rep            $30
* lda #:ajsl
* brk $aa
                 lda            :dp
                 tcd
                 lda            :id
                 ldx            #^qasmstr
                 ldy            #qasmstr
:ajsl            jsl            $FFFFFF
:return          php
                 clc
                 xce
                 phk
                 plb
                 rep            $30
                 pha
                 jsr            restorevects
                 pla
                 plp
                 rep            $30
                 pld
                 plb

:norun           php
                 pha
                 bcs            :sdown
                 ldy            #etype
                 lda            []zp],y
                 cmp            #$05
                 beq            :nosdown
                 ldy            #eflags
                 lda            []zp],y
                 bit            #$4000
                 beq            :nosdown
:sdown           lda            ]zp
                 ldx            ]zp+2
                 jsr            shutdownid
:nosdown         pla
                 plp
                 jcs            :xit
                 lda            #0
                 brl            :xit


:name            ds             20
:id              ds             2
:add             ds             4
:dp              ds             2


:internal        lda            cmdtbl
                 sta            ]zp
                 lda            cmdtbl+2
                 sta            ]zp+2
                 lda            ]cmdid
                 jeq            :bad
                 cmp            []zp]
                 blt            :iok
                 jne            :bad
:iok             dec
                 asl
                 asl                                        ;*4
                 clc
                 adc            #$02                        ;to account for count word
                 tay
                 lda            []zp],y
                 sta            :ijsl+1
                 iny
                 iny
                 lda            []zp],y
                 sep            $20
                 sta            :ijsl+3
                 rep            $30
                 phd
                 phb
:ijsl            jsl            $FFFFFF
                 rep            $30
                 plb
                 pld
                 bcc            :i0
                 brl            :xit
:i0              lda            #0
                 brl            :xit


qagetmessbyid
                 dum            0
]ptr             ds             4
]ct              ds             2
]rtl             ds             6                           ;these are passed on stack
]userid          ds             2
]newstack        =              *-6                         ;must be at end of passed params
]subtype         ds             4
]message         ds             2
                 dend

                 mx             %00
                 tsc
                 sec
                 sbc            #]rtl
                 tcs
                 phd
                 inc
                 tcd
                 phb
                 phk
                 plb
                 stz            ]message
                 stz            ]subtype
                 stz            ]subtype+2
                 lda            ]userid
                 beq            :notfound
                 psl            cmdhandle
                 _Hlock
                 bcs            :notfound
                 lda            cmdhandle
                 sta            ]ptr
                 lda            cmdhandle+2
                 sta            ]ptr+2
                 ldy            #$02
                 lda            []ptr]
                 tax
                 lda            []ptr],y
                 sta            ]ptr+2
                 stx            ]ptr
                 lda            numcmds
                 sta            ]ct
]lup             lda            ]ct
                 beq            :notfound
                 ldy            #euserid
                 lda            []ptr],y
                 cmp            ]userid
                 beq            :found
:next            dec            ]ct
                 lda            #erecsize
                 clc
                 adc            ]ptr
                 sta            ]ptr
                 bcc            ]lup
                 inc            ]ptr+2
                 bra            ]lup
:found           ldy            #emesstype
                 lda            []ptr],y
                 sta            ]message
                 ldy            #emesssub
                 lda            []ptr],y
                 sta            ]subtype
                 iny
                 iny
                 lda            []ptr],y
                 sta            ]subtype+2
                 lda            #0
                 brl            :xit
:notfound        lda            #$01
:xit             rep            $30
                 tax
                 lda            ]rtl+4
                 sta            ]newstack+4
                 lda            ]rtl+2
                 sta            ]newstack+2
                 lda            ]rtl
                 sta            ]newstack
                 plb
                 pld
                 tsc
                 clc
                 adc            #]newstack
                 tcs
                 txa
                 brl            errxit



qarun
                 dum            0
]ptr             ds             4
]ct              ds             2
]rtl             ds             6                           ;these are passed on stack
]newstack        =              *-6                         ;must be at end of passed params
                 dend

                 mx             %00
                 tsc
                 sec
                 sbc            #]rtl
                 tcs
                 phd
                 inc
                 tcd
                 phb
                 phk
                 plb
                 psl            cmdhandle
                 _Hlock
                 jcs            :done
                 lda            cmdhandle
                 sta            ]ptr
                 lda            cmdhandle+2
                 sta            ]ptr+2
                 ldy            #$02
                 lda            []ptr]
                 tax
                 lda            []ptr],y
                 sta            ]ptr+2
                 stx            ]ptr
                 lda            numcmds
                 sta            ]ct
]lup             lda            ]ct
                 beq            :done
                 ldy            #euserid
                 lda            []ptr],y
                 beq            :next
                 ldy            #etype
                 lda            []ptr],y
                 cmp            #$05                        ;application?
                 bne            :next
                 ldy            #eaddress
                 lda            []ptr],y
                 iny
                 iny
                 ora            []ptr],y
                 beq            :next
                 ldy            #emesstype
                 lda            #runmess
                 sta            []ptr],y
                 ldy            #emesssub
                 lda            #0
                 sta            []ptr],y
                 iny
                 iny
                 sta            []ptr],y
                 ldy            #eaddress
                 lda            []ptr],y
                 sta            :jsl+1
                 iny
                 iny
                 lda            []ptr],y
                 sep            $20
                 sta            :jsl+3
                 rep            $30
                 ldy            #euserid
                 lda            []ptr],y
                 tax
                 ldy            #edp
                 lda            []ptr],y
                 phd
                 phb
                 tcd
                 txa
                 ldy            #0
                 tyx
:jsl             jsl            $FFFFFF
                 php
                 clc
                 xce
                 plp
                 rep            $30
                 plb
                 pld
                 ldy            #emesstype
                 lda            #0
                 sta            []ptr],y
:next            dec            ]ct
                 lda            #erecsize
                 clc
                 adc            ]ptr
                 sta            ]ptr
                 bcc            ]lup
                 inc            ]ptr+2
                 bra            ]lup
:done            lda            #0
:xit             rep            $30
                 tax
                 lda            ]rtl+4
                 sta            ]newstack+4
                 lda            ]rtl+2
                 sta            ]newstack+2
                 lda            ]rtl
                 sta            ]newstack
                 plb
                 pld
                 tsc
                 clc
                 adc            #]newstack
                 tcs
                 txa
                 brl            errxit


qaevent
                 dum            0
]ptr             ds             4
]ct              ds             2
]rtl             ds             6                           ;these are passed on stack
]taskflag        ds             2
]eventptr        ds             4
]newstack        =              *-6                         ;must be at end of passed params
                 dend

                 mx             %00
                 tsc
                 sec
                 sbc            #]rtl
                 tcs
                 phd
                 inc
                 tcd
                 phb
                 phk
                 plb

                 psl            cmdhandle
                 _Hlock
                 jcs            :done
                 lda            cmdhandle
                 sta            ]ptr
                 lda            cmdhandle+2
                 sta            ]ptr+2
                 ldy            #$02
                 lda            []ptr]
                 tax
                 lda            []ptr],y
                 sta            ]ptr+2
                 stx            ]ptr
                 lda            numcmds
                 sta            ]ct
]lup             lda            ]ct
                 jeq            :done
                 ldy            #euserid
                 lda            []ptr],y
                 beq            :next
                 ldy            #etype
                 lda            []ptr],y
                 cmp            #$05                        ;application?
                 bne            :next
                 ldy            #eaddress
                 lda            []ptr],y
                 iny
                 iny
                 ora            []ptr],y
                 beq            :next
                 ldy            #emesstype
                 lda            #eventmess
                 sta            []ptr],y
                 ldy            #emesssub
                 lda            ]eventptr
                 sta            []ptr],y
                 iny
                 iny
                 lda            ]eventptr+2
                 ldx            ]taskflag
                 beq            :sta
                 ora            #$8000
:sta             sta            []ptr],y
                 ldy            #eaddress
                 lda            []ptr],y
                 sta            :jsl+1
                 iny
                 iny
                 lda            []ptr],y
                 sep            $20
                 sta            :jsl+3
                 rep            $30
                 ldy            #euserid
                 lda            []ptr],y
                 tax
                 ldy            #edp
                 lda            []ptr],y
                 phd
                 phb
                 tcd
                 txa
                 ldy            #0
                 tyx
:jsl             jsl            $FFFFFF
                 php
                 clc
                 xce
                 plp
                 rep            $30
                 plb
                 pld
                 php
                 ldy            #emesstype
                 lda            #0
                 sta            []ptr],y
                 plp
                 bcc            :done                       ;was event handled?
:next            dec            ]ct
                 lda            #erecsize
                 clc
                 adc            ]ptr
                 sta            ]ptr
                 jcc            ]lup
                 inc            ]ptr+2
                 brl            ]lup
:done            lda            #0
:xit             rep            $30
                 tax
                 lda            ]rtl+4
                 sta            ]newstack+4
                 lda            ]rtl+2
                 sta            ]newstack+2
                 lda            ]rtl
                 sta            ]newstack
                 plb
                 pld
                 tsc
                 clc
                 adc            #]newstack
                 tcs
                 txa
                 brl            errxit


getcmdptr
                 dum            0
]ct              ds             2
]rtl             ds             3                           ;these are passed on stack
]id              ds             2
]type            ds             2
]newstack        =              *-3                         ;must be at end of passed params
]ptr             ds             4
                 dend

                 mx             %00
                 tsc
                 sec
                 sbc            #]rtl
                 tcs
                 phd
                 inc
                 tcd
                 phb
                 phk
                 plb
                 stz            ]ptr
                 stz            ]ptr+2
                 psl            cmdhandle
                 _Hlock
                 bcs            :notfound
                 lda            cmdhandle
                 sta            ]ptr
                 lda            cmdhandle+2
                 sta            ]ptr+2
                 ldy            #$02
                 lda            []ptr]
                 tax
                 lda            []ptr],y
                 sta            ]ptr+2
                 stx            ]ptr
                 lda            numcmds
                 sta            ]ct
]lup             lda            ]ct
                 beq            :notfound
                 ldy            #eid
                 lda            []ptr],y
                 cmp            ]id
                 bne            :next
                 ldy            #etype
                 lda            []ptr],y
                 cmp            ]type
                 beq            :found
:next            dec            ]ct
                 lda            #erecsize
                 clc
                 adc            ]ptr
                 sta            ]ptr
                 bcc            ]lup
                 inc            ]ptr+2
                 bra            ]lup
:found           lda            #0
                 brl            :xit
:notfound        lda            #$01
:xit             rep            $30
                 tax
                 lda            ]rtl+1
                 sta            ]newstack+1
                 lda            ]rtl
                 sta            ]newstack
                 plb
                 pld
                 tsc
                 clc
                 adc            #]newstack
                 tcs
                 txa
                 brl            errxit

qadispose
                 dum            0
]ct              ds             2
]ptr             ds             4
]rtl             ds             6                           ;these are passed on stack
]newstack        =              *-6                         ;must be at end of passed params
                 dend

                 mx             %00
                 tsc
                 sec
                 sbc            #]rtl
                 tcs
                 phd
                 inc
                 tcd
                 phb
                 phk
                 plb
***
                 ldal           cmdhandle
                 oral           cmdhandle+2
                 jeq            :noerr
                 lda            cmdhandle+2
                 pha
                 lda            cmdhandle
                 pha
                 _Hlock
                 bcs            :xit
                 lda            cmdhandle
                 sta            ]ptr
                 lda            cmdhandle+2
                 sta            ]ptr+2
                 ldy            #$02
                 lda            []ptr]
                 tax
                 lda            []ptr],y
                 sta            ]ptr+2
                 stx            ]ptr
                 ldal           numcmds
                 sta            ]ct
]lup             lda            ]ct
                 beq            :noerr
                 ldy            #eflags                     ;clear the restart bit
                 lda            []ptr],y
                 and            #$7fff
                 sta            []ptr],y
                 lda            ]ptr
                 ldx            ]ptr+2
                 jsr            shutdownid
                 dec            ]ct
                 lda            ]ptr
                 clc
                 adc            #erecsize
                 sta            ]ptr
                 bcc            ]lup
                 inc            ]ptr+2
                 bra            ]lup
:noerr           rep            $30
                 lda            #0
:xit             rep            $30
                 tax
                 lda            ]rtl+4
                 sta            ]newstack+4
                 lda            ]rtl+2
                 sta            ]newstack+2
                 lda            ]rtl
                 sta            ]newstack
                 plb
                 pld
                 tsc
                 clc
                 adc            #]newstack
                 tcs
                 txa
                 brl            errxit

                 mx             %00
qaresetvectors
                 ldx            #vectend-vectortbl1-2
]lup             ldal           vectortbl1,x
                 stal           vectortbl,x
                 dex
                 dex                                        ;restore default vectors
                 bpl            ]lup
                 brl            noerror

qasetvector
                 lda            11,s
                 beq            :badid
                 cmp            #maxvectors+1
                 bge            :badid
                 dec
                 asl
                 asl
                 tax
                 lda            9,s
                 sep            $20
                 stal           vectortbl+3,x
                 rep            $20
                 lda            7,s
                 stal           vectortbl+1,x
                 lda            #0
                 brl            :xit
:badid           lda            #qabadvectornum
:xit             tax
                 lda            5,s
                 sta            5+6,s
                 lda            3,s
                 sta            3+6,s
                 lda            1,s
                 sta            1+6,s
                 pla
                 pla
                 pla
                 txa
                 cmp            #$01
                 rtl

qagetvector      rep            $30
                 lda            7,s
                 beq            :badid
                 cmp            #maxvectors+1
                 bge            :badid
                 dec
                 asl
                 asl
                 tax
                 ldal           vectortbl+1,x
                 sta            9,s
                 ldal           vectortbl+3,x
                 and            #$ff
                 sta            11,s
                 lda            #0
                 bra            :xit
:badid           lda            #qabadvectornum
:xit             tax
                 lda            5,s
                 sta            5+2,s
                 lda            3,s
                 sta            3+2,s
                 lda            1,s
                 sta            1+2,s
                 pla
                 txa
                 cmp            #$01
                 rtl

qashutdownid
                 dum            0
]ct              ds             2
]ptr             ds             4
]rtl             ds             6                           ;these are passed on stack
]userid          ds             2
]newstack        =              *-6                         ;must be at end of passed params
                 dend

                 mx             %00
                 tsc
                 sec
                 sbc            #]rtl
                 tcs
                 phd
                 inc
                 tcd
                 phb
                 phk
                 plb
***
                 ldal           cmdhandle
                 oral           cmdhandle+2
                 jeq            :noerr
                 lda            cmdhandle+2
                 pha
                 lda            cmdhandle
                 pha
                 _Hlock
                 bcs            :xit
                 lda            cmdhandle
                 sta            ]ptr
                 lda            cmdhandle+2
                 sta            ]ptr+2
                 ldy            #$02
                 lda            []ptr]
                 tax
                 lda            []ptr],y
                 sta            ]ptr+2
                 stx            ]ptr
                 ldal           numcmds
                 sta            ]ct
]lup             lda            ]ct
                 beq            :noerr

                 ldy            #euserid
                 lda            []ptr],y
                 cmp            ]userid
                 bne            :next
                 lda            ]ptr
                 ldx            ]ptr+2
                 jsr            shutdownid
:next            dec            ]ct
                 lda            ]ptr
                 clc
                 adc            #erecsize
                 sta            ]ptr
                 bcc            ]lup
                 inc            ]ptr+2
                 bra            ]lup
:noerr           rep            $30
                 lda            #0
:xit             rep            $30
                 tax
                 lda            ]rtl+4
                 sta            ]newstack+4
                 lda            ]rtl+2
                 sta            ]newstack+2
                 lda            ]rtl
                 sta            ]newstack
                 plb
                 pld
                 tsc
                 clc
                 adc            #]newstack
                 tcs
                 txa
                 brl            errxit


shutdownid       php                                        ;enters with recptr(low) in A
                 phd                                        ;            recptr(high) in X
                 rep            $30
                 pha
                 pha
                 tay
                 tsc
                 inc
                 tcd
                 sty            0
                 stx            2

                 ldy            #euserid
                 lda            [0],y
                 jeq            :done
                 ldy            #eaddress
                 lda            [0],y
                 iny
                 iny
                 ora            [0],y
                 jeq            :nomess

                 ldy            #etype
                 lda            [0],y
                 cmp            #$05
                 jne            :nomess                     ;pass shutdown only to APPS
                 ldy            #eflags
                 lda            [0],y
                 bit            #$4000
                 jeq            :nomess                     ;if already shutdown no message.

                 ldy            #emesstype
                 lda            #shutdownmess
                 sta            [0],y
                 ldy            #emesssub
                 lda            #0
                 sta            [0],y
                 iny
                 iny
                 sta            [0],y
                 ldy            #eaddress
                 lda            [0],y
                 sta            :jsl+1
                 iny
                 iny
                 lda            [0],y
                 sep            $20
                 sta            :jsl+3
                 rep            $30
                 ldy            #euserid
                 lda            [0],y
                 tax
                 ldy            #edp
                 lda            [0],y
                 phb
                 phd
                 tcd
                 txa
:jsl             jsl            $FFFFFF
                 clc
                 xce
                 rep            $30
                 pld
                 plb
:nomess          ldy            #edphandle
                 lda            [0],y
                 iny
                 iny
                 ora            [0],y
                 beq            :nodispose
                 ldy            #edphandle+2
                 lda            [0],y
                 pha
                 lda            #0
                 sta            [0],y
                 dey
                 dey
                 lda            [0],y
                 pha
                 lda            #0
                 sta            [0],y
                 _disposehandle
:nodispose       ldy            #euserid
                 ldx            #0
                 lda            [0],y
                 pha
                 pha
                 ldy            #eflags
                 lda            [0],y
                 and            #$8000                      ;get restart flag
                 beq            :tax
                 lda            #$4000
:tax             tax
:phx             phx
                 tll            $1211                       ;_UserShutdown
                 pla
:done            lda            #0
                 ldy            #eaddress
                 sta            [0],y
                 iny
                 iny
                 sta            [0],y
                 ldy            #eflags
                 lda            [0],y
                 bit            #$8000                      ;restartable?
                 bne            :dp
:id0             ldy            #euserid
                 lda            #0
                 sta            [0],y
:dp              ldy            #edp
                 lda            #0
                 sta            [0],y
                 ldy            #emesstype
                 sta            [0],y
                 ldy            #emesssub
                 sta            [0],y
                 iny
                 iny
                 sta            [0],y
                 ldy            #edp
                 sta            [0],y

                 ldy            #eflags
                 lda            [0],y
                 and            #$4000!$FFFF
                 sta            [0],y

                 pla
                 pla
                 pld
                 plp
                 rts

qatyp2txt

                 dum            0
]rtl             ds             3                           ;these are passed on stack
]rtl1            ds             3
]typestr         ds             4
]filetype        ds             2
]newstack        =              *-6                         ;must be at end of passed params
                 dend

                 mx             %00

                 tsc
                 sec
                 sbc            #]rtl
                 tcs
                 phd
                 inc
                 tcd
                 phb
                 phk
                 plb
                 lda            ]filetype
                 pha
                 asl
                 clc
                 adc            1,s
                 sta            1,s
                 plx
                 lda            filetypelist,x
                 and            #$ff
                 xba
                 ora            #$03
                 sta            []typestr]
                 ldy            #$02
                 lda            filetypelist+1,x
                 sta            []typestr],y
                 lda            #0
:xit             rep            $30
                 tax
                 lda            ]rtl+4
                 sta            ]newstack+4
                 lda            ]rtl+2
                 sta            ]newstack+2
                 lda            ]rtl
                 sta            ]newstack
                 plb
                 pld
                 tsc
                 clc
                 adc            #]newstack
                 tcs
                 txa
                 brl            errxit

qatxt2typ

                 dum            0
]rtl             ds             3                           ;these are passed on stack
]rtl1            ds             3
]typestr         ds             4
]newstack        =              *-6                         ;must be at end of passed params
]filetype        ds             2
                 dend

                 mx             %00

                 tsc
                 sec
                 sbc            #]rtl
                 tcs
                 phd
                 inc
                 tcd
                 phb
                 phk
                 plb
                 stz            ]filetype
                 sep            $20
                 lda            []typestr]
                 cmp            #$03
                 bne            :err1
                 ldx            #0
]lup             sep            $20
                 ldy            #$01
                 lda            []typestr],y
                 and            #$7f
                 cmp            #'a'
                 blt            :1
                 cmp            #'z'+1
                 bge            :1
                 and            #$5f
:1               cmp            filetypelist,x
                 bne            :next
                 iny
                 lda            []typestr],y
                 and            #$7f
                 cmp            #'a'
                 blt            :2
                 cmp            #'z'+1
                 bge            :2
                 and            #$5f
:2               cmp            filetypelist+1,x
                 bne            :next
                 iny
                 lda            []typestr],y
                 and            #$7f
                 cmp            #'a'
                 blt            :3
                 cmp            #'z'+1
                 bge            :3
                 and            #$5f
:3               cmp            filetypelist+2,x
                 beq            :found
:next            rep            $20
                 inc            ]filetype
                 txa
                 clc
                 adc            #$03
                 tax
                 cpx            #256*3
                 blt            ]lup
                 brl            :err1
:found           rep            $30
                 lda            #0
                 brl            :xit
:err1            rep            $30
                 lda            #qaunknowntypestr
:xit             rep            $30
                 tax
                 lda            ]rtl+4
                 sta            ]newstack+4
                 lda            ]rtl+2
                 sta            ]newstack+2
                 lda            ]rtl
                 sta            ]newstack
                 plb
                 pld
                 tsc
                 clc
                 adc            #]newstack
                 tcs
                 txa
                 brl            errxit



                 mx             %00
qastarttiming
                 ldal           timerlevel
                 cmp            #10
                 bge            :err
                 pha
                 pha
                 pha
                 pha
                 tll            $0d03                       ;_readtimehex
                 ldal           timerlevel
                 asl
                 asl
                 asl
                 tax
                 pla
                 tay
                 and            #$ff
                 stal           timetbl,x
                 tya
                 xba
                 and            #$ff
                 stal           timetbl+2,x
                 pla
                 and            #$ff
                 stal           timetbl+4,x
                 pla
                 pla
                 ldal           timerlevel
                 inc
                 stal           timerlevel
                 brl            noerror
:err             lda            #qatimeleverr
                 brl            errxit

qaendtiming      ldal           timerlevel
                 jeq            :zero
                 dec
                 stal           timerlevel
                 pha
                 pha
                 pha
                 pha
                 tll            $0d03                       ;_readtimehex
                 pla
                 tay
                 and            #$ff
                 stal           :secs
                 tya
                 xba
                 and            #$ff
                 stal           :mins
                 pla
                 and            #$ff
                 stal           :hours
                 pla
                 pla
                 ldal           timerlevel
                 asl
                 asl
                 asl
                 tax
                 phb
                 phk
                 plb
                 lda            :secs
                 sec
                 sbc            timetbl,x
                 bcs            :min
                 adc            #60
                 ldy            :mins
                 bne            :dmin
                 dec            :hours
                 bpl            :dmin1
                 ldy            #23
                 sty            :hours
:dmin1           ldy            #59
                 sty            :mins
                 brl            :min
:dmin            dey
                 sty            :mins
:min             sta            :secs
                 lda            :mins
                 sec
                 sbc            timetbl+2,x
                 bcs            :hour
                 adc            #60
                 dec            :hours
                 bpl            :hour
                 ldy            #23
                 sty            :hours
:hour            sta            :mins
                 lda            :hours
                 sec
                 sbc            timetbl+4,x
                 bcs            :show
                 adc            #24
:show            sta            :hours
                 plb
                 ldal           :secs
                 sta            11,s
                 ldal           :mins
                 sta            9,s
                 ldal           :hours
                 sta            7,s
                 brl            noerror
:zero            lda            #0
                 sta            7,s
                 sta            9,s
                 sta            11,s
                 brl            noerror
:hours           ds             2
:mins            ds             2
:secs            ds             2


qainctotalerrs
                 ldal           totalerrlev
                 tay
]lup             cpy            #0
                 beq            :done
                 dey
                 tya
                 asl
                 tax
                 ldal           errtbl,x
                 inc
                 stal           errtbl,x
                 brl            ]lup
:done            brl            noerror

qainittotalerrs
                 ldal           totalerrlev
                 cmp            #10
                 bge            :err
                 tay
                 asl
                 tax
                 lda            #0
                 stal           errtbl,x
                 tya
                 inc
                 stal           totalerrlev
                 brl            noerror
:err             lda            #qatotalerrleverr
                 brl            errxit

qagettotalerrs
                 ldal           totalerrlev
                 beq            :zero
                 dec
                 stal           totalerrlev
                 asl
                 tax
                 ldal           errtbl,x
                 sta            7,s
                 brl            noerror
:zero            lda            #0
                 sta            7,s
                 brl            noerror

qareadtotalerrs
                 ldal           totalerrlev
                 beq            :zero
                 dec
                 asl
                 tax
                 ldal           errtbl,x
                 sta            7,s
                 brl            noerror
:zero            lda            #0
                 sta            7,s
                 brl            noerror


qasetname
                 dum            0
]rtl             ds             6                           ;these are passed on stack
]pathptr         ds             4
]newstack        =              *-6                         ;must be at end of passed params
                 dend

                 mx             %00

                 tsc
                 sec
                 sbc            #]rtl
                 tcs
                 phd
                 inc
                 tcd
                 phb
                 phk
                 plb
                 sep            $30
                 lda            []pathptr]
                 cmp            #127
                 blt            :1
                 lda            #127
:1               tay
]lup             lda            []pathptr],y
                 cpy            #0
                 beq            :sta
                 and            #$7f
:sta             sta            filename,y
                 dey
                 cpy            #$ff
                 bne            ]lup
:xit             rep            $30
                 lda            ]rtl+4
                 sta            ]newstack+4
                 lda            ]rtl+2
                 sta            ]newstack+2
                 lda            ]rtl
                 sta            ]newstack
                 plb
                 pld
                 tsc
                 clc
                 adc            #]newstack
                 tcs
                 lda            #0
                 brl            errxit

qasetobjname
                 dum            0
]rtl             ds             6                           ;these are passed on stack
]pathptr         ds             4
]newstack        =              *-6                         ;must be at end of passed params
                 dend

                 mx             %00

                 tsc
                 sec
                 sbc            #]rtl
                 tcs
                 phd
                 inc
                 tcd
                 phb
                 phk
                 plb
                 sep            $30
                 lda            []pathptr]
                 cmp            #127
                 blt            :1
                 lda            #127
:1               tay
]lup             lda            []pathptr],y
                 cpy            #0
                 beq            :sta
                 and            #$7f
:sta             sta            objfilename,y
                 dey
                 cpy            #$ff
                 bne            ]lup
:xit             rep            $30
                 lda            ]rtl+4
                 sta            ]newstack+4
                 lda            ]rtl+2
                 sta            ]newstack+2
                 lda            ]rtl
                 sta            ]newstack
                 plb
                 pld
                 tsc
                 clc
                 adc            #]newstack
                 tcs
                 lda            #0
                 brl            errxit

qaconvertpath

                 dum            0
]rtl             ds             6                           ;these are passed on stack
]appendflag      ds             2
]newpath         ds             4
]oldpath         ds             4
]newstack        =              *-6                         ;must be at end of passed params
                 dend

                 mx             %00
                 tsc
                 sec
                 sbc            #]rtl
                 tcs
                 phd
                 inc
                 tcd
                 phb
                 phk
                 plb
                 lda            ]appendflag
                 and            #$FF
                 sta            ]appendflag
                 lda            #0
                 ldy            #$02
                 sta            []newpath]
                 sta            []newpath],y
                 sep            $30
                 ldy            #$01
]flush           lda            []oldpath],y
                 and            #$7f
                 cmp            #' '
                 blt            :bad
                 bne            :first
                 iny
                 brl            ]flush
:first           cmp            #'.'
                 jeq            :backup
                 brl            :ok
:bad             pea            #qabadpathname
                 brl            :error
:ok              ldx            #0
:return          sep            $30
:save            lda            []oldpath],y
                 and            #$7f
                 cmp            #' '+1
                 blt            :done
                 cmp            #'/'
                 bne            :store
                 lda            #':'
:store           cpx            #128
                 bge            :inx
                 phy
                 txy
                 iny
                 sta            []newpath],y
                 ply
:inx             inx
                 iny
                 brl            :save
:done            cpx            #64
                 blt            :len
                 ldx            #64
:len             txa
                 sta            []newpath]
                 lda            ]appendflag
                 beq            :plp
                 lda            []newpath]
                 cmp            #63
                 bge            :plp
                 tay
                 lda            []newpath],y
                 and            #$7f
                 cmp            #':'
                 beq            :plp
                 lda            []newpath]
                 inc
                 inc
                 sta            []newpath]
                 iny
                 lda            #'.'
                 sta            []newpath],y
                 iny
                 lda            ]appendflag
                 and            #$5f
                 sta            []newpath],y
:plp             sep            $30
                 lda            []newpath]
                 beq            :syn
                 rep            $30
                 lda            #0
                 brl            :xit
:syn             rep            $30
                 lda            #qabadpathname
                 brl            :xit
                 mx             %11

:backup          stz            :level
:loop            sty            :y
                 iny
                 lda            []oldpath],y
                 and            #$7f
                 cmp            #' '+1
                 blt            :pfx
                 cmp            #'.'
                 bne            :pfx
                 iny
                 lda            []oldpath],y
                 and            #$7f
                 cmp            #' '+1
                 blt            :pfx
                 cmp            #'/'
                 beq            :g
                 cmp            #':'
                 bne            :pfx
:g               inc            :level
                 iny
                 sty            :y
                 lda            []oldpath],y
                 and            #$7f
                 cmp            #'.'
                 beq            :loop
:pfx             ldx            #0
                 lda            :level
                 beq            :noexp
                 rep            $30
                 lda            #0
                 sta            []newpath]
                 lda            ]newpath+2
                 sta            :pfxparm+4
                 lda            ]newpath
                 sta            :pfxparm+2
                 _GSOS          _getprefix;:pfxparm
                 sep            $30
                 lda            []newpath]
                 tay
                 beq            :noexp
]lup             lda            []newpath],y
                 and            #$7f
                 cmp            #'/'
                 bne            :store1
                 lda            #':'
:store1          sta            []newpath],y
                 dey
                 bne            ]lup
                 lda            []newpath]
                 tay
                 lda            []newpath],y
                 cmp            #':'
                 bne            :exp
                 dey
:exp             cpy            #0
                 beq            :noexp
                 lda            []newpath],y
                 and            #$7f
                 cmp            #':'
                 bne            :dex
                 dec            :level
                 beq            :noexp
:dex             dey
                 brl            :exp
:noexp           tya
                 sta            []newpath]
                 tax
                 ldy            :y
                 brl            :return
:error           rep            $30
                 pla
:xit             rep            $30
                 tax
                 lda            ]rtl+4
                 sta            ]newstack+4
                 lda            ]rtl+2
                 sta            ]newstack+2
                 lda            ]rtl
                 sta            ]newstack
                 plb
                 pld
                 tsc
                 clc
                 adc            #]newstack
                 tcs
                 txa
                 brl            errxit

:temp            ds             2
:level           ds             2
:y               ds             2
:pfxparm         dw             0
                 adrl           0


qagetname
                 dum            0
]rtl             ds             6                           ;these are passed on stack
]pathptr         ds             4
]newstack        =              *-6                         ;must be at end of passed params
                 dend

                 mx             %00

                 tsc
                 sec
                 sbc            #]rtl
                 tcs
                 phd
                 inc
                 tcd
                 phb
                 phk
                 plb
                 sep            $30
                 lda            filename
                 cmp            #127
                 blt            :1
                 lda            #127
:1               tay
]lup             lda            filename,y
                 cpy            #0
                 beq            :sta
                 and            #$7f
:sta             sta            []pathptr],y
                 dey
                 cpy            #$ff
                 bne            ]lup
:xit             rep            $30
                 lda            ]rtl+4
                 sta            ]newstack+4
                 lda            ]rtl+2
                 sta            ]newstack+2
                 lda            ]rtl
                 sta            ]newstack
                 plb
                 pld
                 tsc
                 clc
                 adc            #]newstack
                 tcs
                 lda            #0
                 brl            errxit

qagetobjname
                 dum            0
]rtl             ds             6                           ;these are passed on stack
]pathptr         ds             4
]newstack        =              *-6                         ;must be at end of passed params
                 dend

                 mx             %00

                 tsc
                 sec
                 sbc            #]rtl
                 tcs
                 phd
                 inc
                 tcd
                 phb
                 phk
                 plb
                 sep            $30
                 lda            objfilename
                 cmp            #127
                 blt            :1
                 lda            #127
:1               tay
]lup             lda            objfilename,y
                 cpy            #0
                 beq            :sta
                 and            #$7f
:sta             sta            []pathptr],y
                 dey
                 cpy            #$ff
                 bne            ]lup
:xit             rep            $30
                 lda            ]rtl+4
                 sta            ]newstack+4
                 lda            ]rtl+2
                 sta            ]newstack+2
                 lda            ]rtl
                 sta            ]newstack
                 plb
                 pld
                 tsc
                 clc
                 adc            #]newstack
                 tcs
                 lda            #0
                 brl            errxit

                 mx             %00
qasetobjtype
                 lda            7,s
                 and            #$ff
                 stal           objfiletype
                 lda            5,s
                 sta            5+2,s
                 lda            3,s
                 sta            3+2,s
                 lda            1,s
                 sta            1+2,s
                 pla
                 brl            noerror
qagetobjtype
                 ldal           objfiletype
                 sta            7,s
                 brl            noerror

                 mx             %00
qasetwindow
                 lda            7,s
                 stal           windowflag
                 lda            5,s
                 sta            5+2,s
                 lda            3,s
                 sta            3+2,s
                 lda            1,s
                 sta            1+2,s
                 pla
                 brl            noerror
qagetwindow
                 ldal           windowflag
                 sta            7,s
                 brl            noerror
                 mx             %00
qasetshellid
                 lda            7,s
                 stal           shellUid
                 lda            5,s
                 sta            5+2,s
                 lda            3,s
                 sta            3+2,s
                 lda            1,s
                 sta            1+2,s
                 pla
                 brl            noerror
qagetshellid
                 ldal           shellUid
                 sta            7,s
                 brl            noerror

qagetsymtbl
                 dum            0
]rtl             ds             6                           ;these are passed on stack
]newstack        =              *-6                         ;must be at end of passed params
]nextptr         ds             4
]number          ds             2
]symhandle       ds             4
]symptr          ds             4
                 dend

                 mx             %00
                 tsc
                 sec
                 sbc            #]rtl
                 tcs
                 phd
                 inc
                 tcd
                 phb
                 phk
                 plb
                 lda            symnext
                 sta            ]nextptr
                 lda            symnext+2
                 sta            ]nextptr+2
                 lda            symhandle
                 sta            ]symhandle
                 lda            symhandle+2
                 sta            ]symhandle+2
                 lda            symptr
                 sta            ]symptr
                 lda            symptr+2
                 sta            ]symptr+2
                 lda            symlabels
                 sta            ]number
                 lda            #0
:xit             rep            $30
                 tax
                 lda            ]rtl+4
                 sta            ]newstack+4
                 lda            ]rtl+2
                 sta            ]newstack+2
                 lda            ]rtl
                 sta            ]newstack
                 plb
                 pld
                 tsc
                 clc
                 adc            #]newstack
                 tcs
                 txa
                 brl            errxit


qasetsymtbl
                 dum            0
]rtl             ds             6                           ;these are passed on stack
]nextptr         ds             4
]number          ds             2
]symhandle       ds             4
]symptr          ds             4
]newstack        =              *-6                         ;must be at end of passed params
                 dend

                 mx             %00
                 tsc
                 sec
                 sbc            #]rtl
                 tcs
                 phd
                 inc
                 tcd
                 phb
                 phk
                 plb
                 lda            ]nextptr
                 sta            symnext
                 lda            ]nextptr+2
                 sta            symnext+2
                 lda            ]symhandle
                 sta            symhandle
                 lda            ]symhandle+2
                 sta            symhandle+2
                 lda            ]symptr
                 sta            symptr
                 lda            ]symptr+2
                 sta            symptr+2
                 lda            ]number
                 sta            symlabels
                 lda            #0
:xit             rep            $30
                 tax
                 lda            ]rtl+4
                 sta            ]newstack+4
                 lda            ]rtl+2
                 sta            ]newstack+2
                 lda            ]rtl
                 sta            ]newstack
                 plb
                 pld
                 tsc
                 clc
                 adc            #]newstack
                 tcs
                 txa
                 brl            errxit

QABarGraph
                 dum            0
]rtl             ds             6                           ;these are passed on stack
]msgptr          ds             4
]percent         ds             4
]newstack        =              *-6                         ;must be at end of passed params
                 dend

                 mx             %00
                 tsc
                 sec
                 sbc            #]rtl
                 tcs
                 phd
                 inc
                 tcd
                 phb
                 phk
                 plb

                 lda            #0
:xit             rep            $30
                 tax
                 lda            ]rtl+4
                 sta            ]newstack+4
                 lda            ]rtl+2
                 sta            ]newstack+2
                 lda            ]rtl
                 sta            ]newstack
                 plb
                 pld
                 tsc
                 clc
                 adc            #]newstack
                 tcs
                 txa
                 brl            errxit


QAErrorMsg
                 dum            0
]rtl             ds             6                           ;these are passed on stack
]errorcode       ds             2
]newstack        =              *-6                         ;must be at end of passed params
                 dend

                 mx             %00
                 tsc
                 sec
                 sbc            #]rtl
                 tcs
                 phd
                 inc
                 tcd
                 phb
                 phk
                 plb
                 lda            windowflag
                 pha
                 lda            #-1
                 sta            windowflag
                 psl            #:str
                 _QADrawErrString
                 lda            ]errorcode
                 pha
                 _QAPrbytel
                 pea            #$0d
                 _QADrawErrChar
                 pla
                 sta            windowflag
:xit             rep            $30
                 tax
                 lda            ]rtl+4
                 sta            ]newstack+4
                 lda            ]rtl+2
                 sta            ]newstack+2
                 lda            ]rtl
                 sta            ]newstack
                 plb
                 pld
                 tsc
                 clc
                 adc            #]newstack
                 tcs
                 txa
                 brl            errxit
:str             str            'Unknown Error $'

*------------------------------------------------------
pchar
pechar           php
                 rep            $30
                 jsr            printchar
                 plp
                 clc
                 rtl

pstr
pestr            php
                 phd
                 rep            $30
                 phx
                 pha
                 tsc
                 inc
                 tcd
                 sep            $30
                 lda            [0]
                 beq            :xit
                 tax
                 ldy            #$01
]lup             lda            [0],y
                 phy
                 phx
                 jsr            printchar
                 plx
                 ply
                 iny
                 dex
                 bne            ]lup
:xit             rep            $30
                 pla
                 pla
                 pld
                 plp
                 clc
                 rtl

pestrl
pstrl            php
                 phd
                 rep            $30
                 phx
                 pha
                 tsc
                 inc
                 tcd

                 lda            [0]
                 beq            :xit
                 tax
                 ldy            #$02
                 sep            $20
]lup             lda            [0],y
                 phy
                 phx
                 jsr            printchar
                 plx
                 ply
                 iny
                 dex
                 bne            ]lup
:xit             rep            $30
                 pla
                 pla
                 pld
                 plp
                 clc
                 rtl

pblk
peblk            php
                 phd
                 rep            $30
                 phx
                 pha
                 tsc
                 inc
                 tcd
                 sep            $20
                 ldy            #0
]lup             lda            [0],y
                 beq            :xit
                 phy
                 jsr            printchar
                 ply
                 iny
                 bne            ]lup
:xit             rep            $30
                 pla
                 pla
                 pld
                 plp
                 clc
                 rtl

*------------------------------------------------------
putop
putbyte
eval
relcorrect
rtl              clc
                 rtl

mytabtocol       sep            $20
                 cmpl           winwidth
                 blt            :ok
                 pha
                 jsl            DrawCR                      ;past edge, do a CR
                 pla
                 sec
                 sbcl           winwidth
:ok              cmpl           cursx
                 blt            :space
                 beq            :space
                 stal           cursx
                 rep            $30
                 lda            #0
                 clc
                 rtl

:space           rep            $30
                 brl            DrawSpace                   ;tab over a single space

*======================================================
* Routines to read the keyboard in a quick/fast manner.

mygetchar
                 ~GetNextEvent  #%101000;#tpfx
                 pla
                 beq            mygetchar                   ;wait for a keypress
                 lda            #0
                 stal           keypress                    ;show no keypress waiting
                 sep            $20
                 ldal           #$E0C025                    ;place modifiers in hi byte
                 xba
                 ldal           tpfx+2                      ; & ASCII in lo
                 ora            #$80
                 rep            $20
                 clc
                 rtl

*------------------------------------------------------
* Clear keypress flag, coulda been set earlier!

QAClearKey
                 lda            #0                          ;simple!
                 stal           keypress
                 brl            noerror

*------------------------------------------------------
* Allows QUICK checking to see if a key event occured

myKeyAvail
                 ldal           keypress                    ;all there is to it!
                 clc
                 rtl

*------------------------------------------------------
* Setup the Event Manager so we get to see keypresses
* as they happen, for quick and easy _KeyAvail checks.

InitASK
                 ~GetVector     #$F                         ;get the current keypress vector
                 pla
                 sta            amod+1
                 sta            EMKeyVect
                 pla
                 sta            EMKeyVect+2
                 SEP            #$20
                 sta            amod+3
                 REP            #$20
                 ~SetVector     #$F;#ASyncKey               ;point to our vector
                 rts

ASyncKey
                 ldal           $E0C025                     ;get modifiers
                 xba
                 ldal           $E0C000                     ; & combine into standard mod/ascii word
                 REP            #$20
                 stal           keypress                    ;save for later test
                 SEP            #$20
amod             jml            $E10000                     ; & continue w/keypress handling

*======================================================
* The PRINTCHAR control code handlers

formfeed         php
                 rep            $30
                 jsr            clearwindow
                 bra            h1
home             php
                 rep            $30
h1               lda            wintop
                 sta            cursy
                 lda            winleft
                 sta            cursx
                 jsr            setcurs
                 plp
                 rts

gotoxy           php
                 sep            $30
                 lda            #$01
                 tsb            charflag
                 plp
                 rts

tab2             php
                 sep            $30
                 lda            #%100
                 tsb            charflag
                 plp
                 rts

clreoln          php
                 sep            $30
                 lda            cursx
                 tax
                 clc
                 adc            winleft
                 tay
]lup             cpx            winwidth
                 bge            :done
                 phy
                 phx
                 lda            #$a0
                 jsr            storchar
                 plx
                 ply
                 iny
                 inx
                 bra            ]lup
:done            plp
                 rts

clrline          php
                 sep            $30
                 lda            #0
                 tax
                 clc
                 adc            winleft
                 tay
]lup             cpx            winwidth
                 bge            :done
                 phy
                 phx
                 lda            #$a0
                 jsr            storchar
                 plx
                 ply
                 iny
                 inx
                 bra            ]lup
:done            plp
                 rts


printmult        php
                 sep            $30
                 lda            #$80
                 tsb            charflag+1
                 lda            #%0110_0000
                 trb            charflag+1
                 plp
                 rts

clreos           rts

savexy           php
                 sep            $30
                 lda            cursx
                 sta            xtemp
                 lda            cursy
                 sta            ytemp
                 plp
                 rts

savex            php
                 sep            $30
                 lda            cursx
                 sta            xtemp
                 plp
                 rts

savey            php
                 sep            $30
                 lda            cursy
                 sta            ytemp
                 plp
                 rts

restorexy        php
                 sep            $30
                 lda            xtemp
                 sta            cursx
                 lda            ytemp
                 sta            cursy
                 jsr            setcurs
                 plp
                 rts

restorex         php
                 sep            $30
                 lda            xtemp
                 sta            cursx
                 jsr            setcurs
                 plp
                 rts

restorey         php
                 sep            $30
                 lda            ytemp
                 sta            cursy
                 jsr            setcurs
                 plp
                 rts


linefeed         php
                 rep            $30
                 lda            outflag
                 bit            #$80                        ;cr out?
                 beq            :lf
                 stz            outflag
                 plp
                 rts
:lf              inc            cursy
                 lda            cursy
                 cmp            winbot
                 blt            :update
                 beq            :update
                 jsr            scrollup
                 lda            winbot
                 sta            cursy
:update          rep            $30
                 and            #$7f
                 asl
                 tay
                 lda            table,y
                 sta            basl
                 plp
                 rts

textcr           php
                 rep            $30
                 stz            cursx
                 lda            outflag
                 bit            #$40                        ;has a LF been sent?
                 beq            :lf
                 stz            outflag
                 plp
                 rts

:lf              inc            cursy
                 lda            cursy
                 cmp            winbot
                 blt            :update
                 beq            :update
                 jsr            scrollup
                 lda            winbot
                 sta            cursy
:update          rep            $30
                 and            #$7f
                 asl
                 tay
                 lda            table,y
                 sta            basl
                 plp
                 rts

nil              rts

inverse          php
                 sep            $30
                 lda            #$80
                 trb            charflag
                 plp
                 rts
normal           php
                 sep            $30
                 lda            #$80
                 tsb            charflag
                 plp
                 rts
mouseon          php
                 sep            $30
                 lda            #$40
                 tsb            charflag
                 plp
                 rts
mouseoff         php
                 sep            $30
                 lda            #$40
                 trb            charflag
                 plp
                 rts


setcurs          php
                 rep            $30
                 lda            cursy
                 cmp            winbot
                 blt            :ok
                 lda            winbot
                 sta            cursy
:ok              asl
                 tay
                 lda            table,y
                 sta            basl
                 lda            cursx
                 clc
                 adc            winleft
                 cmp            winwidth
                 blt            :rts
                 beq            :rts
                 lda            cursx
                 clc
                 adc            winwidth
                 cmp            #80
                 blt            :s
                 lda            #80-1
:s               sta            cursx
:rts             plp
                 rts

ttinitscreen     php
                 rep            $30
                 pha
                 pha
                 tll            $0e0c                       ;_GetErrGlobals
                 pla
                 sta            errormask
                 pla
                 sta            errandmask
                 pha
                 pha
                 tll            $0C0C                       ;_GetInGlobals
                 pla
                 sta            inormask
                 pla
                 sta            inandmask
                 pha
                 pha
                 tll            $0D0C                       ;_GetOutGlobals
                 pla
                 sta            outormask
                 pla
                 sta            outandmask

                 pea            0
                 psl            #0
                 tll            $140C                       ;_GetErrorDevice
                 pll            errdevslot
                 pla
                 sta            errdevtype

                 pea            0
                 psl            #0
                 tll            $120C                       ;_GetInputDevice
                 pll            indevslot
                 pla
                 sta            indevtype

                 pea            0
                 psl            #0
                 tll            $130C                       ;_GetErrorDevice
                 pll            outdevslot
                 pla
                 sta            outdevtype

                 pea            2                           ;RAM Based
                 psl            #TTErrDevice
                 tll            $110C
                 pea            #$FF
                 pea            #$80
                 tll            $0B0C

                 pea            2                           ;RAM Based
                 psl            #TTDevice
                 tll            $0F0C
                 pea            #$FF
                 pea            #$80
                 tll            $090C

                 pea            2                           ;RAM Based
                 psl            #TTDevice
                 tll            $100C
                 pea            #$FF
                 pea            #$80
                 tll            $0A0C

                 jsr            ttinitvars
                 jsr            setcurs
                 jsr            clearwindow
                 plp
                 rts

ttshutdown       php
                 rep            $30
                 lda            indevtype
                 pha
                 psl            indevslot
                 tll            $0F0C
                 lda            inandmask
                 pha
                 lda            inormask
                 pha
                 tll            $090C

                 lda            outdevtype
                 pha
                 psl            outdevslot
                 tll            $100C
                 lda            outandmask
                 pha
                 lda            outormask
                 pha
                 tll            $0A0C

                 lda            errdevtype
                 pha
                 psl            errdevslot
                 tll            $110C
                 lda            errandmask
                 pha
                 lda            errormask
                 pha
                 tll            $0B0C
                 plp
                 rts

*======================================================
                 put            qatools.1
*======================================================

filetypelist
                 ASC            'NON'
                 ASC            'BAD'
                 ASC            '$02'
                 ASC            '$03'
                 ASC            'TXT'
                 ASC            '$05'
                 ASC            'BIN'
                 ASC            '$07'
                 ASC            '$08'
                 ASC            '$09'
                 ASC            '$0A'
                 ASC            '$0B'
                 ASC            '$0C'
                 ASC            '$0D'
                 ASC            '$0E'
                 ASC            'DIR'
                 ASC            '$10'
                 ASC            '$11'
                 ASC            '$12'
                 ASC            '$13'
                 ASC            '$14'
                 ASC            '$15'
                 ASC            'PFS'
                 ASC            '$17'
                 ASC            '$18'
                 ASC            'ADB'
                 ASC            'AWP'
                 ASC            'ASP'
                 ASC            '$1C'
                 ASC            '$1D'
                 ASC            '$1E'
                 ASC            '$1F'
                 ASC            '$20'
                 ASC            '$21'
                 ASC            '$22'
                 ASC            '$23'
                 ASC            '$24'
                 ASC            '$25'
                 ASC            '$26'
                 ASC            '$27'
                 ASC            '$28'
                 ASC            '$29'
                 ASC            '$2A'
                 ASC            '$2B'
                 ASC            '$2C'
                 ASC            '$2D'
                 ASC            '$2E'
                 ASC            '$2F'
                 ASC            '$30'
                 ASC            '$31'
                 ASC            '$32'
                 ASC            '$33'
                 ASC            '$34'
                 ASC            '$35'
                 ASC            '$36'
                 ASC            '$37'
                 ASC            '$38'
                 ASC            '$39'
                 ASC            '$3A'
                 ASC            '$3B'
                 ASC            '$3C'
                 ASC            '$3D'
                 ASC            '$3E'
                 ASC            '$3F'
                 ASC            '$40'
                 ASC            '$41'
                 ASC            '$42'
                 ASC            '$43'
                 ASC            '$44'
                 ASC            '$45'
                 ASC            '$46'
                 ASC            '$47'
                 ASC            '$48'
                 ASC            '$49'
                 ASC            '$4A'
                 ASC            '$4B'
                 ASC            '$4C'
                 ASC            '$4D'
                 ASC            '$4E'
                 ASC            '$4F'
                 ASC            '$50'
                 ASC            '$51'
                 ASC            '$52'
                 ASC            '$53'
                 ASC            '$54'
                 ASC            '$55'
                 ASC            '$56'
                 ASC            '$57'
                 ASC            '$58'
                 ASC            '$59'
                 ASC            '$5A'
                 ASC            '$5B'
                 ASC            '$5C'
                 ASC            '$5D'
                 ASC            '$5E'
                 ASC            '$5F'
                 ASC            '$60'
                 ASC            '$61'
                 ASC            '$62'
                 ASC            '$63'
                 ASC            '$64'
                 ASC            '$65'
                 ASC            '$66'
                 ASC            '$67'
                 ASC            '$68'
                 ASC            '$69'
                 ASC            '$6A'
                 ASC            '$6B'
                 ASC            '$6C'
                 ASC            '$6D'
                 ASC            '$6E'
                 ASC            '$6F'
                 ASC            '$70'
                 ASC            '$71'
                 ASC            '$72'
                 ASC            '$73'
                 ASC            '$74'
                 ASC            '$75'
                 ASC            '$76'
                 ASC            '$77'
                 ASC            '$78'
                 ASC            '$79'
                 ASC            '$7A'
                 ASC            '$7B'
                 ASC            '$7C'
                 ASC            '$7D'
                 ASC            '$7E'
                 ASC            '$7F'
                 ASC            '$80'
                 ASC            '$81'
                 ASC            '$82'
                 ASC            '$83'
                 ASC            '$84'
                 ASC            '$85'
                 ASC            '$86'
                 ASC            '$87'
                 ASC            '$88'
                 ASC            '$89'
                 ASC            '$8A'
                 ASC            '$8B'
                 ASC            '$8C'
                 ASC            '$8D'
                 ASC            '$8E'
                 ASC            '$8F'
                 ASC            '$90'
                 ASC            '$91'
                 ASC            '$92'
                 ASC            '$93'
                 ASC            '$94'
                 ASC            '$95'
                 ASC            '$96'
                 ASC            '$97'
                 ASC            '$98'
                 ASC            '$99'
                 ASC            '$9A'
                 ASC            '$9B'
                 ASC            '$9C'
                 ASC            '$9D'
                 ASC            '$9E'
                 ASC            '$9F'
                 ASC            '$A0'
                 ASC            '$A1'
                 ASC            '$A2'
                 ASC            '$A3'
                 ASC            '$A4'
                 ASC            '$A5'
                 ASC            '$A6'
                 ASC            '$A7'
                 ASC            '$A8'
                 ASC            '$A9'
                 ASC            '$AA'
                 ASC            'BAS'
                 ASC            'TDF'
                 ASC            'DAT'
                 ASC            '$AE'
                 ASC            '$AF'
                 ASC            'SRC'
                 ASC            'OBJ'
                 ASC            'LIB'
                 ASC            'S16'
                 ASC            'RTL'
                 ASC            'EXE'
                 ASC            'PIF'
                 ASC            'TIF'
                 ASC            'NDA'
                 ASC            'CDA'
                 ASC            'TOL'
                 ASC            'DRV'
                 ASC            '$BC'
                 ASC            'FST'
                 ASC            '$BE'
                 ASC            'DOC'
                 ASC            'PNT'
                 ASC            'PIC'
                 ASC            '$C2'
                 ASC            '$C3'
                 ASC            '$C4'
                 ASC            '$C5'
                 ASC            '$C6'
                 ASC            '$C7'
                 ASC            'FON'
                 ASC            'FND'
                 ASC            'ICN'
                 ASC            '$CB'
                 ASC            '$CC'
                 ASC            '$CD'
                 ASC            '$CE'
                 ASC            '$CF'
                 ASC            '$D0'
                 ASC            '$D1'
                 ASC            '$D2'
                 ASC            '$D3'
                 ASC            '$D4'
                 ASC            '$D5'
                 ASC            '$D6'
                 ASC            '$D7'
                 ASC            '$D8'
                 ASC            '$D9'
                 ASC            '$DA'
                 ASC            '$DB'
                 ASC            '$DC'
                 ASC            '$DD'
                 ASC            '$DE'
                 ASC            '$DF'
                 ASC            'TEL'
                 ASC            '$E1'
                 ASC            'ATK'
                 ASC            '$E3'
                 ASC            '$E4'
                 ASC            '$E5'
                 ASC            '$E6'
                 ASC            '$E7'
                 ASC            '$E8'
                 ASC            '$E9'
                 ASC            '$EA'
                 ASC            '$EB'
                 ASC            '$EC'
                 ASC            '$ED'
                 ASC            '$EE'
                 ASC            'PAS'
                 ASC            '$F0'
                 ASC            '$F1'
                 ASC            '$F2'
                 ASC            '$F3'
                 ASC            '$F4'
                 ASC            '$F5'
                 ASC            '$F6'
                 ASC            '$F7'
                 ASC            'LNK'
                 ASC            'DOS'
                 ASC            'INT'
                 ASC            'IVR'
                 ASC            'BAS'
                 ASC            'VAR'
                 ASC            'REL'
                 ASC            'SYS'

*------------------------------------------------------
* Stuff for the end of the code segment--no disk space!

qasmstr          asc            'MERLINGS'

DS_Start
                 dum            *                           ;allocated by loader

cmdline          ds             256
cmdhandle        ds             4                           ;handle to command table
cmdtbl           ds             4                           ;ptr to the internal cmd table
userid           ds             2                           ;our userid
initid           ds             2                           ;id that started us
started          ds             2                           ;<>0 if currently started up
modeflags        ds             4                           ;b15 = text (0), graphics (1)
                                                            ;b14 = Event Manager Active
numcmds          ds             2
compiler         ds             2
linker           ds             2
linkactive       ds             2
compileactive    ds             2
windowflag       ds             2

** application variables

shellUid         ds             2
quitflag         ds             2
cancelflag       ds             2
totalerrlev      ds             2
timerlevel       ds             2
parmhandle       ds             4                           ;handle to system preferences

xtemp            ds             2
ytemp            ds             2

filename         ds             130
objfilename      ds             130
objfiletype      ds             2
cmdstr           ds             256
errtbl           ds             20
timetbl          ds             10*8
symhandle        ds             4
symnext          ds             4
symptr           ds             4
symlabels        ds             2

inandmask        ds             2
inormask         ds             2
indevtype        ds             2
indevslot        ds             4
outandmask       ds             2
outormask        ds             2
outdevtype       ds             2
outdevslot       ds             4
errandmask       ds             2
errormask        ds             2
errdevtype       ds             2
errdevslot       ds             4

charflag         ds             2                           ;b7 = normal text enable
cursx            ds             2
cursy            ds             2
basl             ds             2
wintop           ds             2
winbot           ds             2
winleft          ds             2
winwidth         ds             2
fullwindow       ds             2                           ;neg if window not set to 80x24

launchflags      ds             2
launchpath       ds             256

stack            ds             2
return           ds             2

p16y             ds             2

outflag          ds             2
startx           ds             2
startpos         ds             2
curpos           ds             2
tempbuff         ds             256

hdstr            ds             declen+1
hdfinalstr       ds             declen+2

EMKeyVect        ds             4
keypress         ds             2
VCount           ds             2
BlinkRate        ds             2

wcstring         ds             16
wcftype          ds             2
wcftypemask      ds             2
wcaux            ds             4
wcauxmask        ds             4

dhandles         ds             maxlevels*8

spfx             ds             2
                 ds             2
pptr             ds             4

tpfx             ds             258

emactive         dw             0
keyintsactive    ds             2
keyaddress       ds             2

DS_Size          =              *-CmdLine
                 ENT            DS_Size
                 dend

                 typ            tol

                 lst            off
                 sav            2/obj/qatools.l

