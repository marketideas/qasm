            lst   off

*** LEAVE THIS WORD ALONE *****

setup       dw    %1000_0000_0000_0000
                              ;b15:	1 = graphics
                              ;	0 = text


**** YOU MAY CHANGE THESE PFX'S ****

prefixtbl
:pfx0       str   ''
            ds    64-{*-:pfx0}
:pfx1       str   '0/'
            ds    64-{*-:pfx1}
:pfx2       str   '0/Library'
            ds    64-{*-:pfx2}
:pfx3       str   '/a/work/'
            ds    64-{*-:pfx3}
:pfx4       str   '/a/Merlin/Macs'
            ds    64-{*-:pfx4}
:pfx5       str   '9/'
            ds    64-{*-:pfx5}
:pfx6       str   '9/Utility'
            ds    64-{*-:pfx6}
:pfx7       str   '9/QASystem/Help.Files'
            ds    64-{*-:pfx7}

            typ   $06
            sav   qaprefs

