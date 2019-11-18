#!/bin/bash

OUTDIR=./testout
TMPFILE=/tmp/qasm_out.txt

rm -f $TMPFILE
rm -rf $OUTDIR
mkdir -p $OUTDIR

SRC=`ls ./testdata`


for S in $SRC ; do

	rm -f $TMPFILE

	S1=$S
	S1=${S1/.S/.bin}
	S1=${S1/.s/.bin}

	./qasm -o 0/$OUTDIR/$S1 ./testdata/$S >> $TMPFILE

	R=?$
	echo $S " " $S1
	cat $TMPFILE | grep "End qASM assembly"

done
ls -l $OUTDIR



