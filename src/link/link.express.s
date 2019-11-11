writeexp       php
               rep           $30
               stz           :errcode
               stz           :delflag
               jsr           randomize
               pha
               psl           #tempname+12
               pea           4
               tll           $220b                   ;int2hex

               jsr           einitvars
               jcs           :errxit
               jsr           readfile
               jcs           :errxit
               jsr           buildexp
               jcs           :errxit

               jsr           writesegments
               jcs           :errxit
               jsr           writeexphdr
               jcs           :errxit
               jmp           :xit
:errxit        rep           $30
               sta           :errcode
:xit           rep           $30
               lda           infileopen
               beq           :1
               _close        infileopen
               stz           infileopen
:1             lda           eoutfileopen
               beq           :3
               _close        eoutfileopen
               stz           eoutfileopen
:3             lda           :errcode
               bne           :delete
               _Destroy      indelete
               bcc           :rename
               sta           :errcode
               jmp           :delete
:rename        dec           :delflag
               _ChangePath   renameparm
               bcc           :2
               sta           :errcode
:delete
               _Destroy      outdelete
:2             rep           $30
               lda           :errcode
               cmp           #$00
               beq           :good
               lda           :delflag
               beq           :p0
               psl           #badstr1
               jmp           :p
:p0            psl           #badstr
:p             _QADrawstring
               lda           :errcode
               jsr           prbytel
               lda           #$0d
               jsr           drawchar
               jmp           :xit1
:good          psl           #goodstr
               _QADrawstring
:xit1          lda           #$0d
               jsr           drawchar
               plp
               lda           :errcode
               cmp           one
               rts
:errcode       ds            2
:delflag       ds            2
goodstr        str           'successful.',0d
badstr         str           'unsuccessful. Error $'
badstr1        str           'unsuccessful, output file DELETED.',0d

einitvars      php
               rep           $30
               stz           remapseg
               stz           segdataptr
               stz           segdataptr+2
               stz           segdatahdl
               stz           segdatahdl+2
               stz           seghdrptr
               stz           seghdrptr+2
               stz           seghdrhdl
               stz           seghdrhdl+2
               stz           expptr
               stz           expptr+2
               stz           exphdl
               stz           exphdl+2
               stz           currentseg
               stz           currentseghdr

               stz           numsegments
               stz           infileopen
               stz           eoutfileopen
               ldx           #$00
               lda           #$00
]lup           sta           segdata,x
               inx
               inx
               cpx           #32*emaxsegments
               blt           ]lup
               _getfileinfo  ininfo
               jcs           :sec
               lda           intype
               and           #$f0
               cmp           #$b0
               beq           :open
               lda           #notomf
               jmp           :sec
:open          _open         infileopen
               jcs           :sec
               lda           infileopen
               sta           inread
               sta           ineofparm


               _Destroy      outdelete
               _create       outcreate
               jcs           :sec
               _open         eoutfileopen
               jcs           :sec
               lda           eoutfileopen
               sta           outread
               sta           outeofparm
:clc           plp
               clc
               rts
:sec           plp
               sec
               rts

buildexp       php
               rep           $30
               stz           expsize+2
               lda           numsegments             ;(numsegments*10)+2
               asl
               pha
               asl
               asl
               clc
               adc           1,s
               clc
               adc           #$02+6+4                ;2 for count, 5 for elconst rec+1 for end
               sta           expsize
               pla
               lda           #expseghdrlen
               clc
               adc           expsize
               sta           expsize
               bcc           :stz
               inc           expsize+2
:stz           stz           :ct
]lup           lda           :ct
               cmp           numsegments
               bge           :done
               asl
               asl
               asl
               asl
               asl
               tax
               lda           segdata+enamelen,x
               clc
               adc           #58+1
               clc
               adc           expsize
               sta           expsize
               bcc           :next
               inc           expsize+2
:next          inc           :ct
               bra           ]lup
:done
               psl           #$00
               psl           expsize
               lda           userid
               ora           #linkmemid
               pha
               pea           $8000
               psl           #$00
               _newhandle
               plx
               ply
               jcs           :errxit
               stx           exphdl
               sty           exphdl+2
               ldy           #$02
               lda           [exphdl]
               sta           expptr
               lda           [exphdl],y
               sta           expptr+2

               ldy           #$00
               lda           #$00
]lup           sta           [expptr],y
               iny
               iny
               cpy           expsize
               blt           ]lup

               do            0
               lda           expsize+2
               jsr           prbytel
               lda           expsize
               jsr           prbytel
               lda           #$0d
               jsr           drawchar
               fin

               pea           $00
               jmp           :xit
:errxit        rep           $30
               pha
:xit           rep           $30
               pla
               plp
               cmp           one
               rts
:ct            ds            2


writeexphdr    php
               rep           $30
               lda           exphdl
               ora           exphdl+2
               jeq           :badhdr

               lda           #expseghdrlen+6+5
               sta           :size
               stz           :size+2
               lda           numsegments
               asl
               asl
               asl
               clc
               adc           :size
               sta           :size
               lda           #$00
               adc           :size+2
               sta           :size+2
               lda           expptr
               clc
               adc           :size
               sta           zpage
               lda           expptr+2
               adc           :size+2
               sta           zpage+2
               stz           :size
]lup           lda           :size
               cmp           numsegments
               bge           :setwrite
               asl
               asl
               asl
               asl
               asl
               tax
               lda           segdata+oldsegnum,x
               dec
               asl
               tay
               lda           segdata+newsegnum,x
               sta           [zpage],y
               inc           :size
               bra           ]lup
:setwrite      lda           expsize
               sta           expbytecnt
               sec
               sbc           #expseghdrlen+6
               sta           expdsize
               sta           explength
               lda           expsize+2
               sta           expbytecnt+2
               sbc           #^expseghdrlen+6
               sta           expdsize+2
               sta           explength+2
               lda           numsegments
               sta           expnum

               ldy           #$00
               sep           $20
]lup           lda           expresshdr,y
               sta           [expptr],y
               iny
               cpy           #expseghdrlen+5+6
               blt           ]lup
               rep           $20


               stz           outeof
               stz           outeof+2
               _setmark      outeofparm
               jcs           :errxit
               lda           expsize
               sta           outrequest
               lda           expsize+2
               sta           outrequest+2
               lda           expptr
               sta           outbuffer
               lda           expptr+2
               sta           outbuffer+2
               _write        outread
               jcs           :errxit

               jmp           :noerr
:badhdr        pea           #invalidexphdr
               jmp           :xit
:noerr         pea           $00
               jmp           :xit
:errxit        rep           $30
               pha
:xit           rep           $30
               pla
               plp
               cmp           one
               rts
:size          ds            2


writesegments  php
               rep           $30
               lda           expsize
               sta           outeof
               lda           expsize+2
               sta           outeof+2
               _seteof       outeofparm
               bcs           :err
               _setmark      outeofparm
               bcs           :err

               lda           #expseghdrlen+6+5
               sta           expoffset
               stz           expoffset+2
               lda           expsize
               sta           filemark
               lda           expsize+2
               sta           filemark+2

               lda           numsegments
               asl
               pha
               asl
               asl
               clc
               adc           1,s
               sta           1,s
               pla                                   ;*10
               clc
               adc           expoffset
               sta           expoffset
               lda           #$00
               adc           expoffset+2
               sta           expoffset+2

               lda           #$02
               sta           remapseg
               jsr           winitsegs
               bcs           :err
               jsr           wcode1seg
               bcs           :err
               jsr           wdpsegs
               bcs           :err
               jsr           wscodesegs
               bcs           :err
               jsr           wstatics
               bcs           :err
               jsr           wdyncodesegs
               bcs           :err
               jsr           wdynsegs
               bcs           :err

               plp
               clc
               rts
:err           plp
               sec
               rts


wdpsegs
wstatics
wdyncodesegs
wdynsegs
               clc
               rts

winitsegs      php
               rep           $30
               stz           :ct
]lup           lda           :ct
               cmp           numsegments
               bge           :done
               asl
               asl
               asl
               asl
               asl
               tax
               stx           :offset
               lda           segdata+ekind,x
               bmi           :next                   ;it's dynamic
               bit           #$10                    ;init segment?
               beq           :next
               lda           segdata+processed,x
               bne           :next
               lda           segdata+oldsegnum,x
               jsr           processseg
               bcs           :err
               ldx           :offset
               lda           #$ffff
               sta           segdata+processed,x
               lda           remapseg
               sta           segdata+newsegnum,x
               inc           remapseg
:next          inc           :ct
               jmp           ]lup
:done          plp
               clc
               rts
:err           plp
               sec
               rts
:offset        ds            2
:ct            ds            2


wcode1seg      php
               rep           $30
               stz           :ct
]lup           lda           :ct
               cmp           numsegments
               bge           :done
               asl
               asl
               asl
               asl
               asl
               tax
               stx           :offset
               lda           segdata+ekind,x
               bmi           :next                   ;it's dynamic
               and           #$ff                    ;code segment?
               bne           :next
               lda           segdata+processed,x
               bne           :next
               lda           segdata+oldsegnum,x
               jsr           processseg
               bcs           :err
               ldx           :offset
               lda           #$ffff
               sta           segdata+processed,x
               lda           remapseg
               sta           segdata+newsegnum,x
               inc           remapseg
               jmp           :done
:next          inc           :ct
               jmp           ]lup
:done          plp
               clc
               rts
:err           plp
               sec
               rts
:offset        ds            2
:ct            ds            2

wscodesegs     php
               rep           $30
               stz           :ct
]lup           lda           :ct
               cmp           numsegments
               bge           :done
               asl
               asl
               asl
               asl
               asl
               tax
               stx           :offset
               lda           segdata+ekind,x
               bmi           :next                   ;it's dynamic
               and           #$ff                    ;code segment?
               bne           :next
               lda           segdata+processed,x
               bne           :next
               lda           segdata+oldsegnum,x
               jsr           processseg
               bcs           :err
               ldx           :offset
               lda           #$ffff
               sta           segdata+processed,x
               lda           remapseg
               sta           segdata+newsegnum,x
               inc           remapseg
:next          inc           :ct
               jmp           ]lup
:done          plp
               clc
               rts
:err           plp
               sec
               rts
:offset        ds            2
:ct            ds            2


processseg     php                                   ;enter with old segnum in A
               rep           $30
               sta           :segnum

               jsr           readseg
               jcs           :errxit

               stz           lcsize
               stz           lcsize+2
               stz           relocsize
               stz           relocsize+2

               lda           segdataptr
               sta           zpage
               lda           segdataptr+2
               sta           zpage+2
]lup           lda           [zpage]
               and           #$ff
               cmp           #$00
               jeq           :next
               cmp           #$f1
               jeq           :ds
               cmp           #$f2
               jeq           :elconst
               cmp           #$f5
               jeq           :creloc
               cmp           #$f6
               jeq           :cinterseg
               cmp           #$f7
               jeq           :super
               cmp           #$e2
               jeq           :reloc
               cmp           #$e3
               jeq           :interseg
               lda           #badomfrec
               jmp           :errxit
:next          lda           :segnum
               dec
               asl
               asl
               asl
               asl
               asl
               tax
               stx           :xoffset
               inc           relocsize
               bne           :n1
               inc           relocsize+2
:n1            lda           relocsize
               sta           segdata+srelocsize,x
               lda           relocsize+2
               sta           segdata+srelocsize+2,x
               lda           lcsize
               clc
               adc           #$05
               sta           lcsize
               sta           segdata+slcsize,x
               lda           lcsize+2
               adc           #$00
               sta           lcsize+2
               sta           segdata+slcsize+2,x
               jmp           :final

:ds            ldy           #$01
               lda           [zpage],y
               clc
               adc           lcsize
               sta           lcsize
               ldy           #$03
               lda           [zpage],y
               adc           lcsize+2
               sta           lcsize+2
               lda           #$05
               jmp           :addlc
:elconst       ldy           #$01
               lda           [zpage],y
               clc
               adc           lcsize
               sta           lcsize
               ldy           #$03
               lda           [zpage],y
               adc           lcsize+2
               sta           lcsize+2
               ldy           #$01
               lda           [zpage],y
               clc
               adc           zpage
               tax
               ldy           #$03
               lda           [zpage],y
               adc           zpage+2
               sta           zpage+2
               stx           zpage
               lda           #$05
               jmp           :addlc
:super         ldy           #$01
               lda           [zpage],y
               clc
               adc           relocsize
               sta           relocsize
               ldy           #$03
               lda           [zpage],y
               adc           relocsize+2
               sta           relocsize+2
               ldy           #$01
               lda           [zpage],y
               clc
               adc           zpage
               tax
               ldy           #$03
               lda           [zpage],y
               adc           zpage+2
               sta           zpage+2
               stx           zpage
               lda           #$05
               jmp           :addreloc

:reloc         lda           #11
               jmp           :addreloc
:interseg      lda           #15
               jmp           :addreloc
:creloc        lda           #7
               jmp           :addreloc
:cinterseg     lda           #8
               jmp           :addreloc
:addlc         clc
               adc           zpage
               sta           zpage
               lda           #$00
               adc           zpage+2
               sta           zpage+2
               jmp           ]lup
:addreloc      pha
               clc
               adc           zpage
               sta           zpage
               lda           #$00
               adc           zpage+2
               sta           zpage+2
               pla
               clc
               adc           relocsize
               sta           relocsize
               lda           #$00
               adc           relocsize+2
               sta           relocsize+2
               jmp           ]lup

:final         rep           $30
               lda           remapseg
               dec
               dec                                   ;this starts at 2
               asl
               asl
               asl
               clc
               adc           #$06+expseghdrlen+5
               tay
               sty           :where
               lda           expoffset
               sec
               sbc           :where
               sta           [expptr],y

               lda           expptr
               clc
               adc           expoffset
               sta           zpage
               lda           expptr+2
               adc           expoffset+2
               sta           zpage+2
               ldy           #$02
               ldx           :xoffset
               lda           segdata+headerlen,x
               clc
               adc           filemark
               sta           [zpage]
               lda           #$00
               adc           filemark+2
               sta           [zpage],y
               ldy           #$04
               lda           lcsize
               sta           [zpage],y
               ldy           #$06
               lda           lcsize+2
               sta           [zpage],y
               ldy           #$02
               lda           [zpage]
               clc
               adc           lcsize
               sta           :temp
               lda           [zpage],y
               adc           lcsize+2
               sta           :temp+2
               ldy           #$08
               lda           :temp
               sta           [zpage],y
               ldy           #$0a
               lda           :temp+2
               sta           [zpage],y
               ldy           #$0c
               lda           relocsize
               sta           [zpage],y
               ldy           #$0e
               lda           relocsize+2
               sta           [zpage],y

               ldy           #$22
               lda           remapseg
               sta           [seghdrptr],y

               ldx           #$0c
               ldy           #$10
               sep           $20
]lup           phy
               txy
               lda           [seghdrptr],y
               ply
               sta           [zpage],y
               inx
               iny
               cpx           #32+$c
               blt           ]lup
               ldx           :xoffset
               lda           segdata+enamelen
               ldy           #$3a
               sta           [zpage],y
               rep           $20
               and           #$ff
               sta           :enamelen
               ldy           #$28
               lda           [seghdrptr],y
               clc
               adc           #10
               tax
               ldy           #$3b
               sep           $20
]lup           phy
               txy
               lda           [seghdrptr],y
               ply
               sta           [zpage],y
               iny
               inx
               dec           :enamelen
               bne           ]lup
               rep           $20
               tya
               clc
               adc           expoffset
               sta           expoffset
               lda           #$00
               adc           expoffset+2
               sta           expoffset+2
               ldx           :xoffset
               lda           segdata+headerlen,x
               clc
               adc           filemark
               sta           filemark
               lda           #$00
               adc           filemark+2
               sta           filemark+2
               lda           lcsize
               clc
               adc           filemark
               sta           filemark
               lda           lcsize+2
               adc           filemark+2
               sta           filemark+2
               lda           relocsize
               clc
               adc           filemark
               sta           filemark
               lda           relocsize+2
               adc           filemark+2
               sta           filemark+2
               jsr           writeseg
               jcs           :errxit
:noerr         pea           $00
               jmp           :xit
:errxit        rep           $30
               pha
:xit           rep           $30
               pla
               plp
               cmp           one
               rts
:temp          ds            4
:xoffset       ds            2
:enamelen      ds            2,0
:segnum        ds            2
:where         ds            2

writeseg       php
               rep           $30
               psl           #$00
               psl           seghdrhdl
               _gethandlesize
               pll           outrequest
               lda           seghdrptr
               sta           outbuffer
               lda           seghdrptr+2
               sta           outbuffer+2
               _write        outread
               jcs           :err
               psl           #$00
               psl           segdatahdl
               _gethandlesize
               pll           outrequest
               lda           segdataptr
               sta           outbuffer
               lda           segdataptr+2
               sta           outbuffer+2
               _write        outread
               jcs           :err
               plp
               clc
               rts
:err           plp
               sec
               rts

readseg        php
               rep           $30
               sta           :segnum
               cmp           #$00
               jeq           :badseg
               dec
               cmp           numsegments
               jge           :badseg
               asl
               asl
               asl
               asl
               asl
               tax
               stx           :offset
               lda           segdata+fileoffset,x
               sta           ineof
               lda           segdata+fileoffset+2,x
               sta           ineof+2
               _setmark      ineofparm
               jcs           :errxit
               lda           seghdrhdl
               ora           seghdrhdl+2
               bne           :resize
               psl           #$00
               psl           #$01
               lda           userid
               ora           #linkmemid
               pha
               pea           $0000
               psl           #$00
               _newhandle
               plx
               ply
               jcs           :errxit
               stx           seghdrhdl
               sty           seghdrhdl+2
:resize        psl           seghdrhdl
               _Hunlock
               ldx           :offset
               pea           $00
               lda           segdata+headerlen,x
               pha
               psl           seghdrhdl
               _sethandlesize
               php
               pha
               psl           seghdrhdl
               _Hlock
               pla
               plp
               jcs           :errxit
               ldy           #$02
               lda           [seghdrhdl]
               sta           seghdrptr
               lda           [seghdrhdl],y
               sta           seghdrptr+2

               lda           seghdrptr
               sta           inbuffer
               lda           seghdrptr+2
               sta           inbuffer+2
               ldx           :offset
               lda           segdata+headerlen,x
               sta           inrequest
               stz           inrequest+2
               _read         inread
               jcs           :errxit

               lda           segdatahdl
               ora           segdatahdl+2
               bne           :resize1

               psl           #$00
               psl           #$01
               lda           userid
               ora           #linkmemid
               pha
               pea           $0000
               psl           #$00
               _newhandle
               plx
               ply
               jcs           :errxit
               stx           segdatahdl
               sty           segdatahdl+2
:resize1       psl           segdatahdl
               _Hunlock
               ldx           :offset
               ldy           #$02
               lda           [seghdrptr]             ;get bytecnt
               sec
               sbc           segdata+headerlen,x
               sta           inrequest
               lda           [seghdrptr],y
               sbc           #$00
               sta           inrequest+2
               pha
               lda           inrequest
               pha
               psl           segdatahdl
               _sethandlesize
               php
               pha
               psl           segdatahdl
               _Hlock
               pla
               plp
               jcs           :errxit
               ldy           #$02
               lda           [segdatahdl]
               sta           segdataptr
               lda           [segdatahdl],y
               sta           segdataptr+2

               lda           segdataptr
               sta           inbuffer
               lda           segdataptr+2
               sta           inbuffer+2
               _read         inread
               jcs           :errxit
               lda           :segnum
               sta           currentseg
               jmp           :noerr
:badseg        pea           #badsegnum
               jmp           :xit
:noerr         pea           $00
               jmp           :xit
:errxit        rep           $30
               pha
:xit           rep           $30
               pla
               plp
               cmp           one
               rts
:offset        ds            2
:segnum        ds            2

readfile       php
               rep           $30
:next          lda           numsegments
               cmp           #emaxsegments
               blt           :read
               lda           #toomanysegs
               jmp           :errxit
:read          _getmark      ineofparm
               jcs           :errxit
               lda           ineof
               sta           :offset
               lda           ineof+2
               sta           :offset+2
               lda           #:buffer
               sta           inbuffer
               lda           #^:buffer
               sta           inbuffer+2
               lda           #44
               sta           inrequest
               stz           inrequest+2
               _read         inread
               bcc           :setup
               cmp           #$4c
               jeq           :noerr
               jmp           :errxit
:setup         lda           intransfer
               cmp           #44
               jne           :notomf
               lda           intransfer+2
               jne           :notomf
               lda           :buffer+$F
               and           #$ff
               cmp           #$02
               jlt           :notver2

               lda           #:namebuff
               sta           inbuffer
               lda           #^:namebuff
               sta           inbuffer+2


               lda           :buffer+$2a
               sec
               sbc           #44
               sta           inrequest
               stz           inrequest+2
               _read         inread
               jcs           :errxit

               lda           :buffer+$2a             ;offset to data
               sec
               sbc           :buffer+$28             ;- offset to names
               sec
               sbc           #10                     ;-10 (for load name field) = esegname length
               sta           :len
               lda           :buffer+$28
               sec
               sbc           #34
               tax
               ldy           #$00
               lda           :express
               and           #$ff
               sta           :len1
               sep           $20
               cmp           :len
               beq           :cmp
               bge           :rep
:cmp
]lup           lda           :namebuff,x
               and           #$7f
               cmp           #'a'
               blt           :chk
               cmp           #'z'+1
               bge           :chk
               and           #$5f
:chk           cmp           :express+1,y
               bne           :rep
               iny
               inx
               cpy           :len1
               blt           ]lup
               rep           $30
               lda           #alreadyexpressed
               jmp           :errxit

:rep           rep           $30
               lda           numsegments
               asl
               asl
               asl
               asl
               asl
               tax
               lda           :buffer+$14             ;get kind
               sta           segdata+ekind,x
               lda           :offset
               sta           segdata+fileoffset,x
               lda           :offset+2
               sta           segdata+fileoffset+2,x
               lda           :buffer+$22
               sta           segdata+oldsegnum,x
               lda           :buffer+$2a
               sta           segdata+headerlen,x

               lda           :buffer+$2a             ;offset to data
               sec
               sbc           :buffer+$28             ;- offset to names
               sec
               sbc           #10                     ;-10 (for load name field) = esegname length
               sta           segdata+enamelen,x

               stz           segdata+processed,x

               lda           :buffer
               clc
               adc           :offset
               sta           ineof
               lda           :buffer+2
               adc           :offset+2
               sta           ineof+2
               inc           numsegments
               _setmark      ineofparm
               jcc           :next
               cmp           #$4d                    ;mark past eof
               beq           :noerr
               jmp           :errxit
:noerr         pea           #$00
               jmp           :xit
:notver2       pea           #notomf2
               jmp           :xit
:notomf        pea           #notomf
               jmp           :xit
:errxit        rep           $30
               pha
:xit           rep           $30
               pla
               plp
               cmp           one
               rts
:offset        ds            4
:len           ds            2
:len1          ds            2
:express       str           'EXPRESSLOAD'
:buffer        ds            44,0
:namebuff      ds            100,0

random         php                                   ;save environment
               phb
               phk
               plb
               rep           %00111001
               ldx           indexi
               ldy           indexj
               lda           array-2,x
               adc           array-2,y
               sta           array-2,x
               dex
               dex
               bne           :dy
               ldx           #17*2                   ;cycle index if at end of
:dy            dey                                   ; the array
               dey
               bne           :setix
               ldy           #17*2
:setix         stx           indexi
               sty           indexj
               plb
               plp
               rts

indexi         da            17*2                    ;the relative positions of
indexj         da            5*2                     ; these indexes is crucial

array          da            1,1,2,3,5,8,13,21,54,75,129,204
               da            323,527,850,1377,2227

               err           *-array-34

seed           php
               rep           %00110000
seed2          phb
               phk
               plb
               pha
               ora           #1                      ;at least one must be odd
               sta           array
               stx           array+2
               phx                                   ;push index regs on stack
               phy
               ldx           #30
]lup           sta           array+2,x
               dex
               dex
               lda           1,s                     ;was y
               sta           array+2,x
               dex
               dex
               lda           3,s                     ;was x
               sta           array+2,x
               lda           5,s                     ;original a
               dex
               dex
               bne           ]lup
               lda           #17*2
               sta           indexi                  ;init proper indexes
               lda           #5*2                    ; into array
               sta           indexj
               jsr           random                  ;warm the generator up.
               jsr           random
               ply                                   ;replace all registers
               plx
               pla
               plb
               plp
               rts

randomize      php
               rep           %00110000
               lda           #0
               pha
               pha
               pha
               pha
               ldx           #$D03                   ;readtimehex
               jsl           $E10000
               pla
               plx
               ply
               sta           1,s                     ;trick to pull last word
               pla                                   ; fm stack without ruining
               bra           seed2                   ; the previous ones.


print          php
               rep           $30
               lda           numsegments
               jsr           prbytel
               lda           #$0d
               jsr           drawchar
               stz           :ct
]lup           lda           :ct
               cmp           numsegments
               bge           :end
               asl
               asl
               asl
               asl
               asl
               sta           :offset
               tax
               lda           segdata+oldsegnum,x
               jsr           prbytel
               lda           #$20
               jsr           drawchar
               ldx           :offset
               lda           segdata+ekind,x
               jsr           prbytel
               lda           #$20
               jsr           drawchar
               ldx           :offset
               lda           segdata+headerlen,x
               jsr           prbytel

               lda           #$20
               jsr           drawchar
               ldx           :offset
               lda           segdata+enamelen,x
               jsr           prbytel


               lda           #$20
               jsr           drawchar
               ldx           :offset
               lda           segdata+slcsize+2,x
               jsr           prbytel
               ldx           :offset
               lda           segdata+slcsize,x
               jsr           prbytel

               lda           #$20
               jsr           drawchar
               ldx           :offset
               lda           segdata+srelocsize+2,x
               jsr           prbytel
               ldx           :offset
               lda           segdata+srelocsize,x
               jsr           prbytel

               lda           #$0d
               jsr           drawchar
               inc           :ct
               jmp           ]lup

:end           plp
               rts
:offset        ds            2
:ct            ds            2

tempname       str           'expresstemp0000'

infileopen     ds            2
               adrl          filename
               adrl          $00

eoutfileopen   ds            2
               adrl          tempname
               adrl          $00

outread        dw            0
outbuffer      ds            4
outrequest     ds            4
outtransfer    ds            4
inread         dw            0
inbuffer       ds            4
inrequest      ds            4
intransfer     ds            4
outeofparm     ds            2
outeof         ds            4
ineofparm      ds            2
ineof          ds            4
ininfo         adrl          filename
               ds            2
intype         ds            2
               ds            18,0
outcreate      adrl          tempname
               dw            $e3
               dw            $B3                     ;general OMF type
               adrl          $00
               dw            $01
               adrl          $00
               adrl          $00

renameparm
outdelete      adrl          tempname
indelete       adrl          filename

segdata        ds            32*emaxsegments

****

button         pha
               php
               sep           $20
:1             ldal          $e0c010
               ldal          $e0c062
               bpl           :1
               plp
               pla
               rts

expresshdr
expbytecnt     ds            4
               adrl          $00
explength      ds            4
               dfb           0
               dfb           elconst-esegname        ;label length
               dfb           4                       ;numlen
expversion     dfb           2                       ;version
               adrl          $10000                  ;bank size
               dw            $8001                   ;kind field
               dw            0
               adrl          $00                     ;org
               adrl          $00                     ;align
               dfb           0                       ;numsex
               dfb           0                       ;revision
expsegnum      dw            $01                     ;always seg #1
               adrl          $00                     ;entry
               dw            eloadname-expresshdr    ;disp to names
               dw            elconst-expresshdr      ;disp to data
eloadname      asc           'QuickXPRES'
esegname       asc           'ExpressLoad'
expseghdrlen   equ           *-expresshdr
elconst        hex           f2
expdsize       ds            4
               ds            4,0                     ;reserved
expnum         ds            2,0

one            dw            $01

