/* ProDOS block image. The volume directory is blocks 2-5. The bitmap
   starts at block 6. A set bit is a free block, and bit 7 of a byte is
   the lowest-numbered block in that byte. Index blocks store the low
   byte of each pointer in the first half and the high byte in the second. */

#include "qpro.hpp"

#include <ctime>
#include <cstring>
#include <fstream>
#include <utility>

namespace qasm {
namespace {

constexpr size_t kBlock = 512;
constexpr uint32_t kMaxEof = 0xFFFFFFu;
constexpr uint32_t kSaplingMax = 131072;
constexpr int kEntry = 0x27;
constexpr int kSlots = 13;
constexpr uint8_t kAccess = 0xE3;

constexpr uint8_t kSeed = 0x01;
constexpr uint8_t kSap = 0x02;
constexpr uint8_t kTree = 0x03;
constexpr uint8_t kExtended = 0x05;
constexpr uint8_t kDir = 0x0D;
constexpr uint8_t kDirHdr = 0x0E;
constexpr uint8_t kVolHdr = 0x0F;

uint16_t r16(const uint8_t *p)
{
    return static_cast<uint16_t>(p[0] | (p[1] << 8));
}

uint32_t r24(const uint8_t *p)
{
    return static_cast<uint32_t>(p[0] | (p[1] << 8) | (p[2] << 16));
}

void w16(uint8_t *p, uint16_t v)
{
    p[0] = static_cast<uint8_t>(v);
    p[1] = static_cast<uint8_t>(v >> 8);
}

void w24(uint8_t *p, uint32_t v)
{
    p[0] = static_cast<uint8_t>(v);
    p[1] = static_cast<uint8_t>(v >> 8);
    p[2] = static_cast<uint8_t>(v >> 16);
}

void w32(uint8_t *p, uint32_t v)
{
    w16(p, static_cast<uint16_t>(v));
    w16(p + 2, static_cast<uint16_t>(v >> 16));
}

uint32_t r32(const uint8_t *p)
{
    return static_cast<uint32_t>(r16(p)) | (static_cast<uint32_t>(r16(p + 2)) << 16);
}

std::string upper_copy(const std::string &s)
{
    std::string o = s;
    for (char &c : o) {
        if (c >= 'a' && c <= 'z') c = static_cast<char>(c - 'a' + 'A');
    }
    return o;
}

std::string lower_copy(const std::string &s)
{
    std::string o = s;
    for (char &c : o) {
        if (c >= 'A' && c <= 'Z') c = static_cast<char>(c - 'A' + 'a');
    }
    return o;
}

bool valid_name(const std::string &s)
{
    if (s.size() < 1 || s.size() > 15) return false;
    if (s[0] < 'A' || s[0] > 'Z') return false;
    for (char c : s) {
        if (c >= 'A' && c <= 'Z') continue;
        if (c >= '0' && c <= '9') continue;
        if (c == '.') continue;
        return false;
    }
    return true;
}

bool ends_ci(const std::string &path, const char *ext)
{
    size_t n = std::strlen(ext);
    if (path.size() < n) return false;
    for (size_t i = 0; i < n; i++) {
        char a = path[path.size() - n + i];
        if (a >= 'A' && a <= 'Z') a = static_cast<char>(a - 'A' + 'a');
        if (a != ext[i]) return false;
    }
    return true;
}

void prodos_now(uint16_t &date, uint16_t &tim)
{
    std::time_t now = std::time(nullptr);
    std::tm tm{};
    localtime_r(&now, &tm);
    int year = tm.tm_year + 1900;
    int y;
    if (year >= 2000 && year <= 2039) y = year - 2000;
    else if (year >= 1940 && year <= 1999) y = year - 1900;
    else if (year > 2039) y = 39;
    else y = 40;
    int month = tm.tm_mon + 1;
    int day = tm.tm_mday;
    date = static_cast<uint16_t>((y << 9) | (month << 5) | day);
    tim = static_cast<uint16_t>((tm.tm_hour << 8) | tm.tm_min);
}

bool in_range(const ProVolume &vol, uint16_t b)
{
    return static_cast<size_t>(b) < vol.blocks.size() / kBlock;
}

uint8_t *at(ProVolume &vol, uint16_t b, uint16_t off)
{
    return vol.blocks.data() + static_cast<size_t>(b) * kBlock + off;
}

const uint8_t *at(const ProVolume &vol, uint16_t b, uint16_t off)
{
    return vol.blocks.data() + static_cast<size_t>(b) * kBlock + off;
}

uint8_t *entry_at(ProVolume &vol, uint16_t b, uint8_t index)
{
    return at(vol, b, static_cast<uint16_t>(4 + index * kEntry));
}

const uint8_t *entry_at(const ProVolume &vol, uint16_t b, uint8_t index)
{
    return at(vol, b, static_cast<uint16_t>(4 + index * kEntry));
}

uint16_t total_of(const ProVolume &vol)
{
    if (!in_range(vol, 2)) return 0;
    return r16(at(vol, 2, 0x29));
}

uint16_t bitmap_ptr(const ProVolume &vol)
{
    return r16(at(vol, 2, 0x27));
}

uint32_t bitmap_span(uint16_t total)
{
    return (static_cast<uint32_t>(total) + 4095u) / 4096u;
}

std::string volume_name_of(const ProVolume &vol)
{
    if (!in_range(vol, 2)) return {};
    const uint8_t *h = at(vol, 2, 4);
    unsigned n = h[0] & 0x0f;
    if (n > 15) n = 15;
    return std::string(reinterpret_cast<const char *>(h + 1), n);
}

bool ready(const ProVolume &vol, std::string &err)
{
    if (vol.blocks.size() < 7 * kBlock || vol.blocks.size() % kBlock != 0) {
        err = "not a ProDOS volume";
        return false;
    }
    const uint8_t *b = at(vol, 2, 0);
    if ((b[4] >> 4) != kVolHdr || b[0x23] != kEntry) {
        err = "not a ProDOS volume";
        return false;
    }
    if (r16(b + 0x29) != vol.blocks.size() / kBlock) {
        err = "block count mismatch";
        return false;
    }
    return true;
}

uint8_t bit_mask(uint16_t block)
{
    return static_cast<uint8_t>(0x80u >> (block & 7));
}

bool bit_is_free(const ProVolume &vol, uint16_t block)
{
    uint16_t bmp = bitmap_ptr(vol);
    uint32_t byte_index = block / 8u;
    uint32_t which = bmp + byte_index / kBlock;
    uint32_t off = byte_index % kBlock;
    if (!in_range(vol, static_cast<uint16_t>(which))) return false;
    return (at(vol, static_cast<uint16_t>(which), static_cast<uint16_t>(off))[0] & bit_mask(block)) != 0;
}

void set_bit(ProVolume &vol, uint16_t block, bool free)
{
    uint16_t total = total_of(vol);
    uint16_t bmp = bitmap_ptr(vol);
    uint32_t byte_index = block / 8u;
    uint32_t which = bmp + byte_index / kBlock;
    uint32_t off = byte_index % kBlock;
    if (which >= total || !in_range(vol, static_cast<uint16_t>(which))) return;
    uint8_t *p = at(vol, static_cast<uint16_t>(which), static_cast<uint16_t>(off));
    uint8_t mask = bit_mask(block);
    if (free) *p = static_cast<uint8_t>(*p | mask);
    else *p = static_cast<uint8_t>(*p & static_cast<uint8_t>(~mask));
}

bool system_block(const ProVolume &vol, uint16_t block)
{
    uint16_t bmp = bitmap_ptr(vol);
    uint32_t span = bitmap_span(total_of(vol));
    if (block < bmp) return true;
    if (block >= bmp && block < bmp + span) return true;
    return false;
}

void free_block(ProVolume &vol, uint16_t block)
{
    uint16_t total = total_of(vol);
    if (block == 0 || block >= total) return;
    if (system_block(vol, block)) return;
    set_bit(vol, block, true);
}

bool alloc_block(ProVolume &vol, uint16_t &out, std::string &err)
{
    uint16_t total = total_of(vol);
    for (uint32_t b = 1; b < total; b++) {
        if (system_block(vol, static_cast<uint16_t>(b))) continue;
        if (!bit_is_free(vol, static_cast<uint16_t>(b))) continue;
        out = static_cast<uint16_t>(b);
        set_bit(vol, out, false);
        std::memset(at(vol, out, 0), 0, kBlock);
        return true;
    }
    err = "disk full";
    return false;
}

void rollback(ProVolume &vol, const std::vector<uint16_t> &blocks)
{
    for (uint16_t b : blocks) free_block(vol, b);
}

uint16_t index_ptr(const uint8_t *index, unsigned i)
{
    return static_cast<uint16_t>(index[i] | (index[256 + i] << 8));
}

void set_index_ptr(uint8_t *index, unsigned i, uint16_t block)
{
    index[i] = static_cast<uint8_t>(block);
    index[256 + i] = static_cast<uint8_t>(block >> 8);
}

void put_name(uint8_t *e, uint8_t storage, const std::string &name)
{
    e[0] = static_cast<uint8_t>((storage << 4) | (name.size() & 0x0f));
    std::memcpy(e + 1, name.data(), name.size());
}

bool name_eq(const uint8_t *e, const std::string &name)
{
    unsigned n = e[0] & 0x0f;
    if (n != name.size()) return false;
    return std::memcmp(e + 1, name.data(), n) == 0;
}

void fill_info(const uint8_t *e, ProFileInfo &info)
{
    info = ProFileInfo{};
    unsigned n = e[0] & 0x0f;
    if (n > 15) n = 15;
    info.storage = static_cast<uint8_t>(e[0] >> 4);
    info.name.assign(reinterpret_cast<const char *>(e + 1), n);
    info.type = e[0x10];
    info.blocks = r16(e + 0x13);
    info.eof = r24(e + 0x15);
    info.create_date = r16(e + 0x18);
    info.create_time = r16(e + 0x1a);
    info.access = e[0x1e];
    info.aux = r16(e + 0x1f);
    info.mod_date = r16(e + 0x21);
    info.mod_time = r16(e + 0x23);
    info.directory = info.storage == kDir;
}

struct Slot {
    uint16_t block = 0;
    uint8_t index = 0;
    uint16_t last = 0;
};

bool walk_dir(const ProVolume &vol, uint16_t key, std::string &err,
              const std::string *want, Slot *found, Slot *hole)
{
    uint16_t b = key;
    uint32_t guard = 0;
    uint16_t total = total_of(vol);
    while (b != 0) {
        if (!in_range(vol, b) || ++guard > total) {
            err = "bad directory";
            return false;
        }
        for (uint8_t i = 0; i < kSlots; i++) {
            if (b == key && i == 0) continue;
            const uint8_t *e = entry_at(vol, b, i);
            uint8_t storage = static_cast<uint8_t>(e[0] >> 4);
            if (storage == 0) {
                if (hole && hole->block == 0) {
                    hole->block = b;
                    hole->index = i;
                }
                continue;
            }
            if (want && name_eq(e, *want)) {
                found->block = b;
                found->index = i;
                return true;
            }
        }
        uint16_t next = r16(at(vol, b, 2));
        if (next == 0 && hole) hole->last = b;
        b = next;
    }
    if (want) {
        err = "not found";
        return false;
    }
    return true;
}

bool find_entry(const ProVolume &vol, uint16_t key, const std::string &name, Slot &slot,
                std::string &err)
{
    return walk_dir(vol, key, err, &name, &slot, nullptr);
}

bool find_hole(const ProVolume &vol, uint16_t key, Slot &hole, bool &need_grow, std::string &err)
{
    hole = Slot{};
    need_grow = false;
    if (!walk_dir(vol, key, err, nullptr, nullptr, &hole)) return false;
    if (hole.block != 0) return true;
    const uint8_t *h = at(vol, key, 4);
    if ((h[0] >> 4) == kVolHdr) {
        err = "directory full";
        return false;
    }
    need_grow = true;
    return true;
}

void link_dir_block(ProVolume &vol, uint16_t key, uint16_t last, uint16_t nb)
{
    w16(at(vol, last, 2), nb);
    w16(at(vol, nb, 0), last);
    w16(at(vol, nb, 2), 0);
    /* Header +$23 is the parent block that holds this directory's entry,
       and +$25 is that entry's 1-based slot. The volume header uses those
       bytes for the bitmap, so this runs only for a subdirectory. */
    uint8_t *h = at(vol, key, 4);
    uint16_t pblk = r16(h + 0x23);
    uint8_t pent = h[0x25];
    if (pent < 1 || pent > kSlots || !in_range(vol, pblk)) return;
    uint8_t *pe = entry_at(vol, pblk, static_cast<uint8_t>(pent - 1));
    uint16_t used = static_cast<uint16_t>(r16(pe + 0x13) + 1);
    w16(pe + 0x13, used);
    w24(pe + 0x15, static_cast<uint32_t>(used) * kBlock);
}

void write_times(uint8_t *e, uint16_t date, uint16_t tim, bool mod_too)
{
    w16(e + 0x18, date);
    w16(e + 0x1a, tim);
    if (mod_too) {
        w16(e + 0x21, date);
        w16(e + 0x23, tim);
    }
}

void bump_count(ProVolume &vol, uint16_t dir_key, int delta)
{
    uint8_t *h = at(vol, dir_key, 4);
    uint16_t n = r16(h + 0x21);
    if (delta > 0) n = static_cast<uint16_t>(n + 1);
    else if (n > 0) n = static_cast<uint16_t>(n - 1);
    w16(h + 0x21, n);
}

bool split_path(const ProVolume &vol, const std::string &path, std::vector<std::string> &parts,
                std::string &err)
{
    parts.clear();
    if (!ready(vol, err)) return false;
    std::string volname = volume_name_of(vol);
    bool absolute = !path.empty() && path[0] == '/';
    std::vector<std::string> raw;
    std::string cur;
    auto flush = [&]() {
        if (cur.empty()) return;
        raw.push_back(upper_copy(cur));
        cur.clear();
    };
    for (char c : path) {
        if (c == '/') flush();
        else cur.push_back(c);
    }
    flush();
    if (absolute) {
        if (raw.empty()) return true;
        if (raw[0] != volname) {
            err = "volume name mismatch";
            return false;
        }
        raw.erase(raw.begin());
    }
    for (const auto &n : raw) {
        if (!valid_name(n)) {
            err = "invalid name";
            return false;
        }
        parts.push_back(n);
    }
    return true;
}

struct Loc {
    bool root = false;
    uint16_t parent_key = 2;
    Slot slot;
    uint8_t storage = 0;
    uint16_t key = 0;
};

bool lookup(const ProVolume &vol, const std::vector<std::string> &parts, Loc &loc, std::string &err)
{
    loc = Loc{};
    loc.parent_key = 2;
    loc.key = 2;
    loc.storage = kVolHdr;
    if (parts.empty()) {
        loc.root = true;
        return true;
    }
    uint16_t dir = 2;
    for (size_t i = 0; i < parts.size(); i++) {
        Slot slot;
        if (!find_entry(vol, dir, parts[i], slot, err)) return false;
        const uint8_t *e = entry_at(vol, slot.block, slot.index);
        uint8_t storage = static_cast<uint8_t>(e[0] >> 4);
        uint16_t key = r16(e + 0x11);
        bool last = i + 1 == parts.size();
        if (!last) {
            if (storage != kDir) {
                err = "not a directory";
                return false;
            }
            dir = key;
            continue;
        }
        loc.root = false;
        loc.parent_key = dir;
        loc.slot = slot;
        loc.storage = storage;
        loc.key = key;
        return true;
    }
    err = "not found";
    return false;
}

bool parent_of(const ProVolume &vol, const std::vector<std::string> &parts, std::string &name,
               Loc &parent, std::string &err)
{
    if (parts.empty()) {
        err = "missing name";
        return false;
    }
    name = parts.back();
    std::vector<std::string> up(parts.begin(), parts.end() - 1);
    if (!lookup(vol, up, parent, err)) return false;
    if (!parent.root && parent.storage != kDir) {
        err = "not a directory";
        return false;
    }
    parent.key = parent.root ? 2 : parent.key;
    return true;
}

bool dir_is_empty(const ProVolume &vol, uint16_t key, std::string &err)
{
    uint16_t b = key;
    uint32_t guard = 0;
    uint16_t total = total_of(vol);
    while (b != 0) {
        if (!in_range(vol, b) || ++guard > total) {
            err = "bad directory";
            return false;
        }
        for (uint8_t i = 0; i < kSlots; i++) {
            if (b == key && i == 0) continue;
            if ((entry_at(vol, b, i)[0] >> 4) != 0) {
                err = "directory not empty";
                return false;
            }
        }
        b = r16(at(vol, b, 2));
    }
    return true;
}

bool remember(const ProVolume &vol, std::vector<uint16_t> &blocks, std::vector<uint8_t> &seen,
              uint16_t block, std::string &err)
{
    if (block == 0) return true;
    if (!in_range(vol, block)) {
        err = "bad block";
        return false;
    }
    if (seen[block]) return true;
    seen[block] = 1;
    blocks.push_back(block);
    return true;
}

bool collect_file(const ProVolume &vol, uint8_t storage, uint16_t key, std::vector<uint16_t> &blocks,
                  std::string &err)
{
    blocks.clear();
    std::vector<uint8_t> seen(total_of(vol), 0);
    if (storage == kSeed) return remember(vol, blocks, seen, key, err);
    if (storage != kSap && storage != kTree) {
        err = "unsupported storage";
        return false;
    }
    if (key == 0 || !in_range(vol, key)) {
        err = "bad block";
        return false;
    }
    if (storage == kSap) {
        const uint8_t *index = at(vol, key, 0);
        for (unsigned i = 0; i < 256; i++) {
            if (!remember(vol, blocks, seen, index_ptr(index, i), err)) return false;
        }
        return remember(vol, blocks, seen, key, err);
    }
    const uint8_t *master = at(vol, key, 0);
    for (unsigned s = 0; s < 128; s++) {
        uint16_t ib = index_ptr(master, s);
        if (ib == 0) continue;
        if (!in_range(vol, ib)) {
            err = "bad block";
            return false;
        }
        const uint8_t *index = at(vol, ib, 0);
        for (unsigned i = 0; i < 256; i++) {
            if (!remember(vol, blocks, seen, index_ptr(index, i), err)) return false;
        }
        if (!remember(vol, blocks, seen, ib, err)) return false;
    }
    return remember(vol, blocks, seen, key, err);
}

bool collect_dir_blocks(const ProVolume &vol, uint16_t key, std::vector<uint16_t> &blocks,
                        std::string &err)
{
    blocks.clear();
    std::vector<uint8_t> seen(total_of(vol), 0);
    uint16_t b = key;
    uint32_t guard = 0;
    uint16_t total = total_of(vol);
    while (b != 0) {
        if (!in_range(vol, b) || ++guard > total) {
            err = "bad directory";
            return false;
        }
        if (!remember(vol, blocks, seen, b, err)) return false;
        b = r16(at(vol, b, 2));
    }
    return true;
}

bool read_bytes(const ProVolume &vol, uint8_t storage, uint16_t key, uint32_t eof,
                std::vector<uint8_t> &data, std::string &err)
{
    data.assign(eof, 0);
    if (eof == 0) return true;
    if (storage == kSeed) {
        if (eof > kBlock || key == 0 || !in_range(vol, key)) {
            err = "bad block";
            return false;
        }
        std::memcpy(data.data(), at(vol, key, 0), eof);
        return true;
    }
    if (storage == kSap && eof > kSaplingMax) {
        err = "bad block";
        return false;
    }
    if (storage != kSap && storage != kTree) {
        err = "unsupported storage";
        return false;
    }
    if (key == 0 || !in_range(vol, key)) {
        err = "bad block";
        return false;
    }
    const uint8_t *master = at(vol, key, 0);
    uint32_t off = 0;
    while (off < eof) {
        uint32_t n = eof - off;
        if (n > kBlock) n = kBlock;
        uint32_t index = off / kBlock;
        uint16_t db = 0;
        if (storage == kSap) {
            if (index >= 256) {
                err = "bad block";
                return false;
            }
            db = index_ptr(master, static_cast<unsigned>(index));
        } else {
            unsigned sub = static_cast<unsigned>(index / 256);
            unsigned ix = static_cast<unsigned>(index % 256);
            if (sub >= 128) {
                err = "bad block";
                return false;
            }
            uint16_t ib = index_ptr(master, sub);
            if (ib == 0) db = 0;
            else if (!in_range(vol, ib)) {
                err = "bad block";
                return false;
            } else db = index_ptr(at(vol, ib, 0), ix);
        }
        if (db == 0) {
            /* Sparse hole. The bytes are already zero. */
        } else if (!in_range(vol, db)) {
            err = "bad block";
            return false;
        } else {
            std::memcpy(data.data() + off, at(vol, db, 0), n);
        }
        off += n;
    }
    return true;
}

bool place_data(ProVolume &vol, const std::vector<uint8_t> &data, uint8_t &storage, uint16_t &key,
                uint16_t &blocks_used, std::string &err)
{
    uint32_t eof = static_cast<uint32_t>(data.size());
    std::vector<uint16_t> got;
    auto take = [&](uint16_t &dst) -> bool {
        if (!alloc_block(vol, dst, err)) {
            rollback(vol, got);
            return false;
        }
        got.push_back(dst);
        return true;
    };
    if (eof <= kBlock) {
        uint16_t data_b = 0;
        if (!take(data_b)) return false;
        if (eof) std::memcpy(at(vol, data_b, 0), data.data(), eof);
        storage = kSeed;
        key = data_b;
        blocks_used = 1;
        return true;
    }
    uint32_t ndata = (eof + static_cast<uint32_t>(kBlock) - 1) / static_cast<uint32_t>(kBlock);
    if (eof <= kSaplingMax) {
        uint16_t index_b = 0;
        if (!take(index_b)) return false;
        std::vector<uint16_t> data_b(ndata);
        for (uint32_t i = 0; i < ndata; i++) {
            if (!take(data_b[i])) return false;
            set_index_ptr(at(vol, index_b, 0), static_cast<unsigned>(i), data_b[i]);
        }
        uint32_t off = 0;
        for (uint32_t i = 0; i < ndata; i++) {
            uint32_t n = eof - off;
            if (n > kBlock) n = kBlock;
            std::memcpy(at(vol, data_b[i], 0), data.data() + off, n);
            off += n;
        }
        storage = kSap;
        key = index_b;
        blocks_used = static_cast<uint16_t>(1 + ndata);
        return true;
    }
    uint32_t nindex = (ndata + 255) / 256;
    uint16_t master_b = 0;
    if (!take(master_b)) return false;
    std::vector<uint16_t> index_b(nindex);
    for (uint32_t s = 0; s < nindex; s++) {
        if (!take(index_b[s])) return false;
        set_index_ptr(at(vol, master_b, 0), static_cast<unsigned>(s), index_b[s]);
    }
    std::vector<uint16_t> data_b(ndata);
    uint32_t off = 0;
    for (uint32_t i = 0; i < ndata; i++) {
        if (!take(data_b[i])) return false;
        unsigned sub = static_cast<unsigned>(i / 256);
        unsigned ix = static_cast<unsigned>(i % 256);
        set_index_ptr(at(vol, index_b[sub], 0), ix, data_b[i]);
        uint32_t n = eof - off;
        if (n > kBlock) n = kBlock;
        std::memcpy(at(vol, data_b[i], 0), data.data() + off, n);
        off += n;
    }
    storage = kTree;
    key = master_b;
    blocks_used = static_cast<uint16_t>(1 + nindex + ndata);
    return true;
}

void write_file_entry(ProVolume &vol, const Slot &slot, const std::string &name, uint8_t storage,
                      uint8_t type, uint16_t aux, uint16_t key, uint16_t blocks_used, uint32_t eof,
                      uint16_t parent_key)
{
    uint16_t date = 0;
    uint16_t tim = 0;
    prodos_now(date, tim);
    uint8_t *e = entry_at(vol, slot.block, slot.index);
    std::memset(e, 0, kEntry);
    put_name(e, storage, name);
    e[0x10] = type;
    w16(e + 0x11, key);
    w16(e + 0x13, blocks_used);
    w24(e + 0x15, eof);
    write_times(e, date, tim, true);
    e[0x1e] = kAccess;
    w16(e + 0x1f, aux);
    /* +$25 is the key block of the directory that owns this entry. */
    w16(e + 0x25, parent_key);
}

bool list_dir(const ProVolume &vol, uint16_t key, std::vector<ProFileInfo> &out, std::string &err)
{
    out.clear();
    uint16_t b = key;
    uint32_t guard = 0;
    uint16_t total = total_of(vol);
    while (b != 0) {
        if (!in_range(vol, b) || ++guard > total) {
            err = "bad directory";
            return false;
        }
        for (uint8_t i = 0; i < kSlots; i++) {
            if (b == key && i == 0) continue;
            const uint8_t *e = entry_at(vol, b, i);
            if ((e[0] >> 4) == 0) continue;
            ProFileInfo info;
            fill_info(e, info);
            out.push_back(std::move(info));
        }
        b = r16(at(vol, b, 2));
    }
    return true;
}

bool validate_header(const ProVolume &vol, std::string &err)
{
    if (vol.blocks.size() < 7 * kBlock || vol.blocks.size() % kBlock != 0) {
        err = "not a ProDOS volume";
        return false;
    }
    if (vol.blocks.size() / kBlock > 65535) {
        err = "not a ProDOS volume";
        return false;
    }
    const uint8_t *b = at(vol, 2, 0);
    if (r16(b) != 0) {
        err = "not a ProDOS volume";
        return false;
    }
    unsigned nlen = b[4] & 0x0f;
    if ((b[4] >> 4) != kVolHdr || nlen < 1 || nlen > 15) {
        err = "not a ProDOS volume";
        return false;
    }
    if (b[5] < 'A' || b[5] > 'Z') {
        err = "not a ProDOS volume";
        return false;
    }
    if (b[0x23] != kEntry || b[0x24] != kSlots) {
        err = "not a ProDOS volume";
        return false;
    }
    uint16_t total = r16(b + 0x29);
    if (total != vol.blocks.size() / kBlock) {
        err = "block count mismatch";
        return false;
    }
    uint16_t bmp = r16(b + 0x27);
    if (bmp == 0 || bmp >= total) {
        err = "not a ProDOS volume";
        return false;
    }
    return true;
}

bool read_host(const std::string &path, std::vector<uint8_t> &buf, std::string &err)
{
    std::ifstream in(path, std::ios::binary);
    if (!in) {
        err = path + ": cannot open";
        return false;
    }
    buf.assign(std::istreambuf_iterator<char>(in), std::istreambuf_iterator<char>());
    return true;
}

bool write_host(const std::string &path, const std::vector<uint8_t> &buf, std::string &err)
{
    std::string tmp = path + ".qpro-tmp";
    {
        std::ofstream out(tmp, std::ios::binary);
        if (!out) {
            err = path + ": cannot write";
            return false;
        }
        if (!buf.empty())
            out.write(reinterpret_cast<const char *>(buf.data()),
                      static_cast<std::streamsize>(buf.size()));
        if (!out) {
            err = path + ": cannot write";
            std::remove(tmp.c_str());
            return false;
        }
    }
    if (std::rename(tmp.c_str(), path.c_str()) != 0) {
        std::remove(tmp.c_str());
        err = path + ": cannot write";
        return false;
    }
    return true;
}

bool load_2mg(const std::vector<uint8_t> &file, ProVolume &vol, std::string &err)
{
    if (file.size() < 64 || std::memcmp(file.data(), "2IMG", 4) != 0) {
        err = "not a ProDOS volume";
        return false;
    }
    uint32_t format = r32(file.data() + 0x0c);
    uint32_t blocks = r32(file.data() + 0x14);
    uint32_t off = r32(file.data() + 0x18);
    uint32_t len = r32(file.data() + 0x1c);
    if (format != 1) {
        err = "not a ProDOS-order image";
        return false;
    }
    if (blocks == 0 || blocks > 65535 || len != blocks * static_cast<uint32_t>(kBlock)) {
        err = "block count mismatch";
        return false;
    }
    if (off > file.size() || len > file.size() - off) {
        err = "truncated image";
        return false;
    }
    vol.blocks.assign(file.data() + off, file.data() + off + len);
    vol.wrapped_2mg = true;
    return validate_header(vol, err);
}

} // namespace

bool pro_parse_size(const std::string &spec, uint16_t &blocks, std::string &err)
{
    std::string s = lower_copy(spec);
    if (s == "140k" || s == "140kb") blocks = 280;
    else if (s == "800k" || s == "800kb") blocks = 1600;
    else if (s == "32m" || s == "32mb") blocks = 65535;
    else {
        err = "bad size " + spec;
        return false;
    }
    return true;
}

bool pro_create(ProVolume &vol, const std::string &name_in, uint16_t nblocks, std::string &err)
{
    std::string name = upper_copy(name_in);
    if (!valid_name(name)) {
        err = "invalid name";
        return false;
    }
    if (nblocks < 7) {
        err = "volume too small";
        return false;
    }
    uint32_t span = bitmap_span(nblocks);
    uint32_t used_end = 6 + span;
    if (used_end > nblocks) {
        err = "volume too small";
        return false;
    }
    vol.blocks.assign(static_cast<size_t>(nblocks) * kBlock, 0);
    vol.wrapped_2mg = false;

    uint16_t date = 0;
    uint16_t tim = 0;
    prodos_now(date, tim);

    uint8_t *b2 = at(vol, 2, 0);
    w16(b2 + 0, 0);
    w16(b2 + 2, 3);
    uint8_t *h = b2 + 4;
    put_name(h, kVolHdr, name);
    w16(h + 0x12, date);
    w16(h + 0x14, tim);
    w16(h + 0x18, date);
    w16(h + 0x1a, tim);
    h[0x1c] = 0;
    h[0x1d] = 0;
    h[0x1e] = kAccess;
    h[0x1f] = kEntry;
    h[0x20] = kSlots;
    w16(h + 0x21, 0);
    w16(h + 0x23, 6);
    w16(h + 0x25, nblocks);

    w16(at(vol, 3, 0), 2);
    w16(at(vol, 3, 2), 4);
    w16(at(vol, 4, 0), 3);
    w16(at(vol, 4, 2), 5);
    w16(at(vol, 5, 0), 4);
    w16(at(vol, 5, 2), 0);

    /* Boot blocks stay zero: the volume mounts and is not bootable.
       Blocks before the first free bit are the boot blocks, the four
       directory blocks, and the bitmap. */
    for (uint32_t b = used_end; b < nblocks; b++) set_bit(vol, static_cast<uint16_t>(b), true);
    return true;
}

bool pro_load(ProVolume &vol, const std::string &path, std::string &err)
{
    std::vector<uint8_t> file;
    if (!read_host(path, file, err)) return false;
    std::string why;
    bool ok = false;
    if (file.size() >= 4 && std::memcmp(file.data(), "2IMG", 4) == 0) ok = load_2mg(file, vol, why);
    else {
        vol.blocks = std::move(file);
        vol.wrapped_2mg = false;
        ok = validate_header(vol, why);
    }
    if (!ok) {
        err = path + ": " + why;
        return false;
    }
    return true;
}

bool pro_save(const ProVolume &vol, const std::string &path, std::string &err)
{
    if (vol.blocks.empty() || vol.blocks.size() % kBlock != 0) {
        err = path + ": not a ProDOS volume";
        return false;
    }
    if (ends_ci(path, ".2mg") || ends_ci(path, ".2img")) {
        uint32_t nblocks = static_cast<uint32_t>(vol.blocks.size() / kBlock);
        std::vector<uint8_t> out(64 + vol.blocks.size(), 0);
        std::memcpy(out.data(), "2IMG", 4);
        std::memcpy(out.data() + 4, "qpro", 4);
        w16(out.data() + 0x08, 64);
        w16(out.data() + 0x0a, 1);
        w32(out.data() + 0x0c, 1);
        w32(out.data() + 0x14, nblocks);
        w32(out.data() + 0x18, 64);
        w32(out.data() + 0x1c, static_cast<uint32_t>(vol.blocks.size()));
        std::memcpy(out.data() + 64, vol.blocks.data(), vol.blocks.size());
        return write_host(path, out, err);
    }
    return write_host(path, vol.blocks, err);
}

bool pro_write_boot(ProVolume &vol, const std::vector<uint8_t> &boot, std::string &err)
{
    if (!ready(vol, err)) return false;
    if (boot.size() != 1024) {
        err = "boot image must be 1024 bytes";
        return false;
    }
    std::memcpy(at(vol, 0, 0), boot.data(), kBlock);
    std::memcpy(at(vol, 1, 0), boot.data() + kBlock, kBlock);
    return true;
}

std::string pro_volume_name(const ProVolume &vol)
{
    return volume_name_of(vol);
}

uint16_t pro_total_blocks(const ProVolume &vol)
{
    return total_of(vol);
}

uint16_t pro_free_blocks(const ProVolume &vol)
{
    if (!in_range(vol, 2)) return 0;
    uint16_t total = total_of(vol);
    uint16_t n = 0;
    for (uint32_t b = 0; b < total; b++) {
        if (bit_is_free(vol, static_cast<uint16_t>(b))) n++;
    }
    return n;
}

bool pro_catalog(const ProVolume &vol, const std::string &path, std::vector<ProFileInfo> &out,
                 std::string &err)
{
    std::vector<std::string> parts;
    if (!split_path(vol, path, parts, err)) return false;
    Loc loc;
    if (!lookup(vol, parts, loc, err)) return false;
    if (loc.root || loc.storage == kDir) {
        uint16_t key = loc.root ? 2 : loc.key;
        return list_dir(vol, key, out, err);
    }
    out.clear();
    ProFileInfo info;
    fill_info(entry_at(vol, loc.slot.block, loc.slot.index), info);
    out.push_back(std::move(info));
    return true;
}

bool pro_add(ProVolume &vol, const std::string &path, const std::vector<uint8_t> &data,
             uint8_t type, uint16_t aux, std::string &err)
{
    if (data.size() > kMaxEof) {
        err = "file too large";
        return false;
    }
    std::vector<std::string> parts;
    if (!split_path(vol, path, parts, err)) return false;
    std::string name;
    Loc parent;
    if (!parent_of(vol, parts, name, parent, err)) return false;
    uint16_t dir_key = parent.root ? static_cast<uint16_t>(2) : parent.key;
    Slot existing;
    if (find_entry(vol, dir_key, name, existing, err)) {
        err = "already exists";
        return false;
    }
    if (err != "not found") return false;
    err.clear();

    bool need_grow = false;
    Slot hole;
    if (!find_hole(vol, dir_key, hole, need_grow, err)) return false;

    uint8_t storage = 0;
    uint16_t key = 0;
    uint16_t blocks_used = 0;
    std::vector<uint16_t> extra;
    if (!place_data(vol, data, storage, key, blocks_used, err)) return false;
    Slot slot = hole;
    if (need_grow) {
        uint16_t nb = 0;
        if (!alloc_block(vol, nb, err)) {
            std::vector<uint16_t> file_blocks;
            if (collect_file(vol, storage, key, file_blocks, err)) rollback(vol, file_blocks);
            err = "disk full";
            return false;
        }
        extra.push_back(nb);
        if (!in_range(vol, hole.last)) {
            rollback(vol, extra);
            std::vector<uint16_t> file_blocks;
            std::string ignore;
            if (collect_file(vol, storage, key, file_blocks, ignore)) rollback(vol, file_blocks);
            err = "bad directory";
            return false;
        }
        link_dir_block(vol, dir_key, hole.last, nb);
        slot.block = nb;
        slot.index = 0;
    }
    write_file_entry(vol, slot, name, storage, type, aux, key, blocks_used,
                     static_cast<uint32_t>(data.size()), dir_key);
    bump_count(vol, dir_key, 1);
    return true;
}

bool pro_get(const ProVolume &vol, const std::string &path, std::vector<uint8_t> &data,
             std::string &err)
{
    std::vector<std::string> parts;
    if (!split_path(vol, path, parts, err)) return false;
    Loc loc;
    if (!lookup(vol, parts, loc, err)) return false;
    if (loc.root || loc.storage == kDir) {
        err = "is a directory";
        return false;
    }
    if (loc.storage == kExtended) {
        err = "extended files are not supported";
        return false;
    }
    const uint8_t *e = entry_at(vol, loc.slot.block, loc.slot.index);
    return read_bytes(vol, loc.storage, loc.key, r24(e + 0x15), data, err);
}

bool pro_mkdir(ProVolume &vol, const std::string &path, std::string &err)
{
    std::vector<std::string> parts;
    if (!split_path(vol, path, parts, err)) return false;
    std::string name;
    Loc parent;
    if (!parent_of(vol, parts, name, parent, err)) return false;
    uint16_t dir_key = parent.root ? static_cast<uint16_t>(2) : parent.key;
    Slot existing;
    if (find_entry(vol, dir_key, name, existing, err)) {
        err = "already exists";
        return false;
    }
    if (err != "not found") return false;
    err.clear();

    bool need_grow = false;
    Slot hole;
    if (!find_hole(vol, dir_key, hole, need_grow, err)) return false;

    uint16_t nb = 0;
    if (!alloc_block(vol, nb, err)) return false;
    Slot slot = hole;
    if (need_grow) {
        if (hole.last == 0 || !in_range(vol, hole.last)) {
            free_block(vol, nb);
            err = "bad directory";
            return false;
        }
        uint16_t ext = 0;
        if (!alloc_block(vol, ext, err)) {
            free_block(vol, nb);
            return false;
        }
        link_dir_block(vol, dir_key, hole.last, ext);
        slot.block = ext;
        slot.index = 0;
    }

    uint16_t date = 0;
    uint16_t tim = 0;
    prodos_now(date, tim);

    uint8_t *sb = at(vol, nb, 0);
    std::memset(sb, 0, kBlock);
    w16(sb + 0, 0);
    w16(sb + 2, 0);
    uint8_t *h = sb + 4;
    put_name(h, kDirHdr, name);
    h[0x10] = 0x76;
    w16(h + 0x18, date);
    w16(h + 0x1a, tim);
    h[0x1c] = 5;
    h[0x1d] = 0;
    h[0x1e] = kAccess;
    h[0x1f] = kEntry;
    h[0x20] = kSlots;
    w16(h + 0x21, 0);
    /* +$23 is the block containing this directory's entry, not the
       parent directory's key block. +$25 is the 1-based slot. */
    w16(h + 0x23, slot.block);
    h[0x25] = static_cast<uint8_t>(slot.index + 1);
    h[0x26] = kEntry;

    write_file_entry(vol, slot, name, kDir, 0x0f, 0, nb, 1, kBlock, dir_key);
    bump_count(vol, dir_key, 1);
    return true;
}

bool pro_remove(ProVolume &vol, const std::string &path, std::string &err)
{
    std::vector<std::string> parts;
    if (!split_path(vol, path, parts, err)) return false;
    Loc loc;
    if (!lookup(vol, parts, loc, err)) return false;
    if (loc.root) {
        err = "cannot remove volume";
        return false;
    }
    std::vector<uint16_t> blocks;
    if (loc.storage == kDir) {
        if (!dir_is_empty(vol, loc.key, err)) return false;
        if (!collect_dir_blocks(vol, loc.key, blocks, err)) return false;
    } else if (loc.storage == kExtended) {
        err = "extended files are not supported";
        return false;
    } else if (loc.storage == kSeed || loc.storage == kSap || loc.storage == kTree) {
        if (!collect_file(vol, loc.storage, loc.key, blocks, err)) return false;
    } else {
        err = "unsupported storage";
        return false;
    }
    rollback(vol, blocks);
    std::memset(entry_at(vol, loc.slot.block, loc.slot.index), 0, kEntry);
    bump_count(vol, loc.parent_key, -1);
    return true;
}

bool pro_set_type(ProVolume &vol, const std::string &path, bool set_type, uint8_t type,
                  bool set_aux, uint16_t aux, std::string &err)
{
    if (!set_type && !set_aux) {
        err = "missing type";
        return false;
    }
    std::vector<std::string> parts;
    if (!split_path(vol, path, parts, err)) return false;
    Loc loc;
    if (!lookup(vol, parts, loc, err)) return false;
    if (loc.root) {
        err = "missing name";
        return false;
    }
    uint8_t *e = entry_at(vol, loc.slot.block, loc.slot.index);
    if (set_type) e[0x10] = type;
    if (set_aux) w16(e + 0x1f, aux);
    uint16_t date = 0;
    uint16_t tim = 0;
    prodos_now(date, tim);
    w16(e + 0x21, date);
    w16(e + 0x23, tim);
    return true;
}

} // namespace qasm
