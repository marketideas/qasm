              lst   off

maxsymbols    equ   $2000

shellflag     =     %0000_0001  ;shell
asmflag       =     %0000_0010  ;asm
linkflag      =     %0000_0100  ;linker
editflag      =     %0000_1000  ;editor
cmddflag      =     %0001_0000  ;command processor

shellmemid    =     $100        ;these are OR'd with individual USERIDs
asmmemid      =     $100        ;and are GLOBAL...individual programs
linkmemid     =     $100        ;should request/dispose memory of an ID
editmemid     =     $100        ;HIGHER than these on a local basis.
cmdmemid      =     $100

              dum   $00

shelldp       ds    2
globalsdp     ds    2
asmdp         ds    2
linkdp        ds    2
editdp        ds    2
cmddp         ds    2

goshellptr    ds    4
goasmptr      ds    4
golinkptr     ds    4
goeditptr     ds    4
gocmdptr      ds    4

idactive      ds    2           ;use flags above
idloaded      ds    2

shellhandle   ds    4
asmhandle     ds    4
linkhandle    ds    4
edithandle    ds    4
cmdhandle     ds    4

shellptr      ds    4
asmptr        ds    4
linkptr       ds    4
editptr       ds    4
cmdptr        ds    4

shelluserid   ds    2
asmuserid     ds    2
linkuserid    ds    2
edituserid    ds    2
cmduserid     ds    2


shelllable    ds    32          ;used to pass lables between programs
gobjtype      ds    2           ;default filetype for sav/link
gobjaux       ds    4           ;default auxtype for sav/link

keyquit       ds    2
shellerrors   ds    2           ;used to pass error counts
lasterror     ds    2           ;code of last error to occur

objcodesaved  ds    2           ;<>0 if object code saved by asm

linkfileptr   ds    4           ;pointer to passed data for linker
linkhdlid     ds    2           ;0 = command line
                                ;1 = loaded TXT file

asmfileptr    ds    4           ;pointer to passed data for assembler
asmhdlid      ds    2           ;0 = command line
                                ;1 = loaded TXT file
                                ;2 = filename
asmfilelen    ds    4           ;if above = 1 then this is length of file


editfileptr   ds    4           ;pointer to passed data for editor
edithdlid     ds    2           ;0 = command line
                                ;1 = loaded TXT file

cmdfileptr    ds    4           ;pointer to passed data for cmd processor
cmdhdlid      ds    2           ;0 = command line
                                ;1 = loaded TXT file

editlinenum   ds    2           ;editors current line number

linksymhdl    ds    4
linksymtbl    ds    4
linksymnum    ds    2
linklstflag   ds    2
linknextlbl   ds    4
linkkbdptr    ds    4

extmacptr     ds    4
usrptr        ds    4
userptr       ds    4

              err   */$100
              dend

              lst   rtn


