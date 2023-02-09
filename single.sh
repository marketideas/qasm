#!/bin/bash

FNAME=2007-labels-and-symbols
if [ "$1""L" != "L" ] ; then
  FNAME=$1
fi

cp testdata/$FNAME.S /tmp

cd /tmp
OUTNAME=/tmp/compare.txt
merlin32 -V ${FNAME}.S >/dev/null
cat ${FNAME}_Output.txt >OUTNAME
cat ${FNAME}_Output.txt

qasm ${FNAME}.S -t merlin32 -i M65816 -o 0/${FNAME}.S.bin
qasm ${FNAME}.S -t qasm -i M65816 -o 0/${FNAME}.S_q.bin

vbindiff ${FNAME} ${FNAME}.S.bin
