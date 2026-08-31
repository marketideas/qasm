CXX ?= g++
CXXFLAGS ?= -std=c++17 -Wall -Wextra -O2 -g
LDFLAGS ?= -pthread

LIB_SRC = src/util.cpp src/parse.cpp src/expr.cpp src/opcode.cpp src/assemble.cpp
LIB_OBJ = $(LIB_SRC:.cpp=.o)

.PHONY: all test clean

all: merlin

merlin: $(LIB_OBJ) src/main.o
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS)

test_merlin: $(LIB_OBJ) test/test_merlin.o
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS)

src/%.o: src/%.cpp src/merlin.hpp src/intern.hpp
	$(CXX) $(CXXFLAGS) -c -o $@ $<

test/test_merlin.o: test/test_merlin.cpp src/merlin.hpp
	$(CXX) $(CXXFLAGS) -Isrc -c -o $@ $<

test: merlin test_merlin
	./test_merlin
	./merlin test/fixtures/hello.s test/test.s

clean:
	rm -f merlin test_merlin src/*.o test/*.o
	rm -f test/fixtures/hello.bin test/fixtures/hello.lst
	rm -f test/test.bin test/test.lst
