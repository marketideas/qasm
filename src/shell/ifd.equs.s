*======================================================
* Equates needed in order to use the IFD Libraries
* Design and programming by Lane Roath
* Copyright (c) 1989 Lane Roath & Ideas From the Deep

*------------------------------------------------------
yes = 1 ;readability
no = 0
*------------------------------------------------------
* First, define which routines are to be used today...

AllGrfx = no ;drawing, lines, etc
Allio = yes ;use all the disk IO routines

DrawVBL = no ;wait for VBL before draws?
EraseVBL = no ;wait for VBL before erasing?
Shadowing = no ;draw to shadow'd screen?
Border = no ;show drawing speed on border?

* Routines to draw directly to the screen, erased w/BGBuffer

Place = no ;place frame (use appr. rtns!)

FDraw = no ;direct draw (no mask)
MDraw = no ;masked draw
XMDraw = no ;EOR'd masked draw
XDraw = no ;eor'd draw (no mask)

* The following routines require a background buffer

FErase = no ;direct erase
MErase = no ;masked erase

* These erase routines erase ONLY w/color 0... limited use!

BErase = no ;black erase
ZErase = no ;zap frame erase

* Routines to draw to the screen, use an UNDO buffer to erase!

FDrawU = no ;draw w/undo saves
MDrawU = no ;masked draw w/undo saves
XMDrawU = no ;EOR'd masked draw w/undo
XDrawU = no ;EOR'd draw w/undo (no mask)

Undo = no ;undo above draws

* Define which plotting/line drawing routines to use

XLines = no ;straight line drawing XOR'd
Lines = no ;straight line drawing
QDLines = no ;QD style lines
Dots = no ;dot plotting
XBoxes = no ;box drawing routines
QDBoxes = no ;QD Boxes

* Sound playing routines

PlayHdl = no ;pass Handle to sound
PlayPtr = no ;pass Pointer to sound
PlayTbl = no ;use table & pass offset
CustSnd = no ;custom sound stuff?

* Define which disk I/O routines we will be using

ioPath = no ;path setting
ioRead = no ;read from disk
ioWrite = no ;write to disk
ioGet = no ;get file SF dialog (open)
ioPut = no ;put file SF dialog (save)
ioCopyPath = no ;track multiple paths
DocChk = no ;check for doc click

* Miscellaneous routines we have available

SysErr = yes ;system error dialog
TxtErr = yes ;error handler (text io)
WtEvt = yes ;wait event routine
CtrDlg = yes ;center a dialog
Rndm = yes ;random # routines
VErrs = yes ;volume error handler
MemStuff = no ;memory handling routines
MenuStuff = yes ;menu create/handling rtns
SS_Stuff = yes ;startup/shutdown rtns
AlertWin = yes ;Alert Window routine
DlgStuff = yes ;Misc. dialog stuff
UnPacking = no ;SHR unpacking code

*------------------------------------------------------
 do Allio.ioRead.ioWrite.ioGet.ioPut.ioCopyPath
AnyIO = yes
 else  ;make many tests easier!
AnyIO = no
 fin
*------------------------------------------------------
 do AllGrfx.FDraw.MDraw.XMDraw.FDrawU.MDrawU.XMDrawU.XDraw.XDrawU
Draw = yes
 else  ;using any drawing routines?
Draw = no
 fin
*------------------------------------------------------
 do AllGrfx.MErase.FErase.Undo
Erase = yes
 else ;using any erase routines?
Erase = no
 fin
*------------------------------------------------------
 do AllGrfx.XLines.Lines.QDLines.Dots.XBoxes.QDBoxes
Plot = yes
 else  ;using any plotting routines
Plot = no
 fin
*------------------------------------------------------
 do Draw.Plot ;all we need to check!
AnyGrfx = yes
 else  ;make alot of tests much easier!
AnyGrfx = no
 fin
*------------------------------------------------------
 do PlayHdl.PlayPtr.PlayTbl
AnySound = yes
 else ;are we using any sound routines?
AnySound = no
 fin

*======================================================
* Define IFD Zero page usage.  We don't need much...

 dum 0
Ptr ds 4 ;misc
Hdl ds 4 ;misc

ID ds 2 ;user ID's for memory allocation
ID2 ds 2
ID3 ds 2

temp ds 4
temp2 ds 4 ;we use this area for lots of shit!
temp3 ds 4

 do AnyGrfx ;--- only used by grfx routines ---

ytemp ds 2 ;drawing temps!
xtemp ds 2

xloc ds 2 ;drawing coords
yloc ds 2

x_size = temp
y_add = temp2
x_loc = temp2+2 ;only used in Setup
ScnPtr = temp3+2
y_loc = ytemp

 do Erase.AllGrfx
ErasePtr = * ;only used by ERASE!
 fin

FramePtr ds 4 ;pointer to frame bits
MaskPtr ds 4 ;pointer to frame's mask

 do Undo.AllGrfx
UndoIdx ds 2 ;length of undo buffer
UndoPtr ds 4 ;pointer to undo buffer
 fin

 fin

 do AnySound ;only needed for sound routines
SoundOff ds 2 ;BFL = play sound, BTR = don't
 fin

EndZP = * ;report size of ZP to user

 dend

*------------------------------------------------------
* Define the various data definitions we use

 dum 0 ;image header definition
I_Type ds 2
I_Frames ds 2
I_YSize ds 2
I_XSize ds 2
I_YHSize ds 2
I_XHSize ds 2
I_Table = * ;start of DA table
 dend

 dum 0 ;Sound Shop sound file def
HFileID ds 4
HDataOffset ds 4
HVersID ds 4
HDataID ds 4
HLength2 ds 2
HPbRate2 ds 2
HVolume2 ds 2
HEcho2 ds 2
HLength ds 2
HAce ds 2
HPbRate ds 2
HVolume ds 2
HStereo ds 2
HEcho ds 2
HReserved ds 2
HRepeat ds 2
HOffset1 ds 4
HExtra ds 4
HFileName ds 16
SSData = * ;start of digitized 8bit data
 dend

*------------------------------------------------------
* Some general equates

ScnWidth = 640 ;width of screen in lines
ScnBytes = 160 ;bytes per scan line
ScnLines = 200 ;scan line count

 do Shadowing
ScnBase = $012000 ;NOT always safe to use these!
SCBBase = $019D00
PltBase = $019E00
 else
ScnBase = $E12000 ;always safe to use these!
SCBBase = $E19D00
PltBase = $E19E00
 fin
SHR_size = $8000 ;size of base SHR screen
ScnSize = SHR_size

VBLReg = $E0C019 ;VBL register
VideoCounters = $E0C02E ;vertical & horizontal (word)
ShadowReg = $E0C035 ;shadowing register

Keyboard = $E0C000 ;read keypresses (BMI = new)
KeyClear = $E0C010 ;clear keypress (set ^ BPL)
KeyIsUp? = KeyClear ;BMI = key down, BPL = key up

OA_Key = $E0C061 ;BMI = pressed (buttons 0 & 1)
SA_Key = $E0C062 ;BMI = Pressed ( of joystick )

yVect = $0003F8 ;CTRL-Y vector in monitor

CR = 'M'&$1F
SPC = ' '

*=====================================================================
* These equates can be used with the GSOS.MACS in the MACRO.LIBRARY
* directory.  You can also copy the data structures at the end of this
* file directly into your own source files.

*------------------------------------------------------
* File access - CreateRec, OpenRec access and requestAccess fields

readEnable = %0000001 ;read enable bit:
writeEnable = %0000010 ;write enable bit:
backupNeeded = %0010000 ;backup needed bit:must be '0' in requestAccess field )
renameEnable = %0100000 ;rename enable bit:
destroyEnable = %1000000 ;read enable bit:

* base - > setMark = ...

startPlus = $0000 ;base - setMark = displacement
eofMinus = $0001 ;base - setMark = eof - displacement
markPlus = $0002 ;base - setMark = mark + displacement
markMinus = $0003 ;base - setMark = mark - displacement

* cachePriority

noCache = $0000 ;cachePriority - do not cache blocks invloved in this read
cache = $0001 ;cachePriority - cache blocks invloved in this read if possible

*------------------------------------------------------
* GS/OS Error codes

badSystemCall = $0001 ;bad system call number
invalidPcount = $0004 ;invalid parameter count
gsosActive = $0007 ;GS/OS already active
devNotFound = $0010 ;device not found
invalidDevNum = $0011 ;invalid device number
drvrBadReq = $0020 ;bad request or command
drvrBadCode = $0021 ;bad control or status code
drvrBadParm = $0022 ;bad call parameter
drvrNotOpen = $0023 ;character device not open
drvrPriorOpen = $0024 ;character device already open
irqTableFull = $0025 ;interrupt table full
drvrNoResrc = $0026 ;resources not available
drvrIOError = $0027 ;I/O error
drvrNoDevice = $0028 ;device not connected
drvrBusy = $0029 ;call aborted, driver is busy
drvrWrtProt = $002B ;device is write protected
drvrBadCount = $002C ;invalid byte count
drvrBadBlock = $002D ;invalid block address
drvrDiskSwitch = $002E ;disk has been switched
drvrOffLine = $002F ;device off line/ no media present
badPathSyntax = $0040 ;invalid pathname syntax
invalidRefNum = $0043 ;invalid reference number
pathNotFound = $0044 ;subdirectory does not exist
volNotFound = $0045 ;volume not found
fileNotFound = $0046 ;file not found
dupPathname = $0047 ;create or rename with existing name
volumeFull = $0048 ;volume full error
volDirFull = $0049 ;volume directory full
badFileFormat = $004A ;version error (incompatible file format)
badStoreType = $004B ;unsupported (or incorrect) storage type
eofEncountered = $004C ;end-of-file encountered
outOfRange = $004D ;position out of range
invalidAccess = $004E ;access not allowed
buffTooSmall = $004F ;buffer too small
fileBusy = $0050 ;file is already open
dirError = $0051 ;directory error
unknownVol = $0052 ;unknown volume type
paramRangeErr = $0053 ;parameter out of range
outOfMem = $0054 ;out of memory
dupVolume = $0057 ;duplicate volume name
notBlockDev = $0058 ;not a block device
invalidLevel = $0059 ;specifield level outside legal range
damagedBitMap = $005A ;block number too large
badPathNames = $005B ;invalid pathnames for ChangePath
notSystemFile = $005C ;not an executable file
osUnsupported = $005D ;Operating System not supported
stackOverflow = $005F ;too many applications on stack
dataUnavail = $0060 ;Data unavailable
endOfDir = $0061 ;end of directory has been reached
invalidClass = $0062 ;invalid FST call class
resNotFound = $0063 ;file does not contain required resource

*------------------------------------------------------
* FileSysID's

proDOS = $0001 ;ProDOS/SOS
dos33 = $0002 ;DOS 3.3
dos32 = $0003 ;DOS 3.2
dos31 = $0003 ;DOS 3.1
appleIIPascal = $0004 ;Apple II Pascal
mfs = $0005 ;Macintosh (flat file system)
hfs = $0006 ;Macintosh (hierarchical file system)
lisa = $0007 ;Lisa file system
appleCPM = $0008 ;Apple CP/M
charFST = $0009 ;Character FST
msDOS = $000A ;MS/DOS
highSierra = $000B ;High Sierra

*  fileSysID (NEW FOR GSOS 5.0)

ProDOSFSID = $01 ;ProDOS/SOS
dos33FSID = $02 ;DOS 3.3
dos32FSID = $03 ;DOS 3.2
dos31FSID = $03 ;DOS 3.1
appleIIPascalFSID = $04 ;Apple II Pascal
mfsFSID = $05 ;Macintosh (flat file system)
hfsFSID = $06 ;Macintosh (hierarchical file system)
lisaFSID = $07 ;Lisa file system
appleCPMFSID = $08 ;Apple CP/M
charFSTFSID = $09 ;Character FST
msDOSFSID = $0A ;MS/DOS
highSierraFSID = $0B ;High Sierra
ISO9660FSID = $0C ;ISO 9660
AppleShare = $0D ;AppleShare

* FSTInfo.attributes

characterFST = $4000 ;character FST
ucFST = $8000 ;SCM should upper case pathnames before
; passing them to the FST
* QuitRec.flags

onStack = $8000 ;place state information about quitting
; program on the quit return stack
restartable = $4000 ;the quitting program is capable of being
; restarted from its dormant memory
* StorageType

seedling = $0001 ;standard file with seedling structure
standardFile = $01 ;standard file type (no resource fork)
sapling = $0002 ;standard file with sapling structure
tree = $0003 ;standard file with tree structure
pascalRegion = $0004 ;UCSD Pascal region on a partitioned disk
extendedFile = $0005 ;extended file type (with resource fork)
directoryFile = $000D ;volume directory or subdirectory file

* version

minorRelNum = $00FF ;version - minor release number
majorRelNum = $7F00 ;version - major release number
finalRel = $8000 ;version - final release

isFileExtended = $8000

*------------------------------------------------------
*  GSOS Call ID numbers

* Set 'Class1' to $2000 to use Class 1 calls, $0000 for Class 0 calls

*Class1 = $2000

prodos = $E100A8

_Create = $0001.Class1
_Destroy = $0002.Class1
_OSShutdown = $2003 ;class '1' only
_ChangePath = $0004.Class1
_SetFileInfo = $0005.Class1
_GetFileInfo = $0006.Class1
_Volume = $0008.Class1
_SetPrefix = $0009.Class1
_GetPrefix = $000A.Class1
_ClearBackup = $000B.Class1
_SetSysPrefs = $200C ;class '1' only
_Null = $200D ;class '1' only
_ExpandPath = $200E ;class '1' only
_GetSysPrefs = $200F ;class '1' only
_Open = $0010.Class1
_Newline = $0011.Class1
_Read = $0012.Class1
_Write = $0013.Class1
_Close = $0014.Class1
_Flush = $0015.Class1
_SetMark = $0016.Class1
_GetMark = $0017.Class1
_SetEOF = $0018.Class1
_GetEOF = $0019.Class1
_SetLevel = $001A.Class1
_GetLevel = $001B.Class1
_GetDirEntry = $001C.Class1
_BeginSession = $201D ;class '1' only
_EndSession = $201E ;class '1' only
_SessionStatus = $201F ;class '1' only
_GetDevNumber = $0020.Class1
_GetLastDev = $0021.Class1
_ReadBlock = $0022 ;class '0' only
_WriteBlock = $0023 ;class '0' only
_Format = $0024.Class1
_EraseDisk = $0025.Class1
_ResetCache = $2026 ;class '1' only
_GetName = $0027.Class1
_GetBootVol = $0028.Class1
_Quit = $0029.Class1
_GetVersion = $002A.Class1
_GetFSTInfo = $202B ;class '1' only
_DInfo = $002C.Class1
_DStatus = $202D ;class '1' only
_DControl = $202E ;class '1' only
_DRead = $202F ;class '1' only
_DWrite = $2030 ;class '1' only
_AllocInterrupt = $0031 ;P16 call
_BindInt = $2031 ;GS/OS call
_DeallocInterrupt = $0032 ;P16 call
_UnbindInt = $2032 'GS/OS call
_AddNotifyProc = $2034 ;class '1' only
_DelNotifyProc = $2035 ;class '1' only
_DRename = $2036 ;class '1' only
_GetStdRefNum = $2037 ;class '1' only
_GetRefNum = $2038 ;class '1' only
_GetRefInfo = $2039 ;class '1' only

 fin ;--- disk IO equates ---
