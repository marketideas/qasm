                  mx    %00
omfprint          equ   0

maxlinklab        equ   $4000                 ;8192 linker lables
maxfiles          equ   100                   ;maximum link files
maxsegs           equ   256

namelen           equ   10                    ;length of segment names

syntax            equ   $01+$80
doserror          equ   $02+$80
mismatch          equ   $5C

badasmcmd         equ   $04
badcmd            equ   $06+$80
badlable          equ   $07
outofmem          equ   $08+$80
undeflable        equ   $09
badoperand        equ   $0a
badrelative       equ   $0b
symfull           equ   $0c+$80
baddictionary     equ   $0d+$80
badexternal       equ   $0e
extnotzp          equ   $0f
maxsegments       equ   $10
relfull           equ   $11+$80
dupentry          equ   $12
maxfileserr       equ   $13+$80
onesave           equ   $14+$80
badvalue          equ   $15+$80
badalignop        equ   $16
jmptblfull        equ   $17+$80
baddsop           equ   $18+$80
constraint        equ   $19+$80
notresolved       equ   $20
illegalcmd        equ   $21+$80
filetoolarge      equ   $22
nesterror         equ   $23+$80
forwardref        equ   $24
badopchar         equ   $25
evaltoocomplex    equ   $26
duplable          equ   $27

*** label bit flags (used in linker)

linkgeqbit        =     %0100_0000_0000_0000
linkequbit        =     %0010_0000_0000_0000
linkequ1bit       =     %0001_0000_0000_0000
linkentrybit      =     %0000_1000_0000_0000
linkabsbit        =     %0000_0100_0000_0000
linkusedbit       =     %0000_0010_0000_0000
linkequvalid      =     %0000_0001_0000_0000
linkentused       =     %0000_0000_1000_0000

*** label bit flags (used in assembler) ***

localbit          =     %0000_0000_0000_0001
variablebit       =     %0000_0000_0000_0010
macrobit          =     %0000_0000_0000_0100
equatebit         =     %0000_0000_0000_1000
externalbit       =     %0000_0000_0001_0000
macvarbit         =     %0000_0000_0010_0000
linkerbit         =     %0001_0000_0000_0000
usedbit           =     %0010_0000_0000_0000
entrybit          =     %0100_0000_0000_0000
absolutebit       =     %1000_0000_0000_0000




**** Segment Record Offsets ****
                  dum   $00
kindfield         ds    2
alignfield        ds    4
dsfield           ds    4
orgfield          ds    4
                  dend

                  do    doexpress
**** ExpressLoad equates ****

emaxsegments      equ   12                    ;only allow 12 segments in EXPRESS

notomf            equ   $8001
notomf2           equ   $8002
toomanysegs       equ   $8003
alreadyexpressed  equ   $8004
badsegnum         equ   $8005
badomfrec         equ   $8006
invalidexphdr     equ   $8007

                  dum   $00
oldsegnum         ds    2
newsegnum         ds    2
ekind             ds    2
fileoffset        ds    4
newfileoffset     ds    4
headerlen         ds    2
enamelen          ds    2
processed         ds    2
slcsize           ds    4
srelocsize        ds    4
                  dend
                  fin

**** DP storage ****
                  dum   $00
zpage             ds    4
labstr            ds    lab_size+1            ;Lable STR that we are working on
labnum            ds    2                     ;REC num of current lable
lableft           ds    2                     ;B-Tree Structures
labright          ds    2
labprev           ds    2
lablocal          ds    2                     ;REC of Local Lable Tree
labtype           ds    2                     ;Type of Label
labval            ds    4                     ;EQU value of Lable
*foundlable        ds    sym_size              ;lable REC returned from FINDLABLE
globlab           ds    2                     ;REC of Current Global Lable
myvalue           ds    4
lvalue            ds    4
caseflag          ds    2
lableptr          ds    4
lableptr1         ds    4
nextlableptr      ds    4
asmnextlable      ds    4
lasmptr           ds    4
lasmptr1          ds    4
cptr              ds    4
cptr1             ds    4
clength           ds    4

tempptr           ds    4
tempptr1          ds    4
tempptr2          ds    4
segmentptr        ds    4
relptr            ds    4

filehandle        ds    4
filelen           ds    4
fileptr           ds    4
flen              ds    4
dirptr            ds    4
dirct             ds    2
linkaddress       ds    4
lineptr           ds    4
jmpptr            ds    4
jmphdl            ds    4
subtype           ds    4

modeflag          ds    2
doflag            =     %0000_0000_1000_0000

                  do    doexpress
*** Express DP ***
seghdrhdl         ds    4
seghdrptr         ds    4
segdatahdl        ds    4
segdataptr        ds    4
exphdl            ds    4
expptr            ds    4
                  fin

xreg              ds    4                     ;variables used by EVAL
yreg              ds    4
val               ds    4
xrel              ds    2
yrel              ds    2
zrel              ds    2
op                ds    2
top               ds    2
deczp             ds    2

workspace         ds    16

                  lst
here              =     *
                  lst   off
                  err   */$100
                  dend

foundlable        ds    sym_size              ;lable REC returned from FINDLABLE

asmpath           ds    130,0
rezpath           ds    130,0

loadid            ds    2

                  do    doexpress
currentseg        ds    2
currentseghdr     ds    2
numsegments       ds    2
lcsize            ds    4
relocsize         ds    4
expsize           ds    4
remapseg          ds    2
expoffset         ds    4
filemark          ds    4
                  fin

rellength         ds    4
interseg          ds    2
reloffset         ds    4
passnum           ds    2
omfoff1           ds    2
omfoff2           ds    2
omfshift          ds    2
omfbytes          ds    2
omfcode           ds    2
omflength         ds    2
linenum           ds    2
maxsegnum         ds    2
message           ds    2
domask            ds    2
dolevel           ds    2


orgval            ds    4
adrval            ds    4
globalhdl         ds    4
segmenthdl        ds    4
lnkflag           ds    2
lablect           ds    2
asmlablect        ds    2
cancelflag        ds    2
totalerrs         ds    2
linkversion       ds    2
omfversion        ds    2
verchg            ds    2
lkvchg            ds    2
zipflag           ds    2
notfound          ds    2
opflag            ds    2
shiftct           ds    2
savcount          ds    2
lableused         ds    2
noshift           ds    4
compresshdl       ds    4
outfileopen       ds    2
objok             ds    2
linktype          ds    2
totalbytes        ds    4
omfok             ds    2
bankorg           ds    2                     ;used to set segment load bank
jmplength         ds    2
dynamic           ds    2
extseg            ds    2
quicklink         ds    2

linksymhdl        ds    4
linksymtbl        ds    4
linksymnum        ds    2
linknextlbl       ds    4


opmask            ds    2                     ;EVAL variables
number            ds    2
bracevalid        ds    2
estack            ds    2
evallevel         ds    2
evalrelok         ds    2
offset            ds    2
*shiftct ds 2


errlable          ds    16,0
errpos            ds    2

newlable          ds    18,0

segheader
bytecnt           ds    4
resspc            ds    4,0
seglength         ds    4
lablen            dw    namelen*256
numlen            hex   04
version           hex   02
banksize          adrl  $10000
kind              dw    $1000
                  ds    2,0
org               adrl  $00
align             adrl  $00
numsex            hex   00
                  hex   00
segnum            ds    2
entry             adrl  $00
dispname          dw    44
disdata           dw    54+namelen
loadname          ds    namelen
segname           ds    namelen
lconst            hex   f2
lcbytes           hex   00000000

seghdrlen         dw    lconst-segheader


omfheader1
blkcount          ds    4
resspc1           ds    4
seglength1        ds    4
kind1             hex   00
lablen1           dfb   namelen
numlen1           dfb   4
version1          dfb   1
banksize1         adrl  $10000
                  adrl  $00
org1              adrl  $00
align1            adrl  $00
numsex1           dfb   0
lcbank            dfb   0
segnum1           dw    0
entry1            adrl  0
dispname1         ds    namelen*2+4
lconst1           hex   f200000000

seghdrlen1        dw    lconst1-omfheader1

extrabytes        ds    2

