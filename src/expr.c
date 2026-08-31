#include "merlin.h"

#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

typedef struct {
    const char *s;
    int i;
    ExprCtx *ctx;
    char err[192];
    bool algebraic;
} P;

static void seterr(P *p, const char *m)
{
    if (p->err[0] == 0)
        merlin_strlcpy(p->err, m, sizeof(p->err));
}

static void skip(P *p)
{
    while (p->s[p->i] == ' ' || p->s[p->i] == '\t') p->i++;
}



static int64_t parse_alg(P *p);
static int64_t parse_ltr(P *p);

static int hexval(int c)
{
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    return -1;
}

static int64_t parse_atom(P *p)
{
    skip(p);
    int c = (unsigned char)p->s[p->i];
    if (c == 0) {
        seterr(p, "empty expression");
        return 0;
    }

    /* braces: algebraic subexpression */
    if (c == '{') {
        p->i++;
        bool save = p->algebraic;
        p->algebraic = true;
        int64_t v = parse_alg(p);
        p->algebraic = save;
        skip(p);
        if (p->s[p->i] == '}') p->i++;
        else seterr(p, "missing }");
        return v;
    }

    /* current PC */
    if (c == '*') {
        p->i++;
        return (int64_t)p->ctx->pc;
    }

    /* hex */
    if (c == '$') {
        p->i++;
        int64_t v = 0;
        int n = 0;
        while (hexval((unsigned char)p->s[p->i]) >= 0) {
            v = (v << 4) | hexval((unsigned char)p->s[p->i]);
            p->i++;
            n++;
        }
        if (n == 0) seterr(p, "bad hex number");
        return v;
    }

    /* binary */
    if (c == '%') {
        p->i++;
        int64_t v = 0;
        int n = 0;
        while (p->s[p->i] == '0' || p->s[p->i] == '1' || p->s[p->i] == '_') {
            if (p->s[p->i] != '_') {
                v = (v << 1) | (p->s[p->i] - '0');
                n++;
            }
            p->i++;
        }
        if (n == 0) seterr(p, "bad binary number");
        return v;
    }

    /* ASCII char 'A' or "A" */
    if (c == '\'' || c == '"') {
        int quote = c;
        p->i++;
        int64_t v = (unsigned char)p->s[p->i];
        if (quote == '"') v |= 0x80;
        if (p->s[p->i]) p->i++;
        if (p->s[p->i] == quote) p->i++;
        return v;
    }

    /* decimal */
    if (isdigit(c)) {
        int64_t v = 0;
        while (isdigit((unsigned char)p->s[p->i])) {
            v = v * 10 + (p->s[p->i] - '0');
            p->i++;
        }
        return v;
    }

    /* MX as a built-in */
    if ((c == 'M' || c == 'm') && (p->s[p->i + 1] == 'X' || p->s[p->i + 1] == 'x') &&
        !isalnum((unsigned char)p->s[p->i + 2]) && p->s[p->i + 2] != '_') {
        p->i += 2;
        return p->ctx->mx;
    }

    /* label / variable */
    if (isalpha(c) || c == '_' || c == ']' || c == ':' || c == '@' || c == '.') {
        char name[MERLIN_MAX_LABEL];
        int n = 0;
        while (p->s[p->i] && !strchr("+-*/&!.<=>#{} \t,;", p->s[p->i])) {
            if (n + 1 < MERLIN_MAX_LABEL)
                name[n++] = p->s[p->i];
            p->i++;
        }
        name[n] = '\0';
        int64_t v = 0;
        bool known = false;
        if (p->ctx->lookup)
            p->ctx->lookup(p->ctx->asm_ptr, name, &v, &known);
        if (!known && p->ctx->pass == 2)
            seterr(p, "unknown label");
        return v;
    }

    seterr(p, "bad expression");
    return 0;
}

static int64_t parse_unary(P *p)
{
    skip(p);
    bool neg = false;
    if (p->s[p->i] == '-') {
        neg = true;
        p->i++;
    }
    skip(p);
    int sel = 0;
    if (p->s[p->i] == '<' || p->s[p->i] == '>' || p->s[p->i] == '^') {
        sel = (unsigned char)p->s[p->i];
        p->i++;
    }
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
    case 'L': case 'G': case 'E': case 'N': return 1; /* < > = # */
    case '+': case '-': return 2;
    case '*': case '/': return 3;
    case '&': case '.': case '!': return 4;
    default: return 0;
    }
}

static int read_op(P *p)
{
    skip(p);
    int c = (unsigned char)p->s[p->i];
    if (c == '+' || c == '-' || c == '*' || c == '/' || c == '&' || c == '.' ||
        c == '!' || c == '=' || c == '#') {
        p->i++;
        if (c == '<') return 'L';
        if (c == '>') return 'G';
        if (c == '=') return 'E';
        if (c == '#') return 'N';
        return c;
    }
    if (c == '<') {
        p->i++;
        return 'L';
    }
    if (c == '>') {
        p->i++;
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
    case '&': return a & b;
    case '.': return a | b;
    case '!': return a ^ b;
    case 'L': return a < b ? 1 : 0;
    case 'G': return a > b ? 1 : 0;
    case 'E': return a == b ? 1 : 0;
    case 'N': return a != b ? 1 : 0;
    default: return 0;
    }
}

static int64_t parse_ltr(P *p)
{
    int64_t v = parse_unary(p);
    for (;;) {
        int save = p->i;
        int op = read_op(p);
        if (!op) {
            p->i = save;
            break;
        }
        int64_t r = parse_unary(p);
        v = apply_op(op, v, r);
    }
    return v;
}

/* Pratt / precedence climbing for { } */
static int64_t parse_prec(P *p, int min_prec)
{
    int64_t v = parse_unary(p);
    for (;;) {
        int save = p->i;
        int op = read_op(p);
        if (!op) {
            p->i = save;
            break;
        }
        int prec = op_prec(op);
        if (prec < min_prec) {
            p->i = save;
            break;
        }
        int64_t r = parse_prec(p, prec + 1); /* left-assoc */
        v = apply_op(op, v, r);
    }
    return v;
}

static int64_t parse_alg(P *p)
{
    return parse_prec(p, 1);
}

int eval_expr(ExprCtx *ctx, const char *expr, int64_t *out, char *err, size_t errn)
{
    P p;
    memset(&p, 0, sizeof(p));
    p.s = expr ? expr : "";
    p.ctx = ctx;
    p.algebraic = ctx->algebraic;
    int64_t v = p.algebraic ? parse_alg(&p) : parse_ltr(&p);
    skip(&p);
    if (p.s[p.i] && p.err[0] == 0) {
        /* leftover is ok for some callers; flag only junk that isn't a closer */
        if (p.s[p.i] != ')' && p.s[p.i] != ']' && p.s[p.i] != '}')
            seterr(&p, "junk after expression");
    }
    if (p.err[0]) {
        if (err) merlin_strlcpy(err, p.err, errn);
        return -1;
    }
    *out = v;
    if (err && errn) err[0] = '\0';
    return 0;
}
