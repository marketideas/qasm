 lst off
 ttl "QASM Menu Routines"
 exp off
 tr on
 cas se
* dup
*======================================================
* Graphic Shell for QuickASM development system

* Programming by Lane Roath
* Copyright (c) 1990 Ideas From the Deep & Lane Roath
*------------------------------------------------------
* 22-Feb-90 0.20 :remove from main file
*======================================================

 rel

Class1 = $2000

 lst off
 use 2/data/qa.equates
 use macs
 use ifd.equs
 use equs
 lst rtn

 EXT TextName,TextPath,GetTEInfo,GetSelection,selStart,selEnd
 EXT SetSelection,DWarning,GetSelText,SetText,tFind,Shell
 EXT NewStyle,AllTypes,FNSub,tReplace,rulerH,DEOF
 EXT QuitPath,MFOpen,HFile,TEInfoRec,RemoveText,GetText
 EXT textH,TxtTypes

*======================================================
* Handle the find menu (find & replace stuff)

HProj ENT
 cmp #-1 ;open finder doc?
 bne :0

 lda TextName ; yes- special case it!
 tax
 clc ;get length of window title
 adc TextPath
 sta TextPath
 tay
]loop lda TextName+1,x ; & append filename to prefix
 sta TextPath+1,y
 dey
 dex ;done?
 bne ]loop
 bra :DoOpen ; yes- open doc!
:0
 asl ;create index
 tax
 jmp (:tbl,x) ; & pass control to item handler
:tbl
 da :New
 da :Open
 da :Close
 da :Save
 da :Save_As
 da :Build
 da :Options
 da :AddWdw
 da :AddFile
 da :Remove
 da :Other

*------------------------------------------------------
:New
 rts
*------------------------------------------------------
:Open
:DoOpen ;finder entry
 rts
*------------------------------------------------------
:Close
 rts
*------------------------------------------------------
:Save
 rts
*------------------------------------------------------
:Save_As
 rts
*------------------------------------------------------
:Build
* ~PutFile #:BuildAs;#TextName
* bcs :err
* bfl :xit
 ~QASetCancelFlag #0 ;haven't done so yet!
 _QAClearKey
 ~SelectWindow CmdPtr
 jsr pTextPath
 ~QALink #lquick;#TextPath ; yes- link it
 jsr pTextPath
 bcc :xit
:err
 ~SysError #:lerr ;show any errors
:xit
 rts

:BuildAs str 'Save Application as...'
*------------------------------------------------------
:Other
 ~GetFile #:Prompt;#TextName;#TxtTypes
 bcs :err
 bfl :xit
 ~QASetCancelFlag #0 ;haven't done so yet!
 _QAClearKey
 ~SelectWindow CmdPtr ;must have this in forground!
 jsr pTextPath
 ~QALink #lfromname;#TextPath-1
 jsr pTextPath
 bcs :err
 rts

:Prompt str 'Link the file...'
:lerr str 'Linking'

*------------------------------------------------------
:Options
 rts
*------------------------------------------------------
:AddWdw
 rts
*------------------------------------------------------
:AddFile
 rts
*------------------------------------------------------
:Remove
 rts

*======================================================
* Handle the find menu (find & replace stuff)

HSrc ENT
 asl ;create index
 tax
 jmp (:tbl,x) ; & pass control to item handler
:tbl
 da :Find
 da :Find_Again
 da :Replace
 da :Replace_All
 da :Tabs
 da :Fix
 da :Info
 da :Font
 da :Color
 da :Color
 da :Color
 da :Color
 da :Color
 da :Color
 da :Color
 da :Assem
 da :Line

*------------------------------------------------------
:Find
 jsr GetTEInfo
 brl FRDialog ; yes- only if doc not empty!
*------------------------------------------------------
:Find_Again
 ldx tFLen ;anything to search for?
 beq :Find
 jmp FindNext ; yes- do so
*------------------------------------------------------
:Replace
 ldx tFLen ;anything to search for?
 beq :Find
:doReplace
 jsr FindNext ;can we find a match?
 bcs :2x
 ~TEReplace #%101;#tReplace+1;tRLen;#0;#0;#0 ;YES-replace it!
 bcs :2y
 lda selStart
 adc tRLen ;get start/end of replaced
 sta selEnd
 lda selStart+2 ; text (old start & len of new)
 adc #0
 sta selEnd+2
 jsr SetSelection ;hilite the new text for user
 bcc :2x
:2y
 ~SysError #:FR ;oh shit!
:2x rts

:FR str 'Search'

*------------------------------------------------------
:Replace_All
 ldx tFLen ;anything to search for?
 beq :Find
]loop jsr :doReplace ;do one replace
 bcc ]loop
 rts ; & repeat till error

*------------------------------------------------------
:Tabs
 brl MTDialog ; yes- do it w/dialog

*------------------------------------------------------
* Fix text so it will display as true ASCII, not garbage

:Fix
 stz temp ;assume no selection

 ~NewAlert #DWarning ;warn use undo-able!
 bne :2z

 _WaitCursor  ;show we're working

 jsr GetSelText ;get text (selection)
 bcs :2c

 SHORTM
]loop
 lda [Ptr],y ;get a character
 cmp #" "
 bne :f0
 lda #9 ;merlin spaces to tabs!
:f0 and #$7F
 sta [Ptr],y ;store TE readable value
 iny
 bne :f1 ;update bank byte?
 inc Ptr+2
:f1 cpy selEnd ;are we done?
 bne ]loop
 dec temp3 ; (must also check bank!)
 bpl ]loop

 LONGM

 jsr SetText ;replace text & style info
 Hdl_Ptr TEHdl;Ptr
 ldy #$10
 lda [Ptr],y ;show we changed the text
 ora #%01000000
 sta [Ptr],y
:2c
 _InitCursor
 rts

*------------------------------------------------------
:Info
 jsr SetInfo ; yes- set info for dialog
 lda textLen
 ora textLen+2 ;did we get anything?
 bfl :2z
 ~Alert #InfoAlert;#0 ; yes- show user some cool stuff
 pla
:2z
 rts

*------------------------------------------------------
:Font
 jsr GetStyle
 ~ChooseFont NewStyle;#0 ; yes- allow user to do so
 PullLong NewStyle
 bcs :9
 txa
 ora NewStyle ;cancel?
 bfl :fx
 lda #%1100010 ; no, update TE record
 brl SetStyle
:9
 ~SysError #:TEStyle ;oops!
:fx rts

:TEStyle str 'SetStyle'

*------------------------------------------------------
:Color
 sbc #8 ;create index value
 asl
 tax
 lda :colors,x ;get color word
 tax
 lda TaskRc+14 ;option key pressed?
 and #%0000100000000000
 bfl :fore
 stx NewStyle+6 ; yes- change background color
 lda #%00001000
 brl SetStyle
:fore
 stx NewStyle+4
 lda #%00010000 ; no- change foreground color
 brl SetStyle
:colors
 dw $0000,$1111,$4444,$5555,$8888,$9999,$CCCC

*------------------------------------------------------
* Assemble the current source (window)

:Assem
 ~QASetCancelFlag #0 ;haven't done so yet!

 lda FrontWdw ;do we have a window open?
 bfl :sfile
 jsr GetText
 ~SelectWindow CmdPtr ;bring cmd wdw to front!
 _QAClearKey
 ~QACompile #afromhandle;textH ; & assemble source
 jsr RemoveText
 bcc :xit
:err
 ~SysError #:aerr ;show any errors
:xit
 rts
:sfile
 ~GetFile #:Prompt;#TextName;#TxtTypes
 bcs :err
 bfl :xit
 ~SelectWindow CmdPtr ;must have this in forground!
 ~QACompile #afromname;#TextPath
 bcs :err
 rts

:Prompt str 'Assemble the file...'
:aerr str 'Assembling'

*------------------------------------------------------
* Jump to line # in current source window

:Line
 jsr GetTEInfo
 brl LLDialog ;only if doc not empty!

*======================================================
* Handle the TOOL menu added items!

HTool ENT
 bne :added
 ~GetFile #:Prompt;#TextName;#:Types
 bcs :err
 bfl :xit
:xit
 rts
:added
 rts
:err
 ~SysError #MFOpen ;oops!
 rts

*------------------------------------------------------
:Prompt
 str 'Execute the tool...'
:Types
 dw 1
 dw $8000 ;any aux type
 dw $B2
 adrl 0

*======================================================
* Handle the GS/OS menu

HGSOS ENT
 asl ;create index
 tax
 jmp (:tbl,x) ; & pass control to item handler
:tbl
 da :Delete
 da :Rename
 da :Format

*------------------------------------------------------
:Delete
 ~GetFile #:DPrompt;#TextName;#AllTypes
 bcs :de
 bfl :nodel
 lax #TextPath+1
 sax FNSub
 lda TextPath
 xba ;create PString
 sta TextPath
 ~AlertWindow #1;#FNSub;#:DDelete ; yes- should we save it?
 plx
 bcs :de
 btr :Delete
 _WaitCursor
 _GSOS _Destroy;:DelParms ;...delete the file!...
 pha
 _InitCursor
 lda TextPath
 xba ;restore real pathname
 sta TextPath
 pla
 bfl :Delete
:de
 ~SysError #:Del ;show errors
:nodel
 rts
*------------------------------------------------------
:Rename
 rts
*------------------------------------------------------
:Format
 rts
*------------------------------------------------------
:DPrompt
 str 'Delete the file...'
:DDelete
 asc '55$'
 asc 'Are you sure you wish to delete the file *0 ?$'
 asc '#6$^#1',00
:DelParms
 dw 1
 adrl TextName
:Del str 'Delete'

*======================================================
* Handle the LAUNCH menu

HTran ENT
 bne :parmfile ;other than zero special!
 ~GetFile #:Prompt;#TextName;#:Types
 bcs :SFErr
 bfl :xit
 bra :SetLaunch ; yes-setup to launch properly
:SFErr
 ~SysError #MFOpen ;oops!
:xit rts
:parmfile
 rts

*------------------------------------------------------
:Prompt
 str 'Launch...'
:Types
 dw 2
 dw $8000
 dw $FF
 adrl 0 ;we can launch these file types
 dw $8000
 dw $B3
 adrl 0

*------------------------------------------------------
* Setup the quit parms to launch another program

:SetLaunch
* ldx TextPath
* stx QuitPath ;copy length
* SHORTM
*]loop lda TextPath+1,x ;copy to safe buffer
* sta QuitPath+1,x
* dex ; done?
* bne ]loop
* LONGM

 ldy #$C000 ;assume sublaunch
 lda TaskRc+14
 and #%0000100000000000
 bfl :slx ;option key = simple launch
 ldy #$8000
:slx
 sty temp
 ~QASetLaunch #QuitPath;temp ;tell QA to do launch
 lda #267-FileMenu
 jmp HFile   ; & fake QUIT menu selection

*======================================================
* Set a ruler styling.
* ENTRY: A = ruler value, Y = index into ruler record
*  EXIT: none

SetRuler ENT
 pha ;save parms
 phy
 _WaitCursor
 ~TEGetRuler #3;#rulerH;#0 ;get ruler
 bcc :ok
 ply
 plx ;exit w/parms saved
 bra rerr
:ok
 MoveLong rulerH;Hdl ;get into DP
 Hdl_Ptr Hdl;Ptr
 ply ;get offset to justify type
 pla
 sta [Ptr],y ; & set for this file
mySetRuler ENT
 ~TESetRuler #1;Hdl;TEHdl ;all done!
 bcc ne
rerr
 ~SysError #MRuler ;show errors
ne
 ~DisposeHandle Hdl ;hey- we don't want it anymore!
 _InitCursor
 rts

MRuler str 'SetRuler'
*======================================================
* Set style of current TE record seletion
* ENTRY: A = style flags, NewStyle = new style record
*  EXIT: none

SetStyle ENT
 sta temp
 _WaitCursor
 ~TEStyleChange temp;#NewStyle;#0
 _InitCursor
 rts

*======================================================
* Get the current TE record selection's style info.
* ENTRY: none
*  Exit: none

GetStyle
 ~NewHandle #1024;ID3;#0;#0 ;who cares!
 PullLong Hdl
 bcs :9
 ~TEGetSelStyle #NewStyle;Hdl;#0
 plx
 stx temp ;get style return flags
 bcc :1
:9
 ~SysError #:GetStyle ;ooops!
:1
 ~DisposeHandle Hdl ;we don't care!

 lsr temp
 bcs :2 ;attr. valid?
 SHORTM
 stz NewStyle+2 ; no- zap it
 LONGM
:2
 lsr temp ;user data valid?
 bcs :3
 stz NewStyle+8 ; no- zap old data
 stz NewStyle+10
:3
 lsr temp ;backcolor valid?
 bcs :4
 stz NewStyle+6 ; no- zap it
:4
 lsr temp ;forecolor valid?
 bcs :5
 stz NewStyle+4 ; no- ignore it
:5
 lsr temp ;font family valid?
 bcs :7
 stz NewStyle ; no- ignore it
:7
 rts

:GetStyle str 'GetStyle'

*======================================================
* Create a pString or gString of TextPath, depending.

pTextPath ENT
 pha
 lda TextPath
 xba ;[][ Linker not Class1 yet ][]
 sta TextPath
 pla
 rts

*======================================================
* Find the next occurance after the current selection
* of the string in the find buffer.
* ENTRY: none
*  EXIT: selStart/End = offset range of find, bcs = no find

FindNext
 lda FromTop ;start at top?
 btr :top
 jsr GetSelection ; no- start search at end of selection
:top
 jsr GetText ;get the text to search through

 CmpLong selEnd;textLen ;do this?
 blt :doit
 brl :eof ; no- done!
:doit
 lda [Hdl]
 sta Ptr
 ldy #2 ;get TRUE starting location
 lda [Hdl],y
 clc
 adc selEnd+2 ; (ie, adj. for bank)
 sta Ptr+2

 lda textLen+2
 sec
 sbc selEnd+2 ;get # of banks to search
 sta temp3

 SHORTM
 lda CaseFlg ;case insensitive?
 bfl :no
 lda #$7F ; yes- set stuff
 ldx #'_'
 bra :set
:no
 lda #$FF ; no- dissuade code from working
 tax
:set sta :cm1+1
 txa
 sta :cm2+1 ;set ANDs appropriately

 ldy selEnd
:initx
 ldx #1 ;init indexes
]loop
 iny
 bne :ckeof ;update text pointers
 inc Ptr+2
 inc selEnd+2 ;update selection as needed
:ckeof
 cpy textLen ;are we at the EOF?
 bne :getchar
 dec temp3 ; well, past first 64K anyway
 bmi :eof
:getchar
 lda [Ptr],y ;get a char
:cm1 and #$7F
 cmp #'`'+1 ;upper?
 blt :nocnv
:cm2 and #'_' ; yes- force lower
:nocnv
 cmp tFind,x ;does it match?
 bne :initx
 cpx #1 ; yes, fist match?
 bne :no1st
 LONGM
 lda selEnd+2 ; yes- save selection
 sta selStart+2
 sty selStart ; for highlighting
 tya
 dec ;backup one
 clc
 adc Ptr
 sta temp2 ; & set pointer for word checks!
 lda Ptr+2
 adc #0
 sta temp2+2 ; & set zero page for word check
 SHORTM
:no1st
 cpx tFLen ;have we found the entire string?
 inx
 blt ]loop ; no- keep going!
:fnd
 lda LabelFlg ;looking for label?
 bfl :nolbl
 lda [temp2] ; yes, is prev. char a CR?
 cmp #$0D
 bne :initx ; no- not found!
:nolbl
 lda WordFlg ;looking for words?
 bfl :found
 jsr :checkword ; yes- do we have one?
 bfl :initx
:found
 LONGM
 iny ; (must go past last char!)
 sty selEnd
 jsr SetSelection ;show user where selection found!
 bra :bye
:eof
 REP #$30
 ~NewAlert #DEOF ;show user EOF reached
 sec
:bye
 jmp RemoveText ; & exit w/all restored

*------------------------------------------------------
* Check to see if where we now point is a word or just
* part of a word intermixed within some text.

 MX %11 ;in emulation!!!
:checkword
 iny
 lda [Ptr],y ;get char after word
 cmp #'-'
 beq :w0 ;dash?
 cmp #"'"&$7F
 beq :w0
 cmp #'`' ;check for stupid quotes
 bne :w1
:w0
 iny
 lda [Ptr],y ;is this a lonely quote/dash?
 dey
 cmp #' '+1
 blt :w2 ; yes- could be a word
:noword
 dey
 lda #0 ; no- return w/bfl
 rts
:w1
 cmp #'0'
 blt :w2 ;can't be a number
 cmp #'9'+1
 blt :noword
 cmp #'A'
 blt :w2 ;can't be a letter
 cmp #'Z'+1
 blt :noword
 cmp #'a'
 blt :w2 ; (upper or lower case!)
 cmp #'z'+1
 blt :noword
:w2
 lda selStart ;at TOF?
 ora selStart+1
 beq :word
 lda [temp2] ; no- get char before 'word'
 cmp #'0'
 blt :word ;can't be a number
 cmp #'9'+1
 blt :noword
 cmp #'A'
 blt :word ;can't be a letter
 cmp #'Z'+1
 blt :noword
 cmp #'a'
 blt :word ; (upper or lower case!)
 cmp #'z'+1
 blt :noword
:word
 dey ;return normal
 lda #1
 rts

 MX %00 ;back to native!
:justs
 dw 2,0,-1,1

*======================================================
* Bring up the Find and Replace dialog & get user's input

FRDialog
 ~GetNewModalDialog #FindDialog
 PullLong Ptr
 bcc :0
:err
 ~SysError #:FRDlg ;error?
 rts
:0
*---------------------------------------------------------------------
* make the text you got last time the default text

 ~SelectIText Ptr;#5;#0;#-1 ;select the find text
 bcs :err
 ldx #$8000
 lda CaseFlg
 jsr SetDIValue ;set check marks
 ldx #$8002
 lda FromTop
 jsr SetDIValue
 ldx #$8004
 lda WordFlg
 jsr SetDIValue
 ~ShowWindow Ptr ;now show the dialog
 bcs :err
:1
 ~ModalDialog #0 ;let user do his/her thing
 pla
 bmi :check
 cmp #2 ;was it cancel?
 beq :Quit
 cmp #1 ;wait for one of the find
 beq :2
 cmp #4+1 ; or replace buttons
 bge :1
:2
 sta :t
 jsr :SaveText ;save find/replace text
 bfl :1
 pea #:dofind-1 ; & go find whatever it is
:Quit
 ~CloseDialog Ptr
 rts

:t dw 0 ;can't use stack!

*------------------------------------------------------
* handle the checking of the boxes, senor.
*  enter with the ID of the check box in the accumulator

:check
 sta temp ;save for use

 ~GetDItemValue Ptr;temp ;get value of item
 lda temp
 and #$FF ;get index into flags
 tax
 pla
 eor #1 ;invert the value bit
 sta CaseFlg,x
 ldx temp
 jsr SetDIValue
 brl :1

*------------------------------------------------------
* Save the find/replace text so we always have them!

:SaveText
 ~GrabText #5;#tFind
 ~GrabText #6;#tReplace
 lda tFind
 and #$FF
 sta tFLen ;any text to find?
 bfl :no
 jsr CaseFind ; yes -case it as desired
 lda tReplace
 and #$FF
 sta tRLen ; & set replace length as needed
 stz tRLen+2
 lda #1 ;set BTR flag
:no
 rts

*=====================================================================
* find the word that they want to see.

:dofind
 stz selEnd ;assume start search @ top
 stz selEnd+2
 stz LabelFlg ;show NOT a label

 lda :t ;get button #
 dec
 bne :10 ;find = # 1
 inc
:10 jmp HSrc ;handle as menu selection

:FRDlg str 'FRDialog'

*------------------------------------------------------
* Make the FIND text case insensitive

CaseFind
 lda CaseFlg
 bfl :nocase
 ldx tFLen
 SHORTM
]loop lda tFind,x ; yes- transform search string
 and #$7F
 cmp #'`'+1 ;upper?
 blt :nocnv
 and #'_' ; yes- force lower
:nocnv sta tFind,x
 dex ;done?
 bne ]loop
 LONGM ; yes- back to normal
:nocase
 rts

*======================================================
* Bring up the Label/Line # dialog & get user's input

LLDialog
 ~GetNewModalDialog #LineDialog
 PullLong Ptr
 bcc :0
:err
 ~SysError #:LLDlg ;error?
 rts
:0
*---------------------------------------------------------------------
* make the text you got last time the default text

 ~SelectIText Ptr;#3;#0;#-1 ;select the find text
 bcs :err
:1
 ~ModalDialog #0 ;let user do his/her thing
 pla
 cmp #2 ;was it cancel?
 beq :Quit
 dec  ; no- was it just an event?
 bne :1
 jsr :SaveText ;save find/replace text
 bfl :1
 pea #:dofind-1 ; & go find whatever it is
:Quit
 ~CloseDialog Ptr
 rts

*------------------------------------------------------
* Save the find/replace text so we always have them!

:SaveText
 ~GrabText #3;#tFind
 lda tFind
 and #$FF
 sta tFLen
 stz tRLen ;no replacing!
 stz tRLen+2
 rts

*------------------------------------------------------
* find the word that they want to see.

:dofind
 lda tFind+1
 and #$7F
 cmp #'9'+1 ;line # or label?
 blt :line

 dec LabelFlg ;label -tell 'FIND' about it!
 jsr CaseFind

 lda #1
 sta FromTop ;always search from top!
 stz selEnd
 stz selEnd+2
 jmp HSrc ; & handle as simple 'find'

:LLDlg str 'LLDialog'

*------------------------------------------------------
* Display line # @ center of screen
* Based on DISPLAY, not CRs, but this is faster & memory efficient!

:line
 stz temp3 ;init value

 ldx #0 ;start w/first digit
]loop
 lda tFind+1,x ;get a char
 and #$7F
 cmp #'0'
 blt :done ; is it a number?
 cmp #'9'+1
 bge :done
 and #$F
 sta temp3+2 ; yes- get hex digit
 lda temp3
 asl
 sta temp3 ;multiply current value by 10
 asl
 asl
 adc temp3
 adc temp3+2 ;add in new digit
 sta temp3
 inx
 cpx tFLen ;are we done?
 blt ]loop
:done
 stz temp3+2 ; yes- zap high word

 ~TEScroll #3;temp3;#0;#0 ; & show line!
 rts

* ldy #$10+4
* lda [WdwPtr],y ;depth of window (top = 0)
* lsr
* sta temp ; / 2 = middle of window
* stz temp+2
*
* ~TEPointToOffset temp;#0;#0
* PullLong selStart
* bcs :oops
* ~TEPointToOffset temp;#1000;#0 ;get offsets to start & end of line
* PullLong selEnd
* bcs :oops
* jmp SetSelection ; & highlight the line!
*:oops
* ~SysError #:lerr
* rts
*
*:lerr str 'GOTO line'

*======================================================
* Handle the magins & tabs dialog.

MTDialog
 ~TEGetRuler #3;#rulerH;#0 ;get ruler
 bcc :ok
 brl :err
:ok
 MoveLong rulerH;Hdl
 ~HLock Hdl ;lock & make usable

 lda #6
 sta DecLeft
 sta DecIndent
 sta DecRight ;they could be bogus
 sta DecLine
 sta DecTabs

 Hdl_Ptr Hdl;temp3

 lda [temp3],y ;create 'user-friendly' value
 sec
 sbc [temp3]
 sta [temp3],y
 ~Int2Dec [temp3],y;#DecIndent+1;#6;#1

 ~Int2Dec [temp3];#DecLeft+1;#6;#1
 ldy #4
 ~Int2Dec [temp3],y;#DecRight+1;#6;#1
 ldy #8
 ~Int2Dec [temp3],y;#DecLine+1;#6;#1
 ldy #$14
 ~Int2Dec [temp3],y;#DecTabs+1;#6;#1
 ldy #$18
 ~Int2Dec [temp3],y;#DecTabs1+1;#6;#1
 ldy #$1C
 ~Int2Dec [temp3],y;#DecTabs2+1;#6;#1
 ldy #$20
 ~Int2Dec [temp3],y;#DecTabs3+1;#6;#1

 ~GetNewModalDialog #TabDialog
 PullLong Ptr
 bcc :0
:err
 ~SysError #:TabDlg ;error?
 rts
:0
*---------------------------------------------------------------------
* Handle the actual usage of this dialog

 ~SelectIText Ptr;#3;#0;#-1 ;select first box
 bcs :err
 ~ShowWindow Ptr ;now show the dialog
 bcs :err
:1
 ~ModalDialog #0 ;let user do his/her thing
 pla
 cmp #2 ;was it cancel?
 beq :Quit
 dec ; no, ok?
 bne :1
:2
 jsr :SaveText ;save changed values
:Quit
 ~CloseDialog Ptr
 rts
:verr
 ~NewAlert #DIllVal ;show illegal value
 pla
 bra :1 ; zap RTS & continue

*------------------------------------------------------
* Save the value of the dialog into the ruler settings

:SaveText
 ~GetInt #3 ;left margin
 bcs :verr
 sta [temp3]

 ~GetInt #5 ;indention
 bcs :verr
 ldy #2
 adc [temp3] ; (which is added to left margin)
 sta [temp3],y
 sta temp

 ~GetInt #4 ;right margin
 bcs :verr
 ldy #4
 sta [temp3],y
 cmp [temp3] ;must be > left margin
 blt :verr
 cmp temp ; and paragraph indention!
 blt :verr

 ~GetInt #6 ;line spacing
 bcs :verr
 ldy #8
 sta [temp3],y

 ~GetInt #7 ;tabs
 bcs :t1
 ldy #$14
 sta [temp3],y
:t1
 ~GetInt #16
 bcs :t2
 ldy #$18
 sta [temp3],y
:t2
 ~GetInt #17
 bcs :t3
 ldy #$1C
 sta [temp3],y
:t3
 ~GetInt #18
 bcs :t4
 ldy #$20
 sta [temp3],y
:t4
 jmp mySetRuler ;make changes

:TabDlg str 'Margin'

*======================================================
* Update the values shown in the info dialog

SetInfo
 _WaitCursor

 jsr GetTEInfo ;get some info, check for empty

 ~Long2Dec TEInfoRec;#DecLen+1;#6;#0 ;...char count
 ~Long2Dec TEInfoRec+4;#DecLines+1;#4;#0 ;...lines
 ~Long2Dec TEInfoRec+12;#DecMem+1;#8;#0 ;...memory
 ~Long2Dec TEInfoRec+16;#DecStCt+1;#4;#0 ;...styles

 jsr GetSelText ;get text (selection)
 bcc :doit
 rts
:doit
 stz temp ;no words
 stz temp+2 ;no paras
 stz temp2 ;no prev. word

 SHORTM ;work w/char
]loop
 lda [Ptr],y ;get a char
 cmp #' '
 beq :word ;word?
 cmp #13
 beq :cr ;paragraph?
 stz temp2
 bra :no ; no- must be text
:cr
 ldx temp+2 ; yes- count paragraph
 inx
 stx temp+2
:word
 ldx temp2 ;space/CR previous?
 btr :no
 dec temp2 ; no- mark & count this one
 ldx temp
 inx  ; (16 bit incr. ... INC = 8 here!)
 stx temp
:no
 iny
 bne :same ;update bank byte?
 inc Ptr+2
:same cpy selEnd ;done w/this bank?
 bne ]loop
 dec temp3 ; yes- are we totally done?
 bpl ]loop

 LONGM
 and #$7F
 cmp #13 ;last char a CR?
 beq :skip
 cmp #' ' ; or a space?
 beq :skip
 inc temp ; no- one last word & para.
 inc temp+2
:skip
 ~Int2Dec temp;#DecWord+1;#4;#0
 ~Int2Dec temp+2;#DecPara+1;#4;#0 ;covert values to dec ASCII

 jsr RemoveText ;free up memory for next part

 ~FreeMem ;get free memory
 PullLong temp
 ~Long2Dec temp;#DecFree+1;#8;#0
 ~RealFreeMem
 PullLong temp ;get purgable free mem
 ~Long2Dec temp;#DecPurg+1;#8;#0
 ~MaxBlock
 PullLong temp ;largest block
 ~Long2Dec temp;#DecBlock+1;#8;#0
 ~TotalMem
 PullLong temp ;total system memory
 ~Long2Dec temp;#DecTotal+1;#8;#0

 _InitCursor
 rts

*=================================================
* our Document Information dialog thingy!

InfoAlert
 dw 34,130,129,473
 dw 1
 hex 80808080
 adrl :item1
 adrl :item23
 adrl :item22
 adrl :item21
 adrl :item20
 adrl :item19
 adrl :item18
 adrl :item17
 adrl :item16
 adrl :item15
 adrl :item14
 adrl :item2
 adrl :item3
 adrl :item4
 adrl :item5
 adrl :item6
 adrl :item7
 adrl :item8
 adrl :item9
 adrl :item10
 adrl :item11
 adrl :item12
 adrl :item13
 adrl 0

:item23 dw 23
 dw 58,271,68,333
 dw #$800F
 adrl DecTotal
 dw 0
 dw 0
 adrl 0

:item22 dw 22
 dw 48,271,58,333
 dw #$800F
 adrl DecBlock
 dw 0
 dw 0
 adrl 0

:item21 dw 21
 dw 38,271,48,333
 dw #$800F
 adrl DecPurg
 dw 0
 dw 0
 adrl 0

:item20 dw 20
 dw 28,271,38,333
 dw #$800F
 adrl DecFree
 dw 0
 dw 0
 adrl 0

:item19 dw 19
 dw 18,271,28,333
 dw #$800F
 adrl DecMem
 dw 0
 dw 0
 adrl 0

:item18 dw 18
 dw 58,100,68,148
 dw #$800F
 adrl DecPara
 dw 0
 dw 0
 adrl 0

:item17 dw 17
 dw 48,100,58,148
 dw #$800F
 adrl DecWord
 dw 0
 dw 0
 adrl 0

:item16 dw 16
 dw 38,100,48,148
 dw #$800F
 adrl DecStCt
 dw 0
 dw 0
 adrl 0

:item15 dw 15
 dw 28,99,38,147
 dw #$800F
 adrl DecLines
 dw 0
 dw 0
 adrl 0

:item14 dw 14
 dw 18,99,28,147
 dw #$800F
 adrl DecLen
 dw 0
 dw 0
 adrl 0

:item1 dw 1
 dw 77,70,90,270
 dw #$A
 adrl :item1txt
 dw 0
 dw 1
 adrl 0
:item1txt str /Well, Isn't that special!/

:item2 dw 2
 dw 18,13,28,96
 dw #$800F
 adrl :item2txt
 dw 0
 dw 0
 adrl 0
:item2txt str 'Char. Count:'

:item3 dw 3
 dw 28,18,38,96
 dw #$800F
 adrl :item3txt
 dw 0
 dw 0
 adrl 0
:item3txt str 'Line Count:'

:item4 dw 4
 dw 38,11,48,96
 dw #$800F
 adrl :item4txt
 dw 0
 dw 0
 adrl 0
:item4txt str 'Num. Styles:'

:item5 dw 5
 dw 48,16,58,96
 dw #$800F
 adrl :item5txt
 dw 0
 dw 0
 adrl 0
:item5txt str 'Word Count:'

:item6 dw 6
 dw 58,14,68,96
 dw #$800F
 adrl :item6txt
 dw 0
 dw 0
 adrl 0
:item6txt str 'Paragraphs:'

:item7 dw 7
 dw 18,182,28,267
 dw #$800F
 adrl :item7txt
 dw 0
 dw 0
 adrl 0
:item7txt str 'Doc. Memory:'

:item8 dw 8
 dw 28,180,38,267
 dw #$800F
 adrl :item8txt
 dw 0
 dw 0
 adrl 0
:item8txt str 'Free Memory:'

:item9 dw 9
 dw 38,193,48,267
 dw #$800F
 adrl :item9txt
 dw 0
 dw 0
 adrl 0
:item9txt str 'w/Purging:'

:item10 dw 10
 dw 48,164,58,267
 dw #$800F
 adrl :item10txt
 dw 0
 dw 0
 adrl 0
:item10txt str 'Largest Block:'

:item11 dw 11
 dw 58,170,68,267
 dw #$800F
 adrl :item11txt
 dw 0
 dw 0
 adrl 0
:item11txt str 'Total Memory:'

:item13 dw 13
 dw 5,3,16,344
 dw #$800F
 adrl :item13txt
 dw 0
 dw 0
 adrl 0
:item13txt str '__________________________________________'

:item12 dw 12
 dw 3,62,12,285
 dw #$800F
 adrl :item12txt
 dw 0
 dw 0
 adrl 0
:item12txt str 'Document & System Information'

*=================================================
FindDialog
 dw 34,50,105,399
 dw 0
 adrl 0
 adrl :words
 adrl :case
 adrl :fromtop
 adrl :item6
 adrl :item5
 adrl :item8
 adrl :item7
 adrl :item4
 adrl :item3
 adrl :item2
 adrl :item1
 adrl 0

:item8 dw 8
 dw 24,4,37,99
 dw #$800F
 adrl :item8txt
 dw 0
 dw 0
 adrl 0
:item8txt str 'Replace with:'

:item7 dw 7
 dw 8,3,21,100
 dw #$800F
 adrl :item7txt
 dw 0
 dw 0
 adrl 0
:item7txt str 'Find the text:'

:item6 dw 6
 dw 22,102,36,342
 dw #$11
 adrl tReplace
 dw 30
 dw 0
 adrl 0

:item5 dw 5
 dw 6,102,20,342
 dw #$11
 adrl tFind
 dw 30
 dw 0
 adrl 0

:item4 dw 2
 dw 53,270,66,338
 dw #$A
 adrl CancelTxt
 dw 0
 dw $00
 adrl 0

:item3 dw 4
 dw 53,155,66,259
 dw #$A
 adrl :item3txt
 dw 0
 dw $00
 adrl 0
:item3txt str 'Replace All'

:item2 dw 3
 dw 53,69,66,145
 dw #$A
 adrl :item2txt
 dw 0
 dw $00
 adrl 0
:item2txt str 'Replace'

:item1 dw 1
 dw 53,8,66,57
 dw #$A
 adrl :item1txt
 dw 0
 dw $01
 adrl 0
:item1txt str 'Find'

:case
 dw $8000
 dw 40,85,50,200
 dw $B
 adrl :casetxt
 dw 1
 dw 4
 adrl 0
:casetxt
 str 'Ignore Case'

:fromtop
 dw $8002
 dw 40,210,50,340
 dw $B
 adrl :ftxt
 dw 1
 dw 4
 adrl 0
:ftxt
 str 'From Beginning'

:words
 dw $8004
 dw 40,6,50,70
 dw $B
 adrl :wordtxt
 dw 0
 dw 4
 adrl 0
:wordtxt
 str 'Words'

*=================================================
TabDialog
 dw 36,115,162,275
 dw 0
 adrl 0
 adrl :item15
 adrl :item14
 adrl :item13
 adrl :item12
 adrl :item11
 adrl :item10
 adrl :item9
 adrl :item8
 adrl :item18
 adrl :item17
 adrl :item16
 adrl :item7
 adrl :item6
 adrl :item5
 adrl :item4
 adrl :item3
 adrl :item2
 adrl :item1
 adrl 0

:item15 dw 15
 dw 95,16,106,96
 dw #$800F
 adrl :item15txt
 dw 0
 dw 0
 adrl 0
:item15txt str 'Tab #4:'

:item14 dw 14
 dw 82,16,93,96
 dw #$800F
 adrl :item14txt
 dw 0
 dw 0
 adrl 0
:item14txt str 'Tab #3:'

:item13 dw 13
 dw 69,16,80,96
 dw #$800F
 adrl :item13txt
 dw 0
 dw 0
 adrl 0
:item13txt str 'Tab #2:'

:item12 dw 12
 dw 56,16,67,96
 dw #$800F
 adrl :item12txt
 dw 0
 dw 0
 adrl 0
:item12txt str 'Tab #1:'

:item11 dw 11
 dw 43,4,54,96
 dw #$800F
 adrl :item11txt
 dw 0
 dw 0
 adrl 0
:item11txt str 'Line Spacing:'

:item10 dw 10
 dw 30,22,41,96
 dw #$800F
 adrl :item10txt
 dw 0
 dw 0
 adrl 0
:item10txt str 'Indention:'

:item9 dw 9
 dw 17,4,28,96
 dw #$800F
 adrl :item9txt
 dw 0
 dw 0
 adrl 0
:item9txt str 'Right Margin:'

:item8 dw 8
 dw 4,11,15,96
 dw #$800F
 adrl :item8txt
 dw 0
 dw 0
 adrl 0
:item8txt str 'Left Margin:'

:item18 dw 18
 dw 93,100,107,154
 dw #$11
 adrl DecTabs3
 dw 6
 dw 0
 adrl 0

:item17 dw 17
 dw 80,100,94,154
 dw #$11
 adrl DecTabs2
 dw 6
 dw 0
 adrl 0

:item16 dw 16
 dw 67,100,81,154
 dw #$11
 adrl DecTabs1
 dw 6
 dw 0
 adrl 0

:item7 dw 7
 dw 54,100,68,154
 dw #$11
 adrl DecTabs
 dw 6
 dw 0
 adrl 0

:item6 dw 6
 dw 41,100,55,154
 dw #$11
 adrl DecLine
 dw 6
 dw 0
 adrl 0

:item5 dw 5
 dw 28,100,42,154
 dw #$11
 adrl DecIndent
 dw 6
 dw 0
 adrl 0

:item4 dw 4
 dw 15,100,29,154
 dw #$11
 adrl DecRight
 dw 6
 dw 0
 adrl 0

:item3 dw 3
 dw 2,100,16,154
 dw #$11
 adrl DecLeft
 dw 6
 dw 0
 adrl 0

:item2 dw 2
 dw 110,86,123,154
 dw #$A
 adrl CancelTxt
 dw 0
 dw 0
 adrl 0

:item1 dw 1
 dw 110,12,123,69
 dw #$A
 adrl :item1txt
 dw 0
 dw 1
 adrl 0
:item1txt str 'Done'

DIllVal
 asc '12/'
 asc 'Illegal Value!/'
 asc '^#0',00
*------------------------------------------------------
* Used by info alert

DecWord str '    '
DecPara str '    '
DecLines str '    ' ;strings for Info alert
DecStCt str '    '
DecLen str '      '
DecMem str '        '
DecFree str '        '
DecPurg str '        '
DecBlock str '        '
DecTotal str '        '
DecLeft str '      '
DecRight str '      '
DecIndent str '      '
DecLine str '      '
DecTabs str '      '
DecTabs1 str '      '
DecTabs2 str '      '
DecTabs3 str '      '

CancelTxt str 'Cancel'

*------------------------------------------------------
LineDialog
 dw 34,50,69,298
 dw -1
 adrl 0
 adrl :item4
 adrl :item3
 adrl :item2
 adrl :item1
 adrl 0

:item4 dw 4
 dw 6,5,19,95
 dw #$800F
 adrl :item4txt
 dw 0
 dw 0
 adrl 0
:item4txt str 'Label/Line #'

:item3 dw 3
 dw 19,4,33,244
 dw #$11
 adrl tFind
 dw 30
 dw 0
 adrl 0

:item2 dw 2
 dw 3,175,16,243
 dw #$A
 adrl CancelTxt
 dw 0
 dw $00
 adrl 0

:item1 dw 1
 dw 4,119,15,167
 dw #$A
 adrl :item1txt
 dw 0
 dw 1
 adrl 0
:item1txt str 'GO'

 lst off
 sav 2/obj/qasm1.l
