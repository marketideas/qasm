* ProDOS 8 boot block for a SmartPort / block device.
* Firmware may enter at $0800 or $0801. X is the slot times 16
* and is the drive-1 unit number. The driver entry is $Cn00
* plus the byte at $CnFF. During the call:
*   $42 command (1 reads), $43 unit, $44-$45 buffer, $46-$47 block.
* Carry set means the read failed. No other zero page is used.
* The file named PRODOS, type $FF, is loaded at $2000 and entered.

        ORG   $0800

        CLD
        CLD
        STX   UNIT
        TXA
        LSR
        LSR
        LSR
        LSR
        ORA   #$C0
        STA   SLOT
        LDA   #$FF
        STA   PEEK+1
        LDA   SLOT
        STA   PEEK+2
PEEK    LDA   $C000
        STA   CALL+1
        LDA   SLOT
        STA   CALL+2

        LDA   #2
        STA   BLOCK
        LDA   #0
        STA   BLOCK+1
        LDA   $1024
        STA   EMAX

NEXTDIR LDA   #$00
        STA   BUF
        LDA   #$10
        STA   BUF+1
        JSR   RDBLK
        BCC   DIRGOT
        JMP   FAIL
DIRGOT  LDA   #$04
        STA   ENT
        LDA   #$10
        STA   ENT+1
        LDA   #0
        STA   ECNT

NEXTENT LDA   ECNT
        CMP   EMAX
        BCC   DOENT
        JMP   DONEDIR
DOENT   LDY   #0
        JSR   GETBYT
        STA   STOR
        AND   #$0F
        STA   NLEN
        LDA   STOR
        LSR
        LSR
        LSR
        LSR
        BEQ   STEP
        CMP   #$0F
        BEQ   STEP
        CMP   #$0E
        BEQ   STEP
        CMP   #1
        BCC   STEP
        CMP   #4
        BCS   STEP
        LDA   NLEN
        CMP   #6
        BNE   STEP
        LDY   #$10
        JSR   GETBYT
        CMP   #$FF
        BNE   STEP
        LDX   #0
        LDY   #1
CMPNM   JSR   GETBYT
        CMP   NAME,X
        BNE   STEP
        INY
        INX
        CPX   #6
        BNE   CMPNM

        LDA   STOR
        LSR
        LSR
        LSR
        LSR
        STA   KIND
        LDY   #$11
        JSR   GETBYT
        STA   KEY
        INY
        JSR   GETBYT
        STA   KEY+1
        LDY   #$15
        JSR   GETBYT
        STA   LEFT
        INY
        JSR   GETBYT
        STA   LEFT+1
        INY
        JSR   GETBYT
        STA   LEFT+2
        JMP   LOAD

STEP    CLC
        LDA   ENT
        ADC   #$27
        STA   ENT
        BCC   STEPHI
        INC   ENT+1
STEPHI  INC   ECNT
        JMP   NEXTENT

DONEDIR LDY   #2
        LDA   $1000,Y
        STA   BLOCK
        INY
        LDA   $1000,Y
        STA   BLOCK+1
        ORA   BLOCK
        BNE   MOREDIR
        JMP   FAIL
MOREDIR JMP   NEXTDIR

* Keep the file below $BF00. $9F00 bytes fits.
LOAD    LDA   LEFT+2
        BNE   CAP
        LDA   LEFT+1
        CMP   #$9F
        BCC   NOCAP
        BNE   CAP
        LDA   LEFT
        BEQ   NOCAP
CAP     LDA   #0
        STA   LEFT
        STA   LEFT+2
        LDA   #$9F
        STA   LEFT+1
NOCAP   LDA   #$00
        STA   DEST
        LDA   #$20
        STA   DEST+1
        LDA   KIND
        CMP   #1
        BEQ   SEED
        CMP   #2
        BEQ   SAP
        CMP   #3
        BEQ   TREE
        JMP   FAIL

SEED    LDA   KEY
        STA   BLOCK
        LDA   KEY+1
        STA   BLOCK+1
        JSR   ONEBLK
        JMP   $2000

SAP     LDA   KEY
        STA   BLOCK
        LDA   KEY+1
        STA   BLOCK+1
        JSR   READIDX
        LDA   #0
        STA   IDX
SAPN    LDX   IDX
        LDA   $1000,X
        STA   BLOCK
        LDA   $1100,X
        STA   BLOCK+1
        JSR   ONEBLK
        INC   IDX
        BNE   SAPN
        JMP   $2000

TREE    LDA   KEY
        STA   BLOCK
        LDA   KEY+1
        STA   BLOCK+1
        LDA   #0
        STA   BUF
        LDA   #$12
        STA   BUF+1
        JSR   RDBLK
        BCC   TREEG
        JMP   FAIL
TREEG   LDA   #0
        STA   MIDX
TNXT    LDX   MIDX
        LDA   $1200,X
        STA   BLOCK
        LDA   $1300,X
        STA   BLOCK+1
        ORA   BLOCK
        BEQ   TZERO
        JSR   READIDX
        LDA   #0
        STA   IDX
TN      LDX   IDX
        LDA   $1000,X
        STA   BLOCK
        LDA   $1100,X
        STA   BLOCK+1
        JSR   ONEBLK
        INC   IDX
        BNE   TN
        JMP   TSTEP
TZERO   LDA   #0
        STA   IDX
TZ      LDA   #0
        STA   BLOCK
        STA   BLOCK+1
        JSR   ONEBLK
        INC   IDX
        BNE   TZ
TSTEP   INC   MIDX
        BNE   TNXT
        JMP   $2000

READIDX LDA   #0
        STA   BUF
        LDA   #$10
        STA   BUF+1
        JSR   RDBLK
        BCC   IDXOK
        JMP   FAIL
IDXOK   RTS

* One data block. A zero block number is a hole.
* Jump to $2000 once the requested length is in memory.
ONEBLK  LDA   LEFT
        ORA   LEFT+1
        ORA   LEFT+2
        BNE   MORE
        JMP   $2000
MORE    LDA   BLOCK
        ORA   BLOCK+1
        BEQ   ZERO
        LDA   DEST
        STA   BUF
        LDA   DEST+1
        STA   BUF+1
        JSR   RDBLK
        BCC   ADV
        JMP   FAIL
ZERO    LDA   DEST+1
        STA   Z1+2
        CLC
        ADC   #1
        STA   Z2+2
        LDY   #0
        TYA
Z1      STA   $2000,Y
        INY
        BNE   Z1
Z2      STA   $2100,Y
        INY
        BNE   Z2
ADV     LDA   LEFT+2
        BNE   FULL
        LDA   LEFT+1
        CMP   #2
        BCS   FULL
        JMP   $2000
FULL    INC   DEST+1
        INC   DEST+1
        LDA   LEFT+1
        SEC
        SBC   #2
        STA   LEFT+1
        BCS   ADVD
        DEC   LEFT+2
ADVD    RTS

GETBYT  LDA   ENT
        STA   GB+1
        LDA   ENT+1
        STA   GB+2
GB      LDA   $1000,Y
        RTS

RDBLK   LDA   $CFFF
        LDA   #1
        STA   $42
        LDA   UNIT
        STA   $43
        LDA   BUF
        STA   $44
        LDA   BUF+1
        STA   $45
        LDA   BLOCK
        STA   $46
        LDA   BLOCK+1
        STA   $47
CALL    JSR   $C000
        RTS

FAIL    LDY   #0
PR      LDA   MSG,Y
        BEQ   HANG
        JSR   $FDED
        INY
        BNE   PR
HANG    JMP   HANG

MSG     HEX   CE,CF,A0,D0,D2,CF,C4,CF,D3,8D,00
NAME    HEX   50524F444F53

UNIT    DS    1
SLOT    DS    1
BLOCK   DS    2
BUF     DS    2
ENT     DS    2
ECNT    DS    1
EMAX    DS    1
STOR    DS    1
NLEN    DS    1
KIND    DS    1
KEY     DS    2
LEFT    DS    3
DEST    DS    2
IDX     DS    1
MIDX    DS    1

        DS    $0C00-*
