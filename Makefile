export USE_CLANG=0

ifeq ($(USE_CLANG),1)
export CXX=/usr/bin/clang++
export CC=/usr/bin/clang
else
export CXX=g++
export CC=gcc
endif

V?=
export S=
ifneq ("$V","")
export S="VERBOSE=1"
else
.SILENT:
endif

all:
	-mkdir -p ./build
	-cd ./build && $(MAKE) $S

release:
	-rm -rf ./build
	-mkdir -p ./build
	-cd ./build && cmake -DCMAKE_BUILD_TYPE=RELEASE .. && $(MAKE) $S

debug:
	-rm -rf ./build
	-mkdir -p ./build
	-cd ./build && cmake -DCMAKE_BUILD_TYPE=DEBUG .. && $(MAKE) $S

cider:
	-rm -rf ./build
	-mkdir -p ./build
	-cd ./build && cmake -DCIDER=1 -DCMAKE_BUILD_TYPE=DEBUG .. && $(MAKE) $S

distclean: clean
	-rm -rf ./qasmout
	-rm -rf ./m32out
	-rm -rf ./libhfs/build ./nufxlib/build ./diskimg/build ./libpal/build

clean:
	-rm -rf ./build *.2mg test.bin *_Output.txt _FileInforma*.txt testdata/*.bin testdata/Finder.Data
	-rm -rf ./log_qasm ./testdata1 test 

depend:
	-cd ./build && $(MAKE) depend

rebuild:
	-cd ./build && $(MAKE) rebuild_cache

run:
	-cd ./build && $(MAKE) run

install:
	-cd ./build && cmake -P cmake_install.cmake

reformat:
	qasm -x REFORMAT  test.s

asm:

tests:
	-rm -rf ./m32out/* ./qasmout/*
	merlintests.sh
	runtests.sh


test1:
	-qasm testdata/3001-runfile.S

test2:
	-qasm testdata/3002-testfile.S

test3:
	-qasm testdata/3003-var.S
	
gsplus:
	daemon -- /usr/bin/xterm -e "cd /mnt/nas/gsplus && ./gsplus"

	



