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
_DISPOSEHANDLE    MAC
                  Tool   $1002
                  <<<
^PURGEALL         MAC
                  PHW    ]1
                  Tool   $1302
                  <<<
_COMPACTMEM       MAC
                  Tool   $1F02
                  <<<
_HLOCK            MAC
                  Tool   $2002
                  <<<
~QAGetWord        MAC
                  pha
                  pha
                  psl    ]1
                  phw    ]2
                  phw    ]3
_QAGetWord        mac                     ;_QAGetWord(@Text,Offset,MaxLen):BegOffset,EndOffset
                  utool  $61
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
_QADRAWCHAR       mac
                  utool  $09
                  eom
_QADRAWSTRING     mac
                  utool  $0A
                  eom
_QADRAWSTR        mac
                  utool  $0A
                  eom
_QAGETPARMHDL     mac
                  utool  $12
                  eom
_QAGETCMDHDL      mac
                  utool  $14
                  eom
_QALOADFILE       mac
                  utool  $18
                  eom
_QAGETCMDLINE     mac
                  utool  $1B
                  eom
_QASETQUITFLAG    mac
                  utool  $1E
                  eom
_QACOMPILE        mac
                  utool  $26
                  eom
_QALINK           mac
                  utool  $27
                  eom
_QAGETVECTOR      mac
                  utool  $2E
                  eom
_QASETVECTOR      mac
                  utool  $2F
                  eom
_QATABTOCOL       mac
                  utool  $33
                  eom
_QASETCANCELFLAG  mac
                  utool  $40
                  eom
_QAGETSHELLID     mac
                  utool  $55
                  eom
_QASETLAUNCH      mac
                  utool  $60
                  eom
_QADRAWCR         mac
                  utool  $63
                  <<<
_QADRAWSPACE      mac
                  utool  $64
                  <<<
UTOOL             mac
                  ldx    #]1*256+toolnum
                  do     userorsys
                  jsl    $E10008
                  else
                  jsl    $E10000
                  fin
                  eom
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

