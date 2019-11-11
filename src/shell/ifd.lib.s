 lst off
 tr on
 exp off
 mx %00
 cas se

 rel ;creating a LNK library

*======================================================
* Control file needed in order to assemble the IFD Libraries
* Design and programming by Lane Roath
* Copyright (c) 1989 Lane Roath & Ideas From the Deep
*------------------------------------------------------
* 25-Oct-89 1.00 :finish first version & text it out
*======================================================

Class1 = $2000

 use ifd.equs
 use 3/ifdlib/macs

 EXT QuickASM

 jmp QuickASM

 ENT ON

 put 3/ifdlib/disk
 put 3/ifdlib/draw
 put 3/ifdlib/misc

 ENT OFF

 sav 2/obj/ifd.lib
