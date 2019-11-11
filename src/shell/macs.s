utool mac
 ldx #]1*256+ToolNum
 do userorsys
 jsl $E10008
 else
 jsl $E10000
 fin
 <<<
_QASetShellID mac
 utool $56
 <<<
_QARun mac 
 utool $23 
 <<<
_QAStatus mac
 utool $06
 <<<
~QAGetQuitFlag mac  ;_QAGetQuitFlag():quitflag
 pha
 utool $1D
 <<<
~QASetQuitFlag mac ;_QASetQuitFlag(quitflag)
 psw ]1
 utool $1E
 <<<
~QASetLaunch MAC 
 psl ]1 
 psw ]2 
_QASetLaunch mac ;_QASetLaunch(@path,flags)
 utool $60 
 <<<
~QAGetLaunch MAC
 pha
 pha
 pha
_QAGetLaunch mac
 utool $5F
 <<<
~QASetVector MAC
 psw ]1
 psl ]2
 utool $2F
 <<<
_QAResetVectors mac  ;_QAResetVectors()
 utool $30
 <<<
~QASetCancelFlag MAC
 psw ]1
 utool $40
 <<<
~QACompile MAC
 psw ]1
 psl ]2
 utool $26
 <<<
~QALink MAC
 psw ]1
 psl ]2
 utool $27
 <<<
~QAParseCmdLine MAC 
 pha 
 pha 
 psl ]1 
 utool $1C 
 <<< 
_QAExecCommand mac 
 utool $21 
 <<< 
~GetScrapHandle MAC 
 P2SW ]1 
 Tool $E16 
 <<< 
~TEScroll MAC
 PHW ]1
 PxL ]2;]3;]4
 Tool $2522
 <<<
~TEPointToOffset MAC
 PHS 2
 PxL ]1;]2;]3
 Tool $2122
 <<<
~TEKey MAC 
 PxL ]1;]2 
 Tool $1422 
 <<< 
~TEClear MAC 
 PHL ]1 
 Tool $1922 
 <<< 
_WaitCursor MAC
 Tool $A12
 <<<
_InitCursor MAC 
 Tool $CA04 
 <<< 
~MessageCenter MAC 
 PxW ]1;]2 
 PHL ]3 
 Tool $1501 
 <<< 
~NewHandle MAC 
 P2SL ]1 
 PxW ]2;]3 
 PHL ]4 
 Tool $902 
 <<< 
~HiliteMenu MAC
 PxW ]1;]2
 Tool $2C0F
 <<<
~TaskMaster MAC 
 PHA 
 PHWL ]1;]2 
 Tool $1D0E 
 <<< 
~FrontWindow MAC
 PHS 2
 Tool $150E
 <<<
~CloseWindow MAC
 PHL ]1
 Tool $B0E
 <<<
_CloseAllNDAs MAC
 Tool $1D05
 <<<
~DrawControls MAC 
 PHL ]1 
 Tool $1010 
 <<< 
~NewControl2 MAC 
 P2SL ]1 
 PHWL ]2;]3 
 Tool $3110 
 <<< 
~NewWindow MAC 
 P2SL ]1 
 Tool $90E 
 <<< 
~SendBehind MAC
 PxL ]1;]2
 Tool $140E
 <<<
~Alert MAC 
 PHA 
 PxL ]1;]2 
 Tool $1715 
 <<< 
~FMGetCurFID MAC
 PHS 2
 Tool $1A1B
 <<<
~ChooseFont MAC 
 P2SL ]1 
 PHW ]2 
 Tool $161B 
 <<< 
~ItemID2FamNum MAC 
 P1SW ]1 
 Tool $171B 
 <<< 
~TESetSelection MAC
 PxL ]1;]2;]3
 Tool $1D22
 <<<
~DisposeHandle MAC 
 PHL ]1 
_DisposeHandle MAC
 Tool $1002 
 <<< 
~TEInsert MAC
 PHWL ]1;]2
 PHLW ]3;]4
 PxL ]5;]6
 Tool $1A22
 <<<
~TEGetSelStyle MAC
 PHA 
 PxL ]1;]2;]3 
 Tool $1E22 
 <<< 
~TEStyleChange MAC 
 PHW ]1 
 PxL ]2;]3 
 Tool $1F22 
 <<< 
~TESetText MAC 
 PHWL ]1;]2 
 PHLW ]3;]4 
 PxL ]5;]6 
 Tool $B22 
 <<< 
~TEGetText MAC 
 PHS 2 
 PHWL ]1;]2 
 PHLW ]3;]4 
 PxL ]5;]6 
 Tool $C22 
 <<< 
~TEGetSelection MAC 
 PxL ]1;]2;]3 
 Tool $1C22 
 <<< 
~TEReplace MAC
 PHWL ]1;]2 
 PHLW ]3;]4 
 PxL ]5;]6 
 Tool $1B22
 <<< 
~AlertWindow MAC 
 P1SW ]1 
 PxL ]2;]3 
 Tool $590E 
 <<< 
~ZoomWindow MAC
 PHL ]1
 Tool $270E
 <<<
~TEUpdate MAC
 PHL ]1
 Tool $1222
 <<<
~PrSetDocName MAC
 PHL ]1
 Tool $3713
 <<<
_PrDefault MAC 
 Tool $0913 
 <<< 
~PrValidate MAC 
 P1SL ]1 
 Tool $0A13 
 <<< 
~PrJobDialog MAC 
 P1SL ]1 
 Tool $0C13 
 <<< 
~PrOpenDoc MAC 
 P2SL ]1 
 PHL ]2 
 Tool $0E13 
 <<< 
~PrCloseDoc MAC 
 PHL ]1 
 Tool $0F13 
 <<< 
~PrOpenPage MAC 
 PxL ]1;]2 
 Tool $1013 
 <<< 
~PrClosePage MAC 
 PHL ]1 
 Tool $1113 
 <<< 
~PrPicFile MAC 
 PxL ]1;]2;]3 
 Tool $1213 
 <<< 
~PrSetError MAC 
 PHW ]1 
_PrSetError MAC
 Tool $1513 
 <<< 
~GetPortRect MAC 
 PHL ]1 
 Tool $2004 
 <<< 
~TEPaintText MAC 
 P2SL ]1 
 PxL ]2;]3 
 PHWL ]4;]5 
 Tool $1322 
 <<< 
~PrStlDialog MAC
 P1SL ]1
 Tool $0B13
 <<<
~SetWRefCon MAC
 PxL ]1;]2
 Tool $280E
 <<<
~GetWRefCon MAC
 P2SL ]1
 Tool $290E
 <<<
~SetWTitle MAC
 PxL ]1;]2
 Tool $D0E
 <<<
~GetWTitle MAC
 P2SL ]1
 Tool $E0E
 <<<
~SetInfoRefCon MAC 
 PxL ]1;]2 
 Tool $360E 
 <<< 
~GetCtlHandleFromID MAC 
 PHS 2 
 PxL ]1;]2 
 Tool $3010 
 <<< 
~GetInfoRefCon MAC 
 P2SL ]1 
 Tool $350E 
 <<< 
~CloseDialog MAC 
 PHL ]1 
 Tool $C15 
 <<< 
~ModalDialog MAC 
 P1SL ]1 
 Tool $F15 
 <<< 
~GetIText MAC 
 PHL ]1 
 PHWL ]2;]3 
_GetIText MAC
 Tool $1F15 
 <<< 
~SetIText MAC 
 PHL ]1 
 PHWL ]2;]3 
_SetIText MAC
 Tool $2015 
 <<< 
~GetNewModalDialog MAC 
 P2SL ]1 
 Tool $3215 
 <<< 
~ShowHide MAC
 PHWL ]1;]2
_ShowHide MAC
 Tool $230E
 <<<
~ShowWindow MAC 
 PHL ]1 
 Tool $130E 
 <<< 
~SelectIText MAC 
 PHL ]1 
 PxW ]2;]3;]4 
 Tool $2115 
 <<< 
~GetDItemValue MAC 
 PHA 
 PHLW ]1;]2 
 Tool $2E15 
 <<< 
~SetDItemValue MAC 
 PHW ]1 
 PHLW ]2;]3 
_SetDItemValue MAC
 Tool $2F15 
 <<< 
~SetFontFlags MAC
 PHW ]1
 Tool $9804
 <<<
~SetPort MAC
 PHL ]1
 Tool $1B04
 <<<
~InsertMItem MAC 
 PHL ]1 
 PxW ]2;]3 
 Tool $F0F 
 <<< 
_DeleteMItem MAC 
 Tool $100F 
 <<< 
~CalcMenuSize MAC 
 PxW ]1;]2;]3 
 Tool $1C0F 
 <<< 
~CheckMItem MAC 
 PxW ]1;]2 
 Tool $320F 
 <<< 
~SetMItemName MAC 
 PHLW ]1;]2 
 Tool $3A0F 
 <<< 
~SelectWindow MAC
 PHL ]1 
_SelectWindow MAC
 Tool $110E
 <<< 
~GetWKind MAC
 P1SL ]1
 Tool $2B0E
 <<<
~GetNextWindow MAC 
 P2SL ]1 
 Tool $2A0E 
 <<< 
~GetFirstWindow MAC 
 PHS 2 
 Tool $520E 
 <<< 
~MoveWindow MAC
 PxW ]1;]2
 PHL ]3
 Tool $190E
 <<<
~SizeWindow MAC
 PxW ]1;]2
 PHL ]3
 Tool $1C0E
 <<<
~NotifyCtls MAC
 PxW ]1;]2
 PxL ]3;]4
 Tool $2D10
 <<<
~SetPortLoc MAC
 PHL ]1
 Tool $1D04
 <<<
~GetPortLoc MAC
 PHL ]1
 Tool $1E04
 <<<
~Dec2Int MAC
 P1SL ]1
 PxW ]2;]3
_Dec2Int MAC
 Tool $280B
 <<<
~Int2Dec MAC 
 PHWL ]1;]2 
 PxW ]3;]4 
 Tool $260B 
 <<< 
~Long2Dec MAC 
 PxL ]1;]2 
 PxW ]3;]4 
 Tool $270B 
 <<< 
~TECopy MAC
 PHL ]1
 Tool $1722
 <<<
~TEGetRuler MAC 
 PHWL ]1;]2 
 PHL ]3 
 Tool $2322 
 <<< 
~TESetRuler MAC 
 PHW ]1 
 PxL ]2;]3 
 Tool $2422 
 <<< 
~ReadFile MAC 
 lda ]1 
 ldy ]2 
 jsr ReadFile 
 <<< 
~WriteFile MAC 
 do ]0/3 
 lda ]3 
 sta CreateParms+8
 fin 
 ldy ]1 
 lax ]2 
 jsr WriteFile 
 <<< 
~GetFile MAC 
 lda ]1 
 ldx ]2 
 ldy ]3 
_GetFile MAC
 jsr GetFile 
 <<< 
~PutFile MAC 
 lda ]1 
 ldx ]2 
 jsr PutFile 
 <<< 
~PutText MAC
 ldx ]1
 lda ]2
_PutText MAC
 jsr PutText
 <<<
~GrabText MAC
 ldx ]1
 lda ]2
_GrabText MAC
 jsr GrabText
 <<<
~GetInt MAC
 ldx ]1
_GetInt MAC
 jsr GetInt
 <<<
~TEGetLastError MAC
 PHA
 PHWL ]1;]2
 Tool $2722
 <<<
~InvalCtls MAC
 PHL ]1
 Tool $3710
 <<<
_CreateSFPath MAC 
 jsr CreateSFPath 
 <<< 
_GSOS MAC
 do inline
 jsl prodos
 dw ]1
 adrl ]2
 else
 psl #]2
 pea ]1
 jsl prodosIL
 fin
 <<<
~SysError MAC 
 ldx ]1 
 do ]0/2 
 lda ]2 
 fin 
 jsr SysError 
 <<< 
~CenterDialog MAC 
 lda ]1 
 jsr CenterDialog 
 <<< 
~Startup MAC
 ldx ]1
 ldy ]2
 lda ]3
 jsr Startup
 <<<
_Shutdown MAC 
 jsr Shutdown 
 <<< 
~CreateMBar MAC 
 lda ]1 
 ldx ]2 
 ldy ]3 
 jsr CreateMBar 
 <<< 
_SetMenus MAC 
 jsr SetMenus 
 <<< 
_SetMItems MAC 
 jsr SetMItems 
 <<< 
~FreeMem MAC 
 PHS 2 
 Tool $1B02 
 <<< 
~MaxBlock MAC 
 PHS 2 
 Tool $1C02 
 <<< 
~TotalMem MAC 
 PHS 2 
 Tool $1D02 
 <<< 
~RealFreeMem MAC 
 PHS 2 
 Tool $2F02 
 <<< 
~TEGetTextInfo MAC 
 PHLW ]1;]2 
 PHL ]3 
 Tool $D22 
 <<< 
~CheckClick MAC
 lda #]1
 jsr CheckClick
 <<<
~NewAlert MAC
 lda #]1
 jsr NewAlert
 <<<
~CreateResourceFile MAC
 PHLW ]1;]2
 PHWL ]3;]4
 Tool $91E
 <<<
~OpenResourceFile MAC 
 P1SW ]1 
 PxL ]2;]3 
 Tool $A1E 
 <<< 
_CloseResourceFile MAC 
 Tool $B1E 
 <<< 
~AddResource MAC 
 PHLW ]1;]2 
 PHWL ]3;]4 
 Tool $C1E 
 <<< 
~LoadResource MAC 
 P2SW ]1 
 PHL ]2 
 Tool $E1E 
 <<< 
~DetatchResource MAC 
 PHWL ]1;]2 
 Tool $181E 
 <<< 
~RemoveResource MAC 
 PHWL ]1;]2 
 Tool $F1E 
 <<< 
~HLock MAC
 PHL ]1
 Tool $2002
 <<<
~HUnlock MAC
 PHL ]1
 Tool $2202
 <<<
~GetHandleSize MAC 
 P2SL ]1 
 Tool $1802 
 <<< 
~HandToHand MAC 
 PxL ]1;]2;]3
 Tool $2A02 
 <<< 
~InitialLoad MAC 
 PHS 5 
 PHWL ]1;]2 
 PHW ]3 
 Tool $911 
 <<< 
~SetTSPtr MAC 
 PxW ]1;]2 
 PHL ]3 
 Tool $A01 
 <<< 
_SetHandleSize MAC 
 Tool $1902 
 <<< 
_QABootInit mac 
 utool $01 
 <<< 
_QAStartup mac 
 utool $02 
 <<< 
_QAGetLine mac 
 utool $10 
 <<< 
~QASetParmHdl MAC 
 psl ]1 
 utool $11 
 <<< 
~QASetCmdHdl MAC 
 psl ]1 
 psw ]2 
 utool $13 
 <<< 
~QASetCmdTbl MAC 
 psl ]1 
 utool $1F 
 <<< 
~QAGetCompileID MAC 
 pha 
 utool $2A 
 <<< 
~QASetCompileID MAC 
 psw ]1 
 utool $2B 
 <<< 
~QAGetLinkID MAC 
 pha 
 utool $2C 
 <<< 
~QASetLinkID MAC 
 psw ]1 
 utool $2D 
 <<< 
_QAGetCmdRecSize mac 
 utool $32 
 <<< 
~QAGetWord MAC 
 pha 
 pha 
 psl ]1 
 psw ]2 
 psw ]3 
 utool $61 
 <<< 
~QANextLine MAC 
 pha 
 psl ]1 
 psw ]2 
 psw ]3 
 utool $6C
 <<< 
~QADrawStr MAC
 psl ]1
 utool $0A
 <<<
_QAShutdown mac 
 utool $03 
 <<< 
_QADispose mac 
 utool $24 
 <<< 
_QADrawBlock mac 
 utool $5B 
 <<< 
~QADrawVersion mac 
 psl ]1 
 utool $65 
 <<< 
_QAPrByteL mac
 utool $0C
 <<<
_QADrawCR mac 
 utool $63 
 <<< 
_GrafOn MAC
 Tool $A04
 <<<
_GrafOff MAC
 Tool $B04
 <<<
_QAClearKey MAC 
 utool $6D
 <<< 
P2SW MAC 
 PHA 
 PHA 
 IF #=]1 
 PEA ]1 
 ELSE 
 IF MX/2 
 LDA ]1+1 
 PHA 
 FIN 
 LDA ]1 
 PHA 
 FIN 
 <<< 
CmpLong MAC 
 LDA ]1 
 CMP ]2 
 IF #=]1 
 LDA ^]1 
 ELSE 
 LDA ]1+2 
 FIN 
 IF #=]2 
 SBC ^]2 
 ELSE 
 SBC ]2+2 
 FIN 
 <<< 
Hdl_Ptr MAC 
 lda []1] 
 sta ]2 
 ldy #2 
 lda []1],y 
 sta ]2+2 
 <<< 
bfl mac 
 beq ]1 
 <<< 
btr mac 
 bne ]1 
 <<< 
lax mac 
 lda ]1 
 if #,]1 
 ldx ^]1 
 else 
 ldx ]1+2 
 fin 
 <<< 
sax MAC 
 sta ]1 
 stx ]1+2 
 <<< 
P1SL MAC 
 PHA 
 IF #=]1 
 PEA ^]1 
 ELSE 
 PHW ]1+2 
 FIN 
 PHW ]1 
 <<< 
MoveLong MAC
 MoveWord ]1;]2
 MoveWord ]1+2;]2+2
 <<<
MoveWord MAC
 LDA ]1
 STA ]2
 IF MX/2
 LDA ]1+1
 STA ]2+1
 FIN
 <<<
PHLW MAC 
 PHL ]1 
 PHW ]2 
 <<< 
P1SW MAC 
 PHA 
 IF #=]1 
 PEA ]1 
 ELSE 
 IF MX/2 
 LDA ]1+1 
 PHA 
 FIN 
 LDA ]1 
 PHA 
 FIN 
 <<< 
PxL MAC 
 DO ]0/1 
 PHL ]1 
 DO ]0/2 
 PHL ]2 
 DO ]0/3 
 PHL ]3 
 DO ]0/4 
 PHL ]4 
 FIN 
 FIN 
 FIN 
 FIN 
 <<< 
PHWL MAC 
 PHW ]1 
 PHL ]2 
 <<< 
PHS MAC
 DO ]0
 LUP ]1
 PHA
 --^
 ELSE
 PHA
 FIN
 <<<
psw MAC
PushWord MAC 
 IF #=]1 
 PEA ]1 
 ELSE 
 IF MX/2 
 LDA ]1+1 
 PHA 
 FIN 
 LDA ]1 
 PHA 
 FIN 
 <<< 
PxW MAC 
 DO ]0/1 
 PHW ]1 
 DO ]0/2 
 PHW ]2 
 DO ]0/3 
 PHW ]3 
 DO ]0/4 
 PHW ]4 
 FIN 
 FIN 
 FIN 
 FIN 
 <<< 
P2SL MAC 
 PHA 
 PHA 
 IF #=]1 
 PEA ^]1 
 ELSE 
 PHW ]1+2 
 FIN 
 PHW ]1 
 <<< 
psl mac 
PHL MAC 
 IF #=]1 
 PEA ^]1 
 ELSE 
 PHW ]1+2 
 FIN 
 PHW ]1 
 <<< 
PHW MAC 
 IF #=]1 
 PEA ]1 
 ELSE 
 IF MX/2 
 LDA ]1+1 
 PHA 
 FIN 
 LDA ]1 
 PHA 
 FIN 
 <<< 
PullLong MAC 
 DO ]0 
 PullWord ]1 
 PullWord ]1+2 
 ELSE 
 PullWord 
 PullWord 
 FIN 
 <<< 
PullWord MAC 
 PLx
 DO ]0 
 STx ]1
 FIN 
 IF MX/2 
 PLx
 DO ]0 
 STx ]1+1
 FIN 
 FIN 
 <<< 
LONGAX MAC 
 IF MX 
 REP %00110000 
 FIN 
 <<< 
SHORTAX MAC 
 IF MX!%11 
 SEP %00110000 
 FIN 
 <<< 
LONGM MAC
 IF MX&2
 REP %00100000
 FIN
 <<<
SHORTM MAC
 IF MX&2
 ELSE
 SEP %00100000
 FIN
 <<<
Tool MAC 
 LDX #]1 
 JSL $E10000 
 <<< 
