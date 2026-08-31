#include "intern.hpp"

#include <cctype>
#include <cstring>

namespace merlin {

static bool is_ws(unsigned char c)
{
    return c == ' ' || c == '\t' || is_field_tab(c);
}

static bool line_has_a0(const unsigned char *s, size_t n)
{
    for (size_t i = 0; i < n; i++)
        if (s[i] == 0xA0) return true;
    return false;
}

static void put_ascii(std::string &dst, unsigned char c)
{
    unsigned char ch = to_ascii(c);
    if (ch) dst.push_back(static_cast<char>(ch));
}

static SrcLine parse_line_native(const unsigned char *s, size_t n)
{
    std::string fields[4];
    int f = 0;
    for (size_t i = 0; i < n; i++) {
        unsigned char c = s[i];
        if (is_eol(c)) break;
        if (is_field_tab(c)) {
            if (f < 3) f++;
            else fields[3].push_back(' ');
            continue;
        }
        put_ascii(fields[f], c);
    }
    SrcLine out;
    out.label = trim_copy(fields[0]);
    out.opcode = trim_copy(fields[1]);
    out.operand = trim_copy(fields[2]);
    out.has_label = !out.label.empty();
    if ((!out.label.empty() && (out.label[0] == '*' || out.label[0] == ';')) ||
        (out.label.empty() && !out.opcode.empty() &&
         (out.opcode[0] == '*' || out.opcode[0] == ';')))
        out.is_comment = true;
    return out;
}

SrcLine parse_line_text(const std::string &text)
{
    const auto *s = reinterpret_cast<const unsigned char *>(text.data());
    size_t n = 0;
    while (n < text.size() && !is_eol(s[n])) n++;

    SrcLine out;
    if (n == 0) return out;

    if (line_has_a0(s, n))
        return parse_line_native(s, n);

    size_t i = 0;
    while (i < n && is_ws(s[i])) i++;
    if (i >= n) return out;

    unsigned char first = to_ascii(s[i]);
    if (first == '*' || first == ';') {
        out.is_comment = true;
        return out;
    }

    if (!is_ws(s[0])) {
        while (i < n && !is_ws(s[i]) && to_ascii(s[i]) != ';') {
            put_ascii(out.label, s[i]);
            i++;
        }
        out.has_label = !out.label.empty();
    }

    while (i < n && is_ws(s[i])) i++;
    if (i >= n || to_ascii(s[i]) == ';' || to_ascii(s[i]) == '*')
        return out;

    while (i < n && !is_ws(s[i]) && to_ascii(s[i]) != ';') {
        put_ascii(out.opcode, s[i]);
        i++;
    }

    while (i < n && is_ws(s[i])) i++;
    if (i >= n || to_ascii(s[i]) == ';') return out;

    bool in_sq = false, in_dq = false;
    while (i < n) {
        unsigned char c = to_ascii(s[i]);
        if (!in_sq && !in_dq && c == ';') {
            if (out.operand.empty() ||
                is_ws(static_cast<unsigned char>(out.operand.back())))
                break;
        }
        if (!in_sq && !in_dq) {
            if (c == '\'') in_sq = true;
            else if (c == '"') in_dq = true;
        } else if (in_sq && c == '\'') in_sq = false;
        else if (in_dq && c == '"') in_dq = false;
        if (c != 0) out.operand.push_back(static_cast<char>(c));
        i++;
    }
    out.operand = trim_copy(out.operand);
    return out;
}

std::vector<SrcLine> parse_source(const std::string &src, const std::string &name)
{
    std::vector<SrcLine> lines;
    const auto *p = reinterpret_cast<const unsigned char *>(src.data());
    const auto *end = p + src.size();
    int lineno = 1;
    while (p < end) {
        const auto *start = p;
        while (p < end && !is_eol(*p)) p++;
        std::string buf(reinterpret_cast<const char *>(start),
                        static_cast<size_t>(p - start));
        SrcLine ln = parse_line_text(buf);
        ln.file = name;
        ln.lineno = lineno;
        ln.raw = std::move(buf);
        lines.push_back(std::move(ln));
        if (p >= end) break;
        if (*p == 0x0D && p + 1 < end && p[1] == 0x0A) p += 2;
        else p++;
        lineno++;
    }
    return lines;
}

static bool split_top_comma(const std::string &s, std::string &left, std::string &right)
{
    int depth = 0;
    bool sq = false, dq = false;
    for (size_t i = 0; i < s.size(); i++) {
        char c = s[i];
        if (!sq && !dq) {
            if (c == '\'') sq = true;
            else if (c == '"') dq = true;
            else if (c == '(' || c == '[' || c == '{') depth++;
            else if ((c == ')' || c == ']' || c == '}') && depth > 0) depth--;
            else if (c == ',' && depth == 0) {
                left = trim_copy(s.substr(0, i));
                right = trim_copy(s.substr(i + 1));
                return true;
            }
        } else if (sq && c == '\'') sq = false;
        else if (dq && c == '"') dq = false;
    }
    return false;
}

OperandForm parse_operand_form(const std::string &operand)
{
    OperandForm form;
    std::string buf = trim_copy(operand);
    if (buf.empty()) return form;
    const char *s = buf.c_str();

    auto skipsp = [&]() {
        while (*s == ' ' || *s == '\t') s++;
    };

    if (*s == '#') {
        form.syntax = SYN_IMM;
        s++;
        skipsp();
        if (*s == '<' || *s == '>' || *s == '^') {
            form.byte_sel = *s++;
        } else if ((*s == 'A' || *s == 'a') && s[1] && s[1] != 'N' && s[1] != 'n') {
            form.byte_sel = '^';
            s++;
        }
        form.expr = s;
        return form;
    }

    if (*s == '|') {
        form.force = FORCE_ABS;
        s++;
        skipsp();
    } else if (*s == '>') {
        form.force = FORCE_LONG;
        s++;
        skipsp();
    } else if (*s == '<' && s[1] != '=') {
        form.force = FORCE_DP;
        s++;
        skipsp();
    } else if (*s == '^') {
        form.force = FORCE_ABS;
        form.byte_sel = '^';
        s++;
        skipsp();
    }

    if (*s == '(') {
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
            form.expr = s;
            form.syntax = SYN_ABS;
            return form;
        }
        int close = i - 1;
        std::string inner(s + 1, static_cast<size_t>(close - 1));
        std::string rest = trim_copy(s + close + 1);
        if (comma >= 0) {
            std::string a, b;
            split_top_comma(inner, a, b);
            if (icmp(b, "X") == 0) {
                form.syntax = SYN_INDX;
                form.expr = trim_copy(a);
            } else if (icmp(b, "S") == 0) {
                if (rest.size() >= 2 && rest[0] == ',' &&
                    (rest[1] == 'Y' || rest[1] == 'y')) {
                    form.syntax = SYN_SIY;
                    form.expr = trim_copy(a);
                } else {
                    form.syntax = SYN_IND;
                    form.expr = trim_copy(inner);
                }
            } else {
                form.syntax = SYN_IND;
                form.expr = trim_copy(inner);
            }
        } else if (rest.size() >= 2 && rest[0] == ',' &&
                   (rest[1] == 'Y' || rest[1] == 'y')) {
            form.syntax = SYN_INDY;
            form.expr = trim_copy(inner);
        } else {
            form.syntax = SYN_IND;
            form.expr = trim_copy(inner);
        }
        return form;
    }

    if (*s == '[') {
        int depth = 1, i = 1;
        for (; s[i] && depth; i++) {
            if (s[i] == '[') depth++;
            else if (s[i] == ']') depth--;
        }
        int close = i - 1;
        std::string inner(s + 1, static_cast<size_t>(close - 1));
        std::string rest = trim_copy(s + close + 1);
        form.expr = trim_copy(inner);
        form.syntax = (rest.size() >= 2 && rest[0] == ',' &&
                       (rest[1] == 'Y' || rest[1] == 'y'))
                          ? SYN_INDLY
                          : SYN_INDL;
        return form;
    }

    std::string left, right;
    if (split_top_comma(s, left, right)) {
        if (icmp(right, "X") == 0) {
            form.syntax = SYN_X;
            form.expr = left;
        } else if (icmp(right, "Y") == 0) {
            form.syntax = SYN_Y;
            form.expr = left;
        } else if (icmp(right, "S") == 0) {
            form.syntax = SYN_S;
            form.expr = left;
        } else {
            form.syntax = SYN_BLK;
            form.expr = left;
            form.expr2 = right;
        }
        return form;
    }

    form.syntax = SYN_ABS;
    form.expr = s;
    return form;
}

} // namespace merlin
