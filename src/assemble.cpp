#include "intern.hpp"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <map>
#include <sstream>

namespace merlin {

struct Sym {
    std::string name;
    int64_t value = 0;
    bool defined = false;
    bool is_var = false;
    bool is_local = false;
    bool is_colon = false;
    int scope = 0;
    int order = 0;
};

struct Macro {
    std::string name;
    std::vector<SrcLine> body;
};

struct Assembler {
    Options opt;
    Result *out = nullptr;
    std::vector<SrcLine> *lines = nullptr;
    int pass = 1;
    uint32_t pc = 0;
    uint32_t org = 0;
    bool org_set = false;
    int mx = 3;
    int xc = 2;
    bool dummy = false;
    uint32_t dummy_save = 0;
    uint32_t org_resume = 0;
    bool org_saved = false;
    bool emitting = true;
    int cond[kMaxCond]{};
    int cond_taken[kMaxCond]{};
    int cond_else[kMaxCond]{};
    int csp = 0;
    std::vector<uint8_t> obj;
    size_t chk_start = 0;
    std::string dsk_name;
    uint16_t filetype = 0x06;
    bool case_sensitive = false;
    bool ended = false;
    std::vector<Sym> syms;
    int scope_id = 0;
    int last_global_scope = 0;
    int def_order = 0;
    std::vector<Macro> macs;
    std::vector<ListLine> listing;
    uint32_t list_pc = 0;
    size_t list_off = 0;
    const SrcLine *list_ln = nullptr;
    int oz_id = 1;
    std::map<std::string, std::vector<SrcLine>> include_cache;

    std::vector<SrcLine> load_include(const SrcLine *ln, const std::string &name);
    void collect_macros_from(const std::vector<SrcLine> &ls);
    void uniquify_macro_body(std::vector<SrcLine> &body);
    void do_put_use(const SrcLine *ln, bool use_only);

    void err(const SrcLine *ln, const std::string &msg);
    int namecmp(const std::string &x, const std::string &y) const;
    bool cond_on() const { return emitting; }
    void emit_byte(uint8_t b);
    void emit_n(uint32_t v, int n);
    static int lookup_cb(void *p, const std::string &name, int64_t *val, bool *known);
    int lookup(const std::string &name, int64_t *val, bool *known);
    Sym *find_sym(const std::string &name, bool var_only);
    void define_label(const SrcLine *ln, const std::string &name, int64_t val, bool is_var);
    bool eval_on(const SrcLine *ln, const std::string &expr, int64_t &out);
    Macro *find_macro(const std::string &name);
    void collect_macros();
    void do_pseudo(const SrcLine *ln);
    void do_instruction(const SrcLine *ln);
    void do_range(std::vector<SrcLine> &ls, int lo, int hi);
    void run_pass(int p);
    void begin_list(const SrcLine *ln);
    void end_list();
};

void Assembler::err(const SrcLine *ln, const std::string &msg)
{
    Error e;
    if (ln) {
        e.file = ln->file;
        e.line = ln->lineno;
    }
    e.msg = msg;
    out->errors.push_back(std::move(e));
}

int Assembler::namecmp(const std::string &x, const std::string &y) const
{
    return case_sensitive ? x.compare(y) : icmp(x, y);
}

void Assembler::begin_list(const SrcLine *ln)
{
    if (pass != 2) return;
    list_pc = pc;
    list_off = obj.size();
    list_ln = ln;
}

void Assembler::end_list()
{
    if (pass != 2 || !list_ln) return;
    ListLine ll;
    ll.pc = list_pc;
    ll.lineno = list_ln->lineno;
    if (list_off <= obj.size())
        ll.bytes.assign(obj.begin() + static_cast<std::ptrdiff_t>(list_off), obj.end());
    if (!list_ln->raw.empty())
        ll.source = list_ln->raw;
    else {
        ll.source = list_ln->label;
        if (!list_ln->opcode.empty()) {
            if (!ll.source.empty()) ll.source += "  ";
            ll.source += list_ln->opcode;
            if (!list_ln->operand.empty())
                ll.source += "  " + list_ln->operand;
        }
    }
    listing.push_back(std::move(ll));
    list_ln = nullptr;
}

void Assembler::emit_byte(uint8_t b)
{
    if (!cond_on()) return;
    if (pass == 2 && !dummy)
        obj.push_back(b);
    pc++;
}

void Assembler::emit_n(uint32_t v, int n)
{
    for (int i = 0; i < n; i++)
        emit_byte(static_cast<uint8_t>((v >> (8 * i)) & 0xFF));
}

int Assembler::lookup_cb(void *p, const std::string &name, int64_t *val, bool *known)
{
    return static_cast<Assembler *>(p)->lookup(name, val, known);
}

int Assembler::lookup(const std::string &name, int64_t *val, bool *known)
{
    *known = false;
    *val = 0;
    int colon_scope = name.size() && name[0] == ':' ? last_global_scope : -1;
    int best = -1;
    for (int i = 0; i < static_cast<int>(syms.size()); i++) {
        if (namecmp(syms[i].name, name) != 0) continue;
        if (syms[i].is_colon && syms[i].scope != colon_scope) continue;
        if (syms[i].is_local) {
            if (syms[i].order <= def_order) best = i;
            continue;
        }
        if (syms[i].defined) {
            *val = syms[i].value;
            *known = true;
            return 0;
        }
    }
    if (best >= 0 && syms[best].defined) {
        *val = syms[best].value;
        *known = true;
    }
    return 0;
}

Sym *Assembler::find_sym(const std::string &name, bool var_only)
{
    for (int i = static_cast<int>(syms.size()) - 1; i >= 0; i--) {
        if (namecmp(syms[i].name, name) != 0) continue;
        if (var_only && !syms[i].is_var) continue;
        if (syms[i].is_colon && syms[i].scope != last_global_scope) continue;
        return &syms[i];
    }
    return nullptr;
}

void Assembler::define_label(const SrcLine *ln, const std::string &name, int64_t val, bool is_var)
{
    if (name.empty()) return;
    def_order++;
    if (name[0] != ']' && name[0] != ':') {
        scope_id++;
        last_global_scope = scope_id;
    }
    if (pass == 2 && !is_var) return;
    if (is_var) {
        Sym *s = find_sym(name, true);
        if (!s) {
            syms.push_back({});
            s = &syms.back();
            s->name = name;
        }
        s->is_var = true;
        s->value = val;
        s->defined = true;
        s->order = def_order;
        return;
    }
    if (name[0] == ']') {
        Sym s;
        s.name = name;
        s.is_local = true;
        s.value = val;
        s.defined = true;
        s.order = def_order;
        s.scope = last_global_scope;
        syms.push_back(std::move(s));
        return;
    }
    Sym *s = find_sym(name, false);
    if (s && s->defined && s->value != val && pass == 2)
        err(ln, "duplicate label " + name);
    if (!s) {
        syms.push_back({});
        s = &syms.back();
        s->name = name;
        s->is_colon = name[0] == ':';
        s->scope = last_global_scope;
    }
    s->value = val;
    s->defined = true;
    s->order = def_order;
}

bool Assembler::eval_on(const SrcLine *ln, const std::string &expr, int64_t &outv)
{
    ExprCtx ctx;
    ctx.pc = pc;
    ctx.mx = mx;
    ctx.algebraic = opt.algebraic;
    ctx.case_sensitive = case_sensitive;
    ctx.pass = pass;
    ctx.asm_ptr = this;
    ctx.lookup = lookup_cb;
    std::string e;
    if (!eval_expr(ctx, expr, outv, e)) {
        if (pass == 2) err(ln, e + " in '" + expr + "'");
        outv = 0;
        return false;
    }
    return true;
}

static bool is_pseudo(const std::string &op)
{
    static const char *ps[] = {
        "ORG", "OBJ", "EQU", "=", "HEX", "DFB", "DB", "DA", "DW", "DDB",
        "ADR", "ADRL", "DS", "ASC", "DCI", "INV", "FLS", "REV", "STR", "STRL",
        "MX", "XC", "LST", "END", "DUM", "DEND", "DO", "ELSE", "FIN", "IF",
        "MAC", "EOM", "<<<", "PMC", ">>>", "LUP", "--^", "SAV", "DSK", "TYP",
        "REL", "LNK", "ENT", "EXT", "PUT", "USE", "CAS", "ERR", "CHK",
        "AST", "SKP", "PAG", "TR", "EXP", "PAU", "KBD", "DAT", "DATE",
        "VAR", "USR", "FLO", "LSTDO", "GEQU", "GEQ", "OVR", "ASM", "SYM",
        "LEN", "POS", "CYC", nullptr
    };
    for (int i = 0; ps[i]; i++)
        if (icmp(op, ps[i]) == 0) return true;
    return false;
}

Macro *Assembler::find_macro(const std::string &name)
{
    for (auto &m : macs)
        if (namecmp(m.name, name) == 0) return &m;
    return nullptr;
}

void Assembler::collect_macros_from(const std::vector<SrcLine> &ls)
{
    for (int i = 0; i < static_cast<int>(ls.size()); i++) {
        if (icmp(ls[i].opcode, "MAC") != 0 || !ls[i].has_label) continue;
        if (find_macro(ls[i].label)) {
            int nest = 1, j = i + 1;
            for (; j < static_cast<int>(ls.size()); j++) {
                if (icmp(ls[j].opcode, "MAC") == 0) nest++;
                if (icmp(ls[j].opcode, "EOM") == 0 || icmp(ls[j].opcode, "<<<") == 0) {
                    nest--;
                    if (nest == 0) break;
                }
            }
            i = j;
            continue;
        }
        Macro m;
        m.name = ls[i].label;
        int nest = 1, j = i + 1;
        for (; j < static_cast<int>(ls.size()); j++) {
            if (icmp(ls[j].opcode, "MAC") == 0) nest++;
            if (icmp(ls[j].opcode, "EOM") == 0 || icmp(ls[j].opcode, "<<<") == 0) {
                nest--;
                if (nest == 0) break;
            }
            m.body.push_back(ls[j]);
        }
        macs.push_back(std::move(m));
        i = j;
    }
}

void Assembler::collect_macros()
{
    collect_macros_from(*lines);
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
        } else {
            out.push_back(s[i++]);
        }
    }
    return out;
}

void Assembler::uniquify_macro_body(std::vector<SrcLine> &body)
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

std::vector<SrcLine> Assembler::load_include(const SrcLine *ln, const std::string &name)
{
    std::string from = ln && !ln->file.empty() ? ln->file : ".";
    std::string path = resolve_include(name, from, opt.include_dirs);
    if (path.empty()) {
        if (pass == 2)
            err(ln, "cannot open PUT/USE file '" + strip_quotes(name) + "'");
        return {};
    }
    auto it = include_cache.find(path);
    if (it != include_cache.end()) return it->second;
    std::string e;
    std::string src = read_file(path, &e);
    if (!e.empty() && src.empty()) {
        if (pass == 2) err(ln, e + ": " + path);
        return {};
    }
    auto parsed = parse_source(src, path);
    include_cache[path] = parsed;
    return parsed;
}

void Assembler::do_put_use(const SrcLine *ln, bool use_only)
{
    auto inc = load_include(ln, ln->operand);
    collect_macros_from(inc);
    if (use_only) return;
    if (!inc.empty())
        do_range(inc, 0, static_cast<int>(inc.size()));
}

static std::string subst_params(const std::string &src, const std::string p[10])
{
    std::string dst;
    for (size_t i = 0; i < src.size(); ) {
        if (src[i] == ']' && i + 1 < src.size() && src[i + 1] >= '1' && src[i + 1] <= '9') {
            int k = src[i + 1] - '0';
            dst += p[k];
            i += 2;
        } else {
            dst.push_back(src[i++]);
        }
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

static void apply_mx(Assembler &a, const std::string &cname, int64_t imm)
{
    uint8_t m = static_cast<uint8_t>(imm & 0xFF);
    if (icmp(cname, "SEP") == 0) {
        if (m & 0x20) a.mx |= 2;
        if (m & 0x10) a.mx |= 1;
    } else if (icmp(cname, "REP") == 0) {
        if (m & 0x20) a.mx &= ~2;
        if (m & 0x10) a.mx &= ~1;
    }
}

static int operand_bytes(AddrMode am, int mx, const std::string &cname)
{
    switch (am) {
    case AM_IMP: return 0;
    case AM_IMM8: return 1;
    case AM_IMM16: return 2;
    case AM_IMM: {
        int w = imm_width_reg(cname);
        if (w == 8) return 1;
        if (w == 16) return 2;
        if (w == 1) return (mx & 1) ? 1 : 2;
        return (mx & 2) ? 1 : 2;
    }
    case AM_DP: case AM_DPX: case AM_DPY:
    case AM_IND: case AM_INDX: case AM_INDY:
    case AM_INDL: case AM_INDLY:
    case AM_SR: case AM_SRIY: case AM_REL:
        return 1;
    case AM_ABS: case AM_ABSX: case AM_ABSY:
    case AM_ABSIND: case AM_ABSINDX: case AM_ABSINDL:
    case AM_RELL:
        return 2;
    case AM_LONG: case AM_LONGX: case AM_BLK:
        return 3;
    default: return 0;
    }
}

static AddrMode resolve_am(Assembler &a, const std::string &cname, const OperandForm &f,
                           int64_t value, bool known, int force, bool long_mn)
{
    int cpu = a.xc;
    int force2 = f.force ? f.force : force;
    if (long_mn) force2 = FORCE_LONG;

    if (is_branch_long(cname)) return AM_RELL;
    if (is_branch(cname)) return AM_REL;
    if (icmp(cname, "PEA") == 0) return AM_IMM16;
    if (icmp(cname, "PER") == 0) return AM_RELL;
    if (icmp(cname, "MVN") == 0 || icmp(cname, "MVP") == 0) return AM_BLK;
    if (icmp(cname, "SEP") == 0 || icmp(cname, "REP") == 0 || icmp(cname, "COP") == 0)
        return AM_IMM8;
    /* BRK / WDM take a signature byte; Merlin 16+ accepts #imm, and
       testdata / Merlin 32 also write a bare operand (BRK ZP, brk $00). */
    if ((icmp(cname, "BRK") == 0 || icmp(cname, "WDM") == 0) && f.syntax != SYN_IMP)
        return AM_IMM8;

    switch (f.syntax) {
    case SYN_IMP: return AM_IMP;
    case SYN_IMM: return AM_IMM;
    case SYN_S: return AM_SR;
    case SYN_SIY: return AM_SRIY;
    case SYN_INDX:
        if (opcode_supports(cname, AM_ABSINDX, cpu) && !opcode_supports(cname, AM_INDX, cpu))
            return AM_ABSINDX;
        return AM_INDX;
    case SYN_INDY: return AM_INDY;
    case SYN_INDLY: return AM_INDLY;
    case SYN_IND:
        if (opcode_supports(cname, AM_ABSIND, cpu) &&
            (!opcode_supports(cname, AM_IND, cpu) || force2 == FORCE_ABS ||
             (known && value > 0xFF)))
            return AM_ABSIND;
        return AM_IND;
    case SYN_INDL:
        if (opcode_supports(cname, AM_ABSINDL, cpu) &&
            (!opcode_supports(cname, AM_INDL, cpu) || force2 == FORCE_ABS ||
             (known && value > 0xFF)))
            return AM_ABSINDL;
        return AM_INDL;
    case SYN_X:
        if (force2 == FORCE_LONG && opcode_supports(cname, AM_LONGX, cpu)) return AM_LONGX;
        if (force2 == FORCE_DP ||
            (force2 == FORCE_NONE && known && value <= 0xFF && opcode_supports(cname, AM_DPX, cpu)))
            return AM_DPX;
        return AM_ABSX;
    case SYN_Y:
        if (force2 == FORCE_DP ||
            (force2 == FORCE_NONE && known && value <= 0xFF && opcode_supports(cname, AM_DPY, cpu)))
            return AM_DPY;
        return AM_ABSY;
    case SYN_BLK: return AM_BLK;
    case SYN_ABS:
    default:
        if (force2 == FORCE_LONG && opcode_supports(cname, AM_LONG, cpu)) return AM_LONG;
        if (force2 == FORCE_DP) return AM_DP;
        if (force2 == FORCE_ABS) {
            if (opcode_supports(cname, AM_ABS, cpu)) return AM_ABS;
            if (opcode_supports(cname, AM_LONG, cpu)) return AM_LONG;
            return AM_ABS;
        }
        if (known && value <= 0xFF && opcode_supports(cname, AM_DP, cpu)) return AM_DP;
        if (known && value > 0xFFFF && opcode_supports(cname, AM_LONG, cpu)) return AM_LONG;
        if (opcode_supports(cname, AM_ABS, cpu)) return AM_ABS;
        /* JML / JSL have no 16-bit absolute form; a label or $00..$FFFF
           operand still encodes as long (bank 0). */
        if (opcode_supports(cname, AM_LONG, cpu)) return AM_LONG;
        return AM_ABS;
    }
}

static int64_t extract_sel(int64_t v, int sel, int nbytes)
{
    if (sel == '<') return nbytes >= 2 ? v & 0xFFFF : v & 0xFF;
    if (sel == '>') return nbytes >= 2 ? (v >> 8) & 0xFFFF : (v >> 8) & 0xFF;
    if (sel == '^' || sel == '|')
        return nbytes >= 2 ? (v >> 16) & 0xFFFF : (v >> 16) & 0xFF;
    return v;
}

static void emit_code(Assembler &a, const SrcLine *ln, AddrMode am, uint8_t opc,
                     int64_t val, int64_t val2, int sel, int nbytes)
{
    a.emit_byte(opc);
    if (am == AM_REL) {
        int32_t rel = static_cast<int32_t>(val) - static_cast<int32_t>(a.pc + 1);
        if (a.pass == 2 && (rel < -128 || rel > 127))
            a.err(ln, "branch out of range");
        a.emit_byte(static_cast<uint8_t>(rel));
        return;
    }
    if (am == AM_RELL) {
        int32_t rel = static_cast<int32_t>(val) - static_cast<int32_t>(a.pc + 2);
        a.emit_n(static_cast<uint32_t>(rel), 2);
        return;
    }
    if (am == AM_BLK) {
        uint8_t dst = (val2 & 0xFFFF00) == 0 ? static_cast<uint8_t>(val2)
                                             : static_cast<uint8_t>((val2 >> 16) & 0xFF);
        uint8_t src = (val & 0xFFFF00) == 0 ? static_cast<uint8_t>(val)
                                            : static_cast<uint8_t>((val >> 16) & 0xFF);
        a.emit_byte(dst);
        a.emit_byte(src);
        return;
    }
    a.emit_n(static_cast<uint32_t>(extract_sel(val, sel, nbytes)), nbytes);
}

static uint8_t ascii_map(uint8_t ch, const std::string &kind, int quote)
{
    int hi = (quote == '"') ? 0x80 : 0x00;
    if (icmp(kind, "INV") == 0) {
        if (ch >= 0x40 && ch <= 0x7F) return static_cast<uint8_t>(ch & 0x3F);
        return static_cast<uint8_t>(ch & 0x3F);
    }
    if (icmp(kind, "FLS") == 0)
        return static_cast<uint8_t>((ch & 0x3F) | 0x40);
    return static_cast<uint8_t>((ch & 0x7F) | hi);
}

static void emit_string_pseudo(Assembler &a, const SrcLine *ln, const std::string &kind)
{
    const char *s = ln->operand.c_str();
    while (*s == ' ' || *s == '\t') s++;
    if (icmp(kind, "ASC") == 0 && *s == '#') {
        int neg = 0, pad = 0;
        s++;
        if (*s == '\'') s++;
        else if (*s == '"') { neg = 1; s++; }
        if (*s == '>') { pad = 1; s++; }
        int64_t v = 0;
        a.eval_on(ln, s, v);
        char buf[16];
        std::snprintf(buf, sizeof(buf), pad ? "%5d" : "%d", static_cast<int>(v));
        for (char *p = buf; *p; p++) {
            auto ch = static_cast<uint8_t>(*p);
            if (neg) ch |= 0x80;
            a.emit_byte(ch);
        }
        return;
    }
    bool strl = icmp(kind, "STRL") == 0;
    bool str1 = icmp(kind, "STR") == 0;
    bool dci = icmp(kind, "DCI") == 0;
    bool rev = icmp(kind, "REV") == 0;
    std::vector<uint8_t> bytes;
    while (*s && bytes.size() < 500) {
        while (*s == ' ' || *s == '\t' || *s == ',') s++;
        if (!*s) break;
        if (*s == '\'' || *s == '"') {
            int q = *s++;
            while (*s && *s != q)
                bytes.push_back(ascii_map(static_cast<uint8_t>(*s++), kind, q));
            if (*s == q) s++;
        } else if (std::isxdigit(static_cast<unsigned char>(*s))) {
            int v = 0, d = 0;
            while (std::isxdigit(static_cast<unsigned char>(*s))) {
                int h = std::isdigit(static_cast<unsigned char>(*s))
                            ? *s - '0'
                            : std::tolower(static_cast<unsigned char>(*s)) - 'a' + 10;
                v = (v << 4) | h;
                s++;
                d++;
                if (d == 2) {
                    bytes.push_back(static_cast<uint8_t>(v));
                    v = 0;
                    d = 0;
                }
            }
        } else break;
    }
    if (rev)
        std::reverse(bytes.begin(), bytes.end());
    if (dci && !bytes.empty()) bytes.back() ^= 0x80;
    if (str1) a.emit_byte(static_cast<uint8_t>(bytes.size()));
    if (strl) a.emit_n(static_cast<uint32_t>(bytes.size()), 2);
    for (auto b : bytes) a.emit_byte(b);
}

static void emit_hex(Assembler &a, const SrcLine *ln)
{
    const char *s = ln->operand.c_str();
    int acc = 0, digits = 0;
    while (*s) {
        if (*s == ',' || *s == ' ' || *s == '\t') { s++; continue; }
        if (!std::isxdigit(static_cast<unsigned char>(*s))) {
            if (a.pass == 2) a.err(ln, "bad HEX operand");
            break;
        }
        int h = std::isdigit(static_cast<unsigned char>(*s))
                    ? *s - '0'
                    : std::tolower(static_cast<unsigned char>(*s)) - 'a' + 10;
        acc = (acc << 4) | h;
        digits++;
        s++;
        if (digits == 2) {
            a.emit_byte(static_cast<uint8_t>(acc));
            acc = 0;
            digits = 0;
        }
    }
    if (digits && a.pass == 2) a.err(ln, "HEX needs even number of digits");
}

static void emit_list_data(Assembler &a, const SrcLine *ln, const std::string &kind)
{
    int width = 1, hi_first = 0;
    if (icmp(kind, "DA") == 0 || icmp(kind, "DW") == 0) width = 2;
    else if (icmp(kind, "DDB") == 0) { width = 2; hi_first = 1; }
    else if (icmp(kind, "ADR") == 0) width = 3;
    else if (icmp(kind, "ADRL") == 0) width = 4;

    std::string buf = ln->operand;
    size_t pos = 0;
    while (pos < buf.size()) {
        size_t comma = buf.find(',', pos);
        std::string tok = trim_copy(comma == std::string::npos ? buf.substr(pos)
                                                              : buf.substr(pos, comma - pos));
        int64_t v = 0;
        a.eval_on(ln, tok, v);
        if (icmp(kind, "DFB") == 0 || icmp(kind, "DB") == 0) {
            v &= 0xFF;
            a.emit_byte(static_cast<uint8_t>(v));
        } else if (hi_first) {
            a.emit_byte(static_cast<uint8_t>((v >> 8) & 0xFF));
            a.emit_byte(static_cast<uint8_t>(v & 0xFF));
        } else {
            a.emit_n(static_cast<uint32_t>(v), width);
        }
        if (comma == std::string::npos) break;
        pos = comma + 1;
    }
}

static int filetype_from(const std::string &s0)
{
    std::string t = trim_copy(s0);
    if (!t.empty() && t[0] == '$') return static_cast<int>(std::strtol(t.c_str() + 1, nullptr, 16));
    if (icmp(t, "BIN") == 0) return 0x06;
    if (icmp(t, "SYS") == 0) return 0xFF;
    if (icmp(t, "S16") == 0 || icmp(t, "SYS16") == 0) return 0xB3;
    if (icmp(t, "CDA") == 0) return 0xB9;
    if (icmp(t, "NDA") == 0) return 0xB8;
    if (icmp(t, "EXE") == 0) return 0xB5;
    if (icmp(t, "TXT") == 0) return 0x04;
    if (icmp(t, "SRC") == 0) return 0xB0;
    if (icmp(t, "LNK") == 0) return 0x2E;
    return static_cast<int>(std::strtol(t.c_str(), nullptr, 0));
}

/* 10-byte SANE extended (same layout as 80-bit x87). */
static void sane_extended(double x, uint8_t out[10])
{
    std::memset(out, 0, 10);
    if (x == 0.0) {
        if (std::signbit(x)) out[9] = 0x80;
        return;
    }
    bool neg = std::signbit(x);
    x = std::fabs(x);
    if (std::isinf(x) || std::isnan(x)) {
        out[9] = static_cast<uint8_t>(neg ? 0xFF : 0x7F);
        out[8] = 0xFF;
        out[7] = std::isnan(x) ? 0xC0 : 0x80;
        return;
    }
    int exp = 0;
    double m = std::frexp(x, &exp); /* [0.5, 1) */
    int sane_exp = exp - 1 + 16383;
    if (sane_exp <= 0) {
        if (neg) out[9] = 0x80;
        return;
    }
    if (sane_exp >= 0x7FFF) {
        out[9] = static_cast<uint8_t>(neg ? 0xFF : 0x7F);
        out[8] = 0xFF;
        out[7] = 0x80;
        return;
    }
    /* significand = m * 2^64 → [2^63, 2^64). Shift from 2^63 to avoid
       overflowing uint64 when m rounds to 1. */
    uint64_t frac = static_cast<uint64_t>(std::ldexp(m, 63)) << 1;
    for (int i = 0; i < 8; i++)
        out[i] = static_cast<uint8_t>((frac >> (8 * i)) & 0xFF);
    uint16_t ew = static_cast<uint16_t>(sane_exp);
    if (neg) ew |= 0x8000;
    out[8] = static_cast<uint8_t>(ew & 0xFF);
    out[9] = static_cast<uint8_t>(ew >> 8);
}

static void emit_flo(Assembler &a, const SrcLine *ln)
{
    std::string s = strip_quotes(ln->operand);
    if (s.empty()) {
        uint8_t z[10]{};
        for (int i = 0; i < 10; i++) a.emit_byte(z[i]);
        return;
    }
    char *end = nullptr;
    double v = std::strtod(s.c_str(), &end);
    if (end == s.c_str() && a.pass == 2)
        a.err(ln, "bad FLO operand");
    uint8_t b[10];
    sane_extended(v, b);
    for (int i = 0; i < 10; i++) a.emit_byte(b[i]);
}

static void emit_date(Assembler &a, const SrcLine *ln)
{
    int64_t mode = 0;
    if (!ln->operand.empty())
        a.eval_on(ln, ln->operand, mode);
    if (mode <= 0) return; /* listing-only on original Merlin */

    std::time_t t = std::time(nullptr);
    std::tm tm{};
#if defined(_WIN32)
    localtime_s(&tm, &t);
#else
    localtime_r(&t, &tm);
#endif
    static const char *mon[] = {"JAN","FEB","MAR","APR","MAY","JUN",
                                "JUL","AUG","SEP","OCT","NOV","DEC"};
    int m = tm.tm_mon;
    if (m < 0 || m > 11) m = 0;
    char buf[40];
    int want = 0;
    int pos_ascii = 0;
    int kind = static_cast<int>(mode);
    if (kind >= 5 && kind <= 8) {
        pos_ascii = 1;
        kind -= 4;
    }
    switch (kind) {
    case 1:
        std::snprintf(buf, sizeof(buf), "%02d-%s-%02d",
                      tm.tm_mday, mon[m], tm.tm_year % 100);
        want = 9;
        break;
    case 2:
        std::snprintf(buf, sizeof(buf), "%02d/%02d/%02d",
                      tm.tm_mon + 1, tm.tm_mday, tm.tm_year % 100);
        want = 8;
        break;
    case 3: {
        int hour = tm.tm_hour % 12;
        if (hour == 0) hour = 12;
        std::snprintf(buf, sizeof(buf), "%02d-%s-%02d %2d:%02d:%02d %s",
                      tm.tm_mday, mon[m], tm.tm_year % 100,
                      hour, tm.tm_min, tm.tm_sec,
                      tm.tm_hour >= 12 ? "PM" : "AM");
        want = 22;
        break;
    }
    case 4: {
        int hour = tm.tm_hour % 12;
        if (hour == 0) hour = 12;
        std::snprintf(buf, sizeof(buf), "%02d/%02d/%02d %2d:%02d:%02d %s",
                      tm.tm_mon + 1, tm.tm_mday, tm.tm_year % 100,
                      hour, tm.tm_min, tm.tm_sec,
                      tm.tm_hour >= 12 ? "PM" : "AM");
        want = 20;
        break;
    }
    default:
        return;
    }
    std::string s = buf;
    if (static_cast<int>(s.size()) < want) s.append(static_cast<size_t>(want - s.size()), ' ');
    if (static_cast<int>(s.size()) > want) s.resize(static_cast<size_t>(want));
    for (char c : s) {
        auto b = static_cast<uint8_t>(c);
        if (!pos_ascii) b |= 0x80;
        a.emit_byte(b);
    }
}

void Assembler::do_pseudo(const SrcLine *ln)
{
    const auto &op = ln->opcode;
    if (icmp(op, "LST") == 0 || icmp(op, "EXP") == 0 || icmp(op, "TR") == 0 ||
        icmp(op, "PAU") == 0 || icmp(op, "PAG") == 0 || icmp(op, "AST") == 0 ||
        icmp(op, "SKP") == 0 || icmp(op, "KBD") == 0)
        return;
    if (icmp(op, "END") == 0) { ended = true; return; }
    if (icmp(op, "CAS") == 0) {
        if (nicmp(ln->operand, "SE", 2) == 0) case_sensitive = true;
        if (nicmp(ln->operand, "IN", 2) == 0) case_sensitive = false;
        return;
    }
    if (icmp(op, "XC") == 0) {
        if (icmp(ln->operand, "OFF") == 0) xc = 0;
        else if (xc < 2) xc++;
        return;
    }
    if (icmp(op, "MX") == 0) {
        int64_t v = 3;
        eval_on(ln, ln->operand.empty() ? "%11" : ln->operand, v);
        mx = static_cast<int>(v & 3);
        return;
    }
    if (icmp(op, "ORG") == 0) {
        /* Bare ORG restores the PC saved by the previous ORG (merlin32). */
        if (trim_copy(ln->operand).empty()) {
            if (org_saved) {
                pc = org_resume;
                org_saved = false;
            }
            return;
        }
        int64_t v = 0;
        eval_on(ln, ln->operand, v);
        if (!dummy) {
            org_resume = pc;
            org_saved = true;
            if (!org_set) org = static_cast<uint32_t>(v);
            org_set = true;
            chk_start = obj.size();
        }
        pc = static_cast<uint32_t>(v);
        return;
    }
    if (icmp(op, "CHK") == 0) {
        uint8_t x = 0;
        if (pass == 2)
            for (size_t i = chk_start; i < obj.size(); i++) x ^= obj[i];
        emit_byte(x);
        chk_start = obj.size();
        return;
    }
    if (icmp(op, "DUM") == 0) {
        int64_t v = 0;
        eval_on(ln, ln->operand, v);
        dummy_save = pc;
        pc = static_cast<uint32_t>(v);
        dummy = true;
        return;
    }
    if (icmp(op, "DEND") == 0) {
        pc = dummy_save;
        dummy = false;
        return;
    }
    if (icmp(op, "EQU") == 0 || op == "=" || icmp(op, "GEQU") == 0 ||
        icmp(op, "GEQ") == 0) {
        int64_t v = 0;
        eval_on(ln, ln->operand, v);
        bool is_var = ln->has_label && !ln->label.empty() && ln->label[0] == ']';
        define_label(ln, ln->label, v, is_var);
        return;
    }
    if (icmp(op, "TYP") == 0) {
        filetype = static_cast<uint16_t>(filetype_from(ln->operand));
        return;
    }
    if (icmp(op, "DSK") == 0 || icmp(op, "SAV") == 0) {
        dsk_name = trim_copy(ln->operand);
        if (dsk_name.size() >= 2 &&
            (dsk_name.front() == '"' || dsk_name.front() == '\'') &&
            dsk_name.back() == dsk_name.front())
            dsk_name = dsk_name.substr(1, dsk_name.size() - 2);
        return;
    }
    if (icmp(op, "PUT") == 0) {
        if (cond_on()) do_put_use(ln, false);
        return;
    }
    if (icmp(op, "USE") == 0) {
        if (cond_on()) do_put_use(ln, true);
        return;
    }
    if (icmp(op, "VAR") == 0) {
        if (!cond_on()) return;
        std::string p[10];
        split_mac_args(ln->operand, p);
        for (int i = 1; i <= 9; i++) {
            if (p[i].empty()) break;
            int64_t v = 0;
            eval_on(ln, p[i], v);
            define_label(ln, "]" + std::to_string(i), v, true);
        }
        return;
    }
    if (icmp(op, "FLO") == 0) {
        if (cond_on()) emit_flo(*this, ln);
        return;
    }
    if (icmp(op, "DATE") == 0) {
        if (cond_on()) emit_date(*this, ln);
        return;
    }
    if (icmp(op, "OBJ") == 0 || icmp(op, "DAT") == 0)
        return;
    if (icmp(op, "USR") == 0) {
        /* Merlin USR is a 2-byte user opcode; merlin32 opcode tables
           rely on that width (ERR *-CODES-2). */
        emit_n(0, 2);
        return;
    }
    if (icmp(op, "OVR") == 0 || icmp(op, "ASM") == 0 || icmp(op, "SYM") == 0 ||
        icmp(op, "CYC") == 0)
        return;
    if (icmp(op, "LEN") == 0 || icmp(op, "POS") == 0) {
        std::string n = trim_copy(ln->operand);
        if (n.empty()) n = ln->label;
        if (!n.empty())
            define_label(ln, n, 0, false);
        return;
    }
    if (icmp(op, "REL") == 0) {
        /* absolute assembler: accept, start PC at 0 if no ORG yet */
        if (!org_set) {
            pc = 0;
            org = 0;
            org_set = true;
        }
        return;
    }
    if (icmp(op, "LNK") == 0 || icmp(op, "ENT") == 0) {
        if (ln->has_label)
            define_label(ln, ln->label, pc, false);
        return;
    }
    if (icmp(op, "EXT") == 0) {
        /* unresolved external: define as 0 so absolute assembly can proceed.
           Merlin allows a comma list: EXT a,b,c */
        std::string names = ln->operand;
        if (ln->has_label)
            define_label(ln, ln->label, 0, false);
        size_t pos = 0;
        while (pos <= names.size()) {
            size_t comma = names.find(',', pos);
            std::string n = trim_copy(comma == std::string::npos
                                          ? names.substr(pos)
                                          : names.substr(pos, comma - pos));
            if (!n.empty())
                define_label(ln, n, 0, false);
            if (comma == std::string::npos) break;
            pos = comma + 1;
        }
        return;
    }

    if (!cond_on() && icmp(op, "DO") != 0 && icmp(op, "IF") != 0 &&
        icmp(op, "ELSE") != 0 && icmp(op, "FIN") != 0)
        return;

    if (icmp(op, "HEX") == 0) { emit_hex(*this, ln); return; }
    if (icmp(op, "DFB") == 0 || icmp(op, "DB") == 0 || icmp(op, "DA") == 0 ||
        icmp(op, "DW") == 0 || icmp(op, "DDB") == 0 || icmp(op, "ADR") == 0 ||
        icmp(op, "ADRL") == 0) {
        emit_list_data(*this, ln, op);
        return;
    }
    if (icmp(op, "DS") == 0) {
        std::string left = ln->operand, right;
        auto c = left.find(',');
        if (c != std::string::npos) {
            right = trim_copy(left.substr(c + 1));
            left = left.substr(0, c);
        }
        left = trim_copy(left);
        int64_t fill = 0, n = 0;
        if (!left.empty() && left[0] == '\\') {
            uint32_t next = (pc + 0xFF) & ~0xFFu;
            n = static_cast<int64_t>(next - pc);
            if (n == 0) n = 256;
        } else {
            eval_on(ln, left, n);
        }
        if (!right.empty()) eval_on(ln, right, fill);
        if (n < 0) n = 0;
        if (n > 0x10000) n = 0x10000;
        for (int64_t i = 0; i < n; i++) emit_byte(static_cast<uint8_t>(fill));
        return;
    }
    if (icmp(op, "ASC") == 0 || icmp(op, "STR") == 0 || icmp(op, "STRL") == 0 ||
        icmp(op, "DCI") == 0 || icmp(op, "INV") == 0 || icmp(op, "FLS") == 0 ||
        icmp(op, "REV") == 0) {
        emit_string_pseudo(*this, ln, op);
        return;
    }
    if (icmp(op, "ERR") == 0) {
        int64_t v = 0;
        eval_on(ln, ln->operand, v);
        if (v && pass == 2) err(ln, "ERR forced");
    }
}

void Assembler::do_instruction(const SrcLine *ln)
{
    if (!cond_on()) return;
    int force = FORCE_NONE;
    bool long_mn = false;
    std::string cname = opcode_canonical(ln->opcode, force, long_mn);
    OperandForm f = parse_operand_form(ln->operand);
    /* 6502 / Merlin 32 write ASL A (etc.); Merlin 16+ uses a bare mnemonic.
       Treat a lone A as accumulator so it is not looked up as a label. */
    if (is_alu_acc(cname) && f.syntax == SYN_ABS && icmp(f.expr, "A") == 0) {
        f.syntax = SYN_IMP;
        f.expr.clear();
    }

    int64_t val = 0, val2 = 0;
    bool known = true;
    if (!f.expr.empty()) {
        ExprCtx ctx;
        ctx.pc = pc;
        ctx.mx = mx;
        ctx.algebraic = opt.algebraic;
        ctx.case_sensitive = case_sensitive;
        ctx.pass = pass;
        ctx.asm_ptr = this;
        ctx.lookup = lookup_cb;
        std::string e;
        eval_expr(ctx, f.expr, val, e);
        known = e.empty();
        if (pass == 1) {
            bool lab_known = false;
            int64_t lv = 0;
            lookup(f.expr, &lv, &lab_known);
            if (!lab_known && !f.expr.empty() &&
                !std::isdigit(static_cast<unsigned char>(f.expr[0])) &&
                f.expr[0] != '$' && f.expr[0] != '%' && f.expr[0] != '#' &&
                f.expr[0] != '\'' && f.expr[0] != '"' && f.expr[0] != '{' &&
                f.expr[0] != '<' && f.expr[0] != '>' && f.expr[0] != '*' &&
                f.expr.find('+') == std::string::npos &&
                f.expr.find('-') == std::string::npos)
                known = false;
            else if (lab_known) {
                known = true;
                val = lv;
            }
        }
        if (pass == 2 && !e.empty()) err(ln, e);
    }
    if (!f.expr2.empty()) eval_on(ln, f.expr2, val2);

    AddrMode am = resolve_am(*this, cname, f, val, known, force, long_mn);
    if (f.syntax == SYN_IMP && is_alu_acc(cname)) am = AM_IMP;

    uint8_t opc = 0;
    if (opcode_encode(cname, am, xc, opc) != 0) {
        if (am == AM_IMM && opcode_encode(cname, AM_IMM8, xc, opc) == 0)
            am = AM_IMM8;
        else if (am == AM_DP && opcode_encode(cname, AM_ABS, xc, opc) == 0)
            am = AM_ABS;
        else {
            if (pass == 2) err(ln, "bad addressing mode for " + cname);
            return;
        }
    }
    emit_code(*this, ln, am, opc, val, val2, f.byte_sel, operand_bytes(am, mx, cname));
    apply_mx(*this, cname, val);
}

static int find_matching(std::vector<SrcLine> &ls, int n, int start,
                         const char *open, const char *close, const char *close2)
{
    int nest = 1;
    for (int i = start; i < n; i++) {
        if (icmp(ls[i].opcode, open) == 0) nest++;
        if (icmp(ls[i].opcode, close) == 0 ||
            (close2 && icmp(ls[i].opcode, close2) == 0)) {
            nest--;
            if (nest == 0) return i;
        }
    }
    return n;
}

void Assembler::do_range(std::vector<SrcLine> &ls, int lo, int hi)
{
    for (int i = lo; i < hi && !ended; i++) {
        SrcLine *ln = &ls[i];
        begin_list(ln);
        if (ln->is_comment) {
            end_list();
            continue;
        }
        const auto &op = ln->opcode;

        if (icmp(op, "MAC") == 0) {
            i = find_matching(ls, static_cast<int>(lines->size()), i + 1, "MAC", "EOM", "<<<");
            end_list();
            continue;
        }
        if (icmp(op, "EOM") == 0 || icmp(op, "<<<") == 0) {
            end_list();
            continue;
        }

        if (icmp(op, "DO") == 0 || icmp(op, "IF") == 0) {
            bool parent = emitting;
            bool take = false;
            if (icmp(op, "IF") == 0 && ln->operand.size() >= 2 &&
                (ln->operand[1] == ',' || ln->operand[1] == '=')) {
                const char *rhs = ln->operand.c_str() + 2;
                while (*rhs == ' ' || *rhs == '\t') rhs++;
                take = (*rhs == ln->operand[0]);
            } else {
                int64_t v = 0;
                eval_on(ln, ln->operand.empty() ? "1" : ln->operand, v);
                take = v != 0;
            }
            if (csp >= kMaxCond - 1) {
                err(ln, "conditional nest too deep");
                end_list();
                continue;
            }
            csp++;
            cond[csp] = parent;
            cond_taken[csp] = take;
            cond_else[csp] = 0;
            emitting = parent && take;
            end_list();
            continue;
        }
        if (icmp(op, "ELSE") == 0) {
            if (csp <= 0) err(ln, "ELSE without DO/IF");
            else {
                bool parent = cond[csp];
                cond_else[csp] = 1;
                emitting = parent && !cond_taken[csp];
            }
            end_list();
            continue;
        }
        if (icmp(op, "FIN") == 0) {
            if (csp <= 0) err(ln, "FIN without DO/IF");
            else {
                csp--;
                bool em = true;
                for (int k = 1; k <= csp; k++) {
                    bool on = cond_taken[k];
                    if (cond_else[k]) on = !cond_taken[k];
                    em = cond[k] && on;
                }
                if (csp == 0) em = true;
                emitting = em;
            }
            end_list();
            continue;
        }
        if (icmp(op, "LUP") == 0) {
            int64_t n = 0;
            eval_on(ln, ln->operand, n);
            int body_end = find_matching(ls, hi, i + 1, "LUP", "--^", nullptr);
            if (n < 0) n = 0;
            if (n > 0x8000) n = 0x8000;
            end_list();
            for (int64_t k = 0; k < n; k++) {
                char at = (k < 26) ? static_cast<char>('Z' - k) : 'A';
                std::vector<SrcLine> iter;
                for (int j = i + 1; j < body_end; j++) {
                    SrcLine b = ls[j];
                    auto subat = [at](std::string s) {
                        for (char &c : s)
                            if (c == '@') c = at;
                        return s;
                    };
                    b.label = subat(b.label);
                    b.opcode = subat(b.opcode);
                    b.operand = subat(b.operand);
                    b.has_label = !b.label.empty();
                    b.raw.clear();
                    iter.push_back(std::move(b));
                }
                do_range(iter, 0, static_cast<int>(iter.size()));
            }
            i = body_end;
            continue;
        }
        if (icmp(op, "--^") == 0) {
            end_list();
            continue;
        }

        std::string callname = op;
        if (icmp(op, "PMC") == 0 || icmp(op, ">>>") == 0) {
            auto sp = ln->operand.find(' ');
            callname = sp == std::string::npos ? ln->operand : ln->operand.substr(0, sp);
        }
        Macro *m = callname.empty() ? nullptr : find_macro(callname);
        if (m) {
            if (ln->has_label) define_label(ln, ln->label, pc, false);
            std::string params[10];
            std::string arg = ln->operand;
            if (icmp(op, "PMC") == 0 || icmp(op, ">>>") == 0) {
                size_t p = 0;
                while (p < arg.size() && arg[p] != ' ' && arg[p] != '\t') p++;
                while (p < arg.size() && (arg[p] == ' ' || arg[p] == '\t')) p++;
                arg = arg.substr(p);
            }
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
            uniquify_macro_body(body);
            end_list();
            do_range(body, 0, static_cast<int>(body.size()));
            continue;
        }

        if (ln->has_label && icmp(op, "EQU") != 0 && op != "=" &&
            icmp(op, "GEQU") != 0 && icmp(op, "GEQ") != 0)
            define_label(ln, ln->label, pc, false);

        if (op.empty()) {
            end_list();
            continue;
        }
        if (is_pseudo(op)) do_pseudo(ln);
        else do_instruction(ln);
        end_list();
    }
}

void Assembler::run_pass(int p)
{
    pass = p;
    pc = 0x8000;
    org = 0x8000;
    org_set = false;
    mx = opt.start_mx;
    xc = opt.start_xc;
    dummy = false;
    org_resume = 0;
    org_saved = false;
    emitting = true;
    csp = 0;
    ended = false;
    scope_id = 0;
    last_global_scope = 0;
    def_order = 0;
    oz_id = 1;
    if (p == 1) syms.clear();
    if (p == 2) {
        obj.clear();
        listing.clear();
    }
    do_range(*lines, 0, static_cast<int>(lines->size()));
}

std::string format_listing(const std::string &name, const Result &r,
                           const std::vector<ListLine> &lines)
{
    std::ostringstream o;
    o << "; merlin  " << name
      << "  org=$" << std::uppercase << std::hex;
    o.width(6); o.fill('0');
    o << r.org << std::dec
      << "  bytes=" << r.bytes.size()
      << "  errors=" << r.errors.size() << "\n;\n";
    for (const auto &ln : lines) {
        char pcbuf[16];
        std::snprintf(pcbuf, sizeof(pcbuf), "%06X", ln.pc);
        o << pcbuf << "  ";
        std::string hex;
        size_t nshow = std::min<size_t>(ln.bytes.size(), 4);
        for (size_t i = 0; i < nshow; i++) {
            char b[4];
            std::snprintf(b, sizeof(b), "%02X ", ln.bytes[i]);
            hex += b;
        }
        if (ln.bytes.size() > 4) hex += "... ";
        while (hex.size() < 16) hex.push_back(' ');
        o << hex << " " << ln.source << "\n";
        /* extra bytes */
        for (size_t i = 4; i < ln.bytes.size(); i += 4) {
            o << "        ";
            std::string h2;
            size_t m = std::min<size_t>(4, ln.bytes.size() - i);
            for (size_t j = 0; j < m; j++) {
                char b[4];
                std::snprintf(b, sizeof(b), "%02X ", ln.bytes[i + j]);
                h2 += b;
            }
            o << h2 << "\n";
        }
    }
    if (!r.errors.empty()) {
        o << ";\n; errors:\n";
        for (const auto &e : r.errors)
            o << ";  " << e.file << ":" << e.line << ": " << e.msg << "\n";
    }
    return o.str();
}

Result assemble_lines(std::vector<SrcLine> &lines, const Options &opt)
{
    Result r;
    r.filetype = 0x06;
    Assembler a;
    a.opt = opt;
    a.out = &r;
    a.lines = &lines;
    a.case_sensitive = opt.case_sensitive;
    a.emitting = true;
    a.collect_macros();
    a.run_pass(1);
    a.run_pass(2);
    r.bytes = std::move(a.obj);
    r.org = a.org_set ? a.org : 0x8000;
    r.filetype = a.filetype;
    r.dsk_name = a.dsk_name;
    r.listing = format_listing(lines.empty() ? std::string() : lines[0].file, r, a.listing);
    return r;
}

Result assemble_string(const std::string &src, const std::string &name, const Options &opt)
{
    auto lines = parse_source(src, name.empty() ? "<src>" : name);
    return assemble_lines(lines, opt);
}

Result assemble_file(const std::string &path, const Options &opt)
{
    std::string err;
    std::string src = read_file(path, &err);
    if (!err.empty() && src.empty()) {
        Result r;
        r.errors.push_back({path, 0, err});
        return r;
    }
    return assemble_string(src, path, opt);
}

} // namespace merlin
