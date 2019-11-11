 lst off
 ttl "QASM text routines"
 exp off
 tr on
 cas se
* dup
*======================================================
* Graphic Shell for QuickASM development system

* Programming by Lane Roath
* Copyright (c) 1990 Ideas From the Deep & Lane Roath
*------------------------------------------------------
* 26-Feb-90 0.10 :start working on text windows
*======================================================

 rel

Class1 = $2000

 lst off
 use 2/data/qa.equates
 use macs
 use ifd.equs
 use equs
 lst rtn

 EXT TextName,TextPath,GetTEInfo,FindNext,selStart,selEnd
 EXT SetSelection,QuitPath,GetSelText,SetText,tFind,myDP
 EXT HEdit,PrintBuf,CmdLine,TempBuf,SetStyle,SetRuler

*======================================================
* We redirect all text i/o to these routines

pt2c ENT
 phb
 phk ;need our bank
 plb
 SEP #$30
 sta CmdLine ;save col #
 lda #$20
 ldx PrintBuf ;get current length
]loop
 inx ;next char
 beq :done
 sta PrintBuf,x ; is a space
 stx PrintBuf
 cpx CmdLine
 blt ]loop ;until reached column
:done
 REP #$30
 plb  ;restore bank & exit
 rtl

*------------------------------------------------------

pchr ENT ;print a character
 clc
 hex 24
pechr ENT ;error entry
 sec

 phb
 phk ;need our bank
 plb
 phd
 pha
 lda myDP ;need our DP
 tcd
 pla
 sta CmdLine
 stz CmdLine+1 ;fake CString
 lax #CmdLine
 bra pblkz

*------------------------------------------------------
pblk ENT ;print a CString
 clc
 hex 24
peblk ENT ;error entry
 sec

 phb
 phk ;need our bank
 plb
 phd
 pha
 lda myDP ;need our DP
 tcd
 pla
pblkz
 sax Ptr ;point to CString
 SEP #$30
 ldy #0
]loop
 lda [Ptr],y
 beq :end ; & get it's length
 iny
 bne ]loop
 dey ;backup!
:end
 REP #$30
 bra pstr2

*------------------------------------------------------
pstr ENT ;print a PString
 clc
 hex 24
pestr ENT ;error entry
 sec

 phb
 phk ;need our bank
 plb
 phd
 pha
 lda myDP ;need our DP
 tcd
 pla
 sax Ptr ;point to string
 lda [Ptr]
 and #$FF ;get length
 tay
 inc Ptr ; & skip length byte
pstr2
 sty temp2 ;don't over use DP!

 lda #0
 ror ;place carry in BMI bit
 cmp WhichWdw
 beq :same ;same as last call?
 pha
 jsr AddText ; no- add text to prev. window
 pla
:same
 sta WhichWdw ;save which window we are going to

 SEP #$30 ;8 bit code follows

 ldy #0 ;get indexes
:loop
 ldx PrintBuf
]loop
 inx  ;buffer overflow?
 bne :ok
 phy
 jsr AddText ; yes- add current text
 ply
 bra :loop ; & restart fill
:ok
 stx PrintBuf
 lda [Ptr],y ;copy a char
 and #$7F
 cmp #' ' ;control char?
 blt :ctrl ; yes- special
:char
 sta PrintBuf,x ; no- just store char
:nochar
 iny
 cpy temp2 ;are we done?
 blt ]loop
 cmp #13 ; yes- last char a CR?
 bne :xit
 jsr AddText ; yes- add text
:xit
 REP #$30
 pld
 plb  ;restore dp,bank & exit
 rtl

*------------------------------------------------------
 mx %11
:ctrl
 cmp #13 ;CR?
 beq :char
 dex
 cmp #'U'&$1F ;multi char?
 bne :nochar
 inx
 iny
 lda [Ptr],y ; yes, get count
 sta temp2+2
 iny
 lda [Ptr],y ; get char to repeat
 and #$7F
]loop
 stx PrintBuf
 sta PrintBuf,x ;place a char
 inx
 bne :ok1 ;buffer overflow?
 phy
 pha
 jsr AddText ; yes- add current text
 pla
 ply
 ldx #1 ; & reinit index
:ok1
 dec temp2+2 ;done?
 bne ]loop
 dex
 bra :nochar ; yes- back to loop

 mx %00
*------------------------------------------------------
* Add the text to the TE record of user's choice

AddText
 php ;must be in 16bit mode!

 SEP #$30
 lda PrintBuf ;anything to print?
 beq :xit
 REP #$30

 lda WhichWdw ; yes, to which window?
 bmi :1
 lax CmdTEHdl ; Command window
 bra :2
:1
 lax ErrTEHdl ; Error window
:2
 sax QuitPath ;save TE record
 ~TEInsert #0;#PrintBuf;PrintBuf;#0;#0;QuitPath ; & insert in wdw
 stz PrintBuf
:xit
 plp
 rts

WhichWdw dw 0 ;assume command

*======================================================
* Install our keypress checker into the TE record

 mx %00

InstallKey ENT
 lda #%1100010 ; no, update TE record
 jsr SetStyle
 lda #-2
 ldy #8 ;adjust line spacing
 jsr SetRuler

 Hdl_Ptr TEHdl;Ptr ;point to command window TE record
 ldy #$C8
 lda #KeyFilter
 sta [Ptr],y
 iny
 iny  ;install our key filter
 lda #^KeyFilter
 sta [Ptr],y
 rts

*======================================================
* Check for ENTER or CLEAR keypresses on keypad
* Just sets some flags, actual work done by main program!

KeyFilter

 dum 4
]rtl ds 3 ;these are passed on stack
]type ds 2
]handle ds 4
]newstack = *-3 ;must be at end of passed params
 dend

 phd ;save DP, bank
 phb
 phk
 plb
 lda myDP ; & use ours
 tcd

 lda ]handle+2,s
 sta Hdl+2 ;get TE handle
 lda ]handle,s
 sta Hdl ; & dereference for use
 Hdl_Ptr Hdl;Ptr
 lda ]type,s ;check for type 1
 dec
 bne :xit
 ldy #$D8+2
 lda [Ptr],y ;keypad ?
 and #$2000
 beq :xit ; no- exit
 dey
 dey
 lda [Ptr],y
 and #$7F ;get keypress
 cmp #'X'&$1F
 bne :enterchk ;CLEAR?
 dec ClearFlg
 bra :wedo ; yes- tell program
:enterchk
 cmp #13 ;ENTER?
 bne :xit
 dec EnterFlg ; yes- inform program
:wedo
 lda #2 ;TE... don't handle this press!
 bra :xit2
:xit
 lda #0 ;TE... do normal processing
:xit2
 ldy #$D8+$C
 sta [Ptr],y ;tell TE what to do

 lda ]rtl,s
 sta ]newstack,s

 SEP #$30 ;remove parms
 lda ]rtl+2,s
 sta ]newstack+2,s
 REP #$30

 plb ;restore DP, bank
 pld
 tsc
 clc
 adc #]newstack-4 ;adjust stack
 tcs
 rtl

*======================================================
* User pressed CLEAR on the keypad, clear TE text

DoClear ENT
 stz ClearFlg
 lda #20 ;select entire document
 jsr HEdit
 ~TEClear #0 ; & clear it
 rts

*======================================================
* User pressed ENTER on keypad, parse QA commands

DoEnter ENT
 stz EnterFlg ;we're doing it!
 ldx #'H'&$1F
 lda #$800 ;move to beginning of line
 jsr :dokey
 ldx #'U'&$1F
 lda #$A00 ;select to end of line
 jsr :dokey
 ~TECopy #0 ;copy to clipboard
 bcs :err
 ~GetScrapHandle #0 ;get handle to copied text
 PullLong Hdl
 bcs :err
 ~HLock Hdl ;lock it down
 Hdl_Ptr Hdl;Ptr
 ~GetHandleSize Hdl ;get size
 ply
 plx
 bcs :err

 SEP #$30
 sty CmdLine ;set length
]loop dey
 bmi :xit ;don't do NULL string
 lda [Ptr],y
 iny  ;copy text to PString
 sta CmdLine,y
 dey
 bne ]loop
 REP #$30

 ~QAParseCmdLine #CmdLine ;let QA parse the command
 plx
 ply
 bcc :doit ;ok?
:err
 ~SysError #sntx
:xit
 REP #$30
 rts
:doit
 phx ; yes- try to run it!
 phy

 ldx #'U'&$1F ;move to end of line
 lda #0
 jsr :dokey
 ldx #13 ; & insert a CR
 jsr :dokey2
 _QAClearKey
 _QAExecCommand ;let QA do it's thing
 bcs :err
 rts

*------------------------------------------------------
:dokey
 sta TaskRc+14
:dokey2
 stx TaskRc+2 ;set keypress
 lda #3 ;show keydown event
 sta TaskRc
 ~TEKey #TaskRc;TEHdl ; & have TE do it
 rts

sntx str 'Command not found!'

*======================================================
* This is the text mode handler, so we can switch back
* and forth between it and graphics quickly!!!

doTextMode ENT
 _GrafOff ;back to text!
 _QAResetVectors
 _QAClearKey  ; (w/no pending keypress!)
 bra :cr
]loop
 ~QAGetQuitFlag
 pla
 bne :end ;time to quit?
 _QARun
 jsr GetLine ; no- get user input
 bcc :cr

 ~QAParseCmdLine #CmdLine ;let QA parse the command
 plx
 ply
 bcs :err ;able to parse?
 phx
 phy
 _QAClearKey
 _QAExecCommand ;let QA do it's thing
 bcc ]loop
:err
 pha
 ~QADrawStr #sntx ;show error msg
 _QAPrByteL
:cr
 _QADrawCR
 bra ]loop
:end
 _GrafOn ;back to graphics!

*======================================================
* Force printing in QuickASM to be placed in TEdit window

GrafVectors ENT
 ~QASetVector #1;#pchr
 ~QASetVector #2;#pstr ;set vectors for text output
 ~QASetVector #5;#pblk
 ~QASetVector #3;#pechr
 ~QASetVector #4;#pestr ;set error vectors for text output
 ~QASetVector #6;#peblk
 ~QASetVector #14;#pt2c
 rts

*======================================================
* Use the QA tools to get some input in the text mode

GetLine
 stz CmdLine ;force nothing in buffer

 pea 0 ;room for returned stuff
 pea 0
 pea 0
 psl #CmdLine ;pointer to my buffer
 psl #:prompt ;my prompt string
 lda :prompt ;calculate maximum length
 and #$ff ;from prompt length
 sec
 sbc #79
 eor #$FFFF
 inc
 pha
 pea 0 ;start at first position
 lda #"_" ;insert cursor
 ora #' '*256 ;overstrike is high byte
 pha
 lda :cursor ;current cursor
 and #$FF
 ora #" "*256 ;"fill" character
 pha
 psl #:abortptr ;keys to abort on (besides ESC and CR)
 _QAGetLine
 pla
 and #$FF
 sta :cursor ;save user's cursor pref
 pla ;pull off last position
 pla ;pull last key press
 and #$7f
 cmp #$1b ;ESC?
 bne :noesc
 _GrafOn ; yes-
 pla
 brl GrafVectors ; exit back to graphics!
:noesc
 lda CmdLine
 and #$ff
 beq :clc ;empty line?
 tay
 lda CmdLine,y
 and #$7F
 cmp #$0D ;look for end of input
 beq :sec
 inc CmdLine
 lda #$0D
 sta CmdLine+1,y ; insure CR at end
:sec
 _QADrawCR
 sec
 rts
:clc
 lda #$0D01
 sta CmdLine
 clc
 rts

:cursor dw ' ' ;start with overstrike
:prompt str 'CMD:'
:abortptr dw 0 ;no keys abort

 mx %00
*======================================================
* Load the QATools and QACommand table files

LoadQAStuff ENT
 ~InitialLoad ID2;#ToolName;#-1 ;load our special tools
 plx
 PullLong ToolAdr ;ignore ID, save address
 plx
 plx ;ignore DP/stack information
 bcs :ggg

 ~SetTSPtr #ToolType;#ToolNum;ToolAdr ;setup in tool table
 bcs :ggg

 _QABootInit ;initialize the toolset
 bcs :ggg

 ~InitialLoad ID2;#CmdName;#-1 ;load commands
 plx
 PullLong CmdAdr ;ignore ID, save pointer to cmd code
 plx
 plx ;ignore DP/stack info
 bcs :ggg

 ~ReadFile #ParmName;#$8000 ;read parameter file
 bcs :ggg
 sax ParmHdl

 Hdl_Ptr ParmHdl;Ptr ;deref parms
 pei ID
 pea #0
 lda [Ptr]
 and #$8000 ;text or graphics?
 pha
 _QAStartup ;start up tools
:ggg bcs :gxit

 jsr SetCmdHdl ;read command table
 bcs :gxit
 ~QASetCmdHdl CmdHdl;NumCmds ;let QA know abut stuff
 ~QASetParmHdl ParmHdl
 ~QASetCmdTbl CmdAdr

 ~ReadFile #LoginName;#0 ;read parameter file
:gxit bcs :xit
 lda ReadParms+12 ; & exit if empty
 beq :xit

 stz temp ;init index into file
]loop
 ldy temp ;is current line blank?
 lda [Ptr],y
 and #$7F
 cmp #13
 beq :nextline
 cmp #';' ; no- do we have a good command?
 beq :nextline
 cmp #'*'
 beq :nextline
 dey  ; yes- backup one for PString creation
 bmi :xit
 tya
 clc
 adc Ptr ;create pointer to text
 sta temp2
 lda Ptr+2
 adc #0 ; allowing wrapping around bank!
 sta temp2+2

 SEP #$30 ;only need 8 bit stuff here!

 ldy #1
]lup
 lda [temp2],y
 and #$7F ;look for EOL
 cmp #'I'&$1F
 beq :tab
 cmp #' ' ; (anything < space 'cept tabs!)
 blt :fnd
:tab
 iny ;repeat until found (>255 = error)
 bne ]lup
:fnd
 tya ;save length!
 sta [temp2] ; (only a byte)

 REP #$30

 ~QAParseCmdLine temp2 ;parse a command line
 plx
 ply
 bcs :xit ;able to parse?
 phx
 phy
 _QAExecCommand ;let QA do it's thing
:nextline
 ~QANextLine Ptr;temp;ReadParms+12
 PullWord temp
 bcc ]loop ;repeat util done!
 clc
:xit
 rts

*======================================================
* Read the command table & create the 'commands' we know

RecSize = temp2
begword = temp3
endword = temp3+2 ;all unused at this time!!!
Ptr2 = tRLen
size = textLen

SetCmdHdl
 stz CmdHdl ;we don't have one yet!
 stz CmdHdl+2
 pha
 _QAGetCmdRecSize ;Valid even if QATools not started
 pla
 sta RecSize

 ~ReadFile #TableName;#0 ;read in command table
 bcs :err
 sax Hdl
 Hdl_Ptr Hdl;Ptr ; & point to it

 stz NumCmds ;we don't have any

 ~GetHandleSize Hdl ;get size of table
 PullLong temp

 jsr :getentry ;set all the commands
 php
 pha
 ~DisposeHandle Hdl ;get rid of data, save error status
 pla
 plp
:err
 rts

*------------------------------------------------------
* Get the entries in the command table & set our internal
* information appropriately

:getentry
 stz endword ;start at beginning of file
:gloop
 ldx #eRecSize-2
]lup stz CmdLine,x ;clear buffer
 dex
 dex
 bpl ]lup

 SEP #$20

 jsr :getword ;get command word w/first char in 'A'
 bcc :nl0
 brl :done ;reached EOF!
:nl0
 cmp #'*'
 beq :nl1 ;have a comment?
 cmp #';'
 bne :nl2
:nl1 brl :newline ; yes- skip line!
:nl2
 ldx #$00
 bra :c1 ; no- save first char
]loop
 jsr :getchar ;get next char
 bcs :nextfield
:c1
 sta CmdLine+1,x ;save the command
 inx
 cpx #16 ; & continue for up to 15 chars
 blt ]loop
 dex ; (real length)
:nextfield
 SEP #$10
 stx CmdLine ;save length of command (byte)
 REP #$10

 jsr :getword ;get next word
 bcs :gbad
 cmp #'*' ;is this command restartable?
 bne :cmp
 lda #$80
 tsb CmdLine+eflags+1 ; yes- show it
 jsr :getchar
 bcs :gbad
:cmp
 ldy #1
 cmp #'L' ;linker?
 beq :ty
 iny
 cmp #'C' ;compiler?
 beq :ty
 iny
 cmp #'I' ;internal?
 beq :ty
 iny
 cmp #'E' ;external?
 beq :ty
 iny
 cmp #'A' ;application?
 bne :bad
:ty
 sty CmdLine+etype ;save type

 jsr :getword ;get next word (ID #)
:gbad bcs :bad
 ldx #$00 ;save first char
 bra :c2
]lup
 jsr :getchar ;get next char
 bcs :stx
:c2
 cmp #'0'
 blt :bad ;insure it's a decimal #
 cmp #'9'+1
 bge :bad
 sta TempBuf,x ;then save it
 inx
 cpx #5 ; & do so for up to 4 chars
 blt ]lup
 dex
:stx
 REP #$20 ;16 bit stuff
 pha
 psl #TempBuf
 phx
 pea 0
 _Dec2Int  ;convert ASCII to hex
 pla
 sta CmdLine+eid ; & save ID in table

 inc NumCmds ;we got another!
 jsr :saveit
 bcs :eerr
:newline
 REP #$20 ;insure 16 bit A

 ~QANextLine Ptr;endword;temp
 PullWord endword
 bcs :done
 brl :gloop
:done
 rep $30
 lda NumCmds ;must have at least one command!
 beq :bad
 clc
 rts
:bbad
 ply ;get rid of an RTS
:bad
 rep $30
 lda #qabadcmdfile ;we didn't like this file!
:eerr
 sec
 rts

*------------------------------------------------------
:getword
 REP #$20 ;force 16 bit
]loop
 ~QAGetWord Ptr;endword;temp ;get a word
 plx
 ply
 beq :0 ;don't modify if no word!
 stx endword
 sty begword
 bcc :1
 tax ;real error, or just no word?
 bmi :1
:0
 inc endword ;no word- look for one!
 bra ]loop
:1
 SEP #$20
 bra :gc ;get first char, uppercase!

*------------------------------------------------------
 mx %10
:getchar
 iny ;are we at end of word?
 cpy endword
 bge :gc1 ; yes- outa here!
 cpy temp
 bge :bbad
:gc
 lda [Ptr],y
 and #$7F ;create usable dude
 cmp #'a'
 blt :gc1 ;convert lower case
 cmp #'z'+1
 bge :gc2
 and #$5F
:gc2
 clc ;no error
:gc1
 rts

*------------------------------------------------------
 mx %00
:saveit
 lda CmdHdl
 ora CmdHdl+2 ;already started?
 bne :resize

 ~NewHandle #1;ID2;#0;#0 ; no- need a handle!
 PullLong CmdHdl
 bcs :serr
:resize
 ~HUnlock CmdHdl ;we want to use this

 psl #$00
 pei NumCmds
 pei RecSize
 Tool $090B ;multiply # of commands by record size
 lda 1,s
 sta size
 lda 3,s ;get result, leave on stack
 sta size+2

 psl CmdHdl ; to make handle the correct size
 _SetHandleSize
 bcc :noerr
:serr
 rts ;always reached w/BCS
:noerr
 ~HLock CmdHdl
 Hdl_Ptr CmdHdl;Ptr2 ;deref record handle

 lda size
 sec
 sbc RecSize ;get offset to start of new record
 bcs :s1
 dec size+2
:s1
 clc
 adc Ptr2
 sta Ptr2 ;adjust pointer for our use
 lda Ptr2+2
 adc size+2
 sta Ptr2+2

 ldy RecSize ;# of bytes+2 to move
]lup
 dey
 dey ;next word
 bmi :set
 lda CmdLine,y
 sta [Ptr2],y ;move a word into array
 bra ]lup
:set
 lda CmdLine+etype ;setup system vars as found
 cmp #1
 beq :linker
 cmp #2
 bne :ul
 ~QAGetCompileID  ;compiler ID found...already set?
 pla
 bne :ul
 ~QASetCompileID CmdLine+eid ; no- set it
 bra :ul
:linker
 ~QAGetLinkID  ;linker ID found... already set?
 pla
 bne :ul
 ~QASetLinkID CmdLine+eid ; no- set it
:ul
 ~HUnlock CmdHdl ;don't clog memory
 rts

ToolName str '@:qasystem:qatools'
CmdName str '@:qasystem:qaintcmd'
ParmName strl '@:qasystem:qaprefs'
TableName strl '@:qasystem:qacmd'
LoginName strl '@:qasystem:login'
*======================================================
* Display the QuickASM main greeting on the text screen

PrintWelcome ENT
 psl #:welcome
 _QADrawBlock
 ~QADrawVersion #versionnum
 psl #:next
 _QADrawBlock
 rts

:welcome
 dfb 'U'&$1F,31,' '
 asc 'QuickASM GS v',00
:next hex 0d
 dfb 'U'&$1F,38,' '
 asc 'by',0d
 dfb 'U'&$1F,27,' '
 asc 'Shawn Quick & Lane Roath',0d,0d
 dfb 'U'&$1F,15,' '
 asc 'Copyright (c) 1990 QuickSoft Software Development',0d
 dfb 'U'&$1F,25,' '
 asc 'All Rights Reserved Worldwide',0d
 dfb 'U'&$1F,80,'_'
 hex 0d0d
 hex 00

 lst off
 sav 2/obj/qasm2.l
