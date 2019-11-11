              lst   off
              tr    adr
              xc
              xc
              cyc   avg

              rel
* dsk object/optest.l

              mx    %00

              rep   #$FF
              sep   #$FF              ;so we don't mess up MX status
                                      ;each are 3 cycles
              xba                     ;2 cycles

              mx    %11
                                      ;14
imediate                              ;# 2 and 3 cycles
              ldy   #$FFFF
              cpy   #$FFFF
              cpx   #$FFFF
              ldx   #$FFFF
              ora   #$FFFF
              and   #$FFFF
              eor   #$FFFF
              adc   #$FFFF
              bit   #$FFFF
              lda   #$FFFF
              cmp   #$FFFF
              sbc   #$FFFF

              ldy   #$FFFF
              cpy   #$FFFF
              cpx   #$FFFF
              ldx   #$FFFF
              ora   #$FFFF
              and   #$FFFF
              eor   #$FFFF
              adc   #$FFFF
              bit   #$FFFF
              lda   #$FFFF
              cmp   #$FFFF
              sbc   #$FFFF

;16
absolute                              ;a   4 and 5 cycles
              bit   $FFFF
              sty   $FFFF
              stz   $FFFF
              ldy   $FFFF
              cpy   $FFFF
              cpx   $FFFF
              stx   $FFFF
              ldx   $FFFF
              ora   $FFFF
              and   $FFFF
              eor   $FFFF
              adc   $FFFF
              sta   $FFFF
              lda   $FFFF
              cmp   $FFFF
              sbc   $FFFF


;8
absolutermw                           ;a (r/m/w) 6 and 8

              asl   $FFFF
              rol   $FFFF
              lsr   $FFFF
              ror   $FFFF
              dec   $FFFF
              inc   $FFFF
              tsb   $FFFF
              trb   $FFFF

                                      ;2
absjump
              jmp   $FFFF             ;3 cycles
              jsr   $FFFF             ;6 cycles

;8
abslong                               ;5 and 6 cycles
              oral  $FFFFFF
              andl  $FFFFFF
              eorl  $FFFFFF
              adcl  $FFFFFF
              stal  $FFFFFF
              ldal  $FFFFFF
              cmpl  $FFFFFF
              sbcl  $FFFFFF

;2
absljmp
              jml   $FFFFFF           ;4 cycles
              jsl   $FFFFFF           ;8 cycles

                                      ;16
direct                                ;d   3,4 and 5 cycles
              bit   $FF
              sty   $FF
              stz   $FF
              ldy   $FF
              cpy   $FF
              cpx   $FF
              stx   $FF
              ldx   $FF
              ora   $FF
              and   $FF
              eor   $FF
              adc   $FF
              sta   $FF
              lda   $FF
              cmp   $FF
              sbc   $FF

                                      ;8
directrmw                             ;d (r/m/w) 5,6,7 and 8
              asl   $FF
              rol   $FF
              lsr   $FF
              ror   $FF
              dec   $FF
              inc   $FF
              tsb   $FF
              trb   $FF

                                      ;6
areg                                  ;2 cycles
              asl
              inc
              rol
              dec
              lsr
              ror


;25
implied                               ;2 cycles

              dey
              iny
              inx
              dex
              nop
              tya
              tay
              txa
              txs
              tax
              tsx
              tcs
              tsc
              tcd
              tdc
              txy
              tyx
              clc
              sec
              cli
              sei
              clv
              cld
              sed

                                      ;1
implied1
              xba                     ;3 cycles

                                      ;2
wait                                  ;3 cycles
              wai
              stp

                                      ;8
dii                                   ;(d),y  5,6,7, and 8
              ora   ($ff),y
              and   ($ff),y
              eor   ($ff),y
              adc   ($ff),y
              sta   ($ff),y
              lda   ($ff),y
              cmp   ($ff),y
              sbc   ($ff),y

                                      ;8
diil                                  ;[d],y  6,7, and 8
              ora   [$ff],y
              and   [$ff],y
              eor   [$ff],y
              adc   [$ff],y
              sta   [$ff],y
              lda   [$ff],y
              cmp   [$ff],y
              sbc   [$ff],y

                                      ;8
diix                                  ;(d,x)  6,7, and 8
              ora   ($FF,X)
              and   ($FF,X)
              eor   ($FF,X)
              adc   ($FF,X)
              sta   ($FF,X)
              lda   ($FF,X)
              cmp   ($FF,X)
              sbc   ($FF,X)


                                      ;12
dx                                    ;d,x  4,5, and 6
              bit   $FF,x
              stz   $FF,x
              sty   $FF,x
              ldy   $FF,x
              ora   $FF,x
              and   $FF,x
              eor   $FF,x
              adc   $FF,x
              sta   $FF,x
              lda   $FF,x
              cmp   $FF,x
              sbc   $FF,x

                                      ;6
dxrwm                                 ;d,x (r/m/w) 6,7,8, and 9
              asl   $FF,x
              rol   $FF,x
              lsr   $FF,x
              ror   $FF,x
              dec   $FF,x
              inc   $FF,x

                                      ;2
dy                                    ;d,y  4,5 and 6
              stx   $FF,y
              ldx   $FF,y

                                      ;11
absx                                  ;a,x  4,5 and 6
              bit   $FFFF,x
              ldy   $FFFF,x
              stz   $FFFF,x
              ora   $FFFF,x
              and   $FFFF,x
              eor   $FFFF,x
              adc   $FFFF,x
              sta   $FFFF,x
              lda   $FFFF,x
              cmp   $FFFF,x
              sbc   $FFFF,x

                                      ;6
absxrmw                               ;a,x (r/m/w)  7 and 9
              asl   $FFFF,x
              rol   $FFFF,x
              lsr   $FFFF,x
              ror   $FFFF,x
              dec   $FFFF,x
              inc   $FFFF,x

                                      ;8
abslx                                 ;al,x  5 and 6
              oral  $FFFFFF,x
              andl  $FFFFFF,x
              eorl  $FFFFFF,x
              adcl  $FFFFFF,x
              stal  $FFFFFF,x
              ldal  $FFFFFF,x
              cmpl  $FFFFFF,x
              sbcl  $FFFFFF,x

                                      ;9
absy                                  ;a,y  4,5 and 6
              ldx   $FFFF,y
              ora   $FFFF,y
              and   $FFFF,y
              eor   $FFFF,y
              adc   $FFFF,y
              sta   $FFFF,y
              lda   $FFFF,y
              cmp   $FFFF,y
              sbc   $FFFF,y

                                      ;9
relative                              ;2,3 and 4
              bpl   relative
              bmi   relative
              bvc   relative
              bvs   relative
              bcc   relative
              bcs   relative
              bne   relative
              beq   relative
              bra   relative

                                      ;1
relativelong                          ;4 cycles
              brl   relativelong

                                      ;2
indirjmp
              jmp   ($FFFF)           ;5 3 bytes
              jml   [$FFFF]           ;6 3 bytes
; jml ($ffff) ;5 cycles

                                      ;8
dindirect                             ;(d)  5,6,and 7
              ora   ($ff)
              and   ($ff)
              eor   ($ff)
              adc   ($ff)
              sta   ($ff)
              lda   ($ff)
              cmp   ($ff)
              sbc   ($ff)

                                      ;8
dindirectl                            ;[d]  6,7, and 8
              ora   [$ff],y
              and   [$ff],y
              eor   [$ff],y
              adc   [$ff],y
              sta   [$ff],y
              lda   [$ff],y
              cmp   [$ff],y
              sbc   [$ff],y

                                      ;2
abdindinx
              jmp   ($FFFF,x)         ;6
              jsr   ($FFFF,x)         ;8
                                      ;2
interupts
              brk   $FF               ;7 and 8 (7 if E=1)
              cop   $FF               ;7 and 8

                                      ;3
stackreturn
              rti                     ;6 and 7
              rts                     ;6
              rtl                     ;6

                                      ;7
stackpush                             ;3 and 4
              php
              pha
              phy
              phx
              phd
              phk
              phb

                                      ;6
stackpull                             ;4 and 5
              plp
              pla
              ply
              plx
              pld
              plb

                                      ;3
stackadd
              pei   $FF               ;6 and 7
              pea   $FFFF             ;5
              per   $FFFF             ;6

;8
stackrel                              ;d,s  4 and 5
              ora   $FF,s
              and   $FF,s
              eor   $FF,s
              adc   $FF,s
              sta   $FF,s
              lda   $FF,s
              cmp   $FF,s
              sbc   $FF,s

                                      ;8
stackrely                             ;d,s  7 and 8
              ora   ($FF,s),y
              and   ($FF,s),y
              eor   ($FF,s),y
              adc   ($FF,s),y
              sta   ($FF,s),y
              lda   ($FF,s),y
              cmp   ($FF,s),y
              sbc   ($FF,s),y


                                      ;2
move                                  ;7 cycles per byte

              mvn   $123456,$123456
              mvp   $123456,$123456

misc          wdm   $FF


              lst
              chk
              lst   off

* sav object/optest.1


