# QuickAsm

QuickAsm (`qasm`) is a host-side Merlin 16+ cross-assembler for the 65816,
and for the 6502 and 65C02 through `XC`. The language is Glen Bredon’s
Merlin 16+ (Roger Wagner Publishing, 1988–89), as documented in the 8/16
user’s manual and the 16+ supplementary.

Edit source on the host, assemble it with `qasm`, and run the object on a
IIgs, an emulator, or the sibling `m65816` FPGA core.

Each source file is identified, lowered to one 65816 pcode stream, and
assembled in two passes. The object is an absolute binary. Merlin 16+ is
the language the encoder consumes. Merlin 32, ORCA/M, LISA, and ca65 are
lowered to that form. Identification, pseudo-op rewriting, and the limits
of that lowering are in `doc/SYNTAX.md`. The Merlin 16+ language contract
is `doc/DIALECT.md`.

Startup matches Merlin 16+ on a IIgs: 65816 opcodes, `MX %11` (M and X both
8-bit), case-insensitive labels, program counter `$8000`, and filetype `$06`
(BIN). Put explicit `MX` and `XC` at the top of a source so it matches a
real 16+ assembly. `TYP` changes the type printed with the object. The
bytes stay a raw image.

Native Merlin disk files are accepted as-is (bit 7 set, `$A0` column tabs,
`$8D` line endings). Host `.s` files with spaces, tabs, and LF work too.

Labels of 26 characters or fewer, lines of 255 characters or fewer, a macro
nest of 15, and a condition nest of 8 stay inside the Merlin 16+ limits for
a source that will also assemble on a real 16+.

Absolute BIN is the object. Relocatable OMF and Linker.GS are unimplemented.
Under `REL`, an unknown label is 0 and the object is still the raw image.

## Build

C++17. CMake is the build. The Makefile configures `build/` when
`CMakeLists.txt` is newer than the cache, then builds the requested target.
Binaries are `build/qasm` and `build/test_qasm`.

```
make
make test
make fixtures
./build/qasm test/fixtures/hello.s
./build/qasm a.s b.s c.s
```

`make` builds `qasm`. Several source files on one command line assemble in
parallel. `make test` runs the unit tests, assembles `test/fixtures/hello.s`
and `test/test.s`, assembles the five coverage fixtures, and requires those
five objects to be byte-identical. `make fixtures` assembles and compares
only the coverage fixtures. Run both from the repository root. `PUT` and
`USE` paths are relative to that directory.

`make clean` removes `build/` and the `.bin`, `.lst`, and `.pcode` files
the test targets write under `test/`.

## Usage

```
usage: qasm [options] file.s [file2.s ...]
  -o FILE            object output (single file only)
  -l FILE            listing path (single file only; default: <src>.lst)
  --no-lst           do not write a listing
  -j N, --jobs N     max parallel assemblies (default: HW threads)
  -I DIR              add PUT/USE search directory
  --case-sensitive
  --algebraic
  --syntax NAME      merlin, merlin32, orca, lisa, ca65, or auto
  --dump-pcode       write <file>.pcode beside the source
```

With no `-o`, the object path is the `DSK` or `SAV` name from the source,
or `<file>.bin` when the source sets neither. Every assembly writes a
listing beside the source (`foo.s` → `foo.lst`) with the program counter,
object bytes, and the original line. The listing header begins
`; qasm  <name>  syntax=<dialect>`. Override the path with `-l`, or skip
the file with `--no-lst`.

`--algebraic` evaluates every expression with operator precedence. Merlin
braces `{...}` do the same for one expression. Merlin expressions otherwise
run left to right, so `1+2*3` is 9. ca65 and ORCA/M expressions are
rewritten into fully parenthesized Merlin form, so the same text is 7.
LISA stays left to right.

`--syntax auto`, and omitting `--syntax`, identifies each file. One name
applies to every file on the command line. An unknown name is an error.
`--dump-pcode` writes the lowered stream to `<file>.pcode`.

The assemble line reports the byte count, origin, dialect, object path,
listing path, and filetype. A clean Merlin file looks like:

```
test/fixtures/hello.s: assembled 4 bytes at $008000 syntax=merlin -> test/fixtures/hello.bin  lst test/fixtures/hello.lst (typ $06)
```

## Syntaxes

| Dialect | `--syntax` | How a file is recognized |
| --- | --- | --- |
| Merlin 16+ | `merlin` | Default when the text is ambiguous. Native high-bit, `$A0`, or `$8D` files. |
| Merlin 32 | `merlin32` | Same language. `Assembler: Merlin 32`, or `GEQU` / `GEQ`. |
| ORCA/M | `orca` | `longa`, `anop`, `mcopy`, `dc i1'...'`. |
| LISA | `lisa` | `.OR`, `.EQ`, `.DA`, `.HS`, `.EP`. |
| ca65 | `ca65` | `.org`, `.byte`, `.p816`, `.macro`. |

A marker in the first 40 lines wins: `syntax: ca65` or `Assembler: Merlin 32`.

Macros expand while the source is lowered, so Merlin `]1` text and `LUP`'s
`@` letter still work when the assembler runs the pcode. `PUT` and `USE`
are pulled in at that step, including when they sit in a false conditional.
ca65 symbols are case-sensitive. ORCA/M `CASE ON` is too. Segments are
flattened into the absolute image. A LISA `EPZ` name is forced to direct
page on later instructions.

ORCA/M `AIF`, `SETA`, and `LCLA`, and ca65 anonymous `:` labels, are
rejected. The full pseudo-op tables and the remaining limits are in
`doc/SYNTAX.md`.

## Tests

The coverage fixtures are one program, written once in each syntax:

- `test/fixtures/coverage-merlin.s`
- `test/fixtures/coverage-merlin32.s`
- `test/fixtures/coverage-orca.s`
- `test/fixtures/coverage-lisa.s`
- `test/fixtures/coverage-ca65.s`

`make test` and `make fixtures` assemble them and compare each object with
`coverage-merlin.bin`. A match is silent. To compare the objects by hand
after a run:

```
cmp test/fixtures/coverage-merlin.bin test/fixtures/coverage-merlin32.bin && \
cmp test/fixtures/coverage-merlin.bin test/fixtures/coverage-orca.bin && \
cmp test/fixtures/coverage-merlin.bin test/fixtures/coverage-lisa.bin && \
cmp test/fixtures/coverage-merlin.bin test/fixtures/coverage-ca65.bin && \
echo match
```

`testdata/` is the faddenSoft Merlin 32 corpus (Apache 2.0). It is a
comparison suite and is not part of `make test`.

## Documentation

- `doc/DIALECT.md` — Merlin 16+ line format, expressions, locals, and directives
- `doc/SYNTAX.md` — identification, pcode, per-dialect pseudo-ops, and limits
- `doc/manuals/Merlin_816_Macro_Assembler_Manual.pdf` — Merlin 8/16 user’s manual
- `doc/manuals/Merlin_16_Supplementary_Manual.pdf` — Merlin 16+ additions
- `doc/manuals/Merlin_16_Utilities_Manual.pdf` — 16+ disk utilities, outside this assembler

## License

MIT. See `LICENSE`.
