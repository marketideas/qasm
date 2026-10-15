# Merlin 16+ dialect

QuickAsm implements **Merlin 16+** (Glen Bredon, Roger Wagner Publishing,
1988–89). The language contract is:

- `doc/manuals/Merlin_816_Macro_Assembler_Manual.pdf` — base syntax
- `doc/manuals/Merlin_16_Supplementary_Manual.pdf` — 16+ additions

Merlin 16+ is the native language and the form the encoder consumes.
ORCA/M, LISA, Merlin 32, and ca65 sources are lowered to that form.
Identification, pcode, per-dialect pseudo-ops, and limitations are in
`doc/SYNTAX.md`.

## Line format

```
LABEL    OPCODE    OPERAND    ; comment
```

- A label, if present, starts in column 0 (no leading whitespace).
- Fields are separated by spaces or tabs.
- `*` or `;` as the first non-blank character makes a comment line.
- Opcode mnemonics are case-insensitive. Labels, macros, and equates follow
  `CAS SE` / `CAS IN` (default: insensitive, typical FARMS).

### Native 16+ source files (disk / IIgs editor)

On disk, Merlin 16+ source is not plain ASCII:

- Letters, digits, and punctuation normally have **bit 7 set**.
- **Column tabs** (label / opcode / operand / comment) are a single `$A0`
  (space with the high bit set). `$09` and `$89` (TAB) are accepted too.
- **Literal spaces** in quoted operands and comments are `$20` (high bit
  clear), so columns can be split without tracking quotes.
- Lines end with `$8D` (high-bit CR), sometimes `$0D` / `$0A`.
- Extra `$A0` after the third separator is an ordinary space.

Host-side `.s` files (spaces, TABs, LF/CRLF, high bit clear) are also
accepted.

## Processors

| `XC` | CPU |
| --- | --- |
| `XC OFF` | 6502 only |
| `XC` once | 65C02 |
| `XC` twice (16+ default at startup) | 65802 / 65816 |

Startup: 65816 opcodes on, `MX %11` (emulation). Put explicit `MX` / `XC` at
the top of each source so it matches a real 16+ machine regardless of FARMS.

`SEP` / `REP` update assembler MX from a constant immediate. `MX %00`–`%11`
(or 0–3) sets it without emitting code. `M=0` / `X=0` is 16-bit; `1` is 8-bit.

## Addressing

Merlin does **not** write `ASL A`. Accumulator/implied is a bare mnemonic.

Immediate data starts with `#`. Addresses do not.

| Syntax | Mode |
| --- | --- |
| `LDA #$00` | immediate (8 or 16 from M) |
| `LDA $10` | direct page if value < $100 and not forced |
| `LDA $C000` | absolute |
| `LDAL $E12000` / `LDA >$E12000` | long |
| `LDA: $10` | force absolute (any 4th opcode character except `L` or `D`) |
| `LDA <$1234` | force direct page (low byte) |
| `LDA \|$04` | force absolute |
| `LDA ($10),Y` | DP indirect indexed |
| `LDA [$10],Y` | DP indirect long indexed |
| `LDA $10,S` | stack relative |
| `LDA ($10,S),Y` | stack relative indirect indexed |
| `BEQ LABEL` | relative |
| `MVN src,dst` | block move (object: dest bank, src bank) |

Immediate byte/word selects (8-bit vs 16-bit from MX):

| | 8-bit | 16-bit |
| --- | --- | --- |
| `#expr` / `#<expr` | low byte | low word (bytes 0–1) |
| `#>expr` | high byte | high word (bytes 1–2) |
| `#^expr` / `#Aexpr` | bank byte | bank word (bytes 2–3) |

Address-mode force prefixes (16+):

| Prefix | Mode |
| --- | --- |
| `<expr` | force direct page (low byte) |
| `\|expr` | force absolute (16-bit) |
| `>expr` | force absolute long (24-bit) |
| `^expr` | absolute using the high word |
| `LDAL` / `lda:` | long / forced absolute |

`;` inside an operand with no preceding space is data (macro parameters
`arg1;arg2`). A `;` after whitespace starts a comment.

Alternate mnemonics: `BLT`=`BCC`, `BGE`=`BCS`, `TAS`=`TCS`, `TSA`=`TSC`,
`TAD`=`TCD`, `TDA`=`TDC`, `SWA`=`XBA`. Long ALU forms `LDAL`, `STAL`, …

Undefined labels are 16-bit (absolute) until equated. Zero-page labels must be
defined before use.

## Expressions

Numbers: decimal, `$hex`, `%binary`. ASCII `'A'` / `"A"`.
`*` is the program counter at term position, multiply at operator position.

Default evaluation is **left-to-right, no precedence** (`1+2*3` = 9). Enclose
in `{ }` for algebraic precedence. `--algebraic` does that for all expressions
(FARMS bit; can break `LAB1-LAB2/2` sources).

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

- Global: start with a letter or extra-alphabetic (not a digit). Max 26
  characters on a real 16+.
- `]NAME` as a **label** is a backward-only local (nearest previous).
- `:NAME` is a local whose scope is the enclosing global labels.
- `]NAME = expr` is a **variable** (redefinable). No forward refs.
- Locals cannot be `ENT`/`EXT` and cannot be the first label in a file.

## Directives

`ORG`, `OBJ`, `EQU`/`=`, `PUT`, `USE`, `VAR`, `SAV`, `DSK`, `END`, `DUM`,
`DEND`, `TYP`, `REL`, `LNK`, `ENT`, `EXT`, `MX`, `XC`, `CAS`, `ERR`, `CHK`,
`DATE`, `FLO` (10-byte SANE), `STRL`, `LST`, `EXP`, `TR`, `PAU`, `PAG`,
`AST`, `SKP`.

`PUT file` inserts and assembles another source (search: directory of the
current file, `-I` dirs, then `.`; `.s` is optional). `USE file` loads
macros from that file without assembling its code. `VAR e1;e2;…` assigns
`]1`…`]9` for a following `PUT`.

Data: `HEX`, `DFB`/`DB`, `DA`/`DW`, `DDB`, `ADR`, `ADRL`, `DS`,
`ASC`, `DCI`, `INV`, `FLS`, `REV`, `STR`, `STRL`.

`ASC` accepts hex bytes mixed into the string, empty strings, and
`ASC #expr` / `#'` / `#"` / `#>`.

Conditionals: `DO` / `ELSE` / `FIN`, `IF` / `ELSE` / `FIN`.
`IF MX/2` tests M; `IF "=]1"` / `IF #,]1` tests the first character of a
variable (macros). Nest ≤ 8 on real 16+.

Macros: `MAC` … `EOM` / `<<<`. Call by name, or `PMC` / `>>>`. Parameters
`]1`–`]9` separated by `;`. Nest ≤ 15 on real 16+. Labels in a macro body
(except `EQU`/`=`) are uniquified per expansion.

Loops: `LUP n` … `--^`. `@` in a label becomes Z,Y,X,… per iteration (max 26).

## Output

Absolute object (BIN) from `ORG` + `DSK`/`SAV`/`-o`.
`REL` / Linker.GS / OMF v2.1 is not implemented yet.

`TYP` accepts hex (`$B3`) or ASCII names (`SYS`, `S16`, `CDA`, `EXE`, `BIN`).

## 16+ additions (vs Merlin 16) that are first-class here

- `XC OFF`
- `CAS SE` / `CAS IN`
- `{algebraic}` expressions and `< = > #` comparisons
- `STRL`
- mixed hex in `ASC`/`STR`/… and `ASC #`
- `TYP` ASCII filetypes
- `SAV` with `REL`
- `LST FILE,name`
- `DATE` operands 1–8
- `FLO` (SANE extended)
