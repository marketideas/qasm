
_DisposeAll     MAC
        tll     $1102
        <<<
_HLock  MAC
        tll     $2002
        <<<
_HUnlock        MAC
        tll     $2202
        <<<
_GetHandleSize MAC
        tll $1802
        <<<
_SetHandleSize MAC
        tll $1902
        <<<
_NewHandle MAC
        tll $902
        <<<
_PurgeAll MAC
        tll $1302
        <<<
_CompactMem MAC
        tll $1F02
        <<<
_ReadTimeHex MAC
        tll $D03
        <<<
_ReadAsciiTime MAC
        tll $F03
        <<<
_SysBeep MAC
        tll $2C03
        <<<
_Long2Dec MAC
        tll $270B
        <<<
_LongDivide MAC
        tll $D0B
        <<<
_WriteString MAC
        tll $1C0C
        <<<

_SANEFP816      MAC
        tll     $90A
        <<<
_SANEDecStr816  MAC
        tll     $A0A
        <<<

FOPRF   MAC             ;call FP
        PEA     ]1
        _SANEFP816
        <<<
FOPRD   MAC             ;call DecStr
        PEA     ]1
        _SANEDecStr816
        <<<

FDEC2X  MAC
        FOPRF   $009
        <<<
FPSTR2DEC       MAC             ;pascal string to decimal record
        FOPRD   0
        <<<





_setmark        MAC
        jsl     $e100a8
        da      $16
        adrl    ]1
        <<<

_getmark        MAC
        jsl     $e100a8
        da      $17
        adrl    ]1
        <<<

_getprefix      MAC
        jsl     $e100a8
        da      $0a
        adrl    ]1
        <<<

_create MAC
        jsl     $e100a8
        da      $01
        adrl    ]1
        <<<

_setfileinfo    MAC
        jsl     $e100a8
        da      $05
        adrl    ]1
        <<<
_getfileinfo    MAC
        jsl     $e100a8
        da      $06
        adrl    ]1
        <<<

_open   MAC
        jsl     $e100a8
        da      $10
        adrl    ]1
        <<<
_write  MAC
        jsl     $e100a8
        da      $13
        adrl    ]1
        <<<
_close  MAC
        jsl     $e100a8
        da      $14
        adrl    ]1
        <<<
_seteof MAC
        jsl     $e100a8
        da      $18
        adrl    ]1
        <<<

opno    mac
        sec
        rts
        <<<

opco    mac
        db      $c9     ; cmp #
        usr     ]1
        bne     nope
        ldx     #]2
        ldy     #]3
        clc
        rts
nope
        <<<

opcl    mac
        if $=]1
        else
        opco ]1;]2;]3
        fin
        sec
        rts
        <<<

opcx    mac
        db      $c9     ; cmp #
        usr     ]1
        bne     nope
        ldx     #]2
        ldy     #^]2
        clc
        rts
nope
        <<<

opcxl   mac
        opcx ]1;]2
        sec
        rts
        <<<
