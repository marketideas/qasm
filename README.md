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

C++17, `g++`. Independent source files assemble in parallel.

```
make
make test
./merlin test/fixtures/hello.s
./merlin a.s b.s c.s          # parallel; each gets its own .bin and .lst
```

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
```

Absolute BIN/SYS is the current output. Relocatable OMF / Linker.GS is not
done yet.

## References

- Glen Bredon, *Merlin 8/16 User’s Manual*, Roger Wagner Publishing
- Glen Bredon, *Merlin 16+ Supplementary Manual*, Roger Wagner Publishing, 1988–89
