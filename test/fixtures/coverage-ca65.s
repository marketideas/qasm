; Assembler: ca65
;
; Same program as coverage-merlin.s. The object matches byte for byte.
; back and part are the local labels. (1+2)*3 is 9. 1+2*3 is 7.
; ~1 is bitwise NOT. 'A'|$80 is the high-bit character.

.p816
.a8
.i8
.org    $8000

ZP       =      $10
WORD     =      $1234
MASK     =      $00FF
LONGV    =      $012345
ONE      =      1
SRCB     =      $01
DSTB     =      $02
BELL     =      $FBDD
.export  BELL
.import  OUTSIDE
.set     STEP, 1
.set     STEP, STEP+1

.export  GLOB
GLOB:
         nop
back:
         nop
         beq    back
part:
         nop
         bra    part

         .byte  (1+2)*3, 1+2*3, 20/3, 20/3*3
         .byte  1=1, 1<>2, 1<2, 2>1
         .byte  WORD&MASK, 1|2, WORD^MASK, ~1
         .byte  $2A, %00101010
         .byte  'A', 'A'|$80
         .byte  <WORD, >WORD, ^LONGV
         .byte  <GLOB, >GLOB, ^GLOB, STEP
         .word  WORD, GLOB, GLOB-GLOB, *-GLOB, back, part, BELL, OUTSIDE+WORD
         .word  GLOB+back-part
         .byte  >WORD, <WORD
         .faraddr LONGV
         .dword LONGV, GLOB

         lda    ZP+1
         lda    ZP+1,x
         lda    (ZP+1),y
         lda    [ZP+1],y
         lda    (ZP+1,x)
         lda    ZP+1,s
         lda    (ZP+1,s),y
         lda    f:LONGV+1,x
         lda    a:GLOB+1
         lda    f:GLOB
         lda    z:ZP
         lda    back
         lda    part
         lda    a:OUTSIDE
         lda    #<WORD
         lda    #>WORD
         lda    #^LONGV
         lda    GLOB+part-back
         jsr    GLOB
         jsr    OUTSIDE
         jmp    back
         brl    back
         brl    part

         asl    a
         lda    WORD
         tsb    WORD
         ldaz   ZP
         ldal   LONGV
         stal   GLOB
         adcl   LONGV
         sbcl   LONGV
         andl   LONGV
         oral   LONGV
         eorl   LONGV
         cmpl   LONGV
         jmpl   LONGV

NEXTG:
         nop
; Every opcode and addressing mode. Direct and absolute operands are
; the absolute symbols ZP, WORD, LONGV, SRCB, and DSTB.
; A relative branch to *+2 lands on the next instruction.
; ADC
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
; AND
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
; ASL
         ASL  ; implied
         ASL    ZP  ; direct
         ASL    ZP,X  ; direct,X
         ASL    WORD  ; absolute
         ASL    WORD,X  ; absolute,X
; BIT
         BIT    ZP  ; direct
         BIT    WORD  ; absolute
         BIT    ZP,X  ; direct,X
         BIT    WORD,X  ; absolute,X
         BIT    #ZP  ; immediate
; CMP
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
; CPX
         CPX    #ZP  ; immediate
         CPX    ZP  ; direct
         CPX    WORD  ; absolute
; CPY
         CPY    #ZP  ; immediate
         CPY    ZP  ; direct
         CPY    WORD  ; absolute
; DEC
         DEC  ; implied
         DEC    ZP  ; direct
         DEC    ZP,X  ; direct,X
         DEC    WORD  ; absolute
         DEC    WORD,X  ; absolute,X
; EOR
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
; INC
         INC  ; implied
         INC    ZP  ; direct
         INC    ZP,X  ; direct,X
         INC    WORD  ; absolute
         INC    WORD,X  ; absolute,X
; JMP
         JMP    WORD  ; absolute
         JMP    (WORD)  ; (absolute)
         JMP    (WORD,X)  ; (absolute,X)
         JMP    >LONGV  ; long
         JMP    [WORD]  ; [absolute]
; JML
         JML    >LONGV  ; long
         JML    [WORD]  ; [absolute]
; JSR
         JSR    WORD  ; absolute
         JSR    (WORD,X)  ; (absolute,X)
         JSR    >LONGV  ; long
; JSL
         JSL    >LONGV  ; long
; LDA
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
; LDX
         LDX    #ZP  ; immediate
         LDX    ZP  ; direct
         LDX    ZP,Y  ; direct,Y
         LDX    WORD  ; absolute
         LDX    WORD,Y  ; absolute,Y
; LDY
         LDY    #ZP  ; immediate
         LDY    ZP  ; direct
         LDY    ZP,X  ; direct,X
         LDY    WORD  ; absolute
         LDY    WORD,X  ; absolute,X
; LSR
         LSR  ; implied
         LSR    ZP  ; direct
         LSR    ZP,X  ; direct,X
         LSR    WORD  ; absolute
         LSR    WORD,X  ; absolute,X
; ORA
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
; ROL
         ROL  ; implied
         ROL    ZP  ; direct
         ROL    ZP,X  ; direct,X
         ROL    WORD  ; absolute
         ROL    WORD,X  ; absolute,X
; ROR
         ROR  ; implied
         ROR    ZP  ; direct
         ROR    ZP,X  ; direct,X
         ROR    WORD  ; absolute
         ROR    WORD,X  ; absolute,X
; SBC
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
; STA
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
; STX
         STX    ZP  ; direct
         STX    ZP,Y  ; direct,Y
         STX    WORD  ; absolute
; STY
         STY    ZP  ; direct
         STY    ZP,X  ; direct,X
         STY    WORD  ; absolute
; STZ
         STZ    ZP  ; direct
         STZ    ZP,X  ; direct,X
         STZ    WORD  ; absolute
         STZ    WORD,X  ; absolute,X
; TRB
         TRB    ZP  ; direct
         TRB    WORD  ; absolute
; TSB
         TSB    ZP  ; direct
         TSB    WORD  ; absolute
; BPL
         BPL    *+2  ; relative
; BMI
         BMI    *+2  ; relative
; BVC
         BVC    *+2  ; relative
; BVS
         BVS    *+2  ; relative
; BCC
         BCC    *+2  ; relative
; BCS
         BCS    *+2  ; relative
; BNE
         BNE    *+2  ; relative
; BEQ
         BEQ    *+2  ; relative
; BLT
         BLT    *+2  ; relative
; BGE
         BGE    *+2  ; relative
; BRA
         BRA    *+2  ; relative
; BRL
         BRL    *+3  ; relative long
; BRK
         BRK  ; implied
         BRK    ZP  ; immediate byte
; RTI
         RTI  ; implied
; RTS
         RTS  ; implied
; PHP
         PHP  ; implied
; CLC
         CLC  ; implied
; PLP
         PLP  ; implied
; SEC
         SEC  ; implied
; PHA
         PHA  ; implied
; CLI
         CLI  ; implied
; PLA
         PLA  ; implied
; SEI
         SEI  ; implied
; DEY
         DEY  ; implied
; TYA
         TYA  ; implied
; TAY
         TAY  ; implied
; CLV
         CLV  ; implied
; INY
         INY  ; implied
; CLD
         CLD  ; implied
; INX
         INX  ; implied
; SED
         SED  ; implied
; TXA
         TXA  ; implied
; TXS
         TXS  ; implied
; TAX
         TAX  ; implied
; TSX
         TSX  ; implied
; DEX
         DEX  ; implied
; NOP
         NOP  ; implied
; PHY
         PHY  ; implied
; PLY
         PLY  ; implied
; PHX
         PHX  ; implied
; PLX
         PLX  ; implied
; PHD
         PHD  ; implied
; PLD
         PLD  ; implied
; PHK
         PHK  ; implied
; RTL
         RTL  ; implied
; PHB
         PHB  ; implied
; PLB
         PLB  ; implied
; WAI
         WAI  ; implied
; STP
         STP  ; implied
; XBA
         XBA  ; implied
; SWA
         SWA  ; implied
; XCE
         XCE  ; implied
; TCS
         TCS  ; implied
; TAS
         TAS  ; implied
; TSC
         TSC  ; implied
; TSA
         TSA  ; implied
; TCD
         TCD  ; implied
; TAD
         TAD  ; implied
; TDC
         TDC  ; implied
; TDA
         TDA  ; implied
; TXY
         TXY  ; implied
; TYX
         TYX  ; implied
; COP
         COP    #$30  ; immediate byte
; WDM
         WDM    ZP  ; immediate byte
         WDM  ; implied
; PEA
         PEA    #WORD  ; immediate word
         PEA    WORD  ; absolute
; PEI
         PEI    (ZP)  ; (direct)
         PEI    ZP  ; direct
; PER
         PER    *+3  ; relative long
; MVN
         MVN    SRCB,DSTB  ; block move
; MVP
         MVP    SRCB,DSTB  ; block move
; REP
         REP    #ZP  ; immediate
         REP    #$30  ; immediate byte
; SEP
         SEP    #ZP  ; immediate
         SEP    #$30  ; immediate byte

; Immediate operands with M and X set to 16 bits
.a16
.i16
         ADC    #WORD  ; immediate, 16-bit register
         AND    #WORD  ; immediate, 16-bit register
         BIT    #WORD  ; immediate, 16-bit register
         CMP    #WORD  ; immediate, 16-bit register
         CPX    #WORD  ; immediate, 16-bit register
         CPY    #WORD  ; immediate, 16-bit register
         EOR    #WORD  ; immediate, 16-bit register
         LDA    #WORD  ; immediate, 16-bit register
         LDX    #WORD  ; immediate, 16-bit register
         LDY    #WORD  ; immediate, 16-bit register
         ORA    #WORD  ; immediate, 16-bit register
         SBC    #WORD  ; immediate, 16-bit register
.a8
.i8

.end
