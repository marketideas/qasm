#pragma once

/* Common 65816 pcode.
   Each front end (Merlin, Merlin 32, ORCA/M, LISA, ca65) lowers a source
   file to this stream. The assembler in assemble.cpp executes the stream:
   two passes, symbols, MX/CPU, opcode encoding, listing, absolute object.
   Line-like ops carry a Merlin opcode and operand because that is the
   form the encoder already evaluates. Control ops (IF/LUP/...) are
   executed directly. Expressions from algebraic dialects are rewritten
   into fully parenthesized Merlin expressions before they get here. */

#include "intern.hpp"

#include <cstdint>
#include <string>
#include <vector>

namespace merlin {

enum class Syntax {
    Merlin = 0,
    Merlin32,
    Orca,
    Lisa,
    Ca65
};

enum class POp : uint16_t {
    Nop = 0,
    End,
    Label,
    Org,
    Equ,
    Mx,
    Xc,
    MxPart, /* i0 = mx bit mask, i1 = new bits. bit1 (2) is M, bit0 (1) is X */
    Cpu,    /* i0 = CPU_6502 / CPU_65C02 / CPU_65816 */
    Inst,
    Data,
    Ds,
    Asm,
    Bytes,
    Align, /* operand = count expr, expr2 = fill expr */
    If,
    Else,
    Endif,
    Lup,
    Endlup
};

struct PInstr {
    POp op = POp::Nop;
    std::string opcode;
    std::string operand;
    std::string label;
    std::string source;
    std::string file;
    int lineno = 0;
    int i0 = 0;
    int i1 = 0;
    /* Canonical view of an instruction, filled for P_INST. */
    std::string cname;
    int syntax = 0;
    int force = 0;
    int byte_sel = 0;
    bool long_mn = false;
    std::string expr;
    std::string expr2;
    std::vector<uint8_t> raw;
};

struct PCode {
    Syntax syntax = Syntax::Merlin;
    std::string name;
    std::vector<PInstr> ins;
    std::vector<Error> errors;
};

const char *syntax_name(Syntax s);
/* Empty or "auto" leaves *ok true and returns Merlin only as a placeholder;
   callers should identify instead. Unknown text sets *ok false. */
Syntax syntax_from_name(const std::string &name, bool &ok);

Syntax identify_syntax(const std::string &src);

/* tilde_name: ORCA/M `~label` stays a symbol. Otherwise `~x` is bitwise NOT. */
std::string translate_algebraic(const std::string &expr, bool tilde_name = false);
std::vector<std::string> split_args(const std::string &s, char sep = ',');
std::string form_operand(const OperandForm &f);
void annotate_inst(PInstr &in);
std::string format_pcode(const PCode &code);

PCode compile_source(const std::string &src, const std::string &name, const Options &opt);
void merlin_compile(const std::vector<SrcLine> &lines, const Options &opt, PCode &code);
void orca_compile(const std::string &src, const std::string &name, const Options &opt, PCode &code);
void lisa_compile(const std::string &src, const std::string &name, const Options &opt, PCode &code);
void ca65_compile(const std::string &src, const std::string &name, const Options &opt, PCode &code);

Result assemble_pcode(PCode &code, const Options &opt);

} // namespace merlin
