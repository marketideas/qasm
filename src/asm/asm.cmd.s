* ovr all
                  ;use   ../macs/tool.macs.s
                  ;use   ../macs/qatools.macs.s
                  ;use   ../macs/toolmacs.s

            put   asm.vars
            put   asm.1
            put   asm.eval
            put   asm.cond
            put   asm.opcodes
            put   asm.dsk
            put   asm.errors
            put   ../data/opdata
            asm   asm.header

            lnk   ../utility/qasmgs.l
            typ   exe
            sav   ../utility/qasmgs
mylable     equ   $1234
            ent

