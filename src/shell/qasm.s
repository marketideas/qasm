 lst off
 ttl "QuickASM Shell v0.70"
 exp off
 tr on
 cas se
* dup
*======================================================
* Graphic Shell for QuickASM development system

* Programming by Lane Roath
* Copyright (c) 1990 Ideas From the Deep & Lane Roath
*------------------------------------------------------
* 26-Jun-90 0.70 :Line/Label in, Find centers text, WORDS works!
* 20-Jun-90 0.60 :now works w/new stuff from Shawn & LOGIN!!!!
* 10-Jun-90 0.50 :asm,link,menus now much easier to use
* 30-Mar-90 0.40 :One shell, graphics & text... works!
* 01-Mar-90 0.35 :QA command parsing working!!!
* 27-Feb-90 0.30 :QA output trapped, link & assemble work
* 22-Feb-90 0.20 :start adding QA stuff (seperate file)
* 09-Feb-90 0.10 :start graphics shell from WW code
*======================================================

 rel

Version = $00700000 ;v0.70
Class1 = $2000

 lst off
 use 2/data/qa.equates
 use macs
 use ifd.equs
 use equs
 lst rtn

 EXT HProj,HSrc,HGSOS,HTran,HTool,InstallKey,LoadQAStuff
 EXT pchr,pstr,pblk,pechr,pestr,peblk,DoClear,DoEnter
 EXT doTextMode,PrintWelcome,pt2c,SetStyle,mySetRuler
 EXT GrafVectors,SetTabs

*======================================================
* Startup the program & do all that cool stuff

QuickASM ENT
 phk ;use our bank as data bank
 plb
 tdc  ; & save DP for special use
 sta myDP

 ~Startup #SSRec;#mySD;#0 ;startup the toolbox

 stz WdwCnt
 stz SDFlg
 stz ClearFlg
 stz EnterFlg
 stz PrtOK?
 stz LastFile
 stz SaveText
 lda #5002 ;init window menu
 sta WMenuRef
 lda #1 ;init search flags
 sta CaseFlg
 sta FromTop
 stz WordFlg
 stz LabelFlg
 inc
 sta TextPath ;can't have NIL initial path!
 lda #'1:'
 sta TextPath+2

 ~NewHandle #200;ID2;#0;#0 ;allocate print record
 ply
 sty PrtHdl ;save handle, good or bad (stack)!
 plx
 stx PrtHdl+2
 bcs :4
 phx
 phy
 _PrDefault ;init record w/default values
 bcc :1
:4
 ~SysError #MPInit ;show error w/allocation
 bra :0
:1
 dec PrtOK?
 Hdl_Ptr PrtHdl;Ptr
 ldy #$18 ;index to wDev in style subrecord
 lda [Ptr],y
 and #%11111111_11011010 ;force condensed & text quality
 ora #%00000000_00000001
 sta [Ptr],y
:0
 ~FMGetCurFID ;get current font ID
 PullLong NewStyle
 lda #22
 sta NewStyle ;force cmd windows to be in COURIER!
 SEP #$20
 lda #12 ;use 10 point
 sta NewStyle+3
 REP #$20

 jsr LoadQAStuff ;need QA stuff
 bcc :qagood
 ~SysError #QAError
:qagood
 jsr PrintWelcome ;show QuickASM welcome text

 jsr GrafVectors ;set print vectors for graphics

 ~CreateMBar #Menus;#AppleMenu;#0 ;create our menu bar

 lda #16*1024 ;16K max
 sta TEMaxChrs

 lda #100
 sta WdwRec ;only use half of screen
 lda #CmdWdwID
 sta WdwIDNum
 ldx #CmdTitle ;open command window
 jsr OpenWindow
 lax WdwPtr
 sax CmdPtr ;save wdw pointer
 lax TEHdl
 sax CmdTEHdl ;save TE handle (for inserts)

 jsr InstallKey ;let ENTER,CLEAR work

 lda #25
 sta WdwRec
 lda #100 ;only use half of screen
 sta WdwRec+4
 lda #ErrWdwID
 sta WdwIDNum
 ldx #ErrTitle ;open error window
 jsr OpenWindow
 lax WdwPtr
 sax ErrPtr ;save wdw pointer
 lax TEHdl
 sax ErrTEHdl ;save TE handle (for inserts)

 jsr InstallKey ;setup as required

 stz TEMaxChrs ;unlimited source size
 lda #199
 sta WdwRec+4 ;docs use all of screen
 lda #WindowID
 sta WdwIDNum
 sta FrontWdw ;force update of menus

 ~SelectWindow CmdPtr

 stz PrintBuf
 jsr PrintWelcome ;show QuickASM welcome text

 _InitCursor ;no longer waiting to startup

 ~CheckClick #TextName ;do we have a doc to open?
 bcs :9
 txa
 beq :9 ; no- don't open anything

 jsr HProj ;open new/finder doc
:9
 do TeaseWare
 jsr DoTease ;show teaser if on
 fin

*======================================================
* Main event loop

Main
 _QARun ;allow background apps time

 ~QAGetQuitFlag ;time to quit?
 pla
 bfl :0
 jsr mySD ; yes- repeat if open windows
:0
 jsr SetWindow ;insure menus set correctly

 ~TaskMaster #$FFFF;#TaskRc ;handle the tasks!
 pla
 bfl :9 ;result from TaskMaster

 cmp #$19 ;special menu item?
 beq :4
 cmp #$11 ;menu event?
 bne :1
:4
 jsr HandleMenus ; yes- handle it
 bra :9
:1
 cmp #$16 ;close window
 bne :2
 jsr CloseWindow ; yes- do so!
:2
:9
 ~TEGetLastError #-1;TEHdl ;report any internal errors
 pla
 bfl :ok
 ~SysError #MTEInfo ; (saves crashes!)
 bra Main
:ok
 lda ClearFlg ;user press CLEAR?
 beq :9a
 jsr DoClear ; yes- clear text
:9a
 lda EnterFlg ;how about ENTER?
 beq Main
 jsr DoEnter ; yes- parse line
 bra Main

*======================================================
* Close all windows, save all docs, and shutdown the tools

mySD
 phk
 plb
 clc ;use our bank, in 65816, 16 bit mode
 xce
 rep #$30
 lda myDP
 tcd

 lda WdwCnt ;do we need to close a window?
 cmp #3
 blt :1
 jsr CloseWindow ; yes- try to do so
 bcc :2
 ~QASetQuitFlag #0 ;user canceled!!!
 stz SDFlg
:2 rts
:1
 ~QAGetLaunch ;get launch flags (leave on stack)
 _QADispose
 _QAShutdown  ;shutdown QA tools

 _Shutdown ;shutdown real tools

 ply
 pla
 plx ;get launch flags from stack
 stz QuitParms
 lax #TextPath ;[][ vat do we get back? ][]
 sax QuitParms+2
 sty QuitParms+6 ; & save to quit area
 tya
 beq :quit
 and #$FF ;launch or shutdown?
 bfl :launch

 lda #1 ; SD- make parms usable
 sta SDParms
 _GSOS _OSShutdown;SDParms ;shutdown
 brk $69
:launch
 lda #2
 sta QuitParms ;use launch parms!
:quit
 _GSOS _Quit;QuitParms
 brk $69

*======================================================
* Handle Menu events from Task Master

HandleMenus
 lda TData+2
 ldx #-2 ;locate index
]loop inx
 inx
 cpx MaxMenus ;should never happen!
 bge :err
 cmp MenuNums,x ; by looking for menu #
 bne ]loop
 lda TData ; item = item # - menu #
 sec
 sbc TData+2 ;and exit via da table
 jsr (HdlMenus,x)

 ~HiliteMenu #0;TData+2 ;unhilite menu
 rts
:err
 ora #$8000
 ~SysError #MMenu ;ohhhh no!
 rts

*======================================================
* Set the window after a new one becomes active

SetWindow
 ~FrontWindow
 pla ;get pointer to front window
 plx  ; (system,ours,none)
 cmp WdwPtr
 bne :1
 cpx WdwPtr+2 ;is this a new window?
 bne :1
 rts ; no- done!
:1
 sax WdwPtr ; yes- save pointer
 ora WdwPtr+2
 bfl :disable ;window open?

 ~CheckMItem #0;LastFile ; yes- uncheck last file in menu

 ~GetWKind WdwPtr ;is this one of our windows?
 plx
 stx SysWdw ;save status
 bmi :disable

 ~GetCtlHandleFromID WdwPtr;#TECtrlID
 PullLong TEHdl

 ~GetWRefCon WdwPtr ;get application value
 plx
 stx LastFile ;check in menu
 ~CheckMItem #1;LastFile
 ply
 cpy #WindowID ;source window?
 bne :disable+2
 brl EnableMenus ; yes, enable our menus
:disable
 stz LastFile
 brl DisableMenus ; no, disable our menus

*======================================================
* Handle Apple menu events

HApple
 bne :1 about?
 ldx #Anorm
 ldy #anz-Anorm
 lda TaskRc+14 ;option key pressed?
 and #%0000100000000000
 bfl :a
 ldx #Aspcl  ; yes, show bullshit dialog
 ldy #asz-Aspcl
:a
 stx AMod ;set text to show
 sty AMod+4
 ~CenterDialog #DAbout
 ~Alert #DAbout;#0 ; & display centered alert
 pla
:1
 dec ;help?
 bne :2
:2
 do TeaseWare
DoTease ~NewAlert #DTease ; yes, does user really want to?
 fin

 rts

*======================================================
* Handle the File menu selections

HFile ENT
 asl ;create index
 tax
 jmp (:tbl,x) ; & pass control to item handler
:tbl
 da :Close
 da :New
 da :Open
 da :Save
 da :Save_As
 da :Write
 da :Write_As
 da :Append
 da :Revert
 da :Page_Setup
 da :Print
 da :Shutdown
 da :Quit

*------------------------------------------------------
:Close
 brl CloseWindow
*------------------------------------------------------
:New
 SHORTAX
 ldx NewName
 inc NewName+1,x ;we allow new files A-Z
 LONGAX
 ldx #NewName
 brl OpenWindow2 ; yes- do so!

*------------------------------------------------------
:Open
 ldy #TxtTypes
 lda TaskRc+14 ;option key pressed?
 and #%0000100000000000
 bfl :a
 ldy #AllTypes ; yes!  Allow opening of ANY file!
:a
 lda #OpenPrompt
 ldx #TextName ;present SFDialog to select file
 _GetFile
 bcs :2b
 btr :2a
:1a rts ;no file selected!
:2a
 _WaitCursor
 jsr :ReadFile ;read file w/style if present
 bcs :2d
 ldx #TextPath ;title = pathname
 jsr OpenWindow2 ;Now open a window for the text!
 bcs :2d
 jsr SetText ;place text into TERec
 bcc :2c
:2d
 jsr RemoveText ;error- clean up memory
:2b
 ~SysError #MFOpen ;inform user of errors
:2c
 _InitCursor
 rts
*------------------------------------------------------
:Write
 dec SaveText ;FALL THRU!!!
*------------------------------------------------------
:Save
 ~GetWTitle WdwPtr ; yes- need a filename?
 PullLong Ptr
 lda [Ptr]
 cmp #$550A ; (untitled = 10,'U')
 beq :Save_As
 brl SaveData ; no, just save

*------------------------------------------------------
:Write_As
 dec SaveText ;FALL THRU!!!
*------------------------------------------------------
:Save_As
 ~GetWTitle WdwPtr ; yes- get filename
 pla
 plx ; & set up for SF dialog
 ldy #TextName
 _CreateSFPath ; (set path & file info)
 bcs :2b
 ~PutFile #SavePrompt;#TextName
 bcs :2b
 bfl :2c
 ~GetInfoRefCon WdwPtr ;get handle to title memory
 _DisposeHandle ; & free that memory!
 bcs :2b
 ldx #InPath ;reset window title
 jsr SetWdwTitle
:g2b bcs :2b
 brl SaveData ;save file under new name!

*------------------------------------------------------
:Page_Setup
 lda PrtOK? ;ok to do this?
 bfl :6a
 ~PrStlDialog PrtHdl ; yep, do so
 plx
:62b bcs :52b
:6a rts

*------------------------------------------------------
:Print
 lda PrtOK? ; yes, printing ok?
 bfl :6a
 brl PrintText ; yes- do so!

*------------------------------------------------------
:Append
 ~GetFile #AppendPrompt;#TextName;#TxtTypes
 bcs :g2b
 bfl :6a
 ~TESetSelection #-1;#-1;#0 ;move to end of text
:DoApnd
 _WaitCursor
 jsr :ReadFile ;read text & style from file
:52b bcs :g2b
 ~TEReplace #%1101;textH;#0;#1;styleH;#0 ; & replace selection
 jsr RemoveText
 brl :2c

*------------------------------------------------------
:Revert
 ~GetWTitle WdwPtr ; yes- anything to revert to?
 PullLong Ptr
 lda [Ptr]
 cmp #$550A ; (can't revert if never saved!)
 beq :9a
 ~NewAlert #DWarning ; yes, does user really want to?
 bne :9a
 ~GetWTitle WdwPtr ;get name to revert to
 pla
 plx
 ldy #TextName
 _CreateSFPath ;set path & get save name
:g52b bcs :52b
 lda #20 ;select entire document
 jsr HEdit
 brl :DoApnd ; & replace w/file contents

*------------------------------------------------------
:Shutdown
 ~QASetLaunch #0;#-1 ;shutdown

*------------------------------------------------------
:Quit
 _CloseAllNDAs  ;close any open NDAs first
 bcs :g52b
 ~QASetQuitFlag #-1 ; & quit if we are OK
:9a rts

*------------------------------------------------------
* Save some code space, make changes easier

:ReadFile
 ~ReadFile #TextName;#0 ;read file into memory
 bcs :rfxit
 sax textH
 stz styleH ;assume just a text file
 stz styleH+2
 lda OpenParms+14 ;wp file?
 eor #$50
 bne :rfxit
 jsr LoadStyle ; yes- get style info
:rfxit rts

*======================================================
* Handle the edit menu selections

HEdit ENT
 sec
 sbc #20 ;create usable #, ignore sys stuff
 blt :2z
 ~TESetSelection #0;#-1;#0 ;Select All!
:2z
 rts

*======================================================
* Handle a menu item selection

HWdwMenu
 bne :1 ;stack windows?
 jsr :InitStack
 lda #:stack ; yes- do so
 brl DoWindows
:1
 dec ;edit next document?
 beq :3
 dec  ;text mode?
 bne :2
 jmp doTextMode ; yes- do it!
:3
 stz temp
 lda #:nextwdw ; yes- search for it
 jsr DoWindows
 lda temp2 ;got one?
 cmp #-1
 bne :2a
 lda temp3 ; no- or we wrapped to first!
:2a
 sta TData ;and select it!!!
:2
 lda #:front
 jsr DoWindows ;select it- return = error!
 lda #$FACE
:9
 ~SysError #MGetWindow ;oh shit!
 rts
*------------------------------------------------------
:front
 cpx TData ; yes- correct one?
 bne :no
 pla ; yes, return to main loop!
 pla
 ~SelectWindow Ptr ;bring it to the front!
 bcs :9
 _InitCursor ; & exit
:no
 rts
*------------------------------------------------------
:stack
 cpy #WindowID ;only stack source windows
 bne :no
 ~ShowHide #0;Ptr ;adjust window pos while hidden
 ~MoveWindow :pos+2;:pos;Ptr
 ~SizeWindow #586;#124;Ptr
 ~NotifyCtls #-1;#16;#0;Ptr
 ~ShowWindow Ptr ;redisplay it

 lda :pos+2
 sec
 sbc #10
 tax ;adjust for new pos
 lda :pos
 sbc #10 ; (+10 in both directions)
 cmp #25
 bge :is2 ;still on screen?
:InitStack
 lda #24
 ldx #1 ;set start of stack
 ldy WdwCnt
]loop
 dey ;done w/windows?
 beq :is2
 adc #10 ; no- move windows up
 pha
 txa
 adc #10 ; & to the left
 tax
 pla
 cmp #70 ;moved to furthest pos?
 blt ]loop
:is2
 sta :pos
 stx :pos+2
 rts
:pos
 dw 0,0

*------------------------------------------------------
* Search thru windows for 'next' one (wish I could search menus!)

:nextwdw
 lda temp ;first time?
 bne :srch
 stx temp ; yes- init
 stz temp2
 dec temp2
 bra :s2
:s1
 cpx temp3 ;less than first?
 bge :xit
:s2
 stx temp3 ; yes- save for wrap
 rts
:srch
 cpx temp ;greater than first?
 blt :s1
 cpx temp2 ; yes- less than last?
 bge :xit
 stx temp2 ; yes- save it
:xit rts

*======================================================
* Go thru each window on the screen.  If a window is ours
* call a procedure to deal with it, otherwise cycle to end
* of the windows & return to caller
* ENTRY: A = routine pointer
*  EXIT: none (last window reached)

DoWindows
 sta :mod+1 ;save pointer to routine

 _WaitCursor

 ~GetFirstWindow ;get first window in system
 bra :getptr
]loop
 ~GetWRefCon Ptr ;check to see if it's the right window
 plx
 ply
 bcs :9
 cpy #WindowID ;is it ours?
 beq :mod
 cpy #ErrWdwID
 beq :mod
 cpy #CmdWdwID
 bne :next
:mod jsr $FFFF ; yes -handle it!
:next
 ~GetNextWindow Ptr ;try the next one
:getptr
 pla
 plx
 sax Ptr ;got one?
 ora Ptr+2
 bne ]loop ; yes- check it!
:9
 _InitCursor
 rts

*======================================================
* Open a new text edit window for our use
* ENTRY: X = title to window
*  EXIT: standard errors

OpenWindow2 ;zeros out WdwPtr after open
 jsr OpenWindow
 stz WdwPtr
 stz WdwPtr+2 ;insure menus set correctly
 rts
OpenWindow
 phx ;save pointer to title

 ~NewWindow #WindowParms ;open actual window
 PullLong WdwPtr
 bcs :9 ;error?

 inc WdwCnt ;we opened another!

 ~NewControl2 WdwPtr;#0;#TETemplate
 PullLong TEHdl
 bcc :1
:9
 plx
 ~SysError #MWOpen ;ooops! Show user!
 rts
:1
 lda #2
 ldy #$10 ;we use
 inc WMenuRef
 lda WMenuRef
 sta NWID ;id for menu
 sta temp
 lda WdwIDNum ;id for checks
 sta temp+2
 ~SetWRefCon temp;WdwPtr ;set 'our window' thingy.
 bcs :9
 ~InsertMItem #NewWdw;#-1;#WindowMenu
 bcs :9

 ~TEGetRuler #3;#rulerH;#0 ;get ruler
 bcs :9

 lax rulerH
 sax Hdl ;move to DP & place on stack
 pea #0
 pea #$26
 phx
 pha
 _SetHandleSize ;it's a bit bigger now!
 bcs :9

 Hdl_Ptr Hdl;Ptr
 ldy #$10
 lda #2 ;we use specific tabs
 sta [Ptr],y
 ldy #$14
 lda #75 ;opcode tab
 sta [Ptr],y
 ldy #$18
 lda #125 ;operand
 sta [Ptr],y
 ldy #$1C
 lda #200 ;comment
 sta [Ptr],y
 ldy #$20
 lda #300 ;extra
 sta [Ptr],y
 ldy #$24
 lda #-1 ;terminator
 sta [Ptr],y
 jsr mySetRuler ;use it!

 Hdl_Ptr TEHdl;Ptr ;point to TE record
 ldy #$10
 lda [Ptr],y ;clear dirty flag!
 and #%10111111
 sta [Ptr],y

 plx

*======================================================
* Set the title for the current window
* ENTRY: X = address of title (GS/OS class 1 string)
*  EXIT: none

SetWdwTitle
 stx temp2 ;point to title
 lda (temp2)
 inc
 inc
 sta temp ; & get length
 stz temp+2

 ~NewHandle temp;ID3;#$C000;#0 ;get memory for title
 PullLong Hdl
 bcc :1
:9
 ~SysError #MWTitle ;show error!
 rts
:1
 Hdl_Ptr Hdl;Ptr ;point to this memory

 SHORTM
 lda (temp2) ;get length of title
 sta [Ptr]
 tay
]loop
 iny
 lda (temp2),y ;copy string to buffer
 dey
 sta [Ptr],y
 dey
 bne ]loop
 LONGM

 ~PrSetDocName Ptr ;show name over network
 bcs :9
 ~SetWTitle Ptr;WdwPtr ;set window title
 bcs :9
 ~SetInfoRefCon Hdl;WdwPtr ; & save handle to title memory
:g9 bcs :9
 ~GetWRefCon WdwPtr ;get menu item #
 plx
 ply
 bcs :g9
 stx temp
 ~SetMItemName Ptr;temp ;set menu item's name
 bcs :g9
 ~CalcMenuSize #0;#0;#WindowMenu
 rts

*======================================================
* Close the currently open window, checking to see if the
* window's contents need to be saved.

CloseWindow
 lda FrontWdw ;is it ours?
 btr :0
 ~SendBehind #-2;WdwPtr ; no- send it behind the others
 rts
:0
 jsr CheckSave ;save data if needed
 bcs :9
 ~GetInfoRefCon WdwPtr ;get handle to title memory
 _DisposeHandle ; & free that memory!
 bcs :1
 ~GetWRefCon WdwPtr ;get menu item #
 plx
 ply
 bcs :1
 phx
 _DeleteMItem ;remove from window!
 bcs :1
 ~CalcMenuSize #0;#0;#WindowMenu

 dec WdwCnt ;one less!
 ~CloseWindow WdwPtr ;close window if OK
 bcc :9
:1
 ~SysError #MClose ;oops!
:9
 rts

*======================================================
* Check to see if the contents of the current window need
* to be saved, and save them if so.

CheckSave
 ~GetWTitle WdwPtr ;get title for dialog
 PullLong FNSub
 Hdl_Ptr TEHdl;Ptr ;deref TE record
 ldy #$10
 lda [Ptr],y ;get ctrlFlag
 and #%01000000 ;...has record been modified?
 bfl :0
 ~AlertWindow #1;#FNSub;#DSave ; yes- should we save it?
 plx
 beq :save ; yes- do so
 dex
 beq :0 ; no, but continue anyway
:9
 sec
:0 rts ; no- abort whatever we're doing!
:save
 lda #3 ;handle as 'save' from menu!
 brl HFile

*======================================================
* Save the document data, including Styles if asked!

SaveData
 do TeaseWare
 brl DoTease ;no saving... only writes!
 else

 _WaitCursor ;show saving

 ~ZoomWindow WdwPtr ;insure proper Ruler settings

 jsr GetText ; (well-first check for no text)

 ~GetWTitle WdwPtr ;get name to save under
 pla
 plx
 bcs :g9 ;good window?
 ldy #TextName
 _CreateSFPath ;set path & get save name
 bcs :g9
 lda #$50 ;assume w/p
 ldx #'AQ'
 ldy SaveText ;correct?
 bfl :1
 lda #4 ; no- save as text
 ldx #0
:1
 sta CreateParms+8 ;set file & aux type
 stx CreateParms+10
 ~WriteFile #TextName;textH ;save text to data fork
:g9 bcs :9
 lda SaveText ;save as text only?
 bfl :7
 _GSOS _GetFileInfo;SFIParms
 lda SFIParms+10
 and #$FFFE        ; yes- set linker's ASM bit
 sta SFIParms+10
 _GSOS _SetFileInfo;SFIParms
 bra :8
:7
 jsr SaveStyle ; no- go write style info
 bcs :9
:8
 Hdl_Ptr TEHdl;Ptr ;point to TE record
 ldy #$10
 lda [Ptr],y ;saved...clear dirty flag!
 and #%10111111
 sta [Ptr],y
:xit
 ~ZoomWindow WdwPtr ;back to normal

 stz SaveText ;clear text only flag
 _InitCursor
 brl RemoveText ;get rid of that memory!
:9
 ~SysError #MWriting ;ohh... shit!
 bra :xit

*======================================================
* Save the style information to the resource fork
* of the appr. file.  styleH contains handle to styles

SaveStyle
 ~CreateResourceFile #'QA';#$50;#$C3;#TextName
 ~OpenResourceFile #0;#0;#TextName
 bcc :1
 cmp #eofEncountered ;empty?
 sec
 bne RClose
:1
 ~RemoveResource #rTEStyle;#1
 bcc :2
 cmp #resNotFound ;$63 -GS/OS
 beq :2
 cmp #$1E06 ;not found?
 sec
 bne RClose ; bad boy error!
:2
 ~AddResource styleH;#0;#rTEStyle;#1

 fin ;--- TEASEWARE ---
RClose
 plx
 php
 pha
 phx
 _CloseResourceFile ;File ID on stack
 pla
 plp
 rts

*======================================================
* Get the style information from WP file

LoadStyle
 ~OpenResourceFile #0;#0;#TextName
 bcs RClose
 ~LoadResource #rTEStyle;#1 ;try to load it
 PullLong styleH
 bcs RClose
 ~DetatchResource #rTEStyle;#1 ;take it from the system!
 bra RClose

*======================================================
* Get the text from the current document, and setup the
* selection information for use by somebody important.
* ENTRY: none (front window = text document to work with)
*  EXIT: bcs = error; selStart,selEnd = range, temp3 = # of banks

GetSelText ENT
 jsr GetText ;get text & style info

 jsr GetSelection ;get start & end of selection

 CmpLong selStart;selEnd
 bne :sel ;do we have a selection?
 stz selStart
 stz selStart+2
 MoveLong textLen;selEnd ; no- textualize entire doc!
:sel
 lda [Hdl]
 sta Ptr
 ldy #2 ;deref returned handle
 lda [Hdl],y
 clc ;insure offset into large buffer
 adc selStart+2
 sta Ptr+2

 lda selEnd+2
 sec
 sbc selStart+2 ;get # of banks to look thru
 sta temp3
 ldy selStart ;get inner bank offset
 clc
 rts

*======================================================
* Get the text and style records from the current window
* ENTRY: none
*  EXIT: textLen = length of text, HDL = copy of textH

GetText ENT
 ~TEGetText #%11101;#textH;#0;#3;#styleH;#0
 PullLong textLen
 bcs :9 ;get text OK?
 lda textLen
 ora textLen+2 ;do we have any text?
 bne :8
 brl EmptyDlg ; no- inform user
:8
 ldx textH
 stx Hdl ;save a few bytes...
 ldx textH+2
 stx Hdl+2
 rts
:9
 ~SysError #MGetTxt ;show user!
 pla
 bra RemoveText

*------------------------------------------------------
* Awwww... save a few bytes, make it easier... next LIB!
* ENTRY: textH, styleH = handles to text and style data
*  EXIT: textH and styleH are disposed, TE errors passed thru

SetText ENT
 ~TESetText #%01101;textH;#0;#1;styleH;#0

*------------------------------------------------------
* After we get it we usually need to free the memory again!

RemoveText ENT
 php ;save errors from SetText
 pha
 ~DisposeHandle textH ;get rid of that memory!
 ~DisposeHandle styleH
 pla
 plp
 rts

*======================================================
* Get some information about the current TE record

GetTEInfo ENT
 ~TEGetTextInfo #TEInfoRec;#5;#0
 bcc :1
 ~SysError #MTEInfo ;oh... damnation!
:2
 rts
:1
 lda TEInfoRec
 ora TEInfoRec+2 ;anything in document?
 btr :2

*------------------------------------------------------
* Show user file is empty!

EmptyDlg
 _InitCursor  ;probably a watch...

 ~NewAlert #DEmpty ;inform user
 pla ; & skip calling routine!
 sec
 bra RemoveText

*======================================================
* Get or set the selection area in the current TE window

GetSelection ENT
 ~TEGetSelection #selStart;#selEnd;#0
 rts

SetSelection ENT
 ~TEScroll #1;selStart;#0;#0
 ~TESetSelection selStart;selEnd;#0
 rts

*======================================================
* Enable our menus to allow normal operation

EnableMenus
 lda FrontWdw ;we already do this?
 bfl :1
 rts
:1
 stz FrontWdw ; no- we will now
 dec FrontWdw
 ldx #-1
 lda #$FF7F ;turn them on!
 bra SetMens

*======================================================
* Disable our menus so we can't screw things up (ie, DAs, no window)

DisableMenus
 lda FrontWdw ;we already do this?
 btr :1
 lda SysWdw ;system window?
 cmp :wdw
 sta :wdw ; (not already done)
 bne :1
 rts
:1
 stz FrontWdw ; no- we will now

 ldx #0
 lda #$80 ;turn them off!
 bra SetMens

:wdw ds 2
*------------------------------------------------------
* Set menus according to Acc. value

SetMens
 psl #0 ;end of list flag

 do TeaseWare
 else ;leave save/print items disabled
 pea #258
 phx
 pea #259
 phx
 pea #260
 phx
 pea #261
 phx
 fin ;--- TEASEWARE ---

 pea #262
 phx
 pea #263
 phx
 ldx #0
 bit SysWdw
 bmi :1
 ldx #-1
:1 pea #270
 phx
 pea #265
 phx

 pea #0 ;end of list flag
 pha
 pea #SrcMenu ;dis/enable some menus
 _SetMenus ;stack 'em up!
 _SetMItems
 rts

*======================================================
* Update our text window

UpdateWin
 ~DrawControls TaskRc+16 ;update is easy!
 rtl

*======================================================
* Print the loaded text to the printer, via Print Manager

PrintText
 do TeaseWare
 brl DoTease
 else

 ~PrValidate PrtHdl ;insure a good record
 plx
 bcs :zpe1

 ~PrJobDialog PrtHdl ;get user's printing options
 plx
 bcs :PE1 ;error?
 txa
 btr :GoForIt ;cancel?
 rts
:GoForIt
 _WaitCursor

 ~ZoomWindow WdwPtr ;[][ work around TE bug ][]

* Open the 'print document' and start printing our information

 ~PrOpenDoc PrtHdl;#0 ;open new grafPort for printing
 PullLong PPort
:zpe1 bcs :PE1

 Hdl_Ptr PrtHdl;Ptr ;Dereference the print record
 ldy #6+2+6
 ldx #8-2
]loop lda [Ptr],y ;copy page rectangle to our area
 sta QuitPath,x
 dey
 dey
 dex
 dex
 bpl ]loop

 stz temp ;starting line # = 0
 stz temp+2
:NewPage
 ~PrOpenPage PPort;#0 ;open a new page to print on
:PE1 bcs :eof

 ~TEPaintText PPort;temp;#QuitPath;#0;TEHdl
 PullLong temp
 bpl :ok
 lda #$2209 ;x = $FFFF at EOF!
:ok
 pha
 ~PrClosePage PPort ;close the current page
 pla
 bfl :NewPage ;error or EOF?
 cmp #$2209
 clc
 beq :eof
 sec ; no- real error!
:eof
 php
 pha
 ~PrCloseDoc PPort ; yes- close entire printed document
 pla
 plp
 bcs :err

 ~PrPicFile PrtHdl;#0;#StatusRec ;print file to the printer!
 bcc :done
:err
 cmp #$80 ;ok if just a Cancel (oA-.) command
 beq :done
 pha
 pha
 _PrSetError ;abort printing w/proper error
 pla
 ora #$8000
 ~SysError #MPrint ;show user our error!
:done
 ~ZoomWindow WdwPtr ;[][ undo TE bug fix ][]
 _InitCursor
 rts

 fin ;--- TeaseWare ---

*======================================================
* This is our tool record for the Startup call

SSRec
 dw 0
 dw $C080 ;640 & do it as fast as possible!
 dw 0
 adrl 0 ;dpage handle
 dw :sse-*/4 ;number of tools

 dw 10,$0100 ;SANE
 dw 04,$0300 ;quickdraw
 dw 18,$0206 ;qdaux
 dw 06,$0300 ;event
 dw 27,$0300 ;font
 dw 14,$0300 ;window
 dw 16,$0300 ;control
 dw 15,$0300 ;menu
 dw 28,$0300 ;list
 dw 20,$0300 ;lined
 dw 21,$0101 ;dialog
 dw 22,$0104 ;scrap
 dw 05,$0101 ;desk
 dw 23,$0101 ;file
 dw 19,$0200 ;print manager
 dw 34,$0100 ;TextEdit
:sse
*------------------------------------------------------
* Menu definitions

Menus
 adrl MWindow
 adrl MTran
 adrl MGSOS
 adrl MTool
 adrl MSrc
 adrl MProj
 adrl MEdit
 adrl MFile
 adrl MApple
 adrl 0

* We use the following to get our menu indexes

MenuNums
 dw AppleMenu
 dw FileMenu
 dw EditMenu
 dw ProjMenu
 dw SrcMenu
 dw ToolMenu
 dw GSOSMenu
 dw TranMenu
 dw WindowMenu

MaxMenus dw *-MenuNums ;used to insure we don't bomb!

HdlMenus
 da HApple
 da HFile
 da HEdit
 da HProj
 da HSrc
 da HTool
 da HGSOS
 da HTran
 da HWdwMenu

*------------------------------------------------------
MApple
 asc '$$@\XN300',00
 asc '--About QuickASM...\N300',00
 asc '--Help...\N301*HhVD',00
 asc '>'
MFile
 asc '$$  File \N255',00
 asc '--New\N256*Nn',00
 asc '--Open...\N257*Oo',00
 asc '--Close\N255*`~V',00
 asc '--Save\N258*SsD',00
 asc '--Save As...\N259D',00
 asc '--Write Text\N260*WwD',00
 asc '--Write As...\N261DV',00
 asc '--Append...\N262',00
 asc '--Revert\N263',00
 asc '--Page Setup...\N264',00
 asc '--Print...\N265*PpDV',00
 asc '--Shutdown\N266',00
 asc '--Quit\N267*Qq',00
 asc '>'
MEdit
 asc '$$  Edit \N250',00
 asc '--Undo\N250*ZzVD',00
 asc '--Cut\N251*Xx',00
 asc '--Copy\N252*Cc',00
 asc '--Paste\N253*Vv',00
 asc '--Clear\N254',00
 asc '--Select All\N270',00
 asc '>'
MProj
 asc '$$  Project \N400',00
 asc '--New\N400D',00
 asc '--Open...\N401D',00
 asc '--Close\N402VD',00
 asc '--Save\N403D',00
 asc '--Save As...\N404VD',00
 asc '--Build Project\N405*Bb',00
 asc '--Build other...\N410',00
 asc '--Options...\N406VD',00
 asc '--Add Window\N407D',00
 asc '--Add File...\N408D',00
 asc '--Remove Window\N409D',00
 asc '>'
MSrc
 asc '$$  Source \N500',00
 asc '--Find...\N500*Ff',00
 asc '--Find Again\N501*Gg',00
 asc '--Find & Replace\N502*Rr',00
 asc '--Replace All\N503',00
 asc '--Go Label/Line\N516*LlV',00
 asc '--Assemble\N515*Aa',00
 asc '--Margins & Tabs\N504*Mm',00
 asc '--Fix Source\N505*Yy',00
 asc '--Information\N506*IiV',00
 asc '--Type Style...\N507V',00
 asc '--Black\N508',00
 asc '--Blue\N509',00
 asc '--Red\N510',00
 asc '--Violet\N511',00
 asc '--Green\N512',00
 asc '--Jade\N513',00
 asc '--L.Grey\N514',00
 asc '>'
MTool
 asc '$$  Tools \N600',00
 asc '--Execute Tool...\N600VD',00
 asc '>'
MGSOS
 asc '$$  GS/OS \N700',00
 asc '--Delete...\N700*Dd',00
 asc '--Rename...\N701VD',00
 asc '--Format Disk\N702D',00
 asc '>'
MTran
 asc '$$  Transfer \N800',00
 asc '--Launch...\N800*=+V',00
 asc '--Merlin 16+\N801D',00
 asc '>'
MWindow
 asc '$$  Windows \N5000',00
 asc '--Stack Windows\N5000*Kk',00
 asc '--Edit Next Doc\N5001*Ee',00
 asc '--Text Mode\N5002*TtV',00
 asc '>'
NewWdw
 asc '--New Window\H'
NWID hex FACE00

*------------------------------------------------------
WindowParms
 da WindowEnd-WindowParms
 da %1100001110100100
WdwTtl adrl MWOpen
 adrl 0
 da 25,1,199,639
 adrl 0
 da 0
 da 0
 da 0
 da 0
 da 0
 da 0
 da 9
 da 0
 da 162
 da 0
 adrl 0
 da 0
 adrl 0
 adrl 0
 adrl UpdateWin
WdwRec da 25,1,199,639
 adrl -1
 adrl 0
WindowEnd

CmdTitle strl ' Commands '
ErrTitle strl ' Errors '
*------------------------------------------------------
* The TextEdit window control definition

TETemplate
 dw 17
 adrl TECtrlID
 dw 0,0,0,0
 adrl $85000000
 dw 0
 dw %0111110000000000
 adrl 0
 adrl %01000010001000000000000000000000
 dw 2,4,2,4
 adrl $FFFFFFFF
 dw 0
 adrl 0
 dw 0
 adrl 0
 dw 0
 adrl 0
 adrl 0
TEMaxChrs adrl 0 ;modified

*======================================================
* About dialog to give credit where due

DAbout
 dw 40,25,115,270
 dw 1
 hex 80,80,80,80
 adrl :3
 adrl :1
 adrl :2
 adrl 0

:2 dw 1
 dw 0,0,75,245
 dw $A
 adrl :2a
 dw 0
 dw 0
 adrl 0
:2a str ''

:3 dw 2
 dw 0,0,75,245
 dw $F
 adrl :2a
 dw 0
 dw 0
 adrl 0
:1
 dw 3
 dw 5,3,72,243
 dw $8016
AMod adrl Anorm
 dw anz-Anorm
 dw 0
 adrl 0
Anorm
 hex 01530300,014A0100
 asc 'QuickASM Shell',AA,' v0.70'
 hex 01530000,0D0D
 asc ,'Portions are Copyright ',A9,' 1988-90'
 hex 0D,01430100
 asc 'Ideas From the Deep'
 hex 01430000
 asc ' & '
 hex 01430200
 asc 'Lane Roath'
 hex 01430000,0d0d
 asc 'QuickASM system written by ',0D
 asc 'Shawn Quick and Lane Roath'
anz
Aspcl
 hex 014A0100
 asc 'QuickASM written in QuickAsm ',0D
 asc '& Merlin 16+.  Dated '
 date 5 ;dd-mmm-yy
 hex 0d0d
 hex 0153020001430100
 asc /"Will you still need me, will you /
 asc /still feed me, when I'm 64?"/,0D
 asc /Sgt. Pepper's Lonely Hearts Club Band /
 asc / \ When I'm 64 \ Beatles/
asz
*======================================================
* Misc. NewAlert dialog templates

 do TeaseWare
DTease
 asc '80\'
 asc 'This version has this stupid message everywhere to '
 asc 'remind you that this is a PRELIMINARY version of '
 asc 'QuickASM.  Please contact us to purchase the final copy '
 asc 'or to report bugs and/or suggest inprovements! ',0D0D
 asc 'Ideas From the Deep - '
 asc '309 Oak Ridge Lane  / Haughton  / LA  / 71037',0D
 asc 'Phone: (318) 949-8264',0D,'(if no answer, leave message)\'
 asc '^#0',00

 fin ;--- tease dialog ---

DWarning ENT
 asc '54/'
 asc 'This operation could damage the document '
 asc 'contents!  Are you sure you wish to do this?/'
 asc '^#6/#1',00
DSave
 asc '55$'
 asc '"*0" has been changed!  Should I save it?$'
 asc '^#2$#3$#1',00
DEOF ENT
 asc '13/'
 asc 'No more matches!/'
 asc '^#0',00
DEmpty
 asc '14/'
 asc 'File Empty!/'
 asc '^#0',00
FNSub ENT
 adrl 0 ;filled in!

*------------------------------------------------------
* Our GS/OS parm tables (NOTE: Class 1 now!)

SFIParms dw 4
 adrl TextName
 ds 8

TxtTypes ENT
 dw 3
 dw $8000
 dw $04
 adrl 0
 dw $8000 ;we read these types of files
 dw $B0
 adrl 0
 dw $8000
 dw $50
 adrl 0
AllTypes ENT
 dw 1
 dw $C000 ;we can delete anything!
 dw 0
 adrl 0

*------------------------------------------------------
* Error message text

 ENT MFOpen

MQuit str 'Quit'
MMenu str 'Menu #'
MWOpen str 'Opening Window'
MFOpen str 'Open File'
MGetTxt str 'GetText'
MClose str 'Close Wdw'
MPInit str 'Init PrRec'
MPrint str 'Printing'
MWTitle str 'Wdw Title'
MWriting str 'Writting!'
MGetWindow str 'Get Wdw'
MTEInfo str 'TEInfo'
QAError str 'QA Startup'

OpenPrompt str 'Open the file...'
SavePrompt str 'Save file as...'
AppendPrompt str 'Append the file...'

NewName strl 'Untitled.@'

*======================================================
* The following are equates to use DS w/no code space

 ENT tFind,tReplace,TextName,TextPath,QuitPath,PrintBuf

 dum * ;we DS this in the link file

QuitParms ds 8
SDParms ds 4

WdwIDNum ds 2 ;so Cmd,Err,Source wdws have unique IDs

tFind ds 30 ;oh-no!
tReplace ds 30

TextName ds 32 ;Class 1 file & path buffers
TextPath ds 256
CmdLine ENT
QuitPath ds 128 ;dup of above, for saves!!!
TEInfoRec ENT ;textedit info record
StatusRec ds 128 ;Used by printing routines
TempBuf ENT
PrintBuf ds 256
*------------------------------------------------------
* Text Edit records we use

 ENT NewStyle,textH,styleH,rulerH,selStart,selEnd,myDP

NewStyle ds 12

textH ds 4 ;handles that can't be in DP!
styleH ds 4
rulerH ds 4

selStart ds 4 ;text selection info
selEnd ds 4

myDP ds 2 ;page in bank 0 of my DP
DS_Size ENT
 dend

 sav 2/obj/qasm.l
