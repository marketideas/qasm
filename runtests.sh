#!/bin/bash

OUTDIR=./testout
TMPFILE=/tmp/qasm_out.txt

rm -f $TMPFILE
rm -rf $OUTDIR
mkdir -p $OUTDIR

SRC=`ls ./testdata | grep -E '^([0-9]+)(.*)\.[Ss]'`

#for S in $SRC ; do
#	echo $S
#done
#exit

TOTAL=0
FAILCT=0

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
	P="PASS:          "
	TOTAL=$(($TOTAL+1))
	if [ $ect != 0 ] ; then
		printf 'FAIL: (%3s)    ' $ect

		FAILCT=$(($FAILCT+1))
	else
		printf "PASS:          "
	fi
	echo " $S"
done
echo "Total: $TOTAL  Fail: $FAILCT"



