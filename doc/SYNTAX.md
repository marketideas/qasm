# Syntaxes and pcode

Merlin 16+ is the language the encoder understands. Every other dialect is
lowered to one 65816 pcode stream, and that stream is what gets assembled.
The object is an absolute binary. Merlin line format, expressions, and the
16+ manual contract are in `doc/DIALECT.md`. This file is how a source file
gets there, how each dialect's pseudo-ops are rewritten, and where the
implementation stops.

## Pipeline

```
source file
    │
    ├─ Options.syntax, or identify_syntax()
    │
    ├─ dialect front end  →  PCode
    │
    └─ assemble_pcode()   →  two passes, symbols, MX/CPU, bytes, listing
```

`assemble_file` reads one file and calls `assemble_string`. That identifies
the dialect (unless `--syntax` overrides it) and compiles to pcode.
`assemble_lines` skips identification and always uses the Merlin front end.
That is the path for a caller that already parsed Merlin lines.

One command-line `--syntax` applies to every file. Each file is still
assembled on its own, including under `-j`. A file that is `PUT` or `USE`d
by another file on the same command line is not also assembled as a
top-level job.

Startup, before any source directive:

| State | Value |
| --- | --- |
| CPU | 65816 (`XC` level 2) |
| `MX` | `%11` (M and X both 8-bit) |
| PC and default `ORG` | `$8000` |
| Case | insensitive, until a directive says otherwise |
| File type | `$06` BIN |

`MX` bits: bit 1 (value 2) is M, bit 0 (value 1) is X. A set bit means
8-bit. After `.a16` or `longa on`, M is clear, so `LDA #1` is
`A9 01 00`.

Assembly is two passes over the same pcode. Pass 1 assigns addresses and
defines symbols. Pass 2 emits object bytes and the listing. On pass 2 a
normal label is left at the value from pass 1. A Merlin variable (`]N` or
`]NAME`) is updated on both passes. An unknown label is an error on pass 2.
Under `REL`, an unknown label is 0.

The listing header records the dialect (`syntax=merlin`, and so on).
`--dump-pcode` asks the library to fill `Result::pcode`. The `merlin`
command writes that text to `<file>.pcode`. The library does not write the
file itself.

## Identification

Order:

1. `--syntax NAME`, when it is not empty and not `auto`. An unknown name
   is an error and nothing is assembled.
2. A marker in the first 40 lines, after high bits are stripped:
   `syntax: ca65`, `syntax ca65`, `!syntax ca65`, or
   `Assembler: Merlin 32`. `Merlin 32` and `Merlin32` are checked before
   the single word `Merlin`.
3. A native Merlin file: a `$A0` column tab or a `$8D` line ending, and
   more than four bytes with bit 7 set.
4. Otherwise, score distinctive tokens on comment-stripped, uppercased
   text. One occurrence is enough. Shared words such as `ORG`, `EQU`,
   `JSR`, `END`, and `START` add nothing. A leading dot matters: `.ORG`
   is not Merlin `ORG`.

| Dialect | Tokens that score |
| --- | --- |
| Merlin | `MX` `XC` `DFB` `DDB` `STRL` `ADRL` `DEND` `DSK` `LUP` `DCI` `FLS` `PMC` `EOM` `DUM` `PUT` `USE` `--^` `MAC` |
| Merlin 32 | `GEQU` or `GEQ` (also counts as Merlin) |
| ORCA/M | `LONGA` `LONGI` `ANOP` `MCOPY` `MEND` `PRIVDATA` `ENDC`, or a `DC` lead-in `I1'` `I2'` `I4'` `I1"` `I2"` `C'` `H'` |
| LISA | `.OR` `.HS` `.BS` `.EQ` `.DA` `.EN` `.EP` `.AS` `.FI` `.EL` `.DB` `.BY` |
| ca65 | `.ORG` `.BYTE` `.WORD` `.DWORD` `.FARADDR` `.RES` `.MACRO` `.ENDMACRO` `.P816` `.A8` `.A16` `.I8` `.I16` `.PROC` `.IMPORT` `.EXPORT` `.SEGMENT` `.SETCPU` `.PC02` `.P02` `.FEATURE` `.INCLUDE` `.ALIGN` `.REPEAT` `.ENDPROC` |

The highest score wins. A tie stays Merlin. A score of zero stays Merlin,
so a file that is only `ORG` / `EQU` / `JSR` / `RTS` is Merlin. If the
Merlin 32 flag is set and Merlin wins, the dialect is Merlin 32. Merlin 32
uses the same front end and the same encoder as Merlin 16+.

Accepted names: `merlin`, `merlin16`, `merlin16+`, `merlin-16`, `merlin32`,
`merlin-32`, `m32`, `orca`, `orca/m`, `orcam`, `orca-m`, `lisa`, `lisa816`,
`lisa-816`, `ca65`, `cc65`, `auto`.

## What pcode is

Each `PInstr` is one operation. Line-like operations carry a Merlin opcode
and operand, because that is what the encoder evaluates. Control operations
are executed by the pcode walker. Instruction lines also store a canonical
view (`cname`, addressing form, force, byte select, expression) for the
pcode dump. Encoding uses the opcode and operand text, not that canonical
view.

| Op | What the assembler does |
| --- | --- |
| `P_NOP` | Lists the line. A real label is defined at the PC. A `MAC` / `EOM` / `<<<` name is not a symbol. A comment label that starts with `*` or `;` is not a symbol. The opcode is not executed. |
| `P_LABEL` | Defines the label at the PC. No bytes. |
| `P_END` | Defines a label if the line has one, then stops the assembly. |
| `P_ORG` | Merlin `ORG`. See below. |
| `P_EQU` | Merlin `EQU`, `=`, `GEQU`, or `GEQ`. |
| `P_MX` | Merlin `MX`. |
| `P_XC` | Merlin `XC`. |
| `P_MXPART` | Changes part of `MX`. `i0` is the bit mask, `i1` is the new bits. Applied even inside a false conditional. |
| `P_CPU` | Sets the CPU: 0 = 6502, 1 = 65C02, 2 = 65816. Applied even inside a false conditional. |
| `P_INST` | A machine instruction. |
| `P_DATA` | `DFB` / `DB` / `DA` / `DW` / `DDB` / `ADR` / `ADRL`. |
| `P_DS` | Merlin `DS`. |
| `P_ASM` | Any other Merlin pseudo-op (`HEX`, `ASC`, `EXT`, `CAS`, …). |
| `P_BYTES` | Raw bytes. The label is defined, then each byte is emitted. |
| `P_ALIGN` | Pad the PC up to a multiple of the count. Optional fill byte. Count and fill are expressions. A count of 0 or 1 does nothing. The count is capped at `$10000`. |
| `P_IF` / `P_ELSE` / `P_ENDIF` | Conditional. Labels on these lines are not defined. |
| `P_LUP` / `P_ENDLUP` | Loop. Labels on these lines are not defined. |

For every op except the ones called out above, a label is defined at the
current PC before the opcode runs. `EQU` / `=` / `GEQU` / `GEQ` are the
exception: the label gets the expression value, not the PC.

`P_IF` / `P_ELSE` / `P_ENDIF` / `P_LUP` do not define a label. `P_END` does,
then assembly stops. Lines after `END` are ignored.

### Conditionals

`DO` and `IF` push a conditional level (maximum 15). The parent level must
already be emitting, and the test must be true, before the body emits.

Merlin character `IF` is special. It applies only when the opcode text is
`IF` and the second character of the operand is `,` or `=`. The first
character of the operand is compared with the first character of the rest.
No expression is evaluated. `IF "=]1"` and `IF #,]1` are this form.
`IF 1+1` is an expression, because the second character is `+`.

ORCA/M, LISA, and ca65 expression tests are emitted with opcode `DO`, so
the character form does not apply to them. A Merlin source `IF` stays `IF`.

`ELSE` emits when the parent is emitting and the matching test was false.
`FIN` pops one level. A false branch still defines labels. The PC does not
move, and instructions and data do not emit. `ORG`, `EQU`, `MX`, `XC`,
`CAS`, `DUM`, `DEND`, `REL`, `EXT`, `ENT`, `LNK`, `TYP`, `DSK`, and `SAV`
still take effect inside a false branch. `VAR`, `FLO`, `DATE`, `HEX`,
`CHK`, data, strings, `DS`, `ERR`, and `USR` do not.

### Loops

`LUP n` evaluates `n` once. A negative count runs zero times. The count is
capped at `$8000`. The loop runs even when the surrounding conditional is
false. Instructions inside still obey the conditional.

`@` in a label, opcode, operand, or stored expression becomes a letter for
that iteration: Z, Y, X, … down to A, then A again after 26. The file name
is left alone. An outer `LUP` replaces `@` in the inner body, including
the inner loop's own `@`, before the inner loop runs. That is Merlin's
text substitution.

ca65 `.repeat` is the same loop. A `@` in a `.repeat` body is still
replaced.

### Macros

Macros are expanded while the source is lowered, not while pcode runs.
The assembler's own macro table stays empty. A name that was not expanded
is assembled as an instruction and fails if it is not a mnemonic.

An expansion is refused when it is already nested more than 16 deep.
Merlin and ca65 put the call-site label on its own `P_LABEL` (or a
`P_NOP` when there is no label). That label is not attached to the first
instruction of the body. ORCA/M does that only when the prototype has no
`&lab` parameter. When `&lab` is declared, the call-site label is
substituted for `&lab` in the body and is not also defined on its own.
Body lines are listed from the substituted fields.

Merlin parameters are `]1`–`]9`, split on `;`. A `]` variable that is not
a parameter stays text and is looked up when the line assembles, so `VAR`
and a later `PUT` still work. Labels in the body are renamed to `ozunid_N`
once, at expansion time, so both passes see the same names. `]` locals,
`:` locals, and `EQU` / `=` labels are not renamed. `*` in an operand stays
an expression and is the PC at the moment that line assembles.

A macro whose name is also an instruction (`inc` calling `inc`) expands
until the depth limit, then errors with "macro nest too deep".

`CAS` is recorded when the front end sees it, so later macro lookup in
that file follows the same case rule the assembler will use. The `CAS`
line is also in the pcode and runs again during assembly.

## Expressions

Merlin operands are copied through unchanged. Evaluation is left to right
with no precedence: `1+2*3` is 9. `{1+2*3}` is 7. `--algebraic` turns on
precedence for every Merlin expression. Parentheses are addressing, not
grouping.

ca65 and ORCA/M expressions are rewritten into fully parenthesized Merlin
before they are assembled. `1+2*3` becomes `{1+{2*3}}` and is 7.
`(1+2)*3` becomes `{{1+2}*3}` and is 9. A number or a bare name is left
unwrapped. On a parse failure the original text is kept.

| Source | Merlin text |
| --- | --- |
| `a\|b`, `a \|\| b`, `.or`, `.bitor` | `{a.b}` (OR) |
| `a^b`, `.xor`, `.bitxor`, `.eor` | `{a!b}` (XOR) |
| `a&b`, `a&&b`, `.and`, `.bitand` | `{a&b}` (AND) |
| `a<>b` | `{a#b}` (not equal) |
| `a<=b` | `{{a<b}.{a=b}}` |
| `a>=b` | `{{a>b}.{a=b}}` |
| `~x` | `{x!-1}` |
| `<x`, `.lobyte(x)` | low byte |
| `>x`, `.hibyte(x)` | high byte |
| `^x`, `.bankbyte(x)` | bank byte |
| `*` | program counter |

The rewrite is applied to the expression inside an operand, not to the
addressing punctuation. `(dp),y` stays indirect indexed. `z:`, `a:`, `f:`,
`zeropage:`, `direct:`, `absolute:`, `near:`, and `far:` become Merlin
force prefixes `<`, `|`, and `>`.

LISA expressions stay left to right. They are not rewritten.

`<<` and `>>` are not rewritten. The original text is handed to the Merlin
evaluator, which has no shift operator. `->` is left as source text for
the same reason.

## Includes

Search order: the directory of the file that contains the directive, then
each `-I` directory, then `.`. For each name the assembler also tries
`.s`, `.S`, `.Macs`, and `.Macs.s`. A Merlin prefix `4/Mem.Macs` is tried
again without the `4/`. Quotes around the name are stripped. An include
cycle is an error. Nesting stops at 16.

`PUT`, `USE`, ORCA/M `COPY` / `APPEND` / `MCOPY`, and ca65 `.include` are
pulled in while the file is lowered. That happens before conditionals run,
so the included file is assembled even when the directive sits in a false
`DO` / `IF`. `USE` only collects macros. The other forms assemble the
included code at the point of the directive.

## Merlin and Merlin 32 pseudo-ops

These are the operations the assembler executes. Merlin 32 is the same
set. `GEQU` and `GEQ` are equates, and they also mark the file as
Merlin 32 during identification. The line format is `doc/DIALECT.md`.

A label on `END` is defined. A label on `DO`, `IF`, `ELSE`, `FIN`, `LUP`,
or `--^` is not.

| Directive | Treatment |
| --- | --- |
| `ORG expr` | Sets the PC. The first `ORG` also sets the object origin. A later `ORG` saves the PC, and a bare `ORG` restores that saved PC once. `ORG` inside `DUM` moves the PC and leaves the saved PC alone. Object bytes stay one stream; `ORG` does not insert a gap in the file. |
| `EQU` `=` `GEQU` `GEQ` | Define the label as the expression. A label that starts with `]` is a variable and may be redefined. |
| `MX expr` | Sets `MX` to the value anded with 3. An empty operand is `%11`. |
| `XC` | `XC OFF` selects the 6502. Any other `XC` steps 6502 → 65C02 → 65816 and then stays there. |
| `CAS SE` / `CAS IN` | Case-sensitive or case-insensitive symbols. The first two letters decide. |
| `DUM expr` / `DEND` | `DUM` saves the PC, sets `dummy`, and moves the PC to the expression. Bytes are not stored. `DEND` restores the PC. |
| `REL` | Marks the assembly relocatable for symbol lookup. If there has been no `ORG`, the PC and origin become 0. Unknown labels are 0. No relocatable records are written. |
| `EXT a,b,c` | Defines each name as 0. A label on the line is also 0. |
| `ENT` / `LNK` | A label on the line is defined at the PC. No relocation record. |
| `LEN` / `POS` | Defines the operand (or the line label) as 0. |
| `CHK` | Emits one byte, the XOR of object bytes since the last `ORG`. |
| `USR` | Emits two zero bytes. The operand is ignored. In a false conditional this emits nothing. |
| `HEX` | Hex digit pairs. Spaces and commas are skipped. An odd digit count is an error. |
| `DFB` `DB` | One byte per expression. |
| `DA` `DW` | Little-endian word per expression. |
| `DDB` | Big-endian word per expression. |
| `ADR` | Three-byte address. |
| `ADRL` | Four-byte address. |
| `DS n` / `DS n,fill` | `n` bytes of `fill` (default 0). `DS \` aligns to the next page boundary (256 bytes when already aligned). `n` is capped at `$10000`. |
| `ASC` `STR` `DCI` `INV` `FLS` `REV` `STRL` | String data. Single quotes are plain ASCII. Double quotes set bit 7. See `doc/DIALECT.md` for hex mixed into the string and for `STRL`. |
| `FLO` | Ten-byte SANE extended. |
| `DATE` | Nine-byte date. Modes 1–8. See `doc/DIALECT.md`. |
| `ERR expr` | Error on pass 2 when the expression is non-zero. |
| `PUT` | Assemble the included file at this point. This happens while the file is lowered, so a `PUT` in a false conditional is still included. |
| `USE` | Load macros from the file. Its code is not assembled. Collected the same way as `PUT`, including inside a false conditional. |
| `VAR e1;e2;…` | Set variables `]1`…`]9`. Empty arguments stop the list. Skipped in a false conditional. |
| `DSK` / `SAV` | Output file name. Surrounding quotes are removed. |
| `TYP` | File type. `$B3` or a name: `BIN` `$06`, `SYS` `$FF`, `S16`/`SYS16` `$B3`, `CDA` `$B9`, `NDA` `$B8`, `EXE` `$B5`, `TXT` `$04`, `SRC` `$B0`, `LNK` `$2E`. |
| `MAC` … `EOM` or `<<<` | Macro definition. The body is not assembled at the definition. |
| `PMC name args` / `>>>` | Call that macro. The name is the first word of the operand. |
| `DO` / `IF` / `ELSE` / `FIN` | Conditionals, as above. |
| `LUP n` … `--^` | Loop, as above. A stray `--^` is ignored. |
| `END` | Stop assembly. |
| `LST` `EXP` `TR` `PAU` `PAG` `AST` `SKP` `KBD` `OBJ` `DAT` `OVR` `ASM` `SYM` `CYC` | No object bytes. A label is still defined at the PC. |

`ASL A` (and the other accumulator ALU mnemonics with a lone `A`) is the
accumulator form. A bare mnemonic is the same form.

## ORCA/M

The Merlin line parser is used, then a column fix. A trailing `:` on a
label is removed. A directive written in the label column is shifted into
the opcode column, so `longa off` at column 0 works. `start anop` stays a
label plus `ANOP`, because both words are directives and the line is not
shifted.

Expressions in operands are algebraic, as above.

| Directive | Treatment |
| --- | --- |
| `ORG` | Merlin `ORG` with an algebraic expression. |
| `EQU` `GEQU` | Merlin equate. The operand is algebraic. |
| `DS` | Merlin `DS`. Each comma-separated expression is algebraic. |
| `DC` | One or more typed constants. See the next table. The label goes on the first item. |
| `LONGA` / `LONGI` | `ON`, `YES`, or `1` selects 16-bit (that `MX` bit clears). Any other operand, including `OFF` and an empty operand, selects 8-bit. |
| `IF` / `ELSE` / `ENDC` / `FIN` / `ENDIF` | Merlin `DO` / `ELSE` / `FIN`. The test is algebraic. |
| `EXTERN` | Merlin `EXT`. Each name is 0. |
| `ENTRY` | Label only. |
| `ALIGN n` / `ALIGN n,fill` | `P_ALIGN`. An empty count is 2. |
| `CASE ON` | `CAS SE`. Any other operand is `CAS IN`. |
| `MACHINE` | `6502` or `65C02` selects that CPU. Anything else, including `65816`, selects the 65816. `65C02` is recognized as the 65C02. |
| `START` `DATA` `PRIVATE` `PRIVDATA` `ANOP` | Label only. They do not open a segment or change the PC. |
| `MACRO` / `MEND` / `ENDM` | Macro. The next non-blank line is the prototype: the opcode is the name, a label `&lab` receives the call-site label, and the operand is the parameter list. Names in the body that start with `&` are replaced, longest first. |
| `COPY` `APPEND` `MCOPY` | Include and assemble as ORCA/M. Macros in the file are collected. |
| `USING` `EJECT` `OBJ` `OBJEND` `KEEP` `MERR` `MEM` | No bytes. A label is kept. |
| `END` | Stop assembly. |
| `AIF` `AGO` `AELSE` `AEND` `AWHILE` `SETA` `SETB` `SETC` `LCLA` `LCLB` `LCLC` `GBLA` `GBLB` `GBLC` `MNOTE` `MEXIT` `ACTR` `DIRECT` `KIND` `RENAME` `SETCOM` | Error: unsupported ORCA directive. A label on the line is kept. |

`DC` types, written `type'value'` or `type"value"`:

| Type | Bytes |
| --- | --- |
| `C` | Characters. A value with no embedded quote becomes Merlin `ASC` in single quotes. Any other value is raw bytes. |
| `H` | Hex digits. Spaces and commas inside the quotes are removed, then Merlin `HEX`. |
| `I1` `B` | One byte per comma-separated expression (`DFB`). |
| `I` `I2` `A` `R` | One little-endian word per expression (`DA`). `R` is not a relocation; it is a word. |
| `I3` | Three-byte address (`ADR`). |
| `I4` | Four-byte address (`ADRL`). |

An unknown `DC` type, or a type that is not followed by a quote, is an
error. Several specs may share one `DC` line, separated by commas outside
the quotes: `dc i1'1,2',i2'$10',c'A',h'0d'` is `01 02 10 00 41 0D`.

Instruction operands are algebraic in the expression only.
`jsr bell` stays `JSR bell`.

## LISA

The Merlin line parser is used. A trailing `:` on a label is removed. A
label that starts with `.` is a directive that was written in column 0; it
is shifted into the opcode column. One leading dot is stripped and the
opcode is uppercased, so `.OR`, `.EQ`, and `OR` are the same directive.
Instruction mnemonics keep their original spelling. The encoder is
case-insensitive.

Expressions stay left to right. There is no macro language.

| Directive | Treatment |
| --- | --- |
| `.OR` `.ORG` | Merlin `ORG`. |
| `.EQ` `.EQU` | Merlin `EQU`. |
| `.EP` `.EPZ` | Merlin `EQU`, and the label is remembered. A later instruction whose entire address expression is that name is forced to direct page, even when the value is greater than 255. `EPZ $1234` then `LDA ZP` is `A5 34`. |
| `.DA` | Split on commas. A quoted item is `ASC`. `#expr` is `DFB` (one byte). `/expr` is `DFB >expr` (high byte). Anything else is a word (`DA`). The label goes on the first item. |
| `.DB` `.BY` `.BYT` `.BYTE` `.DFB` | `DFB`. An item that starts with `/` becomes `>item`. |
| `.HS` `.HEX` | Merlin `HEX`. |
| `.AS` `.ASC` `.AT` | Merlin `ASC`. |
| `.BS` `.BLK` `.DFS` `.DS` | Merlin `DS`. |
| `.IF` / `.EL` or `.ELSE` / `.FI` or `.FIN` | Merlin `DO` / `ELSE` / `FIN`. The test is left to right. |
| `.EN` `.END` | Stop assembly. |
| `.STR` `.DCI` `.INV` | The same Merlin string directives. |
| anything else with an opcode | Instruction. A leading `/` on the operand becomes `#>`, the high-byte immediate. |

## ca65

ca65 has its own line parser. `;` starts a comment outside quotes.
`name:` is a label. `name = expr` and `name := expr` are equates.
A directive starts with `.`. The first pcode operation of every ca65 file
is `CAS SE`, so symbols and macro names are case-sensitive before the
first user line. `--case-sensitive` is then redundant for ca65.

Expressions are algebraic. `.repeat` is `LUP` and has no ca65-style
counter variable. `@` in the body is still the Merlin loop letter.

| Directive | Treatment |
| --- | --- |
| `.ORG` | Merlin `ORG`, algebraic. |
| `=` `.EQU` | Merlin `=`, algebraic. |
| `.SET name, expr` | The same equate. On pass 1 a later `.SET` of the same name replaces the value. Pass 2 keeps that last value for the whole file, so a `.SET` does not take effect in the middle of pass 2. |
| `.BYTE` `.BYT` | `DFB` for numbers and expressions. `"..."` is raw ASCII bytes, with `\\` `\"` `\'` `\n` `\r` `\t`. A one-character `'A'` stays an expression. A longer single-quoted string is raw bytes. The label goes on the first item. |
| `.WORD` `.ADDR` | Little-endian words (`DA`). |
| `.FARADDR` | Three-byte addresses (`ADR`). |
| `.DWORD` `.LONG` | Four-byte values (`ADRL`). |
| `.RES` `.DS` | Merlin `DS`. Each part is algebraic. |
| `.ALIGN n` / `.ALIGN n,fill` | `P_ALIGN`. An empty count is 2. |
| `.A8` `.A16` `.I8` `.I16` | Set the M bit (`.A*`) or the X bit (`.I*`). 8 sets the bit. 16 clears it. |
| `.P816` | CPU 65816. |
| `.P02` | CPU 6502. |
| `.PC02` | CPU 65C02. |
| `.SETCPU` | `65C02` or `65SC02` selects the 65C02. `6502` selects the 6502. Anything else selects the 65816. |
| `.IF` `.IFNE` | Merlin `DO`. Non-zero is true. Algebraic. An empty test is 1. |
| `.IFEQ` | True when the expression is 0. |
| `.ELSE` / `.ENDIF` `.FI` | Merlin `ELSE` / `FIN`. |
| `.ELSEIF` | Error. The line emits nothing. |
| `.END` | Stop assembly. |
| `.PROC` `.SCOPE` | Label only, from the label or from the operand. No scope is pushed. `.ENDPROC` and `.ENDSCOPE` are ignored. |
| `.IMPORT` `.IMPORTZP` | Merlin `EXT`. A `:size` suffix on a name is removed. The name is 0. `.IMPORTZP` does not force direct page. |
| `.INCLUDE` | Include and assemble as ca65. |
| `.MACRO` … `.ENDMACRO` or `.ENDMAC` | Macro. Parameters are whole identifiers, case-sensitive, longest first. The call `name arg,arg` matches. |
| `.REPEAT` … `.ENDREPEAT` or `.ENDREP` | `LUP`. The count is algebraic. |
| `.ERROR` | The operand is recorded as an error. |
| `.SMART` `.FEATURE` `.LIST` `.DEBUGINFO` `.ASSERT` `.LOCAL` `.SEGMENT` `.CODE` `.DATA` `.RODATA` `.BSS` `.ZEROPAGE` `.ENDPROC` `.ENDSCOPE` `.EXPORT` `.EXPORTZP` `.GLOBAL` `.CASE` `.WARNING` `.OUT` | No bytes. A label is defined. Segments do not move the PC or change the origin. |
| any other `.directive` | Error: unsupported ca65 directive. A label is kept. |
| a line that is only a label | Defines the label at the PC. |

Size prefixes on an instruction operand (`lda z:label`, `lda f:addr`)
become Merlin `<` / `|` / `>`.

## Object and listing

The object is the bytes emitted on pass 2, in order. `ORG` changes the PC
and the recorded origin. It does not pad the file. `DUM` moves the PC
without storing bytes. The default origin is `$8000` when no `ORG` and no
`REL` ran. `REL` with no `ORG` records origin 0.

`DSK` or `SAV` names the output file when `-o` is absent. Otherwise the
output is `<source>.bin`. The listing is `<source>.lst` unless `-l` or
`--no-lst` is set. `TYP` changes the type printed in the status line and
stored on `Result`. It does not wrap the bytes in an OMF record.

The pcode dump is one line per operation: file, line, op name, label,
opcode, operand, and for instructions the addressing form and expression.
`P_MXPART`, `P_CPU`, and `P_BYTES` add their mask, CPU, or hex bytes.

## Limitations

These are properties of this assembler, not of the original dialects.

- The object is absolute BIN. `REL`, `ENT`, `EXT`, `.IMPORT`, and `DC R`
  do not produce OMF or Linker.GS records. External and unknown relocatable
  names are 0.
- ORCA/M segments (`START`, `DATA`, `PRIVATE`, `PRIVDATA`) and ca65
  segments (`.SEGMENT`, `.CODE`, `.DATA`, `.RODATA`, `.BSS`, `.ZEROPAGE`)
  are one flat PC. They do not change the origin.
- ORCA/M conditional macro language is rejected: `AIF`, `AGO`, `SETA`,
  `LCLA`, and the related directives listed above.
- ca65 anonymous labels (`:`, `:+`, `:-`), `.ELSEIF`, and scoped `.PROC`
  / `.LOCAL` symbols are not implemented. `.LOCAL` is ignored.
- ca65 `.SMART`, `.FEATURE`, and listing controls do not change encoding
  or the listing.
- ca65 `.IMPORTZP` defines the symbol as 0 and leaves addressing to the
  value and to any `z:` prefix. It does not remember the name the way
  LISA `.EPZ` does.
- Shift operators and `->` are not rewritten into Merlin expressions.
- There is no separate ca65 or ORCA/M operator for true logical AND/OR
  that yields only 0 or 1 beyond the bitwise operators above. `&&` and
  `||` are bitwise AND and OR.
- `PUT`, `USE`, `COPY`, `MCOPY`, `APPEND`, and `.include` are expanded
  while lowering, including inside a false conditional.
- A macro that calls its own name recurses until the depth limit, then errors.
- ca65 `.SET` updates the symbol on pass 1. Pass 2 uses the final pass-1
  value everywhere, including at lines that appear before the later `.SET`.
- `@` inside ca65 `.repeat` is the Merlin loop letter.
- Nested `LUP` bodies share one `@`. The outer loop substitutes first.
- Loop count maximum is `$8000`. Conditional nesting maximum is 15.
  An include or macro expansion is refused when it is already nested more
  than 16 deep. `DS` and `ALIGN` counts are capped at `$10000`.
- Only the first 26 `LUP` iterations get a distinct `@` letter.
- Identification is a heuristic. A file with no distinctive token is
  Merlin. `--syntax` or a `syntax:` marker is the reliable override.
  `START` alone does not select ORCA/M.
- Native high-bit Merlin text is Merlin even if later lines look like
  another dialect, unless a marker in the first 40 lines already matched.
- Empty `LONGA` / `LONGI` selects 8-bit. Only `ON`, `YES`, and `1` select
  16-bit.
- LISA has no macros and no algebraic expressions.
- Merlin 32 is not a second encoder. It is Merlin 16+ with a different
  syntax name, plus `GEQU` / `GEQ` as equates.
