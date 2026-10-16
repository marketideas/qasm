/* Flatten OMF load files the way MakeBinIIGS does. */

#include "link.hpp"
#include "makebin.hpp"
#include "omf.hpp"

#include <cstdint>
#include <cstdlib>
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

std::vector<uint8_t> bytes_of(const uint8_t *p, size_t n)
{
    return std::vector<uint8_t>(p, p + n);
}

void expect_bytes(const std::string &what, const std::vector<uint8_t> &got,
                  const std::vector<uint8_t> &want)
{
    if (got == want) return;
    std::ostringstream o;
    o << what << " len " << got.size() << " want " << want.size();
    fail(o.str());
}

qasm::OmfSeg seg(const std::string &name, uint32_t org, const std::vector<uint8_t> &image)
{
    qasm::OmfSeg s;
    s.name = name;
    s.org = org;
    s.image = image;
    return s;
}

void expect_ok(const char *what, const qasm::OmfFile &file, bool org_set, uint32_t org,
               uint32_t want_org, const std::vector<uint8_t> &want)
{
    qasm::BinImage image;
    std::string err;
    if (!qasm::make_bin(file, org_set, org, image, err)) {
        fail(std::string(what) + ": " + err);
        return;
    }
    if (image.org != want_org) {
        std::ostringstream o;
        o << what << " org $" << std::hex << image.org << " want $" << want_org;
        fail(o.str());
    }
    expect_bytes(what, image.bytes, want);
}

void expect_err(const char *what, const qasm::OmfFile &file, bool org_set, uint32_t org,
                const std::string &piece)
{
    qasm::BinImage image;
    std::string err;
    if (qasm::make_bin(file, org_set, org, image, err)) {
        fail(std::string(what) + " was accepted");
        return;
    }
    if (err.find(piece) == std::string::npos) fail(std::string(what) + ": " + err);
}

const qasm::LinkProduct *find_prod(const qasm::LinkOutput &o, const std::string &suf)
{
    for (const auto &p : o.products)
        if (p.path.size() >= suf.size() &&
            p.path.compare(p.path.size() - suf.size(), suf.size(), suf) == 0)
            return &p;
    return nullptr;
}

} // namespace

int main()
{
    uint32_t addr = 0;
    std::string err;
    if (!qasm::parse_address("$2000", addr, err) || addr != 0x2000) fail("parse $2000");
    if (!qasm::parse_address("0x2000", addr, err) || addr != 0x2000) fail("parse 0x2000");
    if (!qasm::parse_address("9A00", addr, err) || addr != 0x9A00) fail("parse 9A00");
    if (qasm::parse_address("$", addr, err)) fail("empty $ was accepted");
    if (qasm::parse_address("12G", addr, err)) fail("bad digit was accepted");

    const uint8_t apple[] = {0x20, 0x0A, 0x20, 0xAD, 0x09, 0x20, 0x09, 0x20, 0x6B,
                             0x42, 0x20, 0x00, 0x20, 0xAD, 0x00, 0x20, 0x00, 0x20, 0x60};
    qasm::OmfFile one;
    one.segs.push_back(seg("CODE", 0x2000, bytes_of(apple, sizeof(apple))));
    expect_ok("one segment", one, false, 0, 0x2000, bytes_of(apple, sizeof(apple)));
    expect_ok("explicit org", one, true, 0x2000, 0x2000, bytes_of(apple, sizeof(apple)));

    std::vector<uint8_t> padded(16, 0);
    padded.insert(padded.end(), apple, apple + sizeof(apple));
    expect_ok("lower org", one, true, 0x1FF0, 0x1FF0, padded);
    expect_err("org inside", one, true, 0x2001, "before org");

    qasm::OmfFile gap;
    gap.segs.push_back(seg("CODE", 0x2000, {0xEA, 0xEA}));
    gap.segs.push_back(seg("DATA", 0x2004, {0x60}));
    expect_ok("gap", gap, false, 0, 0x2000, {0xEA, 0xEA, 0x00, 0x00, 0x60});

    qasm::OmfFile over = gap;
    over.segs[1].org = 0x2001;
    expect_err("overlap", over, false, 0, "overlaps");

    qasm::OmfFile obj = one;
    obj.object = true;
    expect_err("object", obj, false, 0, "object");

    qasm::OmfFile rel = one;
    rel.segs[0].relocs.push_back({});
    expect_err("reloc", rel, false, 0, "relocations");

    qasm::OmfFile empty;
    expect_err("no segs", empty, false, 0, "no segments");

    std::ostringstream log;
    qasm::LinkOutput linked = qasm::link_script("test/fixtures/disk.link", log);
    if (!linked.ok()) {
        for (const auto &e : linked.errors) fail(e);
    } else {
        const qasm::LinkProduct *apple_omf = find_prod(linked, "apple.omf");
        if (!apple_omf) fail("missing apple.omf");
        else
            expect_ok("apple.omf", apple_omf->file, true, 0x2000, 0x2000,
                      bytes_of(apple, sizeof(apple)));

        const qasm::LinkProduct *gap_omf = find_prod(linked, "gap.omf");
        if (!gap_omf) fail("missing gap.omf");
        else {
            qasm::BinImage image;
            if (!qasm::make_bin(gap_omf->file, true, 0x2000, image, err))
                fail(std::string("gap.omf: ") + err);
            else if (image.org != 0x2000 || image.bytes.size() != 51)
                fail("gap.omf image size");
            else if (image.bytes[0] != 0x20 || image.bytes[9] != 0 || image.bytes[41] != 0x42 ||
                     image.bytes[50] != 0x60)
                fail("gap.omf image bytes");
        }

        const qasm::LinkProduct *prog = find_prod(linked, "prog.omf");
        if (!prog) fail("missing prog.omf");
        else
            expect_err("prog.omf", prog->file, false, 0, "relocations");

        const qasm::LinkProduct *lib = find_prod(linked, "runtime.lib");
        if (!lib) fail("missing runtime.lib");
        else
            expect_err("runtime.lib", lib->file, false, 0, "object");
    }

    const char *tool = std::getenv("MAKEBIN");
    if (tool && !one.segs.empty()) {
        std::vector<uint8_t> omf;
        if (!qasm::omf_write(one, omf, err)) {
            fail("omf_write: " + err);
        } else {
            const std::string in = "test/fixtures/makebin-one.omf";
            const std::string out = "test/fixtures/makebin-one.bin";
            std::ofstream f(in, std::ios::binary);
            f.write(reinterpret_cast<const char *>(omf.data()),
                    static_cast<std::streamsize>(omf.size()));
            f.close();
            /* Quote the address. A shell reads $2000 as a variable. */
            std::string cmd = std::string("\"") + tool + "\" -org '$2000' -o \"" + out + "\" \"" +
                              in + "\"";
            int rc = std::system(cmd.c_str());
            if (rc != 0) fail("makeBin command failed");
            else {
                std::ifstream bin(out, std::ios::binary);
                std::vector<uint8_t> got((std::istreambuf_iterator<char>(bin)),
                                         std::istreambuf_iterator<char>());
                expect_bytes("cli image", got, bytes_of(apple, sizeof(apple)));
            }
            std::remove(in.c_str());
            std::remove(out.c_str());
        }
    }

    if (fails) {
        std::cerr << fails << " makeBin check" << (fails == 1 ? "" : "s") << " failed\n";
        return 1;
    }
    std::cout << "makeBin tests passed\n";
    return 0;
}
