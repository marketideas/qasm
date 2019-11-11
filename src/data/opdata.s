p6502          =      %0000_0000_0000_0000
p65C02         =      %1000_0000_0000_0000
p65816         =      %1100_0000_0000_0000
m6502          =      %0000_0000_0000_0000
m65C02         =      %1000_0000_0000_0000
m65816         =      %1100_0000_0000_0000
conditional    =      %0010_0000_0000_0000
branch         =      %0001_0000_0000_0000
onebyte        =      %0000_1000_0000_0000
general        =      %0000_0100_0000_0000
long           =      %0000_0010_0000_0000
macro          =      %0000_0001_0000_0000

psuedo         =      %0000_0000_1000_0000
mY             =      %0000_0000_0100_0000
mX             =      %0000_0000_0010_0000
mA             =      %0000_0000_0001_0000

               mx     %00
op31code       opcl   $00;$00;$00
op30code       opcl   '>>> ';psuedo.macro.p6502;pmcop
op29code       opcl   '=   ';psuedo.p6502;equop
op28code       opcl   '<<< ';psuedo.macro.p6502;eomop
op27code       opcl   $00;$00;$00
opzcode        opcl   $00;$00;$00
opycode        opcl   $00;$00;$00
opxcode        opco   'XC- ';psuedo.p6502;xcop1
               opco   'XCE ';m65816;xceop
               opco   'XC  ';psuedo.p6502;xcop
               opcl   'XBA ';onebyte.m65816;$EB
opwcode        opco   'WDM ';m65816;wdmop
               opcl   'WAI ';onebyte.m65c02;$CB
opvcode        opcl   'VAR ';psuedo.p6502;varop
opucode        opco   'USR ';psuedo.p6502;opcop                ;*** change this
               opcl   'USE ';psuedo.p6502;useop
optcode        opco   'TYX ';onebyte.m65816;$BB
               opco   'TYP ';psuedo.p6502;typop
               opco   'TYA ';onebyte.m6502;$98
               opco   'TXY ';onebyte.m65816;$9B
               opco   'TXS ';onebyte.m6502;$9A
               opco   'TXA ';onebyte.m6502;$8A
               opco   'TTL ';psuedo.p6502;ttlop
               opco   'TSX ';onebyte.m6502;$BA
               opco   'TSC ';onebyte.m65816;$3B
               opco   'TSB ';m65c02.general;tsbtbl
               opco   'TSA ';onebyte.m65816;$3B
               opco   'TRB ';m65c02.general;trbtbl
               opco   'TR  ';psuedo.p6502;trop
               opco   'TDC ';onebyte.m65816;$7B
               opco   'TDA ';onebyte.m65816;$7B
               opco   'TCS ';onebyte.m65816;$1B
               opco   'TCD ';onebyte.m65816;$5b
               opco   'TBX ';psuedo.p65816;tbxop
               opco   'TAY ';onebyte.m6502;$a8
               opco   'TAX ';onebyte.m6502;$aa
               opco   'TAS ';onebyte.m65816;$1b
               opcl   'TAD ';onebyte.m65816;$5b
opscode        opco   'SYM ';psuedo.p6502;symop
               opco   'SWA ';onebyte.m65816;$eb
               opco   'STZ ';general.m6502.mA;stztbl
               opco   'STY ';general.m6502.mY;stytbl
               opco   'STX ';general.m6502.mX;stxtbl
               opco   'STRL';psuedo.p6502;strlop
               opco   'STR ';psuedo.p6502;strop
               opco   'STP ';onebyte.m65c02;$db
               opco   'STAL';general.long.m65816.mA;statbl
               opco   'STA ';general.m6502.mA;statbl
               opco   'SKP ';psuedo.p6502;skpop
               opco   'SEP ';m65816;sepop
               opco   'SEI ';onebyte.m6502;$78
               opco   'SED ';onebyte.m6502;$f8
               opco   'SEC ';onebyte.m6502;$38
               opco   'SBCL';general.long.m65816.mA;sbctbl
               opco   'SBC ';general.m6502.mA;sbctbl
               opcl   'SAV ';psuedo.p6502;savop
oprcode        opco   'RTS ';onebyte.m6502;$60
               opco   'RTL ';onebyte.m65816;$6b
               opco   'RTI ';onebyte.m6502;$40
               opco   'ROR ';general.m6502.mA;rortbl
               opco   'ROL ';general.m6502.mA;roltbl
               opco   'RND ';psuedo.p6502;rndop
               opco   'REV ';psuedo.p6502;revop
               opco   'REP ';m65816;repop
               opcl   'REL ';psuedo.p6502;relop
opqcode        opcl   $00;$00;$00
oppcode        opco   'PUT ';psuedo.p6502;putop
               opco   'PMC ';psuedo.macro.p6502;pmcop
               opco   'PLY ';onebyte.m65C02;$7a
               opco   'PLX ';onebyte.m65C02;$fa
               opco   'PLP ';onebyte.m6502;$28
               opco   'PLD ';onebyte.m65816;$2b
               opco   'PLB ';onebyte.m65816;$ab
               opco   'PLA ';onebyte.m6502;$68
               opco   'PHY ';onebyte.m65C02;$5a
               opco   'PHX ';onebyte.m65C02;$da
               opco   'PHP ';onebyte.m6502;$08
               opco   'PHK ';onebyte.m65816;$4b
               opco   'PHD ';onebyte.m65816;$0b
               opco   'PHB ';onebyte.m65816;$8b
               opco   'PHA ';onebyte.m6502;$48
               opco   'PER ';m65816;perop
               opco   'PEK ';psuedo.p6502;pekop
               opco   'PEI ';m65816.general;peitbl
               opco   'PEA ';m65816;peaop
               opco   'PAU ';psuedo.p6502;pauop
               opcl   'PAG ';psuedo.p6502;pagop
opocode        opco   'ORG ';psuedo.p6502;orgop
               opco   'ORAL';general.long.m65816.mA;oratbl
               opco   'ORA ';general.m6502.mA;oratbl
               opcl   'OBJ ';psuedo.p6502;objop
opncode        opcl   'NOP ';onebyte.m6502;$ea
opmcode        opco   'MX  ';psuedo.p65816;mxop
               opco   'MVP ';m65816;mvpop
               opco   'MVN ';m65816;mvnop
               opco   'MTX ';psuedo.p6502;mtxop
               opco   '--^ ';psuedo.p6502;lupend
               opcl   'MAC ';psuedo.macro.p6502;macop
oplcode        opco   'LUP ';psuedo.p6502;lupop
               opco   'LSTL';psuedo.p6502;lstdoop
               opco   'LST ';psuedo.p6502;lstop
               opco   'LSR ';general.m6502.mA;lsrtbl
               opco   'LIB ';psuedo.p6502;libop
               opco   'LDY ';general.m6502.mY;ldytbl
               opco   'LDX ';general.m6502.mX;ldxtbl
               opco   'LDAL';general.long.m65816.mA;ldatbl
               lst
               opcl   'LDA ';general.m6502.mA;ldatbl
               lst    off
opkcode        opcl   'KBD ';psuedo.p6502;kbdop
opjcode        opco   'JSR ';m6502;jsrop
               opco   'JSL ';m65816;jslop
               opco   'JMP ';m6502;jmpop
               opcl   'JML ';m65816;jmlop
opicode        opco   'INY ';onebyte.m6502;$c8
               opco   'INX ';onebyte.m6502;$e8
               opco   'INV ';psuedo.p6502;invop
               opco   'INC ';general.m6502.mA;inctbl
               opco   'INA ';onebyte.m65C02.mA;$1A
               opcl   'IF  ';psuedo.conditional.p6502;ifop
ophcode        opcl   'HEX ';psuedo.p6502;hexop
opgcode        opcl   $00;$00;$00
opfcode        opco   'FLS ';psuedo.p6502;flsop

               do     floatingpoint
               opco   'FLO ';psuedo.m6502;floop
               fin

               opcl   'FIN ';psuedo.conditional.p6502;finop
opecode        opco   'EXT ';psuedo.p6502;extop
               opco   'EXP ';psuedo.p6502;expop
               opco   'EXD ';psuedo.p6502;exdop
               opco   'EVL ';psuedo.p6502;evlop
               opco   'ERR ';psuedo.p6502;errop
               opco   'EQU ';psuedo.p6502;equop
               opco   'EORL';general.long.m65816.mA;eortbl
               opco   'EOR ';general.m6502.mA;eortbl
               opco   'EOM ';psuedo.macro.p6502;eomop
               opco   'ENT ';psuedo.p6502;entop
               opco   'END ';psuedo.p6502;endop
               opco   'ENC ';psuedo.p6502;encop
               opcl   'ELS ';psuedo.conditional.p6502;elseop
opdcode        opco   'DW  ';psuedo.p6502;dwop
               opco   'DUP ';psuedo.p6502;dupop
               opco   'DUM ';psuedo.p6502;dumop
               opco   'DSK ';psuedo.p6502;dskop
               opco   'DS  ';psuedo.p6502;dsop
               opco   'DO  ';psuedo.conditional.p6502;doop
               opco   'DL  ';psuedo.p6502;adrlop
               opco   'DFS ';psuedo.p6502;dsop
               opco   'DFB ';psuedo.p6502;dfbop
               opco   'DEY ';onebyte.m6502;$88
               opco   'DEX ';onebyte.m6502;$ca
               opco   'DEN ';psuedo.p6502;dendop
               opco   'DEC ';general.m6502.mA;dectbl
               opco   'DEA ';onebyte.m65C02.mA;$3A
               opco   'DDB ';psuedo.p6502;ddbop
               opco   'DCI ';psuedo.p6502;dciop
               opco   'DBY ';psuedo.p6502;ddbop
               opco   'DB  ';psuedo.p6502;dfbop
               opco   'DAT ';psuedo.p6502;datop
               opcl   'DA  ';psuedo.p6502;dwop
opccode        opco   'CYC ';psuedo.p6502;cycop
               opco   'CRC ';psuedo.p6502;crcop
               opco   'CPY ';general.m6502.mY;cpytbl
               opco   'CPX ';general.m6502.mX;cpxtbl
               opco   'COP ';m65816;copop
               opco   'CMPL';general.long.m65816.mA;cmptbl
               opco   'CMP ';general.m6502.mA;cmptbl
               opco   'CLV ';onebyte.m6502;$b8
               opco   'CLI ';onebyte.m6502;$58
               opco   'CLD ';onebyte.m6502;$d8
               opco   'CLC ';onebyte.m6502;$18
               opco   'CHK ';psuedo.p6502;chkop
               opcl   'CAS ';psuedo.p6502;casop
opbcode        opco   'BYT ';psuedo.p6502;dfbop
               opco   'BVS ';branch.m6502;$70
               opco   'BVC ';branch.m6502;$50
               opco   'BTR ';branch.m6502;$d0
               opco   'BRL ';branch.m65816;$82+$800
               opco   'BRK ';m6502;brkop
               opco   'BRA ';branch.m65C02;$80+$400
               opco   'BPL ';branch.m6502;$10
               opco   'BNE ';branch.m6502;$d0
               opco   'BMI ';branch.m6502;$30
               opco   'BLT ';branch.m6502;$90
               opco   'BIT ';general.m6502.mA;bittbl
               opco   'BGE ';branch.m6502;$b0
               opco   'BFL ';branch.m6502;$f0
               opco   'BEQ ';branch.m6502;$f0
               opco   'BEL ';psuedo.p6502;belop
               opco   'BCS ';branch.m6502;$b0
               opcl   'BCC ';branch.m6502;$90
opacode        opco   'AST ';psuedo.p6502;astop
               opco   'ASL ';general.m6502.mA;asltbl
               opco   'ASC ';psuedo.p6502;ascop
               opco   'ANDL';general.long.m65816.mA;andtbl
               opco   'AND ';general.m6502.mA;andtbl
               opco   'ADRL';psuedo.p6502;adrlop
               opco   'ADR ';psuedo.p6502;adrop
               opco   'ADCL';general.long.m65816.mA;adctbl
               opcl   'ADC ';general.m6502.mA;adctbl
op0code        opcl   $00;$00;$00


opcodelookup
               dw     op0code
               dw     opacode
               dw     opbcode
               dw     opccode
               dw     opdcode
               dw     opecode
               dw     opfcode
               dw     opgcode
               dw     ophcode
               dw     opicode
               dw     opjcode
               dw     opkcode
               dw     oplcode
               dw     opmcode
               dw     opncode
               dw     opocode
               dw     oppcode
               dw     opqcode
               dw     oprcode
               dw     opscode
               dw     optcode
               dw     opucode
               dw     opvcode
               dw     opwcode
               dw     opxcode
               dw     opycode
               dw     opzcode
               dw     op27code
               dw     op28code
               dw     op29code
               dw     op30code
               dw     op31code


cycletbl                                                       ;byte 1 = base cycles
               dfb    8,0,0,0                                  ;     2 =
               dfb    6,3,1,0
               dfb    8,0,0,0
               dfb    4,2,1,0
               dfb    5,2,2,0
               dfb    3,2,1,0
               dfb    5,2,2,0
               dfb    6,2,1,0
               dfb    3,0,0,0
               dfb    2,2,1,0

               dfb    2,2,0,0
               dfb    4,0,0,0
               dfb    6,2,2,0
               dfb    4,2,1,0
               dfb    6,2,2,0
               dfb    5,2,1,0
               dfb    2,0,0,0
               dfb    5,3,1,1
               dfb    5,2,1,0
               dfb    7,3,1,0

               dfb    5,2,2,0
               dfb    4,3,1,0
               dfb    6,3,2,0
               dfb    6,3,1,0
               dfb    2,0,0,0
               dfb    4,3,1,1
               dfb    2,2,0,0
               dfb    2,2,0,0
               dfb    6,2,2,0
               dfb    4,3,1,1

               dfb    7,3,2,0
               dfb    5,3,1,0
               dfb    6,0,0,0
               dfb    6,3,1,0
               dfb    8,0,0,0
               dfb    4,2,1,0
               dfb    3,2,1,0
               dfb    3,2,1,0
               dfb    5,2,2,0
               dfb    6,2,1,0

               dfb    4,0,0,0
               dfb    2,2,1,0
               dfb    2,2,0,0
               dfb    5,0,0,0
               dfb    4,2,1,0
               dfb    4,2,1,0
               dfb    6,2,2,0
               dfb    5,2,1,0
               dfb    2,0,0,0
               dfb    5,3,1,1

               dfb    5,2,1,0
               dfb    7,3,1,0
               dfb    4,3,1,0
               dfb    4,3,1,0
               dfb    6,3,2,0
               dfb    6,3,1,0
               dfb    2,0,0,0
               dfb    4,3,1,1
               dfb    2,2,0,0
               dfb    2,2,0,0

               dfb    4,3,1,1
               dfb    4,3,1,1
               dfb    7,3,2,0
               dfb    5,3,1,0
               dfb    7,0,0,0
               dfb    6,3,1,0
               dfb    2,0,0,0
               dfb    4,2,1,0
               dfb    7,0,0,0
               dfb    3,2,1,0

               dfb    5,2,2,0
               dfb    6,2,1,0
               dfb    3,2,1,0
               dfb    2,2,1,0
               dfb    2,2,0,0
               dfb    3,0,0,0
               dfb    3,0,0,0
               dfb    4,2,1,0
               dfb    6,2,2,0
               dfb    5,2,1,0

               dfb    2,0,0,0
               dfb    5,3,1,1
               dfb    5,2,1,0
               dfb    7,3,1,0
               dfb    7,0,0,0
               dfb    4,3,1,0
               dfb    6,3,2,0
               dfb    6,3,1,0
               dfb    2,0,0,0
               dfb    4,3,1,1

               dfb    3,1,1,0
               dfb    2,2,0,0
               dfb    4,0,0,0
               dfb    4,3,1,1
               dfb    7,3,2,0
               dfb    5,3,1,0
               dfb    6,0,0,0
               dfb    6,3,1,0
               dfb    6,0,0,0
               dfb    4,2,1,0

               dfb    3,2,1,0
               dfb    3,2,1,0
               dfb    5,2,2,0
               dfb    6,2,1,0
               dfb    4,2,1,0
               dfb    2,2,1,0
               dfb    2,2,0,0
               dfb    6,0,0,0
               dfb    5,0,0,0
               dfb    4,2,1,0

               dfb    6,2,2,0
               dfb    5,2,1,0
               dfb    2,0,0,0
               dfb    5,3,1,1
               dfb    5,2,1,0
               dfb    7,3,1,0
               dfb    4,3,1,0
               dfb    4,3,1,0
               dfb    6,3,2,0
               dfb    6,3,1,0

               dfb    2,0,0,0
               dfb    4,3,1,1
               dfb    4,1,1,0
               dfb    2,2,0,0
               dfb    6,1,0,0
               dfb    4,3,1,1
               dfb    7,3,2,0
               dfb    5,3,1,0
               dfb    3,0,0,0                                  ;bra
               dfb    6,3,1,0

               dfb    4,0,0,0                                  ;brl
               dfb    4,2,1,0
               dfb    3,1,1,0
               dfb    3,2,1,0
               dfb    3,1,1,0
               dfb    6,2,1,0
               dfb    2,1,0,0
               dfb    2,2,1,0
               dfb    2,0,0,0
               dfb    3,0,0,0

               dfb    4,1,1,0
               dfb    4,2,1,0
               dfb    4,1,1,0
               dfb    5,2,1,0
               dfb    2,0,0,0
               dfb    6,3,1,0
               dfb    5,2,1,0
               dfb    7,3,1,0
               dfb    4,3,1,0
               dfb    4,3,1,0
               dfb    4,3,1,0
               dfb    6,3,1,0
               dfb    2,0,0,0
               dfb    5,3,1,0
               dfb    2,0,0,0
               dfb    2,0,0,0
               dfb    4,2,1,0
               dfb    5,3,1,0
               dfb    5,3,1,0
               dfb    5,3,1,0
               dfb    2,1,1,0
               dfb    6,3,1,0
               dfb    2,1,1,0
               dfb    4,2,1,0
               dfb    3,1,1,0
               dfb    3,2,1,0
               dfb    3,1,1,0
               dfb    6,2,1,0
               dfb    2,0,0,0
               dfb    2,2,1,0
               dfb    2,0,0,0
               dfb    4,0,0,0
               dfb    4,1,1,0
               dfb    4,2,1,0
               dfb    4,1,1,0
               dfb    5,2,1,0
               dfb    2,0,0,0
               dfb    5,3,1,1
               dfb    5,2,1,0
               dfb    7,3,1,0
               dfb    4,3,1,0
               dfb    4,3,1,0
               dfb    4,3,1,0
               dfb    6,3,1,0
               dfb    2,0,0,0
               dfb    4,3,1,1
               dfb    2,0,0,0
               dfb    2,0,0,0
               dfb    4,3,1,1
               dfb    4,3,1,1
               dfb    4,3,1,1
               dfb    5,3,1,0
               dfb    2,1,1,0
               dfb    6,3,1,0
               dfb    3,0,0,0
               dfb    4,2,1,0
               dfb    3,1,1,0
               dfb    3,2,1,0
               dfb    5,2,2,0
               dfb    6,2,1,0
               dfb    2,0,0,0
               dfb    2,2,1,0
               dfb    2,0,0,0
               dfb    3,0,0,0
               dfb    4,1,1,0
               dfb    4,2,1,0
               dfb    6,2,2,0
               dfb    5,2,1,0
               dfb    2,0,0,0
               dfb    5,3,1,1
               dfb    5,2,1,0
               dfb    7,3,1,0
               dfb    6,0,0,0
               dfb    4,3,1,0
               dfb    6,3,2,0
               dfb    6,3,1,0
               dfb    2,0,0,0
               dfb    4,3,1,1
               dfb    3,1,1,0
               dfb    3,0,0,0
               dfb    6,0,0,0
               dfb    4,3,1,1
               dfb    7,3,2,0
               dfb    5,3,1,0
               dfb    2,1,1,0
               dfb    6,3,1,0
               dfb    3,0,0,0
               dfb    4,2,1,0
               dfb    3,1,1,0
               dfb    3,2,1,0
               dfb    5,2,2,0
               dfb    6,2,1,0
               dfb    2,0,0,0
               dfb    2,2,1,0
               dfb    2,0,0,0
               dfb    3,0,0,0
               dfb    4,1,1,0
               dfb    4,2,1,0
               dfb    6,2,2,0
               dfb    5,2,1,0
               dfb    2,0,0,0
               dfb    5,3,1,1
               dfb    5,2,1,0
               dfb    7,3,1,0
               dfb    5,0,0,0
               dfb    4,3,1,0
               dfb    6,3,2,0
               dfb    6,3,1,0
               dfb    2,0,0,0
               dfb    4,3,1,1
               dfb    4,1,1,0
               dfb    2,0,0,0
               dfb    8,0,0,0
               dfb    4,3,1,1
               dfb    7,3,2,0
               dfb    5,3,1,0






mactbl
               opcx   'TLL ';tlltxt;0
               opcx   'TLC ';tlctxt;0
               opcx   'PSW ';pswtxt;0
               opcx   'PSL ';psltxt;0
               opcx   'PLW ';plwtxt;0
               opcx   'PLL ';plltxt;0
               opcx   'JVSL';jvsltxt;0
               opcx   'JVS ';jvstxt;0
               opcx   'JVCL';jvcltxt;0
               opcx   'JVC ';jvctxt;0
               opcx   'JPLL';jplltxt;0
               opcx   'JPL ';jpltxt;0
               opcx   'JNEL';jneltxt;0
               opcx   'JNE ';jnetxt;0
               opcx   'JMIL';jmiltxt;0
               opcx   'JMI ';jmitxt;0
               opcx   'JLTL';jltltxt;0
               opcx   'JLT ';jlttxt;0
               opcx   'JLEL';jleltxt;0
               opcx   'JLE ';jletxt;0
               opcx   'JGEL';jgeltxt;0
               opcx   'JGE ';jgetxt;0
               opcx   'JEQL';jeqltxt;0
               opcx   'JEQ ';jeqtxt;0
               opcx   'JCSL';jcsltxt;0
               opcx   'JCS ';jcstxt;0
               opcx   'JCCL';jccltxt;0
               opcx   'JCC ';jcctxt;0
               opcx   'DOS ';dostxt;0
               opcx   'BSRL';bsrltxt;0
               opcx   'BSR ';bsrtxt;0
               opcxl  'BLE ';bletxt;0

dostxt         asc    ' jsl $E100A8',0d
               asc    ' dw ]',31,0d
               asc    ' adrl ]',32,0d
               asc    ' eom',0d
dostxt1        asc    ' jsl $E100A8',0d
               asc    ' dw $'
dosnum         asc    '0000',0d
               asc    ' adrl ]',31,0d
               asc    ' eom',0d
tlltxt         asc    ' ldx #]',31,0d
               asc    ' jsl $E10000',0d
               asc    ' eom',0d
tlltxt1        asc    ' ldx #]',31,0d
               asc    ' jsl $E10000',0d
               asc    ' eom',0d
tlctxt         asc    ' ldx #]',31,0d
               asc    ' jsl $E10000',0d
               asc    ' bcc *+4',0d
               asc    ' brk $00',0d
               asc    ' eom',0d
psltxt         asc    ' if #,]',31,0d
               asc    ' pea ^]',31,0d
               asc    ' pea ]',31,0d
               asc    ' else',0d
               asc    ' lda ]',31,'+2',0d
               asc    ' pha',0d
               asc    ' lda ]',31,0d
               asc    ' pha',0d
               asc    ' fin',0d
               asc    ' eom',0d
pswtxt         asc    ' if #,]',31,0d
               asc    ' pea ]',31,0d
               asc    ' else',0d
               asc    ' lda ]',31,0d
               asc    ' pha',0d
               asc    ' fin',0d
               asc    ' eom',0d
plltxt         asc    ' pla',0d
               asc    ' sta ]',31,0d
               asc    ' pla',0d
               asc    ' sta ]',31,'+2',0d
               asc    ' eom',0d
plwtxt         asc    ' pla',0d
               asc    ' sta ]',31,0d
               asc    ' eom',0d
bsrtxt         asc    ' per *+4',0d
               asc    ' bra ]',31,0d
               asc    ' eom',0d
bsrltxt        asc    ' per *+5',0d
               asc    ' brl ]',31,0d
               asc    ' eom',0d
jmitxt         asc    ' bpl *+5',0d
               asc    ' jmp ]',31,0d
               asc    ' eom',0d
jpltxt         asc    ' bmi *+5',0d
               asc    ' jmp ]',31,0d
               asc    ' eom',0d
jnetxt         asc    ' beq *+5',0d
               asc    ' jmp ]',31,0d
               asc    ' eom',0d
jeqtxt         asc    ' bne *+5',0d
               asc    ' jmp ]',31,0d
               asc    ' eom',0d
jlttxt         asc    ' bge *+5',0d
               asc    ' jmp ]',31,0d
               asc    ' eom',0d
jgetxt         asc    ' blt *+5',0d
               asc    ' jmp ]',31,0d
               asc    ' eom',0d
bletxt         asc    ' blt ]',31,0d
               asc    ' beq ]',31,0d
               asc    ' eom',0d
jletxt         asc    ' beq *+4',0d
               asc    ' bge *+5',0d
               asc    ' jmp ]',31,0d
               asc    ' eom',0d
jcstxt         asc    ' bcc *+5',0d
               asc    ' jmp ]',31,0d
               asc    ' eom',0d
jcctxt         asc    ' bcs *+5',0d
               asc    ' jmp ]',31,0d
               asc    ' eom',0d
jvstxt         asc    ' bvc *+5',0d
               asc    ' jmp ]',31,0d
               asc    ' eom',0d
jvctxt         asc    ' bvs *+5',0d
               asc    ' jmp ]',31,0d
               asc    ' eom',0d
jmiltxt        asc    ' bpl *+6',0d
               asc    ' jml ]',31,0d
               asc    ' eom',0d
jplltxt        asc    ' bmi *+6',0d
               asc    ' jmp ]',31,0d
               asc    ' eom',0d
jneltxt        asc    ' beq *+6',0d
               asc    ' jml ]',31,0d
               asc    ' eom',0d
jeqltxt        asc    ' bne *+6',0d
               asc    ' jml ]',31,0d
               asc    ' eom',0d
jgeltxt        asc    ' blt *+6',0d
               asc    ' jml ]',31,0d
               asc    ' eom',0d
jltltxt        asc    ' bge *+6',0d
               asc    ' jml ]',31,0d
               asc    ' eom',0d
jleltxt        asc    ' beq *+4',0d
               asc    ' bge *+6',0d
               asc    ' jml ]',31,0d
               asc    ' eom',0d
jcsltxt        asc    ' bcc *+6',0d
               asc    ' jml ]',31,0d
               asc    ' eom',0d
jccltxt        asc    ' bcs *+6',0d
               asc    ' jml ]',31,0d
               asc    ' eom',0d
jvsltxt        asc    ' bvc *+6',0d
               asc    ' jml ]',31,0d
               asc    ' eom',0d
jvcltxt        asc    ' bvs *+6',0d
               asc    ' jml ]',31,0d
               asc    ' eom',0d


adctbl
               hex    696969
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    656565
               hex    757575
               hex    000000
               hex    007272
               hex    616161
               hex    717171
               hex    000067
               hex    000077
               hex    6d6d6d
               hex    7d7d7d
               hex    797979
               hex    00006f
               hex    00007f
               hex    000063
               hex    000073
               hex    000000
               hex    000000
               hex    000000

andtbl
               hex    292929
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    252525
               hex    353535
               hex    000000
               hex    003232
               hex    212121
               hex    313131
               hex    000027
               hex    000037
               hex    2d2d2d
               hex    3d3d3d
               hex    393939
               hex    00002f
               hex    00003f
               hex    000023
               hex    000033
               hex    000000
               hex    000000
               hex    000000

asltbl
               hex    000000
               hex    0a0a0a
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    060606
               hex    161616
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    0e0e0e
               hex    1e1e1e
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000

bittbl
               hex    008989
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    242424
               hex    003434
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    2c2c2c
               hex    003c3c
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000


cmptbl
               hex    c9c9c9
               hex    cdcdcd
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    c5c5c5
               hex    d5d5d5
               hex    000000
               hex    00d2d2
               hex    c1c1c1
               hex    d1d1d1
               hex    0000c7
               hex    0000d7
               hex    cdcdcd
               hex    dddddd
               hex    d9d9d9
               hex    0000cf
               hex    0000df
               hex    0000c3
               hex    0000d3
               hex    000000
               hex    000000
               hex    000000


cpxtbl
               hex    e0e0e0
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    e4e4e4
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    ececec
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000

cpytbl
               hex    c0c0c0
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    c4c4c4
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    cccccc
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000

dectbl
               hex    000000
               hex    003a3a
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    c6c6c6
               hex    d6d6d6
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    cecece
               hex    dedede
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000


eortbl
               hex    494949
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    454545
               hex    555555
               hex    000000
               hex    005252
               hex    414141
               hex    515151
               hex    000047
               hex    000057
               hex    4d4d4d
               hex    5d5d5d
               hex    595959
               hex    00004f
               hex    00005f
               hex    000043
               hex    000053
               hex    000000
               hex    000000
               hex    000000

inctbl
               hex    000000
               hex    001a1a
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    e6e6e6
               hex    f6f6f6
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    eeeeee
               hex    fefefe
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000

ldatbl
               hex    a9a9a9
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    a5a5a5
               hex    b5b5b5
               hex    000000
               hex    00b2b2
               hex    a1a1a1
               hex    b1b1b1
               hex    0000a7
               hex    0000b7
               hex    adadad
               hex    bdbdbd
               hex    b9b9b9
               hex    0000af
               hex    0000bf
               hex    0000a3
               hex    0000b3
               hex    000000
               hex    000000
               hex    000000

ldxtbl
               hex    a2a2a2
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    a6a6a6
               hex    000000
               hex    b6b6b6
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    aeaeae
               hex    000000
               hex    bebebe
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000

ldytbl
               hex    a0a0a0
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    a4a4a4
               hex    b4b4b4
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    acacac
               hex    bcbcbc
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000

lsrtbl
               hex    000000
               hex    4a4a4a
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    464646
               hex    565656
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    4e4e4e
               hex    5e5e5e
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000


oratbl
               hex    090909
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    050505
               hex    151515
               hex    000000
               hex    001212
               hex    010101
               hex    111111
               hex    000007
               hex    000017
               hex    0d0d0d
               hex    1d1d1d
               hex    191919
               hex    00000f
               hex    00001f
               hex    000003
               hex    000013
               hex    000000
               hex    000000
               hex    000000


peitbl
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    0000D4
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000



roltbl
               hex    000000
               hex    2a2a2a
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    262626
               hex    363636
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    2e2e2e
               hex    3e3e3e
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000

rortbl
               hex    000000
               hex    6a6a6a
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    666666
               hex    767676
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    6e6e6e
               hex    7e7e7e
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000


sbctbl
               hex    e9e9e9
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    e5e5e5
               hex    f5f5f5
               hex    000000
               hex    00f2f2
               hex    e1e1e1
               hex    f1f1f1
               hex    0000e7
               hex    0000f7
               hex    ededed
               hex    fdfdfd
               hex    f9f9f9
               hex    0000ef
               hex    0000ff
               hex    0000e3
               hex    0000f3
               hex    000000
               hex    000000
               hex    000000



statbl
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    858585
               hex    959595
               hex    000000
               hex    009292
               hex    818181
               hex    919191
               hex    000087
               hex    000097
               hex    8d8d8d
               hex    9d9d9d
               hex    999999
               hex    00008f
               hex    00009f
               hex    000083
               hex    000093
               hex    000000
               hex    000000
               hex    000000


stxtbl
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    868686
               hex    000000
               hex    969696
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    8e8e8e
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000

stytbl
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    848484
               hex    949494
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    8c8c8c
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000

stztbl
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    006464
               hex    007474
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    009c9c
               hex    009e9e
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000


trbtbl
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    001414
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    001c1c
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000

tsbtbl
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000404
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000c0c
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000
               hex    000000

ftmonths
               asc    'Jan-'
               asc    'Feb-'
               asc    'Mar-'
               asc    'Apr-'
               asc    'May-'
               asc    'Jun-'
               asc    'Jul-'
               asc    'Aug-'
               asc    'Sep-'
               asc    'Oct-'
               asc    'Nov-'
               asc    'Dec-'


