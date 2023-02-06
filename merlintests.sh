#!/bin/bash

X=
if [ "$1""L" != "L" ] ; then
	X=_$1
fi

OUTDIR=./m32out

rm -rf $OUTDIR
mkdir -p $OUTDIR

SRC=`ls ./testdata | grep -E '^([0-9]+)(.*)\.[Ss]'`

#SRC=`ls ./testdata | grep -E '^([0-9]+)(.*)\.[Ss]' | grep -i 2007`

for S in $SRC ; do

	echo "merlin32 $S"
	S1=$S
	S1=${S1/.S/}
	S1=${S1/.s/}

	cd ./testdata
	#merlin32$X . $S 2>/dev/null >/dev/null
	merlin32$X -V . $S 

	#merlin32 . $S 2>/dev/null 

	R=?$
	cd .. >/dev/null
	mv ./testdata/$S1 $OUTDIR/$S1.bin 2>/dev/null
	rm -f ./testdata/*.txt 2>/dev/null
	R=?$

done
ls $OUTDIR



