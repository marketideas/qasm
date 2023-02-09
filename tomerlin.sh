#!/bin/bash
mkdir -p ./testdata1
rm -rf ./testdata1/*
cp -r ./testdata/*.S testdata1/
cp ./merlintest.s ./testdata1/merlintest.S
cd ./testdata1
X=`ls *.S`

for F in $X ; do
    UFNAME=`echo $F | tr '[:lower:]' '[:upper:]'`
	qasm -x format-merlin $F >${UFNAME}
	rm -rf $F
done
ls 
