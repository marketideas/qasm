#!/bin/bash

OUTDIR=./testout
TMPFILE=/tmp/qasm_out.txt

rm -f $TMPFILE
rm -rf $OUTDIR
mkdir -p $OUTDIR

SRC=`ls ./testdata | grep -E '^[0-9]+'`


for S in $SRC ; do

	rm -f $TMPFILE

	S1=$S
	S1=${S1/.S/.bin}
	S1=${S1/.s/.bin}

	./qasm -o 0/$OUTDIR/$S1 ./testdata/$S >> $TMPFILE

	R=?$
	#echo $S " " $S1
	R=`cat $TMPFILE | grep "End qASM assembly"`
	E=`echo $R | awk -e '{ print $6; }'`
	ect=`echo $(($E))`
	P="FAIL:"
	#echo "$S Errors: $ect"
	if [ $ect = 0 ] ; then
		P="PASS:"
	fi
	echo "$P $S"

done
ls -l $OUTDIR



