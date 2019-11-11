_NEWHANDLE        MAC
                  Tool   $902
                  <<<
_DISPOSEHANDLE    MAC
                  Tool   $1002
                  <<<
_GETHANDLESIZE    MAC
                  Tool   $1802
                  <<<
_SETHANDLESIZE    MAC
                  Tool   $1902
                  <<<
_HLOCK            MAC
                  Tool   $2002
                  <<<
_HUNLOCK          MAC
                  Tool   $2202
                  <<<
^READTIMEHEX      MAC
                  PHS    4
                  Tool   $D03
                  <<<
^READASCIITIME    MAC
                  PHL    ]1
                  Tool   $F03
                  <<<
^GETNEXTEVENT     MAC
                  PHA
                  PHWL   ]1;]2
                  Tool   $A06
                  <<<
^SETVECTOR        MAC
                  PHWL   ]1;]2
                  Tool   $1003
                  <<<
^GETVECTOR        MAC
                  P2SW   ]1
                  Tool   $1103
                  <<<
PHWL              MAC
                  PHW    ]1
                  PHL    ]2
                  <<<
P2SW              MAC
                  PHA
                  PHA
                  IF     #=]1
                  PEA    ]1
                  ELSE
                  IF     MX/2
                  LDA    ]1+1
                  PHA
                  FIN
                  LDA    ]1
                  PHA
                  FIN
                  <<<
PSW               MAC
                  IF     #=]1
                  PEA    ]1
                  ELSE
                  IF     MX/2
                  LDA    ]1+1
                  PHA
                  FIN
                  LDA    ]1
                  PHA
                  FIN
                  <<<
PSL               mac
                  if     #,]1
                  pea    ^]1
                  pea    ]1
                  else
                  if     :,]1
                  lda    ]1+2
                  pha
                  lda    ]1
                  pha
                  else
                  lda    ]1+2
                  pha
                  lda    ]1
                  pha
                  fin
                  fin
                  eom
PLL               mac
                  if     :,]1
                  pla
                  sta    ]1
                  pla
                  sta    ]1+2
                  else
                  pla
                  sta    ]1
                  pla
                  sta    ]1+2
                  fin
                  eom
TOOL              mac
                  ldx    #]1
                  jsl    $E10000
                  eom
TLL               mac
                  ldx    #]1
                  jsl    $E10000
                  eom
JMI               mac
                  bpl    *+5
                  jmp    ]1
                  eom
JPL               mac
                  bmi    *+5
                  jmp    ]1
                  eom
JNE               mac
                  beq    *+5
                  jmp    ]1
                  eom
JEQ               mac
                  bne    *+5
                  jmp    ]1
                  eom
JGE               mac
                  blt    *+5
                  jmp    ]1
                  eom
JLT               mac
                  bge    *+5
                  jmp    ]1
                  eom
JCS               mac
                  bcc    *+5
                  jmp    ]1
                  eom
JCC               mac
                  bcs    *+5
                  jmp    ]1
                  eom
_QAGotoXY         mac
                  utool  $57
                  eom
_QADRAWSTRING     mac
                  utool  $0A
                  <<<
_QADRAWSTR        mac
                  utool  $0A
                  <<<
_QAPRBYTE         mac
                  utool  $0B
                  <<<
_QAPRBYTEL        mac
                  utool  $0C
                  <<<
_QADRAWDEC        mac
                  utool  $0D
                  <<<
_QAKEYAVAIL       mac
                  utool  $0E
                  <<<
_QAGETCHAR        mac
                  utool  $0F
                  <<<
_QAGETCMDLINE     mac
                  utool  $1B
                  <<<
_QARUN            mac
                  utool  $23
                  <<<
_QADRAWERRCHAR    mac
                  utool  $51
                  <<<
_QADRAWERRSTRING  mac
                  utool  $52
                  <<<
_QADRAWHEX        mac
                  utool  $5A
                  <<<
^QADRAWCSTRING    mac
                  psl    ]1
                  utool  $5B
                  <<<
_QADRAWCHARX      mac
                  utool  $5D
                  <<<
~QAGetWord        MAC
                  pha
                  pha
                  psl    ]1
                  psw    ]2
                  utool  $61
                  <<<
_GSOS             MAC
                  do     inline
                  jsl    prodos
                  dw     ]1
                  adrl   ]2
                  else
                  psl    #]2
                  pea    ]1
                  jsl    prodosIL
                  fin
                  <<<
UTOOL             mac
                  ldx    #]1*256+toolnum
                  do     userorsys
                  jsl    $E10008
                  else
                  jsl    $E10000
                  fin
                  <<<
PHL               MAC
                  IF     #=]1
                  PEA    ^]1
                  ELSE
                  PHW    ]1+2
                  FIN
                  PHW    ]1
                  <<<
PHW               MAC
                  IF     #=]1
                  PEA    ]1
                  ELSE
                  IF     MX/2
                  LDA    ]1+1
                  PHA
                  FIN
                  LDA    ]1
                  PHA
                  FIN
                  <<<
PHS               MAC
                  DO     ]0
                  LUP    ]1
                  PHA
                  --^
                  ELSE
                  PHA
                  FIN
                  <<<

