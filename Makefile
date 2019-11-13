#export CC=/usr/bin/clang
#export CXX=/usr/bin/clang++


V?=
S=
ifneq ("$V","")
S="VERBOSE=1"
else
.SILENT:
endif

all:
	-mkdir -p ./build
	-cd ./build && cmake .. && $(MAKE) $S

distclean:
	rm -rf ./build 

clean:
	-rm -rf ./build

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
	
asm:
	
test1:
	-qasm src/main.s

test2:
	-qasm src/testfile.s
	
	

	



