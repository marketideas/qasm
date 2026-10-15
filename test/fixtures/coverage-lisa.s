* Assembler: LISA
*
* Same program as coverage-merlin.s. The object matches byte for byte.
* ]BACK and :PART are the locals. OUTSIDE is .EQ 0. LISA has no EXT.
* 1+2*3 is 9. {1+2*3} is 7. MX sets the 16-bit immediate tail.

.OR    $8000

ZP       .EPZ   $10
WORD     .EQ    $1234
MASK     .EQ    $00FF
LONGV    .EQ    $012345
ONE      .EQ    1
SRCB     .EQ    $01
DSTB     .EQ    $02
BELL     .EQ    $FBDD
OUTSIDE  .EQ    0

GLOB
         NOP
]BACK    NOP
         BEQ    ]BACK
:PART    NOP
         BRA    :PART
]STEP    .EQ    1
]STEP    .EQ    ]STEP+1

         .DB    1+2*3
         .DB    {1+2*3}
         .DB    20/3
         .DB    {20/3*3}
         .DB    1=1
         .DB    1#2
         .DB    {1<2}
         .DB    {2>1}
         .DB    WORD&MASK
         .DB    1.2
         .DB    WORD!MASK
         .DB    -2
         .DB    $2A
         .DB    %00101010
         .DB    'A'
         .DB    "A"
         .DB    <WORD
         .DB    >WORD
         .DB    ^LONGV
         .DB    <GLOB
         .DB    >GLOB
         .DB    ^GLOB
         .DB    ]STEP
         .DA    WORD
         .DA    GLOB
         .DA    GLOB-GLOB
         .DA    *-GLOB
         .DA    ]BACK
         .DA    :PART
         .DA    BELL
         .DA    OUTSIDE+WORD
         .DA    GLOB+]BACK-:PART
         .DB    /WORD
         .DB    #WORD
         .DB    <LONGV
         .DB    >LONGV
         .DB    ^LONGV
         .DB    <LONGV
         .DB    >LONGV
         .DB    ^LONGV
         .DB    0
         .DB    <GLOB
         .DB    >GLOB
         .DB    ^GLOB
         .DB    0

         LDA    ZP+1
         LDA    ZP+1,X
         LDA    (ZP+1),Y
         LDA    [ZP+1],Y
         LDA    (ZP+1,X)
         LDA    ZP+1,S
         LDA    (ZP+1,S),Y
         LDA    >LONGV+1,X
         LDA    |GLOB+1
         LDA    >GLOB
         LDA    <ZP
         LDA    ]BACK
         LDA    :PART
         LDA    |OUTSIDE
         LDA    #<WORD
         LDA    #>WORD
         LDA    #^LONGV
         LDA    GLOB+:PART-]BACK
         JSR    GLOB
         JSR    OUTSIDE
         JMP    ]BACK
         BRL    ]BACK
         BRL    :PART

         ASL    A
         LDA:   WORD
         TSB:   WORD
         LDAZ   ZP
         LDAL   LONGV
         STAL   GLOB
         ADCL   LONGV
         SBCL   LONGV
         ANDL   LONGV
         ORAL   LONGV
         EORL   LONGV
         CMPL   LONGV
         JMPL   LONGV

NEXTG    NOP
* Every opcode and addressing mode. Direct and absolute operands are
* the absolute symbols ZP, WORD, LONGV, SRCB, and DSTB.
* A relative branch to *+2 lands on the next instruction.
* ADC
         ADC    #ZP  ; immediate
         ADC    ZP  ; direct
         ADC    ZP,X  ; direct,X
         ADC    (ZP,X)  ; (direct,X)
         ADC    (ZP),Y  ; (direct),Y
         ADC    WORD  ; absolute
         ADC    WORD,X  ; absolute,X
         ADC    WORD,Y  ; absolute,Y
         ADC    (ZP)  ; (direct)
         ADC    >LONGV  ; long
         ADC    >LONGV,X  ; long,X
         ADC    ZP,S  ; stack
         ADC    (ZP,S),Y  ; (stack),Y
         ADC    [ZP]  ; [direct]
         ADC    [ZP],Y  ; [direct],Y
* AND
         AND    #ZP  ; immediate
         AND    ZP  ; direct
         AND    ZP,X  ; direct,X
         AND    (ZP,X)  ; (direct,X)
         AND    (ZP),Y  ; (direct),Y
         AND    WORD  ; absolute
         AND    WORD,X  ; absolute,X
         AND    WORD,Y  ; absolute,Y
         AND    (ZP)  ; (direct)
         AND    >LONGV  ; long
         AND    >LONGV,X  ; long,X
         AND    ZP,S  ; stack
         AND    (ZP,S),Y  ; (stack),Y
         AND    [ZP]  ; [direct]
         AND    [ZP],Y  ; [direct],Y
* ASL
         ASL  ; implied
         ASL    ZP  ; direct
         ASL    ZP,X  ; direct,X
         ASL    WORD  ; absolute
         ASL    WORD,X  ; absolute,X
* BIT
         BIT    ZP  ; direct
         BIT    WORD  ; absolute
         BIT    ZP,X  ; direct,X
         BIT    WORD,X  ; absolute,X
         BIT    #ZP  ; immediate
* CMP
         CMP    #ZP  ; immediate
         CMP    ZP  ; direct
         CMP    ZP,X  ; direct,X
         CMP    (ZP,X)  ; (direct,X)
         CMP    (ZP),Y  ; (direct),Y
         CMP    WORD  ; absolute
         CMP    WORD,X  ; absolute,X
         CMP    WORD,Y  ; absolute,Y
         CMP    (ZP)  ; (direct)
         CMP    >LONGV  ; long
         CMP    >LONGV,X  ; long,X
         CMP    ZP,S  ; stack
         CMP    (ZP,S),Y  ; (stack),Y
         CMP    [ZP]  ; [direct]
         CMP    [ZP],Y  ; [direct],Y
* CPX
         CPX    #ZP  ; immediate
         CPX    ZP  ; direct
         CPX    WORD  ; absolute
* CPY
         CPY    #ZP  ; immediate
         CPY    ZP  ; direct
         CPY    WORD  ; absolute
* DEC
         DEC  ; implied
         DEC    ZP  ; direct
         DEC    ZP,X  ; direct,X
         DEC    WORD  ; absolute
         DEC    WORD,X  ; absolute,X
* EOR
         EOR    #ZP  ; immediate
         EOR    ZP  ; direct
         EOR    ZP,X  ; direct,X
         EOR    (ZP,X)  ; (direct,X)
         EOR    (ZP),Y  ; (direct),Y
         EOR    WORD  ; absolute
         EOR    WORD,X  ; absolute,X
         EOR    WORD,Y  ; absolute,Y
         EOR    (ZP)  ; (direct)
         EOR    >LONGV  ; long
         EOR    >LONGV,X  ; long,X
         EOR    ZP,S  ; stack
         EOR    (ZP,S),Y  ; (stack),Y
         EOR    [ZP]  ; [direct]
         EOR    [ZP],Y  ; [direct],Y
* INC
         INC  ; implied
         INC    ZP  ; direct
         INC    ZP,X  ; direct,X
         INC    WORD  ; absolute
         INC    WORD,X  ; absolute,X
* JMP
         JMP    WORD  ; absolute
         JMP    (WORD)  ; (absolute)
         JMP    (WORD,X)  ; (absolute,X)
         JMP    >LONGV  ; long
         JMP    [WORD]  ; [absolute]
* JML
         JML    >LONGV  ; long
         JML    [WORD]  ; [absolute]
* JSR
         JSR    WORD  ; absolute
         JSR    (WORD,X)  ; (absolute,X)
         JSR    >LONGV  ; long
* JSL
         JSL    >LONGV  ; long
* LDA
         LDA    #ZP  ; immediate
         LDA    ZP  ; direct
         LDA    ZP,X  ; direct,X
         LDA    (ZP,X)  ; (direct,X)
         LDA    (ZP),Y  ; (direct),Y
         LDA    WORD  ; absolute
         LDA    WORD,X  ; absolute,X
         LDA    WORD,Y  ; absolute,Y
         LDA    (ZP)  ; (direct)
         LDA    >LONGV  ; long
         LDA    >LONGV,X  ; long,X
         LDA    ZP,S  ; stack
         LDA    (ZP,S),Y  ; (stack),Y
         LDA    [ZP]  ; [direct]
         LDA    [ZP],Y  ; [direct],Y
* LDX
         LDX    #ZP  ; immediate
         LDX    ZP  ; direct
         LDX    ZP,Y  ; direct,Y
         LDX    WORD  ; absolute
         LDX    WORD,Y  ; absolute,Y
* LDY
         LDY    #ZP  ; immediate
         LDY    ZP  ; direct
         LDY    ZP,X  ; direct,X
         LDY    WORD  ; absolute
         LDY    WORD,X  ; absolute,X
* LSR
         LSR  ; implied
         LSR    ZP  ; direct
         LSR    ZP,X  ; direct,X
         LSR    WORD  ; absolute
         LSR    WORD,X  ; absolute,X
* ORA
         ORA    #ZP  ; immediate
         ORA    ZP  ; direct
         ORA    ZP,X  ; direct,X
         ORA    (ZP,X)  ; (direct,X)
         ORA    (ZP),Y  ; (direct),Y
         ORA    WORD  ; absolute
         ORA    WORD,X  ; absolute,X
         ORA    WORD,Y  ; absolute,Y
         ORA    (ZP)  ; (direct)
         ORA    >LONGV  ; long
         ORA    >LONGV,X  ; long,X
         ORA    ZP,S  ; stack
         ORA    (ZP,S),Y  ; (stack),Y
         ORA    [ZP]  ; [direct]
         ORA    [ZP],Y  ; [direct],Y
* ROL
         ROL  ; implied
         ROL    ZP  ; direct
         ROL    ZP,X  ; direct,X
         ROL    WORD  ; absolute
         ROL    WORD,X  ; absolute,X
* ROR
         ROR  ; implied
         ROR    ZP  ; direct
         ROR    ZP,X  ; direct,X
         ROR    WORD  ; absolute
         ROR    WORD,X  ; absolute,X
* SBC
         SBC    #ZP  ; immediate
         SBC    ZP  ; direct
         SBC    ZP,X  ; direct,X
         SBC    (ZP,X)  ; (direct,X)
         SBC    (ZP),Y  ; (direct),Y
         SBC    WORD  ; absolute
         SBC    WORD,X  ; absolute,X
         SBC    WORD,Y  ; absolute,Y
         SBC    (ZP)  ; (direct)
         SBC    >LONGV  ; long
         SBC    >LONGV,X  ; long,X
         SBC    ZP,S  ; stack
         SBC    (ZP,S),Y  ; (stack),Y
         SBC    [ZP]  ; [direct]
         SBC    [ZP],Y  ; [direct],Y
* STA
         STA    ZP  ; direct
         STA    ZP,X  ; direct,X
         STA    (ZP,X)  ; (direct,X)
         STA    (ZP),Y  ; (direct),Y
         STA    WORD  ; absolute
         STA    WORD,X  ; absolute,X
         STA    WORD,Y  ; absolute,Y
         STA    (ZP)  ; (direct)
         STA    >LONGV  ; long
         STA    >LONGV,X  ; long,X
         STA    ZP,S  ; stack
         STA    (ZP,S),Y  ; (stack),Y
         STA    [ZP]  ; [direct]
         STA    [ZP],Y  ; [direct],Y
* STX
         STX    ZP  ; direct
         STX    ZP,Y  ; direct,Y
         STX    WORD  ; absolute
* STY
         STY    ZP  ; direct
         STY    ZP,X  ; direct,X
         STY    WORD  ; absolute
* STZ
         STZ    ZP  ; direct
         STZ    ZP,X  ; direct,X
         STZ    WORD  ; absolute
         STZ    WORD,X  ; absolute,X
* TRB
         TRB    ZP  ; direct
         TRB    WORD  ; absolute
* TSB
         TSB    ZP  ; direct
         TSB    WORD  ; absolute
* BPL
         BPL    *+2  ; relative
* BMI
         BMI    *+2  ; relative
* BVC
         BVC    *+2  ; relative
* BVS
         BVS    *+2  ; relative
* BCC
         BCC    *+2  ; relative
* BCS
         BCS    *+2  ; relative
* BNE
         BNE    *+2  ; relative
* BEQ
         BEQ    *+2  ; relative
* BLT
         BLT    *+2  ; relative
* BGE
         BGE    *+2  ; relative
* BRA
         BRA    *+2  ; relative
* BRL
         BRL    *+3  ; relative long
* BRK
         BRK  ; implied
         BRK    ZP  ; immediate byte
* RTI
         RTI  ; implied
* RTS
         RTS  ; implied
* PHP
         PHP  ; implied
* CLC
         CLC  ; implied
* PLP
         PLP  ; implied
* SEC
         SEC  ; implied
* PHA
         PHA  ; implied
* CLI
         CLI  ; implied
* PLA
         PLA  ; implied
* SEI
         SEI  ; implied
* DEY
         DEY  ; implied
* TYA
         TYA  ; implied
* TAY
         TAY  ; implied
* CLV
         CLV  ; implied
* INY
         INY  ; implied
* CLD
         CLD  ; implied
* INX
         INX  ; implied
* SED
         SED  ; implied
* TXA
         TXA  ; implied
* TXS
         TXS  ; implied
* TAX
         TAX  ; implied
* TSX
         TSX  ; implied
* DEX
         DEX  ; implied
* NOP
         NOP  ; implied
* PHY
         PHY  ; implied
* PLY
         PLY  ; implied
* PHX
         PHX  ; implied
* PLX
         PLX  ; implied
* PHD
         PHD  ; implied
* PLD
         PLD  ; implied
* PHK
         PHK  ; implied
* RTL
         RTL  ; implied
* PHB
         PHB  ; implied
* PLB
         PLB  ; implied
* WAI
         WAI  ; implied
* STP
         STP  ; implied
* XBA
         XBA  ; implied
* SWA
         SWA  ; implied
* XCE
         XCE  ; implied
* TCS
         TCS  ; implied
* TAS
         TAS  ; implied
* TSC
         TSC  ; implied
* TSA
         TSA  ; implied
* TCD
         TCD  ; implied
* TAD
         TAD  ; implied
* TDC
         TDC  ; implied
* TDA
         TDA  ; implied
* TXY
         TXY  ; implied
* TYX
         TYX  ; implied
* COP
         COP    #$30  ; immediate byte
* WDM
         WDM    ZP  ; immediate byte
         WDM  ; implied
* PEA
         PEA    #WORD  ; immediate word
         PEA    WORD  ; absolute
* PEI
         PEI    (ZP)  ; (direct)
         PEI    ZP  ; direct
* PER
         PER    *+3  ; relative long
* MVN
         MVN    SRCB,DSTB  ; block move
* MVP
         MVP    SRCB,DSTB  ; block move
* REP
         REP    #ZP  ; immediate
         REP    #$30  ; immediate byte
* SEP
         SEP    #ZP  ; immediate
         SEP    #$30  ; immediate byte


* Immediate operands with M and X set to 16 bits
         MX     %00
         ADC    #WORD
         AND    #WORD
         BIT    #WORD
         CMP    #WORD
         CPX    #WORD
         CPY    #WORD
         EOR    #WORD
         LDA    #WORD
         LDX    #WORD
         LDY    #WORD
         ORA    #WORD
         SBC    #WORD
         MX     %11

.EN
