#!/bin/bash

OUTDIR=./qasmout
TMPFILE=/tmp/qasm_out.txt

rm -f $TMPFILE
rm -rf $OUTDIR
rm -rf ./testdata/*.bin

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

	BASE=${S/.S/}
	BASE=${BASE/.s/}
	#./qasm -o 0/$OUTDIR/$S1 ./testdata/$S 

	X="./qasm -q -c -t merlin32 -i M65816 -o 0/$OUTDIR/$S1 ./testdata/$S"

	$X >$TMPFILE
	#echo $X

	R=?$
	#echo $S " " $S1
	#cat $TMPFILE
	R=`cat $TMPFILE | grep "End qASM assembly"`
	E=`echo $R | awk -e '{ print $6; }'`
	ect=`echo $(($E))`

	MSHA="Q"
	QSHA="M"


	if [ -f ./m32out/$BASE.bin ] ; then
	  MSHA=`sha256sum ./m32out/$BASE.bin | awk '{ print $1;}'` 2>/dev/null >/dev/null
    fi

    if [ -f $OUTDIR/$BASE.bin ] ; then
	   QSHA=`sha256sum $OUTDIR/$BASE.bin |awk '{print $1;}'` 2>/dev/null >/dev/null
    fi
    #echo "MSHA=$MSHA    QSHA=$QSHA"

	shapass=0;
	CX=" "

	if [ "$MSHA""L" != "$QSHA""L" ] ; then
		shapass=1
		CX="!"
	fi

	P="PASS:          "
	TOTAL=$(($TOTAL+1))
	pct=$(($ect+$shapass))
	if [ $pct != 0  ] ; then
		printf 'FAIL: (%3s) ' $ect
		printf '%s  ' $CX
		echo " $S"

		FAILCT=$(($FAILCT+1))
		#cat $TMPFILE
		#echo $X
		#exit 255
	else
		printf "PASS:          "
	fi
	echo " $S"
done
echo "Total: $TOTAL  Fail: $FAILCT"



