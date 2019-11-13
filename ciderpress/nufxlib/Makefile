.SILENT:
export CC=gcc
export CXX=g++

.PHONY: clean

all: nufx

nufx:
	-mkdir -p ./build
	cd ./build && cmake ..
	cd ./build && $(MAKE)

clean:
	-rm -rf ./build
