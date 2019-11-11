export CC=/usr/bin/clang
export CXX=/usr/bin/clang++


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
	rm -rf build app/build sgqlib/build

clean:
	-cd ./build && $(MAKE) clean

depend:
	-cd ./build && $(MAKE) depend

rebuild:
	-cd ./build && $(MAKE) rebuild_cache

lib:
	-cd ./build && $(MAKE) sgq

run:
	-cd ./build && $(MAKE) run

install:
	-cd ./build && cmake -P cmake_install.cmake

asm:
	qasm src/testfile.s
	#cd src/asm && ../qasm main.s
	
	

	



