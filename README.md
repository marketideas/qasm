# QuickAsm

QuickAsm (`qasm`) is a Linux cross-assembler for the 65816, and for the
6502 and 65C02 through `XC`. It reads source in more than one syntax,
lowers every file to one common pcode stream, and assembles from that
stream. The object is an absolute binary.

The original QuickAsm repository is now
[qasm-legacy](https://github.com/marketideas/qasm-legacy). This tree is
the current assembler.

The syntaxes are Merlin 16+, Merlin 32, ORCA/M, APW/MPW, LISA, and ca65.
Merlin 16+ (Glen Bredon, Roger Wagner Publishing, 1988–89) is the
language the encoder consumes. The others are rewritten into the same
pcode, so one program can be written in any of them and assemble to the
same bytes. APW is Apple's 65816 assembler, the ORCA/M language Apple
shipped. `mpw` is the same dialect: the listing reports `syntax=apw`. Identification, pseudo-op rewriting, and the limits of that
lowering are in `doc/SYNTAX.md`. The Merlin 16+ language contract is
`doc/DIALECT.md`.

Edit source on Linux, assemble it with `qasm`, and run the object on a
IIgs, an emulator, or the sibling `m65816` FPGA core.

## From source to pcode to object

```
source file
    → identify the syntax, or take --syntax
    → dialect front end writes one pcode stream
    → two passes over that pcode
    → absolute BIN, and a listing when -l is given
```

A file is identified by `--syntax`, a marker in the first 40 lines,
native high-bit Merlin text, or a score of distinctive tokens. A tie
stays Merlin 16+. One `--syntax` name applies to every file on the
command line. Omitting it identifies each file on its own, so one
`qasm` command can assemble a Merlin file and a ca65 file together.

The front end expands macros, and pulls in Merlin `PUT` and `USE`,
ORCA/M `COPY`, `MCOPY`, and `APPEND`, and ca65 `.include`, while it
writes the pcode. QuickAsm then walks that stream twice. Pass 1
assigns addresses and defines symbols. Pass 2 emits the object bytes
and the listing. `--dump-pcode` writes the stream beside the source
as `<file>.pcode`.

Several sources on one command line assemble independently, in
parallel. Each file keeps its own syntax and its own object.

Startup matches Merlin 16+ on a IIgs: 65816 opcodes, `MX %11` (M and X both
8-bit), case-insensitive labels, program counter `$8000`, and filetype `$06`
(BIN). Put explicit `MX` and `XC` at the top of a source so it matches a
real 16+ assembly. `TYP` changes the type printed with the object. The
bytes stay a raw image.

Native Merlin disk files are accepted as-is (bit 7 set, `$A0` column tabs,
`$8D` line endings). Linux text `.s` files with spaces, tabs, and LF work
too.

Labels of 26 characters or fewer, lines of 255 characters or fewer, a macro
nest of 15, and a condition nest of 8 stay inside the Merlin 16+ limits for
a source that will also assemble on a real 16+.

Absolute BIN is the object qasm writes for a fixed origin. A relocatable
module also gets an OMF 2.0 object. `qlink` links those into an OMF load
file, and `makeBin` turns that load file into the raw image ProDOS can
load. `qomf` prints an OMF file, including its header and relocation
records. Under `REL`, an unknown label is 0 and the assembler still writes
the raw image beside the object.

## Build

QuickAsm builds and runs on Linux. The code is C++17. CMake is the build.
The Makefile configures `build/release` and `build/debug` when
`CMakeLists.txt` is newer than that cache, then builds the requested target.
Release uses `-O2 -DNDEBUG`. Debug uses `-O0 -g`. Executables are copied
under `bin/`, which is not version controlled. `make` produces release
`bin/qasm`, `bin/qlink`, `bin/makeBin`, and `bin/qomf`, and the same four names under
`bin/debug/`.
`make release` and `make debug` build one configuration. `make test` uses
the release build and also copies `bin/test_qasm`.

`qasm`, `qlink`, `makeBin`, and `qomf` each have a major, minor, and patch number
in `CMakeLists.txt`. Debug and release each have a build number that
increases by one every time that configuration is built. `--version`
prints all of it, for example `qasm 0.1.0 build 3 release`.

```
make
make release
make debug
make test
make fixtures
./bin/qasm test/fixtures/hello.s
./bin/qasm a.s b.s c.s
```

`make` builds release and debug `qasm`, `qlink`, `makeBin`, and `qomf`. Several source files on one command line assemble in
parallel. `make test` runs the unit tests, assembles `test/fixtures/hello.s`
and `test/test.s`, assembles the six coverage fixtures, and requires those
six objects to be byte-identical. `make fixtures` assembles and compares
only the coverage fixtures. Run both from the repository root. `PUT` and
`USE` paths are relative to that directory.

`make clean` removes `build/` and the `.bin`, `.lst`, and `.pcode` files
the test targets write under `test/`.

## Usage

```
usage: qasm [options] file.s [file2.s ...]
  -o FILE            object output (single file only)
  -l FILE            write a listing to FILE (- or stdout for standard output)
  --no-lst           do not write a listing
  -j N, --jobs N     max parallel assemblies (default: HW threads)
  -I DIR              add PUT/USE search directory
  --case-sensitive
  --algebraic
  --syntax NAME      merlin, merlin32, orca, apw, mpw, lisa, ca65, or auto
  --dump-pcode       write <file>.pcode beside the source
  -V, --version      print version and exit
```

With no `-o`, the object path is the `DSK` or `SAV` name from the source,
or `<file>.bin` when the source sets neither. A listing is written only
when `-l FILE` is given. `FILE` may be `-` or `stdout`, which writes the
listing to standard output and the assemble summary to standard error.
One named file applies to a single source; `-` or `stdout` can be used
with several sources. The listing shows the program counter, object
bytes, and the original line. Its header begins
`; qasm  <name>  syntax=<dialect>`. `--no-lst` turns the listing off
again.

`--algebraic` evaluates every expression with operator precedence. Merlin
braces `{...}` do the same for one expression. Merlin expressions otherwise
run left to right, so `1+2*3` is 9. ca65 and ORCA/M expressions are
rewritten into fully parenthesized Merlin form, so the same text is 7.
LISA stays left to right.

`--syntax auto`, and omitting `--syntax`, identifies each file. One name
applies to every file on the command line. An unknown name is an error.
`--dump-pcode` writes the lowered stream to `<file>.pcode`.

The assemble line reports the byte count, origin, dialect, object path,
and filetype. A `-l` path is included when a listing is written. A clean
QuickAsm run looks like:

```
test/fixtures/hello.s: assembled 4 bytes at $008000 syntax=merlin -> test/fixtures/hello.bin (typ $06)
```

## makeBin

`qlink` writes an OMF load file. ProDOS 8 loads a raw image, which is what
MPW `MakeBinIIGS` extracts. `makeBin` does that step.

```
usage: makeBin [options] loadfile [loadfile...]
  -o FILE            output image (one load file only; - or stdout)
  -org ADDR          address of the first output byte ($2000, 0x2000, or hex)
                     default: the lowest segment address
  -V, --version      print version and exit
  -h, --help         print this help and exit
  With no -o, each load file is replaced by its raw image.
```

Byte 0 of the image is the `-org` address, or the lowest segment address
when `-org` is omitted. A later segment leaves zeros in the gap. A segment
below that address, an object or library, or a segment that still has
relocations is an error. The file type and auxiliary type are not stored
in the image.

```
makeBin apple.omf -org '$2000' -o apple.bin
```

## qomf

`qomf` prints an OMF 1.0 or 2.0 file: each segment header, every record,
and the relocation entries.

```
usage: qomf [options] file [file...]
  -V, --version      print version and exit
  -h, --help         print this help and exit
```

The dump lists the byte or block count, reserved space, length, kind,
origin, alignment, load name, and segment name. `CONST` and `LCONST`
bytes are shown in hex. `RELOC` and `INTERSEG` lines give the width,
shift, offset, and displacement. `INTERSEG` also gives the file and
segment numbers. Object files show `GLOBAL` and `LOCAL` with the length,
type, and private flag, and `RELEXPR` with its expression. Each segment
ends with a relocation count and a fixup count. Bytes after `END` are
the block padding on an OMF 1.0 load file. A `SUPER` record is printed
as its type byte and the bytes that follow it. A record whose size is
not known, including `ENTRY`, stops the dump and is reported on standard
error.

```
qomf prog.omf
```

## qpro

`qpro` builds a ProDOS volume and copies files in and out of it. The
image is a series of 512-byte blocks. A name ending in `.2mg` or `.2img`
is a 2MG wrapper around those blocks. Any other name is the raw blocks.
Boot blocks are left empty, so the volume mounts and does not boot.

```
usage: qpro create VOLUME -name NAME (-blocks N | -size SPEC)
       qpro cat VOLUME [PATH]
       qpro add VOLUME PATH HOSTFILE [-t TYPE] [-a AUX]
       qpro get VOLUME PATH HOSTFILE
       qpro rm VOLUME PATH
       qpro mkdir VOLUME PATH
       qpro typ VOLUME PATH [-t TYPE] [-a AUX]
  -name NAME         volume name
  -blocks N          decimal block count (7 to 65535)
  -size SPEC         140k, 800k, or 32m
  -t TYPE            file type ($06, 0x06, or hex); add defaults to $06
  -a AUX             auxiliary type; add defaults to $0000
  -V, --version      print version and exit
  -h, --help         print this help and exit
```

`-blocks` is a decimal count. `-size 140k` is 280 blocks, `800k` is
1600, and `32m` is 65535. A path is `DIR/FILE`, or `/VOLUME/DIR/FILE`
when the path starts with the volume name. Names are stored in upper
case. `add` refuses a name that is already there. `rm` refuses a
directory that still has files. `mkdir` does not create missing parents.

The file type and auxiliary type live in the directory entry. Quote
them in the shell so `$` is not expanded.

```
qpro create disk.po -name DISK -size 140k
qpro add disk.po BASIC.SYSTEM basic.bin -t '$FF' -a '$2000'
qpro get disk.po /DISK/BASIC.SYSTEM basic.bin
qpro typ disk.po BASIC.SYSTEM -t '$06' -a '$2000'
```

GS/OS extended files stay in the directory. `qpro` does not read or
write their resource forks.

## Syntaxes

| Dialect | `--syntax` | How a file is recognized |
| --- | --- | --- |
| Merlin 16+ | `merlin` | Default when the text is ambiguous. Native high-bit, `$A0`, or `$8D` files. |
| Merlin 32 | `merlin32` | Same language. `Assembler: Merlin 32`, or `GEQU` / `GEQ`. |
| ORCA/M | `orca` | `longa`, `anop`, `mcopy`, `dc i1'...'`. |
| APW/MPW | `apw` | Apple's assembler. `mpw` selects it too. `Assembler: APW`, `Assembler: MPW`, or `absaddr`, `msb`, `codechk`, `instime`. |
| LISA | `lisa` | `.OR`, `.EQ`, `.DA`, `.HS`, `.EP`. |
| ca65 | `ca65` | `.org`, `.byte`, `.p816`, `.macro`. |

A marker in the first 40 lines wins: `syntax: ca65`, `Assembler: Merlin 32`, or `Assembler: APW`. `Assembler: MPW` selects APW.

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
- `test/fixtures/coverage-apw.s`
- `test/fixtures/coverage-lisa.s`
- `test/fixtures/coverage-ca65.s`

`make test` and `make fixtures` assemble them and compare each object with
`coverage-merlin.bin`. A match is silent.

The relocatable fixtures are two sections that call and address each
other. `rel-code-*.s` exports `CODE`, calls `HOOK`, and loads `VALUE`.
`rel-data-*.s` exports `VALUE` and `HOOK`, calls `CODE`, and loads it.
The six syntaxes of each section match. `qlink` will link the pair into
an OMF. To compare the objects by hand after a run:

```
cmp test/fixtures/coverage-merlin.bin test/fixtures/coverage-merlin32.bin && \
cmp test/fixtures/coverage-merlin.bin test/fixtures/coverage-orca.bin && \
cmp test/fixtures/coverage-merlin.bin test/fixtures/coverage-apw.bin && \
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
