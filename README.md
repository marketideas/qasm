# merlin

A host-side **Merlin 16+** cross-assembler for the 65816 (and 6502 / 65C02
via `XC`). The language is Glen Bredon’s Merlin 16+ (Roger Wagner Publishing,
1988–89), as documented in the 8/16 user’s manual and the 16+ supplementary.

This is an assembler, not a clone of the IIgs IDE. Edit on the host, assemble
here, run the object on a IIgs, emulator, or the sibling `m65816` FPGA core.

Startup matches Merlin 16+ on a IIgs: 65816 opcodes enabled, `MX %11`
(emulation). Put explicit `MX` / `XC` at the top of a source so it matches a
real 16+ assembly regardless of FARMS.

Native Merlin disk files are accepted as-is (bit 7 set, `$A0` column tabs,
`$8D` line endings). Host `.s` files with spaces/TABs/LF work too.

If you care about round-tripping to a real Merlin 16+: labels ≤ 26 characters,
lines ≤ 255, macro nest ≤ 15, condition nest ≤ 8.

Manuals (local copies):

- `doc/manuals/Merlin_816_Macro_Assembler_Manual.pdf` — Merlin 8/16 user’s manual (the 16+ base language)
- `doc/manuals/Merlin_16_Supplementary_Manual.pdf` — Merlin 16+ additions (this is the baseline)
- `doc/manuals/Merlin_16_Utilities_Manual.pdf` — 16+ disk utilities (not part of the cross-assembler)

Language notes: `doc/DIALECT.md`.

## Build

C++17, `g++`. The Makefile drives CMake, and the binaries land in `build/`.
Independent source files assemble in parallel.

```
make
make test
make fixtures
./build/merlin test/fixtures/hello.s
./build/merlin a.s b.s c.s    # parallel; each gets its own .bin and .lst
```

`make clean` removes `build/` and the `.bin`, `.lst`, and `.pcode` files
the test targets write into `test/`.

Every assemble writes a listing next to the source (`foo.s` → `foo.lst`) with
PC, object bytes, and the original source line. Override with `-l`, or disable
with `--no-lst`.

```
usage: merlin [options] file.s [file2.s ...]
  -o FILE          object output (single file only; default: DSK/SAV or <file>.bin)
  -l FILE          listing path (single file only; default: <file>.lst)
  --no-lst         do not write a listing
  -j N, --jobs N   max parallel assemblies (default: hardware threads)
  -I DIR           add PUT/USE search directory
  --case-sensitive
  --algebraic      evaluate all expressions with operator precedence (FARMS bit)
  --syntax NAME    merlin, merlin32, orca, lisa, ca65, or auto
  --dump-pcode     write <file>.pcode beside the source
```

Absolute BIN/SYS is the current output. Relocatable OMF / Linker.GS is not
done yet.

## Syntaxes

Each source file is identified, lowered to one 65816 pcode stream, and then
assembled. The object stays absolute BIN. How identification works, how
each dialect's pseudo-ops are rewritten, and the limits of that lowering
are in `doc/SYNTAX.md`. Merlin 16+ itself is `doc/DIALECT.md`.

| Dialect | `--syntax` | How a file is recognized |
| --- | --- | --- |
| Merlin 16+ | `merlin` | Default when the text is ambiguous. Native high-bit / `$A0` / `$8D` files. |
| Merlin 32 | `merlin32` | Same language. `Assembler: Merlin 32`, or `GEQU` / `GEQ`. |
| ORCA/M | `orca` | `longa`, `anop`, `mcopy`, `dc i1'...'`. |
| LISA | `lisa` | `.OR`, `.EQ`, `.DA`, `.HS`, `.EP`. |
| ca65 | `ca65` | `.org`, `.byte`, `.p816`, `.macro`. |

A marker in the first 40 lines wins: `syntax: ca65` or `Assembler: Merlin 32`.
`--syntax auto` (or leaving it off) identifies each file. An unknown name is
an error.

Merlin expressions stay left to right (`1+2*3` is 9). ca65 and ORCA/M
expressions are rewritten into fully parenthesized Merlin form, so the same
text is 7. LISA stays left to right. A LISA `EPZ` name is forced to direct
page on later instructions.

Macros expand while the source is lowered, so Merlin `]1` text and `LUP`'s
`@` letter still work when the assembler runs the pcode. `PUT` and `USE`
are pulled in at that step, including when they sit in a false conditional.
ca65 symbols are case-sensitive. ORCA/M `CASE ON` is too. Segments are
flattened into the absolute image.

ORCA/M `AIF` / `SETA` / `LCLA` and ca65 anonymous `:` labels are rejected.
`--dump-pcode` writes the lowered stream; the library itself only fills
`Result::pcode` when asked.

## References

- Glen Bredon, *Merlin 8/16 User’s Manual*, Roger Wagner Publishing
- Glen Bredon, *Merlin 16+ Supplementary Manual*, Roger Wagner Publishing, 1988–89
