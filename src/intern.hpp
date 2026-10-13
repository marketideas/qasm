#pragma once

#include "merlin.hpp"

#include <cstdint>
#include <string>
#include <vector>

namespace merlin {

constexpr int kMaxCond = 16;

enum {
    CPU_6502 = 0,
    CPU_65C02 = 1,
    CPU_65816 = 2
};

enum AddrMode {
    AM_NONE = 0,
    AM_IMP,
    AM_IMM,
    AM_IMM8,
    AM_IMM16,
    AM_DP,
    AM_DPX,
    AM_DPY,
    AM_IND,
    AM_INDX,
    AM_INDY,
    AM_INDL,
    AM_INDLY,
    AM_ABS,
    AM_ABSX,
    AM_ABSY,
    AM_LONG,
    AM_LONGX,
    AM_SR,
    AM_SRIY,
    AM_REL,
    AM_RELL,
    AM_ABSIND,
    AM_ABSINDX,
    AM_ABSINDL,
    AM_BLK,
    AM_COUNT
};

enum {
    SYN_IMP = 0,
    SYN_IMM,
    SYN_ABS,
    SYN_X,
    SYN_Y,
    SYN_S,
    SYN_IND,
    SYN_INDX,
    SYN_INDY,
    SYN_INDL,
    SYN_INDLY,
    SYN_SIY,
    SYN_BLK
};

enum {
    FORCE_NONE = 0,
    FORCE_DP,
    FORCE_ABS,
    FORCE_LONG
};

struct SrcLine {
    std::string file;
    int lineno = 0;
    std::string raw;
    std::string label;
    std::string opcode;
    std::string operand;
    bool has_label = false;
    bool is_comment = false;
};

struct OperandForm {
    int syntax = SYN_IMP;
    int force = FORCE_NONE;
    int byte_sel = 0;
    std::string expr;
    std::string expr2;
};

struct ListLine {
    uint32_t pc = 0;
    std::vector<uint8_t> bytes;
    std::string source;
    int lineno = 0;
};

int icmp(const std::string &a, const std::string &b);
int icmp(const char *a, const char *b);
int nicmp(const std::string &a, const char *b, size_t n);
std::string trim_copy(std::string s);
bool is_eol(unsigned char c);
bool is_field_tab(unsigned char c);
unsigned char to_ascii(unsigned char c);
std::string read_file(const std::string &path, std::string *err);
std::string replace_ext(const std::string &path, const std::string &ext);
std::string dirname_of(const std::string &path);
std::string strip_quotes(std::string s);
bool file_readable(const std::string &path);
std::string resolve_include(const std::string &name, const std::string &from_file,
                            const std::vector<std::string> &include_dirs);

std::vector<SrcLine> parse_source(const std::string &src, const std::string &name);
SrcLine parse_line_text(const std::string &text);
OperandForm parse_operand_form(const std::string &operand);

struct ExprCtx {
    uint32_t pc = 0;
    int mx = 3;
    bool algebraic = false;
    bool case_sensitive = false;
    bool rel = false; /* REL files: undefined names are implicit EXT = 0 */
    int pass = 1;
    void *asm_ptr = nullptr;
    int (*lookup)(void *asm_ptr, const std::string &name, int64_t *val, bool *known) = nullptr;
};

bool eval_expr(ExprCtx &ctx, const std::string &expr, int64_t &out, std::string &err);

std::string opcode_canonical(const std::string &name, int &force_out, bool &long_mn);
int opcode_encode(const std::string &cname, AddrMode am, int cpu, uint8_t &opc);
bool opcode_supports(const std::string &cname, AddrMode am, int cpu);
bool is_branch(const std::string &cname);
bool is_branch_long(const std::string &cname);
bool is_alu_acc(const std::string &cname);
int imm_width_reg(const std::string &cname);

Result assemble_lines(std::vector<SrcLine> &lines, const Options &opt);

bool is_pseudo_op(const std::string &op);

std::string format_listing(const std::string &name, const Result &r,
                           const std::vector<ListLine> &lines,
                           const std::string &syntax = {});

} // namespace merlin
