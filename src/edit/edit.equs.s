*======================================================
* Equates for QuickEdit v2.00... written by Lane Roath

cda           equ   0           ;0=EXE file,1=CDA
library       equ   0           ;is QE a part of another program?
softdisk      equ   0           ;include SOFTDISK code?
mouse         equ   0           ;allow mouse control?

debug         equ   0           ;Must be ZERO
right         equ   80          ;right margin value
catentries    equ   9           ;how many "catalog" entries to show

dplength      equ   $100

              dum   1
toobigerr     ds    1
nottext       ds    1
syntaxerr     ds    1
outofmem      ds    1
notdir        ds    1
              dend

              dum   $00         ;zero page usage
zpage         ds    4
zpage1        ds    4
fileptr       ds    4
tempzp        ds    4
tempzp1       ds    4
basl          ds    2

cliphandle    ds    4
editbufhdl    ds    4

termch        ds    2
termcv        ds    2
mych          ds    2
mycv          ds    2
base          ds    2
tcursx        ds    2
tcursy        ds    2

dirzp         ds    4

asynckey      ds    2
showcr        ds    2
superquit     ds    2
loaderstat    ds    2
oflag         ds    2
linenum       ds    2
gotolnum      ds    2
gotoposition  ds    2
marker        ds    2
xval          ds    2
yval          ds    2
aval          ds    2
emstarted     ds    2
intstatus     ds    2
textdevice    ds    4
texttype      ds    2
textor        ds    2
textand       ds    2
grafentry     ds    2
flen          ds    2
oldlen        ds    2
pos           ds    2
pos1          ds    2
eof           ds    2
sof           ds    2
position      ds    2
dirty         ds    2
alldirty      ds    2
selstart      ds    2
selend        ds    2
selecting     ds    2
selectflag    ds    2
equitflag     ds    2
workspace     ds    16

              err   */$100
              dend

