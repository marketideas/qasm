*======================================================
* Some equates we need defined

TeaseWare = 0 ;1 = no saving allowed!

AppleMenu = 300
FileMenu = 255
EditMenu = 250
ProjMenu = 400
SrcMenu = 500
ToolMenu = 600
GSOSMenu = 700
TranMenu = 800
WindowMenu = 5000

TECtrlID = $69696969
WindowID = $FACE
CmdWdwID = $AAAA
ErrWdwID = $EEEE

rTEStyle = $8012
*------------------------------------------------------
* These are our zero page usage stuff

 dum EndZP
SDFlg ds 2 ;shut down flag

ClickFlg ds 2 ;is there a file to load from finder?

FrontWdw ds 2 ;0 = none of ours active
WdwPtr ds 4 ;current source window
CmdPtr ds 4 ;system window
ErrPtr ds 4 ;error window
TEHdl ds 4 ;for Text Edit record
CmdTEHdl ds 4
ErrTEHdl ds 4

WdwCnt ds 2 ;# of open windows (for menu disable)
SysWdw ds 2 ;NEG = system window

PrtHdl ds 4 ;handle to print record
PPort ds 4 ;printer port handle
PrtOK? ds 2 ;is it ok to print?

WMenuRef ds 2 ;item # for window menu
LastFile ds 2 ;menu # of last file active

CaseFlg ds 2 ;case insensitive = true
FromTop ds 2 ;search from top of doc?
WordFlg ds 2 ;search for words?
LabelFlg ds 2 ;go to a label?

ClearFlg ds 2 ;bne = clear TE text
EnterFlg ds 2 ;bne = parse line via QA tools

SaveText ds 2 ;save as text only?

tFLen ds 2 ;find & replace lengths
tRLen ds 4
textLen ds 4

ToolAdr ds 4 ;address of QATools
CmdAdr ds 4 ;address of command handling code
ParmHdl ds 4 ;parms
CmdHdl ds 4 ;our command table
NumCmds ds 2 ;# of commands we know

 err */$101 ;can't go past $FF
 dend

*======================================================
* The various routines & variables accessable in the IFD library
* (no drawing or sound or random stuff here!)

 EXT SetAPath,SetPath,ReadFile,WriteFile,GetFile,PutFile
 EXT StripPath,CopyPath,CopySFPath,CallDOS
 EXT SysError,TextError,CenterDialog
 EXT WaitEvent,WaitEventz,VErrCheck,AskForDisk

 EXT AppPath,PathParms,OpenParms,InfoParms,EOFParms
 EXT ReadParms,WriteParms,DestParms,CreateParms
 EXT FilePtr,PathPtr,SFTypes,SFRec,InPath
 EXT getpath,VolumeName,CreateSFPath,CheckClick

 EXT DSysErr,theError,ScreenWidth,TaskRc,Event,EType
 EXT Time,yPos,xPos,Mod,TData,TMask

 EXT Startup,Shutdown,CreateMBar,SetMenus,SetMItems,NewAlert

 EXT SetDIValue,PutText,GrabText,GetInt
