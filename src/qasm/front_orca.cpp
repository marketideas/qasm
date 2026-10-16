#include "pcode.hpp"

#include <algorithm>
#include <cctype>
#include <map>

namespace qasm {

static bool orca_dir(const std::string &t)
{
    static const char *d[] = {
        "START", "END", "DATA", "PRIVATE", "PRIVDATA", "LONGA", "LONGI", "DC", "DS",
        "EQU", "GEQU", "ORG", "ENTRY", "EXTERN", "ANOP", "MACRO", "MEND", "ENDM",
        "IF", "ELSE", "ENDC", "FIN", "ENDIF", "COPY", "MCOPY", "USING", "ALIGN",
        "CASE", "MACHINE", "OBJ", "OBJEND", "EJECT", "KEEP", "APPEND", "DIRECT",
        "KIND", "RENAME", "SETCOM", "MERR", "MEM",
        "AIF", "AGO", "AELSE", "AEND", "AWHILE", "SETA", "SETB", "SETC",
        "LCLA", "LCLB", "LCLC", "GBLA", "GBLB", "GBLC", "MNOTE", "MEXIT", "ACTR",
        nullptr
    };
    for (int i = 0; d[i]; i++)
        if (icmp(t, d[i]) == 0) return true;
    return false;
}

/* Directives Apple's APW assembler and the MPW IIgs assembler add on top
   of ORCA/M. They are not ORCA directives: an ORCA file that uses one
   still takes the old path. */
static bool apw_only_dir(const std::string &t)
{
    static const char *d[] = {
        "ABSADDR", "MSB", "CODECHK", "CODECHECK", "DATACHECK", "DATACHK", "DYNCHK",
        "EXPAND", "GEN", "IEEE", "INSTIME", "LIST", "NUMSEX", "OBJCASE",
        "PRINTER", "SYMBOL", "TITLE", "65816", "65C02", "6502",
        "PROC", "ENDP", "ENDPROC", "END_PROC", "FUNC", "ENDF", "ENDFUNC",
        "MAIN", "ENDMAIN", "RECORD", "ENDR", "ENDS", "ENDWITH", "CODE",
        "IMPORT", "EXPORT", "INCLUDE", "STRING", "BLANKS", "PRINT", "SEG",
        "SEGATTR", "PAGESIZE", "SPACE", "SET", "DC.B", "DC.W", "DC.L", "DC.A", "DCB",
        "DCB.B", "DS.B", "DS.W", "DS.L", "AERROR",
        nullptr
    };
    for (int i = 0; d[i]; i++)
        if (icmp(t, d[i]) == 0) return true;
    return false;
}

static bool col_dir(const std::string &t, bool apw)
{
    return orca_dir(t) || (apw && apw_only_dir(t));
}

static bool word_char(unsigned char c)
{
    return std::isalnum(c) || c == '_' || c == '.';
}

/* A trailing THEN is the block-IF keyword. The expression is what remains. */
static bool strip_trailing_then(const std::string &in, std::string &head)
{
    size_t end = in.size();
    while (end > 0 && std::isspace(static_cast<unsigned char>(in[end - 1]))) end--;
    const size_t n = 4;
    if (end < n || icmp(in.substr(end - n, n), "THEN") != 0) return false;
    if (end > n && word_char(static_cast<unsigned char>(in[end - n - 1]))) return false;
    head = trim_copy(in.substr(0, end - n));
    return true;
}

/* `expr GOTO label` skips forward when the expression is true. */
static bool split_goto(const std::string &in, std::string &expr, std::string &label)
{
    bool sq = false, dq = false;
    size_t hit = std::string::npos;
    for (size_t i = 0; i < in.size(); i++) {
        char c = in[i];
        if (!sq && !dq && c == '\'') sq = true;
        else if (!sq && !dq && c == '"') dq = true;
        else if (sq && c == '\'') sq = false;
        else if (dq && c == '"') dq = false;
        else if (!sq && !dq && (c == 'G' || c == 'g') && i + 4 <= in.size() &&
                 icmp(in.substr(i, 4), "GOTO") == 0) {
            bool left = i == 0 || !word_char(static_cast<unsigned char>(in[i - 1]));
            bool right = i + 4 >= in.size() || !word_char(static_cast<unsigned char>(in[i + 4]));
            if (left && right) hit = i;
        }
    }
    if (hit == std::string::npos) return false;
    expr = trim_copy(in.substr(0, hit));
    std::string rest = trim_copy(in.substr(hit + 4));
    if (rest.empty()) return false;
    size_t sp = rest.find_first_of(" \t");
    label = sp == std::string::npos ? rest : rest.substr(0, sp);
    return !label.empty();
}

static bool on_flag(const std::string &operand)
{
    std::string a = trim_copy(operand);
    return icmp(a, "ON") == 0 || icmp(a, "YES") == 0 || a == "1";
}

static void fix_orca(SrcLine &ln, bool apw)
{
    if (ln.is_comment) return;
    if (ln.has_label && !ln.label.empty() && ln.label.back() == ':') {
        ln.label.pop_back();
        ln.has_label = !ln.label.empty();
    }
    if (ln.has_label && col_dir(ln.label, apw) && !col_dir(ln.opcode, apw)) {
        /* A column-1 word that is also a directive stays a label when the
           next field is an instruction: APPEND PHP, PRINT STA, LIST LDA. */
        if (!ln.opcode.empty() && is_mnemonic(ln.opcode)) return;
        if (ln.operand.empty()) ln.operand = ln.opcode;
        else ln.operand = ln.opcode + " " + ln.operand;
        ln.opcode = ln.label;
        ln.label.clear();
        ln.has_label = false;
    }
}

/* A whole item that is '...' or "...". A doubled quote is one quote. */
static bool quoted_item(const std::string &t, std::string &chars)
{
    if (t.size() < 2) return false;
    char q = t[0];
    if (q != '\'' && q != '"') return false;
    std::string out;
    for (size_t i = 1; i < t.size();) {
        if (t[i] == q) {
            if (i + 1 < t.size() && t[i + 1] == q) {
                out.push_back(q);
                i += 2;
                continue;
            }
            if (i + 1 == t.size()) {
                chars = std::move(out);
                return true;
            }
            return false;
        }
        out.push_back(t[i]);
        i++;
    }
    return false;
}

static void append_hex_byte(std::string &o, unsigned char b)
{
    static const char hexd[] = "0123456789ABCDEF";
    o.push_back('$');
    o.push_back(hexd[b >> 4]);
    o.push_back(hexd[b & 0x0F]);
}

/* PROC / FUNC / MAIN operand: `temporg expr` or `org expr`, optional ENTRY. */
static std::string proc_org_expr(const std::string &operand)
{
    const std::string &s = operand;
    for (size_t i = 0; i < s.size();) {
        while (i < s.size() &&
               (std::isspace(static_cast<unsigned char>(s[i])) || s[i] == ','))
            i++;
        if (i >= s.size()) break;
        size_t start = i;
        while (i < s.size() &&
               (std::isalnum(static_cast<unsigned char>(s[i])) || s[i] == '_'))
            i++;
        if (start == i) {
            i++;
            continue;
        }
        std::string w = s.substr(start, i - start);
        if (icmp(w, "temporg") == 0 || icmp(w, "org") == 0) {
            while (i < s.size() && std::isspace(static_cast<unsigned char>(s[i]))) i++;
            size_t e0 = i;
            while (i < s.size() && s[i] != ',') i++;
            return trim_copy(s.substr(e0, i - e0));
        }
    }
    return {};
}

struct Omac {
    std::string name;
    std::string lab;
    std::vector<std::string> params;
    std::vector<SrcLine> body;
};

struct OC {
    const Options *opt = nullptr;
    PCode *out = nullptr;
    std::vector<Omac> macs;
    int depth = 0;
    std::map<std::string, std::vector<SrcLine>> cache;
    std::vector<std::string> opening;
    bool apw = false;
    /* Lowering-time flags. A false IF does not hide them, same as CASE. */
    bool absaddr = false;
    bool msb = false;

    Omac *find_mac(const std::string &name)
    {
        for (auto &m : macs)
            if (icmp(m.name, name) == 0) return &m;
        return nullptr;
    }

    void collect(const std::vector<SrcLine> &ls)
    {
        for (int i = 0; i < static_cast<int>(ls.size()); i++) {
            if (icmp(ls[i].opcode, "MACRO") != 0) continue;
            int j = i + 1;
            while (j < static_cast<int>(ls.size()) &&
                   (ls[j].is_comment || (ls[j].opcode.empty() && !ls[j].has_label)))
                j++;
            if (j >= static_cast<int>(ls.size())) break;
            Omac m;
            m.name = ls[j].opcode;
            m.lab = ls[j].label;
            for (const auto &p : split_args(ls[j].operand, ',')) {
                if (p.empty()) continue;
                m.params.push_back(p[0] == '&' ? p : "&" + p);
            }
            j++;
            for (; j < static_cast<int>(ls.size()); j++) {
                if (icmp(ls[j].opcode, "MEND") == 0 || icmp(ls[j].opcode, "ENDM") == 0)
                    break;
                m.body.push_back(ls[j]);
            }
            if (!m.name.empty() && !find_mac(m.name)) macs.push_back(std::move(m));
            i = j;
        }
    }

    static std::string subst_amp(const std::string &s,
                                 const std::vector<std::pair<std::string, std::string>> &map)
    {
        std::string out;
        for (size_t i = 0; i < s.size(); ) {
            if (s[i] == '&') {
                size_t j = i + 1;
                while (j < s.size()) {
                    unsigned char d = static_cast<unsigned char>(s[j]);
                    if (!std::isalnum(d) && d != '_' && d != '~') break;
                    j++;
                }
                std::string key = s.substr(i, j - i);
                bool hit = false;
                for (const auto &kv : map) {
                    if (icmp(kv.first, key) == 0) {
                        out += kv.second;
                        hit = true;
                        break;
                    }
                }
                if (hit) {
                    i = j;
                    continue;
                }
            }
            out.push_back(s[i++]);
        }
        return out;
    }

    void emit(const SrcLine &ln, POp op, const std::string &opcode, const std::string &operand,
              bool keep_label)
    {
        PInstr in;
        in.op = op;
        in.opcode = opcode;
        in.operand = operand;
        if (keep_label && ln.has_label) in.label = ln.label;
        in.source = ln.raw;
        in.file = ln.file;
        in.lineno = ln.lineno;
        if (op == POp::Inst) annotate_inst(in, false);
        out->ins.push_back(std::move(in));
    }

    std::string alg(const std::string &s) const { return translate_algebraic(s, true); }

    std::string alg_list(const std::string &s) const
    {
        auto parts = split_args(s, ',');
        std::string o;
        for (const auto &p : parts) {
            if (p.empty()) continue;
            if (!o.empty()) o += ",";
            o += alg(p);
        }
        return o;
    }

    /* DC.B items are expressions, or quoted strings of one byte per character.
       MSB ON sets bit 7, the same way DC C does. */
    std::string dc_b_list(const std::string &s) const
    {
        auto parts = split_args(s, ',');
        std::string o;
        auto add = [&](const std::string &p) {
            if (p.empty()) return;
            if (!o.empty()) o.push_back(',');
            o += p;
        };
        for (const auto &p : parts) {
            if (p.empty()) continue;
            std::string chars;
            if (quoted_item(p, chars)) {
                for (unsigned char c : chars) {
                    unsigned char b = msb ? static_cast<unsigned char>(c | 0x80) : c;
                    std::string hex;
                    append_hex_byte(hex, b);
                    add(hex);
                }
            } else {
                add(alg(p));
            }
        }
        return o;
    }

    void emit_ds(const SrcLine &ln, int scale)
    {
        auto parts = split_args(ln.operand, ',');
        std::string count = (parts.empty() || trim_copy(parts[0]).empty())
                                ? std::string("0")
                                : alg(parts[0]);
        std::string oper = scale == 1 ? count
                                      : "{" + count + "}*" + std::to_string(scale);
        if (parts.size() >= 2 && !trim_copy(parts[1]).empty())
            oper += "," + alg(parts[1]);
        emit(ln, POp::Ds, "DS", oper, true);
    }

    std::string alg_addr(const std::string &operand) const
    {
        if (operand.empty()) return operand;
        OperandForm f = parse_operand_form(operand, false);
        /* ABSADDR ON forces an absolute operand. An explicit < | > stays,
           and immediate and implied forms have no absolute width. */
        if (absaddr && f.force == FORCE_NONE && f.syntax != SYN_IMM &&
            f.syntax != SYN_IMP)
            f.force = FORCE_ABS;
        f.expr = alg(f.expr);
        if (!f.expr2.empty()) f.expr2 = alg(f.expr2);
        return form_operand(f);
    }

    bool load(const SrcLine &ln, std::vector<SrcLine> &got)
    {
        std::string path = resolve_include(ln.operand, ln.file.empty() ? "." : ln.file,
                                           opt->include_dirs);
        if (path.empty()) {
            out->errors.push_back({ln.file, ln.lineno,
                                   "cannot open COPY file '" + strip_quotes(ln.operand) + "'"});
            return false;
        }
        for (const auto &p : opening)
            if (icmp(p, path) == 0) {
                out->errors.push_back({ln.file, ln.lineno, "include cycle '" + path + "'"});
                return false;
            }
        auto it = cache.find(path);
        if (it != cache.end()) {
            got = it->second;
            return true;
        }
        std::string err;
        std::string text = read_file(path, &err);
        if (!err.empty() && text.empty()) {
            out->errors.push_back({ln.file, ln.lineno, err});
            return false;
        }
        got = parse_source(text, path, apw);
        for (auto &l : got) fix_orca(l, apw);
        cache[path] = got;
        return true;
    }

    void emit_dc(const SrcLine &ln)
    {
        const std::string &s = ln.operand;
        size_t i = 0;
        bool first = true;
        auto skip = [&]() {
            while (i < s.size() && (s[i] == ' ' || s[i] == '\t')) i++;
        };
        if (trim_copy(s).empty()) {
            emit(ln, POp::Nop, {}, {}, true);
            return;
        }
        while (i < s.size()) {
            skip();
            if (i >= s.size()) break;
            if (s[i] == ',') {
                i++;
                continue;
            }
            size_t t0 = i;
            while (i < s.size() && std::isalnum(static_cast<unsigned char>(s[i]))) i++;
            std::string typ = s.substr(t0, i - t0);
            skip();
            if (typ.empty() || i >= s.size() || (s[i] != '\'' && s[i] != '"')) {
                out->errors.push_back({ln.file, ln.lineno, "bad DC operand"});
                return;
            }
            char q = s[i++];
            size_t v0 = i;
            while (i < s.size() && s[i] != q) i++;
            std::string val = s.substr(v0, i - v0);
            if (i < s.size() && s[i] == q) i++;
            std::string ut = typ;
            for (char &c : ut)
                c = static_cast<char>(std::toupper(static_cast<unsigned char>(c)));
            SrcLine bit = ln;
            if (!first) {
                bit.raw.clear();
                bit.label.clear();
                bit.has_label = false;
            }
            first = false;
            if (ut == "C") {
                bool clean = true;
                for (char c : val)
                    if (c == '\'') clean = false;
                /* MSB ON sets bit 7 on each character. ASC cannot do that
                   for a single-quoted string, so the bytes are raw. */
                if (msb || !clean) {
                    PInstr in;
                    in.op = POp::Bytes;
                    in.source = bit.raw;
                    in.file = bit.file;
                    in.lineno = bit.lineno;
                    if (bit.has_label) in.label = bit.label;
                    for (unsigned char c : val)
                        in.raw.push_back(msb ? static_cast<uint8_t>(c | 0x80) : c);
                    out->ins.push_back(std::move(in));
                } else {
                    emit(bit, POp::Asm, "ASC", "'" + val + "'", true);
                }
            } else if (ut == "H") {
                std::string hex;
                for (char c : val)
                    if (c != ' ' && c != '\t' && c != ',') hex.push_back(c);
                emit(bit, POp::Asm, "HEX", hex, true);
            } else if (ut == "I1" || ut == "B") {
                emit(bit, POp::Data, "DFB", alg_list(val), true);
            } else if (ut == "I" || ut == "I2" || ut == "A" || ut == "R") {
                emit(bit, POp::Data, "DA", alg_list(val), true);
            } else if (ut == "I3") {
                emit(bit, POp::Data, "ADR", alg_list(val), true);
            } else if (ut == "I4") {
                emit(bit, POp::Data, "ADRL", alg_list(val), true);
            } else {
                out->errors.push_back({ln.file, ln.lineno, "unsupported DC type " + typ});
            }
        }
    }

    void mxpart(const SrcLine &ln, int mask, bool on)
    {
        PInstr in;
        in.op = POp::MxPart;
        in.i0 = mask;
        in.i1 = on ? 0 : mask;
        in.source = ln.raw;
        in.file = ln.file;
        in.lineno = ln.lineno;
        if (ln.has_label) in.label = ln.label;
        out->ins.push_back(std::move(in));
    }

    void emit_cpu(const SrcLine &ln, const std::string &cpu_text, bool keep_label)
    {
        PInstr in;
        in.op = POp::Cpu;
        in.i0 = CPU_65816;
        std::string u = cpu_text;
        for (char &c : u)
            c = static_cast<char>(std::toupper(static_cast<unsigned char>(c)));
        if (u.find("6502") != std::string::npos && u.find("65C02") == std::string::npos)
            in.i0 = CPU_6502;
        else if (u.find("65C02") != std::string::npos)
            in.i0 = CPU_65C02;
        in.source = ln.raw;
        in.file = ln.file;
        in.lineno = ln.lineno;
        if (keep_label && ln.has_label) in.label = ln.label;
        out->ins.push_back(std::move(in));
    }

    void one(const SrcLine &ln)
    {
        if (ln.is_comment || (ln.opcode.empty() && !ln.has_label)) {
            emit(ln, POp::Nop, {}, {}, false);
            return;
        }
        const std::string &op = ln.opcode;
        if (icmp(op, "MACRO") == 0) return; /* body skipped by the walker */
        if (icmp(op, "START") == 0 || icmp(op, "DATA") == 0 || icmp(op, "PRIVATE") == 0 ||
            icmp(op, "PRIVDATA") == 0) {
            /* One pcode op: the label stays on this line, and SEG names the
               segment without moving the PC. */
            std::string name = ln.has_label ? ln.label : std::string("CODE");
            bool data = icmp(op, "DATA") == 0 || icmp(op, "PRIVDATA") == 0;
            bool priv = icmp(op, "PRIVATE") == 0 || icmp(op, "PRIVDATA") == 0;
            std::string oper = name + "," + (data ? "DATA" : "CODE");
            if (priv) oper += ",PRIVATE";
            emit(ln, POp::Asm, "SEG", oper, true);
            return;
        }
        if (apw && (icmp(op, "PROC") == 0 || icmp(op, "FUNC") == 0 || icmp(op, "MAIN") == 0)) {
            /* Close a proc that END did not. The joined BASIC sources drop END.
               The proc name is defined before SCOPE, so it stays global. */
            SrcLine bare = ln;
            bare.label.clear();
            bare.has_label = false;
            bare.raw.clear();
            emit(bare, POp::Asm, "UNSCOPE", {}, false);
            std::string orgx = proc_org_expr(ln.operand);
            if (!orgx.empty()) {
                SrcLine orgline = ln;
                orgline.label.clear();
                orgline.has_label = false;
                emit(orgline, POp::Org, "ORG", alg(orgx), false);
                if (ln.has_label) {
                    SrcLine lab = ln;
                    lab.raw.clear();
                    emit(lab, POp::Label, {}, {}, true);
                }
            } else {
                emit(ln, ln.has_label ? POp::Label : POp::Nop, {}, {}, true);
            }
            emit(bare, POp::Asm, "SCOPE", {}, false);
            return;
        }
        if (icmp(op, "ANOP") == 0 ||
            (apw && (icmp(op, "RECORD") == 0 || icmp(op, "CODE") == 0))) {
            emit(ln, ln.has_label ? POp::Label : POp::Nop, {}, {}, true);
            return;
        }
        if (apw && (icmp(op, "ENDP") == 0 || icmp(op, "ENDPROC") == 0 || icmp(op, "END_PROC") == 0 ||
                    icmp(op, "ENDF") == 0 || icmp(op, "ENDFUNC") == 0 || icmp(op, "ENDMAIN") == 0)) {
            /* The label is defined while still inside the proc. */
            emit(ln, POp::Asm, "UNSCOPE", {}, true);
            return;
        }
        if (apw && (icmp(op, "ENDR") == 0 || icmp(op, "ENDS") == 0 || icmp(op, "ENDWITH") == 0)) {
            emit(ln, POp::Nop, {}, {}, true);
            return;
        }
        if (icmp(op, "END") == 0) { emit(ln, POp::End, "END", {}, true); return; }
        if (icmp(op, "ORG") == 0) { emit(ln, POp::Org, "ORG", alg(ln.operand), true); return; }
        if (icmp(op, "EQU") == 0 || icmp(op, "GEQU") == 0 || (apw && icmp(op, "SET") == 0)) {
            emit(ln, POp::Equ, "EQU", alg(ln.operand), true);
            return;
        }
        if (icmp(op, "DS") == 0) { emit(ln, POp::Ds, "DS", alg_list(ln.operand), true); return; }
        if (apw && (icmp(op, "DS.B") == 0 || icmp(op, "DCB.B") == 0)) {
            emit_ds(ln, 1);
            return;
        }
        if (apw && icmp(op, "DS.W") == 0) { emit_ds(ln, 2); return; }
        if (apw && icmp(op, "DS.L") == 0) { emit_ds(ln, 4); return; }
        if (icmp(op, "DC") == 0) { emit_dc(ln); return; }
        if (icmp(op, "LONGA") == 0 || icmp(op, "LONGI") == 0) {
            std::string a = trim_copy(ln.operand);
            bool wide = icmp(a, "ON") == 0 || icmp(a, "YES") == 0 || a == "1";
            mxpart(ln, icmp(op, "LONGA") == 0 ? 2 : 1, wide);
            return;
        }
        if (icmp(op, "IF") == 0) {
            std::string oper = trim_copy(ln.operand);
            std::string expr, label;
            if (apw && split_goto(oper, expr, label)) {
                PInstr in;
                in.op = POp::Ago;
                in.opcode = "IF";
                in.operand = expr.empty() ? std::string("0") : alg(expr);
                in.expr = label;
                in.source = ln.raw;
                in.file = ln.file;
                in.lineno = ln.lineno;
                if (ln.has_label) in.label = ln.label;
                out->ins.push_back(std::move(in));
                return;
            }
            if (apw) {
                std::string head;
                if (strip_trailing_then(oper, head)) oper = head;
            }
            emit(ln, POp::If, "DO", oper.empty() ? "1" : alg(oper), true);
            return;
        }
        if (icmp(op, "ELSE") == 0) { emit(ln, POp::Else, "ELSE", {}, false); return; }
        if (icmp(op, "ENDC") == 0 || icmp(op, "FIN") == 0 || icmp(op, "ENDIF") == 0) {
            emit(ln, POp::Endif, "FIN", {}, false);
            return;
        }
        if (icmp(op, "EXTERN") == 0) { emit(ln, POp::Asm, "EXT", ln.operand, true); return; }
        if (icmp(op, "ENTRY") == 0) {
            emit(ln, POp::Asm, "ENT", ln.operand, true);
            return;
        }
        if (icmp(op, "ALIGN") == 0) {
            PInstr in;
            in.op = POp::Align;
            auto parts = split_args(ln.operand, ',');
            std::string count = parts.empty() ? std::string("2") : parts[0];
            if (trim_copy(count).empty()) count = "2";
            in.operand = alg(count);
            if (parts.size() >= 2) in.expr2 = alg(parts[1]);
            in.source = ln.raw;
            in.file = ln.file;
            in.lineno = ln.lineno;
            if (ln.has_label) in.label = ln.label;
            out->ins.push_back(std::move(in));
            return;
        }
        if (icmp(op, "CASE") == 0) {
            bool on = icmp(ln.operand, "ON") == 0;
            emit(ln, POp::Asm, "CAS", on ? "SE" : "IN", false);
            return;
        }
        if (icmp(op, "MACHINE") == 0) {
            emit_cpu(ln, ln.operand, false);
            return;
        }
        if (icmp(op, "COPY") == 0 || icmp(op, "APPEND") == 0 || icmp(op, "MCOPY") == 0 ||
            (apw && icmp(op, "INCLUDE") == 0)) {
            emit(ln, POp::Nop, {}, {}, false);
            std::vector<SrcLine> inc;
            if (!load(ln, inc)) return;
            if (depth > 16) {
                out->errors.push_back({ln.file, ln.lineno, "include nest too deep"});
                return;
            }
            collect(inc);
            opening.push_back(inc.empty() ? std::string() : inc[0].file);
            depth++;
            compile_all(inc);
            depth--;
            if (!opening.empty()) opening.pop_back();
            return;
        }
        if (icmp(op, "USING") == 0 || icmp(op, "EJECT") == 0 || icmp(op, "OBJ") == 0 ||
            icmp(op, "OBJEND") == 0 || icmp(op, "KEEP") == 0 || icmp(op, "MERR") == 0 ||
            icmp(op, "MEM") == 0) {
            emit(ln, POp::Nop, {}, {}, ln.has_label);
            return;
        }
        if (apw && icmp(op, "ABSADDR") == 0) {
            absaddr = on_flag(ln.operand);
            emit(ln, POp::Nop, {}, {}, true);
            return;
        }
        if (apw && icmp(op, "MSB") == 0) {
            msb = on_flag(ln.operand);
            emit(ln, POp::Nop, {}, {}, true);
            return;
        }
        if (apw && (icmp(op, "65816") == 0 || icmp(op, "65C02") == 0 || icmp(op, "6502") == 0)) {
            std::string a = trim_copy(ln.operand);
            bool off = icmp(a, "OFF") == 0 || icmp(a, "NO") == 0 || a == "0";
            if (off) emit(ln, POp::Nop, {}, {}, true);
            else emit_cpu(ln, op, true);
            return;
        }
        if (apw && icmp(op, "IMPORT") == 0) {
            emit(ln, POp::Asm, "EXT", ln.operand, true);
            return;
        }
        if (apw && (icmp(op, "DC.B") == 0 || icmp(op, "DCB") == 0)) {
            emit(ln, POp::Data, "DFB", dc_b_list(ln.operand), true);
            return;
        }
        if (apw && icmp(op, "DC.W") == 0) {
            emit(ln, POp::Data, "DA", alg_list(ln.operand), true);
            return;
        }
        if (apw && icmp(op, "DC.L") == 0) {
            emit(ln, POp::Data, "ADRL", alg_list(ln.operand), true);
            return;
        }
        if (apw && icmp(op, "DC.A") == 0) {
            emit(ln, POp::Data, "ADR", alg_list(ln.operand), true);
            return;
        }
        if (apw && icmp(op, "AERROR") == 0) {
            emit(ln, POp::Asm, "ERR", ln.operand, true);
            return;
        }
        if (apw && icmp(op, "EXPORT") == 0) {
            emit(ln, POp::Asm, "XPORT", ln.operand, true);
            return;
        }
        if (apw && (apw_only_dir(op) || icmp(op, "KIND") == 0 || icmp(op, "RENAME") == 0 ||
                    icmp(op, "SETCOM") == 0 || icmp(op, "DIRECT") == 0)) {
            /* Listing controls, STRING, EXPORT, SEG, and the other Apple
               directives that do not change object bytes. KIND, RENAME,
               SETCOM, and DIRECT are errors in ORCA/M and no-ops here. */
            emit(ln, POp::Nop, {}, {}, true);
            return;
        }
        if (orca_dir(op) && icmp(op, "DC") != 0) {
            out->errors.push_back({ln.file, ln.lineno, "unsupported ORCA directive " + op});
            emit(ln, POp::Nop, {}, {}, ln.has_label);
            return;
        }
        if (Omac *m = find_mac(op)) {
            if (depth > 16) {
                out->errors.push_back({ln.file, ln.lineno, "macro nest too deep"});
                return;
            }
            std::vector<std::pair<std::string, std::string>> map;
            if (!m->lab.empty()) map.push_back({m->lab, ln.has_label ? ln.label : std::string()});
            auto args = split_args(ln.operand, ',');
            std::sort(m->params.begin(), m->params.end(),
                      [](const std::string &a, const std::string &b) { return a.size() > b.size(); });
            for (size_t k = 0; k < m->params.size(); k++)
                map.push_back({m->params[k], k < args.size() ? args[k] : std::string()});
            /* Longer names first so &worklen is not eaten by &work. The sort
               above is stable enough; also sort the map. */
            std::sort(map.begin(), map.end(),
                      [](const auto &a, const auto &b) { return a.first.size() > b.first.size(); });
            if (ln.has_label && m->lab.empty()) {
                SrcLine mark = ln;
                mark.opcode.clear();
                mark.operand.clear();
                emit(mark, POp::Label, {}, {}, true);
            } else if (!ln.raw.empty()) {
                SrcLine mark = ln;
                mark.opcode.clear();
                mark.operand.clear();
                mark.label.clear();
                mark.has_label = false;
                emit(mark, POp::Nop, {}, {}, false);
            }
            depth++;
            for (const auto &src : m->body) {
                SrcLine b = src;
                b.label = subst_amp(src.label, map);
                b.opcode = subst_amp(src.opcode, map);
                b.operand = subst_amp(src.operand, map);
                b.has_label = !b.label.empty();
                b.raw.clear();
                one(b);
            }
            depth--;
            return;
        }
        emit(ln, POp::Inst, ln.opcode, alg_addr(ln.operand), true);
    }

    void compile_all(const std::vector<SrcLine> &ls)
    {
        for (int i = 0; i < static_cast<int>(ls.size()); i++) {
            if (icmp(ls[i].opcode, "MACRO") == 0) {
                int j = i + 1;
                while (j < static_cast<int>(ls.size()) &&
                       (ls[j].is_comment || (ls[j].opcode.empty() && !ls[j].has_label)))
                    j++;
                if (j < static_cast<int>(ls.size())) j++;
                for (; j < static_cast<int>(ls.size()); j++) {
                    if (icmp(ls[j].opcode, "MEND") == 0 || icmp(ls[j].opcode, "ENDM") == 0)
                        break;
                }
                i = j;
                continue;
            }
            one(ls[i]);
        }
    }
};

void orca_compile(const std::string &src, const std::string &name, const Options &opt, PCode &code)
{
    bool apw = code.syntax == Syntax::Apw;
    auto lines = parse_source(src, name, apw);
    for (auto &ln : lines) fix_orca(ln, apw);
    OC c;
    c.opt = &opt;
    c.out = &code;
    c.apw = apw;
    c.collect(lines);
    c.compile_all(lines);
}

} // namespace qasm
