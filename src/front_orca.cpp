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

static void fix_orca(SrcLine &ln)
{
    if (ln.is_comment) return;
    if (ln.has_label && !ln.label.empty() && ln.label.back() == ':') {
        ln.label.pop_back();
        ln.has_label = !ln.label.empty();
    }
    if (ln.has_label && orca_dir(ln.label) && !orca_dir(ln.opcode)) {
        if (ln.operand.empty()) ln.operand = ln.opcode;
        else ln.operand = ln.opcode + " " + ln.operand;
        ln.opcode = ln.label;
        ln.label.clear();
        ln.has_label = false;
    }
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
        if (op == POp::Inst) annotate_inst(in);
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

    std::string alg_addr(const std::string &operand) const
    {
        if (operand.empty()) return operand;
        OperandForm f = parse_operand_form(operand);
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
        got = parse_source(text, path);
        for (auto &l : got) fix_orca(l);
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
                if (clean) emit(bit, POp::Asm, "ASC", "'" + val + "'", true);
                else {
                    PInstr in;
                    in.op = POp::Bytes;
                    in.source = bit.raw;
                    in.file = bit.file;
                    in.lineno = bit.lineno;
                    if (bit.has_label) in.label = bit.label;
                    for (unsigned char c : val) in.raw.push_back(c);
                    out->ins.push_back(std::move(in));
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

    void one(const SrcLine &ln)
    {
        if (ln.is_comment || (ln.opcode.empty() && !ln.has_label)) {
            emit(ln, POp::Nop, {}, {}, false);
            return;
        }
        const std::string &op = ln.opcode;
        if (icmp(op, "MACRO") == 0) return; /* body skipped by the walker */
        if (icmp(op, "START") == 0 || icmp(op, "DATA") == 0 || icmp(op, "PRIVATE") == 0 ||
            icmp(op, "PRIVDATA") == 0 || icmp(op, "ANOP") == 0) {
            emit(ln, ln.has_label ? POp::Label : POp::Nop, {}, {}, true);
            return;
        }
        if (icmp(op, "END") == 0) { emit(ln, POp::End, "END", {}, true); return; }
        if (icmp(op, "ORG") == 0) { emit(ln, POp::Org, "ORG", alg(ln.operand), true); return; }
        if (icmp(op, "EQU") == 0 || icmp(op, "GEQU") == 0) {
            emit(ln, POp::Equ, "EQU", alg(ln.operand), true);
            return;
        }
        if (icmp(op, "DS") == 0) { emit(ln, POp::Ds, "DS", alg_list(ln.operand), true); return; }
        if (icmp(op, "DC") == 0) { emit_dc(ln); return; }
        if (icmp(op, "LONGA") == 0 || icmp(op, "LONGI") == 0) {
            std::string a = trim_copy(ln.operand);
            bool wide = icmp(a, "ON") == 0 || icmp(a, "YES") == 0 || a == "1";
            mxpart(ln, icmp(op, "LONGA") == 0 ? 2 : 1, wide);
            return;
        }
        if (icmp(op, "IF") == 0) {
            emit(ln, POp::If, "DO", ln.operand.empty() ? "1" : alg(ln.operand), true);
            return;
        }
        if (icmp(op, "ELSE") == 0) { emit(ln, POp::Else, "ELSE", {}, false); return; }
        if (icmp(op, "ENDC") == 0 || icmp(op, "FIN") == 0 || icmp(op, "ENDIF") == 0) {
            emit(ln, POp::Endif, "FIN", {}, false);
            return;
        }
        if (icmp(op, "EXTERN") == 0) { emit(ln, POp::Asm, "EXT", ln.operand, true); return; }
        if (icmp(op, "ENTRY") == 0) {
            if (ln.has_label) emit(ln, POp::Label, {}, {}, true);
            else emit(ln, POp::Nop, {}, {}, false);
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
            PInstr in;
            in.op = POp::Cpu;
            in.i0 = CPU_65816;
            std::string u = ln.operand;
            for (char &c : u) c = static_cast<char>(std::toupper(static_cast<unsigned char>(c)));
            if (u.find("6502") != std::string::npos && u.find("65C02") == std::string::npos)
                in.i0 = CPU_6502;
            else if (u.find("65C02") != std::string::npos) in.i0 = CPU_65C02;
            in.source = ln.raw;
            in.file = ln.file;
            in.lineno = ln.lineno;
            out->ins.push_back(std::move(in));
            return;
        }
        if (icmp(op, "COPY") == 0 || icmp(op, "APPEND") == 0 || icmp(op, "MCOPY") == 0) {
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
    auto lines = parse_source(src, name);
    for (auto &ln : lines) fix_orca(ln);
    OC c;
    c.opt = &opt;
    c.out = &code;
    c.collect(lines);
    c.compile_all(lines);
}

} // namespace qasm
