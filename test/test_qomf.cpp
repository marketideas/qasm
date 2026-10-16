/* Dump OMF headers, records, and relocation entries. */

#include "link.hpp"
#include "omf.hpp"
#include "qomf.hpp"

#include <cstdint>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

namespace {

int fails = 0;
bool showed = false;

void fail(const std::string &msg)
{
    std::cerr << "FAIL " << msg << "\n";
    fails++;
}

void expect_has(const std::string &dump, const std::string &needle)
{
    if (dump.find(needle) != std::string::npos) return;
    fail("missing: " + needle);
    if (!showed) {
        std::cerr << dump;
        showed = true;
    }
}

void expect_absent(const std::string &dump, const std::string &needle)
{
    if (dump.find(needle) == std::string::npos) return;
    fail("unexpected: " + needle);
    if (!showed) {
        std::cerr << dump;
        showed = true;
    }
}

std::string dump_of(const std::vector<uint8_t> &bytes, bool &ok)
{
    std::ostringstream out;
    std::string err;
    ok = qasm::omf_dump(bytes, "sample.omf", out, err);
    if (!ok) out << "ERR " << err << "\n";
    showed = false;
    return out.str();
}

void put_u8(std::vector<uint8_t> &b, uint8_t v) { b.push_back(v); }

void put_u16(std::vector<uint8_t> &b, uint16_t v)
{
    b.push_back(static_cast<uint8_t>(v & 0xFF));
    b.push_back(static_cast<uint8_t>((v >> 8) & 0xFF));
}

void put_u32(std::vector<uint8_t> &b, uint32_t v)
{
    put_u16(b, static_cast<uint16_t>(v & 0xFFFF));
    put_u16(b, static_cast<uint16_t>((v >> 16) & 0xFFFF));
}

void patch_u32(std::vector<uint8_t> &b, size_t at, uint32_t v)
{
    b[at] = static_cast<uint8_t>(v & 0xFF);
    b[at + 1] = static_cast<uint8_t>((v >> 8) & 0xFF);
    b[at + 2] = static_cast<uint8_t>((v >> 16) & 0xFF);
    b[at + 3] = static_cast<uint8_t>((v >> 24) & 0xFF);
}

void patch_u16(std::vector<uint8_t> &b, size_t at, uint16_t v)
{
    b[at] = static_cast<uint8_t>(v & 0xFF);
    b[at + 1] = static_cast<uint8_t>((v >> 8) & 0xFF);
}

/* A one-segment OMF file. Body numbers are little-endian unless big is set. */
std::vector<uint8_t> raw_seg(int version, uint8_t numlen, uint8_t numsex,
                            const std::vector<uint8_t> &body)
{
    std::vector<uint8_t> b(0x2C, 0);
    for (int i = 0; i < 10; i++) b.push_back(0x20);
    put_u8(b, 1);
    b.push_back('A');
    uint16_t dispdata = static_cast<uint16_t>(b.size());
    b.insert(b.end(), body.begin(), body.end());
    patch_u32(b, 0x00, static_cast<uint32_t>(b.size()));
    patch_u32(b, 0x10, 0x00010000);
    b[0x0D] = 0;
    b[0x0E] = numlen;
    b[0x0F] = static_cast<uint8_t>(version);
    b[0x20] = numsex;
    patch_u16(b, 0x22, 1);
    patch_u16(b, 0x28, 0x2C);
    patch_u16(b, 0x2A, dispdata);
    return b;
}

qasm::OmfSeg seg_with(const std::string &name, const std::vector<uint8_t> &image)
{
    qasm::OmfSeg s;
    s.name = name;
    s.image = image;
    return s;
}

} // namespace

int main()
{
    std::string err;
    bool ok = false;

    std::vector<uint8_t> empty;
    std::string empty_dump = dump_of(empty, ok);
    if (ok || empty_dump.find("too small") == std::string::npos) fail("empty file");

    const uint8_t image[] = {0x20, 0x01, 0x00, 0xAD, 0x00, 0x00, 0x00, 0x00, 0x6B};
    qasm::OmfFile load;
    load.version = 2;
    qasm::OmfSeg code = seg_with("CODE", std::vector<uint8_t>(image, image + sizeof(image)));
    code.org = 0x2000;
    code.align = 0x100;
    code.entry = 0x10;
    code.kind = 0x4001;
    code.segnum = 7;
    qasm::OmfReloc reloc;
    reloc.width = 2;
    reloc.at = 1;
    reloc.disp = 0;
    code.relocs.push_back(reloc);
    qasm::OmfReloc inter;
    inter.width = 3;
    inter.shift = -8;
    inter.at = 4;
    inter.disp = 1;
    inter.file = 1;
    inter.seg = 2;
    code.relocs.push_back(inter);
    load.segs.push_back(code);

    std::vector<uint8_t> bytes;
    if (!qasm::omf_write(load, bytes, err)) fail("write load: " + err);
    else {
        std::string dump = dump_of(bytes, ok);
        if (!ok) fail("load dump");
        expect_has(dump, "sample.omf: OMF 2.0 load file, 1 segment, ");
        expect_has(dump, "bytecnt $");
        expect_has(dump, "resspc $00000000");
        expect_has(dump, "length $00000009");
        expect_has(dump, "lablen 0 (Pascal)");
        expect_has(dump, "numlen 4");
        expect_has(dump, "version 2");
        expect_has(dump, "banksize $00010000");
        expect_has(dump, "kind $4001 data private");
        expect_has(dump, "org $00002000");
        expect_has(dump, "align $00000100");
        expect_has(dump, "numsex 0 (little)");
        expect_has(dump, "segnum 7");
        expect_has(dump, "entry $00000010");
        expect_has(dump, "dispname $002C");
        expect_has(dump, "loadname \"\"");
        expect_has(dump, "segname \"CODE\"");
        expect_has(dump, "LCONST  9 bytes at $00000000");
        expect_has(dump, "20 01 00 AD 00 00 00 00 6B");
        expect_has(dump, "RELOC  width 2  shift 0  at $00000001  disp $00000000");
        expect_has(dump, "INTERSEG  width 3  shift -8  at $00000004  file 1  seg 2  disp $00000001");
        expect_has(dump, "END");
        expect_has(dump, "relocations: 2");
        expect_has(dump, "fixups: 0");
        expect_absent(dump, "\n  CONST");
    }

    qasm::OmfFile obj;
    obj.version = 2;
    obj.object = true;
    qasm::OmfSeg oseg = seg_with("CODE", {0x20, 0x00, 0x00, 0xAD, 0x00, 0x00, 0x00, 0x00, 0x6B});
    qasm::OmfSym sym;
    sym.name = "CODE";
    sym.offset = 0;
    oseg.syms.push_back(sym);
    qasm::OmfFix hook;
    hook.at = 1;
    hook.width = 2;
    hook.symbol = "HOOK";
    oseg.fixups.push_back(hook);
    qasm::OmfFix value;
    value.at = 4;
    value.width = 3;
    value.symbol = "VALUE";
    value.addend = 1;
    value.divisor = 256;
    oseg.fixups.push_back(value);
    obj.segs.push_back(oseg);
    if (!qasm::omf_write(obj, bytes, err)) fail("write object: " + err);
    else {
        std::string dump = dump_of(bytes, ok);
        if (!ok) fail("object dump");
        expect_has(dump, "OMF 2.0 object file");
        expect_has(dump, "GLOBAL  \"CODE\"  at $00000000  length $0000  type 'N' ($4E)  private 0");
        expect_has(dump, "CONST  9 bytes at $00000000");
        expect_has(dump, "RELEXPR  width 2  at $00000001  HOOK");
        expect_has(dump, "RELEXPR  width 3  at $00000004  (VALUE+$00000001)/$00000100");
        expect_has(dump, "relocations: 0");
        expect_has(dump, "fixups: 2");
        expect_absent(dump, "LCONST");
    }

    qasm::OmfFile v1obj = obj;
    v1obj.version = 1;
    if (!qasm::omf_write(v1obj, bytes, err)) fail("write v1 object: " + err);
    else {
        std::string dump = dump_of(bytes, ok);
        if (!ok) fail("v1 object dump");
        expect_has(dump, "OMF 1.0 object file");
        expect_has(dump, "bytecnt $");
        expect_has(dump, "GLOBAL  \"CODE\"  at $00000000  length $00  type 'N' ($4E)  private 0");
        expect_has(dump, "RELEXPR  width 2  at $00000001  HOOK");
        expect_absent(dump, "blkcnt");
    }

    qasm::OmfFile v1load;
    v1load.version = 1;
    v1load.segs.push_back(seg_with("CODE", {0x60}));
    if (!qasm::omf_write(v1load, bytes, err)) fail("write v1 load: " + err);
    else {
        std::string dump = dump_of(bytes, ok);
        if (!ok) fail("v1 load dump");
        expect_has(dump, "OMF 1.0 load file");
        expect_has(dump, "blkcnt $00000001");
        expect_has(dump, "lcbank $00");
        expect_has(dump, "LCONST  1 byte at $00000000");
        expect_has(dump, "padding:");
        expect_has(dump, "relocations: 0");
    }

    std::vector<uint8_t> body;
    put_u8(body, 0xE1);
    put_u32(body, 0x00002000);
    put_u8(body, 0xF1);
    put_u32(body, 4);
    put_u8(body, 0xF5);
    put_u8(body, 2);
    put_u8(body, 0);
    put_u16(body, 0x0001);
    put_u16(body, 0x0002);
    put_u8(body, 0xF6);
    put_u8(body, 2);
    put_u8(body, 0xFF);
    put_u16(body, 0x0010);
    put_u8(body, 3);
    put_u16(body, 0x0004);
    put_u8(body, 0xF7);
    put_u32(body, 3);
    put_u8(body, 0x05);
    put_u8(body, 0xAA);
    put_u8(body, 0xBB);
    put_u8(body, 0x00);
    bytes = raw_seg(2, 4, 0, body);
    bytes[0x0C] = 0xAB;
    patch_u16(bytes, 0x16, 0x0002);
    bytes[0x21] = 0x7F;
    {
        std::string dump = dump_of(bytes, ok);
        if (!ok) fail("compressed records");
        expect_has(dump, "reserved +$0C $AB");
        expect_has(dump, "reserved +$16 $0002");
        expect_has(dump, "reserved +$21 $7F");
        expect_has(dump, "ORG  $00002000");
        expect_has(dump, "DS  $00000004 bytes at $00002000");
        expect_has(dump, "cRELOC  width 2  shift 0  at $0001  disp $0002");
        expect_has(dump, "cINTERSEG  width 2  shift -1  at $0010  seg 3  disp $0004");
        expect_has(dump, "SUPER  type $05  2 bytes");
        expect_has(dump, "AA BB");
        expect_has(dump, "relocations: 3");
    }

    body.clear();
    put_u8(body, 0xE2);
    put_u8(body, 2);
    put_u8(body, 0);
    body.push_back(0x00);
    body.push_back(0x00);
    body.push_back(0x00);
    body.push_back(0x01);
    body.push_back(0x00);
    body.push_back(0x00);
    body.push_back(0x00);
    body.push_back(0x0A);
    put_u8(body, 0x00);
    bytes = raw_seg(2, 4, 1, body);
    {
        std::string dump = dump_of(bytes, ok);
        if (!ok) fail("big-endian reloc");
        expect_has(dump, "numsex 1 (big)");
        expect_has(dump, "RELOC  width 2  shift 0  at $00000001  disp $0000000A");
    }

    body.clear();
    put_u8(body, 0xE2);
    put_u8(body, 2);
    put_u8(body, 0);
    put_u16(body, 0x0001);
    put_u16(body, 0x000A);
    put_u8(body, 0x00);
    bytes = raw_seg(2, 2, 0, body);
    {
        std::string dump = dump_of(bytes, ok);
        if (!ok) fail("numlen 2 reloc");
        expect_has(dump, "numlen 2");
        expect_has(dump, "RELOC  width 2  shift 0  at $00000001  disp $0000000A");
    }

    if (!qasm::omf_write(load, bytes, err)) fail("write for bad opcode: " + err);
    else if (bytes.empty() || bytes.back() != 0x00) fail("load file does not end at END");
    else {
        bytes.back() = 0xE9;
        std::string dump = dump_of(bytes, ok);
        if (ok || dump.find("unsupported OMF record $E9") == std::string::npos)
            fail("unsupported record");
    }

    std::ostringstream log;
    qasm::LinkOutput linked = qasm::link_script("test/fixtures/disk.link", log);
    if (!linked.ok()) {
        for (const auto &e : linked.errors) fail(e);
    } else {
        auto check_file = [](const std::string &path, const std::string &needle) {
            std::ifstream in(path, std::ios::binary);
            if (!in) {
                fail("cannot read " + path);
                return;
            }
            std::vector<uint8_t> buf((std::istreambuf_iterator<char>(in)),
                                     std::istreambuf_iterator<char>());
            bool good = false;
            std::string dump = dump_of(buf, good);
            if (!good) fail(path + " dump");
            expect_has(dump, needle);
        };
        check_file("test/fixtures/apple.omf", "OMF 1.0 load file, 1 segment, ");
        check_file("test/fixtures/apple.omf", "org $00002000");
        check_file("test/fixtures/apple.omf", "20 0A 20 AD 09 20 09 20 6B 42 20 00 20");
        check_file("test/fixtures/apple.omf", "blkcnt $");
        check_file("test/fixtures/apple.omf", "relocations: 0");
        check_file("test/fixtures/prog.omf", "OMF 2.0 load file, 2 segments, ");
        check_file("test/fixtures/prog.omf", "segname \"CODE\"");
        check_file("test/fixtures/prog.omf", "segname \"DATA\"");
        check_file("test/fixtures/prog.omf", "kind $0001 data");
        check_file("test/fixtures/prog.omf",
                   "INTERSEG  width 2  shift 0  at $00000001  file 1  seg 2  disp $00000001");
        check_file("test/fixtures/prog.omf",
                   "INTERSEG  width 2  shift 0  at $00000004  file 1  seg 2  disp $00000000");
        check_file("test/fixtures/prog.omf",
                   "INTERSEG  width 2  shift 0  at $00000006  file 1  seg 2  disp $00000000");
        check_file("test/fixtures/prog.omf",
                   "INTERSEG  width 2  shift 0  at $00000002  file 1  seg 1  disp $00000000");
        check_file("test/fixtures/prog.omf",
                   "INTERSEG  width 2  shift 0  at $00000005  file 1  seg 1  disp $00000000");
        check_file("test/fixtures/prog.omf",
                   "INTERSEG  width 2  shift 0  at $00000007  file 1  seg 1  disp $00000000");
        check_file("test/fixtures/prog.omf", "relocations: 3");
        check_file("test/fixtures/runtime.lib", "OMF 2.0 object file");
        check_file("test/fixtures/runtime.lib", "GLOBAL  \"VALUE\"");
        check_file("test/fixtures/runtime.lib", "RELEXPR");
    }

    const char *tool = std::getenv("QOMF");
    if (tool && !load.segs.empty()) {
        if (!qasm::omf_write(load, bytes, err)) fail("cli write: " + err);
        else {
            const std::string in = "test/fixtures/qomf-cli.omf";
            const std::string out = "test/fixtures/qomf-cli.txt";
            std::ofstream f(in, std::ios::binary);
            f.write(reinterpret_cast<const char *>(bytes.data()),
                    static_cast<std::streamsize>(bytes.size()));
            f.close();
            std::string cmd = std::string("\"") + tool + "\" \"" + in + "\" > \"" + out + "\"";
            int rc = std::system(cmd.c_str());
            if (rc != 0) fail("qomf command failed");
            else {
                std::ifstream text(out);
                std::string got((std::istreambuf_iterator<char>(text)),
                                std::istreambuf_iterator<char>());
                expect_has(got, "INTERSEG  width 3  shift -8  at $00000004  file 1  seg 2  disp $00000001");
                expect_has(got, "RELOC  width 2  shift 0  at $00000001  disp $00000000");
                expect_has(got, in + ": OMF 2.0 load file");
            }
            std::remove(in.c_str());
            std::remove(out.c_str());
        }
    }

    if (fails) {
        std::cerr << fails << " qomf check" << (fails == 1 ? "" : "s") << " failed\n";
        return 1;
    }
    std::cout << "qomf tests passed\n";
    return 0;
}
