#include "pcode.hpp"

#include <algorithm>
#include <cctype>
#include <cstring>
#include <map>

namespace qasm {

struct CaLine {
    std::string label;
    std::string opcode;
    std::string operand;
    std::string source;
    std::string file;
    int lineno = 0;
    bool comment = false;
};

static std::string cut_comment(const std::string &s)
{
    bool sq = false, dq = false;
    for (size_t i = 0; i < s.size(); i++) {
        char c = s[i];
        if (!sq && !dq && c == ';') return s.substr(0, i);
        if (!sq && !dq) {
            if (c == '\'') sq = true;
            else if (c == '"') dq = true;
        } else if (sq && c == '\'') sq = false;
        else if (dq && c == '"') dq = false;
    }
    return s;
}

static void parse_stmt(const std::string &s, size_t i, CaLine &r)
{
    auto skip = [&]() {
        while (i < s.size() && std::isspace(static_cast<unsigned char>(s[i]))) i++;
    };
    skip();
    if (i >= s.size()) return;
    if (s[i] == '.') {
        size_t b = i;
        while (i < s.size() && !std::isspace(static_cast<unsigned char>(s[i]))) i++;
        r.opcode = s.substr(b, i - b);
        skip();
        r.operand = trim_copy(s.substr(i));
        return;
    }
    size_t b = i;
    while (i < s.size() && !std::isspace(static_cast<unsigned char>(s[i])) && s[i] != '=' &&
           s[i] != ':')
        i++;
    std::string word = s.substr(b, i - b);
    skip();
    if (i < s.size() && s[i] == ':' && i + 1 < s.size() && s[i + 1] == '=') {
        r.label = word;
        i += 2;
        skip();
        r.opcode = "=";
        r.operand = trim_copy(s.substr(i));
        return;
    }
    if (i < s.size() && s[i] == '=') {
        r.label = word;
        i++;
        skip();
        r.opcode = "=";
        r.operand = trim_copy(s.substr(i));
        return;
    }
    r.opcode = word;
    r.operand = trim_copy(s.substr(i));
}

static CaLine parse_ca_line(const std::string &raw, int lineno, const std::string &file)
{
    CaLine r;
    r.source = raw;
    r.file = file;
    r.lineno = lineno;
    std::string s = trim_copy(cut_comment(raw));
    if (s.empty()) {
        r.comment = true;
        return r;
    }
    size_t i = 0;
    while (i < s.size() && std::isspace(static_cast<unsigned char>(s[i]))) i++;
    if (i < s.size() && s[i] == '.') {
        parse_stmt(s, i, r);
        return r;
    }
    size_t b = i;
    while (i < s.size() && !std::isspace(static_cast<unsigned char>(s[i])) && s[i] != '=' &&
           s[i] != ':')
        i++;
    std::string word = s.substr(b, i - b);
    if (i < s.size() && s[i] == ':') {
        if (!(i + 1 < s.size() && s[i + 1] == '=')) {
            r.label = word;
            i++;
            parse_stmt(s, i, r);
            return r;
        }
    }
    parse_stmt(s, b, r);
    return r;
}

static std::vector<CaLine> ca_lines(const std::string &src, const std::string &name)
{
    std::vector<CaLine> out;
    int lineno = 1;
    size_t i = 0;
    while (i < src.size()) {
        size_t eol = src.find('\n', i);
        if (eol == std::string::npos) eol = src.size();
        std::string raw = src.substr(i, eol - i);
        if (!raw.empty() && raw.back() == '\r') raw.pop_back();
        out.push_back(parse_ca_line(raw, lineno, name));
        if (eol >= src.size()) break;
        i = eol + 1;
        lineno++;
    }
    return out;
}

static bool consume_size(const std::string &s, size_t i, size_t &n, int &fr)
{
    static const char *w[] = {"zeropage:", "direct:", "absolute:", "near:", "far:",
                              "z:",        "a:",      "f:",        nullptr};
    static const int frs[] = {FORCE_DP, FORCE_DP, FORCE_ABS, FORCE_ABS, FORCE_LONG,
                              FORCE_DP, FORCE_ABS, FORCE_LONG};
    if (i && (std::isalnum(static_cast<unsigned char>(s[i - 1])) || s[i - 1] == '_' ||
              s[i - 1] == '@'))
        return false;
    for (int k = 0; w[k]; k++) {
        size_t len = std::strlen(w[k]);
        if (i + len <= s.size() && icmp(s.substr(i, len), w[k]) == 0) {
            n = len;
            fr = frs[k];
            return true;
        }
    }
    return false;
}

static std::string strip_sizes(const std::string &s, int &force)
{
    std::string out;
    bool sq = false, dq = false;
    for (size_t i = 0; i < s.size(); ) {
        char c = s[i];
        if (!sq && !dq) {
            size_t n = 0;
            int fr = FORCE_NONE;
            if (consume_size(s, i, n, fr)) {
                if (force == FORCE_NONE) force = fr;
                i += n;
                continue;
            }
            if (c == '\'') sq = true;
            else if (c == '"') dq = true;
        } else if (sq && c == '\'') sq = false;
        else if (dq && c == '"') dq = false;
        out.push_back(c);
        i++;
    }
    return out;
}

static std::string ca_addr(const std::string &operand)
{
    if (operand.empty()) return operand;
    int force = FORCE_NONE;
    std::string stripped = strip_sizes(operand, force);
    OperandForm f = parse_operand_form(stripped);
    if (force != FORCE_NONE && f.force == FORCE_NONE) f.force = force;
    f.expr = translate_algebraic(f.expr);
    if (!f.expr2.empty()) f.expr2 = translate_algebraic(f.expr2);
    return form_operand(f);
}

static std::string decode_string(const std::string &inner)
{
    std::string o;
    for (size_t i = 0; i < inner.size(); i++) {
        if (inner[i] == '\\' && i + 1 < inner.size()) {
            char n = inner[++i];
            if (n == 'n') o.push_back('\n');
            else if (n == 'r') o.push_back('\r');
            else if (n == 't') o.push_back('\t');
            else o.push_back(n);
        } else o.push_back(inner[i]);
    }
    return o;
}

struct CaMac {
    std::string name;
    std::vector<std::string> params;
    std::vector<CaLine> body;
};

struct CC {
    const Options *opt = nullptr;
    PCode *out = nullptr;
    std::vector<CaMac> macs;
    int depth = 0;
    std::map<std::string, std::vector<CaLine>> cache;
    std::vector<std::string> opening;

    CaMac *find_mac(const std::string &name)
    {
        for (auto &m : macs)
            if (m.name == name) return &m;
        return nullptr;
    }

    void add(const CaLine &ln, POp op, const std::string &opcode, const std::string &operand,
             bool keep_label)
    {
        PInstr in;
        in.op = op;
        in.opcode = opcode;
        in.operand = operand;
        if (keep_label) in.label = ln.label;
        in.source = ln.source;
        in.file = ln.file;
        in.lineno = ln.lineno;
        if (op == POp::Inst) annotate_inst(in);
        out->ins.push_back(std::move(in));
    }

    void mx(const CaLine &ln, int mask, int val)
    {
        PInstr in;
        in.op = POp::MxPart;
        in.i0 = mask;
        in.i1 = val;
        in.label = ln.label;
        in.source = ln.source;
        in.file = ln.file;
        in.lineno = ln.lineno;
        out->ins.push_back(std::move(in));
    }

    void cpu(const CaLine &ln, int which)
    {
        PInstr in;
        in.op = POp::Cpu;
        in.i0 = which;
        in.label = ln.label;
        in.source = ln.source;
        in.file = ln.file;
        in.lineno = ln.lineno;
        out->ins.push_back(std::move(in));
    }

    void emit_width(const CaLine &ln, int width)
    {
        const char *opc = "DFB";
        if (width == 2) opc = "DA";
        else if (width == 3) opc = "ADR";
        else if (width == 4) opc = "ADRL";
        auto parts = split_args(ln.operand, ',');
        std::string pending;
        bool labelled = false;
        /* The label lives on the first emitted op only. */
        auto take_label = [&](CaLine &bit) {
            if (!labelled) {
                bit.label = ln.label;
                labelled = true;
            } else bit.label.clear();
        };
        if (parts.empty()) {
            add(ln, POp::Nop, {}, {}, true);
            return;
        }
        for (const auto &p0 : parts) {
            std::string p = trim_copy(p0);
            if (p.empty()) continue;
            bool str = false;
            std::string bytes;
            if (p.size() >= 2 && p.front() == '"' && p.back() == '"') {
                str = true;
                bytes = decode_string(p.substr(1, p.size() - 2));
            } else if (p.size() >= 2 && p.front() == '\'' && p.back() == '\'' &&
                       p.size() > 3) {
                str = true;
                bytes = decode_string(p.substr(1, p.size() - 2));
            }
            if (str && width == 1) {
                if (!pending.empty()) {
                    CaLine bit = ln;
                    take_label(bit);
                    bit.source = labelled ? std::string() : ln.source;
                    add(bit, POp::Data, opc, pending, !bit.label.empty());
                    pending.clear();
                }
                PInstr in;
                in.op = POp::Bytes;
                in.file = ln.file;
                in.lineno = ln.lineno;
                if (!labelled) {
                    in.label = ln.label;
                    in.source = ln.source;
                    labelled = true;
                }
                for (unsigned char c : bytes) in.raw.push_back(c);
                out->ins.push_back(std::move(in));
            } else {
                if (!pending.empty()) pending += ",";
                pending += translate_algebraic(p);
            }
        }
        if (!pending.empty()) {
            CaLine bit = ln;
            if (labelled) {
                bit.label.clear();
                bit.source.clear();
            }
            add(bit, POp::Data, opc, pending, !bit.label.empty());
        }
    }

    static std::string subst_idents(const std::string &s,
                                    const std::vector<std::pair<std::string, std::string>> &map)
    {
        std::string out;
        for (size_t i = 0; i < s.size(); ) {
            unsigned char c = static_cast<unsigned char>(s[i]);
            if (std::isalpha(c) || c == '_' || c == '@') {
                size_t j = i + 1;
                while (j < s.size()) {
                    unsigned char d = static_cast<unsigned char>(s[j]);
                    if (!std::isalnum(d) && d != '_' && d != '@') break;
                    j++;
                }
                std::string id = s.substr(i, j - i);
                bool hit = false;
                for (const auto &kv : map) {
                    if (kv.first == id) {
                        out += kv.second;
                        hit = true;
                        break;
                    }
                }
                if (!hit) out += id;
                i = j;
            } else out.push_back(s[i++]);
        }
        return out;
    }

    void one(const CaLine &ln);

    void compile_slice(const std::vector<CaLine> &ls, int lo, int hi)
    {
        for (int i = lo; i < hi; i++) {
            if (icmp(ls[i].opcode, ".MACRO") == 0) {
                int j = i + 1;
                int nest = 1;
                for (; j < hi; j++) {
                    if (icmp(ls[j].opcode, ".MACRO") == 0) nest++;
                    if (icmp(ls[j].opcode, ".ENDMACRO") == 0 || icmp(ls[j].opcode, ".ENDMAC") == 0) {
                        if (--nest == 0) break;
                    }
                }
                i = j;
                continue;
            }
            if (icmp(ls[i].opcode, ".REPEAT") == 0) {
                PInstr in;
                in.op = POp::Lup;
                in.opcode = "LUP";
                in.operand = translate_algebraic(ls[i].operand.empty() ? "1" : ls[i].operand);
                in.label = ls[i].label;
                in.source = ls[i].source;
                in.file = ls[i].file;
                in.lineno = ls[i].lineno;
                out->ins.push_back(std::move(in));
                int nest = 1;
                int j = i + 1;
                for (; j < hi; j++) {
                    if (icmp(ls[j].opcode, ".REPEAT") == 0) nest++;
                    if (icmp(ls[j].opcode, ".ENDREPEAT") == 0 || icmp(ls[j].opcode, ".ENDREP") == 0) {
                        if (--nest == 0) break;
                    }
                }
                if (j >= hi)
                    out->errors.push_back({ls[i].file, ls[i].lineno, ".repeat without .endrepeat"});
                compile_slice(ls, i + 1, j);
                PInstr end;
                end.op = POp::Endlup;
                end.file = ls[i].file;
                end.lineno = ls[i].lineno;
                out->ins.push_back(std::move(end));
                i = j;
                continue;
            }
            one(ls[i]);
        }
    }

    void collect(const std::vector<CaLine> &ls)
    {
        for (int i = 0; i < static_cast<int>(ls.size()); i++) {
            if (icmp(ls[i].opcode, ".MACRO") != 0) continue;
            CaMac m;
            std::string spec = trim_copy(ls[i].operand);
            size_t sp = spec.find_first_of(" \t,");
            m.name = sp == std::string::npos ? spec : spec.substr(0, sp);
            std::string rest = sp == std::string::npos ? std::string() : trim_copy(spec.substr(sp));
            for (const auto &p : split_args(rest, ',')) {
                std::string q = trim_copy(p);
                if (!q.empty()) m.params.push_back(q);
            }
            int nest = 1;
            int j = i + 1;
            for (; j < static_cast<int>(ls.size()); j++) {
                if (icmp(ls[j].opcode, ".MACRO") == 0) nest++;
                if (icmp(ls[j].opcode, ".ENDMACRO") == 0 || icmp(ls[j].opcode, ".ENDMAC") == 0) {
                    if (--nest == 0) break;
                }
                if (nest == 1) m.body.push_back(ls[j]);
            }
            if (!m.name.empty() && !find_mac(m.name)) macs.push_back(std::move(m));
            i = j;
        }
    }

    bool load(const CaLine &ln, std::vector<CaLine> &got)
    {
        std::string path = resolve_include(ln.operand, ln.file.empty() ? "." : ln.file,
                                           opt->include_dirs);
        if (path.empty()) {
            out->errors.push_back({ln.file, ln.lineno,
                                   "cannot open include '" + strip_quotes(ln.operand) + "'"});
            return false;
        }
        for (const auto &p : opening)
            if (p == path) {
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
        got = ca_lines(text, path);
        cache[path] = got;
        return true;
    }
};

void CC::one(const CaLine &ln)
{
    if (ln.comment || (ln.opcode.empty() && ln.label.empty())) {
        add(ln, POp::Nop, {}, {}, false);
        return;
    }
    std::string op = ln.opcode;
    for (char &c : op)
        c = static_cast<char>(std::toupper(static_cast<unsigned char>(c)));

    if (op == ".ORG" || op == ".ORG") {
        add(ln, POp::Org, "ORG", translate_algebraic(ln.operand), true);
        return;
    }
    if (op == "=" || op == ".EQU" || op == ".SET") {
        if (op == ".SET") {
            auto parts = split_args(ln.operand, ',');
            std::string name = parts.empty() ? ln.label : parts[0];
            std::string expr = parts.size() >= 2 ? parts[1] : std::string();
            CaLine bit = ln;
            bit.label = name;
            add(bit, POp::Equ, "=", translate_algebraic(expr), true);
            return;
        }
        add(ln, POp::Equ, "=", translate_algebraic(ln.operand), true);
        return;
    }
    if (op == ".BYTE" || op == ".BYT") { emit_width(ln, 1); return; }
    if (op == ".WORD" || op == ".ADDR") { emit_width(ln, 2); return; }
    if (op == ".FARADDR" || op == ".FARADDR") { emit_width(ln, 3); return; }
    if (op == ".DWORD" || op == ".LONG") { emit_width(ln, 4); return; }
    if (op == ".RES" || op == ".DS") {
        add(ln, POp::Ds, "DS", [&]() {
                auto parts = split_args(ln.operand, ',');
                std::string o;
                for (const auto &p : parts) {
                    if (p.empty()) continue;
                    if (!o.empty()) o += ",";
                    o += translate_algebraic(p);
                }
                return o;
            }(),
            true);
        return;
    }
    if (op == ".ALIGN") {
        PInstr in;
        in.op = POp::Align;
        auto parts = split_args(ln.operand, ',');
        std::string count = parts.empty() ? std::string("2") : parts[0];
        if (trim_copy(count).empty()) count = "2";
        in.operand = translate_algebraic(count);
        if (parts.size() >= 2) in.expr2 = translate_algebraic(parts[1]);
        in.label = ln.label;
        in.source = ln.source;
        in.file = ln.file;
        in.lineno = ln.lineno;
        out->ins.push_back(std::move(in));
        return;
    }
    if (op == ".A8") { mx(ln, 2, 2); return; }
    if (op == ".A16") { mx(ln, 2, 0); return; }
    if (op == ".I8") { mx(ln, 1, 1); return; }
    if (op == ".I16") { mx(ln, 1, 0); return; }
    if (op == ".P816" || op == ".SMART") {
        if (op == ".P816") cpu(ln, CPU_65816);
        else add(ln, POp::Nop, {}, {}, true);
        return;
    }
    if (op == ".P02") { cpu(ln, CPU_6502); return; }
    if (op == ".PC02") { cpu(ln, CPU_65C02); return; }
    if (op == ".SETCPU") {
        std::string u = ln.operand;
        for (char &c : u)
            c = static_cast<char>(std::toupper(static_cast<unsigned char>(c)));
        int which = CPU_65816;
        if (u.find("65C02") != std::string::npos || u.find("65SC02") != std::string::npos)
            which = CPU_65C02;
        else if (u.find("6502") != std::string::npos) which = CPU_6502;
        cpu(ln, which);
        return;
    }
    if (op == ".IF" || op == ".IFNE") {
        add(ln, POp::If, "DO", ln.operand.empty() ? "1" : translate_algebraic(ln.operand), true);
        return;
    }
    if (op == ".IFEQ") {
        std::string e = translate_algebraic(ln.operand.empty() ? "0" : ln.operand);
        add(ln, POp::If, "DO", "{" + e + "=0}", true);
        return;
    }
    if (op == ".ELSE") { add(ln, POp::Else, "ELSE", {}, false); return; }
    if (op == ".ENDIF" || op == ".FI") { add(ln, POp::Endif, "FIN", {}, false); return; }
    if (op == ".END") { add(ln, POp::End, "END", {}, true); return; }
    if (op == ".PROC" || op == ".SCOPE") {
        CaLine bit = ln;
        if (bit.label.empty()) bit.label = trim_copy(ln.operand);
        add(bit, bit.label.empty() ? POp::Nop : POp::Label, {}, {}, true);
        return;
    }
    if (op == ".IMPORT" || op == ".IMPORTZP") {
        std::string names;
        for (const auto &p : split_args(ln.operand, ',')) {
            std::string n = p;
            auto c = n.find(':');
            if (c != std::string::npos) n = trim_copy(n.substr(0, c));
            if (n.empty()) continue;
            if (!names.empty()) names += ",";
            names += n;
        }
        add(ln, POp::Asm, "EXT", names, true);
        return;
    }
    if (op == ".INCLUDE") {
        add(ln, POp::Nop, {}, {}, false);
        std::vector<CaLine> inc;
        if (!load(ln, inc)) return;
        if (depth > 16) {
            out->errors.push_back({ln.file, ln.lineno, "include nest too deep"});
            return;
        }
        collect(inc);
        opening.push_back(inc.empty() ? std::string() : inc[0].file);
        depth++;
        compile_slice(inc, 0, static_cast<int>(inc.size()));
        depth--;
        if (!opening.empty()) opening.pop_back();
        return;
    }
    if (op == ".ELSEIF") {
        out->errors.push_back({ln.file, ln.lineno, "ca65 .elseif is not supported"});
        add(ln, POp::Nop, {}, {}, false);
        return;
    }
    if (!op.empty() && op[0] == '.' &&
        (icmp(op, ".SMART") == 0 || icmp(op, ".FEATURE") == 0 || icmp(op, ".LIST") == 0 ||
         icmp(op, ".DEBUGINFO") == 0 || icmp(op, ".ASSERT") == 0 || icmp(op, ".LOCAL") == 0 ||
         icmp(op, ".SEGMENT") == 0 || icmp(op, ".CODE") == 0 || icmp(op, ".DATA") == 0 ||
         icmp(op, ".RODATA") == 0 || icmp(op, ".BSS") == 0 || icmp(op, ".ZEROPAGE") == 0 ||
         icmp(op, ".ENDPROC") == 0 || icmp(op, ".ENDSCOPE") == 0 || icmp(op, ".EXPORT") == 0 ||
         icmp(op, ".EXPORTZP") == 0 || icmp(op, ".GLOBAL") == 0 || icmp(op, ".CASE") == 0 ||
         icmp(op, ".WARNING") == 0 || icmp(op, ".ERROR") == 0 || icmp(op, ".OUT") == 0 ||
         icmp(op, ".REPEAT") == 0 || icmp(op, ".ENDREPEAT") == 0 || icmp(op, ".ENDREP") == 0 ||
         icmp(op, ".ENDMACRO") == 0 || icmp(op, ".ENDMAC") == 0)) {
        if (icmp(op, ".ERROR") == 0)
            out->errors.push_back({ln.file, ln.lineno, ln.operand.empty() ? ".error" : ln.operand});
        add(ln, ln.label.empty() ? POp::Nop : POp::Label, {}, {}, true);
        return;
    }
    if (!op.empty() && op[0] == '.') {
        out->errors.push_back({ln.file, ln.lineno, "unsupported ca65 directive " + ln.opcode});
        add(ln, POp::Nop, {}, {}, !ln.label.empty());
        return;
    }
    if (CaMac *m = op.empty() ? nullptr : find_mac(ln.opcode)) {
        if (depth > 16) {
            out->errors.push_back({ln.file, ln.lineno, "macro nest too deep"});
            return;
        }
        if (!ln.label.empty()) add(ln, POp::Label, {}, {}, true);
        auto args = split_args(ln.operand, ',');
        std::vector<std::pair<std::string, std::string>> map;
        for (size_t k = 0; k < m->params.size(); k++)
            map.push_back({m->params[k], k < args.size() ? args[k] : std::string()});
        std::sort(map.begin(), map.end(),
                  [](const auto &a, const auto &b) { return a.first.size() > b.first.size(); });
        depth++;
        std::vector<CaLine> body;
        for (const auto &src : m->body) {
            CaLine b = src;
            b.label = subst_idents(src.label, map);
            b.opcode = subst_idents(src.opcode, map);
            b.operand = subst_idents(src.operand, map);
            b.source.clear();
            body.push_back(std::move(b));
        }
        compile_slice(body, 0, static_cast<int>(body.size()));
        depth--;
        return;
    }
    if (ln.opcode.empty()) {
        add(ln, ln.label.empty() ? POp::Nop : POp::Label, {}, {}, true);
        return;
    }
    add(ln, POp::Inst, ln.opcode, ca_addr(ln.operand), true);
}

void ca65_compile(const std::string &src, const std::string &name, const Options &opt, PCode &code)
{
    auto lines = ca_lines(src, name);
    CC c;
    c.opt = &opt;
    c.out = &code;
    /* ca65 symbols are case-sensitive. */
    {
        PInstr cas;
        cas.op = POp::Asm;
        cas.opcode = "CAS";
        cas.operand = "SE";
        cas.file = name;
        cas.lineno = 0;
        code.ins.push_back(std::move(cas));
    }
    c.collect(lines);
    c.compile_slice(lines, 0, static_cast<int>(lines.size()));
}

} // namespace qasm
