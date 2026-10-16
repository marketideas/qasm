/* Link the relocatable fixtures and check the OMF images. */

#include "link.hpp"
#include "omf.hpp"

#include <cstdint>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

namespace {

int fails = 0;

void fail(const std::string &msg)
{
    std::cerr << "FAIL " << msg << "\n";
    fails++;
}

bool ends_with(const std::string &s, const std::string &suf)
{
    return s.size() >= suf.size() && s.compare(s.size() - suf.size(), suf.size(), suf) == 0;
}

bool ieq(const std::string &a, const std::string &b)
{
    if (a.size() != b.size()) return false;
    for (size_t i = 0; i < a.size(); i++) {
        unsigned char x = static_cast<unsigned char>(a[i]);
        unsigned char y = static_cast<unsigned char>(b[i]);
        if (x >= 'a' && x <= 'z') x = static_cast<unsigned char>(x - 'a' + 'A');
        if (y >= 'a' && y <= 'z') y = static_cast<unsigned char>(y - 'a' + 'A');
        if (x != y) return false;
    }
    return true;
}

std::string hex_of(const std::vector<uint8_t> &b)
{
    static const char *d = "0123456789ABCDEF";
    std::string s;
    for (size_t i = 0; i < b.size(); i++) {
        if (i) s.push_back(' ');
        s.push_back(d[b[i] >> 4]);
        s.push_back(d[b[i] & 0xF]);
    }
    return s;
}

bool load_omf(const std::string &path, qasm::OmfFile &file)
{
    std::ifstream in(path, std::ios::binary);
    if (!in) {
        fail("cannot read " + path);
        return false;
    }
    std::vector<uint8_t> buf((std::istreambuf_iterator<char>(in)),
                             std::istreambuf_iterator<char>());
    std::string err;
    if (!qasm::omf_read(buf, file, err)) {
        fail(path + ": " + err);
        return false;
    }
    return true;
}

bool exists(const std::string &path)
{
    std::ifstream in(path);
    return static_cast<bool>(in);
}

const qasm::LinkProduct *find_prod(const qasm::LinkOutput &o, const std::string &suf)
{
    for (const auto &p : o.products)
        if (ends_with(p.path, suf)) return &p;
    return nullptr;
}

const qasm::OmfSeg *seg_named(const qasm::OmfFile &f, const std::string &name)
{
    for (const auto &s : f.segs)
        if (ieq(s.name, name)) return &s;
    return nullptr;
}

void expect_bytes(const std::string &what, const std::vector<uint8_t> &got,
                  const std::vector<uint8_t> &want)
{
    if (got != want) {
        fail(what + " bytes\n  got " + hex_of(got) + "\n  exp " + hex_of(want));
    }
}

bool has_global(const qasm::OmfSeg &s, const std::string &name, uint32_t off)
{
    for (const auto &sym : s.syms)
        if (sym.global && ieq(sym.name, name) && sym.offset == off) return true;
    return false;
}

bool has_fix(const qasm::OmfSeg &s, const std::string &name, uint32_t at, uint8_t width)
{
    for (const auto &f : s.fixups)
        if (ieq(f.symbol, name) && f.at == at && f.width == width && f.divisor == 1)
            return true;
    return false;
}

bool has_inter(const qasm::OmfSeg &s, uint32_t at, uint8_t width, uint32_t disp, uint16_t seg)
{
    for (const auto &r : s.relocs)
        if (r.file == 1 && r.seg == seg && r.at == at && r.width == width && r.disp == disp &&
            r.shift == 0)
            return true;
    return false;
}

const uint8_t k_apple[] = {
    0x20, 0x0A, 0x20, 0xAD, 0x09, 0x20, 0x09, 0x20, 0x6B, 0x42, 0x20, 0x00, 0x20,
    0xAD, 0x00, 0x20, 0x00, 0x20, 0x60
};
const uint8_t k_code_obj[] = {0x20, 0x00, 0x00, 0xAD, 0x00, 0x00, 0x00, 0x00, 0x6B};
const uint8_t k_data_obj[] = {0x42, 0x20, 0x00, 0x00, 0xAD, 0x00, 0x00, 0x00, 0x00, 0x60};
const uint8_t k_prog_code[] = {0x20, 0x01, 0x00, 0xAD, 0x00, 0x00, 0x00, 0x00, 0x6B};
const uint8_t k_gap_code[] = {0x20, 0x2A, 0x20, 0xAD, 0x29, 0x20, 0x29, 0x20, 0x6B};
const uint8_t k_gap_tail[] = {0x42, 0x20, 0x00, 0x20, 0xAD, 0x00, 0x20, 0x00, 0x20, 0x60};

std::vector<uint8_t> bytes_of(const uint8_t *p, size_t n)
{
    return std::vector<uint8_t>(p, p + n);
}

void check_object(const std::string &path, const std::string &seg, uint16_t kind,
                  const uint8_t *image, size_t nimage, const char *g1, uint32_t o1,
                  const char *g2, uint32_t o2)
{
    qasm::OmfFile f;
    if (!load_omf(path, f)) return;
    if (f.version != 2 || !f.object) fail(path + " is not an OMF 2.0 object");
    if (f.segs.size() != 1) {
        fail(path + " segment count");
        return;
    }
    const qasm::OmfSeg &s = f.segs[0];
    if (!ieq(s.name, seg)) fail(path + " segment name " + s.name + " want " + seg);
    if (s.kind != kind) fail(path + " kind");
    expect_bytes(path, s.image, bytes_of(image, nimage));
    if (!has_global(s, g1, o1)) fail(path + " missing " + g1);
    if (g2 && !has_global(s, g2, o2)) fail(path + " missing " + g2);
}

void check_apple(const qasm::LinkOutput &o, const std::string &suf)
{
    const qasm::LinkProduct *p = find_prod(o, suf);
    if (!p) {
        fail("missing " + suf);
        return;
    }
    if (p->file.version != 1 || p->file.object) fail(suf + " header");
    if (!p->typ_set || p->typ != 0x06 || p->aux != 0x2000) fail(suf + " typ/aux");
    if (p->file.segs.size() != 1) {
        fail(suf + " segment count");
        return;
    }
    const qasm::OmfSeg &s = p->file.segs[0];
    if (s.org != 0x2000) fail(suf + " org");
    if (s.entry != 0) fail(suf + " entry");
    if (!s.relocs.empty()) fail(suf + " has relocations");
    expect_bytes(suf, s.image, bytes_of(k_apple, sizeof(k_apple)));
}

void check_two(const qasm::LinkOutput &o, const std::string &suf, const std::string &data_name,
               bool reloc)
{
    const qasm::LinkProduct *p = find_prod(o, suf);
    if (!p) {
        fail("missing " + suf);
        return;
    }
    if (p->file.version != 2 || p->file.object) fail(suf + " is not an OMF 2.0 load file");
    if (p->file.segs.size() != 2) {
        fail(suf + " segment count");
        return;
    }
    const qasm::OmfSeg *code = seg_named(p->file, "CODE");
    const qasm::OmfSeg *data = seg_named(p->file, data_name);
    if (!code || !data) {
        fail(suf + " segment names");
        return;
    }
    if (code->org != 0 || data->org != 0) fail(suf + " org");
    expect_bytes(suf + " CODE", code->image, bytes_of(k_prog_code, sizeof(k_prog_code)));
    expect_bytes(suf + " DATA", data->image, bytes_of(k_data_obj, sizeof(k_data_obj)));
    if (!reloc) return;
    if (code->relocs.size() != 3 || data->relocs.size() != 3) fail(suf + " reloc count");
    if (!has_inter(*code, 1, 2, 1, 2) || !has_inter(*code, 4, 2, 0, 2) ||
        !has_inter(*code, 6, 2, 0, 2))
        fail(suf + " CODE interseg");
    if (!has_inter(*data, 2, 2, 0, 1) || !has_inter(*data, 5, 2, 0, 1) ||
        !has_inter(*data, 7, 2, 0, 1))
        fail(suf + " DATA interseg");
}

} // namespace

int main()
{
    const char *no_obj[] = {
        "test/fixtures/coverage-merlin.o",
        "test/fixtures/coverage-orca.o",
        "test/fixtures/coverage-ca65.o",
        "test/fixtures/coverage-apw.o",
        "test/fixtures/rel-code-lisa.o",
        "test/fixtures/rel-data-lisa.o",
    };
    for (const char *p : no_obj)
        if (exists(p)) fail(std::string(p) + " should not be written");

    check_object("test/fixtures/rel-code-merlin.o", "CODE", 0, k_code_obj, sizeof(k_code_obj),
                 "CODE", 0, nullptr, 0);
    check_object("test/fixtures/rel-data-merlin.o", "VALUE", 0, k_data_obj, sizeof(k_data_obj),
                 "VALUE", 0, "HOOK", 1);
    check_object("test/fixtures/rel-code-orca.o", "code", 0, k_code_obj, sizeof(k_code_obj),
                 "code", 0, nullptr, 0);
    /* `data start` is the START directive, so the segment is named data and
       its kind is code. A DATA directive would set kind 1. */
    check_object("test/fixtures/rel-data-orca.o", "data", 0, k_data_obj, sizeof(k_data_obj),
                 "value", 0, "hook", 1);
    check_object("test/fixtures/rel-code-ca65.o", "CODE", 0, k_code_obj, sizeof(k_code_obj),
                 "CODE", 0, nullptr, 0);
    check_object("test/fixtures/rel-data-ca65.o", "DATA", 0, k_data_obj, sizeof(k_data_obj),
                 "VALUE", 0, "HOOK", 1);
    check_object("test/fixtures/rel-code-apw.o", "code", 0, k_code_obj, sizeof(k_code_obj),
                 "code", 0, nullptr, 0);
    check_object("test/fixtures/rel-data-apw.o", "data", 0, k_data_obj, sizeof(k_data_obj),
                 "value", 0, "hook", 1);

    qasm::OmfFile code;
    if (load_omf("test/fixtures/rel-code-merlin.o", code) && !code.segs.empty()) {
        const qasm::OmfSeg &s = code.segs[0];
        if (!has_fix(s, "HOOK", 1, 2) || !has_fix(s, "VALUE", 4, 2) || !has_fix(s, "VALUE", 6, 2))
            fail("rel-code-merlin.o fixups");
        if (s.fixups.size() != 3) fail("rel-code-merlin.o fixup count");
    }
    qasm::OmfFile data;
    if (load_omf("test/fixtures/rel-data-merlin.o", data) && !data.segs.empty()) {
        const qasm::OmfSeg &s = data.segs[0];
        if (!has_fix(s, "CODE", 2, 2) || !has_fix(s, "CODE", 5, 2) || !has_fix(s, "CODE", 7, 2))
            fail("rel-data-merlin.o fixups");
    }

    std::ostringstream log;
    qasm::LinkOutput out = qasm::link_script("test/fixtures/disk.link", log);
    if (!out.ok()) {
        for (const auto &e : out.errors) fail(e);
    }
    std::cout << log.str();
    if (log.str().find("BLOAD") == std::string::npos)
        fail("ver 1 BIN summary should say ProDOS BLOAD does not read OMF");

    check_apple(out, "apple.omf");
    check_apple(out, "apple-orca.omf");
    check_apple(out, "apple-ca65.omf");
    check_apple(out, "apple-apw.omf");

    const qasm::LinkProduct *prog = find_prod(out, "prog.omf");
    if (!prog) fail("missing prog.omf");
    else {
        const qasm::OmfSeg *c = seg_named(prog->file, "CODE");
        const qasm::OmfSeg *d = seg_named(prog->file, "DATA");
        if (!c || c->kind != 0) fail("prog CODE kind");
        if (!d || d->kind != 1) fail("prog DATA kind");
        if (!c || c->entry != 0) fail("prog entry");
    }
    check_two(out, "prog.omf", "DATA", true);
    check_two(out, "merged.omf", "VALUE", true);
    check_two(out, "proglib.omf", "VALUE", true);

    const qasm::LinkProduct *lib = find_prod(out, "runtime.lib");
    if (!lib) fail("missing runtime.lib");
    else if (lib->file.version != 2 || !lib->file.object || lib->typ != 0xB2) {
        fail("runtime.lib is not an OMF 2.0 library");
    } else if (lib->file.segs.size() != 1) {
        fail("runtime.lib segment count");
    } else {
        const qasm::OmfSeg &s = lib->file.segs[0];
        if (!ieq(s.name, "VALUE")) fail("runtime.lib segment name");
        expect_bytes("runtime.lib", s.image, bytes_of(k_data_obj, sizeof(k_data_obj)));
        if (!has_global(s, "VALUE", 0) || !has_global(s, "HOOK", 1))
            fail("runtime.lib globals");
        if (!has_fix(s, "CODE", 2, 2)) fail("runtime.lib kept RELEXPR");
        if (!s.relocs.empty()) fail("runtime.lib has load relocations");
    }

    const qasm::LinkProduct *gap = find_prod(out, "gap.omf");
    if (!gap) fail("missing gap.omf");
    else if (gap->file.version != 1 || gap->file.segs.size() != 2) {
        fail("gap.omf shape");
    } else {
        const qasm::OmfSeg *c = seg_named(gap->file, "CODE");
        const qasm::OmfSeg *d = seg_named(gap->file, "DATA");
        if (!c || !d) fail("gap.omf names");
        else {
            if (c->org != 0x2000) fail("gap CODE org");
            if (d->org != 0x2009) fail("gap DATA org");
            expect_bytes("gap CODE", c->image, bytes_of(k_gap_code, sizeof(k_gap_code)));
            std::vector<uint8_t> data_img(32, 0);
            data_img.insert(data_img.end(), k_gap_tail, k_gap_tail + sizeof(k_gap_tail));
            expect_bytes("gap DATA", d->image, data_img);
            if (!c->relocs.empty() || !d->relocs.empty()) fail("gap has relocations");
        }
    }

    std::ostringstream blog;
    qasm::LinkOutput bad = qasm::link_script("test/fixtures/bad-dynamic.link", blog);
    if (bad.ok()) fail("ver 1 dynamic was accepted");
    else {
        bool saw = false;
        for (const auto &e : bad.errors)
            if (e.find("dynamic") != std::string::npos) saw = true;
        if (!saw) {
            fail("ver 1 dynamic error did not mention dynamic");
            for (const auto &e : bad.errors) std::cerr << e << "\n";
        }
    }
    if (exists("test/fixtures/bad.omf")) fail("bad.omf was written");

    if (fails) {
        std::cerr << fails << " linker check" << (fails == 1 ? "" : "s") << " failed\n";
        return 1;
    }
    std::cout << "qlink tests passed\n";
    return 0;
}
