#!/bin/bash

export NEWDIR=../testdata1/QASMOUT
rm -rf $NEWDIR
mkdir -p $NEWDIR
mkdir -p $NEWDIR/ASM
mkdir -p $NEWDIR/LINK
mkdir -p $NEWDIR/INTCMD
mkdir -p $NEWDIR/MACS
mkdir -p $NEWDIR/TOOLS
mkdir -p $NEWDIR/EDIT
mkdir -p $NEWDIR/SHELL
mkdir -p $NEWDIR/MACROS
mkdir -p $NEWDIR/EXE
mkdir -p $NEWDIR/QASYSTEM
mkdir -p $NEWDIR/DATA



X=`find . -name "*.s"`
for F in $X ; do
	export UP=`echo $F | tr '[:lower:]' '[:upper:]'`
	UP=${NEWDIR}/${UP}
	#echo $F $UP
	#qasm -x format-merlin $F
	qasm -x format-merlin ${F} >${UP}
done