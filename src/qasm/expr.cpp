#include "intern.hpp"

#include <cctype>
#include <cstring>

namespace qasm {

struct P {
    const char *s = "";
    int i = 0;
    ExprCtx *ctx = nullptr;
    std::string err;
    bool algebraic = false;
};

static void seterr(P &p, const char *m)
{
    if (p.err.empty()) p.err = m;
}

static void skip(P &p)
{
    while (p.s[p.i] == ' ' || p.s[p.i] == '\t') p.i++;
}

static int hexval(int c)
{
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    return -1;
}

static int64_t parse_alg(P &p);
static int64_t parse_ltr(P &p);

static int64_t parse_atom(P &p)
{
    skip(p);
    int c = static_cast<unsigned char>(p.s[p.i]);
    if (c == 0) {
        seterr(p, "empty expression");
        return 0;
    }
    if (c == '{') {
        p.i++;
        bool save = p.algebraic;
        p.algebraic = true;
        int64_t v = parse_alg(p);
        p.algebraic = save;
        skip(p);
        if (p.s[p.i] == '}') p.i++;
        else seterr(p, "missing }");
        return v;
    }
    if (c == '*') {
        p.i++;
        return static_cast<int64_t>(p.ctx->pc);
    }
    if (c == '$') {
        p.i++;
        int64_t v = 0;
        int n = 0;
        while (hexval(static_cast<unsigned char>(p.s[p.i])) >= 0) {
            v = (v << 4) | hexval(static_cast<unsigned char>(p.s[p.i]));
            p.i++;
            n++;
        }
        if (n == 0) seterr(p, "bad hex number");
        return v;
    }
    if (c == '%') {
        p.i++;
        int64_t v = 0;
        int n = 0;
        while (p.s[p.i] == '0' || p.s[p.i] == '1' || p.s[p.i] == '_') {
            if (p.s[p.i] != '_') {
                v = (v << 1) | (p.s[p.i] - '0');
                n++;
            }
            p.i++;
        }
        if (n == 0) seterr(p, "bad binary number");
        return v;
    }
    if (c == '\'' || c == '"') {
        int quote = c;
        p.i++;
        int64_t v = static_cast<unsigned char>(p.s[p.i]);
        if (quote == '"') v |= 0x80;
        if (p.s[p.i]) p.i++;
        if (p.s[p.i] == quote) p.i++;
        return v;
    }
    if (std::isdigit(c)) {
        int64_t v = 0;
        while (std::isdigit(static_cast<unsigned char>(p.s[p.i]))) {
            v = v * 10 + (p.s[p.i] - '0');
            p.i++;
        }
        return v;
    }
    if ((c == 'M' || c == 'm') && (p.s[p.i + 1] == 'X' || p.s[p.i + 1] == 'x') &&
        !std::isalnum(static_cast<unsigned char>(p.s[p.i + 2])) &&
        p.s[p.i + 2] != '_') {
        p.i += 2;
        return p.ctx->mx;
    }
    bool tilde_name = c == '~' && (std::isalpha(static_cast<unsigned char>(p.s[p.i + 1])) ||
                                   p.s[p.i + 1] == '_');
    if (std::isalpha(c) || c == '_' || c == ']' || c == ':' || c == '@' || c == '.' ||
        tilde_name) {
        std::string name;
        while (p.s[p.i] && !std::strchr("+-*/%&!.<=>#{} \t,;", p.s[p.i]))
            name.push_back(p.s[p.i++]);
        int64_t v = 0;
        bool known = false;
        if (p.ctx->lookup)
            p.ctx->lookup(p.ctx->asm_ptr, name, &v, &known);
        if (!known && p.ctx->pass == 2 && !p.ctx->rel)
            seterr(p, "unknown label");
        return v;
    }
    seterr(p, "bad expression");
    return 0;
}

static int64_t parse_unary(P &p)
{
    skip(p);
    /* Merlin immediate '#' and force-abs '|' are prefixes, not operators.
       They appear in DFB/DW/DB (e.g. #<ABS, |$01A55A) as well as operands. */
    auto skip_force = [&]() {
        while (p.s[p.i] == '#' || p.s[p.i] == '|') {
            p.i++;
            skip(p);
        }
    };
    skip_force();
    bool neg = false;
    if (p.s[p.i] == '-') {
        neg = true;
        p.i++;
    }
    skip(p);
    skip_force();
    int sel = 0;
    if (p.s[p.i] == '<' || p.s[p.i] == '>' || p.s[p.i] == '^')
        sel = static_cast<unsigned char>(p.s[p.i++]);
    int64_t v = parse_atom(p);
    if (sel == '<') v &= 0xFF;
    else if (sel == '>') v = (v >> 8) & 0xFF;
    else if (sel == '^') v = (v >> 16) & 0xFF;
    if (neg) v = -v;
    return v;
}

static int op_prec(int op)
{
    switch (op) {
    case 'L': case 'G': case 'E': case 'N': return 1;
    case '+': case '-': case 'R': case 'S': return 2;
    case '*': case '/': case '%': return 3;
    case '&': case '.': case '!': return 4;
    default: return 0;
    }
}

static int read_op(P &p)
{
    skip(p);
    int c = static_cast<unsigned char>(p.s[p.i]);
    if (c == '+' || c == '-' || c == '*' || c == '/' || c == '%' || c == '&' ||
        c == '.' || c == '!') {
        p.i++;
        return c;
    }
    /* '=' equal, '#' not-equal. Both sit at the comparison precedence. */
    if (c == '=') {
        p.i++;
        return 'E';
    }
    if (c == '#') {
        p.i++;
        return 'N';
    }
    /* APW only. `<=` `>=` `<>` stay comparisons; the translator rewrites those. */
    if (p.ctx && p.ctx->shifts) {
        if (c == '>' && p.s[p.i + 1] == '>') {
            p.i += 2;
            return 'R';
        }
        if (c == '<' && p.s[p.i + 1] == '<') {
            p.i += 2;
            return 'S';
        }
    }
    if (c == '<') {
        p.i++;
        return 'L';
    }
    if (c == '>') {
        p.i++;
        return 'G';
    }
    return 0;
}

static int64_t apply_op(int op, int64_t a, int64_t b)
{
    switch (op) {
    case '+': return a + b;
    case '-': return a - b;
    case '*': return a * b;
    case '/': return b ? a / b : 0;
    case '%': return b ? a % b : 0;
    case '&': return a & b;
    case '.': return a | b;
    case '!': return a ^ b;
    case 'L': return a < b ? 1 : 0;
    case 'G': return a > b ? 1 : 0;
    case 'E': return a == b ? 1 : 0;
    case 'N': return a != b ? 1 : 0;
    case 'R':
    case 'S': {
        /* Logical shift. A count outside 0..62 is 0 so the shift is defined. */
        if (b < 0 || b >= 63) return 0;
        auto ua = static_cast<uint64_t>(a);
        auto ub = static_cast<unsigned>(b);
        uint64_t r = op == 'R' ? (ua >> ub) : (ua << ub);
        return static_cast<int64_t>(r);
    }
    default: return 0;
    }
}

static int64_t parse_ltr(P &p)
{
    int64_t v = parse_unary(p);
    for (;;) {
        int save = p.i;
        int op = read_op(p);
        if (!op) {
            p.i = save;
            break;
        }
        v = apply_op(op, v, parse_unary(p));
    }
    return v;
}

static int64_t parse_prec(P &p, int min_prec)
{
    int64_t v = parse_unary(p);
    for (;;) {
        int save = p.i;
        int op = read_op(p);
        if (!op) {
            p.i = save;
            break;
        }
        int prec = op_prec(op);
        if (prec < min_prec) {
            p.i = save;
            break;
        }
        v = apply_op(op, v, parse_prec(p, prec + 1));
    }
    return v;
}

static int64_t parse_alg(P &p)
{
    return parse_prec(p, 1);
}

bool eval_expr(ExprCtx &ctx, const std::string &expr, int64_t &out, std::string &err)
{
    P p;
    p.s = expr.c_str();
    p.ctx = &ctx;
    p.algebraic = ctx.algebraic;
    int64_t v = p.algebraic ? parse_alg(p) : parse_ltr(p);
    skip(p);
    if (p.s[p.i] && p.err.empty()) {
        if (p.s[p.i] != ')' && p.s[p.i] != ']' && p.s[p.i] != '}')
            seterr(p, "junk after expression");
    }
    if (!p.err.empty()) {
        err = p.err;
        return false;
    }
    out = v;
    err.clear();
    return true;
}

} // namespace qasm
