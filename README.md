# merlin

A host-side **Merlin 16+** cross-assembler for 6502 / 65C02 / 65816, targeting
the Apple IIgs (and 8-bit Apple II). The dialect is Glen Bredon’s Merlin 16+
(Roger Wagner Publishing, 1988–89). Merlin 8 and Merlin 16 sources are accepted
as a compatibility mode.

This is an assembler and linker, not a clone of the IIgs IDE. Edit sources with
a modern editor; assemble here; run the object on a IIgs, emulator, or the
sibling `m65816` FPGA core.

## Dialect

| Mode | `--dialect` | Startup | Notes |
| --- | --- | --- | --- |
| **Merlin 16+** (default) | `16+` | XC on (65816), MX `%11` (emulation) | Primary target. 16+ directives (`STRL`, `CAS`, `XC OFF`, `{algebraic}`, `TYP CDA`, …) are available. |
| Merlin 16 | `16` | XC on, MX `%11` | Same as 16+ minus later 16+ extras (they are ignored or warned). |
| Merlin 8 | `8` | XC off (6502 only), MX `%11` | `XC` / `XC` twice enable 65C02 then 65802. |

Every version of Merlin is a super-set of the previous one. We assemble 16+ by
default and keep 8/16 sources working: same columns, same left-to-right
expressions, same `]local` / `:local` labels, same `MAC` / `LUP` / `DO`.

Native Merlin disk files are accepted as-is: bit 7 set, `$A0` as the column
tab (while `$20` remains a real space in strings and comments), and `$8D`
line endings. Host-side `.s` files with ordinary spaces/TABs/LF work too.

**16+ sources should still assemble on a real Merlin 16+.** Stay within native
limits if you care about that round-trip:

- labels ≤ 26 characters
- lines ≤ 255 characters
- macro nest ≤ 15, condition nest ≤ 8
- no host-only extensions unless guarded

Original manuals (local copies):

- `doc/manuals/Merlin_816_Macro_Assembler_Manual.pdf` — Merlin 8/16 user’s manual
- `doc/manuals/Merlin_16_Supplementary_Manual.pdf` — Merlin 16+ delta (this is the baseline)
- `doc/manuals/Merlin_16_Utilities_Manual.pdf` — 16+ disk utilities (not part of the cross-assembler)

Language notes: `doc/DIALECT.md`.

## Build

```
make
make test
./merlin -o hello.bin test/fixtures/hello.s
```

```
usage: merlin [options] file.s
  -o FILE          object output (default: DSK/SAV name, else <file>.bin)
  -l FILE          listing output
  --dialect 16+|16|8
  --case-sensitive
  --algebraic      evaluate all expressions with operator precedence (FARMS bit)
```

## Status

MVP: two-pass 65816 assembler with Merlin columns, MX tracking, expressions,
data pseudo-ops, conditionals, macros, LUP, ORG/DSK. Relocatable OMF / Linker.GS
is next; absolute BIN/SYS is the current output.

## References

- Glen Bredon, *Merlin 8/16 User’s Manual*, Roger Wagner Publishing
- Glen Bredon, *Merlin 16+ Supplementary Manual*, Roger Wagner Publishing, 1988–89
- [Brutal Deluxe Merlin 32](https://brutaldeluxe.fr/products/crossdevtools/merlin/) — existing 16+-syntax cross-assembler (behavior reference, not a fork)
