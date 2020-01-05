_DisposeHandle  MAC
        tll     $1002
        <<<
_DisposeAll     MAC
        tll     $1102
        <<<
_NewHandle      MAC
        tll     $902
        <<<
_GetHandleSize  MAC
        tll     $1802
        <<<
_SetHandleSize  MAC
        tll     $1902
        <<<
_HLock  MAC
        tll     $2002
        <<<
_HUnlock        MAC
        tll     $2202
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
_destroy        MAC
        jsl     $e100a8
        da      $02
        adrl    ]1
        <<<
_changepath     MAC
        jsl     $e100a8
        da      $04
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
_read   MAC
        jsl     $e100a8
        da      $12
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
opc     mac
        usr     ]1
        dw      ]2
        dw      ]3
        <<<

