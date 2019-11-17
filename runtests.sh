#!/bin/bash

OUTDIR=./testout
TMPFILE=/tmp/qasm_out.txt

rm -f $TMPFILE
rm -rf $OUTDIR
mkdir -p $OUTDIR

SRC=`ls ./testdata`


for S in $SRC ; do

	rm -f $TMPFILE
	./qasm -o 0/$OUTDIR/$S ./testdata/$S >> $TMPFILE

	R=?$
	echo $S
	cat $TMPFILE | grep "End qASM assembly"

done
ls -l $OUTDIR



