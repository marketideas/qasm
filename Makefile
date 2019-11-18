export USE_CLANG=1

ifeq ($(USE_CLANG),1)
export CXX=/usr/bin/clang++
export CC=/usr/bin/clang
else
export CXX=g++
export CC=gcc
endif

V?=
S=
ifneq ("$V","")
S="VERBOSE=1"
else
.SILENT:
endif

all:
	-mkdir -p ./build
	-cd ./build && cmake -DCMAKE_BUILD_TYPE=DEBUG .. && $(MAKE) $S

release:
	-rm -rf ./build
	-mkdir -p ./build
	-cd ./build && cmake -DCMAKE_BUILD_TYPE=RELEASE .. && $(MAKE) $S

debug:
	-rm -rf ./build
	-mkdir -p ./build
	-cd ./build && cmake -DCMAKE_BUILD_TYPE=DEBUG .. && $(MAKE) $S


distclean:
	rm -rf ./build 
	-rm -rf ./testout

clean:
	-rm -rf ./build
	-rm -rf ./testout

depend:
	-cd ./build && $(MAKE) depend

rebuild:
	-cd ./build && $(MAKE) rebuild_cache

run:
	-cd ./build && $(MAKE) run

install:
	-cd ./build && cmake -P cmake_install.cmake

reformat:
	qasm -x REFORMAT  src/main.s
	
compare:
	-bcompare . ../lane_hex &

asm:
	
test1:
	-qasm src/main.s

test2:
	-qasm src/testfile.s

test3:
	-qasm src/var.s
	
	

	



