/* ProDOS volume create, copy, delete, and file type. */

#include "qpro.hpp"

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>
#include <sys/wait.h>
#include <unistd.h>

namespace {

int fails = 0;

void fail(const std::string &msg)
{
    std::cerr << "FAIL " << msg << "\n";
    fails++;
}

void expect(bool cond, const std::string &msg)
{
    if (!cond) fail(msg);
}

void expect_eq(uint32_t got, uint32_t want, const std::string &msg)
{
    if (got == want) return;
    fail(msg + " got " + std::to_string(got) + " want " + std::to_string(want));
}

void expect_err(bool ok, const std::string &err, const std::string &needle, const std::string &what)
{
    if (ok) {
        fail(what + " succeeded");
        return;
    }
    if (err.find(needle) == std::string::npos) fail(what + " error '" + err + "'");
}

uint16_t r16(const uint8_t *p)
{
    return static_cast<uint16_t>(p[0] | (p[1] << 8));
}

const uint8_t *block(const qasm::ProVolume &vol, uint16_t n)
{
    return vol.blocks.data() + static_cast<size_t>(n) * 512;
}

/* Bit 7 of a bitmap byte is the lowest block. A set bit is free. */
bool bit_free(const qasm::ProVolume &vol, uint16_t blk)
{
    uint16_t bmp = r16(block(vol, 2) + 0x27);
    uint32_t byte = blk / 8u;
    uint16_t which = static_cast<uint16_t>(bmp + byte / 512);
    const uint8_t *p = block(vol, which) + (byte % 512);
    uint8_t mask = static_cast<uint8_t>(0x80u >> (blk & 7));
    return (*p & mask) != 0;
}

std::vector<uint8_t> pattern(size_t n)
{
    std::vector<uint8_t> b(n);
    for (size_t i = 0; i < n; i++) b[i] = static_cast<uint8_t>((i * 17 + 3) & 0xff);
    return b;
}

bool make_vol(qasm::ProVolume &vol, const std::string &name, uint16_t blocks)
{
    std::string err;
    if (!qasm::pro_create(vol, name, blocks, err)) {
        fail("create " + name + ": " + err);
        return false;
    }
    return true;
}

void test_names()
{
    qasm::ProVolume vol;
    std::string err;
    expect_err(qasm::pro_create(vol, "", 280, err), err, "invalid name", "empty name");
    expect_err(qasm::pro_create(vol, "1DISK", 280, err), err, "invalid name", "digit name");
    expect_err(qasm::pro_create(vol, "HAS SPACE", 280, err), err, "invalid name", "space name");
    expect_err(qasm::pro_create(vol, "ABCDEFGHIJKLMNOP", 280, err), err, "invalid name", "long name");
    expect_err(qasm::pro_create(vol, "A-B", 280, err), err, "invalid name", "hyphen");
    expect_err(qasm::pro_create(vol, "OK", 6, err), err, "volume too small", "6 blocks");
    expect(qasm::pro_create(vol, "Test.Disk", 280, err), "dotted name");
    expect(qasm::pro_volume_name(vol) == "TEST.DISK", "stored upper case");

    uint16_t n = 0;
    expect(qasm::pro_parse_size("140K", n, err) && n == 280, "140k");
    expect(qasm::pro_parse_size("800kb", n, err) && n == 1600, "800k");
    expect(qasm::pro_parse_size("32M", n, err) && n == 65535, "32m");
    expect_err(qasm::pro_parse_size("1g", n, err), err, "bad size", "1g");
}

void test_header()
{
    qasm::ProVolume vol;
    if (!make_vol(vol, "test", 280)) return;
    expect_eq(vol.blocks.size(), 280u * 512u, "image bytes");
    expect_eq(qasm::pro_total_blocks(vol), 280, "total");
    expect_eq(qasm::pro_free_blocks(vol), 273, "free");
    const uint8_t *b = block(vol, 2);
    expect(r16(b) == 0, "prev");
    expect(r16(b + 2) == 3, "next");
    expect(b[4] == 0xF4, "storage and length");
    expect(std::memcmp(b + 5, "TEST", 4) == 0, "name bytes");
    expect(b[0x20] == 0, "version");
    expect(b[0x21] == 0, "min version");
    expect(b[0x22] == 0xE3, "access");
    expect(b[0x23] == 0x27, "entry length");
    expect(b[0x24] == 0x0D, "entries per block");
    expect(r16(b + 0x25) == 0, "file count");
    expect(r16(b + 0x27) == 6, "bitmap");
    expect(r16(b + 0x29) == 280, "total field");
    expect(r16(block(vol, 3)) == 2 && r16(block(vol, 3) + 2) == 4, "block 3 links");
    expect(r16(block(vol, 4)) == 3 && r16(block(vol, 4) + 2) == 5, "block 4 links");
    expect(r16(block(vol, 5)) == 4 && r16(block(vol, 5) + 2) == 0, "block 5 links");
    expect(block(vol, 0)[0] == 0 && block(vol, 1)[0] == 0, "boot blocks empty");
    for (uint16_t i = 0; i <= 6; i++) expect(!bit_free(vol, i), "used " + std::to_string(i));
    expect(bit_free(vol, 7), "block 7 free");
    expect(block(vol, 6)[0] == 0x01, "bitmap byte 0");
    expect(block(vol, 6)[34] == 0xFF, "last used bitmap byte");
    expect(block(vol, 6)[35] == 0x00, "bitmap past end");

    std::time_t now = std::time(nullptr);
    std::tm tm{};
    localtime_r(&now, &tm);
    int year = tm.tm_year + 1900;
    int field = year >= 2000 ? year - 2000 : year - 1900;
    uint16_t date = r16(b + 0x1c);
    expect_eq(date >> 9, static_cast<uint32_t>(field), "year");
    expect_eq((date >> 5) & 0xF, static_cast<uint32_t>(tm.tm_mon + 1), "month");
    expect_eq(date & 0x1F, static_cast<uint32_t>(tm.tm_mday), "day");
    uint16_t tim = r16(b + 0x1e);
    expect((tim & ~0x1F3F) == 0, "time unused bits");
    int hour = (tim >> 8) & 0x1F;
    int minute = tim & 0x3F;
    bool same = hour == tm.tm_hour && minute == tm.tm_min;
    int prev_h = tm.tm_hour;
    int prev_m = tm.tm_min - 1;
    if (prev_m < 0) {
        prev_m = 59;
        prev_h = (tm.tm_hour + 23) % 24;
    }
    expect(same || (hour == prev_h && minute == prev_m), "time");

    std::vector<qasm::ProFileInfo> ents;
    std::string err;
    expect(qasm::pro_catalog(vol, "", ents, err) && ents.empty(), "empty catalog");
    expect(qasm::pro_catalog(vol, "/TEST", ents, err) && ents.empty(), "root path");
    expect_err(qasm::pro_catalog(vol, "/NOPE", ents, err), err, "volume name mismatch", "wrong volume");
}

void test_wide_bitmap()
{
    qasm::ProVolume vol;
    if (!make_vol(vol, "wide", 4097)) return;
    expect_eq(qasm::pro_free_blocks(vol), 4097 - 8, "two bitmap blocks");
    expect(!bit_free(vol, 7), "second bitmap used");
    expect(bit_free(vol, 8), "first data free");
    /* Block 4096 is the last block: byte 512 of the bitmap, bit 7. */
    expect(bit_free(vol, 4096), "last block free");
    const uint8_t *second = block(vol, 7);
    expect(second[0] == 0x80, "partial last bitmap byte");
    expect(second[1] == 0, "no block past the end");
}

void test_round_trip(qasm::ProVolume &vol, const std::string &path, const std::vector<uint8_t> &data,
                     uint8_t type, uint16_t aux, uint8_t storage, uint16_t blocks)
{
    std::string err;
    uint16_t before = qasm::pro_free_blocks(vol);
    expect(qasm::pro_add(vol, path, data, type, aux, err), path + " add " + err);
    std::vector<qasm::ProFileInfo> ents;
    expect(qasm::pro_catalog(vol, path, ents, err) && ents.size() == 1, path + " catalog");
    if (ents.size() == 1) {
        expect(ents[0].name == "FILE" || ents[0].name.size() > 0, path + " named");
        expect_eq(ents[0].storage, storage, path + " storage");
        expect_eq(ents[0].type, type, path + " type");
        expect_eq(ents[0].aux, aux, path + " aux");
        expect_eq(ents[0].eof, static_cast<uint32_t>(data.size()), path + " eof");
        expect_eq(ents[0].blocks, blocks, path + " blocks");
    }
    std::vector<uint8_t> got;
    expect(qasm::pro_get(vol, path, got, err), path + " get " + err);
    expect(got == data, path + " bytes");
    expect_eq(static_cast<uint32_t>(before - qasm::pro_free_blocks(vol)), blocks, path + " bitmap");
}

void test_files()
{
    qasm::ProVolume vol;
    if (!make_vol(vol, "files", 280)) return;
    test_round_trip(vol, "empty", {}, 0x06, 0, 1, 1);
    test_round_trip(vol, "small", pattern(100), 0xFF, 0x2000, 1, 1);
    test_round_trip(vol, "fullseed", pattern(512), 0x06, 0, 1, 1);
    test_round_trip(vol, "sap", pattern(513), 0x06, 0, 2, 3);
    test_round_trip(vol, "sap600", pattern(600), 0x04, 0x0000, 2, 3);

    std::string err;
    std::vector<uint8_t> again = pattern(100);
    expect_err(qasm::pro_add(vol, "small", again, 6, 0, err), err, "already exists", "duplicate");
    expect_err(qasm::pro_add(vol, "NO/FILE", again, 6, 0, err), err, "not found", "missing parent");
    expect(qasm::pro_add(vol, "small2", pattern(4), 6, 0, err), "small2");
    expect_err(qasm::pro_add(vol, "small2/child", pattern(4), 6, 0, err), err, "not a directory",
               "file as dir");
    expect_err(qasm::pro_get(vol, "nope", again, err), err, "not found", "missing get");

    uint16_t free_now = qasm::pro_free_blocks(vol);
    expect(qasm::pro_remove(vol, "SMALL", err), "remove small " + err);
    expect_eq(qasm::pro_free_blocks(vol), free_now + 1, "seedling freed");
    expect_err(qasm::pro_get(vol, "small", again, err), err, "not found", "gone");
    expect(qasm::pro_add(vol, "small", pattern(100), 0xFF, 0x2000, err), "readd");
    const uint8_t *e = block(vol, 2) + 4 + 0x27;
    /* The first live entry may be EMPTY. Find SMALL. */
    bool found = false;
    for (int i = 1; i < 13 && !found; i++) {
        const uint8_t *ent = block(vol, 2) + 4 + i * 0x27;
        if ((ent[0] & 0x0f) == 5 && std::memcmp(ent + 1, "SMALL", 5) == 0) {
            expect_eq(r16(ent + 0x11), 8, "key reuses the freed block");
            found = true;
            e = ent;
        }
    }
    expect(found, "SMALL entry");
    (void)e;

    expect(qasm::pro_set_type(vol, "small", true, 0x06, true, 0x0801, err), "set type");
    std::vector<qasm::ProFileInfo> ents;
    expect(qasm::pro_catalog(vol, "Small", ents, err) && ents.size() == 1, "case get");
    if (ents.size() == 1) {
        expect_eq(ents[0].type, 0x06, "new type");
        expect_eq(ents[0].aux, 0x0801, "new aux");
        expect_eq(ents[0].eof, 100, "eof unchanged");
    }
    expect(qasm::pro_set_type(vol, "sap600", false, 0, true, 0x1234, err), "aux only");
    expect(qasm::pro_catalog(vol, "SAP600", ents, err) && ents.size() == 1 && ents[0].type == 0x04 &&
               ents[0].aux == 0x1234,
           "aux kept type");

    qasm::ProVolume tiny;
    expect(qasm::pro_create(tiny, "tiny", 8, err), "8 blocks");
    expect_eq(qasm::pro_free_blocks(tiny), 1, "one free");
    expect_err(qasm::pro_add(tiny, "big", pattern(513), 6, 0, err), err, "disk full", "sapling full");
    expect_eq(qasm::pro_free_blocks(tiny), 1, "unchanged after full");
    expect(qasm::pro_add(tiny, "one", pattern(3), 6, 0, err), "one seedling");
    expect_err(qasm::pro_add(tiny, "two", pattern(3), 6, 0, err), err, "disk full", "second file");
    std::vector<uint8_t> got;
    expect(qasm::pro_get(tiny, "one", got, err) && got == pattern(3), "first file intact");
}

void test_tree()
{
    qasm::ProVolume vol;
    std::string err;
    if (!make_vol(vol, "tree", 280)) return;
    std::vector<uint8_t> sap = pattern(131072);
    uint16_t before = qasm::pro_free_blocks(vol);
    expect(qasm::pro_add(vol, "maxsap", sap, 0x06, 0, err), "max sapling " + err);
    std::vector<qasm::ProFileInfo> ents;
    expect(qasm::pro_catalog(vol, "maxsap", ents, err) && ents.size() == 1, "maxsap info");
    if (ents.size() == 1) {
        expect_eq(ents[0].storage, 2, "sapling storage");
        expect_eq(ents[0].blocks, 257, "sapling blocks");
    }
    std::vector<uint8_t> got;
    expect(qasm::pro_get(vol, "maxsap", got, err) && got == sap, "maxsap bytes");
    expect(qasm::pro_remove(vol, "maxsap", err), "rm maxsap");
    expect_eq(qasm::pro_free_blocks(vol), before, "sapling blocks freed");
    for (uint16_t i = 0; i <= 6; i++) expect(!bit_free(vol, i), "system still used");

    qasm::ProVolume big;
    if (!make_vol(big, "tree", 1600)) return;
    std::vector<uint8_t> tree = pattern(131073);
    before = qasm::pro_free_blocks(big);
    expect(qasm::pro_add(big, "bigtree", tree, 0x06, 0, err), "tree " + err);
    expect(qasm::pro_catalog(big, "bigtree", ents, err) && ents.size() == 1, "tree info");
    if (ents.size() == 1) {
        expect_eq(ents[0].storage, 3, "tree storage");
        expect_eq(ents[0].blocks, 260, "tree blocks");
        expect_eq(ents[0].eof, 131073, "tree eof");
    }
    got.clear();
    expect(qasm::pro_get(big, "bigtree", got, err) && got == tree, "tree bytes");
    expect_eq(static_cast<uint32_t>(before - qasm::pro_free_blocks(big)), 260, "tree bitmap");
    expect(qasm::pro_remove(big, "bigtree", err), "rm tree");
    expect_eq(qasm::pro_free_blocks(big), before, "tree blocks freed");
}

void test_dirs()
{
    qasm::ProVolume vol;
    std::string err;
    if (!make_vol(vol, "disk", 280)) return;
    expect(qasm::pro_mkdir(vol, "sub", err), "mkdir " + err);
    expect_eq(r16(block(vol, 2) + 0x25), 1, "root count");
    const uint8_t *ent = block(vol, 2) + 4 + 0x27;
    expect(ent[0] == 0xD3, "dir storage");
    expect(ent[0x10] == 0x0F, "dir type");
    expect(r16(ent + 0x13) == 1, "dir blocks");
    expect(ent[0x15] == 0 && ent[0x16] == 2 && ent[0x17] == 0, "dir eof 512");
    uint16_t key = r16(ent + 0x11);
    expect_eq(key, 7, "subdir key");
    const uint8_t *h = block(vol, key);
    expect(h[4] == 0xE3, "subdir header");
    expect(h[4 + 0x10] == 0x76, "gsos mark");
    expect(h[4 + 0x1c] == 5, "subdir version");
    expect(r16(h + 4 + 0x21) == 0, "subdir count");
    expect(r16(h + 4 + 0x23) == 2, "parent block");
    expect(h[4 + 0x25] == 2, "parent entry");
    expect(h[4 + 0x26] == 0x27, "parent entry length");

    std::vector<uint8_t> note = pattern(20);
    expect(qasm::pro_add(vol, "SUB/note.txt", note, 0x04, 0, err), "add in dir");
    std::vector<uint8_t> got;
    expect(qasm::pro_get(vol, "/DISK/sub/NOTE.TXT", got, err) && got == note, "get nested");
    expect_err(qasm::pro_get(vol, "sub", got, err), err, "is a directory", "get dir");
    expect_err(qasm::pro_remove(vol, "/DISK", err), err, "cannot remove volume", "rm root");
    expect_err(qasm::pro_remove(vol, "sub", err), err, "directory not empty", "rm full dir");
    expect(qasm::pro_get(vol, "sub/note.txt", got, err) && got == note, "still there");

    expect(qasm::pro_remove(vol, "sub/note.txt", err), "rm note");
    expect(qasm::pro_remove(vol, "sub", err), "rm empty dir");
    expect_eq(r16(block(vol, 2) + 0x25), 0, "root count cleared");
    expect_eq(qasm::pro_free_blocks(vol), 273, "dir blocks freed");

    expect(qasm::pro_mkdir(vol, "sub", err), "mkdir again");
    for (int i = 0; i < 13; i++) {
        std::string path = "sub/F" + std::to_string(i);
        expect(qasm::pro_add(vol, path, pattern(1), 6, 0, err), path);
    }
    std::vector<qasm::ProFileInfo> ents;
    expect(qasm::pro_catalog(vol, "sub", ents, err) && ents.size() == 13, "13 children");
    expect(qasm::pro_catalog(vol, "/DISK/SUB", ents, err), "catalog sub");
    bool sub = false;
    for (const auto &e : ents) {
        if (e.name == "SUB") sub = true;
    }
    /* catalog of the directory lists children, not itself. */
    expect(!sub, "children only");
    expect(qasm::pro_catalog(vol, "", ents, err), "root list");
    sub = false;
    uint16_t sub_blocks = 0;
    uint32_t sub_eof = 0;
    for (const auto &e : ents) {
        if (e.name == "SUB") {
            sub = true;
            sub_blocks = e.blocks;
            sub_eof = e.eof;
        }
    }
    expect(sub, "root shows SUB");
    expect_eq(sub_blocks, 2, "directory grew");
    expect_eq(sub_eof, 1024, "directory eof");
    expect(block(vol, 2)[4] == 0xF4, "volume header intact");
    expect(std::memcmp(block(vol, 2) + 5, "DISK", 4) == 0, "volume name intact");
    expect(r16(block(vol, 2) + 0x29) == 280, "total intact");

    qasm::ProVolume full;
    if (!make_vol(full, "full", 280)) return;
    for (int i = 0; i < 51; i++) {
        char name[8];
        std::snprintf(name, sizeof(name), "F%02d", i);
        if (!qasm::pro_add(full, name, pattern(1), 6, 0, err)) fail(std::string("add ") + name + " " + err);
    }
    expect_eq(r16(block(full, 2) + 0x25), 51, "51 files");
    expect_err(qasm::pro_add(full, "MORE", pattern(1), 6, 0, err), err, "directory full", "52nd");
    expect_err(qasm::pro_mkdir(full, "MORE", err), err, "directory full", "mkdir full");
}

std::string slurp(const std::string &path)
{
    std::ifstream in(path);
    return std::string(std::istreambuf_iterator<char>(in), std::istreambuf_iterator<char>());
}

int run(const std::string &cmd, const std::string &dir, std::string &out, std::string &err)
{
    std::string op = dir + "/stdout.txt";
    std::string ep = dir + "/stderr.txt";
    std::string full = cmd + " > '" + op + "' 2> '" + ep + "'";
    int status = std::system(full.c_str());
    out = slurp(op);
    err = slurp(ep);
    if (status == -1 || !WIFEXITED(status)) return -1;
    return WEXITSTATUS(status);
}

void test_image_io(const std::string &dir)
{
    qasm::ProVolume vol;
    std::string err;
    if (!make_vol(vol, "wrap", 280)) return;
    expect(qasm::pro_add(vol, "a", pattern(40), 0xFF, 0x2000, err), "wrap add");
    std::string po = dir + "/wrap.po";
    std::string mg = dir + "/wrap.2mg";
    expect(qasm::pro_save(vol, po, err), "save po " + err);
    expect(qasm::pro_save(vol, mg, err), "save 2mg " + err);
    std::ifstream raw(po, std::ios::binary);
    std::vector<uint8_t> bytes((std::istreambuf_iterator<char>(raw)), {});
    expect_eq(static_cast<uint32_t>(bytes.size()), 280u * 512u, "raw size");
    expect(bytes.size() >= 4 && std::memcmp(bytes.data(), "2IMG", 4) != 0, "raw has no 2mg");

    std::ifstream img(mg, std::ios::binary);
    std::vector<uint8_t> hdr((std::istreambuf_iterator<char>(img)), {});
    expect(hdr.size() == 64 + 280u * 512u, "2mg size");
    expect(std::memcmp(hdr.data(), "2IMG", 4) == 0, "magic");
    expect(std::memcmp(hdr.data() + 4, "qpro", 4) == 0, "creator");
    expect(r16(hdr.data() + 8) == 64, "header length");
    expect(hdr[0x0c] == 1, "prodos order");

    qasm::ProVolume loaded;
    expect(qasm::pro_load(loaded, mg, err), "load 2mg " + err);
    expect(loaded.wrapped_2mg, "wrapped flag");
    std::vector<uint8_t> got;
    expect(qasm::pro_get(loaded, "A", got, err) && got == pattern(40), "2mg bytes");
    qasm::ProVolume rawv;
    expect(qasm::pro_load(rawv, po, err), "load po");
    expect(!rawv.wrapped_2mg, "raw flag");
    expect(qasm::pro_get(rawv, "a", got, err) && got == pattern(40), "po bytes");

    std::string bad = dir + "/bad.po";
    {
        std::ofstream out(bad, std::ios::binary);
        std::vector<uint8_t> z(7 * 512, 0);
        out.write(reinterpret_cast<const char *>(z.data()), static_cast<std::streamsize>(z.size()));
    }
    expect_err(qasm::pro_load(rawv, bad, err), err, "not a ProDOS volume", "zeros");
}

void test_boot(void)
{
    qasm::ProVolume vol;
    std::string err;
    if (!make_vol(vol, "boot", 280)) return;
    std::vector<uint8_t> boot(1024);
    for (size_t i = 0; i < boot.size(); i++) boot[i] = static_cast<uint8_t>(i & 0xFF);
    boot[0] = 0xD8;
    uint16_t free_before = qasm::pro_free_blocks(vol);
    expect(qasm::pro_write_boot(vol, boot, err), "write boot " + err);
    expect(std::memcmp(block(vol, 0), boot.data(), 512) == 0, "block 0");
    expect(std::memcmp(block(vol, 1), boot.data() + 512, 512) == 0, "block 1");
    expect_eq(qasm::pro_free_blocks(vol), free_before, "boot keeps bitmap");
    expect(!bit_free(vol, 0) && !bit_free(vol, 1) && bit_free(vol, 7), "boot bits");
    std::vector<uint8_t> shortb(512, 0x11);
    expect_err(qasm::pro_write_boot(vol, shortb, err), err, "boot image must be 1024 bytes",
               "short boot");
    expect(block(vol, 0)[0] == 0xD8, "failed boot leaves block 0");
}

void test_cli(const std::string &dir)
{
    const char *tool = std::getenv("QPRO");
    if (!tool || !*tool) return;
    std::string q = std::string("'") + tool + "'";
    std::string vol = dir + "/disk.po";
    std::string host = dir + "/host.bin";
    std::string outp = dir + "/out.bin";
    std::vector<uint8_t> body = pattern(300);
    {
        std::ofstream out(host, std::ios::binary);
        out.write(reinterpret_cast<const char *>(body.data()), static_cast<std::streamsize>(body.size()));
    }
    std::string out, err;
    expect_eq(static_cast<uint32_t>(run(q, dir, out, err)), 2, "no args");
    expect(err.find("qpro create") != std::string::npos, "usage text");
    expect_eq(static_cast<uint32_t>(run(q + " -V", dir, out, err)), 0, "version status");
    expect(out.find("qpro 0.1.0") != std::string::npos, "version text");

    int rc = run(q + " create '" + vol + "' -name Test -blocks 280", dir, out, err);
    expect_eq(static_cast<uint32_t>(rc), 0, "cli create");
    expect(out.find("created volume TEST") != std::string::npos, "create summary");
    expect(out.find("280 blocks") != std::string::npos, "create blocks");
    rc = run(q + " create '" + vol + "' -name Test -blocks 280", dir, out, err);
    expect_eq(static_cast<uint32_t>(rc), 1, "create exists");
    expect(err.find("already exists") != std::string::npos, "exists text");

    std::string sized = dir + "/floppy.po";
    rc = run(q + " create '" + sized + "' -name Floppy -size 140k", dir, out, err);
    expect_eq(static_cast<uint32_t>(rc), 0, "size 140k");
    qasm::ProVolume flop;
    std::string why;
    expect(qasm::pro_load(flop, sized, why) && qasm::pro_total_blocks(flop) == 280, "140k blocks");

    rc = run(q + " add '" + vol + "' basic.system '" + host + "' -t '$FF' -a '$2000'", dir, out, err);
    expect_eq(static_cast<uint32_t>(rc), 0, "cli add " + err);
    rc = run(q + " mkdir '" + vol + "' sub", dir, out, err);
    expect_eq(static_cast<uint32_t>(rc), 0, "cli mkdir");
    rc = run(q + " add '" + vol + "' sub/note '" + host + "' -t '$04'", dir, out, err);
    expect_eq(static_cast<uint32_t>(rc), 0, "cli add dir");
    rc = run(q + " get '" + vol + "' /TEST/BASIC.SYSTEM '" + outp + "'", dir, out, err);
    expect_eq(static_cast<uint32_t>(rc), 0, "cli get");
    std::ifstream gotf(outp, std::ios::binary);
    std::vector<uint8_t> got((std::istreambuf_iterator<char>(gotf)), {});
    expect(got == body, "cli bytes");

    rc = run(q + " cat '" + vol + "'", dir, out, err);
    expect_eq(static_cast<uint32_t>(rc), 0, "cli cat");
    expect(out.find("BASIC.SYSTEM") != std::string::npos, "cat name");
    expect(out.find(" FF  2000") != std::string::npos, "cat type");
    expect(out.find("/TEST") != std::string::npos, "cat volume");

    rc = run(q + " typ '" + vol + "' sub/note -t '$06' -a '$0800'", dir, out, err);
    expect_eq(static_cast<uint32_t>(rc), 0, "cli typ");
    expect(out.find("type $06 aux $0800") != std::string::npos, "typ summary");
    rc = run(q + " rm '" + vol + "' sub", dir, out, err);
    expect_eq(static_cast<uint32_t>(rc), 1, "rm nonempty");
    expect(err.find("directory not empty") != std::string::npos, "nonempty text");
    rc = run(q + " rm '" + vol + "' BASIC.SYSTEM", dir, out, err);
    expect_eq(static_cast<uint32_t>(rc), 0, "cli rm");
    rc = run(q + " rm '" + vol + "' sub/note", dir, out, err);
    expect_eq(static_cast<uint32_t>(rc), 0, "rm note");
    rc = run(q + " rm '" + vol + "' sub", dir, out, err);
    expect_eq(static_cast<uint32_t>(rc), 0, "rm dir");
    rc = run(q + " cat '" + vol + "'", dir, out, err);
    expect(out.find("BASIC.SYSTEM") == std::string::npos, "file gone");
    expect(out.find(" SUB") == std::string::npos, "dir gone");

    std::string bpath = dir + "/bootblk.bin";
    std::vector<uint8_t> boot(1024, 0x22);
    boot[0] = 0xD8;
    {
        std::ofstream bout(bpath, std::ios::binary);
        bout.write(reinterpret_cast<const char *>(boot.data()),
                   static_cast<std::streamsize>(boot.size()));
    }
    rc = run(q + " boot '" + vol + "' '" + bpath + "'", dir, out, err);
    expect_eq(static_cast<uint32_t>(rc), 0, "cli boot " + err);
    qasm::ProVolume booted;
    expect(qasm::pro_load(booted, vol, why), "reload boot");
    expect(booted.blocks.size() >= 512 && booted.blocks[0] == 0xD8, "cli boot byte");
    rc = run(q + " boot '" + vol + "' '" + host + "'", dir, out, err);
    expect_eq(static_cast<uint32_t>(rc), 1, "cli short boot");
    expect(err.find("boot image must be 1024 bytes") != std::string::npos, "short boot text");
}

} // namespace

int main()
{
    char tmpl[] = "/tmp/qpro-test-XXXXXX";
    if (!mkdtemp(tmpl)) {
        std::cerr << "FAIL mkdtemp\n";
        return 1;
    }
    std::string dir = tmpl;
    test_names();
    test_header();
    test_wide_bitmap();
    test_files();
    test_tree();
    test_dirs();
    test_image_io(dir);
    test_boot();
    test_cli(dir);
    std::string cleanup = "rm -rf '" + dir + "'";
    if (std::system(cleanup.c_str()) != 0) fail("cleanup");

    if (fails) {
        std::cerr << fails << " qpro check" << (fails == 1 ? "" : "s") << " failed\n";
        return 1;
    }
    std::cout << "qpro tests passed\n";
    return 0;
}
