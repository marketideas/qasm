*======================================================
* Equates used by all programs in the QuickASM system

ToolNum            =     1
userorsys          =     $8000
ToolType           =     userorsys

versionnum         equ   $01016410

                   dum   1                       ;Languate ID #s
shellid            ds    1
asmid              ds    1
linkid             ds    1
editid             ds    1
projectid          ds    1
rezid              ds    1
utilid             ds    1
externalid         ds    1
                   dend

                   dum   $00                     ;Message ID #s
nomessage          ds    1
                   dend

                   dum   1                       ;Application message types
startmess          ds    1
runmess            ds    1
eventmess          ds    1
shutdownmess       ds    1
                   dend

                   dum   1                       ;Compiler message types
afromcmd           ds    1
afromname          ds    1
afromhandle        ds    1
maxamessage        =     *
                   dend

                   dum   1                       ;Linker message types
lfromcmd           ds    1
lfromname          ds    1
lfromhandle        ds    1
lquick             ds    1
lfromprojfile      ds    1
lfromprojhandle    ds    1
maxlmessage        =     *
                   dend

                   dum   0                       ;Command table record
ename              ds    16
etype              ds    2
eid                ds    2
eflags             ds    2                       ;b15 = restartable
                                                 ;b14 = active (running)
euserid            ds    2
edphandle          ds    4
edp                ds    2
eaddress           ds    4
emesstype          ds    2
emesssub           ds    4

eRecSize           =     *
                   dend


**** Vector ID #'s
                                                 ;  Number          Name
                   dum   1                       ; ------------------------------
vprintchar         ds    1                       ;_QADrawChar Vector
vprintstr          ds    1                       ;_QADrawString Vector
verrchar           ds    1                       ;_QADrawErrChar Vector
verrstr            ds    1                       ;_QADrawErrString Vector
vprintblk          ds    1                       ;_QADrawCStr
verrblk            ds    1                       ;_QADrawErrCStr
vputop             ds    1                       ;_QAPutOpcode Vector
vputbyte           ds    1                       ;_QAPutByte Vector
veval              ds    1                       ;_QAEval Vector
vrelcorrect        ds    1                       ;_QARelCorrect Vector
vkeyavail          ds    1                       ;_QAKeyAvail Vector
vgetchar           ds    1                       ;_QAGetChar Vector
vgetline           ds    1                       ;_QAGetLine Vector
vtabtocol          ds    1                       ;_QATabToCol Vector
vexeccmd           ds    1                       ;EXEC program Vector
vkeymac            ds    1                       ;KeyBoard macro program Vector
vusr               ds    1                       ;USR program Vector
vuser              ds    1                       ;USER program Vector
vxref              ds    1                       ;XREF program Vector
vprintstrl         ds    1                       ;print a class.1 string to current window
verrstrl           ds    1                       ;print a class.1 string to ERR window
vtoolmacs          ds    1                       ;HANDLE to built in ToolBOX Macs

maxvectors         =     *-1
                   dend

*======================================================
* ToolSet Error Codes

qatoolerr          =     ToolNum*256.userorsys

                   dum   qatoolerr
qanotstarted       ds    1
qabadcmdfile       ds    1
qacmdnotfound      ds    1
qalinknotavail     ds    1
qalangnotavail     ds    1
qabadvectornum     ds    1
qaalreadyactive    ds    1
qaunknowntypestr   ds    1
qatimeleverr       ds    1
qatotalerrleverr   ds    1
qabadpathname      ds    1
qanotnumber        ds    1
qanoword           ds    1
qabadinput         ds    1
qaeof              ds    1
                   dend

*------------------------------------------------------
* Assember/Linker Equates

asmmemid           =     $100
linkmemid          =     $100

oldshell           =     0                       ;temporary DO flag
maxsymbols         =     $2000

*======================================================
*  GSOS equates * call ID numbers

* Set 'Class1' to $2000 to use Class 1 calls, $0000 for Class 0 calls
prodos             =     $E100A8
prodosIL           =     $E100B0
inline             =     1                       ;stack or inline?

                   do    0
_Create            =     $0001.Class1
_Destroy           =     $0002.Class1
_OSShutdown        =     $2003                   ;class '1' only
_ChangePath        =     $0004.Class1
_SetFileInfo       =     $0005.Class1
_GetFileInfo       =     $0006.Class1
_Volume            =     $0008.Class1
_SetPrefix         =     $0009.Class1
_GetPrefix         =     $000A.Class1
_ClearBackup       =     $000B.Class1
_SetSysPrefs       =     $200C                   ;class '1' only
_Null              =     $200D                   ;class '1' only
_ExpandPath        =     $000E.Class1
_GetSysPrefs       =     $200F                   ;class '1' only
_Open              =     $0010.Class1
_Newline           =     $0011.Class1
_Read              =     $0012.Class1
_Write             =     $0013.Class1
_Close             =     $0014.Class1
_Flush             =     $0015.Class1
_SetMark           =     $0016.Class1
_GetMark           =     $0017.Class1
_SetEOF            =     $0018.Class1
_GetEOF            =     $0019.Class1
_SetLevel          =     $001A.Class1
_GetLevel          =     $001B.Class1
_GetDirEntry       =     $001C.Class1
_BeginSession      =     $201D                   ;class '1' only
_EndSession        =     $201E                   ;class '1' only
_SessionStatus     =     $201F                   ;class '1' only
_GetDevNumber      =     $0020.Class1
_GetLastDev        =     $0021.Class1
_ReadBlock         =     $0022                   ;class '0' only
_WriteBlock        =     $0023                   ;class '0' only
_Format            =     $0024.Class1
_EraseDisk         =     $0025.Class1
_ResetCache        =     $2026                   ;class '1' only
_GetName           =     $0027.Class1
_GetBootVol        =     $0028.Class1
_Quit              =     $0029.Class1
_GetVersion        =     $002A.Class1
_GetFSTInfo        =     $202B                   ;class '1' only
_DInfo             =     $002C.Class1
_DStatus           =     $202D                   ;class '1' only
_DControl          =     $202E                   ;class '1' only
_DRead             =     $202F                   ;class '1' only
_DWrite            =     $2030                   ;class '1' only
_AllocInterrupt    =     $0031                   ;P16 call
_BindInt           =     $2031                   ;GS/OS call
_DeallocInterrupt  =     $0032                   ;P16 call
_UnbindInt         =     $2032                   ;GS/OS call
_AddNotifyProc     =     $2034                   ;class '1' only
_DelNotifyProc     =     $2035                   ;class '1' only
_DRename           =     $2036                   ;class '1' only
_GetStdRefNum      =     $2037                   ;class '1' only
_GetRefNum         =     $2038                   ;class '1' only
_GetRefInfo        =     $2039                   ;class '1' only
                   fin
