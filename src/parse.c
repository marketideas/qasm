#include "merlin.h"

#include <ctype.h>
#include <stdlib.h>
#include <string.h>

static int is_ws(unsigned char c)
{
    return c == ' ' || c == '\t' || merlin_is_field_tab(c);
}

static int line_has_a0(const unsigned char *s, size_t n)
{
    for (size_t i = 0; i < n; i++)
        if (s[i] == 0xA0) return 1;
    return 0;
}

static void put_ascii(char *dst, int *j, int max, unsigned char c)
{
    unsigned char ch = merlin_ascii(c);
    if (ch == 0) return;
    if (*j + 1 < max)
        dst[(*j)++] = (char)ch;
}

/* Native Merlin: columns separated by a single $A0 (high-bit space).
   $20 in the file is a literal space (strings/comments), not a column tab.
   Extra $A0 after the third separator are ordinary spaces. */
static int parse_line_native(const unsigned char *s, size_t n, SrcLine *out)
{
    char fields[4][MERLIN_MAX_LINE];
    int flen[4] = {0, 0, 0, 0};
    int f = 0;
    memset(fields, 0, sizeof(fields));

    for (size_t i = 0; i < n; i++) {
        unsigned char c = s[i];
        if (merlin_is_eol(c)) break;
        if (merlin_is_field_tab(c)) {
            if (f < 3) {
                f++;
            } else if (flen[3] + 1 < MERLIN_MAX_LINE) {
                fields[3][flen[3]++] = ' ';
            }
            continue;
        }
        put_ascii(fields[f], &flen[f], MERLIN_MAX_LINE, c);
    }
    for (int i = 0; i < 4; i++)
        fields[i][flen[i]] = '\0';

    merlin_strlcpy(out->label, merlin_trim(fields[0]), sizeof(out->label));
    merlin_strlcpy(out->opcode, merlin_trim(fields[1]), sizeof(out->opcode));
    merlin_strlcpy(out->operand, merlin_trim(fields[2]), sizeof(out->operand));
    out->has_label = (out->label[0] != '\0');
    if (out->label[0] == '*' || out->label[0] == ';' ||
        (out->label[0] == 0 && (out->opcode[0] == '*' || out->opcode[0] == ';')))
        out->is_comment = true;
    return 0;
}

int parse_line_text(const char *text, SrcLine *out)
{
    memset(out, 0, sizeof(*out));
    const unsigned char *s = (const unsigned char *)text;
    size_t n = 0;
    while (s[n] && !merlin_is_eol(s[n])) n++;

    out->raw = NULL;
    if (n == 0) return 0;

    if (line_has_a0(s, n))
        return parse_line_native(s, n, out);

    /* Host text / Cadius-cleared files: spaces and TABs separate fields.
       Still strip bit 7 so high-ASCII letters match. */
    int i = 0;
    while (i < (int)n && is_ws(s[i])) i++;
    if (i >= (int)n) return 0;

    unsigned char first = merlin_ascii(s[i]);
    if (first == '*' || first == ';') {
        out->is_comment = true;
        return 0;
    }

    if (!is_ws(s[0])) {
        int j = 0;
        while (i < (int)n && !is_ws(s[i]) && merlin_ascii(s[i]) != ';') {
            put_ascii(out->label, &j, MERLIN_MAX_LABEL, s[i]);
            i++;
        }
        out->label[j] = '\0';
        out->has_label = (out->label[0] != '\0');
    }

    while (i < (int)n && is_ws(s[i])) i++;
    if (i >= (int)n || merlin_ascii(s[i]) == ';' || merlin_ascii(s[i]) == '*')
        return 0;

    int j = 0;
    while (i < (int)n && !is_ws(s[i]) && merlin_ascii(s[i]) != ';') {
        put_ascii(out->opcode, &j, MERLIN_MAX_OP, s[i]);
        i++;
    }
    out->opcode[j] = '\0';

    while (i < (int)n && is_ws(s[i])) i++;
    if (i >= (int)n || merlin_ascii(s[i]) == ';') return 0;

    j = 0;
    bool in_sq = false, in_dq = false;
    while (i < (int)n && j + 1 < MERLIN_MAX_LINE) {
        unsigned char raw = s[i];
        unsigned char c = merlin_ascii(raw);
        if (!in_sq && !in_dq && c == ';') break;
        if (!in_sq && !in_dq) {
            if (c == '\'') in_sq = true;
            else if (c == '"') in_dq = true;
        } else if (in_sq && c == '\'') {
            in_sq = false;
        } else if (in_dq && c == '"') {
            in_dq = false;
        }
        /* Keep $20 as a real space; field tabs shouldn't appear here. */
        if (c == 0) {
            i++;
            continue;
        }
        out->operand[j++] = (char)c;
        i++;
    }
    while (j > 0 && is_ws((unsigned char)out->operand[j - 1])) j--;
    out->operand[j] = '\0';
    return 0;
}

int parse_source(const char *src, const char *name, SrcLine **lines, int *nlines)
{
    int cap = 64, n = 0;
    SrcLine *arr = (SrcLine *)calloc((size_t)cap, sizeof(SrcLine));
    if (!arr) return -1;

    const unsigned char *p = (const unsigned char *)src;
    int lineno = 1;
    while (*p) {
        const unsigned char *start = p;
        while (*p && !merlin_is_eol(*p)) p++;
        size_t len = (size_t)(p - start);
        char buf[MERLIN_MAX_LINE + 8];
        if (len >= sizeof(buf)) len = sizeof(buf) - 1;
        memcpy(buf, start, len);
        buf[len] = '\0';

        if (n >= cap) {
            cap *= 2;
            SrcLine *na = (SrcLine *)realloc(arr, (size_t)cap * sizeof(SrcLine));
            if (!na) {
                free_source(arr, n);
                return -1;
            }
            memset(na + n, 0, (size_t)(cap - n) * sizeof(SrcLine));
            arr = na;
        }
        parse_line_text(buf, &arr[n]);
        arr[n].file = (char *)name;
        arr[n].lineno = lineno;
        arr[n].raw = (char *)malloc(len + 1);
        if (arr[n].raw) {
            memcpy(arr[n].raw, buf, len + 1);
        }
        n++;
        if (*p == 0) break;
        if (*p == 0x0D && p[1] == 0x0A) p += 2;
        else p++;
        lineno++;
    }
    *lines = arr;
    *nlines = n;
    return 0;
}

void free_source(SrcLine *lines, int nlines)
{
    if (!lines) return;
    for (int i = 0; i < nlines; i++)
        free(lines[i].raw);
    free(lines);
    (void)nlines;
}

static int split_top_comma(const char *s, char *left, size_t ln, char *right, size_t rn)
{
    int depth = 0;
    bool sq = false, dq = false;
    for (int i = 0; s[i]; i++) {
        char c = s[i];
        if (!sq && !dq) {
            if (c == '\'') sq = true;
            else if (c == '"') dq = true;
            else if (c == '(' || c == '[' || c == '{') depth++;
            else if (c == ')' || c == ']' || c == '}') {
                if (depth > 0) depth--;
            } else if (c == ',' && depth == 0) {
                char tmp[MERLIN_MAX_LINE];
                merlin_strlcpy(tmp, s, (size_t)i + 1);
                tmp[i] = '\0';
                merlin_strlcpy(left, merlin_trim(tmp), ln);
                merlin_strlcpy(right, merlin_trim((char *)s + i + 1), rn);
                return 1;
            }
        } else if (sq && c == '\'') sq = false;
        else if (dq && c == '"') dq = false;
    }
    return 0;
}

int parse_operand_form(const char *operand, OperandForm *form)
{
    memset(form, 0, sizeof(*form));
    form->syntax = SYN_IMP;
    if (!operand || !operand[0]) return 0;

    char buf[MERLIN_MAX_LINE];
    merlin_strlcpy(buf, operand, sizeof(buf));
    char *s = merlin_trim(buf);
    if (*s == 0) return 0;

    if (*s == '#') {
        form->syntax = SYN_IMM;
        s++;
        while (*s == ' ' || *s == '\t') s++;
        if (*s == '<' || *s == '>' || *s == '^') {
            form->byte_sel = *s;
            s++;
        } else if ((*s == 'A' || *s == 'a') && s[1] && s[1] != 'N' && s[1] != 'n') {
            /* #Aexpr = bank, but not #AND... too rare; also #" and #' */
        }
        merlin_strlcpy(form->expr, s, sizeof(form->expr));
        return 0;
    }

    if (*s == '>') {
        form->force = FORCE_LONG;
        s++;
        while (*s == ' ' || *s == '\t') s++;
    } else if (*s == '<' && s[1] != '=') {
        /* force DP if it looks like a prefix, not a comparison */
        form->force = FORCE_DP;
        s++;
        while (*s == ' ' || *s == '\t') s++;
    }

    if (*s == '(') {
        /* find matching ) */
        int depth = 1, i = 1;
        bool sq = false, dq = false;
        int comma = -1;
        for (; s[i] && depth; i++) {
            char c = s[i];
            if (!sq && !dq) {
                if (c == '\'') sq = true;
                else if (c == '"') dq = true;
                else if (c == '(') depth++;
                else if (c == ')') depth--;
                else if (c == ',' && depth == 1 && comma < 0) comma = i;
            } else if (sq && c == '\'') sq = false;
            else if (dq && c == '"') dq = false;
        }
        if (depth != 0) {
            merlin_strlcpy(form->expr, s, sizeof(form->expr));
            form->syntax = SYN_ABS;
            return 0;
        }
        int close = i - 1;
        char inner[MERLIN_MAX_LINE];
        memcpy(inner, s + 1, (size_t)close - 1);
        inner[close - 1] = '\0';

        char rest[MERLIN_MAX_LINE];
        merlin_strlcpy(rest, s + close + 1, sizeof(rest));
        char *r = merlin_trim(rest);

        if (comma >= 0) {
            char a[MERLIN_MAX_LINE], b[MERLIN_MAX_LINE];
            merlin_strlcpy(a, inner, (size_t)comma);
            a[comma - 1] = '\0';
            merlin_strlcpy(b, inner + (comma), sizeof(b));
            /* inner was s[1..close-1]; comma is index in s, so inner index = comma-1 */
            /* redo split on inner */
            split_top_comma(inner, a, sizeof(a), b, sizeof(b));
            if (merlin_stricmp(b, "X") == 0) {
                form->syntax = SYN_INDX;
                merlin_strlcpy(form->expr, merlin_trim(a), sizeof(form->expr));
            } else if (merlin_stricmp(b, "S") == 0) {
                if (r[0] == ',' && (r[1] == 'Y' || r[1] == 'y') && r[2] == '\0') {
                    form->syntax = SYN_SIY;
                    merlin_strlcpy(form->expr, merlin_trim(a), sizeof(form->expr));
                } else {
                    form->syntax = SYN_IND; /* unusual */
                    merlin_strlcpy(form->expr, merlin_trim(inner), sizeof(form->expr));
                }
            } else {
                form->syntax = SYN_IND;
                merlin_strlcpy(form->expr, merlin_trim(inner), sizeof(form->expr));
            }
        } else if (r[0] == ',' && (r[1] == 'Y' || r[1] == 'y')) {
            form->syntax = SYN_INDY;
            merlin_strlcpy(form->expr, merlin_trim(inner), sizeof(form->expr));
        } else {
            form->syntax = SYN_IND;
            merlin_strlcpy(form->expr, merlin_trim(inner), sizeof(form->expr));
        }
        return 0;
    }

    if (*s == '[') {
        int depth = 1, i = 1;
        for (; s[i] && depth; i++) {
            if (s[i] == '[') depth++;
            else if (s[i] == ']') depth--;
        }
        int close = i - 1;
        char inner[MERLIN_MAX_LINE];
        memcpy(inner, s + 1, (size_t)close - 1);
        inner[close - 1] = '\0';
        char rest[MERLIN_MAX_LINE];
        merlin_strlcpy(rest, s + close + 1, sizeof(rest));
        char *r = merlin_trim(rest);
        merlin_strlcpy(form->expr, merlin_trim(inner), sizeof(form->expr));
        if (r[0] == ',' && (r[1] == 'Y' || r[1] == 'y'))
            form->syntax = SYN_INDLY;
        else
            form->syntax = SYN_INDL;
        return 0;
    }

    char left[MERLIN_MAX_LINE], right[MERLIN_MAX_LINE];
    if (split_top_comma(s, left, sizeof(left), right, sizeof(right))) {
        if (merlin_stricmp(right, "X") == 0) {
            form->syntax = SYN_X;
            merlin_strlcpy(form->expr, left, sizeof(form->expr));
        } else if (merlin_stricmp(right, "Y") == 0) {
            form->syntax = SYN_Y;
            merlin_strlcpy(form->expr, left, sizeof(form->expr));
        } else if (merlin_stricmp(right, "S") == 0) {
            form->syntax = SYN_S;
            merlin_strlcpy(form->expr, left, sizeof(form->expr));
        } else {
            form->syntax = SYN_BLK;
            merlin_strlcpy(form->expr, left, sizeof(form->expr));
            merlin_strlcpy(form->expr2, right, sizeof(form->expr2));
        }
        return 0;
    }

    form->syntax = SYN_ABS;
    merlin_strlcpy(form->expr, s, sizeof(form->expr));
    return 0;
}
