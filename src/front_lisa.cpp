#include "pcode.hpp"

#include <cctype>

namespace merlin {

static std::string upper_op(std::string s)
{
    if (!s.empty() && s[0] == '.') s.erase(s.begin());
    for (char &c : s)
        c = static_cast<char>(std::toupper(static_cast<unsigned char>(c)));
    return s;
}

static void fix_lisa(SrcLine &ln)
{
    if (ln.is_comment) return;
    if (ln.has_label && !ln.label.empty() && ln.label.back() == ':') {
        ln.label.pop_back();
        ln.has_label = !ln.label.empty();
    }
    if (ln.has_label && !ln.label.empty() && ln.label[0] == '.') {
        if (ln.operand.empty()) {
            ln.operand = ln.opcode;
            ln.opcode = ln.label;
        } else {
            ln.operand = ln.opcode + " " + ln.operand;
            ln.opcode = ln.label;
        }
        ln.label.clear();
        ln.has_label = false;
    }
}

static bool is_zp_name(const std::vector<std::string> &zp, const std::string &name)
{
    if (name.empty()) return false;
    for (const auto &z : zp)
        if (icmp(z, name) == 0) return true;
    return false;
}

static std::string apply_zp(const std::string &operand, const std::vector<std::string> &zp)
{
    if (operand.empty()) return operand;
    std::string opnd = operand;
    if (opnd[0] == '/' && (opnd.size() == 1 || opnd[1] != '/'))
        opnd = "#>" + opnd.substr(1);
    OperandForm f = parse_operand_form(opnd);
    if (f.force == FORCE_NONE && f.syntax != SYN_IMM && f.syntax != SYN_IMP &&
        is_zp_name(zp, f.expr)) {
        f.force = FORCE_DP;
        return form_operand(f);
    }
    if (opnd != operand) return opnd;
    return operand;
}

static void push(PCode &code, const SrcLine &ln, POp op, const std::string &opcode,
                 const std::string &operand, bool keep_label)
{
    PInstr in;
    in.op = op;
    in.opcode = opcode;
    in.operand = operand;
    if (keep_label && ln.has_label) in.label = ln.label;
    in.source = ln.raw;
    in.file = ln.file;
    in.lineno = ln.lineno;
    if (op == POp::Inst) annotate_inst(in);
    code.ins.push_back(std::move(in));
}

static void emit_da(PCode &code, const SrcLine &ln)
{
    auto parts = split_args(ln.operand, ',');
    if (parts.empty()) {
        push(code, ln, POp::Nop, {}, {}, true);
        return;
    }
    bool first = true;
    for (const auto &p0 : parts) {
        std::string p = trim_copy(p0);
        if (p.empty()) continue;
        SrcLine bit = ln;
        bit.raw = first ? ln.raw : std::string();
        bit.has_label = first && ln.has_label;
        bit.label = bit.has_label ? ln.label : std::string();
        first = false;
        if (p[0] == '\'' || p[0] == '"') push(code, bit, POp::Asm, "ASC", p, true);
        else if (p[0] == '#') push(code, bit, POp::Data, "DFB", p, true);
        else if (p[0] == '/') push(code, bit, POp::Data, "DFB", ">" + p.substr(1), true);
        else push(code, bit, POp::Data, "DA", p, true);
    }
}

void lisa_compile(const std::string &src, const std::string &name, const Options &opt, PCode &code)
{
    (void)opt;
    auto lines = parse_source(src, name);
    std::vector<std::string> zp;
    for (auto ln : lines) {
        fix_lisa(ln);
        if (ln.is_comment || (ln.opcode.empty() && !ln.has_label)) {
            push(code, ln, POp::Nop, {}, {}, false);
            continue;
        }
        std::string op = upper_op(ln.opcode);
        if (op == "OR" || op == "ORG") {
            push(code, ln, POp::Org, "ORG", ln.operand, true);
        } else if (op == "EQ" || op == "EQU") {
            push(code, ln, POp::Equ, "EQU", ln.operand, true);
        } else if (op == "EP" || op == "EPZ") {
            if (ln.has_label) zp.push_back(ln.label);
            push(code, ln, POp::Equ, "EQU", ln.operand, true);
        } else if (op == "DA") {
            emit_da(code, ln);
        } else if (op == "DB" || op == "BY" || op == "BYT" || op == "BYTE" || op == "DFB") {
            auto parts = split_args(ln.operand, ',');
            std::string joined;
            for (const auto &p0 : parts) {
                std::string p = trim_copy(p0);
                if (p.empty()) continue;
                if (!joined.empty()) joined += ",";
                if (!p.empty() && p[0] == '/') joined += ">" + p.substr(1);
                else joined += p;
            }
            push(code, ln, POp::Data, "DFB", joined, true);
        } else if (op == "HS" || op == "HEX") {
            push(code, ln, POp::Asm, "HEX", ln.operand, true);
        } else if (op == "AS" || op == "ASC" || op == "AT") {
            push(code, ln, POp::Asm, "ASC", ln.operand, true);
        } else if (op == "BS" || op == "BLK" || op == "DFS" || op == "DS") {
            push(code, ln, POp::Ds, "DS", ln.operand, true);
        } else if (op == "IF") {
            push(code, ln, POp::If, "DO", ln.operand.empty() ? "1" : ln.operand, true);
        } else if (op == "EL" || op == "ELSE") {
            push(code, ln, POp::Else, "ELSE", {}, false);
        } else if (op == "FI" || op == "FIN") {
            push(code, ln, POp::Endif, "FIN", {}, false);
        } else if (op == "EN" || op == "END") {
            push(code, ln, POp::End, "END", {}, true);
        } else if (op == "STR" || op == "DCI" || op == "INV") {
            push(code, ln, POp::Asm, op, ln.operand, true);
        } else if (ln.opcode.empty()) {
            push(code, ln, POp::Label, {}, {}, true);
        } else {
            push(code, ln, POp::Inst, ln.opcode, apply_zp(ln.operand, zp), true);
        }
    }
}

} // namespace merlin
