#include "link.hpp"

#include <cctype>
#include <cstdint>
#include <fstream>
#include <map>
#include <set>
#include <sstream>

namespace qasm {
namespace {

std::string trim(std::string s)
{
    size_t a = 0;
    while (a < s.size() && (s[a] == ' ' || s[a] == '\t' || s[a] == '\r')) a++;
    size_t b = s.size();
    while (b > a && (s[b - 1] == ' ' || s[b - 1] == '\t' || s[b - 1] == '\r')) b--;
    return s.substr(a, b - a);
}

std::string upper(std::string s)
{
    for (char &c : s)
        c = static_cast<char>(std::toupper(static_cast<unsigned char>(c)));
    return s;
}

bool ieq(const std::string &a, const std::string &b) { return upper(a) == upper(b); }

std::string dirname_of(const std::string &path)
{
    auto s = path.find_last_of("/\\");
    if (s == std::string::npos) return ".";
    if (s == 0) return "/";
    return path.substr(0, s);
}

std::string join_path(const std::string &dir, const std::string &rel)
{
    if (rel.empty() || rel[0] == '/' || (rel.size() > 1 && rel[1] == ':')) return rel;
    if (dir.empty() || dir == ".") return rel;
    if (dir.back() == '/') return dir + rel;
    return dir + "/" + rel;
}

std::string strip_quotes(std::string s)
{
    s = trim(std::move(s));
    if (s.size() >= 2 && ((s.front() == '"' && s.back() == '"') ||
                          (s.front() == '\'' && s.back() == '\'')))
        s = s.substr(1, s.size() - 2);
    return s;
}

std::string hex32(uint32_t v)
{
    std::ostringstream o;
    o << std::hex << std::uppercase << v;
    return o.str();
}

bool parse_num(const std::string &text, uint32_t &out)
{
    std::string s = trim(text);
    if (s.empty()) return false;
    int base = 10;
    size_t i = 0;
    if (s[0] == '$') {
        base = 16;
        i = 1;
    } else if (s.size() > 2 && s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) {
        base = 16;
        i = 2;
    } else if (s[0] == '%') {
        base = 2;
        i = 1;
    }
    if (i >= s.size()) return false;
    uint32_t v = 0;
    for (; i < s.size(); i++) {
        unsigned char c = static_cast<unsigned char>(s[i]);
        if (c == '_') continue;
        int d;
        if (c >= '0' && c <= '9') d = c - '0';
        else if (c >= 'a' && c <= 'f') d = c - 'a' + 10;
        else if (c >= 'A' && c <= 'F') d = c - 'A' + 10;
        else return false;
        if (d >= base) return false;
        v = v * static_cast<uint32_t>(base) + static_cast<uint32_t>(d);
    }
    out = v;
    return true;
}

struct Piece {
    std::vector<uint8_t> image;
    uint16_t kind = 0;
    struct Sym {
        std::string name;
        uint32_t off = 0;
        bool global = true;
    };
    struct Fix {
        uint32_t at = 0;
        uint8_t width = 2;
        std::string symbol;
        int32_t addend = 0;
        int32_t divisor = 1;
    };
    std::vector<Sym> syms;
    std::vector<Fix> fixes;
};

struct OutSeg {
    std::string name;
    uint16_t kind = 0;
    bool kind_set = false;
    uint32_t align = 0;
    uint32_t org = 0;
    bool org_set = false;
    bool dynamic = false;
    uint32_t entry = 0;
    std::vector<Piece> pieces;
    std::vector<uint8_t> image;
    std::vector<Piece::Sym> syms;
    std::vector<Piece::Fix> fixes;
    std::vector<OmfReloc> relocs;
};

struct Target {
    std::string script;
    int line = 0;
    std::string name;
    std::vector<std::string> deps;
    int ver = 2;
    uint32_t typ = 0;
    uint32_t aux = 0;
    bool typ_set = false;
    std::string entry;
    std::vector<std::string> libs;
    uint32_t org = 0;
    bool org_set = false;
    bool any_seg = false;
    std::vector<OutSeg> segs;
};

struct Act {
    enum Type { Ver, Typ, Org, Entry, Lib, Seg, Plus, Ds } type = Ver;
    std::string script;
    int line = 0;
    std::string text;
    std::string text2;
    uint32_t n = 0;
    uint32_t n2 = 0;
    uint16_t kind = 0;
    bool kind_set = false;
    bool dynamic = false;
};

bool read_bin(const std::string &path, std::vector<uint8_t> &buf, std::string &err)
{
    std::ifstream in(path, std::ios::binary);
    if (!in) {
        err = "cannot read " + path;
        return false;
    }
    buf.assign(std::istreambuf_iterator<char>(in), std::istreambuf_iterator<char>());
    return true;
}

bool write_bin(const std::string &path, const std::vector<uint8_t> &buf, std::string &err)
{
    std::ofstream out(path, std::ios::binary);
    if (!out) {
        err = "cannot write " + path;
        return false;
    }
    if (!buf.empty())
        out.write(reinterpret_cast<const char *>(buf.data()),
                  static_cast<std::streamsize>(buf.size()));
    if (!out) {
        err = "cannot write " + path;
        return false;
    }
    return true;
}

void add_err(LinkOutput &o, const std::string &script, int line, const std::string &msg)
{
    if (line > 0)
        o.errors.push_back(script + ":" + std::to_string(line) + ": " + msg);
    else
        o.errors.push_back(msg);
}

std::string expand(const std::string &in, const std::map<std::string, std::string> &vars,
                   std::string &err)
{
    std::string o;
    for (size_t i = 0; i < in.size();) {
        if (in[i] == '$' && i + 1 < in.size() && in[i + 1] == '(') {
            auto e = in.find(')', i + 2);
            if (e == std::string::npos) {
                err = "unclosed $(...)";
                return {};
            }
            std::string name = in.substr(i + 2, e - (i + 2));
            auto it = vars.find(name);
            if (it == vars.end()) {
                err = "unknown variable " + name;
                return {};
            }
            o += it->second;
            i = e + 1;
        } else {
            o.push_back(in[i++]);
        }
    }
    return o;
}

bool is_ident_char(char c, bool first)
{
    unsigned char u = static_cast<unsigned char>(c);
    if (first) return std::isalpha(u) || c == '_';
    return std::isalnum(u) || c == '_';
}

Piece piece_from(const OmfSeg &seg)
{
    Piece p;
    p.image = seg.image;
    p.kind = seg.kind;
    for (const auto &s : seg.syms) {
        Piece::Sym sym;
        sym.name = s.name;
        sym.off = s.offset;
        sym.global = s.global;
        p.syms.push_back(sym);
    }
    for (const auto &f : seg.fixups) {
        Piece::Fix fx;
        fx.at = f.at;
        fx.width = f.width;
        fx.symbol = f.symbol;
        fx.addend = f.addend;
        fx.divisor = f.divisor;
        p.fixes.push_back(fx);
    }
    return p;
}

bool load_file(const std::string &path, OmfFile &file, std::string &err)
{
    std::vector<uint8_t> buf;
    if (!read_bin(path, buf, err)) return false;
    if (!omf_read(buf, file, err)) {
        err = path + ": " + err;
        return false;
    }
    return true;
}

void layout_seg(OutSeg &s)
{
    s.image.clear();
    s.syms.clear();
    s.fixes.clear();
    for (const auto &p : s.pieces) {
        uint32_t base = static_cast<uint32_t>(s.image.size());
        s.image.insert(s.image.end(), p.image.begin(), p.image.end());
        for (auto sym : p.syms) {
            sym.off += base;
            s.syms.push_back(sym);
        }
        for (auto fx : p.fixes) {
            fx.at += base;
            s.fixes.push_back(fx);
        }
    }
}

struct Hit {
    int seg = -1;
    uint32_t off = 0;
};

bool lookup_sym(const std::vector<OutSeg> &segs, const std::string &name, int prefer, Hit &hit,
                bool &dup)
{
    dup = false;
    int found = 0;
    Hit g;
    for (int si = 0; si < static_cast<int>(segs.size()); si++) {
        for (const auto &s : segs[si].syms) {
            if (!s.global || !ieq(s.name, name)) continue;
            if (found && (g.seg != si || g.off != s.off)) {
                dup = true;
                return false;
            }
            g.seg = si;
            g.off = s.off;
            found++;
        }
    }
    if (found) {
        hit = g;
        return true;
    }
    if (prefer >= 0 && prefer < static_cast<int>(segs.size())) {
        for (const auto &s : segs[prefer].syms) {
            if (s.global || !ieq(s.name, name)) continue;
            hit.seg = prefer;
            hit.off = s.off;
            return true;
        }
    }
    return false;
}

bool store_le(std::vector<uint8_t> &image, uint32_t at, int width, uint32_t v, std::string &err)
{
    if (width < 1 || at + static_cast<uint32_t>(width) > image.size()) {
        err = "fixup lands outside the segment";
        return false;
    }
    for (int i = 0; i < width; i++)
        image[at + static_cast<uint32_t>(i)] = static_cast<uint8_t>((v >> (8 * i)) & 0xFF);
    return true;
}

bool resolve_load(std::vector<OutSeg> &segs, std::string &err)
{
    for (int si = 0; si < static_cast<int>(segs.size()); si++) {
        OutSeg &seg = segs[si];
        seg.relocs.clear();
        for (const auto &fx : seg.fixes) {
            Hit hit;
            bool dup = false;
            if (!lookup_sym(segs, fx.symbol, si, hit, dup)) {
                if (dup) err = "duplicate symbol " + fx.symbol;
                else err = "undefined symbol " + fx.symbol;
                return false;
            }
            bool abs = seg.org_set;
            if (abs != segs[hit.seg].org_set) {
                err = "absolute and relocatable segments are mixed";
                return false;
            }
            int64_t disp = static_cast<int64_t>(hit.off) + fx.addend;
            if (abs) {
                int64_t addr = static_cast<int64_t>(segs[hit.seg].org) + disp;
                if (fx.divisor != 1) addr /= fx.divisor;
                if (!store_le(seg.image, fx.at, fx.width, static_cast<uint32_t>(addr), err))
                    return false;
            } else {
                if (fx.divisor != 1) {
                    err = "a byte selector on a relocatable link is not supported";
                    return false;
                }
                if (disp < 0) {
                    err = "relocation displacement is negative";
                    return false;
                }
                if (!store_le(seg.image, fx.at, fx.width, static_cast<uint32_t>(disp), err))
                    return false;
                OmfReloc r;
                r.at = fx.at;
                r.width = fx.width;
                r.disp = static_cast<uint32_t>(disp);
                if (hit.seg == si) {
                    r.file = 0;
                } else {
                    r.file = 1;
                    r.seg = static_cast<uint16_t>(hit.seg + 1);
                }
                seg.relocs.push_back(r);
            }
        }
    }
    return true;
}

std::set<std::string> undefined_names(const std::vector<OutSeg> &segs)
{
    std::set<std::string> u;
    for (int si = 0; si < static_cast<int>(segs.size()); si++) {
        for (const auto &fx : segs[si].fixes) {
            Hit hit;
            bool dup = false;
            if (!lookup_sym(segs, fx.symbol, si, hit, dup))
                u.insert(upper(fx.symbol));
        }
    }
    return u;
}

void assign_orgs(Target &t)
{
    bool abs = t.org_set;
    for (const auto &s : t.segs)
        if (s.org_set) abs = true;
    uint32_t cursor = t.org_set ? t.org : 0;
    for (auto &s : t.segs) {
        if (!abs) continue;
        if (!s.org_set) {
            s.org = cursor;
            s.org_set = true;
        }
        if (s.align > 1) {
            uint32_t r = s.org % s.align;
            if (r) s.org += s.align - r;
        }
        cursor = s.org + static_cast<uint32_t>(s.image.size());
    }
}

bool apply_entry(Target &t, std::string &err)
{
    if (t.entry.empty()) return true;
    for (auto &s : t.segs) {
        for (const auto &sym : s.syms) {
            if (!sym.global || !ieq(sym.name, t.entry)) continue;
            s.entry = sym.off;
            return true;
        }
    }
    err = "entry " + t.entry + " was not found";
    return false;
}

Piece zeros(uint32_t n)
{
    Piece p;
    p.image.assign(n, 0);
    return p;
}

OutSeg *named_seg(std::vector<OutSeg> &segs, const std::string &name)
{
    for (auto &s : segs)
        if (ieq(s.name, name)) return &s;
    return nullptr;
}

bool place_piece(std::vector<OutSeg> &segs, const std::string &seg_name, Piece piece, bool merge,
                 std::string &err)
{
    if (piece.image.empty() && piece.syms.empty() && piece.fixes.empty()) return true;
    if (!merge) {
        if (segs.empty()) {
            err = "input is outside a segment";
            return false;
        }
        segs.back().pieces.push_back(std::move(piece));
        return true;
    }
    OutSeg *dst = named_seg(segs, seg_name);
    if (!dst) {
        OutSeg s;
        s.name = seg_name.empty() ? "CODE" : seg_name;
        s.kind = piece.kind;
        s.kind_set = true;
        segs.push_back(std::move(s));
        dst = &segs.back();
    }
    dst->pieces.push_back(std::move(piece));
    return true;
}

bool place_file(std::vector<OutSeg> &segs, const OmfFile &file, const std::string &only,
                bool merge, const std::string &into, std::string &err)
{
    if (!file.object && !only.empty()) {
        err = "a load file has no named segment to select";
        return false;
    }
    bool any = false;
    for (const auto &seg : file.segs) {
        if (!only.empty() && !ieq(seg.name, only)) continue;
        if (!file.object && !seg.relocs.empty()) {
            err = "load file still has relocations";
            return false;
        }
        any = true;
        Piece p = piece_from(seg);
        std::string dest = merge ? seg.name : into;
        if (!place_piece(segs, dest, std::move(p), merge, err)) return false;
    }
    if (!any) {
        err = only.empty() ? "object has no segments" : "segment " + only + " was not found";
        return false;
    }
    return true;
}

bool finish_target(Target &t, const std::string &dir, LinkOutput &o, std::ostream &log)
{
    for (auto &s : t.segs) {
        if (s.dynamic) s.kind = static_cast<uint16_t>(s.kind | 0x8000);
        if (t.ver == 1 && s.dynamic) {
            add_err(o, t.script, t.line, "ver 1 cannot store a dynamic segment");
            return false;
        }
        if (t.ver == 1 && (s.kind & 0x1F00)) {
            add_err(o, t.script, t.line, "ver 1 cannot store kind $" + hex32(s.kind));
            return false;
        }
        layout_seg(s);
    }

    bool library = t.typ_set && (t.typ == 0xB1 || t.typ == 0xB2);
    if (!library) {
        std::set<std::string> pulled;
        bool progressed = true;
        int guard = 0;
        while (progressed) {
            progressed = false;
            if (++guard > 1000) {
                add_err(o, t.script, t.line, "library search did not finish");
                return false;
            }
            auto undef = undefined_names(t.segs);
            if (undef.empty()) break;
            for (const auto &lib : t.libs) {
                std::string path = join_path(dir, lib);
                OmfFile lf;
                std::string err;
                if (!load_file(path, lf, err)) {
                    add_err(o, t.script, t.line, err);
                    return false;
                }
                if (!lf.object) {
                    add_err(o, t.script, t.line, path + " is not an object library");
                    return false;
                }
                for (size_t si = 0; si < lf.segs.size(); si++) {
                    std::string key = path + "#" + std::to_string(si);
                    if (pulled.count(key)) continue;
                    bool need = false;
                    for (const auto &sym : lf.segs[si].syms) {
                        if (sym.global && undef.count(upper(sym.name))) need = true;
                    }
                    if (!need) continue;
                    Piece p = piece_from(lf.segs[si]);
                    std::string err2;
                    if (!place_piece(t.segs, lf.segs[si].name, std::move(p), true, err2)) {
                        add_err(o, t.script, t.line, err2);
                        return false;
                    }
                    pulled.insert(key);
                    progressed = true;
                    for (auto &seg : t.segs) layout_seg(seg);
                }
            }
            if (!progressed && !undef.empty()) {
                add_err(o, t.script, t.line, "undefined symbol " + *undef.begin());
                return false;
            }
        }
        assign_orgs(t);
        /* Orgs can move a segment that was already laid out. Layout does not
           depend on org, so the images stay valid. */
        std::string err;
        if (!resolve_load(t.segs, err) || !apply_entry(t, err)) {
            add_err(o, t.script, t.line, err);
            return false;
        }
    } else {
        assign_orgs(t);
        std::string err;
        if (!apply_entry(t, err)) {
            add_err(o, t.script, t.line, err);
            return false;
        }
    }

    if (t.segs.empty()) {
        add_err(o, t.script, t.line, "target has nothing to link");
        return false;
    }

    OmfFile out;
    out.version = t.ver;
    out.object = library;
    for (const auto &s : t.segs) {
        OmfSeg seg;
        seg.name = s.name.empty() ? "CODE" : s.name;
        seg.kind = s.kind;
        seg.org = s.org_set ? s.org : 0;
        seg.align = s.align;
        seg.entry = s.entry;
        seg.image = s.image;
        if (library) {
            for (const auto &sym : s.syms) {
                OmfSym os;
                os.name = sym.name;
                os.offset = sym.off;
                os.global = sym.global;
                seg.syms.push_back(os);
            }
            for (const auto &fx : s.fixes) {
                OmfFix of;
                of.at = fx.at;
                of.width = fx.width;
                of.symbol = fx.symbol;
                of.addend = fx.addend;
                of.divisor = fx.divisor;
                seg.fixups.push_back(of);
            }
        } else {
            seg.relocs = s.relocs;
        }
        out.segs.push_back(std::move(seg));
    }

    std::vector<uint8_t> bytes;
    std::string err;
    if (!omf_write(out, bytes, err)) {
        add_err(o, t.script, t.line, err);
        return false;
    }
    std::string path = join_path(dir, t.name);
    if (!write_bin(path, bytes, err)) {
        add_err(o, t.script, t.line, err);
        return false;
    }
    OmfFile check;
    if (!omf_read(bytes, check, err)) {
        add_err(o, t.script, t.line, "wrote " + path + " but could not read it back: " + err);
        return false;
    }
    LinkProduct prod;
    prod.path = path;
    prod.typ = t.typ;
    prod.aux = t.aux;
    prod.typ_set = t.typ_set;
    prod.file = std::move(check);
    /* The reader classifies a symbol-bearing file as an object. Keep the
       version and org from what we wrote; the image is what was read back. */
    prod.file.version = t.ver;
    prod.file.object = library;
    for (size_t i = 0; i < prod.file.segs.size() && i < out.segs.size(); i++) {
        prod.file.segs[i].org = out.segs[i].org;
        prod.file.segs[i].kind = out.segs[i].kind;
        prod.file.segs[i].entry = out.segs[i].entry;
        prod.file.segs[i].align = out.segs[i].align;
    }

    log << path << ": OMF " << t.ver << ".0 " << (library ? "object" : "load");
    for (const auto &s : out.segs) {
        log << " " << s.name << " " << s.image.size() << " bytes";
        if (s.org) log << " org $" << hex32(s.org);
    }
    if (t.typ_set) log << " typ $" << hex32(t.typ) << " aux $" << hex32(t.aux);
    log << "\n";
    if (!library && t.ver == 1 && t.typ_set && t.typ == 0x06) {
        log << path
            << ": ProDOS BLOAD reads a raw image. This file is an OMF segment; "
               "the aux type is the load address and the image bytes are the "
               "LCONST payload.\n";
    }
    o.products.push_back(std::move(prod));
    return true;
}

struct Script {
    std::string dir;
    std::map<std::string, std::string> vars;
    struct RawTarget {
        std::string script;
        int line = 0;
        std::string name;
        std::vector<std::string> deps;
        std::vector<Act> acts;
    };
    std::vector<RawTarget> targets;
};

bool parse_script(const std::string &path, Script &sc, LinkOutput &o,
                  std::vector<std::string> &stack, int depth)
{
    if (depth > 16) {
        add_err(o, path, 0, "include nest too deep");
        return false;
    }
    for (const auto &s : stack) {
        if (s == path) {
            add_err(o, path, 0, "include cycle");
            return false;
        }
    }
    stack.push_back(path);
    std::ifstream in(path);
    if (!in) {
        add_err(o, path, 0, "cannot read script");
        stack.pop_back();
        return false;
    }
    std::string dir = dirname_of(path);
    int lineno = 0;
    std::string line;
    int cur_i = -1;
    while (std::getline(in, line)) {
        lineno++;
        auto hash = line.find('#');
        if (hash != std::string::npos) line = line.substr(0, hash);
        if (!line.empty() && line.back() == '\r') line.pop_back();
        if (trim(line).empty()) continue;
        bool body = line[0] == ' ' || line[0] == '\t';
        std::string err;
        std::string text = expand(trim(line), sc.vars, err);
        if (!err.empty()) {
            add_err(o, path, lineno, err);
            stack.pop_back();
            return false;
        }
        if (!body) {
            std::string word;
            size_t sp = 0;
            while (sp < text.size() && text[sp] != ' ' && text[sp] != '\t') sp++;
            word = text.substr(0, sp);
            if (ieq(word, "include")) {
                std::string inc = strip_quotes(trim(text.substr(sp)));
                if (inc.empty()) {
                    add_err(o, path, lineno, "include needs a file");
                    stack.pop_back();
                    return false;
                }
                if (!parse_script(join_path(dir, inc), sc, o, stack, depth + 1)) {
                    stack.pop_back();
                    return false;
                }
                continue;
            }
            auto eq = text.find('=');
            auto colon = text.find(':');
            bool assign = eq != std::string::npos && (colon == std::string::npos || eq < colon);
            if (assign) {
                std::string name = trim(text.substr(0, eq));
                std::string value = trim(text.substr(eq + 1));
                if (name.empty() || !is_ident_char(name[0], true)) {
                    add_err(o, path, lineno, "bad variable name");
                    stack.pop_back();
                    return false;
                }
                for (char c : name) {
                    if (!is_ident_char(c, false) && c != name[0]) {
                        /* checked below */
                    }
                }
                for (size_t i = 0; i < name.size(); i++) {
                    if (!is_ident_char(name[i], i == 0)) {
                        add_err(o, path, lineno, "bad variable name");
                        stack.pop_back();
                        return false;
                    }
                }
                sc.vars[name] = value;
                continue;
            }
            if (colon == std::string::npos) {
                add_err(o, path, lineno, "expected a target, include, or assignment");
                stack.pop_back();
                return false;
            }
            Script::RawTarget t;
            t.script = path;
            t.line = lineno;
            t.name = strip_quotes(trim(text.substr(0, colon)));
            std::string deps = trim(text.substr(colon + 1));
            std::istringstream ds(deps);
            std::string dep;
            while (ds >> dep) t.deps.push_back(strip_quotes(dep));
            if (t.name.empty()) {
                add_err(o, path, lineno, "target needs a name");
                stack.pop_back();
                return false;
            }
            sc.targets.push_back(std::move(t));
            cur_i = static_cast<int>(sc.targets.size()) - 1;
            continue;
        }
        if (cur_i < 0) {
            add_err(o, path, lineno, "command is outside a target");
            stack.pop_back();
            return false;
        }
        std::istringstream ls(text);
        std::string cmd;
        ls >> cmd;
        Act act;
        act.script = path;
        act.line = lineno;
        std::string rest;
        std::getline(ls, rest);
        rest = trim(rest);
        if (ieq(cmd, "end")) continue;
        if (ieq(cmd, "ver")) {
            uint32_t v = 0;
            if (!parse_num(rest, v) || (v != 1 && v != 2)) {
                add_err(o, path, lineno, "ver must be 1 or 2");
                stack.pop_back();
                return false;
            }
            act.type = Act::Ver;
            act.n = v;
        } else if (ieq(cmd, "typ")) {
            auto comma = rest.find(',');
            std::string a = comma == std::string::npos ? rest : rest.substr(0, comma);
            std::string b = comma == std::string::npos ? std::string() : rest.substr(comma + 1);
            uint32_t typ = 0, aux = 0;
            if (!parse_num(a, typ) || (comma != std::string::npos && !parse_num(b, aux))) {
                add_err(o, path, lineno, "typ needs a type and an optional aux");
                stack.pop_back();
                return false;
            }
            act.type = Act::Typ;
            act.n = typ;
            act.n2 = aux;
        } else if (ieq(cmd, "org")) {
            uint32_t n = 0;
            if (!parse_num(rest, n)) {
                add_err(o, path, lineno, "org needs an address");
                stack.pop_back();
                return false;
            }
            act.type = Act::Org;
            act.n = n;
        } else if (ieq(cmd, "entry")) {
            if (rest.empty()) {
                add_err(o, path, lineno, "entry needs a label");
                stack.pop_back();
                return false;
            }
            act.type = Act::Entry;
            act.text = rest;
        } else if (ieq(cmd, "lib")) {
            std::string f = strip_quotes(rest);
            if (f.empty()) {
                add_err(o, path, lineno, "lib needs a file");
                stack.pop_back();
                return false;
            }
            act.type = Act::Lib;
            act.text = f;
        } else if (ieq(cmd, "ds")) {
            uint32_t n = 0;
            if (!parse_num(rest, n)) {
                add_err(o, path, lineno, "ds needs a count");
                stack.pop_back();
                return false;
            }
            act.type = Act::Ds;
            act.n = n;
        } else if (ieq(cmd, "seg")) {
            std::istringstream ss(rest);
            std::string name;
            ss >> name;
            if (name.empty()) {
                add_err(o, path, lineno, "seg needs a name");
                stack.pop_back();
                return false;
            }
            act.type = Act::Seg;
            act.text = name;
            std::string tok;
            while (ss >> tok) {
                if (ieq(tok, "dynamic")) {
                    act.dynamic = true;
                    continue;
                }
                auto eq = tok.find('=');
                if (eq == std::string::npos) {
                    add_err(o, path, lineno, "bad segment attribute " + tok);
                    stack.pop_back();
                    return false;
                }
                std::string key = tok.substr(0, eq);
                std::string val = tok.substr(eq + 1);
                uint32_t n = 0;
                if (!parse_num(val, n)) {
                    add_err(o, path, lineno, "bad segment attribute " + tok);
                    stack.pop_back();
                    return false;
                }
                if (ieq(key, "kind")) {
                    act.kind = static_cast<uint16_t>(n);
                    act.kind_set = true;
                } else if (ieq(key, "align")) {
                    act.n = n;
                } else if (ieq(key, "org")) {
                    act.n2 = n;
                    act.kind_set = act.kind_set; /* org flagged below */
                    act.text2 = "org";
                    act.n2 = n;
                } else {
                    add_err(o, path, lineno, "unknown segment attribute " + key);
                    stack.pop_back();
                    return false;
                }
            }
        } else if (!cmd.empty() && cmd[0] == '+') {
            std::string spec = cmd.substr(1);
            if (spec.empty()) spec = rest;
            else if (!rest.empty()) spec += rest;
            spec = strip_quotes(spec);
            std::string seg;
            auto lp = spec.find('(');
            if (lp != std::string::npos) {
                if (spec.empty() || spec.back() != ')') {
                    add_err(o, path, lineno, "expected +file(SEGMENT)");
                    stack.pop_back();
                    return false;
                }
                seg = spec.substr(lp + 1, spec.size() - lp - 2);
                spec = spec.substr(0, lp);
            }
            if (spec.empty()) {
                add_err(o, path, lineno, "+ needs a file");
                stack.pop_back();
                return false;
            }
            act.type = Act::Plus;
            act.text = spec;
            act.text2 = trim(seg);
        } else {
            add_err(o, path, lineno, "unknown command " + cmd);
            stack.pop_back();
            return false;
        }
        sc.targets[static_cast<size_t>(cur_i)].acts.push_back(std::move(act));
    }
    stack.pop_back();
    return true;
}

bool build_target(const Script::RawTarget &raw, const std::string &dir, Target &t, LinkOutput &o)
{
    t.script = raw.script;
    t.line = raw.line;
    t.name = raw.name;
    t.deps = raw.deps;
    bool any_plus = false;
    int cur = -1;
    bool explicit_seg = false;
    for (const auto &act : raw.acts) {
        if (act.type == Act::Seg) explicit_seg = true;
        if (act.type == Act::Plus || act.type == Act::Ds) any_plus = true;
    }
    bool merge = !explicit_seg && ![&]() {
        for (const auto &act : raw.acts)
            if (act.type == Act::Org) return true;
        return false;
    }();
    /* Absolute, no seg commands: one contiguous segment. */
    bool one = !explicit_seg && !merge;

    auto ensure = [&](const Act &act) -> OutSeg * {
        if (explicit_seg) {
            if (cur < 0) {
                add_err(o, act.script, act.line, "input is outside a segment");
                return nullptr;
            }
            return &t.segs[cur];
        }
        if (one) {
            if (t.segs.empty()) {
                OutSeg s;
                s.name = "CODE";
                if (t.org_set) {
                    s.org = t.org;
                    s.org_set = true;
                }
                t.segs.push_back(std::move(s));
            }
            return &t.segs.back();
        }
        return nullptr; /* merge decides per file */
    };

    for (const auto &act : raw.acts) {
        if (act.type == Act::Ver) {
            t.ver = static_cast<int>(act.n);
        } else if (act.type == Act::Typ) {
            t.typ = act.n;
            t.aux = act.n2;
            t.typ_set = true;
        } else if (act.type == Act::Entry) {
            t.entry = act.text;
        } else if (act.type == Act::Lib) {
            t.libs.push_back(act.text);
        } else if (act.type == Act::Org) {
            if (explicit_seg && cur >= 0) {
                t.segs[cur].org = act.n;
                t.segs[cur].org_set = true;
            } else if (one && !t.segs.empty()) {
                OutSeg s;
                s.name = "CODE";
                s.org = act.n;
                s.org_set = true;
                t.segs.push_back(std::move(s));
                t.org = act.n;
                t.org_set = true;
            } else {
                t.org = act.n;
                t.org_set = true;
                if (one && !t.segs.empty()) {
                    t.segs.back().org = act.n;
                    t.segs.back().org_set = true;
                }
            }
        } else if (act.type == Act::Seg) {
            OutSeg s;
            s.name = act.text;
            s.dynamic = act.dynamic;
            if (act.kind_set) {
                s.kind = act.kind;
                s.kind_set = true;
            }
            s.align = act.n;
            if (act.text2 == "org") {
                s.org = act.n2;
                s.org_set = true;
            } else if (t.org_set) {
                /* Default load address. A later segment with no org of its
                   own is placed after this one by assign_orgs, so do not
                   copy the default onto every segment here. */
            }
            t.segs.push_back(std::move(s));
            cur = static_cast<int>(t.segs.size()) - 1;
            t.any_seg = true;
        } else if (act.type == Act::Ds) {
            if (merge) {
                if (t.segs.empty()) {
                    add_err(o, act.script, act.line, "ds is not inside a segment");
                    return false;
                }
                t.segs.back().pieces.push_back(zeros(act.n));
            } else {
                OutSeg *s = ensure(act);
                if (!s) return false;
                s->pieces.push_back(zeros(act.n));
            }
        } else if (act.type == Act::Plus) {
            std::string path = join_path(dir, act.text);
            OmfFile file;
            std::string err;
            if (!load_file(path, file, err)) {
                add_err(o, act.script, act.line, err);
                return false;
            }
            if (explicit_seg || one) {
                OutSeg *s = ensure(act);
                if (!s) return false;
                if (s->name == "CODE" && act.text2.empty() && !file.segs.empty() && one &&
                    t.segs.size() == 1 && s->pieces.empty()) {
                    /* Keep CODE unless the single absolute image has an entry
                       later. The first input's segment name is a better label
                       when the script did not name one. */
                    if (!file.segs[0].name.empty()) s->name = file.segs[0].name;
                }
                std::vector<OutSeg> tmp;
                /* place_file(merge=false) appends to the last seg. */
                tmp.push_back(OutSeg{});
                tmp.back().name = s->name;
                if (!place_file(tmp, file, act.text2, false, s->name, err)) {
                    add_err(o, act.script, act.line, err);
                    return false;
                }
                for (auto &p : tmp.back().pieces) s->pieces.push_back(std::move(p));
            } else {
                if (!place_file(t.segs, file, act.text2, true, {}, err)) {
                    add_err(o, act.script, act.line, err);
                    return false;
                }
            }
        }
    }

    if (!any_plus && !explicit_seg) {
        for (const auto &dep : t.deps) {
            bool is_lib = false;
            for (const auto &lib : t.libs)
                if (ieq(lib, dep)) is_lib = true;
            if (is_lib) continue;
            std::string path = join_path(dir, dep);
            OmfFile file;
            std::string err;
            if (!load_file(path, file, err)) {
                add_err(o, t.script, t.line, err);
                return false;
            }
            if (one || t.org_set) {
                if (t.segs.empty()) {
                    OutSeg s;
                    s.name = file.segs.empty() ? "CODE" : file.segs[0].name;
                    if (t.org_set) {
                        s.org = t.org;
                        s.org_set = true;
                    }
                    t.segs.push_back(std::move(s));
                }
                std::vector<OutSeg> tmp(1);
                if (!place_file(tmp, file, {}, false, t.segs.back().name, err)) {
                    add_err(o, t.script, t.line, err);
                    return false;
                }
                for (auto &p : tmp.back().pieces)
                    t.segs.back().pieces.push_back(std::move(p));
            } else if (!place_file(t.segs, file, {}, true, {}, err)) {
                add_err(o, t.script, t.line, err);
                return false;
            }
        }
    }
    return o.errors.empty();
}

} // namespace

LinkOutput link_script(const std::string &path, std::ostream &log)
{
    LinkOutput o;
    Script sc;
    sc.dir = dirname_of(path);
    std::vector<std::string> stack;
    if (!parse_script(path, sc, o, stack, 0)) return o;
    if (sc.targets.empty()) {
        add_err(o, path, 0, "script has no targets");
        return o;
    }
    for (const auto &raw : sc.targets) {
        Target t;
        if (!build_target(raw, sc.dir, t, o)) return o;
        if (!finish_target(t, sc.dir, o, log)) return o;
    }
    return o;
}

} // namespace qasm
