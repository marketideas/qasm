*======================================================
* Link file for the IFD TEdit word processor
* Written by Lane Roath
* Copyright (c) 1989 Ideas from the Deep
*======================================================

 lkv $01 ;xtra linker, OMF 2
 ver $02

 FAS

 if equs

 asm qasm2
 asm qasm1
 asm qasm

 fin

 do err
 else

 CMD p,s,q

 lnk 2/obj/ifd.lib
 lnk 2/obj/qasm2.l
 lnk 2/obj/qasm1.l
 lnk 2/obj/qasm.l

 ds 1024 ;buffer space

 typ S16
 sav 2/QASM

 fin
