# Merlin 16+ dialect (with 8/16 compatibility)

Primary spec: **Merlin 16+** (Glen Bredon, Roger Wagner Publishing, 1988–89).
Merlin 8/16 is the subset we remain compatible with. This file is the working
language contract for this assembler, distilled from:

- `doc/manuals/Merlin_816_Macro_Assembler_Manual.pdf`
- `doc/manuals/Merlin_16_Supplementary_Manual.pdf`

Host-only extensions, if any, will be called out. None yet.

## Line format

```
LABEL    OPCODE    OPERAND    ; comment
```

- A label, if present, starts in column 0 (no leading whitespace).
- Fields are separated by spaces or tabs.
- `*` or `;` as the first non-blank character makes a comment line.
- Opcode mnemonics are case-insensitive. Labels, macros, and equates follow
  `CAS SE` / `CAS IN` (default: insensitive, matching typical 16+ FARMS).

### Native Merlin source files (disk / IIgs editor)

The on-disk format from Merlin 8/16/16+ is **not** plain ASCII:

- Letters, digits, and punctuation normally have **bit 7 set**.
- **Column tabs** (label / opcode / operand / comment) are a single `$A0`
  (space with the high bit set). `$09` and `$89` (TAB) are accepted too.
- **Literal spaces** in quoted operands and comments are `$20` (high bit
  clear). That is why `$A0` is a tab and `$20` is not: the assembler can
  split columns without tracking quotes.
- Lines end with `$8D` (high-bit CR), sometimes `$0D` / `$0A`.
- Extra `$A0` after the third separator is treated as an ordinary space
  (David Empson / CiderPress notes).

Host-side `.s` files (spaces, TABs, LF/CRLF, high bit clear) are also
accepted. High-bit letters with `$20` separators (partially converted
files) still assemble: bit 7 is stripped on each field.

## Processors

| `XC` | CPU |
| --- | --- |
| off | 6502 only |
| once | 65C02 |
| twice, or 16/16+ default | 65802 / 65816 |

16+: `XC OFF` restores 6502-only. Startup:

- `--dialect 16+` / `16`: XC on (65816), MX `%11` (emulation, 8-bit A/XY)
- `--dialect 8`: XC off, MX `%11`

Sources should still begin with explicit `MX` / `XC` so they assemble the same
way regardless of FARMS / CLI defaults.

`SEP` / `REP` update assembler MX from the immediate operand when it is
constant. `MX %00`–`%11` (or 0–3) sets it without emitting code.

`M=0` / `X=0` means 16-bit; `1` means 8-bit.

## Addressing

Merlin does **not** write `ASL A`. Accumulator/implied is a bare mnemonic.

Immediate data starts with `#`. Addresses do not.

| Syntax | Mode |
| --- | --- |
| `LDA #$00` | immediate (8 or 16 from M) |
| `LDA $10` | direct page if value < $100 and not forced |
| `LDA $C000` | absolute |
| `LDAL $E12000` / `LDA >$E12000` | long |
| `LDA: $10` / `LDA\ $10` | force absolute |
| `LDA <$1234` | force direct page (low byte) |
| `LDA ($10),Y` | DP indirect indexed |
| `LDA [$10],Y` | DP indirect long indexed |
| `LDA $10,S` | stack relative |
| `LDA ($10,S),Y` | stack relative indirect indexed |
| `BEQ LABEL` | relative |
| `MVN src,dst` | block move (object: dest bank, src bank) |

Byte selectors after `#`: `<` low, `>` high, `^` (or `#A`) bank.

Alternate mnemonics: `BLT`=`BCC`, `BGE`=`BCS`, `TAS`=`TCS`, `TSA`=`TSC`,
`TAD`=`TCD`, `TDA`=`TDC`, `SWA`=`XBA`. Long ALU forms `LDAL`, `STAL`, …

Undefined labels are 16-bit (absolute) until equated. Zero-page labels must be
defined before use (Merlin rule; otherwise DP/abs size would be unstable).

## Expressions

Numbers: decimal, `$hex`, `%binary` (`_` allowed in binary). ASCII `'A'` / `"A"`.
`*` is the program counter at term position, multiply at operator position.

Default evaluation is **left-to-right, no precedence** (`1+2*3` = 9). Enclose
in `{ }` for algebraic precedence (16+). `--algebraic` does that for all
expressions (FARMS bit; can break old `LAB1-LAB2/2` sources).

Operators, lowest to highest inside braces:

```
<  =  >  #          comparison (true=1, false=0); # is not-equal
+  -
*  /
&  .  !             AND, OR, XOR
-                   unary minus
```

`(` `)` are addressing, not grouping. Use `{ }`.

## Labels

- Global: start with a letter or extra-alphabetic (`_`, `@`, … not a digit).
- `]NAME` as a **label** is a backward-only local (nearest previous).
- `:NAME` is a local whose scope is the enclosing global labels.
- `]NAME = expr` is a **variable** (redefinable). Forward refs to variables
  are illegal.
- Locals cannot be `ENT`/`EXT` and cannot be the first label in a file.

Compatibility: keep names ≤ 26 characters for real Merlin 16+.

## Data / directives (16+ set, 8/16 subset)

Assembler: `ORG`, `OBJ`, `EQU`/`=`, `PUT`, `USE`, `VAR`, `SAV`, `DSK`, `END`,
`DUM`, `DEND`, `TYP`, `REL`, `LNK`, `ENT`, `EXT`, `MX`, `XC`, `CAS`, `ERR`,
`CHK`, `DATE`, `STRL` (16+), `LST`, `EXP`, `TR`, `PAU`, `PAG`, `AST`, `SKP`.

Data: `HEX`, `DFB`/`DB`, `DA`/`DW`, `DDB`, `ADR`, `ADRL`, `DS`,
`ASC`, `DCI`, `INV`, `FLS`, `REV`, `STR`, `STRL`.

16+ `ASC` accepts hex bytes mixed into the string, empty strings, and
`ASC #expr` / `#'` / `#"` / `#>`.

Conditionals: `DO` / `ELSE` / `FIN`, `IF` / `ELSE` / `FIN`.
`IF MX/2` tests M; `IF "=]1"` / `IF #,]1` tests the first character of a
variable (macros). Nest ≤ 8 on real 16+.

Macros: `MAC` … `EOM` / `<<<`. Call by name, or `PMC` / `>>>`. Parameters
`]1`–`]9` separated by `;`. Nest ≤ 15 on real 16+.

Loops: `LUP n` … `--^`. `@` in a label becomes Z,Y,X,… per iteration (max 26).

## Output

Absolute object (BIN) is produced from `ORG` + `DSK`/`SAV`/`-o`.
`REL` / Linker.GS / OMF v2.1 is planned; not in the MVP.

`TYP` accepts hex (`$B3`) or ASCII names (`SYS`, `S16`, `CDA`, `EXE`, `BIN`).

## What 16+ added (vs 8/16) that we treat as first-class

- `XC OFF`
- `CAS SE` / `CAS IN`
- `{algebraic}` expressions and `< = > #` comparisons
- `STRL`
- mixed hex in `ASC`/`STR`/… and `ASC #`
- `TYP` ASCII filetypes; `TYP` in REL files
- `SAV` compatible with `REL`
- `LST FILE,name`
- pathname `../` (`.` + `/` backup) in assembler/linker files
- `DATE` operands 1–8
- `FLO` (SANE extended) — not yet implemented
- `DUP` equate-same-value option — not yet a CLI flag
