* Assembler: ORCA/M
*
* Same program as coverage-merlin.s. The object matches byte for byte.
* ~loop and ~tail are the local labels. (1+2)*3 is 9. 1+2*3 is 7.
* ~1 is bitwise NOT.

main     start
         case   on
         machine 65816
         longa  off
         longi  off
         org    $8000

zp       equ    $10
word     equ    $1234
mask     equ    $00ff
longv    equ    $012345
one      equ    1
srcb     equ    $01
dstb     equ    $02
bell     gequ   $fbdd
step     equ    2
         extern outside

glob     entry
         nop
~loop    anop
         nop
         beq    ~loop
~tail    anop
         nop
         bra    ~tail

         dc     i1'(1+2)*3,1+2*3,20/3,20/3*3'
         dc     i1'1=1,1<>2,1<2,2>1'
         dc     i1'word&mask,1|2,word^mask,~1'
         dc     i1'$2a,%00101010'
         dc     c'A'
         dc     i1'"A"'
         dc     i1'<word,>word,^longv'
         dc     i1'<glob,>glob,^glob,step'
         dc     i2'word,glob,glob-glob,*-glob,~loop,~tail,bell,outside+word'
         dc     i2'glob+~loop-~tail'
         dc     i1'>word,<word'
         dc     i3'longv'
         dc     i4'longv,glob'

         lda    zp+1
         lda    zp+1,x
         lda    (zp+1),y
         lda    [zp+1],y
         lda    (zp+1,x)
         lda    zp+1,s
         lda    (zp+1,s),y
         lda    >longv+1,x
         lda    |glob+1
         lda    >glob
         lda    <zp
         lda    ~loop
         lda    ~tail
         lda    |outside
         lda    #<word
         lda    #>word
         lda    #^longv
         lda    glob+~tail-~loop
         jsr    glob
         jsr    outside
         jmp    ~loop
         brl    ~loop
         brl    ~tail

         asl    a
         lda    word
         tsb    word
         ldaz   zp
         ldal   longv
         stal   glob
         adcl   longv
         sbcl   longv
         andl   longv
         oral   longv
         eorl   longv
         cmpl   longv
         jmpl   longv

nextg    anop
         nop
* Every opcode and addressing mode.
* adc
         adc    #zp  ; immediate
         adc    zp  ; direct
         adc    zp,x  ; direct,X
         adc    (zp,x)  ; (direct,X)
         adc    (zp),y  ; (direct),Y
         adc    word  ; absolute
         adc    word,x  ; absolute,X
         adc    word,y  ; absolute,Y
         adc    (zp)  ; (direct)
         adc    >longv  ; long
         adc    >longv,x  ; long,X
         adc    zp,s  ; stack
         adc    (zp,s),y  ; (stack),Y
         adc    [zp]  ; [direct]
         adc    [zp],y  ; [direct],Y
* and
         and    #zp  ; immediate
         and    zp  ; direct
         and    zp,x  ; direct,X
         and    (zp,x)  ; (direct,X)
         and    (zp),y  ; (direct),Y
         and    word  ; absolute
         and    word,x  ; absolute,X
         and    word,y  ; absolute,Y
         and    (zp)  ; (direct)
         and    >longv  ; long
         and    >longv,x  ; long,X
         and    zp,s  ; stack
         and    (zp,s),y  ; (stack),Y
         and    [zp]  ; [direct]
         and    [zp],y  ; [direct],Y
* asl
         asl  ; implied
         asl    zp  ; direct
         asl    zp,x  ; direct,X
         asl    word  ; absolute
         asl    word,x  ; absolute,X
* bit
         bit    zp  ; direct
         bit    word  ; absolute
         bit    zp,x  ; direct,X
         bit    word,x  ; absolute,X
         bit    #zp  ; immediate
* cmp
         cmp    #zp  ; immediate
         cmp    zp  ; direct
         cmp    zp,x  ; direct,X
         cmp    (zp,x)  ; (direct,X)
         cmp    (zp),y  ; (direct),Y
         cmp    word  ; absolute
         cmp    word,x  ; absolute,X
         cmp    word,y  ; absolute,Y
         cmp    (zp)  ; (direct)
         cmp    >longv  ; long
         cmp    >longv,x  ; long,X
         cmp    zp,s  ; stack
         cmp    (zp,s),y  ; (stack),Y
         cmp    [zp]  ; [direct]
         cmp    [zp],y  ; [direct],Y
* cpx
         cpx    #zp  ; immediate
         cpx    zp  ; direct
         cpx    word  ; absolute
* cpy
         cpy    #zp  ; immediate
         cpy    zp  ; direct
         cpy    word  ; absolute
* dec
         dec  ; implied
         dec    zp  ; direct
         dec    zp,x  ; direct,X
         dec    word  ; absolute
         dec    word,x  ; absolute,X
* eor
         eor    #zp  ; immediate
         eor    zp  ; direct
         eor    zp,x  ; direct,X
         eor    (zp,x)  ; (direct,X)
         eor    (zp),y  ; (direct),Y
         eor    word  ; absolute
         eor    word,x  ; absolute,X
         eor    word,y  ; absolute,Y
         eor    (zp)  ; (direct)
         eor    >longv  ; long
         eor    >longv,x  ; long,X
         eor    zp,s  ; stack
         eor    (zp,s),y  ; (stack),Y
         eor    [zp]  ; [direct]
         eor    [zp],y  ; [direct],Y
* inc
         inc  ; implied
         inc    zp  ; direct
         inc    zp,x  ; direct,X
         inc    word  ; absolute
         inc    word,x  ; absolute,X
* jmp
         jmp    word  ; absolute
         jmp    (word)  ; (absolute)
         jmp    (word,x)  ; (absolute,X)
         jmp    >longv  ; long
         jmp    [word]  ; [absolute]
* jml
         jml    >longv  ; long
         jml    [word]  ; [absolute]
* jsr
         jsr    word  ; absolute
         jsr    (word,x)  ; (absolute,X)
         jsr    >longv  ; long
* jsl
         jsl    >longv  ; long
* lda
         lda    #zp  ; immediate
         lda    zp  ; direct
         lda    zp,x  ; direct,X
         lda    (zp,x)  ; (direct,X)
         lda    (zp),y  ; (direct),Y
         lda    word  ; absolute
         lda    word,x  ; absolute,X
         lda    word,y  ; absolute,Y
         lda    (zp)  ; (direct)
         lda    >longv  ; long
         lda    >longv,x  ; long,X
         lda    zp,s  ; stack
         lda    (zp,s),y  ; (stack),Y
         lda    [zp]  ; [direct]
         lda    [zp],y  ; [direct],Y
* ldx
         ldx    #zp  ; immediate
         ldx    zp  ; direct
         ldx    zp,y  ; direct,Y
         ldx    word  ; absolute
         ldx    word,y  ; absolute,Y
* ldy
         ldy    #zp  ; immediate
         ldy    zp  ; direct
         ldy    zp,x  ; direct,X
         ldy    word  ; absolute
         ldy    word,x  ; absolute,X
* lsr
         lsr  ; implied
         lsr    zp  ; direct
         lsr    zp,x  ; direct,X
         lsr    word  ; absolute
         lsr    word,x  ; absolute,X
* ora
         ora    #zp  ; immediate
         ora    zp  ; direct
         ora    zp,x  ; direct,X
         ora    (zp,x)  ; (direct,X)
         ora    (zp),y  ; (direct),Y
         ora    word  ; absolute
         ora    word,x  ; absolute,X
         ora    word,y  ; absolute,Y
         ora    (zp)  ; (direct)
         ora    >longv  ; long
         ora    >longv,x  ; long,X
         ora    zp,s  ; stack
         ora    (zp,s),y  ; (stack),Y
         ora    [zp]  ; [direct]
         ora    [zp],y  ; [direct],Y
* rol
         rol  ; implied
         rol    zp  ; direct
         rol    zp,x  ; direct,X
         rol    word  ; absolute
         rol    word,x  ; absolute,X
* ror
         ror  ; implied
         ror    zp  ; direct
         ror    zp,x  ; direct,X
         ror    word  ; absolute
         ror    word,x  ; absolute,X
* sbc
         sbc    #zp  ; immediate
         sbc    zp  ; direct
         sbc    zp,x  ; direct,X
         sbc    (zp,x)  ; (direct,X)
         sbc    (zp),y  ; (direct),Y
         sbc    word  ; absolute
         sbc    word,x  ; absolute,X
         sbc    word,y  ; absolute,Y
         sbc    (zp)  ; (direct)
         sbc    >longv  ; long
         sbc    >longv,x  ; long,X
         sbc    zp,s  ; stack
         sbc    (zp,s),y  ; (stack),Y
         sbc    [zp]  ; [direct]
         sbc    [zp],y  ; [direct],Y
* sta
         sta    zp  ; direct
         sta    zp,x  ; direct,X
         sta    (zp,x)  ; (direct,X)
         sta    (zp),y  ; (direct),Y
         sta    word  ; absolute
         sta    word,x  ; absolute,X
         sta    word,y  ; absolute,Y
         sta    (zp)  ; (direct)
         sta    >longv  ; long
         sta    >longv,x  ; long,X
         sta    zp,s  ; stack
         sta    (zp,s),y  ; (stack),Y
         sta    [zp]  ; [direct]
         sta    [zp],y  ; [direct],Y
* stx
         stx    zp  ; direct
         stx    zp,y  ; direct,Y
         stx    word  ; absolute
* sty
         sty    zp  ; direct
         sty    zp,x  ; direct,X
         sty    word  ; absolute
* stz
         stz    zp  ; direct
         stz    zp,x  ; direct,X
         stz    word  ; absolute
         stz    word,x  ; absolute,X
* trb
         trb    zp  ; direct
         trb    word  ; absolute
* tsb
         tsb    zp  ; direct
         tsb    word  ; absolute
* bpl
         bpl    *+2  ; relative
* bmi
         bmi    *+2  ; relative
* bvc
         bvc    *+2  ; relative
* bvs
         bvs    *+2  ; relative
* bcc
         bcc    *+2  ; relative
* bcs
         bcs    *+2  ; relative
* bne
         bne    *+2  ; relative
* beq
         beq    *+2  ; relative
* blt
         blt    *+2  ; relative
* bge
         bge    *+2  ; relative
* bra
         bra    *+2  ; relative
* brl
         brl    *+3  ; relative long
* brk
         brk  ; implied
         brk    zp  ; immediate byte
* rti
         rti  ; implied
* rts
         rts  ; implied
* php
         php  ; implied
* clc
         clc  ; implied
* plp
         plp  ; implied
* sec
         sec  ; implied
* pha
         pha  ; implied
* cli
         cli  ; implied
* pla
         pla  ; implied
* sei
         sei  ; implied
* dey
         dey  ; implied
* tya
         tya  ; implied
* tay
         tay  ; implied
* clv
         clv  ; implied
* iny
         iny  ; implied
* cld
         cld  ; implied
* inx
         inx  ; implied
* sed
         sed  ; implied
* txa
         txa  ; implied
* txs
         txs  ; implied
* tax
         tax  ; implied
* tsx
         tsx  ; implied
* dex
         dex  ; implied
* nop
         nop  ; implied
* phy
         phy  ; implied
* ply
         ply  ; implied
* phx
         phx  ; implied
* plx
         plx  ; implied
* phd
         phd  ; implied
* pld
         pld  ; implied
* phk
         phk  ; implied
* rtl
         rtl  ; implied
* phb
         phb  ; implied
* plb
         plb  ; implied
* wai
         wai  ; implied
* stp
         stp  ; implied
* xba
         xba  ; implied
* swa
         swa  ; implied
* xce
         xce  ; implied
* tcs
         tcs  ; implied
* tas
         tas  ; implied
* tsc
         tsc  ; implied
* tsa
         tsa  ; implied
* tcd
         tcd  ; implied
* tad
         tad  ; implied
* tdc
         tdc  ; implied
* tda
         tda  ; implied
* txy
         txy  ; implied
* tyx
         tyx  ; implied
* cop
         cop    #$30  ; immediate byte
* wdm
         wdm    zp  ; immediate byte
         wdm  ; implied
* pea
         pea    #word  ; immediate word
         pea    word  ; absolute
* pei
         pei    (zp)  ; (direct)
         pei    zp  ; direct
* per
         per    *+3  ; relative long
* mvn
         mvn    srcb,dstb  ; block move
* mvp
         mvp    srcb,dstb  ; block move
* rep
         rep    #zp  ; immediate
         rep    #$30  ; immediate byte
* sep
         sep    #zp  ; immediate
         sep    #$30  ; immediate byte

* Immediate operands with M and X set to 16 bits
         longa  on
         longi  on
         adc    #word  ; immediate, 16-bit register
         and    #word  ; immediate, 16-bit register
         bit    #word  ; immediate, 16-bit register
         cmp    #word  ; immediate, 16-bit register
         cpx    #word  ; immediate, 16-bit register
         cpy    #word  ; immediate, 16-bit register
         eor    #word  ; immediate, 16-bit register
         lda    #word  ; immediate, 16-bit register
         ldx    #word  ; immediate, 16-bit register
         ldy    #word  ; immediate, 16-bit register
         ora    #word  ; immediate, 16-bit register
         sbc    #word  ; immediate, 16-bit register
         longa  off
         longi  off

         end
