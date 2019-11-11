_QABootInit        mac                     ;_QABootInit()
                   utool  $01
                   <<<
~QAStartup         MAC
                   psw    ]1
                   psl    ]2
_QAStartup         mac                     ;_QAStartup(userid,modeflags/4)
                   utool  $02
                   <<<
_QAShutdown        mac                     ;_QAShutdown()
                   utool  $03
                   <<<
~QAVersion         MAC
                   pha
_QAVersion         mac                     ;_QAVersion():versionnum
                   utool  $04
                   <<<
_QAReset           mac                     ;_QAReset()
                   utool  $05
                   <<<
~QAStatus          MAC
                   pha
_QAStatus          mac                     ;_QAStatus():statflag
                   utool  $06
                   <<<
~QADrawChar        MAC
                   phw    ]1
_QADrawChar        mac                     ;_QADrawChar(char)
                   utool  $09
                   <<<
~QADrawString      MAC
~QADrawStr         MAC
                   psl    ]1
_QADrawString      mac                     ;_QADrawString(@strptr)
_QADrawStr         mac
                   utool  $0A
                   <<<
~QAPrByte          MAC
                   psw    ]1
_QAPrByte          mac                     ;_QAPrByte(byteval)
                   utool  $0B
                   <<<
~QAPrByteL         MAC
                   psw    ]1
_QAPrByteL         mac                     ;_QAPrByteL(hexval)
                   utool  $0C
                   <<<
~QADrawDec         MAC
                   psl    ]1
                   psw    ]2
                   ps2    ]3
_QADrawDec         mac                     ;_QADrawDec(longint/4,flags,fieldsize)
                   utool  $0D
                   <<<
~QAKeyAvail        MAC
                   pha
_QAKeyAvail        mac                     ;_QAKeyAvail():availflag
                   utool  $0E
                   <<<
~QAGetChar         MAC
                   pha
_QAGetChar         mac                     ;_QAGetChar():char (char in low/modifiers in high)
                   utool  $0F
                   <<<
_QAGetLine         mac                     ;_QAGetLine(@linestr)
                   utool  $10
                   <<<
~QASetParmHdl      MAC
                   psl    ]1
_QASetParmHdl      mac                     ;_QASetParmHdl(parmhandle)
                   utool  $11
                   <<<
~QAGetParmHdl      MAC
                   pha
                   pha
_QAGetParmHdl      mac                     ;_QAGetParmHdl():parmhandle
                   utool  $12
                   <<<
~QASetCmdHdl       MAC
                   psl    ]1
                   psw    ]2
_QASetCmdHdl       mac                     ;_QASetCmdHdl(commandhandle,numcmds)
                   utool  $13
                   <<<
~QAGetCmdHdl       MAC
                   pha
                   pha
                   pha
_QAGetCmdHdl       mac                     ;_QAGetCmdHdl():commandhandle,numcmds
                   utool  $14
                   <<<
~QAReadTotalErrs   MAC
                   pha
_QAReadTotalErrs   mac                     ;_QAReadTotalErrs():totalerrs
                   utool  $15
                   <<<
~QAGetModeFlags    MAC
                   pha
                   pha
_QAGetModeFlags    mac                     ;_QAGetModeFlags():modeflags/4
                   utool  $16
                   <<<
~QASetModeFlags    MAC
                   psl    ]1
_QASetModeFlags    mac                     ;_QASetModeFlags(modeflags/4)
                   utool  $17
                   <<<
_QALoadFile        mac                     ;_QALoadfile(@filename,filepos/4,length/4,@typelist,userid,address/4,memattrib):filehandle/4
                   utool  $18
                   <<<
_QASaveFile        mac                     ;_QASavefile(filehandle/4,@filename,filetype,auxtype/4)
                   utool  $19
                   <<<
~QASetCmdLine      MAC
                   psl    ]1
_QASetCmdLine      mac                     ;_QASetCmdLine(@strptr)
                   utool  $1A
                   <<<
~QAGetCmdLine      MAC
                   psl    ]1
                   psw    ]2
_QAGetCmdLine      mac                     ;_QAGetCmdLine(@strptr,maxlen)
                   utool  $1B
                   <<<
~QAParseCmdLine    MAC
                   pha
                   pha
                   psl    ]1
_QAParseCmdLine    mac                     ;_QAParseCmdLine(@strptr):cmdid,cmdtype
                   utool  $1C
                   <<<
~QAGetQuitFlag     MAC
                   pha
_QAGetQuitFlag     mac                     ;_QAGetQuitFlag():quitflag
                   utool  $1D
                   <<<
~QASetQuitFlag     MAC
                   psw    ]1
_QASetQuitFlag     mac                     ;_QASetQuitFlag(quitflag)
                   utool  $1E
                   <<<
~QASetCmdTbl       MAC
                   psl    ]1
_QASetCmdTbl       mac                     ;_QASetCmdTbl(@cmdtbl)
                   utool  $1F
                   <<<
~QAGetCmdTbl       MAC
                   pha
                   pha
_QAGetCmdTbl       mac                     ;_QAGetCmdTbl():@cmdtbl
                   utool  $20
                   <<<
~QAExecCommand     MAC
                   psw    ]1
                   psw    ]2
_QAExecCommand     mac                     ;_QAExecCommand(cmdtype,cmdid)
                   utool  $21
                   <<<
~QAGetMessagebyID  MAC
                   pha
                   pha
                   pha
                   psw    ]1
_QAGetMessagebyID  mac                     ;_QAGetMessagebyID(userid):message,subtype/4
                   utool  $22
                   <<<
_QARun             mac                     ;_QARun()
                   utool  $23
                   <<<
_QADispose         mac                     ;_QADispose()
                   utool  $24
                   <<<
~QAShutdownID      MAC
                   psw    ]1
_QAShutdownID      mac                     ;_QAShutDownID(userid)
                   utool  $25
                   <<<
~QACompile         MAC
                   psw    ]1
                   psl    ]2
_QACompile         mac                     ;_QACompile(message,subtype/4)
                   utool  $26
                   <<<
~QALink            MAC
                   psw    ]1
                   psl    ]2
_QALink            mac                     ;_QALink(message,subtype/4)
                   utool  $27
                   <<<
~QACompilerActive  MAC
                   pha
_QACompilerActive  mac                     ;_QAComplierActive():activeflag
                   utool  $28
                   <<<
~QALinkerActive    MAC
                   pha
_QALinkerActive    mac                     ;_QALinkerActvie():activeflag
                   utool  $29
                   <<<
~QAGetCompileID    MAC
                   pha
_QAGetCompileID    mac                     ;_QAGetCompileID():compileID
                   utool  $2A
                   <<<
~QASetCompileID    MAC
                   psw    ]1
_QASetCompileID    mac                     ;_QASetCompileID(compileID)
                   utool  $2B
                   <<<
~QAGetLinkID       MAC
                   pha
_QAGetLinkID       mac                     ;_QAGetLinkID():linkID
                   utool  $2C
                   <<<
~QASetLinkID       MAC
                   psw    ]1
_QASetLinkID       mac                     ;_QASetLinkID(linkID)
                   utool  $2D
                   <<<
~QAGetVector       MAC
                   pha
                   pha
                   psw    ]1
_QAGetVector       mac                     ;_QAGetVector(vect#):@address
                   utool  $2E
                   <<<
~QASetVector       MAC
                   psw    ]1
                   psl    ]2
_QASetVector       mac                     ;_QASetVector(vect#,@address)
                   utool  $2F
                   <<<
_QAResetVectors    mac                     ;_QAResetVectors()
                   utool  $30
                   <<<
~QAEvent           MAC
                   psl    ]1
                   psw    ]2
_QAEvent           mac                     ;_QAEvent(@eventptr,taskflag)
                   utool  $31
                   <<<
~QAGetCmdRecSize   MAC
                   pha
_QAGetCmdRecSize   mac                     ;_QAGetCmdRecSize():recordsize
                   utool  $32
                   <<<
~QATabtoCol        MAC
                   psw    ]1
_QATabtoCol        mac                     ;_QATabtoCol(columnnum)
                   utool  $33
                   <<<
~QAErrorMsg        MAC
                   psw    ]1
_QAErrorMsg        mac                     ;_QAErrorMsg(ErrorCode)
                   utool  $34
                   <<<
~QABarGraph        MAC
                   psw    ]1
                   psl    ]2
_QABarGraph        mac                     ;_QABarGraph(percent,@Message)
                   utool  $35
                   <<<
~QAConvertPath     MAC
                   psl    ]1
                   psl    ]2
_QAConvertPath     mac                     ;_QAConvertPath(@oldpath,@newpath)
                   utool  $36
                   <<<
~QATyp2Txt         MAC
                   psw    ]1
                   psl    ]2
_QATyp2Txt         mac
_QAConvertTyp2Txt  mac                     ;_QAConvertTyp2Txt(filetype,@typestr)
                   utool  $37
                   <<<
~QATxt2Typ         MAC
                   pha
                   psl    ]1
_QATxt2Typ         mac
_QAConvertTxt2Typ  mac                     ;_QAConvertTxt2Typ(@typestr):type
                   utool  $38
                   <<<
~QAReadDir         MAC
                   psl    ]1
                   psl    ]2
                   psw    ]3
_QAReadDir         mac                     ;_QAReadDir(@pathname,@doroutine,flags)
                   utool  $39
                   <<<
~QAInitWildcard    MAC
                   psl    ]1
                   psw    ]2
                   psl    ]3
                   psw    ]4
                   psl    ]5
_QAInitWildcard    mac                     ;_QAInitWildcard(@wcstr,ft,aux/4,ftmask,auxmask/4)
                   utool  $3A
                   <<<
_QAUndefined       mac                     ;_QAUndefined()
                   utool  $3B
                   <<<
_QAInitTotalErrs   mac                     ;_QAInitTotalErrs()
                   utool  $3C
                   <<<
_QAIncTotalErrs    mac                     ;_QAIncTotalErrs()
                   utool  $3D
                   <<<
~QAGetTotalErrs    MAC
                   pha
_QAGetTotalErrs    mac                     ;_QAGetTotalErrs():totalerrs
                   utool  $3E
                   <<<
~QAGetCancelFlag   MAC
                   pha
_QAGetCancelFlag   mac                     ;_QAGetCancelFlag():cancelflag
                   utool  $3F
                   <<<
~QASetCancelFlag   MAC
                   psw    ]1
_QASetCancelFlag   mac                     ;_QASetCancelFlag(cancelflag)
                   utool  $40
                   <<<
_QAStartTiming     mac                     ;_QAStartTiming()
                   utool  $41
                   <<<
~QAEndTiming       MAC
                   pha
                   pha
                   pha
_QAEndTiming       mac                     ;_QAEndTiming():hours,minutes,seconds
                   utool  $42
                   <<<
~QAGetSymTable     MAC
                   pha
                   pha
                   pha
                   pha
                   pha
_QAGetSymTable     mac                     ;_QAGetSymTable():@table,symhandle/4,numlabels
                   utool  $43
                   <<<
~QASetSymTable     MAC
                   psl    ]1
                   psl    ]2
                   psw    ]3
_QASetSymTable     mac                     ;_QASetSymTable(@table,symhandle/4,numlabels)
                   utool  $44
                   <<<
~QASetPath         MAC
                   psl    ]1
_QASetPath         mac                     ;_QASetPath(@pathname)
                   utool  $45
                   <<<
~QAGetPath         MAC
                   psl    ]1
_QAGetPath         mac                     ;_QAGetPath(@pathname)
                   utool  $46
                   <<<
~QAGetObjType      MAC
                   pha
_QAGetObjType      mac                     ;_QAGetObjType():type
                   utool  $47
                   <<<
~QASetObjType      MAC
                   psw    ]1
_QASetObjType      mac                     ;_QASetObjType(type)
                   utool  $48
                   <<<
~QAGetObjPath      MAC
                   psl    ]1
_QAGetObjPath      mac                     ;_QAGetObjPath(@pathname)
                   utool  $49
                   <<<
~QASetObjPath      MAC
                   psl    ]1
_QASetObjPath      mac                     ;_QASetObjPath(@pathname)
                   utool  $4A
                   <<<
~QACallUSR         MAC
                   pha
                   psw    ]1
                   psl    ]2
_QACallUSR         mac                     ;_QACallUSR(opcode,@operand):handled
                   utool  $4B
                   <<<
~QACallUser        MAC
                   psw    ]1
                   psw    ]2
                   psl    ]3
                   psl    ]4
_QACallUser        mac                     ;_QACallUser(rngstart,rngend,texthandle/4,textlen/4)
                   utool  $4C
                   <<<
~QAGoEval          MAC
                   pha
                   pha
                   psl    ]1
                   psw    ]2
_QAGoEVAL          mac                     ;_QAGoEVAL(@operand,offset):value/4
                   utool  $4D
                   <<<
~QAGoPutByte       MAC
                   psw    ]1
_QAGoPutByte       mac                     ;_QAGoPutByte(byte)
                   utool  $4E
                   <<<
~QAGoPutOpcode     MAC
                   psw    ]1
_QAGoPutOpcode     mac                     ;_QAGoPutOpcode(opcodebyte)
                   utool  $4F
                   <<<
_QAGoRelcorrect    mac                     ;_QAGoRelcorrect()
                   utool  $50
                   <<<
~QADrawErrChar     MAC
                   psw    ]1
_QADrawErrChar     mac                     ;_QADrawErrChar(char)
                   utool  $51
                   <<<
~QADrawErrStr      MAC
                   psl    ]1
_QADrawErrStr      mac
_QADrawErrString   mac                     ;_QADrawErrString(@strptr)
                   utool  $52
                   <<<
~QAGetWindow       MAC
                   pha
                   pha
_QAGetWindow       mac                     ;_QAGetWindow():windowtype
                   utool  $53
                   <<<
~QASetWindow       MAC
                   psl    ]1
_QASetWindow       mac                     ;_QASetWindow(windowtype)
                   utool  $54
                   <<<
~QAGetShellID      MAC
                   pha
_QAGetShellID      mac                     ;_QAGetShellID():userid
                   utool  $55
                   <<<
~QASetShellID      MAC
                   psw    ]1
_QASetShellID      mac                     ;_QASetShellID(userid)
                   utool  $56
                   <<<
~QAGotoXY          MAC
                   psw    ]1
                   psw    ]2
_QAGotoXY          mac                     ;_QAGotoXY(X,Y)
                   utool  $57
                   <<<
~QAGetXY           MAC
                   pha
                   pha
_QAGetXY           mac                     ;_QAGetXY():X,Y
                   utool  $58
                   <<<
~QAPrNibble        MAC
                   psw    ]1
_QAPrNibble        mac                     ;_QAPrNibble(nibval)
                   utool  $59
                   <<<
~QADrawHex         MAC
                   psl    ]1
                   psw    ]2
                   psw    ]3
_QADrawHex         mac                     ;_QADrawHex(hexval/4,flags,fieldsize)
                   utool  $5A
                   <<<
~QADrawCStr        mac
~QADrawCString     mac
                   psl    ]1
_QADrawCStr        mac
_QADrawCString     mac
_QADrawBlock       mac                     ;_QADrawBlock(@CBlock)
                   utool  $5B
                   <<<
~QADrawErrCStr     MAC
                   psl    ]1
_QADrawErrCStr     mac
_QADrawErrBlock    mac                     ;_QADrawErrBlock(@CBlock)
                   utool  $5C
                   <<<
~QADrawCharX       MAC
                   psw    ]1
                   psw    ]2
_QADrawCharX       mac                     ;_QADrawCharX(char,count)
                   utool  $5D
                   <<<
~QADrawECharX      MAC
                   psw    ]1
                   psw    ]2
_QADrawECharX      mac                     ;_QADrawECharX(char,count)
                   utool  $5E
                   <<<
~QAGetLaunch       MAC
                   pha
                   pha
                   pha
_QAGetLaunch       mac                     ;_QAGetLaunch():@path,flags
                   utool  $5F
                   <<<
~QASetLaunch       MAC
                   psl    ]1
                   psw    ]2
_QASetLaunch       mac                     ;_QASetLaunch(@path,flags)
                   utool  $60
                   <<<
~QAGetWord         MAC
                   pha
                   pha
                   psl    ]1
                   psw    ]2
                   psw    ]3
_QAGetWord         mac                     ;_QAGetWord(@Text,Offset,MaxLen):BegOffset,EndOffset
                   utool  $61
                   <<<
~QADateTime        mac
                   psl    ]1
                   psw    ]2
_QADateTime        mac                     ;_QADateTime(@Date,flags)
                   utool  $62
                   <<<
_QADrawCR          mac                     ;_QADrawCR()
                   utool  $63
                   <<<
_QADrawSpace       mac                     ;_QADrawSpace()
                   utool  $64
                   <<<
~QADrawVersion     mac
                   psl    ]1
_QADrawVersion     mac                     ;_QADrawVersion(Version/4)
                   utool  $65
                   <<<
~QADrawBox         MAC
                   pha
                   pha
                   psw    ]1
                   psw    ]2
                   psw    ]3
                   psw    ]4
_QADrawBox         MAC                     ;_QADrawBox(x,y,width,height):buffhdl
                   utool  $66
                   <<<
~QAEraseBox        MAC
                   psl    ]1
_QAEraseBox        MAC                     ;_QAEraseBox(buffhdl)
                   utool  $67
                   <<<
~QAConvertStr      MAC
                   pha
                   psl    ]1
                   psl    ]2
                   psw    ]3
_QAConvertStr      MAC                     ;_QAConvertStr(@string/class.1,@buffer/class.1,cmdcode):rtncode
                   utool  $68
                   <<<
~QADrawStrL        MAC
                   psl    ]1
_QADrawStrL        MAC                     ;_QADrawStrL(@string/class.1)
                   utool  $69
                   <<<
~QADrawErrStrL     MAC
                   psl    ]1
_QADrawErrStrL     MAC                     ;_QADrawErrStrL(@strptr/class.1)
                   utool  $6A
                   <<<
~QAGetKeyAdrs      MAC
                   pha
                   pha
_QAGetKeyAdrs      MAC                     ;_QAGetKeyAdrs():keyaddress/4
                   utool  $6B
                   <<<
~QANextLine        MAC
                   pha
                   pha
                   psl    ]1
                   psw    ]2
                   psw    ]3
_QANextLine        mac                     ;_QANextLine(@Text,Offset,MaxLen):NewLineOffset
                   utool  $6C
                   <<<
_QAClearKey        MAC                     ;_QAClearKey()
                   utool  $6D
                   <<<
_QAParseWord       MAC                     ;_QAParseWord(???):???
                   utool  $6E
                   <<<
utool              mac
                   ldx    #]1*256+ToolNum
                   do     userorsys
                   jsl    $E10008
                   else
                   jsl    $E10000
                   fin
                   <<<

