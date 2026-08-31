#include "merlin.h"

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

typedef struct {
    char name[MERLIN_MAX_LABEL];
    int64_t value;
    bool defined;
    bool is_var;
    bool is_local;     /* ]label */
    bool is_colon;     /* :label */
    int scope;         /* colon-local scope id */
    int order;         /* definition sequence (for backward ]locals) */
} Sym;

typedef struct {
    char name[MERLIN_MAX_LABEL];
    int start; /* index of first body line (after MAC) */
    int end;   /* index of EOM line */
} Macro;

typedef struct {
    MerlinOptions opt;
    AsmResult *out;
    SrcLine *lines;
    int nlines;
    int pass;
    uint32_t pc;
    uint32_t org;
    bool org_set;
    int mx;
    int xc;
    bool dummy;
    uint32_t dummy_save;
    bool emitting;
    int cond[MERLIN_MAX_COND];
    int cond_taken[MERLIN_MAX_COND];
    int cond_else[MERLIN_MAX_COND];
    int csp;
    uint8_t *obj;
    size_t obj_len, obj_cap;
    char dsk_name[256];
    uint16_t filetype;
    bool case_sensitive;
    bool ended;

    Sym *syms;
    int nsyms, capsyms;
    int scope_id;
    int last_global_scope;
    int def_order;     /* increment on each label def */

    Macro *macs;
    int nmacs, capmacs;

    char listing[1 << 16];
    size_t list_len;
} Asm;

static void errf(Asm *a, const SrcLine *ln, const char *fmt, ...)
{
    if (a->out->nerrors >= MERLIN_MAX_ERR) return;
    AsmError *e = &a->out->errors[a->out->nerrors++];
    merlin_strlcpy(e->file, ln && ln->file ? ln->file : "", sizeof(e->file));
    e->line = ln ? ln->lineno : 0;
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(e->msg, sizeof(e->msg), fmt, ap);
    va_end(ap);
}

static int namecmp(Asm *a, const char *x, const char *y)
{
    return a->case_sensitive ? strcmp(x, y) : merlin_stricmp(x, y);
}

static bool cond_on(Asm *a)
{
    return a->emitting;
}

static void emit_byte(Asm *a, uint8_t b)
{
    if (!cond_on(a)) return;
    if (a->pass == 2 && !a->dummy) {
        if (a->obj_len >= a->obj_cap) {
            a->obj_cap = a->obj_cap ? a->obj_cap * 2 : 256;
            a->obj = (uint8_t *)realloc(a->obj, a->obj_cap);
        }
        if (a->obj) a->obj[a->obj_len++] = b;
    }
    a->pc++;
}

static void emit_n(Asm *a, uint32_t v, int n)
{
    for (int i = 0; i < n; i++)
        emit_byte(a, (uint8_t)((v >> (8 * i)) & 0xFF));
}

static int lookup_sym(void *asp, const char *name, int64_t *val, bool *known)
{
    Asm *a = (Asm *)asp;
    *known = false;
    *val = 0;
    int colon_scope = -1;
    if (name[0] == ':') colon_scope = a->last_global_scope;

    /* nearest previous ]local whose def order is <= current */
    int best = -1;
    for (int i = 0; i < a->nsyms; i++) {
        if (namecmp(a, a->syms[i].name, name) != 0) continue;
        if (a->syms[i].is_colon && a->syms[i].scope != colon_scope) continue;
        if (a->syms[i].is_local) {
            if (a->syms[i].order <= a->def_order)
                best = i;
            continue;
        }
        if (a->syms[i].defined) {
            *val = a->syms[i].value;
            *known = true;
            return 0;
        }
    }
    if (best >= 0 && a->syms[best].defined) {
        *val = a->syms[best].value;
        *known = true;
    }
    return 0;
}

static Sym *find_sym(Asm *a, const char *name, bool var_only)
{
    for (int i = a->nsyms - 1; i >= 0; i--) {
        if (namecmp(a, a->syms[i].name, name) != 0) continue;
        if (var_only && !a->syms[i].is_var) continue;
        if (a->syms[i].is_colon && a->syms[i].scope != a->last_global_scope)
            continue;
        return &a->syms[i];
    }
    return NULL;
}

static Sym *add_sym(Asm *a, const char *name)
{
    if (a->nsyms >= a->capsyms) {
        a->capsyms = a->capsyms ? a->capsyms * 2 : 64;
        a->syms = (Sym *)realloc(a->syms, (size_t)a->capsyms * sizeof(Sym));
    }
    Sym *s = &a->syms[a->nsyms++];
    memset(s, 0, sizeof(*s));
    merlin_strlcpy(s->name, name, sizeof(s->name));
    s->is_local = name[0] == ']';
    s->is_colon = name[0] == ':';
    s->scope = a->last_global_scope;
    return s;
}

static void define_label(Asm *a, const SrcLine *ln, const char *name, int64_t val, bool is_var)
{
    if (!name || !name[0]) return;
    a->def_order++;
    if (name[0] != ']' && name[0] != ':') {
        a->scope_id++;
        a->last_global_scope = a->scope_id;
    }
    if (a->pass == 2 && !is_var)
        return;
    Sym *s = NULL;
    if (is_var) {
        s = find_sym(a, name, true);
        if (!s) s = add_sym(a, name);
        s->is_var = true;
        s->value = val;
        s->defined = true;
        s->order = a->def_order;
        return;
    }
    if (name[0] == ']') {
        s = add_sym(a, name);
        s->is_local = true;
        s->value = val;
        s->defined = true;
        s->order = a->def_order;
        return;
    }
    s = find_sym(a, name, false);
    if (s && s->defined && s->value != val && a->pass == 2)
        errf(a, ln, "duplicate label %s", name);
    if (!s) s = add_sym(a, name);
    s->value = val;
    s->defined = true;
    s->order = a->def_order;
}

static int eval_on(Asm *a, const SrcLine *ln, const char *expr, int64_t *out)
{
    ExprCtx ctx;
    memset(&ctx, 0, sizeof(ctx));
    ctx.pc = a->pc;
    ctx.mx = a->mx;
    ctx.algebraic = a->opt.algebraic;
    ctx.case_sensitive = a->case_sensitive;
    ctx.pass = a->pass;
    ctx.asm_ptr = a;
    ctx.lookup = lookup_sym;
    char err[192];
    if (eval_expr(&ctx, expr, out, err, sizeof(err)) != 0) {
        if (a->pass == 2) errf(a, ln, "%s in '%s'", err, expr);
        *out = 0;
        return -1;
    }
    return 0;
}

static bool is_pseudo(const char *op)
{
    static const char *ps[] = {
        "ORG", "OBJ", "EQU", "=", "HEX", "DFB", "DB", "DA", "DW", "DDB",
        "ADR", "ADRL", "DS", "ASC", "DCI", "INV", "FLS", "REV", "STR", "STRL",
        "MX", "XC", "LST", "END", "DUM", "DEND", "DO", "ELSE", "FIN", "IF",
        "MAC", "EOM", "<<<", "PMC", ">>>", "LUP", "--^", "SAV", "DSK", "TYP",
        "REL", "LNK", "ENT", "EXT", "PUT", "USE", "CAS", "ERR", "CHK",
        "AST", "SKP", "PAG", "TR", "EXP", "PAU", "KBD", "DAT", "DATE",
        "VAR", "USR", "FLO", "LSTDO", NULL
    };
    for (int i = 0; ps[i]; i++)
        if (merlin_stricmp(op, ps[i]) == 0) return true;
    return false;
}

static Macro *find_macro(Asm *a, const char *name)
{
    for (int i = 0; i < a->nmacs; i++)
        if (namecmp(a, a->macs[i].name, name) == 0) return &a->macs[i];
    return NULL;
}

static void collect_macros(Asm *a)
{
    for (int i = 0; i < a->nlines; i++) {
        if (merlin_stricmp(a->lines[i].opcode, "MAC") != 0) continue;
        if (!a->lines[i].has_label) continue;
        Macro m;
        memset(&m, 0, sizeof(m));
        merlin_strlcpy(m.name, a->lines[i].label, sizeof(m.name));
        m.start = i + 1;
        int j = i + 1, nest = 1;
        for (; j < a->nlines; j++) {
            if (merlin_stricmp(a->lines[j].opcode, "MAC") == 0) nest++;
            if (merlin_stricmp(a->lines[j].opcode, "EOM") == 0 ||
                merlin_stricmp(a->lines[j].opcode, "<<<") == 0) {
                nest--;
                if (nest == 0) break;
            }
        }
        m.end = j;
        if (a->nmacs >= a->capmacs) {
            a->capmacs = a->capmacs ? a->capmacs * 2 : 16;
            a->macs = (Macro *)realloc(a->macs, (size_t)a->capmacs * sizeof(Macro));
        }
        a->macs[a->nmacs++] = m;
        i = j;
    }
}

static void subst_params(char *dst, size_t dstn, const char *src, char p[10][MERLIN_MAX_LINE])
{
    size_t o = 0;
    for (int i = 0; src[i] && o + 1 < dstn; ) {
        if (src[i] == ']' && src[i + 1] >= '1' && src[i + 1] <= '9') {
            int k = src[i + 1] - '0';
            const char *rep = p[k];
            while (*rep && o + 1 < dstn) dst[o++] = *rep++;
            i += 2;
        } else {
            dst[o++] = src[i++];
        }
    }
    dst[o] = '\0';
}

static void split_mac_args(const char *opnd, char p[10][MERLIN_MAX_LINE])
{
    memset(p, 0, 10 * MERLIN_MAX_LINE);
    if (!opnd || !opnd[0]) return;
    int idx = 1;
    const char *s = opnd;
    while (*s && idx <= 9) {
        const char *semi = strchr(s, ';');
        size_t n = semi ? (size_t)(semi - s) : strlen(s);
        if (n >= MERLIN_MAX_LINE) n = MERLIN_MAX_LINE - 1;
        memcpy(p[idx], s, n);
        p[idx][n] = '\0';
        char *t = merlin_trim(p[idx]);
        if (t != p[idx]) memmove(p[idx], t, strlen(t) + 1);
        idx++;
        if (!semi) break;
        s = semi + 1;
    }
}

static void apply_mx_from_sep_rep(Asm *a, const char *cname, int64_t imm)
{
    uint8_t m = (uint8_t)(imm & 0xFF);
    if (merlin_stricmp(cname, "SEP") == 0) {
        if (m & 0x20) a->mx |= 2;
        if (m & 0x10) a->mx |= 1;
    } else if (merlin_stricmp(cname, "REP") == 0) {
        if (m & 0x20) a->mx &= ~2;
        if (m & 0x10) a->mx &= ~1;
    }
}

static int operand_bytes_for_am(AddrMode am, int mx, const char *cname)
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
    case AM_SR: case AM_REL:
        return 1;
    case AM_ABS: case AM_ABSX: case AM_ABSY:
    case AM_ABSIND: case AM_ABSINDX: case AM_ABSINDL:
    case AM_RELL: case AM_SRIY:
        return 2;
    case AM_LONG: case AM_LONGX: case AM_BLK:
        return 3;
    default: return 0;
    }
}

static AddrMode resolve_am(Asm *a, const char *cname, OperandForm *f,
                           int64_t value, bool known, int force, bool long_mn)
{
    int cpu = a->xc;
    int force2 = force;
    if (f->force) force2 = f->force;
    if (long_mn) force2 = FORCE_LONG;

    if (is_branch_long(cname)) return AM_RELL;
    if (is_branch(cname)) return AM_REL;

    if (merlin_stricmp(cname, "PEA") == 0) return AM_IMM16;
    if (merlin_stricmp(cname, "PER") == 0) return AM_RELL;
    if (merlin_stricmp(cname, "MVN") == 0 || merlin_stricmp(cname, "MVP") == 0)
        return AM_BLK;
    if (merlin_stricmp(cname, "SEP") == 0 || merlin_stricmp(cname, "REP") == 0)
        return AM_IMM8;
    if (merlin_stricmp(cname, "COP") == 0) return AM_IMM8;

    switch (f->syntax) {
    case SYN_IMP:
        return AM_IMP;
    case SYN_IMM:
        return AM_IMM;
    case SYN_S:
        return AM_SR;
    case SYN_SIY:
        return AM_SRIY;
    case SYN_INDX:
        /* (dp,X) vs (abs,X) — JMP/JSR want abs */
        if (opcode_supports(cname, AM_ABSINDX, cpu) &&
            !opcode_supports(cname, AM_INDX, cpu))
            return AM_ABSINDX;
        return AM_INDX;
    case SYN_INDY:
        return AM_INDY;
    case SYN_INDLY:
        return AM_INDLY;
    case SYN_IND:
        if (opcode_supports(cname, AM_ABSIND, cpu) &&
            (!opcode_supports(cname, AM_IND, cpu) || force2 == FORCE_ABS ||
             (known && value > 0xFF)))
            return AM_ABSIND;
        if (merlin_stricmp(cname, "PEI") == 0) return AM_IND;
        return AM_IND;
    case SYN_INDL:
        if (opcode_supports(cname, AM_ABSINDL, cpu) &&
            (!opcode_supports(cname, AM_INDL, cpu) || force2 == FORCE_ABS ||
             (known && value > 0xFF)))
            return AM_ABSINDL;
        return AM_INDL;
    case SYN_X:
        if (force2 == FORCE_LONG && opcode_supports(cname, AM_LONGX, cpu))
            return AM_LONGX;
        if (force2 == FORCE_DP ||
            (force2 == FORCE_NONE && known && value <= 0xFF &&
             opcode_supports(cname, AM_DPX, cpu)))
            return AM_DPX;
        return AM_ABSX;
    case SYN_Y:
        if (force2 == FORCE_DP ||
            (force2 == FORCE_NONE && known && value <= 0xFF &&
             opcode_supports(cname, AM_DPY, cpu)))
            return AM_DPY;
        return AM_ABSY;
    case SYN_BLK:
        return AM_BLK;
    case SYN_ABS:
    default:
        if (force2 == FORCE_LONG && opcode_supports(cname, AM_LONG, cpu))
            return AM_LONG;
        if (force2 == FORCE_DP)
            return AM_DP;
        if (force2 == FORCE_ABS)
            return AM_ABS;
        if (known && value <= 0xFF && opcode_supports(cname, AM_DP, cpu))
            return AM_DP;
        if (known && value > 0xFFFF && opcode_supports(cname, AM_LONG, cpu))
            return AM_LONG;
        return opcode_supports(cname, AM_ABS, cpu) ? AM_ABS :
               (opcode_supports(cname, AM_LONG, cpu) ? AM_LONG : AM_ABS);
    }
}

static int64_t extract_sel(int64_t v, int sel, int nbytes)
{
    if (sel == '<') {
        if (nbytes >= 2) return v & 0xFFFF;
        return v & 0xFF;
    }
    if (sel == '>') {
        if (nbytes >= 2) return (v >> 8) & 0xFFFF;
        return (v >> 8) & 0xFF;
    }
    if (sel == '^') return (v >> 16) & 0xFF;
    return v;
}

static void emit_code(Asm *a, const SrcLine *ln, const char *cname, AddrMode am,
                     uint8_t opc, int64_t val, int64_t val2, int sel, int nbytes)
{
    (void)cname;
    emit_byte(a, opc);
    if (am == AM_REL) {
        int32_t rel = (int32_t)val - (int32_t)(a->pc + 1);
        if (a->pass == 2 && (rel < -128 || rel > 127))
            errf(a, ln, "branch out of range");
        emit_byte(a, (uint8_t)rel);
        return;
    }
    if (am == AM_RELL) {
        int32_t rel = (int32_t)val - (int32_t)(a->pc + 2);
        emit_n(a, (uint32_t)rel, 2);
        return;
    }
    if (am == AM_BLK) {
        uint8_t dst = (uint8_t)((val2 >> 16) & 0xFF);
        if ((val2 & 0xFFFF00) == 0) dst = (uint8_t)(val2 & 0xFF);
        uint8_t src = (uint8_t)((val >> 16) & 0xFF);
        if ((val & 0xFFFF00) == 0) src = (uint8_t)(val & 0xFF);
        /* object: dest, src */
        emit_byte(a, dst);
        emit_byte(a, src);
        return;
    }
    int64_t v = extract_sel(val, sel, nbytes);
    emit_n(a, (uint32_t)v, nbytes);
}

static uint8_t ascii_map(uint8_t ch, const char *kind, int quote)
{
    int hi = (quote == '"') ? 0x80 : 0x00;
    if (merlin_stricmp(kind, "INV") == 0) {
        /* 16+: lowercase -> $60-7F */
        if (ch >= 'a' && ch <= 'z') return (uint8_t)(ch);
        if (ch >= 0x40 && ch <= 0x7F) return (uint8_t)(ch & 0x3F);
        return (uint8_t)(ch & 0x3F);
    }
    if (merlin_stricmp(kind, "FLS") == 0) {
        return (uint8_t)((ch & 0x3F) | 0x40);
    }
    return (uint8_t)((ch & 0x7F) | hi);
}

static void emit_string_pseudo(Asm *a, const SrcLine *ln, const char *kind)
{
    const char *s = ln->operand;
    while (*s == ' ' || *s == '\t') s++;

    /* ASC #expr */
    if (merlin_stricmp(kind, "ASC") == 0 && *s == '#') {
        int neg = 0, pad = 0;
        s++;
        if (*s == '\'') s++;
        else if (*s == '"') {
            neg = 1;
            s++;
        }
        if (*s == '>') {
            pad = 1;
            s++;
        }
        int64_t v = 0;
        eval_on(a, ln, s, &v);
        char buf[16];
        snprintf(buf, sizeof(buf), pad ? "%5d" : "%d", (int)v);
        for (char *p = buf; *p; p++) {
            uint8_t ch = (uint8_t)*p;
            if (neg) ch |= 0x80;
            emit_byte(a, ch);
        }
        return;
    }

    bool strl = merlin_stricmp(kind, "STRL") == 0;
    bool str1 = merlin_stricmp(kind, "STR") == 0;
    bool dci = merlin_stricmp(kind, "DCI") == 0;
    bool rev = merlin_stricmp(kind, "REV") == 0;

    uint8_t bytes[512];
    int n = 0;
    while (*s && n < 500) {
        while (*s == ' ' || *s == '\t' || *s == ',') s++;
        if (!*s) break;
        if (*s == '\'' || *s == '"') {
            int q = *s++;
            while (*s && *s != q && n < 500) {
                bytes[n++] = ascii_map((uint8_t)*s++, kind, q);
            }
            if (*s == q) s++;
        } else if (isxdigit((unsigned char)*s)) {
            /* interspersed hex (16+) */
            int v = 0, d = 0;
            while (isxdigit((unsigned char)*s)) {
                int h = isdigit((unsigned char)*s) ? *s - '0'
                        : (tolower((unsigned char)*s) - 'a' + 10);
                v = (v << 4) | h;
                s++;
                d++;
                if (d == 2) {
                    bytes[n++] = (uint8_t)v;
                    v = 0;
                    d = 0;
                }
            }
        } else break;
    }

    if (rev) {
        for (int i = 0; i < n / 2; i++) {
            uint8_t t = bytes[i];
            bytes[i] = bytes[n - 1 - i];
            bytes[n - 1 - i] = t;
        }
    }
    if (dci && n > 0) bytes[n - 1] ^= 0x80;

    if (str1) emit_byte(a, (uint8_t)n);
    if (strl) emit_n(a, (uint32_t)n, 2);
    for (int i = 0; i < n; i++) emit_byte(a, bytes[i]);
}

static void emit_hex(Asm *a, const SrcLine *ln)
{
    const char *s = ln->operand;
    int acc = 0, digits = 0;
    while (*s) {
        if (*s == ',' || *s == ' ' || *s == '\t') {
            s++;
            continue;
        }
        if (!isxdigit((unsigned char)*s)) {
            if (a->pass == 2) errf(a, ln, "bad HEX operand");
            break;
        }
        int h = isdigit((unsigned char)*s) ? *s - '0'
                : (tolower((unsigned char)*s) - 'a' + 10);
        acc = (acc << 4) | h;
        digits++;
        s++;
        if (digits == 2) {
            emit_byte(a, (uint8_t)acc);
            acc = 0;
            digits = 0;
        }
    }
    if (digits && a->pass == 2) errf(a, ln, "HEX needs even number of digits");
}

static void emit_list_data(Asm *a, const SrcLine *ln, const char *kind)
{
    /* comma-separated expressions */
    const char *s = ln->operand;
    int width = 1, hi_first = 0;
    if (merlin_stricmp(kind, "DA") == 0 || merlin_stricmp(kind, "DW") == 0) width = 2;
    else if (merlin_stricmp(kind, "DDB") == 0) {
        width = 2;
        hi_first = 1;
    } else if (merlin_stricmp(kind, "ADR") == 0) width = 3;
    else if (merlin_stricmp(kind, "ADRL") == 0) width = 4;

    char buf[MERLIN_MAX_LINE];
    merlin_strlcpy(buf, s, sizeof(buf));
    char *p = buf;
    while (p && *p) {
        char *comma = strchr(p, ',');
        if (comma) *comma = '\0';
        int64_t v = 0;
        eval_on(a, ln, merlin_trim(p), &v);
        if (merlin_stricmp(kind, "DFB") == 0 || merlin_stricmp(kind, "DB") == 0) {
            /* >expr = high byte */
            char *t = merlin_trim(p);
            if (*t == '>') v = (v >> 8) & 0xFF;
            else v &= 0xFF;
            emit_byte(a, (uint8_t)v);
        } else if (hi_first) {
            emit_byte(a, (uint8_t)((v >> 8) & 0xFF));
            emit_byte(a, (uint8_t)(v & 0xFF));
        } else {
            emit_n(a, (uint32_t)v, width);
        }
        p = comma ? comma + 1 : NULL;
    }
}

static int filetype_from(const char *s)
{
    char t[32];
    merlin_strlcpy(t, s, sizeof(t));
    merlin_trim(t);
    if (t[0] == '$') return (int)strtol(t + 1, NULL, 16);
    if (merlin_stricmp(t, "BIN") == 0) return 0x06;
    if (merlin_stricmp(t, "SYS") == 0) return 0xFF;
    if (merlin_stricmp(t, "S16") == 0 || merlin_stricmp(t, "SYS16") == 0) return 0xB3;
    if (merlin_stricmp(t, "CDA") == 0) return 0xB9;
    if (merlin_stricmp(t, "NDA") == 0) return 0xB8;
    if (merlin_stricmp(t, "EXE") == 0) return 0xB5;
    if (merlin_stricmp(t, "TXT") == 0) return 0x04;
    if (merlin_stricmp(t, "SRC") == 0) return 0xB0;
    if (merlin_stricmp(t, "LNK") == 0) return 0x2E;
    return (int)strtol(t, NULL, 0);
}

static void do_pseudo(Asm *a, const SrcLine *ln)
{
    const char *op = ln->opcode;

    if (merlin_stricmp(op, "LST") == 0 || merlin_stricmp(op, "EXP") == 0 ||
        merlin_stricmp(op, "TR") == 0 || merlin_stricmp(op, "PAU") == 0 ||
        merlin_stricmp(op, "PAG") == 0 || merlin_stricmp(op, "AST") == 0 ||
        merlin_stricmp(op, "SKP") == 0 || merlin_stricmp(op, "KBD") == 0)
        return;

    if (merlin_stricmp(op, "END") == 0) {
        a->ended = true;
        return;
    }
    if (merlin_stricmp(op, "CAS") == 0) {
        if (merlin_strnicmp(ln->operand, "SE", 2) == 0) a->case_sensitive = true;
        if (merlin_strnicmp(ln->operand, "IN", 2) == 0) a->case_sensitive = false;
        return;
    }
    if (merlin_stricmp(op, "XC") == 0) {
        if (merlin_stricmp(ln->operand, "OFF") == 0) a->xc = 0;
        else if (a->xc < 2) a->xc++;
        return;
    }
    if (merlin_stricmp(op, "MX") == 0) {
        int64_t v = 3;
        eval_on(a, ln, ln->operand[0] ? ln->operand : "%11", &v);
        a->mx = (int)(v & 3);
        return;
    }
    if (merlin_stricmp(op, "ORG") == 0) {
        int64_t v = 0;
        eval_on(a, ln, ln->operand, &v);
        a->pc = (uint32_t)v;
        if (!a->dummy) {
            a->org = (uint32_t)v;
            a->org_set = true;
        }
        return;
    }
    if (merlin_stricmp(op, "DUM") == 0) {
        int64_t v = 0;
        eval_on(a, ln, ln->operand, &v);
        a->dummy_save = a->pc;
        a->pc = (uint32_t)v;
        a->dummy = true;
        return;
    }
    if (merlin_stricmp(op, "DEND") == 0) {
        a->pc = a->dummy_save;
        a->dummy = false;
        return;
    }
    if (merlin_stricmp(op, "EQU") == 0 || strcmp(op, "=") == 0) {
        int64_t v = 0;
        eval_on(a, ln, ln->operand, &v);
        bool is_var = ln->has_label && ln->label[0] == ']';
        define_label(a, ln, ln->label, v, is_var);
        return;
    }
    if (merlin_stricmp(op, "TYP") == 0) {
        a->filetype = (uint16_t)filetype_from(ln->operand);
        return;
    }
    if (merlin_stricmp(op, "DSK") == 0 || merlin_stricmp(op, "SAV") == 0) {
        merlin_strlcpy(a->dsk_name, ln->operand, sizeof(a->dsk_name));
        /* strip quotes */
        char *s = a->dsk_name;
        if ((s[0] == '"' || s[0] == '\'') && s[strlen(s) - 1] == s[0]) {
            s[strlen(s) - 1] = '\0';
            memmove(s, s + 1, strlen(s));
        }
        return;
    }
    if (merlin_stricmp(op, "REL") == 0 || merlin_stricmp(op, "LNK") == 0 ||
        merlin_stricmp(op, "ENT") == 0 || merlin_stricmp(op, "EXT") == 0 ||
        merlin_stricmp(op, "PUT") == 0 || merlin_stricmp(op, "USE") == 0)
        return; /* later */

    if (!cond_on(a) && merlin_stricmp(op, "DO") != 0 &&
        merlin_stricmp(op, "IF") != 0 && merlin_stricmp(op, "ELSE") != 0 &&
        merlin_stricmp(op, "FIN") != 0)
        return;

    if (merlin_stricmp(op, "HEX") == 0) {
        emit_hex(a, ln);
        return;
    }
    if (merlin_stricmp(op, "DFB") == 0 || merlin_stricmp(op, "DB") == 0 ||
        merlin_stricmp(op, "DA") == 0 || merlin_stricmp(op, "DW") == 0 ||
        merlin_stricmp(op, "DDB") == 0 || merlin_stricmp(op, "ADR") == 0 ||
        merlin_stricmp(op, "ADRL") == 0) {
        emit_list_data(a, ln, op);
        return;
    }
    if (merlin_stricmp(op, "DS") == 0) {
        char left[MERLIN_MAX_LINE], right[MERLIN_MAX_LINE];
        merlin_strlcpy(left, ln->operand, sizeof(left));
        right[0] = '\0';
        char *c = strchr(left, ',');
        if (c) {
            *c = '\0';
            merlin_strlcpy(right, merlin_trim(c + 1), sizeof(right));
        }
        int64_t fill = 0, n = 0;
        char *l = merlin_trim(left);
        if (l[0] == '\\') {
            uint32_t next = (a->pc + 0xFF) & ~0xFFu;
            n = (int64_t)(next - a->pc);
            if (n == 0) n = 256;
        } else {
            eval_on(a, ln, l, &n);
        }
        if (right[0]) eval_on(a, ln, right, &fill);
        if (n < 0) n = 0;
        if (n > 0x10000) n = 0x10000;
        for (int64_t i = 0; i < n; i++) emit_byte(a, (uint8_t)fill);
        return;
    }
    if (merlin_stricmp(op, "ASC") == 0 || merlin_stricmp(op, "STR") == 0 ||
        merlin_stricmp(op, "STRL") == 0 || merlin_stricmp(op, "DCI") == 0 ||
        merlin_stricmp(op, "INV") == 0 || merlin_stricmp(op, "FLS") == 0 ||
        merlin_stricmp(op, "REV") == 0) {
        emit_string_pseudo(a, ln, op);
        return;
    }
    if (merlin_stricmp(op, "ERR") == 0) {
        int64_t v = 0;
        eval_on(a, ln, ln->operand, &v);
        if (v && a->pass == 2) errf(a, ln, "ERR forced");
        return;
    }
}

static void do_instruction(Asm *a, const SrcLine *ln)
{
    if (!cond_on(a)) return;
    char tmp[MERLIN_MAX_OP];
    int force = FORCE_NONE;
    bool long_mn = false;
    const char *cname = opcode_canonical(ln->opcode, tmp, sizeof(tmp), &force, &long_mn);

    OperandForm f;
    parse_operand_form(ln->operand, &f);

    int64_t val = 0, val2 = 0;
    bool known = true;
    if (f.expr[0]) {
        char err[192];
        ExprCtx ctx;
        memset(&ctx, 0, sizeof(ctx));
        ctx.pc = a->pc;
        ctx.mx = a->mx;
        ctx.algebraic = a->opt.algebraic;
        ctx.case_sensitive = a->case_sensitive;
        ctx.pass = a->pass;
        ctx.asm_ptr = a;
        ctx.lookup = lookup_sym;
        eval_expr(&ctx, f.expr, &val, err, sizeof(err));
        bool k = false;
        int64_t dummy = 0;
        lookup_sym(a, f.expr, &dummy, &k);
        /* known if eval succeeded or pass 1 */
        known = (err[0] == 0);
        /* For DP decision: unknown labels are NOT zp */
        if (a->pass == 1) {
            /* if expression is a single undefined label, treat as 16-bit */
            bool lab_known = false;
            int64_t lv = 0;
            lookup_sym(a, f.expr, &lv, &lab_known);
            if (!lab_known && f.expr[0] && !isdigit((unsigned char)f.expr[0]) &&
                f.expr[0] != '$' && f.expr[0] != '%' && f.expr[0] != '#' &&
                f.expr[0] != '\'' && f.expr[0] != '"' && f.expr[0] != '{' &&
                f.expr[0] != '<' && f.expr[0] != '>' && f.expr[0] != '*' &&
                strchr(f.expr, '+') == NULL && strchr(f.expr, '-') == NULL)
                known = false;
            else if (lab_known) {
                known = true;
                val = lv;
            }
        }
        if (a->pass == 2 && err[0]) errf(a, ln, "%s", err);
    }
    if (f.expr2[0]) eval_on(a, ln, f.expr2, &val2);

    AddrMode am = resolve_am(a, cname, &f, val, known, force, long_mn);
    if (f.syntax == SYN_IMP && is_alu_acc(cname))
        am = AM_IMP;

    uint8_t opc = 0;
    if (opcode_encode(cname, am, a->xc, &opc) != 0) {
        /* try IMM8 for SEP/REP already handled; try AMP fallback */
        if (am == AM_IMM && opcode_encode(cname, AM_IMM8, a->xc, &opc) == 0)
            am = AM_IMM8;
        else if (am == AM_DP && opcode_encode(cname, AM_ABS, a->xc, &opc) == 0)
            am = AM_ABS;
        else {
            if (a->pass == 2)
                errf(a, ln, "bad addressing mode for %s", cname);
            return;
        }
    }
    int nbytes = operand_bytes_for_am(am, a->mx, cname);
    emit_code(a, ln, cname, am, opc, val, val2, f.byte_sel, nbytes);
    apply_mx_from_sep_rep(a, cname, val);
}

static int find_matching(SrcLine *lines, int n, int start, const char *open,
                         const char *close, const char *close2)
{
    int nest = 1;
    for (int i = start; i < n; i++) {
        if (merlin_stricmp(lines[i].opcode, open) == 0) nest++;
        if (merlin_stricmp(lines[i].opcode, close) == 0 ||
            (close2 && merlin_stricmp(lines[i].opcode, close2) == 0)) {
            nest--;
            if (nest == 0) return i;
        }
    }
    return n;
}

static void do_range(Asm *a, SrcLine *lines, int lo, int hi);

static void do_range(Asm *a, SrcLine *lines, int lo, int hi)
{
    for (int i = lo; i < hi && !a->ended; i++) {
        SrcLine *ln = &lines[i];
        if (ln->is_comment) continue;

        const char *op = ln->opcode;

        /* macros definitions: skip */
        if (merlin_stricmp(op, "MAC") == 0) {
            i = find_matching(lines, a->nlines, i + 1, "MAC", "EOM", "<<<");
            continue;
        }
        if (merlin_stricmp(op, "EOM") == 0 || merlin_stricmp(op, "<<<") == 0)
            continue;

        /* conditionals always processed */
        if (merlin_stricmp(op, "DO") == 0 || merlin_stricmp(op, "IF") == 0) {
            bool parent = a->emitting;
            bool take = false;
            if (merlin_stricmp(op, "IF") == 0 && ln->operand[0] &&
                (ln->operand[1] == ',' || ln->operand[1] == '=')) {
                take = (ln->operand[2] == ln->operand[0] ||
                        (ln->operand[2] == ' ' && ln->operand[3] == ln->operand[0]));
                /* "IF #,]1" after subst is "IF #,#$00" — compare first char of rhs */
                const char *rhs = ln->operand + 2;
                while (*rhs == ' ' || *rhs == '\t') rhs++;
                take = (*rhs == ln->operand[0]);
            } else {
                int64_t v = 0;
                eval_on(a, ln, ln->operand[0] ? ln->operand : "1", &v);
                take = (v != 0);
            }
            if (a->csp >= MERLIN_MAX_COND - 1) {
                errf(a, ln, "conditional nest too deep");
                continue;
            }
            a->csp++;
            a->cond[a->csp] = parent;
            a->cond_taken[a->csp] = take;
            a->cond_else[a->csp] = 0;
            a->emitting = parent && take;
            continue;
        }
        if (merlin_stricmp(op, "ELSE") == 0) {
            if (a->csp <= 0) {
                errf(a, ln, "ELSE without DO/IF");
                continue;
            }
            bool parent = a->cond[a->csp];
            a->cond_else[a->csp] = 1;
            a->emitting = parent && !a->cond_taken[a->csp];
            continue;
        }
        if (merlin_stricmp(op, "FIN") == 0) {
            if (a->csp <= 0) {
                errf(a, ln, "FIN without DO/IF");
                continue;
            }
            a->csp--;
            a->emitting = (a->csp == 0) ? true : (a->cond[a->csp] && a->cond_taken[a->csp] && !a->cond_else[a->csp]) ||
                          (a->csp > 0 && a->emitting);
            /* restore emitting from remaining stack */
            bool em = true;
            for (int k = 1; k <= a->csp; k++) {
                bool on = a->cond_taken[k];
                if (a->cond_else[k]) on = !a->cond_taken[k];
                em = em && on;
                /* parent of level k is cond[k] which we stored as parent */
                em = a->cond[k] && on;
            }
            if (a->csp == 0) em = true;
            a->emitting = em;
            continue;
        }

        if (merlin_stricmp(op, "LUP") == 0) {
            int64_t n = 0;
            eval_on(a, ln, ln->operand, &n);
            int body_end = find_matching(lines, hi, i + 1, "LUP", "--^", NULL);
            if (n < 0) n = 0;
            if (n > 0x8000) n = 0x8000;
            for (int64_t k = 0; k < n; k++)
                do_range(a, lines, i + 1, body_end);
            i = body_end;
            continue;
        }
        if (merlin_stricmp(op, "--^") == 0) continue;

        /* macro call */
        Macro *m = NULL;
        const char *callname = op;
        char mname[MERLIN_MAX_OP];
        if (merlin_stricmp(op, "PMC") == 0 || merlin_stricmp(op, ">>>") == 0) {
            merlin_strlcpy(mname, ln->operand, sizeof(mname));
            char *sp = strchr(mname, ' ');
            if (sp) *sp = '\0';
            callname = mname;
        }
        if (callname[0]) m = find_macro(a, callname);
        if (m) {
            if (ln->has_label)
                define_label(a, ln, ln->label, a->pc, false);
            char params[10][MERLIN_MAX_LINE];
            const char *arg = ln->operand;
            if (merlin_stricmp(op, "PMC") == 0 || merlin_stricmp(op, ">>>") == 0) {
                arg = ln->operand;
                while (*arg && *arg != ' ' && *arg != '\t') arg++;
                while (*arg == ' ' || *arg == '\t') arg++;
            }
            split_mac_args(arg, params);
            int body_n = m->end - m->start;
            SrcLine *body = (SrcLine *)calloc((size_t)body_n, sizeof(SrcLine));
            for (int j = 0; j < body_n; j++) {
                body[j] = a->lines[m->start + j];
                subst_params(body[j].label, sizeof(body[j].label),
                             a->lines[m->start + j].label, params);
                subst_params(body[j].opcode, sizeof(body[j].opcode),
                             a->lines[m->start + j].opcode, params);
                subst_params(body[j].operand, sizeof(body[j].operand),
                             a->lines[m->start + j].operand, params);
                body[j].has_label = body[j].label[0] != '\0';
            }
            do_range(a, body, 0, body_n);
            free(body);
            continue;
        }

        if (ln->has_label && merlin_stricmp(op, "EQU") != 0 && strcmp(op, "=") != 0)
            define_label(a, ln, ln->label, a->pc, false);

        if (op[0] == 0) continue;

        if (is_pseudo(op)) {
            do_pseudo(a, ln);
            continue;
        }

        do_instruction(a, ln);
    }
}

static void run_pass(Asm *a, int pass)
{
    a->pass = pass;
    a->pc = 0x8000; /* Merlin 16 default-ish; ORG should set it */
    a->org = 0x8000;
    a->org_set = false;
    a->mx = a->opt.start_mx;
    a->xc = a->opt.start_xc;
    a->dummy = false;
    a->emitting = true;
    a->csp = 0;
    a->ended = false;
    a->scope_id = 0;
    a->last_global_scope = 0;
    a->def_order = 0;
    if (pass == 1) {
        a->nsyms = 0;
    }
    if (pass == 2) {
        a->obj_len = 0;
    }
    do_range(a, a->lines, 0, a->nlines);
}

int assemble_lines(SrcLine *lines, int nlines, const MerlinOptions *opt, AsmResult *out)
{
    memset(out, 0, sizeof(*out));
    out->filetype = 0x06;
    Asm a;
    memset(&a, 0, sizeof(a));
    a.opt = *opt;
    a.out = out;
    a.lines = lines;
    a.nlines = nlines;
    a.case_sensitive = opt->case_sensitive;
    a.emitting = true;
    a.filetype = 0x06;
    collect_macros(&a);
    run_pass(&a, 1);
    int err1 = out->nerrors;
    run_pass(&a, 2);
    (void)err1;
    out->bytes = a.obj;
    out->len = a.obj_len;
    out->org = a.org_set ? a.org : 0x8000;
    out->filetype = a.filetype;
    merlin_strlcpy(out->dsk_name, a.dsk_name, sizeof(out->dsk_name));
    free(a.syms);
    free(a.macs);
    return out->nerrors ? -1 : 0;
}

void merlin_options_default(MerlinOptions *o)
{
    memset(o, 0, sizeof(*o));
    o->dialect = DIALECT_16PLUS;
    o->case_sensitive = false;
    o->algebraic = false;
    o->start_mx = 3; /* %11 emulation */
    o->start_xc = 2; /* 65816 */
}

void merlin_result_free(AsmResult *r)
{
    free(r->bytes);
    free(r->listing);
    r->bytes = NULL;
    r->listing = NULL;
    r->len = 0;
}

int merlin_assemble_string(const char *src, const char *name,
                           const MerlinOptions *opt, AsmResult *out)
{
    MerlinOptions o;
    if (!opt) {
        merlin_options_default(&o);
        opt = &o;
    } else {
        o = *opt;
        opt = &o;
    }
    if (opt->dialect == DIALECT_8 && opt->start_xc == 2) {
        /* apply dialect defaults if caller left them at 16+ */
    }
    SrcLine *lines = NULL;
    int n = 0;
    if (parse_source(src, name ? name : "<src>", &lines, &n) != 0) {
        memset(out, 0, sizeof(*out));
        if (out->nerrors < MERLIN_MAX_ERR) {
            merlin_strlcpy(out->errors[0].msg, "parse failed", sizeof(out->errors[0].msg));
            out->nerrors = 1;
        }
        return -1;
    }
    int rc = assemble_lines(lines, n, opt, out);
    free_source(lines, n);
    return rc;
}

int merlin_assemble_file(const char *path, const MerlinOptions *opt, AsmResult *out)
{
    size_t len = 0;
    char *src = merlin_read_file(path, &len);
    if (!src) {
        memset(out, 0, sizeof(*out));
        Asm dummy;
        memset(&dummy, 0, sizeof(dummy));
        dummy.out = out;
        SrcLine ln;
        memset(&ln, 0, sizeof(ln));
        ln.file = (char *)path;
        errf(&dummy, &ln, "cannot read file");
        return -1;
    }
    int rc = merlin_assemble_string(src, path, opt, out);
    free(src);
    return rc;
}

