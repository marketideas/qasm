#include "pcode.hpp"

#include <cctype>
#include <map>

namespace merlin {

struct Mac {
    std::string name;
    std::vector<SrcLine> body;
};

struct MC {
    const Options *opt = nullptr;
    PCode *out = nullptr;
    std::vector<Mac> macs;
    bool case_sensitive = false;
    int oz_id = 1;
    int depth = 0;
    std::map<std::string, std::vector<SrcLine>> cache;
    std::vector<std::string> opening;

    int ncmp(const std::string &a, const std::string &b) const
    {
        return case_sensitive ? a.compare(b) : icmp(a, b);
    }

    Mac *find_mac(const std::string &name)
    {
        for (auto &m : macs)
            if (ncmp(m.name, name) == 0) return &m;
        return nullptr;
    }

    void collect(const std::vector<SrcLine> &ls)
    {
        for (int i = 0; i < static_cast<int>(ls.size()); i++) {
            if (icmp(ls[i].opcode, "MAC") != 0 || !ls[i].has_label) continue;
            if (find_mac(ls[i].label)) {
                int nest = 1;
                int j = i + 1;
                for (; j < static_cast<int>(ls.size()); j++) {
                    if (icmp(ls[j].opcode, "MAC") == 0) nest++;
                    if (icmp(ls[j].opcode, "EOM") == 0 || icmp(ls[j].opcode, "<<<") == 0) {
                        if (--nest == 0) break;
                    }
                }
                i = j;
                continue;
            }
            Mac m;
            m.name = ls[i].label;
            int nest = 1;
            int j = i + 1;
            for (; j < static_cast<int>(ls.size()); j++) {
                if (icmp(ls[j].opcode, "MAC") == 0) nest++;
                if (icmp(ls[j].opcode, "EOM") == 0 || icmp(ls[j].opcode, "<<<") == 0) {
                    if (--nest == 0) break;
                }
                m.body.push_back(ls[j]);
            }
            macs.push_back(std::move(m));
            i = j;
        }
    }

    void emit(const SrcLine &ln, POp op)
    {
        PInstr in;
        in.op = op;
        in.opcode = ln.opcode;
        in.operand = ln.operand;
        in.label = ln.has_label ? ln.label : "";
        in.source = ln.raw;
        in.file = ln.file;
        in.lineno = ln.lineno;
        if (op == POp::Inst) annotate_inst(in);
        out->ins.push_back(std::move(in));
    }

    void emit_line(const SrcLine &ln)
    {
        const std::string &op = ln.opcode;
        if (icmp(op, "DO") == 0 || icmp(op, "IF") == 0) { emit(ln, POp::If); return; }
        if (icmp(op, "ELSE") == 0) { emit(ln, POp::Else); return; }
        if (icmp(op, "FIN") == 0) { emit(ln, POp::Endif); return; }
        if (icmp(op, "END") == 0) { emit(ln, POp::End); return; }
        if (icmp(op, "--^") == 0) { emit(ln, POp::Endlup); return; }
        if (icmp(op, "ORG") == 0) { emit(ln, POp::Org); return; }
        if (icmp(op, "EQU") == 0 || op == "=" || icmp(op, "GEQU") == 0 || icmp(op, "GEQ") == 0) {
            emit(ln, POp::Equ);
            return;
        }
        if (icmp(op, "MX") == 0) { emit(ln, POp::Mx); return; }
        if (icmp(op, "XC") == 0) { emit(ln, POp::Xc); return; }
        if (icmp(op, "CAS") == 0) {
            if (nicmp(ln.operand, "SE", 2) == 0) case_sensitive = true;
            if (nicmp(ln.operand, "IN", 2) == 0) case_sensitive = false;
            emit(ln, POp::Asm);
            return;
        }
        if (icmp(op, "DFB") == 0 || icmp(op, "DB") == 0 || icmp(op, "DA") == 0 ||
            icmp(op, "DW") == 0 || icmp(op, "DDB") == 0 || icmp(op, "ADR") == 0 ||
            icmp(op, "ADRL") == 0) {
            emit(ln, POp::Data);
            return;
        }
        if (icmp(op, "DS") == 0) { emit(ln, POp::Ds); return; }
        if (is_pseudo_op(op)) { emit(ln, POp::Asm); return; }
        emit(ln, POp::Inst);
    }

    bool load(const SrcLine &ln, const std::string &name, std::vector<SrcLine> &got)
    {
        std::string from = ln.file.empty() ? "." : ln.file;
        std::string path = resolve_include(name, from, opt->include_dirs);
        if (path.empty()) {
            out->errors.push_back({ln.file, ln.lineno,
                                   "cannot open PUT/USE file '" + strip_quotes(name) + "'"});
            return false;
        }
        for (const auto &p : opening) {
            if (icmp(p, path) == 0) {
                out->errors.push_back({ln.file, ln.lineno, "include cycle '" + path + "'"});
                return false;
            }
        }
        auto it = cache.find(path);
        if (it != cache.end()) {
            got = it->second;
            return true;
        }
        std::string err;
        std::string text = read_file(path, &err);
        if (!err.empty() && text.empty()) {
            out->errors.push_back({ln.file, ln.lineno, err + ": " + path});
            return false;
        }
        got = parse_source(text, path);
        cache[path] = got;
        return true;
    }

    static int find_end(const std::vector<SrcLine> &ls, int n, int start,
                        const char *open, const char *close, const char *close2)
    {
        int nest = 1;
        for (int i = start; i < n; i++) {
            if (icmp(ls[i].opcode, open) == 0) nest++;
            if (icmp(ls[i].opcode, close) == 0 ||
                (close2 && icmp(ls[i].opcode, close2) == 0)) {
                if (--nest == 0) return i;
            }
        }
        return n;
    }

    static std::string subst_params(const std::string &src, const std::string p[10])
    {
        std::string dst;
        for (size_t i = 0; i < src.size(); ) {
            if (src[i] == ']' && i + 1 < src.size() && src[i + 1] >= '1' && src[i + 1] <= '9') {
                dst += p[src[i + 1] - '0'];
                i += 2;
            } else dst.push_back(src[i++]);
        }
        return dst;
    }

    static void split_mac_args(const std::string &opnd, std::string p[10])
    {
        for (int i = 0; i < 10; i++) p[i].clear();
        if (opnd.empty()) return;
        int idx = 1;
        size_t s = 0;
        while (s <= opnd.size() && idx <= 9) {
            size_t semi = opnd.find(';', s);
            std::string tok = (semi == std::string::npos) ? opnd.substr(s)
                                                          : opnd.substr(s, semi - s);
            p[idx++] = trim_copy(tok);
            if (semi == std::string::npos) break;
            s = semi + 1;
        }
    }

    static std::string replace_ident(const std::string &s,
                                     const std::map<std::string, std::string> &ren)
    {
        std::string out;
        for (size_t i = 0; i < s.size(); ) {
            unsigned char c = static_cast<unsigned char>(s[i]);
            if (std::isalpha(c) || c == '_' || c == '.' || c == '@') {
                size_t j = i + 1;
                while (j < s.size()) {
                    unsigned char d = static_cast<unsigned char>(s[j]);
                    if (!std::isalnum(d) && d != '_' && d != '.' && d != '@') break;
                    j++;
                }
                std::string id = s.substr(i, j - i);
                auto it = ren.find(id);
                out += (it != ren.end()) ? it->second : id;
                i = j;
            } else out.push_back(s[i++]);
        }
        return out;
    }

    void uniquify(std::vector<SrcLine> &body)
    {
        std::map<std::string, std::string> ren;
        for (auto &ln : body) {
            if (!ln.has_label || ln.label.empty()) continue;
            if (ln.label[0] == ']' || ln.label[0] == ':') continue;
            if (icmp(ln.opcode, "EQU") == 0 || ln.opcode == "=") continue;
            if (ren.find(ln.label) == ren.end())
                ren[ln.label] = "ozunid_" + std::to_string(oz_id++);
        }
        if (ren.empty()) return;
        for (auto &ln : body) {
            auto it = ren.find(ln.label);
            if (it != ren.end()) ln.label = it->second;
            ln.opcode = replace_ident(ln.opcode, ren);
            ln.operand = replace_ident(ln.operand, ren);
            ln.has_label = !ln.label.empty();
        }
    }

    void compile_range(const std::vector<SrcLine> &ls, int lo, int hi)
    {
        int n = static_cast<int>(ls.size());
        if (hi > n) hi = n;
        for (int i = lo; i < hi; i++) {
            const SrcLine &ln = ls[i];
            if (ln.is_comment || (ln.opcode.empty() && !ln.has_label)) {
                emit(ln, POp::Nop);
                continue;
            }
            const std::string &op = ln.opcode;

            if (icmp(op, "MAC") == 0) {
                emit(ln, POp::Nop);
                i = find_end(ls, n, i + 1, "MAC", "EOM", "<<<");
                continue;
            }
            if (icmp(op, "EOM") == 0 || icmp(op, "<<<") == 0) {
                emit(ln, POp::Nop);
                continue;
            }
            if (icmp(op, "USE") == 0 || icmp(op, "PUT") == 0) {
                emit(ln, POp::Nop);
                std::vector<SrcLine> inc;
                if (!load(ln, ln.operand, inc)) continue;
                collect(inc);
                if (icmp(op, "PUT") == 0 && !inc.empty()) {
                    if (depth > 16) {
                        out->errors.push_back({ln.file, ln.lineno, "include nest too deep"});
                        continue;
                    }
                    std::string path = inc[0].file;
                    opening.push_back(path);
                    depth++;
                    compile_range(inc, 0, static_cast<int>(inc.size()));
                    depth--;
                    opening.pop_back();
                }
                continue;
            }
            if (icmp(op, "LUP") == 0) {
                emit(ln, POp::Lup);
                int end = find_end(ls, hi, i + 1, "LUP", "--^", nullptr);
                if (end >= hi)
                    out->errors.push_back({ln.file, ln.lineno, "LUP without --^"});
                compile_range(ls, i + 1, end);
                SrcLine endln;
                endln.file = ln.file;
                endln.lineno = ln.lineno;
                endln.opcode = "--^";
                emit(endln, POp::Endlup);
                i = end;
                continue;
            }

            std::string callname = op;
            std::string arg = ln.operand;
            if (icmp(op, "PMC") == 0 || icmp(op, ">>>") == 0) {
                size_t sp = ln.operand.find_first_of(" \t");
                callname = sp == std::string::npos ? ln.operand : ln.operand.substr(0, sp);
                size_t p = 0;
                while (p < arg.size() && arg[p] != ' ' && arg[p] != '\t') p++;
                while (p < arg.size() && (arg[p] == ' ' || arg[p] == '\t')) p++;
                arg = arg.substr(p);
            }
            Mac *m = callname.empty() ? nullptr : find_mac(callname);
            if (m) {
                if (depth > 16) {
                    out->errors.push_back({ln.file, ln.lineno, "macro nest too deep"});
                    emit(ln, POp::Nop);
                    continue;
                }
                SrcLine mark = ln;
                mark.opcode.clear();
                mark.operand.clear();
                emit(mark, mark.has_label ? POp::Label : POp::Nop);
                std::string params[10];
                split_mac_args(arg, params);
                std::vector<SrcLine> body;
                body.reserve(m->body.size());
                for (const auto &src : m->body) {
                    SrcLine b = src;
                    b.label = subst_params(src.label, params);
                    b.opcode = subst_params(src.opcode, params);
                    b.operand = subst_params(src.operand, params);
                    b.has_label = !b.label.empty();
                    b.raw.clear();
                    body.push_back(std::move(b));
                }
                uniquify(body);
                depth++;
                compile_range(body, 0, static_cast<int>(body.size()));
                depth--;
                continue;
            }

            emit_line(ln);
        }
    }
};

void merlin_compile(const std::vector<SrcLine> &lines, const Options &opt, PCode &code)
{
    MC c;
    c.opt = &opt;
    c.out = &code;
    c.case_sensitive = opt.case_sensitive;
    c.collect(lines);
    c.compile_range(lines, 0, static_cast<int>(lines.size()));
}

} // namespace merlin
