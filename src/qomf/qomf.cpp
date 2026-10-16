/* Dump Apple IIgs OMF 1.0 and 2.0.
   Header numbers are little-endian. Body numbers use NUMLEN and NUMSEX.
   Record operands follow the layouts read by 6502bench SourceGen
   (faddenSoft, Apache-2.0) and by src/omf/omf.cpp. A record whose size
   is not in those layouts stops the segment. */

#include "qomf.hpp"

#include <cstdint>
#include <cstdio>
#include <sstream>
#include <string>
#include <vector>

namespace qasm {
namespace {

std::string hex_n(uint32_t v, int digits)
{
    char b[16];
    std::snprintf(b, sizeof b, "%0*X", digits, static_cast<unsigned>(v));
    return b;
}

std::string hex8(uint32_t v) { return hex_n(v, 8); }

const char *bytes_word(size_t n) { return n == 1 ? "byte" : "bytes"; }

std::string quote_text(const std::string &s)
{
    std::string o = "\"";
    for (unsigned char c : s) {
        if (c == '"' || c == '\\') {
            o.push_back('\\');
            o.push_back(static_cast<char>(c));
        } else if (c >= 32 && c < 127) {
            o.push_back(static_cast<char>(c));
        } else {
            char b[8];
            std::snprintf(b, sizeof b, "\\x%02X", c);
            o += b;
        }
    }
    o.push_back('"');
    return o;
}

uint32_t load_le(const std::vector<uint8_t> &in, size_t at, int n)
{
    uint32_t v = 0;
    for (int k = 0; k < n; k++)
        v |= static_cast<uint32_t>(in[at + static_cast<size_t>(k)]) << (8 * k);
    return v;
}

struct Cur {
    const std::vector<uint8_t> &in;
    size_t i = 0;
    size_t end = 0;
    int numlen = 4;
    bool big = false;
    int lablen = 0;
    int version = 2;
    std::string err{};
};

bool need(Cur &c, size_t n)
{
    return c.i + n <= c.end;
}

bool read_n(Cur &c, int n, uint32_t &v)
{
    if (n < 1 || !need(c, static_cast<size_t>(n))) return false;
    v = 0;
    if (!c.big) {
        for (int k = 0; k < n; k++)
            v |= static_cast<uint32_t>(c.in[c.i + static_cast<size_t>(k)]) << (8 * k);
    } else {
        for (int k = 0; k < n; k++)
            v = (v << 8) | c.in[c.i + static_cast<size_t>(k)];
    }
    c.i += static_cast<size_t>(n);
    return true;
}

bool read_num(Cur &c, uint32_t &v) { return read_n(c, c.numlen, v); }

bool take_label(const std::vector<uint8_t> &in, size_t &i, size_t end, int lablen,
                std::string &name, std::string &err)
{
    size_t n = static_cast<size_t>(lablen);
    if (lablen == 0) {
        if (i >= end) {
            err = "OMF label runs off the segment";
            return false;
        }
        n = in[i++];
    }
    if (i + n > end) {
        err = "OMF label runs off the segment";
        return false;
    }
    name.assign(reinterpret_cast<const char *>(&in[i]), n);
    if (lablen != 0) {
        while (!name.empty() && name.back() == ' ') name.pop_back();
    }
    i += n;
    return true;
}

bool read_label(Cur &c, std::string &name)
{
    return take_label(c.in, c.i, c.end, c.lablen, name, c.err);
}

const char *bin_op(uint8_t op)
{
    switch (op) {
    case 0x01: return "+";
    case 0x02: return "-";
    case 0x03: return "*";
    case 0x04: return "/";
    case 0x05: return "%";
    case 0x07: return " shift ";
    case 0x08: return "&&";
    case 0x09: return "||";
    case 0x0A: return "^^";
    case 0x0C: return "<=";
    case 0x0D: return ">=";
    case 0x0E: return "!=";
    case 0x0F: return "<";
    case 0x10: return ">";
    case 0x11: return "==";
    case 0x12: return "&";
    case 0x13: return "|";
    case 0x14: return "^";
    default: return nullptr;
    }
}

const char *un_op(uint8_t op)
{
    switch (op) {
    case 0x06: return "-";
    case 0x0B: return "!";
    case 0x15: return "~";
    default: return nullptr;
    }
}

bool outer_parens(const std::string &s)
{
    if (s.size() < 2 || s.front() != '(' || s.back() != ')') return false;
    int d = 0;
    for (size_t i = 0; i < s.size(); i++) {
        if (s[i] == '(') d++;
        else if (s[i] == ')') {
            d--;
            if (d == 0 && i + 1 != s.size()) return false;
        }
    }
    return d == 0;
}

bool read_expr(Cur &c, std::string &expr)
{
    std::vector<std::string> st;
    while (c.i < c.end) {
        uint8_t op = c.in[c.i++];
        if (op == 0x00) {
            if (st.size() == 1) {
                expr = st[0];
                if (outer_parens(expr)) expr = expr.substr(1, expr.size() - 2);
            } else {
                expr.clear();
                for (size_t n = 0; n < st.size(); n++) {
                    if (n) expr += ", ";
                    expr += st[n];
                }
            }
            return true;
        }
        if (const char *bop = bin_op(op)) {
            if (st.size() < 2) {
                c.err = "OMF expression stack underflow";
                return false;
            }
            std::string rhs = st.back();
            st.pop_back();
            std::string lhs = st.back();
            st.pop_back();
            st.push_back("(" + lhs + bop + rhs + ")");
            continue;
        }
        if (const char *uop = un_op(op)) {
            if (st.empty()) {
                c.err = "OMF expression stack underflow";
                return false;
            }
            std::string arg = st.back();
            st.pop_back();
            st.push_back(std::string(uop) + arg);
            continue;
        }
        if (op == 0x80) {
            st.push_back("[loc]");
            continue;
        }
        if (op == 0x81 || op == 0x87) {
            uint32_t v = 0;
            if (!read_num(c, v)) {
                c.err = "OMF constant runs off the expression";
                return false;
            }
            std::string num = "$" + hex_n(v, c.numlen * 2);
            st.push_back(op == 0x87 ? "rel:" + num : num);
            continue;
        }
        if (op >= 0x82 && op <= 0x86) {
            std::string name;
            if (!read_label(c, name)) return false;
            const char *pre = "";
            if (op == 0x82) pre = "weak:";
            else if (op == 0x84) pre = "len:";
            else if (op == 0x85) pre = "typ:";
            else if (op == 0x86) pre = "cnt:";
            st.push_back(std::string(pre) + name);
            continue;
        }
        char b[64];
        std::snprintf(b, sizeof b, "unsupported OMF expression operator $%02X", op);
        c.err = b;
        return false;
    }
    c.err = "OMF expression has no end";
    return false;
}

void hex_rows(std::ostream &out, const std::vector<uint8_t> &in, size_t at, size_t n,
              uint32_t lc)
{
    for (size_t i = 0; i < n; i += 16) {
        uint32_t addr = lc + static_cast<uint32_t>(i);
        int digits = addr > 0xFFFFFFu ? 8 : 6;
        out << "           " << hex_n(addr, digits);
        size_t m = n - i;
        if (m > 16) m = 16;
        for (size_t j = 0; j < m; j++) {
            char b[4];
            std::snprintf(b, sizeof b, " %02X", in[at + i + j]);
            out << b;
        }
        out << "\n";
    }
}

const char *type_name(unsigned low)
{
    switch (low & 0x1Fu) {
    case 0x00: return "code";
    case 0x01: return "data";
    case 0x02: return "jump table";
    case 0x04: return "pathname";
    case 0x08: return "library dictionary";
    case 0x10: return "init";
    case 0x11: return "absolute bank";
    case 0x12: return "dp/stack";
    default: return nullptr;
    }
}

std::string flag_text(bool v2, unsigned raw)
{
    std::string s;
    if (v2) {
        if (raw & 0x0100) s += " bank-relative";
        if (raw & 0x0200) s += " skip";
        if (raw & 0x0400) s += " reloadable";
        if (raw & 0x0800) s += " absolute-bank";
        if (raw & 0x1000) s += " no-special";
        if (raw & 0x2000) s += " position-independent";
        if (raw & 0x4000) s += " private";
        if (raw & 0x8000) s += " dynamic";
    } else {
        if (raw & 0x20) s += " position-independent";
        if (raw & 0x40) s += " private";
        if (raw & 0x80) s += " dynamic";
    }
    if (!s.empty()) s.erase(0, 1);
    return s;
}

std::string kind_words(bool v2, unsigned raw)
{
    unsigned low = v2 ? (raw & 0x1Fu) : (raw & 0x1Fu);
    const char *name = type_name(low);
    std::string flags = flag_text(v2, raw);
    if (name && !flags.empty()) return std::string(name) + " " + flags;
    if (name) return name;
    return flags;
}

bool read_attrs(Cur &c, uint32_t &length, uint8_t &type, uint8_t &priv)
{
    if (c.version <= 1) {
        if (!need(c, 3)) return false;
        length = c.in[c.i];
        type = c.in[c.i + 1];
        priv = c.in[c.i + 2];
        c.i += 3;
        return true;
    }
    if (!need(c, 4)) return false;
    length = c.big ? (static_cast<uint32_t>(c.in[c.i]) << 8) | c.in[c.i + 1]
                   : c.in[c.i] | (static_cast<uint32_t>(c.in[c.i + 1]) << 8);
    type = c.in[c.i + 2];
    priv = c.in[c.i + 3];
    c.i += 4;
    return true;
}

void print_type_byte(std::ostream &out, uint8_t type)
{
    if (type >= 0x20 && type < 0x7F && type != '\'' && type != '\\')
        out << "type '" << static_cast<char>(type) << "' ($" << hex_n(type, 2) << ")";
    else
        out << "type $" << hex_n(type, 2);
}

bool symbol_record(Cur &c, std::ostream &out, size_t rec, uint32_t lc, const char *what,
                   bool with_expr)
{
    std::string name;
    if (!read_label(c, name)) return false;
    uint32_t length = 0;
    uint8_t type = 0, priv = 0;
    if (!read_attrs(c, length, type, priv)) {
        c.err = std::string(what) + " record runs off the segment";
        return false;
    }
    std::string expr;
    if (with_expr && !read_expr(c, expr)) return false;
    int digits = c.version <= 1 ? 2 : 4;
    out << "  +$" << hex8(static_cast<uint32_t>(rec)) << "  " << what << "  " << quote_text(name);
    if (!with_expr) out << "  at $" << hex8(lc);
    out << "  length $" << hex_n(length, digits) << "  ";
    print_type_byte(out, type);
    out << "  private " << static_cast<unsigned>(priv);
    if (with_expr) out << "  = " << expr;
    out << "\n";
    return true;
}

bool parse_records(Cur &c, std::ostream &out, uint32_t &lc, int &relocs, int &fixups,
                   bool &saw_object, bool &saw_load)
{
    while (c.i < c.end) {
        size_t rec = c.i;
        uint8_t op = c.in[c.i++];
        std::string at = hex8(static_cast<uint32_t>(rec));
        if (op == 0x00) {
            out << "  +$" << at << "  END\n";
            return true;
        }
        if (op >= 0x01 && op <= 0xDF) {
            if (!need(c, op)) {
                c.err = "CONST record runs off the segment";
                return false;
            }
            out << "  +$" << at << "  CONST  " << static_cast<unsigned>(op) << " "
                << bytes_word(op) << " at $"
                << hex8(lc) << "\n";
            hex_rows(out, c.in, c.i, op, lc);
            c.i += op;
            lc += op;
            saw_object = true;
            continue;
        }
        if (op == 0xE0 || op == 0xE1 || op == 0xF1) {
            uint32_t n = 0;
            if (!read_num(c, n)) {
                c.err = op == 0xF1 ? "DS record runs off the segment"
                        : op == 0xE0 ? "ALIGN record runs off the segment"
                                     : "ORG record runs off the segment";
                return false;
            }
            if (op == 0xF1) {
                out << "  +$" << at << "  DS  $" << hex8(n) << " bytes at $" << hex8(lc) << "\n";
                lc += n;
            } else if (op == 0xE0) {
                if (n > 1) {
                    uint64_t aligned = (static_cast<uint64_t>(lc) + n - 1) / n * n;
                    if (aligned <= 0xFFFFFFFFu) lc = static_cast<uint32_t>(aligned);
                }
                out << "  +$" << at << "  ALIGN  $" << hex8(n) << "  lc $" << hex8(lc) << "\n";
                saw_object = true;
            } else {
                lc = n;
                out << "  +$" << at << "  ORG  $" << hex8(n) << "\n";
                saw_object = true;
            }
            continue;
        }
        if (op == 0xE2 || op == 0xE3) {
            uint32_t offset = 0, disp = 0, file = 0, seg = 0;
            if (!need(c, 2)) {
                c.err = op == 0xE2 ? "RELOC record runs off the segment"
                                   : "INTERSEG record runs off the segment";
                return false;
            }
            uint8_t width = c.in[c.i];
            int8_t shift = static_cast<int8_t>(c.in[c.i + 1]);
            c.i += 2;
            if (!read_num(c, offset)) {
                c.err = op == 0xE2 ? "RELOC record runs off the segment"
                                   : "INTERSEG record runs off the segment";
                return false;
            }
            if (op == 0xE3) {
                if (!read_n(c, 2, file) || !read_n(c, 2, seg)) {
                    c.err = "INTERSEG record runs off the segment";
                    return false;
                }
            }
            if (!read_num(c, disp)) {
                c.err = op == 0xE2 ? "RELOC record runs off the segment"
                                   : "INTERSEG record runs off the segment";
                return false;
            }
            out << "  +$" << at << (op == 0xE2 ? "  RELOC  " : "  INTERSEG  ") << "width "
                << static_cast<unsigned>(width) << "  shift " << static_cast<int>(shift)
                << "  at $" << hex8(offset);
            if (op == 0xE3)
                out << "  file " << file << "  seg " << seg;
            out << "  disp $" << hex8(disp) << "\n";
            relocs++;
            saw_load = true;
            continue;
        }
        if (op == 0xE4 || op == 0xE5) {
            std::string name;
            if (!read_label(c, name)) return false;
            out << "  +$" << at << (op == 0xE4 ? "  USING  " : "  STRONG  ") << quote_text(name)
                << "\n";
            saw_object = true;
            continue;
        }
        if (op == 0xE6 || op == 0xEF) {
            if (!symbol_record(c, out, rec, lc, op == 0xE6 ? "GLOBAL" : "LOCAL", false))
                return false;
            saw_object = true;
            continue;
        }
        if (op == 0xE7 || op == 0xF0) {
            if (!symbol_record(c, out, rec, lc, op == 0xE7 ? "GEQU" : "EQU", true)) return false;
            saw_object = true;
            continue;
        }
        if (op == 0xE8) {
            uint32_t a = 0, b = 0;
            if (!read_num(c, a) || !read_num(c, b)) {
                c.err = "MEM record runs off the segment";
                return false;
            }
            out << "  +$" << at << "  MEM  $" << hex8(a) << "  $" << hex8(b) << "\n";
            saw_object = true;
            continue;
        }
        if (op == 0xEB || op == 0xEC || op == 0xED || op == 0xF3 || op == 0xEE) {
            if (!need(c, 1)) {
                c.err = "expression record runs off the segment";
                return false;
            }
            uint8_t width = c.in[c.i++];
            uint32_t offset = 0;
            bool relexpr = op == 0xEE;
            if (relexpr && !read_num(c, offset)) {
                c.err = "RELEXPR record runs off the segment";
                return false;
            }
            std::string expr;
            if (!read_expr(c, expr)) return false;
            const char *name = "EXPR";
            if (op == 0xEC) name = "ZEXPR";
            else if (op == 0xED) name = "BEXPR";
            else if (op == 0xF3) name = "LEXPR";
            else if (op == 0xEE) name = "RELEXPR";
            out << "  +$" << at << "  " << name << "  width " << static_cast<unsigned>(width);
            if (relexpr) out << "  at $" << hex8(offset);
            out << "  " << expr << "\n";
            fixups++;
            saw_object = true;
            continue;
        }
        if (op == 0xF2) {
            uint32_t n = 0;
            if (!read_num(c, n) || !need(c, n)) {
                c.err = "LCONST record runs off the segment";
                return false;
            }
            out << "  +$" << at << "  LCONST  " << n << " " << bytes_word(n) << " at $"
                << hex8(lc) << "\n";
            hex_rows(out, c.in, c.i, n, lc);
            c.i += n;
            lc += n;
            continue;
        }
        if (op == 0xF5 || op == 0xF6) {
            int nbytes = op == 0xF5 ? 6 : 7;
            if (!need(c, static_cast<size_t>(nbytes))) {
                c.err = op == 0xF5 ? "cRELOC record runs off the segment"
                                   : "cINTERSEG record runs off the segment";
                return false;
            }
            uint8_t width = c.in[c.i];
            int8_t shift = static_cast<int8_t>(c.in[c.i + 1]);
            c.i += 2;
            uint32_t offset = 0, disp = 0, seg = 0;
            if (!read_n(c, 2, offset)) return false;
            if (op == 0xF6) {
                seg = c.in[c.i++];
            }
            if (!read_n(c, 2, disp)) return false;
            out << "  +$" << at << (op == 0xF5 ? "  cRELOC  " : "  cINTERSEG  ") << "width "
                << static_cast<unsigned>(width) << "  shift " << static_cast<int>(shift)
                << "  at $" << hex_n(offset, 4);
            if (op == 0xF6) out << "  seg " << seg;
            out << "  disp $" << hex_n(disp, 4) << "\n";
            relocs++;
            saw_load = true;
            continue;
        }
        if (op == 0xF7 || op >= 0xFB) {
            uint32_t n = 0;
            if (!read_num(c, n) || !need(c, n)) {
                c.err = op == 0xF7 ? "SUPER record runs off the segment"
                                   : "extended record runs off the segment";
                return false;
            }
            if (op == 0xF7) {
                if (n < 1) {
                    c.err = "SUPER record is empty";
                    return false;
                }
                uint8_t type = c.in[c.i];
                out << "  +$" << at << "  SUPER  type $" << hex_n(type, 2) << "  " << (n - 1) << " "
                    << bytes_word(n - 1) << "\n";
                hex_rows(out, c.in, c.i + 1, n - 1, 0);
                relocs++;
                saw_load = true;
            } else if (op == 0xFB) {
                out << "  +$" << at << "  GENERAL  " << n << " " << bytes_word(n) << "\n";
                hex_rows(out, c.in, c.i, n, 0);
            } else {
                out << "  +$" << at << "  EXPERIMENTAL  $" << hex_n(op, 2) << "  " << n << " "
                    << bytes_word(n) << "\n";
                hex_rows(out, c.in, c.i, n, 0);
            }
            c.i += n;
            continue;
        }
        char b[48];
        std::snprintf(b, sizeof b, "unsupported OMF record $%02X", op);
        c.err = b;
        return false;
    }
    c.err = "segment has no END record";
    return false;
}

struct Head {
    size_t off = 0;
    uint32_t seglen = 0;
    uint32_t count_field = 0;
    bool blocks = false;
    uint32_t resspc = 0;
    uint32_t length = 0;
    uint32_t org = 0;
    uint32_t align = 0;
    uint32_t entry = 0;
    uint32_t banksize = 0;
    uint32_t temporg = 0;
    uint32_t reserved14 = 0;
    uint16_t kind = 0;
    uint16_t segnum = 0;
    uint16_t dispname = 0;
    uint16_t dispdata = 0;
    uint16_t reserved16 = 0;
    uint8_t lablen = 0;
    uint8_t numlen = 4;
    uint8_t version = 2;
    uint8_t numsex = 0;
    uint8_t reserved0c = 0;
    uint8_t lcbank = 0;
    bool v21 = false;
    std::string loadname;
    std::string segname;
    size_t name_end = 0;
};

bool read_header(const std::vector<uint8_t> &in, size_t off, int file_version, Head &h,
                 std::string &err)
{
    if (off + 0x2C > in.size()) {
        err = off == 0 ? "file is too small to be OMF" : "bytes follow the last segment";
        return false;
    }
    int version = in[off + 0x0F];
    if (version != 1 && version != 2) {
        err = "OMF version is not 1 or 2";
        return false;
    }
    if (file_version != 0 && version != file_version) {
        err = "OMF segments disagree on version";
        return false;
    }
    uint8_t numlen = in[off + 0x0E];
    if (numlen != 1 && numlen != 2 && numlen != 4) {
        err = "OMF NUMLEN must be 1, 2, or 4";
        return false;
    }
    uint8_t numsex = in[off + 0x20];
    if (numsex > 1) {
        err = "OMF NUMSEX must be 0 or 1";
        return false;
    }
    uint32_t field = load_le(in, off, 4);
    uint32_t seglen = field;
    bool blocks = false;
    if (version == 1) {
        uint64_t bytes = static_cast<uint64_t>(field) * 512;
        if (field >= 1 && off + bytes <= in.size()) {
            seglen = static_cast<uint32_t>(bytes);
            blocks = true;
        }
    }
    if (seglen < 0x2C || off + seglen > in.size()) {
        err = "OMF segment length runs off the file";
        return false;
    }
    h = Head{};
    h.off = off;
    h.seglen = seglen;
    h.count_field = field;
    h.blocks = blocks;
    h.resspc = load_le(in, off + 0x04, 4);
    h.length = load_le(in, off + 0x08, 4);
    h.banksize = load_le(in, off + 0x10, 4);
    h.org = load_le(in, off + 0x18, 4);
    h.align = load_le(in, off + 0x1C, 4);
    h.segnum = static_cast<uint16_t>(load_le(in, off + 0x22, 2));
    h.entry = load_le(in, off + 0x24, 4);
    h.dispname = static_cast<uint16_t>(load_le(in, off + 0x28, 2));
    h.dispdata = static_cast<uint16_t>(load_le(in, off + 0x2A, 2));
    h.lablen = in[off + 0x0D];
    h.numlen = numlen;
    h.version = static_cast<uint8_t>(version);
    h.numsex = numsex;
    h.lcbank = in[off + 0x21];
    if (version == 1) {
        h.kind = in[off + 0x0C];
        h.reserved14 = load_le(in, off + 0x14, 4);
    } else {
        h.reserved0c = in[off + 0x0C];
        h.kind = static_cast<uint16_t>(load_le(in, off + 0x14, 2));
        h.reserved16 = static_cast<uint16_t>(load_le(in, off + 0x16, 2));
        if (h.dispname > 0x2C) {
            if (h.dispname < 0x30 || seglen < 0x30) {
                err = "OMF DISPNAME or DISPDATA is out of range";
                return false;
            }
            h.v21 = true;
            h.temporg = load_le(in, off + 0x2C, 4);
        }
    }
    uint16_t min_name = h.v21 ? 0x30 : 0x2C;
    if (h.dispname < min_name || static_cast<uint32_t>(h.dispname) + 10 > seglen) {
        err = "OMF DISPNAME or DISPDATA is out of range";
        return false;
    }
    size_t name_at = off + h.dispname;
    std::string load;
    load.assign(reinterpret_cast<const char *>(&in[name_at]), 10);
    while (!load.empty() && (load.back() == ' ' || load.back() == '\0')) load.pop_back();
    h.loadname = load;
    size_t seg_at = name_at + 10;
    if (!take_label(in, seg_at, off + seglen, h.lablen, h.segname, err)) return false;
    h.name_end = seg_at;
    if (h.dispdata < h.name_end - off || h.dispdata >= seglen) {
        err = "OMF DISPNAME or DISPDATA is out of range";
        return false;
    }
    return true;
}

void print_header(std::ostream &out, const Head &h, int index)
{
    out << "segment " << index << " at file+$" << hex8(static_cast<uint32_t>(h.off)) << "\n";
    if (h.blocks)
        out << "  blkcnt $" << hex8(h.count_field) << "\n";
    else
        out << "  bytecnt $" << hex8(h.count_field) << "\n";
    out << "  resspc $" << hex8(h.resspc) << "\n";
    out << "  length $" << hex8(h.length) << "\n";
    if (h.version == 1) {
        out << "  type $" << hex_n(h.kind, 2);
        std::string words = kind_words(false, h.kind);
        if (!words.empty()) out << " " << words;
        out << "\n";
    } else if (h.reserved0c) {
        out << "  reserved +$0C $" << hex_n(h.reserved0c, 2) << "\n";
    }
    out << "  lablen " << static_cast<unsigned>(h.lablen)
        << (h.lablen == 0 ? " (Pascal)\n" : " (fixed)\n");
    out << "  numlen " << static_cast<unsigned>(h.numlen) << "\n";
    out << "  version " << static_cast<unsigned>(h.version) << "\n";
    out << "  banksize $" << hex8(h.banksize) << "\n";
    if (h.version >= 2) {
        out << "  kind $" << hex_n(h.kind, 4);
        std::string words = kind_words(true, h.kind);
        if (!words.empty()) out << " " << words;
        out << "\n";
        if (h.reserved16)
            out << "  reserved +$16 $" << hex_n(h.reserved16, 4) << "\n";
    } else if (h.reserved14) {
        out << "  reserved +$14 $" << hex8(h.reserved14) << "\n";
    }
    out << "  org $" << hex8(h.org) << "\n";
    out << "  align $" << hex8(h.align) << "\n";
    out << "  numsex " << static_cast<unsigned>(h.numsex)
        << (h.numsex ? " (big)\n" : " (little)\n");
    if (h.version == 1)
        out << "  lcbank $" << hex_n(h.lcbank, 2) << "\n";
    else if (h.lcbank)
        out << "  reserved +$21 $" << hex_n(h.lcbank, 2) << "\n";
    out << "  segnum " << h.segnum << "\n";
    out << "  entry $" << hex8(h.entry) << "\n";
    out << "  dispname $" << hex_n(h.dispname, 4) << "\n";
    out << "  dispdata $" << hex_n(h.dispdata, 4) << "\n";
    if (h.v21) {
        out << "  temporg $" << hex8(h.temporg) << "\n";
        if (h.dispname > 0x30)
            out << "  header gap: " << (h.dispname - 0x30) << " bytes\n";
    }
    out << "  loadname " << quote_text(h.loadname) << "\n";
    out << "  segname " << quote_text(h.segname) << "\n";
    size_t body = h.off + h.dispdata;
    if (body > h.name_end)
        out << "  name gap: " << (body - h.name_end) << " bytes\n";
}

} // namespace

bool omf_dump(const std::vector<uint8_t> &in, const std::string &label, std::ostream &out,
              std::string &err)
{
    err.clear();
    if (in.size() < 0x2C) {
        err = "file is too small to be OMF";
        return false;
    }
    std::ostringstream body;
    int file_version = 0;
    bool any_v21 = false;
    bool saw_object = false;
    bool saw_load = false;
    int nseg = 0;
    size_t off = 0;
    while (off < in.size()) {
        Head h;
        if (!read_header(in, off, file_version, h, err)) {
            out << body.str();
            return false;
        }
        file_version = h.version;
        if (h.v21) any_v21 = true;
        if (nseg) body << "\n";
        nseg++;
        print_header(body, h, nseg);
        Cur c{in};
        c.i = off + h.dispdata;
        c.end = off + h.seglen;
        c.numlen = h.numlen;
        c.big = h.numsex != 0;
        c.lablen = h.lablen;
        c.version = h.version;
        uint32_t lc = 0;
        int relocs = 0;
        int fixups = 0;
        if (!parse_records(c, body, lc, relocs, fixups, saw_object, saw_load)) {
            err = c.err.empty() ? "segment has no END record" : c.err;
            out << body.str();
            return false;
        }
        size_t pad = c.end - c.i;
        if (pad) body << "  padding: " << pad << " " << bytes_word(pad) << "\n";
        body << "  relocations: " << relocs << "\n";
        body << "  fixups: " << fixups << "\n";
        off += h.seglen;
    }
    if (nseg == 0) {
        err = "OMF file has no segments";
        return false;
    }
    const char *klass = "load file";
    if (saw_object && saw_load) klass = "mixed file";
    else if (saw_object) klass = "object file";
    const char *ver = "2.0";
    if (file_version == 1) ver = "1.0";
    else if (any_v21) ver = "2.1";
    out << label << ": OMF " << ver << " " << klass << ", " << nseg
        << (nseg == 1 ? " segment, " : " segments, ") << in.size() << " bytes\n";
    out << body.str();
    return true;
}

} // namespace qasm
