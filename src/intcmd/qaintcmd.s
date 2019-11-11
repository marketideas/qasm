              lst        off
              tr         on
              exp        off
              cas        in
*======================================================
* These are the internal commands available for use by
* QuickASM.  Seperate for easy editing, and allows new
* shells to have their own command library files.

* Written by Shawn Quick and Lane Roath
*------------------------------------------------------
* 17-Feb-90 0.20 :remove ASCII command
* 06-Feb-90 0.10 :clean up the code, size, speed
*======================================================

              xc
              xc
              mx         %00
              rel

Class1        =          0000

              lst        off
              use        intcmd.macs
              put        qa.equates
              lst        rtn

*======================================================
* The required command table, preceded by command count

              dw         {tblend-tbl}/4
tbl           adrl       quitcmd              ;ID #1
              adrl       prefixcmd            ;ID #2
              adrl       purgecmd             ;ID #3
              adrl       helpcmd              ;ID #4
              adrl       compilecmd           ;ID #5
              adrl       linkcmd              ;ID #6
              adrl       showcmd              ;ID #7
              adrl       quicklinkcmd         ;ID #8
              adrl       asmlinkgo            ;ID #9
              adrl       setcmd               ;ID #10
              adrl       popcmd               ;ID #11
              adrl       toolmaccmd           ;ID #12
              adrl       launch               ;ID #13  launch with return
              adrl       SubLaunch            ;ID #14  launch with no return
              adrl       shutdown             ;ID #15  reboot system
tblend

one           dw         1

*======================================================
* Quit back to finder (or whatever launched us)

quitcmd
              php
              rep        $30
              pea        $ffff
              _QASetQuitFlag
              lda        #$00
              plp
              clc
              rtl

*------------------------------------------------------
* Shut down the entire computer in a save manner

shutdown
              php
              rep        $30
              pea        $ffff
              _QASetQuitFlag
              psl        #:zero
              pea        $FFFF                ;$FFFF means shutdown
              _QASetLaunch
              lda        #$00
              plp
              clc
              rtl

:zero         dw         0                    ;null path

*======================================================
* Launch or SubLaunch an application (SYS,S16,EXE,etc.)

              mx         %00
launch
              lda        #$C000               ;return and restart
              bra        dolaunch
SubLaunch
              lda        #$4000               ;no return and restart
dolaunch
              php
              phd
              phb
              phk
              plb
              rep        $30
              sta        launchflags
              stz        tempbuff
              stz        filename
              psl        #tempbuff
              pea        255
              _QAGetCmdLine
              lda        tempbuff
              and        #$ff
              beq        :nopath
              lda        tempbuff+1
              and        #$7f
              cmp        #'-'
              beq        :nospace
              cmp        #'='
              bne        :normal
:nospace      sep        $30
              pha
              lda        tempbuff
              inc
              sta        tempbuff-1
              pla
              sta        tempbuff
              lda        #' '
              sta        tempbuff+1
              rep        $30
              ldx        #tempbuff-1
              ldy        #^tempbuff-1
              bra        :getpath
:normal       ldx        #tempbuff
              ldy        #^tempbuff
:getpath      jsr        getpath
              bcc        :gotpath
:nopath       rep        $30
              lda        #$46
              brl        :xit
:gotpath      _GSOS      _GetFileInfo;:info
              jcs        :xit
              lda        :type
              and        #$FF
              cmp        #$FF
              beq        :ok
              and        #$F0
              cmp        #$B0
              bne        :5C
:ok           pea        #$FFFF
              _QASetQuitFlag
              psl        #filename
              lda        launchflags
              pha
              _QASetLaunch
:noerr        rep        $30
              lda        #$00
              bra        :xit
:5c           rep        $30
              lda        #$5C                 ;prodos "not executable file"
:xit          rep        $30
              and        #$ff
              plb
              pld
              plp
              cmpl       one
              rtl

:info         adrl       filename
              dw         0
:type         ds         2
              ds         20

*======================================================
* Remove any of our transient commands from memory
* (*** to be done... allow specifying command to remove! ***)

purgecmd
              php
              rep        $30
              psl        #:str
              _QADrawStr
              ~PurgeAll  #0
              _CompactMem
              plp
              clc
              rtl

:str          str        'Purging memory...',0d

*======================================================
* Compile (assemble) a file

compilecmd
              php
              rep        $30
              pea        0
              _QASetCancelFlag
              pea        #afromcmd            ;compile from command line
              psl        #$00                 ;no subtype
              _QACompile
              bcs        :sec
              plp
              clc
              rtl
:sec          plp
              sec
              rtl

*======================================================
* Execute a linker command file

linkcmd
              php
              rep        $30
              pea        0
              _QASetCancelFlag
              pea        #lfromcmd
              psl        #$00                 ;no subtype
              _QALink
              bcs        :sec
              plp
              clc
              rtl
:sec          plp
              sec
              rtl

*======================================================
* Assemble a file, link the result, and execute the program

asmlinkgo
              rep        $30
              lda        #$FFFF
              sec
              rtl

*======================================================
* This is mainly for editors... ie, Merlin's oa-6 cmd.
* Looks for the file QUICKLINK.S in the current folder,
* then in 9/QASYSTEM if that fails, and passes it to the linker.

quicklinkcmd
              php
              rep        $30
              psl        #tempbuff
              pea        255
              _QAGetCmdLine
              ldx        #tempbuff
              ldy        #^tempbuff
              jsr        getpath
              bcc        :gotpath
              lda        #$46
              plp
              sec
              rtl
:gotpath
              rep        $30
              pea        0
              _QASetCancelFlag
              pea        #lquick
              psl        #filename
              _QALink
              bcs        :sec
              plp
              clc
              rtl
:sec          plp
              sec
              rtl

*======================================================
* Show the user what commands are avail.  If passed a command name
* look in the help directory for that file & display it.

helpcmd
              php
              phb
              phd
              phk
              plb
              rep        $30
              pha
              pha
              tsc
              inc
              tcd
              psl        #:str
              _QADrawString
              pea        0
              psl        #$00
              _QAGetCmdHdl
              plx
              stx        number
              plx
              ply
              jcs        :xit
              stx        handle
              sty        handle+2
              psl        handle
              _Hlock
              lda        handle
              sta        0
              lda        handle+2
              sta        2
              ldy        #$02
              lda        [0]
              tax
              lda        [0],y
              sta        2
              stx        0
              stz        pos
              lda        number
              beq        :noerr
              pea        #$0d
              _QADrawChar
:loop         lda        number
              beq        :done
              ldx        pos
              lda        :tbl,x
              and        #$ff
              pha
              _QATabToCol
              pei        2
              pei        0
              _QADrawstring
              inc        pos
              lda        pos
              cmp        #$04
              blt        :next
              pea        $0d
              _QADrawChar
              stz        pos
:next         dec        number
              lda        0
              clc
              adc        #erecsize
              sta        0
              bcc        :loop
              inc        2
              bra        :loop
:done         lda        pos
              beq        :cr
              pea        $0d
              _QADrawChar
:cr           pea        #$0d
              _QADrawChar
:noerr        lda        #$00
:xit          rep        $30
              plx
              plx
              pld
              plb
              plp
              cmpl       one
              rtl

:tbl          dfb        2,22,42,62
:str          str        0d,'Commands available:',0d

*======================================================
* Show the current prefixes & avail. memory

showcmd
              php
              phb
              phk
              plb
              rep        $30
              pea        $0D
              _QADrawChar
              stz        tempbuff
              lda        #$FFFF
              sta        :pfxnum
              jsl        $e100a8
              dw         $28
              adrl       :boot
              jsr        convertpath
              pea        #'*'
              _QADrawChar
              brl        :init
]lup          lda        :pfxnum
              cmp        #8
              bge        :memory
              stz        tempbuff
              _GSOS      _GetPrefix;:pfxnum

              jsr        convertpath

              lda        :pfxnum
              and        #$0F
              ora        #$30
              pha
              _QADrawChar
:init         pea        ':'
              _QADrawChar
              _QADrawSpace
              pea        '='
              _QADrawChar
              _QADrawSpace
              psl        #tempbuff
              _QADrawstring
              _QADrawCR
              inc        :pfxnum
              brl        ]lup
:memory
              _QADrawCR

              psl        #:mem1
              _QADrawString
              psl        #$00
              tll        $1b02
              pll        :mem
              jsr        :printmem
              _QADrawCR

              psl        #:mem2
              _QADrawString
              psl        #$00
              tll        $2f02
              pll        :mem
              jsr        :printmem
              _QADrawCR

              psl        #:mem3
              _QADrawString
              psl        #$00
              tll        $1c02
              pll        :mem
              jsr        :printmem
              _QADrawCR

              psl        #:mem4
              _QADrawString
              psl        #$00
              tll        $1d02
              pll        :mem
              jsr        :printmem
              _QADrawCR
              _QADrawCR
              plb
              plp
              clc
              rtl
:printmem
              lup        10
              lsr        :mem+2
              ror        :mem
              --^
              psl        :mem
              psl        #:dstr+1
              pea        $04
              pea        $00
              tll        $270b
              psl        #:dstr
              _QADrawString
              pea        'K'
              _QADrawChar
              rts

:str          str        'Prefix #'
:mem          ds         4
:mem1         str        'Free RAM:      '
:mem2         str        'Real Free RAM: '
:mem3         str        'Largest Block: '
:mem4         str        'Total RAM:     '
:dstr         str        '0000'
:boot         adrl       tempbuff
:pfxnum       ds         2
              adrl       tempbuff

*======================================================
* Load the 'built in' macros for use by quick asm

toolmaccmd
              php
              phb
              phk
              plb
              rep        $30
              psl        #$00
              pea        #vtoolmacs
              _QAGetVector
              pll        handle
              lda        handle
              ora        handle+2
              beq        :load
              psl        handle
              _DisposeHandle
:load         stz        handle
              stz        handle+2
              pea        #vtoolmacs
              psl        handle
              _QASetVector
              psl        #$00
              psl        #:name
              psl        #$00                 ;filepos
              psl        #-1                  ;whole file
              psl        #:types
              pea        0
              _QAGetShellId
              psl        #$00
              pea        $0000
              _QALoadfile
              plx
              ply
              jcs        :sec
              sty        handle+2
              stx        handle
              pea        #vtoolmacs
              psl        handle
              _QASetVector
              lda        #$00
:sec          plb
              plp
              cmpl       one
              rtl

:types        hex        00
:name         str        '9/QASYSTEM/TOOLMACS'

*======================================================
* Back up one level in the current prefix

popcmd
              php
              phd
              phb
              phk
              plb
              stz        setparms
              stz        tempbuff
              stz        filename
              psl        #tempbuff
              pea        255
              _QAGetCmdLine
              ldx        #tempbuff
              ldy        #^tempbuff
              jsr        getpath
              bcs        :nopath
              lda        filename
              and        #$ff
              beq        :nopath
              cmp        #$02
              bge        :syntax
              lda        filename+1
              and        #$7f
              cmp        #'0'
              blt        :syntax
              cmp        #'8'
              blt        :gp
:syntax       lda        #$53                 ;*** whatever sounds good
              brl        :err
:gp           and        #$0f
              sta        setparms
:nopath       rep        $30
              lda        #^tempbuff
              sta        pfxptr+2
              lda        #tempbuff
              sta        pfxptr
              _GSOS      _GetPrefix;setparms
              jsr        convertpath
              lda        tempbuff
              and        #$ff
              tax
              sep        $20
              lda        tempbuff,x
              and        #$7f
              cmp        #'/'
              beq        :dec
              cmp        #':'
              bne        :count
:dec          dex
:count        lda        tempbuff,x
              and        #$7f
              cmp        #':'
              beq        :end
              cmp        #'/'
              beq        :end
              dex
              cpx        #$00
              bne        :count
              bra        :xit
:end          txa
              cmp        #$01
              beq        :xit
              sta        tempbuff
              rep        $30
              _GSOS      _SetPrefix;setparms
:xit          plb
              pld
              plp
              clc
              rtl

:err          plb
              pld
              plp
              sec
              rtl

*======================================================
* Set the prefix to something we can use

prefixcmd
              php
              phd
              phb
              phk
              plb
              rep        $30
              stz        tempbuff
              psl        #tempbuff
              pea        255
              _QAGetCmdLine
              lda        #$ffff
              sta        :pfxnum
              sep        $30
              lda        tempbuff
              jeq        :nopath
              ldx        #$00
]lup          inx
              lda        tempbuff,x
              and        #$7f
              cmp        #' '
              jlt        :nopath
              beq        ]lup
]lup          inx
              lda        tempbuff,x
              and        #$7f
              cmp        #' '
              jlt        :nopath
              bne        ]lup
]lup          inx
              lda        tempbuff,x
              and        #$7f
              cmp        #' '
              jlt        :nopath
              beq        ]lup
              cmp        #'0'
              jlt        :gp1
              cmp        #'8'
              jeq        :badnum
              cmp        #'9'
              jeq        :badnum
              jge        :gp1
              tay
              inx
              lda        tempbuff,x
              and        #$7f
              cmp        #' '
              jlt        :show1
              beq        :parm
              cmp        #'/'
              beq        :gp1
              cmp        #':'
              beq        :gp1
              brl        :badnum
:parm         inx
              lda        tempbuff,x
              and        #$7f
              cmp        #' '
              jlt        :show1
              beq        :parm
              dex
              rep        $30
              tya
              and        #$0f
              sta        :pfxnum
              sep        $30
              ldy        #$00
]lup          inx
              lda        tempbuff,x
              and        #$7f
              cmp        #' '
              blt        :nopath
              beq        ]lup
              cmp        #'a'
              blt        :s
              cmp        #'z'+1
              bge        :s
              and        #$5f
:s            cmp        #'/'
              bne        :s1
              lda        #':'
:s1           sta        filename+1
]lup          iny
              inx
              lda        tempbuff,x
              and        #$7f
              cmp        #' '+1
              blt        :save
              cmp        #'a'
              blt        :s2
              cmp        #'z'+1
              bge        :s2
              and        #$5f
:s2           cmp        #'/'
              bne        :s3
              lda        #':'
:s3           sta        filename+1,y
              bra        ]lup
:save         sty        filename
              cpy        #$00
              beq        :nopath
              brl        :gotpath
:badnum       rep        $30
              lda        #$53                 ;GS/OS error $53
              brl        :error
:gp1          rep        $30
              ldx        #tempbuff
              ldy        #^tempbuff
:getpath      rep        $30
              jsr        getpath
              bcc        :gotpath
:nopath
              rep        $30
              jsl        showcmd
              plb
              pld
              plp
              clc
              rtl
:gotpath
              rep        $30
              stz        setparms
              lda        :pfxnum
              cmp        #$ffff
              beq        :fn
              sta        setparms
:fn           lda        #filename
              sta        pfxptr
              lda        #^filename
              sta        pfxptr+2
              _GSOS      _SetPrefix;setparms
              bcs        :error
              lda        #$00
:error        rep        $30
              plb
              pld
              plp
              cmpl       one
              rtl
:show1
              rep        $30
              tya
              and        #$0f
              sta        :pfxnum
              _GSOS      _GetPrefix;:pfxnum
              jsr        convertpath
              _QADrawCR
              lda        :pfxnum
              and        #$0F
              ora        #$30
              pha
              _QADrawChar
:init         pea        ':'
              _QADrawChar
              _QADrawSpace
              pea        '='
              _QADrawChar
              _QADrawSpace
              psl        #tempbuff
              _QADrawstring
              _QADrawCR
              _QADrawCR
              lda        #$00
              brl        :error

:pfxnum       ds         2
              adrl       tempbuff

*======================================================
* Set the prefixes according to a base prefix

setcmd
              php
              phd
              phb
              phk
              plb
              rep        $30
              psl        #tempbuff
              pea        255
              _QAGetCmdLine
              ldx        #tempbuff
              ldy        #^tempbuff
              jsr        getpath
              bcc        :gotpath

:nopath       rep        $30
              jsr        setpfx
              bcs        :error
              lda        #$00
              brl        :error
:gotpath
              stz        setparms
              lda        #filename
              sta        pfxptr
              lda        #^filename
              sta        pfxptr+2
              _GSOS      _SetPrefix;setparms
              bcs        :error
              jsr        setpfx

:error        rep        $30
              plb
              pld
              plp
              cmpl       one
              rtl

*------------------------------------------------------
* Set a prefix from the parms... part of SET handler

              mx         %00
setpfx
              php
              phd
              phb
              phk
              plb
              rep        $30
              lda        #$01
              sta        count
              sta        setparms
              phd
              psl        #$00
              _QAGetParmHdl
              tsc
              inc
              tcd
              lda        0
              ora        2
              beq        :bad
              ldy        #$04
              lda        [0],y
              ora        #$8000
              sta        [0],y
              ldy        #$02
              lda        [0]
              tax
              lda        [0],y
              sta        pfxptr+2
              txa
              clc
              adc        #$04+64              ;Skip Prefix 0
              sta        pfxptr
              bcc        :c1
              inc        pfxptr+2
:c1           pld
              pla
              plx
              bra        :set
:bad          pld
              plx
              plx
              brl        :bad1

:set          lda        count
              _GSOS      _SetPrefix;setparms  ; yes- do so!
              lda        pfxptr
              clc
              adc        #64
              sta        pfxptr
              bcc        :c2
              inc        pfxptr+2
:c2           inc        setparms             ;next prefix
              inc        count
              lda        count
              cmp        #08
              blt        :set
              lda        #$00
              bra        :9
:bad1         lda        #$46
:9            plb
              pld
              plp
              cmp        one
              rts

*------------------------------------------------------
* Get pathname from parm
* ENTRY: XY = Address of path buffer
*  EXIT: filename = returned path

getpath

]ptr          =          0

              php
              phd
              phb
              phk
              plb
              rep        $30
              pha
              pha
              tsc
              inc
              tcd
:get          stx        ]ptr
              sty        ]ptr+2
:go           ldy        #1
              sep        $20
              lda        []ptr]
              beq        :nopath
]lup          lda        []ptr],y
              and        #$7F
              cmp        #' '
              blt        :nopath
              bne        :l1
              iny
              brl        ]lup
:l1           iny
              lda        []ptr],y
              and        #$7F
              cmp        #' '
              blt        :nopath
              bne        :l1
:l2           iny
              lda        []ptr],y
              and        #$7F
              cmp        #' '
              blt        :nopath
              beq        :l2
              cmp        #';'
              beq        :nopath
              rep        $30
              dey
              jsr        :getword             ;look for pathname or save
              bcc        :nopath
              lda        #$0000
              brl        :error
:nopath       rep        $30
              lda        #$46
:error        rep        $30
              tax
              pla
              pla
              txa
              plb
              pld
              plp
              cmp        one
              rts

:pfx          dw         $00
              adrl       filename

*------------------------------------------------------
:getword      php
              sep        $30
              ldx        #0                   ;no chars yet!
              stx        filename
]loop
              iny
              lda        []ptr],y             ;get pathname till eol or delimiter found
              and        #$7F
              clc
              beq        :done                ; 0 = end of line!
              cmp        #'*'
              beq        :inx
              cmp        #'.'
              blt        :done
:inx          inx                             ;part of path, count & store it
              cpx        #65
              bge        :done                ;let's not let the bad boys in!
              cmp        #'a'
              blt        :sta
              cmp        #'z'+1
              bge        :sta
              and        #$5F
:sta          cmp        #'/'
              bne        :sta1
              lda        #':'
:sta1         sta        filename,x           ;update pathname & it's length
              stx        filename
              bra        ]loop
:done         lda        filename
              plp
              cmp        one
              rts

*------------------------------------------------------
* Convert pathname to usable format

convertpath   php
              sep        $30
              ldal       tempbuff
              beq        :plp
              tax
]lup          ldal       tempbuff,x
              and        #$7f
              cmp        #'/'
              bne        :1
              lda        #':'
:1            cmp        #'a'
              blt        :2
              cmp        #'z'+1
              bge        :2
              and        #$5f
:2            stal       tempbuff,x
              dex
              bne        ]lup
:plp          plp
              rts

*======================================================
* Stuff not needed to be saved to disk

              dum        *

launchflags   ds         2

handle        ds         4
number        ds         2
pos           ds         2

setparms      ds         2
pfxptr        ds         4
count         ds         2

filename      ds         130
tempbuff      ds         256

DS_Size       ENT
              dend

              typ        RTL                  ;run time library
              sav        obj/qaintcmd.l

