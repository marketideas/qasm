#include "pcode.hpp"

#include <cctype>
#include <cstdio>
#include <cstring>
#include <sstream>

namespace qasm {

const char *syntax_name(Syntax s)
{
    switch (s) {
    case Syntax::Merlin: return "merlin";
    case Syntax::Merlin32: return "merlin32";
    case Syntax::Orca: return "orca";
    case Syntax::Lisa: return "lisa";
    case Syntax::Ca65: return "ca65";
    case Syntax::Apw: return "apw";
    }
    return "merlin";
}

static std::string upper_copy(std::string s)
{
    for (char &c : s)
        c = static_cast<char>(std::toupper(static_cast<unsigned char>(c)));
    return s;
}

Syntax syntax_from_name(const std::string &name, bool &ok)
{
    ok = true;
    std::string n = upper_copy(trim_copy(name));
    if (n.empty() || n == "AUTO") return Syntax::Merlin;
    if (n == "MERLIN" || n == "MERLIN16" || n == "MERLIN16+" || n == "MERLIN-16")
        return Syntax::Merlin;
    if (n == "MERLIN32" || n == "MERLIN-32" || n == "M32") return Syntax::Merlin32;
    if (n == "ORCA" || n == "ORCA/M" || n == "ORCAM" || n == "ORCA-M") return Syntax::Orca;
    if (n == "LISA" || n == "LISA816" || n == "LISA-816") return Syntax::Lisa;
    if (n == "CA65" || n == "CC65") return Syntax::Ca65;
    if (n == "APW" || n == "MPW" || n == "APW/MPW" || n == "APW-MPW")
        return Syntax::Apw;
    ok = false;
    return Syntax::Merlin;
}

static bool token_at(const std::string &u, size_t p, const char *w)
{
    size_t n = std::strlen(w);
    if (p + n > u.size()) return false;
    if (u.compare(p, n, w) != 0) return false;
    bool left = p == 0 || !std::isalnum(static_cast<unsigned char>(u[p - 1]));
    bool right = p + n == u.size() || !std::isalnum(static_cast<unsigned char>(u[p + n]));
    if (!left || !right) return false;
    if (w[0] != '.' && p > 0 && u[p - 1] == '.') return false;
    return true;
}

static bool has_word(const std::string &u, const char *w)
{
    size_t n = std::strlen(w);
    for (size_t p = 0; p + n <= u.size(); p++) {
        if (token_at(u, p, w)) return true;
    }
    return false;
}

/* Quote patterns such as I1' and C' are followed by the data, which may
   be a digit or letter. Only the left edge has to be a token boundary. */
static bool has_lead(const std::string &u, const char *w)
{
    size_t n = std::strlen(w);
    for (size_t p = 0; p + n <= u.size(); p++) {
        if (u.compare(p, n, w) != 0) continue;
        bool left = p == 0 || !std::isalnum(static_cast<unsigned char>(u[p - 1]));
        if (!left) continue;
        if (w[0] != '.' && p > 0 && u[p - 1] == '.') continue;
        return true;
    }
    return false;
}

static std::string fold_src(const std::string &src)
{
    std::string o;
    o.reserve(src.size());
    for (unsigned char c : src) {
        if (c == 0x8D || c == '\r') {
            o.push_back('\n');
            continue;
        }
        if (c >= 0x80) c = static_cast<unsigned char>(c & 0x7F);
        o.push_back(static_cast<char>(c));
    }
    return o;
}

static bool native_merlin(const std::string &src)
{
    int hibit = 0;
    bool mark = false;
    for (unsigned char c : src) {
        if (c >= 0x80) hibit++;
        if (c == 0xA0 || c == 0x8D) mark = true;
    }
    return mark && hibit > 4;
}

/* A comment directive wins over the heuristic.
   `syntax: ca65` or `Assembler: Merlin 32`. */
static bool explicit_syntax(const std::string &folded, Syntax &out)
{
    std::string u = upper_copy(folded);
    size_t line = 0;
    size_t i = 0;
    while (i < u.size() && line < 40) {
        size_t eol = u.find('\n', i);
        if (eol == std::string::npos) eol = u.size();
        std::string ln = u.substr(i, eol - i);
        i = eol < u.size() ? eol + 1 : u.size();
        line++;
        auto take = [&](size_t pos, const char *key) -> bool {
            if (!token_at(ln, pos, key)) return false;
            size_t k = pos + std::strlen(key);
            while (k < ln.size() && (ln[k] == ' ' || ln[k] == '\t' || ln[k] == ':')) k++;
            bool dummy = true;
            /* "MERLIN 32" is nine characters. Check it before the first word
               is split on the space and read as plain Merlin. */
            auto starts = [&](const char *w) {
                size_t n = std::strlen(w);
                if (k + n > ln.size() || ln.compare(k, n, w) != 0) return false;
                if (k + n < ln.size() &&
                    std::isalnum(static_cast<unsigned char>(ln[k + n])))
                    return false;
                return true;
            };
            if (starts("MERLIN 32") || starts("MERLIN32")) {
                out = Syntax::Merlin32;
                return true;
            }
            std::string rest = ln.substr(k);
            size_t sp = rest.find_first_of(" \t;");
            std::string name = sp == std::string::npos ? rest : rest.substr(0, sp);
            if (name.empty()) return false;
            Syntax s = syntax_from_name(name, dummy);
            if (!dummy) return false;
            /* "MERLIN" after ASSEMBLER: is Merlin, not the auto placeholder. */
            out = s;
            return true;
        };
        for (size_t p = 0; p < ln.size(); p++) {
            if (take(p, "SYNTAX")) return true;
            if (take(p, "ASSEMBLER")) return true;
        }
    }
    return false;
}

static std::string strip_comments(const std::string &folded)
{
    std::string out;
    size_t i = 0;
    while (i < folded.size()) {
        size_t eol = folded.find('\n', i);
        if (eol == std::string::npos) eol = folded.size();
        std::string ln = folded.substr(i, eol - i);
        i = eol < folded.size() ? eol + 1 : folded.size();
        size_t ns = 0;
        while (ns < ln.size() && (ln[ns] == ' ' || ln[ns] == '\t')) ns++;
        if (ns < ln.size() && (ln[ns] == '*' || ln[ns] == ';')) {
            out.push_back('\n');
            continue;
        }
        bool sq = false, dq = false;
        for (size_t k = 0; k < ln.size(); k++) {
            char c = ln[k];
            if (!sq && !dq && c == ';') break;
            if (!sq && !dq) {
                if (c == '\'') sq = true;
                else if (c == '"') dq = true;
            } else if (sq && c == '\'') sq = false;
            else if (dq && c == '"') dq = false;
            out.push_back(c);
        }
        out.push_back('\n');
    }
    return out;
}

Syntax identify_syntax(const std::string &src)
{
    std::string folded = fold_src(src);
    Syntax marked = Syntax::Merlin;
    if (explicit_syntax(folded, marked)) return marked;
    if (native_merlin(src)) return Syntax::Merlin;

    std::string code = upper_copy(strip_comments(folded));
    auto present = [&](const char *w) { return has_word(code, w); };

    int merlin = 0, orca = 0, lisa = 0, ca65 = 0;
    bool m32 = false;

    const char *mstrong[] = {
        "MX", "XC", "DFB", "DDB", "STRL", "ADRL", "DEND", "DSK", "LUP",
        "DCI", "FLS", "PMC", "EOM", "DUM", "PUT", "USE", "--^", "MAC", nullptr
    };
    for (int i = 0; mstrong[i]; i++)
        if (present(mstrong[i])) merlin += 8;
    if (present("GEQU") || present("GEQ")) {
        merlin += 8;
        m32 = true;
    }

    const char *ostrong[] = {
        "LONGA", "LONGI", "ANOP", "MCOPY", "MEND", "PRIVDATA", "ENDC", nullptr
    };
    for (int i = 0; ostrong[i]; i++)
        if (present(ostrong[i])) orca += 8;
    if (has_lead(code, "I1'") || has_lead(code, "I2'") || has_lead(code, "I4'") ||
        has_lead(code, "I1\"") || has_lead(code, "I2\"") || has_lead(code, "C'") ||
        has_lead(code, "H'"))
        orca += 8;

    const char *lstrong[] = {
        ".OR", ".HS", ".BS", ".EQ", ".DA", ".EN", ".EP", ".AS",
        ".FI", ".EL", ".DB", ".BY", nullptr
    };
    for (int i = 0; lstrong[i]; i++)
        if (present(lstrong[i])) lisa += 8;

    const char *cstrong[] = {
        ".ORG", ".BYTE", ".WORD", ".DWORD", ".FARADDR", ".RES", ".MACRO",
        ".ENDMACRO", ".P816", ".A8", ".A16", ".I8", ".I16", ".PROC",
        ".IMPORT", ".EXPORT", ".SEGMENT", ".SETCPU", ".PC02", ".P02",
        ".FEATURE", ".INCLUDE", ".ALIGN", ".REPEAT", ".ENDPROC", nullptr
    };
    for (int i = 0; cstrong[i]; i++)
        if (present(cstrong[i])) ca65 += 8;

    int best = merlin;
    Syntax syn = Syntax::Merlin;
    if (orca > best) { best = orca; syn = Syntax::Orca; }
    if (lisa > best) { best = lisa; syn = Syntax::Lisa; }
    if (ca65 > best) { best = ca65; syn = Syntax::Ca65; }
    /* Apple's assemblers share ORCA/M source. These tokens are not ORCA
       score words, and a short ORCA file can outscore them, so they win
       over ORCA or Merlin after the scores. LISA and ca65 keep a higher
       score. A Merlin 32 file that also has one of these is APW. */
    bool apple = present("ABSADDR") || present("MSB") || present("CODECHK") ||
                 present("CODECHECK") || present("INSTIME");
    if (apple && (syn == Syntax::Orca || syn == Syntax::Merlin))
        return Syntax::Apw;
    if (m32 && syn == Syntax::Merlin) return Syntax::Merlin32;
    return syn;
}

std::vector<std::string> split_args(const std::string &s, char sep)
{
    std::vector<std::string> out;
    std::string cur;
    int depth = 0;
    bool sq = false, dq = false;
    for (size_t i = 0; i < s.size(); i++) {
        char c = s[i];
        if (!sq && !dq) {
            if (c == '\'') sq = true;
            else if (c == '"') dq = true;
            else if (c == '(' || c == '[' || c == '{') depth++;
            else if ((c == ')' || c == ']' || c == '}') && depth > 0) depth--;
            else if (c == sep && depth == 0) {
                out.push_back(trim_copy(cur));
                cur.clear();
                continue;
            }
        } else if (sq && c == '\'') sq = false;
        else if (dq && c == '"') dq = false;
        cur.push_back(c);
    }
    if (!cur.empty() || !out.empty()) out.push_back(trim_copy(cur));
    return out;
}

static std::string force_prefix(const OperandForm &f)
{
    if (f.byte_sel == '^' && f.force == FORCE_ABS) return "^";
    if (f.force == FORCE_DP) return "<";
    if (f.force == FORCE_LONG) return ">";
    if (f.force == FORCE_ABS) return "|";
    return {};
}

std::string form_operand(const OperandForm &f)
{
    const std::string &e = f.expr;
    switch (f.syntax) {
    case SYN_IMP: return {};
    case SYN_IMM: {
        std::string s = "#";
        if (f.byte_sel) s.push_back(static_cast<char>(f.byte_sel));
        s += e;
        return s;
    }
    case SYN_X: return force_prefix(f) + e + ",X";
    case SYN_Y: return force_prefix(f) + e + ",Y";
    case SYN_S: return force_prefix(f) + e + ",S";
    case SYN_IND: return force_prefix(f) + "(" + e + ")";
    case SYN_INDX: return force_prefix(f) + "(" + e + ",X)";
    case SYN_INDY: return force_prefix(f) + "(" + e + "),Y";
    case SYN_INDL: return force_prefix(f) + "[" + e + "]";
    case SYN_INDLY: return force_prefix(f) + "[" + e + "],Y";
    case SYN_SIY: return force_prefix(f) + "(" + e + ",S),Y";
    case SYN_BLK: return e + "," + f.expr2;
    default: return force_prefix(f) + e;
    }
}

static const char *mode_name(int syntax)
{
    switch (syntax) {
    case SYN_IMP: return "imp";
    case SYN_IMM: return "imm";
    case SYN_ABS: return "abs";
    case SYN_X: return "x";
    case SYN_Y: return "y";
    case SYN_S: return "s";
    case SYN_IND: return "ind";
    case SYN_INDX: return "indx";
    case SYN_INDY: return "indy";
    case SYN_INDL: return "indl";
    case SYN_INDLY: return "indly";
    case SYN_SIY: return "siy";
    case SYN_BLK: return "blk";
    default: return "?";
    }
}

void annotate_inst(PInstr &in, bool merlin_hash_a)
{
    int force = FORCE_NONE;
    bool long_mn = false;
    in.cname = opcode_canonical(in.opcode, force, long_mn);
    in.long_mn = long_mn;
    OperandForm f = parse_operand_form(in.operand, merlin_hash_a);
    if (is_alu_acc(in.cname) && f.syntax == SYN_ABS && icmp(f.expr, "A") == 0) {
        f.syntax = SYN_IMP;
        f.expr.clear();
    }
    in.syntax = f.syntax;
    in.force = f.force ? f.force : force;
    if (long_mn) in.force = FORCE_LONG;
    in.byte_sel = f.byte_sel;
    in.expr = std::move(f.expr);
    in.expr2 = std::move(f.expr2);
}

static const char *pop_name(POp op)
{
    switch (op) {
    case POp::Nop: return "P_NOP";
    case POp::End: return "P_END";
    case POp::Label: return "P_LABEL";
    case POp::Org: return "P_ORG";
    case POp::Equ: return "P_EQU";
    case POp::Mx: return "P_MX";
    case POp::Xc: return "P_XC";
    case POp::MxPart: return "P_MXPART";
    case POp::Cpu: return "P_CPU";
    case POp::Inst: return "P_INST";
    case POp::Data: return "P_DATA";
    case POp::Ds: return "P_DS";
    case POp::Asm: return "P_ASM";
    case POp::Bytes: return "P_BYTES";
    case POp::Align: return "P_ALIGN";
    case POp::If: return "P_IF";
    case POp::Else: return "P_ELSE";
    case POp::Endif: return "P_ENDIF";
    case POp::Lup: return "P_LUP";
    case POp::Endlup: return "P_ENDLUP";
    case POp::Ago: return "P_AGO";
    }
    return "P_?";
}

std::string format_pcode(const PCode &code)
{
    std::ostringstream o;
    o << "; pcode syntax=" << syntax_name(code.syntax)
      << " file=" << code.name
      << " ops=" << code.ins.size() << "\n";
    for (size_t i = 0; i < code.ins.size(); i++) {
        const PInstr &in = code.ins[i];
        o << in.file << ":" << in.lineno << "  " << pop_name(in.op);
        if (!in.label.empty()) o << "  " << in.label;
        if (!in.opcode.empty()) o << "  " << in.opcode;
        if (!in.operand.empty()) o << "  " << in.operand;
        if (in.op == POp::Inst) {
            o << "  ; " << mode_name(in.syntax);
            if (in.long_mn) o << " long";
            if (in.force == FORCE_DP) o << " dp";
            else if (in.force == FORCE_ABS) o << " abs";
            else if (in.force == FORCE_LONG) o << " far";
            if (in.byte_sel) o << " sel=" << static_cast<char>(in.byte_sel);
            if (!in.expr.empty()) o << " expr=" << in.expr;
            if (!in.expr2.empty()) o << "," << in.expr2;
        } else if (in.op == POp::MxPart) {
            o << "  ; mask=" << in.i0 << " val=" << in.i1;
        } else if (in.op == POp::Cpu) {
            o << "  ; cpu=" << in.i0;
        } else if (in.op == POp::Bytes) {
            o << "  ;";
            for (uint8_t b : in.raw) {
                char buf[8];
                std::snprintf(buf, sizeof(buf), " %02X", b);
                o << buf;
            }
        }
        o << "\n";
    }
    for (const auto &e : code.errors)
        o << "; error " << e.file << ":" << e.line << ": " << e.msg << "\n";
    return o.str();
}

/* ---- algebraic expression → fully parenthesized Merlin expression ---- */

struct E {
    const char *s = "";
    int i = 0;
    bool ok = true;
    bool tilde_name = false;
};

static void eskip(E &e)
{
    while (e.s[e.i] == ' ' || e.s[e.i] == '\t') e.i++;
}

static std::string e_lor(E &e);

static bool e_word(E &e, const char *w)
{
    eskip(e);
    size_t n = std::strlen(w);
    for (size_t k = 0; k < n; k++) {
        char c = e.s[e.i + static_cast<int>(k)];
        if (std::tolower(static_cast<unsigned char>(c)) != w[k]) return false;
    }
    char after = e.s[e.i + static_cast<int>(n)];
    if (std::isalnum(static_cast<unsigned char>(after)) || after == '_') return false;
    e.i += static_cast<int>(n);
    return true;
}

static std::string e_primary(E &e)
{
    eskip(e);
    if (!e.ok) return {};
    char c = e.s[e.i];
    if (c == 0) {
        e.ok = false;
        return {};
    }
    /* ORCA/APW `&len('text')` is the character count. It is folded here. */
    if (c == '&') {
        int save = e.i;
        e.i++;
        if (e_word(e, "len")) {
            eskip(e);
            if (e.s[e.i] != '(') {
                e.ok = false;
                return {};
            }
            e.i++;
            eskip(e);
            char q = e.s[e.i];
            if (q != '\'' && q != '"') {
                e.ok = false;
                return {};
            }
            e.i++;
            int n = 0;
            while (e.s[e.i] && e.s[e.i] != q) {
                n++;
                e.i++;
            }
            if (e.s[e.i] != q) {
                e.ok = false;
                return {};
            }
            e.i++;
            eskip(e);
            if (e.s[e.i] != ')') {
                e.ok = false;
                return {};
            }
            e.i++;
            return std::to_string(n);
        }
        e.i = save;
        e.ok = false;
        return {};
    }
    if (c == '(') {
        e.i++;
        std::string inner = e_lor(e);
        eskip(e);
        if (e.s[e.i] == ')') e.i++;
        else e.ok = false;
        return inner;
    }
    if (c == '*') {
        e.i++;
        return "*";
    }
    if (c == '$' || c == '%') {
        int start = e.i++;
        if (c == '$') {
            while (std::isxdigit(static_cast<unsigned char>(e.s[e.i]))) e.i++;
        } else {
            while (e.s[e.i] == '0' || e.s[e.i] == '1' || e.s[e.i] == '_') e.i++;
        }
        if (e.i == start + 1) e.ok = false;
        return std::string(e.s + start, static_cast<size_t>(e.i - start));
    }
    if (c == '\'' || c == '"') {
        char q = c;
        int start = e.i++;
        if (e.s[e.i]) e.i++;
        if (e.s[e.i] == q) e.i++;
        return std::string(e.s + start, static_cast<size_t>(e.i - start));
    }
    if (std::isdigit(static_cast<unsigned char>(c))) {
        int start = e.i;
        while (std::isdigit(static_cast<unsigned char>(e.s[e.i]))) e.i++;
        return std::string(e.s + start, static_cast<size_t>(e.i - start));
    }
    if (c == '.' && std::isalpha(static_cast<unsigned char>(e.s[e.i + 1]))) {
        int save = e.i;
        e.i++;
        int w0 = e.i;
        while (std::isalpha(static_cast<unsigned char>(e.s[e.i]))) e.i++;
        std::string w(e.s + w0, static_cast<size_t>(e.i - w0));
        for (char &ch : w)
            ch = static_cast<char>(std::tolower(static_cast<unsigned char>(ch)));
        char sel = 0;
        if (w == "lobyte") sel = '<';
        else if (w == "hibyte") sel = '>';
        else if (w == "bankbyte") sel = '^';
        if (!sel) {
            e.ok = false;
            e.i = save;
            return {};
        }
        eskip(e);
        if (e.s[e.i] != '(') {
            e.ok = false;
            return {};
        }
        e.i++;
        std::string inner = e_lor(e);
        eskip(e);
        if (e.s[e.i] == ')') e.i++;
        else e.ok = false;
        return std::string(1, sel) + inner;
    }
    bool tilde_name = c == '~' && e.tilde_name &&
                      (std::isalpha(static_cast<unsigned char>(e.s[e.i + 1])) ||
                       e.s[e.i + 1] == '_');
    if (std::isalpha(static_cast<unsigned char>(c)) || c == '_' || c == '@' ||
        c == ']' || c == ':' || tilde_name) {
        int start = e.i++;
        while (e.s[e.i]) {
            unsigned char d = static_cast<unsigned char>(e.s[e.i]);
            if (!std::isalnum(d) && d != '_' && d != '@' && d != '$') break;
            e.i++;
        }
        return std::string(e.s + start, static_cast<size_t>(e.i - start));
    }
    e.ok = false;
    return {};
}

static std::string e_unary(E &e)
{
    eskip(e);
    if (e.s[e.i] == '+') {
        e.i++;
        return e_unary(e);
    }
    if (e.s[e.i] == '-') {
        e.i++;
        std::string v = e_unary(e);
        return "-" + v;
    }
    if (e.s[e.i] == '~') {
        unsigned char n = static_cast<unsigned char>(e.s[e.i + 1]);
        /* ORCA/M local labels are `~name`. A tilde before anything else is NOT. */
        if (!(e.tilde_name && (std::isalpha(n) || n == '_'))) {
            e.i++;
            std::string v = e_unary(e);
            return "{" + v + "!-1}";
        }
    }
    char sel = 0;
    if (e.s[e.i] == '<' || e.s[e.i] == '>' || e.s[e.i] == '^') {
        /* `<=` `>=` `<>` are comparisons, parsed lower. A following `=` or
           the other angle bracket means this is not a byte selector. */
        char n = e.s[e.i + 1];
        if (!(e.s[e.i] == '<' && (n == '=' || n == '>')) &&
            !(e.s[e.i] == '>' && n == '=')) {
            sel = e.s[e.i++];
        }
    }
    std::string v = e_primary(e);
    if (sel) v = std::string(1, sel) + v;
    return v;
}

static std::string e_bin(const std::string &a, const std::string &op, const std::string &b)
{
    return "{" + a + op + b + "}";
}

static std::string e_mul(E &e)
{
    std::string v = e_unary(e);
    for (;;) {
        eskip(e);
        char c = e.s[e.i];
        if (c == '*' || c == '/') {
            e.i++;
            v = e_bin(v, std::string(1, c), e_unary(e));
            continue;
        }
        int save = e.i;
        if (e_word(e, "mod")) {
            v = e_bin(v, "%", e_unary(e));
            continue;
        }
        e.i = save;
        break;
    }
    return v;
}

static std::string e_add(E &e)
{
    std::string v = e_mul(e);
    for (;;) {
        eskip(e);
        char c = e.s[e.i];
        if (c != '+' && c != '-') break;
        /* `->` is not subtraction. Give up rather than mis-parse it. */
        if (c == '-' && e.s[e.i + 1] == '>') {
            e.ok = false;
            break;
        }
        e.i++;
        v = e_bin(v, std::string(1, c), e_mul(e));
    }
    return v;
}

static std::string e_cmp(E &e)
{
    std::string v = e_add(e);
    for (;;) {
        eskip(e);
        int save = e.i;
        std::string op;
        if (e.s[e.i] == '<' && e.s[e.i + 1] == '>') {
            e.i += 2;
            op = "#";
        } else if (e.s[e.i] == '<' && e.s[e.i + 1] == '=') {
            e.i += 2;
            std::string r = e_add(e);
            v = "{{" + v + "<" + r + "}.{" + v + "=" + r + "}}";
            continue;
        } else if (e.s[e.i] == '>' && e.s[e.i + 1] == '=') {
            e.i += 2;
            std::string r = e_add(e);
            v = "{{" + v + ">" + r + "}.{" + v + "=" + r + "}}";
            continue;
        } else if (e.s[e.i] == '<' || e.s[e.i] == '>' || e.s[e.i] == '=') {
            op = std::string(1, e.s[e.i]);
            e.i++;
        } else break;
        if (op.empty()) {
            e.i = save;
            break;
        }
        v = e_bin(v, op, e_add(e));
    }
    return v;
}

static std::string e_band(E &e)
{
    std::string v = e_cmp(e);
    for (;;) {
        int save = e.i;
        eskip(e);
        if (e.s[e.i] == '&' && e.s[e.i + 1] != '&') {
            e.i++;
            v = e_bin(v, "&", e_cmp(e));
            continue;
        }
        e.i = save;
        if (e_word(e, ".and") || e_word(e, ".bitand")) {
            v = e_bin(v, "&", e_cmp(e));
            continue;
        }
        e.i = save;
        break;
    }
    return v;
}

static std::string e_bxor(E &e)
{
    std::string v = e_band(e);
    for (;;) {
        int save = e.i;
        eskip(e);
        bool word = false;
        if (!(e.s[e.i] == '^')) {
            e.i = save;
            if (e_word(e, ".xor") || e_word(e, ".bitxor") || e_word(e, ".eor"))
                word = true;
            else {
                e.i = save;
                break;
            }
        } else e.i++;
        v = e_bin(v, "!", e_band(e));
        (void)word;
    }
    return v;
}

static std::string e_bor(E &e)
{
    std::string v = e_bxor(e);
    for (;;) {
        int save = e.i;
        eskip(e);
        if (e.s[e.i] == '|' && e.s[e.i + 1] != '|') {
            e.i++;
            v = e_bin(v, ".", e_bxor(e));
            continue;
        }
        e.i = save;
        if (e_word(e, ".or") || e_word(e, ".bitor")) {
            v = e_bin(v, ".", e_bxor(e));
            continue;
        }
        e.i = save;
        break;
    }
    return v;
}

static std::string e_land(E &e)
{
    std::string v = e_bor(e);
    for (;;) {
        eskip(e);
        if (e.s[e.i] == '&' && e.s[e.i + 1] == '&') {
            e.i += 2;
            v = e_bin(v, "&", e_bor(e));
            continue;
        }
        break;
    }
    return v;
}

static std::string e_lor(E &e)
{
    std::string v = e_land(e);
    for (;;) {
        eskip(e);
        if (e.s[e.i] == '|' && e.s[e.i + 1] == '|') {
            e.i += 2;
            v = e_bin(v, ".", e_land(e));
            continue;
        }
        break;
    }
    return v;
}

std::string translate_algebraic(const std::string &expr, bool tilde_name)
{
    std::string t = trim_copy(expr);
    if (t.empty()) return t;
    E e;
    e.s = t.c_str();
    e.tilde_name = tilde_name;
    std::string r = e_lor(e);
    eskip(e);
    if (!e.ok || e.s[e.i]) return t;
    return r;
}

PCode compile_source(const std::string &src, const std::string &name, const Options &opt)
{
    PCode code;
    code.name = name;
    bool ok = true;
    Syntax syn;
    std::string req = upper_copy(trim_copy(opt.syntax));
    if (req.empty() || req == "AUTO") {
        syn = identify_syntax(src);
    } else {
        syn = syntax_from_name(opt.syntax, ok);
        if (!ok) {
            code.errors.push_back({name, 1, "unknown syntax '" + opt.syntax + "'"});
            return code;
        }
    }
    code.syntax = syn;
    switch (syn) {
    case Syntax::Merlin:
    case Syntax::Merlin32: {
        auto lines = parse_source(src, name);
        merlin_compile(lines, opt, code);
        break;
    }
    case Syntax::Orca:
    case Syntax::Apw:
        orca_compile(src, name, opt, code);
        break;
    case Syntax::Lisa:
        lisa_compile(src, name, opt, code);
        break;
    case Syntax::Ca65:
        ca65_compile(src, name, opt, code);
        break;
    }
    return code;
}

} // namespace qasm
