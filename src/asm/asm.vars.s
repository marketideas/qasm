                tr    on

tcursx          equ   $57b

true            equ   $FFFF
false           equ   $0

stopgo          equ   false
floatingpoint   equ   true

memid           equ   $100
putid           equ   $200
useid           equ   $300

initobjsize     equ   $FFFF
dskobjsize      equ   $1000
relsize         equ   $8000
macsize         equ   $C00*8
macnestmax      equ   16                    ;max mac nest level
maxput          equ   16                    ;max put OR use/lib files (each)
maxlup          equ   16                    ;max lup nesting

**** errcode equates ****

noerror         equ   $00
undeflable      equ   $02
duplable        equ   $03
misalignment    equ   $04

badoperand      equ   $05

notmacro        equ   $07
badopchar       equ   $08
badconditional  equ   $09
badaddress      equ   $0A
badbranch       equ   $0B
forwardref      equ   $0C
twoexternals    equ   $0D
badrelative     equ   $0E
saneerror       equ   $0F
evaltoocomplex  equ   $10

objectfull      equ   $81
symfull         equ   $82
memfull         equ   $83
badput          equ   $84
doserror        equ   $85
relfull         equ   $86
usererror       equ   $87
macrofull       equ   $88
badmacro        equ   $89
nesterror       equ   $8A
badsav          equ   $8B
badopcode       equ   $8C
badinput        equ   $8F
badlable        equ   $90
relfilefull     equ   $91
*badoperand equ $92


filemismatch    equ   $5C


*** Symbol Types ***

localbit        =     %0000_0000_0000_0001
variablebit     =     %0000_0000_0000_0010
macrobit        =     %0000_0000_0000_0100
equatebit       =     %0000_0000_0000_1000
externalbit     =     %0000_0000_0001_0000
macvarbit       =     %0000_0000_0010_0000
linkerbit       =     %0001_0000_0000_0000
usedbit         =     %0010_0000_0000_0000
entrybit        =     %0100_0000_0000_0000
absolutebit     =     %1000_0000_0000_0000



*** Assembly Zpage Equates ***
                dum   $00

labstr          ds    lab_size+1                    ;Lable STR that we are working on
labnum          ds    2                     ;REC num of current lable
lableft         ds    2                     ;B-Tree Structures
labright        ds    2
labprev         ds    2
lablocal        ds    2                     ;REC of Local Lable Tree
labtype         ds    2                     ;Type of Label
labval          ds    4                     ;EQU value of Lable

globlab         ds    2                     ;REC of Current Global Lable
lineptr         ds    4
printptr        ds    4
linelable       ds    2
linehaslab      ds    2
*linelabtxt      ds    lab_size+1,0
linenum         ds    2
totallines      ds    2

fileptr         ds    4
flen            ds    4
filehandle      ds    4
filelen         ds    4

lableptr        ds    4
lableptr1       ds    4
nextlableptr    ds    4

objzpptr        ds    4
relptr          ds    4
macptr          ds    4
macvarptr       ds    2

objct           ds    2
objsize         ds    2
objptr          ds    4
objoffset       ds    4
relct           ds    2
relout          ds    2
reloffset       ds    4
totbytes        ds    4
linerel         ds    2

equateval       ds    4

passnum         ds    2
doneflag        ds    2

modeflag        ds    1

relflag         =     %10000000
dskflag         =     %01000000
putflag         =     %00100000
useflag         =     %00010000
lupflag         =     %00001000
dumflag         =     %00000100
caseflag        =     %00000010
doflag          =     %00000001
                ds    1
tbxflag         =     %10000000
algflag         =     %01000000
encflag         =     %00100000
cycflag         =     %00010000
crcflag         =     %00001000
ifflag          =     %00000100
expflag         =     %00000010
exponly         =     %00000001

modeflag1       ds    1
dupok           =     %00000001
symflag         =     %00000010
                ds    1

macflag         ds    1
                                            ;b7  mac executing
                                            ;b6  external mac
                                            ;b5  internal mac
                                            ;b0  mac init



listflag        ds    2

liston          =     %10000000
lstdoon         =     %01000000
tradron         =     %00100000
branchlst       =     %00010000
lbranchlst      =     %00001000
equlst          =     %00000100
trobjlst        =     %00000010
objlst          =     %00000001


putuse          ds    2
mxflag          ds    1
xcflag          ds    1
forcelong       ds    1
notfound        ds    1
clrglob         ds    1
lableused       ds    2
allmath         ds    2                     ;true = all numbers, 0 = label (after eval)
opflags         ds    2
opdata          ds    2
opcodeword      ds    2

lvalue          ds    4
myvalue         ds    4
noshift         ds    4
lineobjptr      ds    4
pcobjptr        ds    4

xreg            ds    4                     ;variables used by EVAL
yreg            ds    4
val             ds    4
xrel            ds    2
yrel            ds    2
zrel            ds    2
op              ds    2
top             ds    2
deczp           ds    2

checksum        ds    1
crc16           ds    2
cycles          ds    2
cycleavg        ds    2
linecycles      ds    2
cyclemarks      ds    2
cycflags        ds    1
encval          ds    1
tbxand          ds    1
firstchar       ds    2
merrcode        ds    2

linksymtbl      ds    4
linksymhdl      ds    4

keyflag         ds    2

controld        =     %1000_0000
cancelflag      =     %0100_0000
pauseflag       =     %0010_0000
spaceflag       =     %0001_0000

workspace       ds    16
                err   */$100
                dend

* lst
*dpend equ workspace+16 ;length of DP storage
* lst rtn


*** Variables ***

loadid          ds    2
putlevel        ds    2
uselevel        ds    2

opcode          ds    32,0                  ;current opcode
lastlen         ds    2                     ;length of last line

                ds    2                     ;must be before linebuff
linebuff        ds    128,0                 ;operand goes here

comment         ds    256,0

objhdl          ds    4                     ;handle to object buffer

lablect         ds    2
globalct        ds    2
rellabct        ds    2
oldglob         ds    2
dolevel         ds    2
domask          ds    2
maclevel        ds    2
maclocal        ds    2
dumor           ds    2
orgor           ds    2
fllast          ds    2

opmask          ds    2                     ;EVAL variables
number          ds    2
bracevalid      ds    2
estack          ds    2
evallevel       ds    2
evalrelok       ds    2
offset          ds    2
shiftct         ds    2
bytesout        ds    256+2,0
prodoserr       ds    2
errorct         ds    2
objtype         ds    2
objfull         ds    2

tlinenum        ds    2

oldobj          ds    4
oldoffset       ds    4
orgval          ds    4

extmacptr       ds    4,0
dsfill          ds    2
dsoffset        ds    2
erraddress      ds    4
errvalid        ds    2
entcount        ds    2
extcount        ds    2

tabs            dfb   26,36,41,54

macstack        ds    macnestmax+1*32,0
macvars         ds    macnestmax+1*128,0

luplevel        ds    2

dskopen         dw    $00
                adrl  dskpath
                adrl  $0000

dskwrite        dw    $00
dskbuff         adrl  $0000
dskreq          adrl  $0000
dsktran         adrl  $0000

dskeofparm      dw    $00
dskeof          adrl  $0000

dskcreate       adrl  dskpath
                dw    $e3
dskctype        dw    $00
dskcaux         adrl  $00
                dw    $01
dskctime        adrl  $0000
dskinfo         adrl  dskpath
                dw    $00
dsktype         dw    $00
dskaux          adrl  $0000
                ds    16,0
dskdelete       adrl  dskpath

dskclose        dw    $00
dskpath         ds    129,0

atable          ds    128*2,0

titlestr        ds    256,0

linelabtxt      ds    lab_size+1,0

converttable
                hex   00000000000000000000000000000000
                hex   00000000000000000000000000000000
                asc   ' !"#$%&'
                hex   27                    ;the ' character
                asc   '()*+,-./'
                asc   '0123456789'
                asc   ':;<=>?'
                asc   '@ABCDEFGHIJKLMNOPQRSTUVWXYZ'
                asc   '[\]^_'
                asc   '@ABCDEFGHIJKLMNOPQRSTUVWXYZ'
                asc   '[\]^_'               ;DEL is last character
                hex   00000000000000000000000000000000
                hex   00000000000000000000000000000000
                asc   ' !"#$%&'
                hex   27                    ;the ' character
                asc   '()*+,-./'
                asc   '0123456789'
                asc   ':;<=>?'
                asc   '@ABCDEFGHIJKLMNOPQRSTUVWXYZ'
                asc   '[\]^_'
                asc   '@ABCDEFGHIJKLMNOPQRSTUVWXYZ'
                asc   '[\]^_'               ;DEL is last character

inputtbl
                hex   202020202020202020202020200d2020
                hex   20202020202020202020202020202020
                asc   ' !"#$%&'
                hex   27                    ;the ' character
                asc   '()*+,-./'
                asc   '0123456789'
                asc   ':;<=>?'
                asc   '@ABCDEFGHIJKLMNOPQRSTUVWXYZ'
                asc   '[\]^_'
                asc   '`abcdefghijklmnopqrstuvwxyz'
                asc   '{|}~'
                hex   20                    ;delete
                hex   202020202020202020202020200d2020
                hex   20202020202020202020202020202020
                asc   ' !"#$%&'
                hex   27                    ;the ' character
                asc   '()*+,-./'
                asc   '0123456789'
                asc   ':;<=>?'
                asc   '@ABCDEFGHIJKLMNOPQRSTUVWXYZ'
                asc   '[\]^_'
                asc   '`abcdefghijklmnopqrstuvwxyz'
                asc   '{|}~'
                hex   20                    ;delete

