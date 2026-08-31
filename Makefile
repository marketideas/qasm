CC ?= cc
CFLAGS ?= -std=c11 -Wall -Wextra -O2 -g
LDFLAGS ?=

LIB_SRC = src/util.c src/parse.c src/expr.c src/opcode.c src/assemble.c
LIB_OBJ = $(LIB_SRC:.c=.o)

.PHONY: all test clean

all: merlin

merlin: $(LIB_OBJ) src/main.o
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

test_merlin: $(LIB_OBJ) test/test_merlin.o
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

src/%.o: src/%.c src/merlin.h
	$(CC) $(CFLAGS) -c -o $@ $<

test/test_merlin.o: test/test_merlin.c src/merlin.h
	$(CC) $(CFLAGS) -Isrc -c -o $@ $<

test: merlin test_merlin
	./test_merlin
	./merlin -o /tmp/hello.bin test/fixtures/hello.s

clean:
	rm -f merlin test_merlin src/*.o test/*.o
