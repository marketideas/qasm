#include "makebin.hpp"

#include <algorithm>
#include <cctype>
#include <cstddef>
#include <cstdio>
#include <string>

namespace qasm {
namespace {

constexpr uint64_t kMaxImage = 16ull * 1024ull * 1024ull;

std::string hex_addr(uint32_t v)
{
    char b[16];
    std::snprintf(b, sizeof(b), "$%X", v);
    return b;
}

std::string seg_label(const OmfSeg &s, size_t index)
{
    if (!s.name.empty()) return s.name;
    return "segment " + std::to_string(index + 1);
}

} // namespace

bool parse_address(const std::string &text, uint32_t &out, std::string &err)
{
    std::string s = text;
    size_t a = 0;
    while (a < s.size() && std::isspace(static_cast<unsigned char>(s[a]))) a++;
    size_t b = s.size();
    while (b > a && std::isspace(static_cast<unsigned char>(s[b - 1]))) b--;
    s = s.substr(a, b - a);
    if (s.empty()) {
        err = "missing address";
        return false;
    }
    if (s[0] == '$') s.erase(s.begin());
    else if (s.size() > 2 && s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) s.erase(0, 2);
    if (s.empty()) {
        err = "missing address";
        return false;
    }
    uint64_t v = 0;
    for (char c : s) {
        int d;
        if (c >= '0' && c <= '9') d = c - '0';
        else if (c >= 'a' && c <= 'f') d = c - 'a' + 10;
        else if (c >= 'A' && c <= 'F') d = c - 'A' + 10;
        else {
            err = "bad address " + text;
            return false;
        }
        v = (v << 4) | static_cast<uint64_t>(d);
        if (v > 0xFFFFFFFFull) {
            err = "address does not fit in 32 bits";
            return false;
        }
    }
    out = static_cast<uint32_t>(v);
    return true;
}

bool make_bin(const OmfFile &file, bool org_set, uint32_t org, BinImage &out, std::string &err)
{
    out = BinImage{};
    if (file.segs.empty()) {
        err = "OMF file has no segments";
        return false;
    }
    if (file.object) {
        err = "OMF file is an object, not a load file";
        return false;
    }
    for (size_t i = 0; i < file.segs.size(); i++) {
        const OmfSeg &s = file.segs[i];
        if (!s.relocs.empty() || !s.fixups.empty()) {
            err = "segment " + seg_label(s, i) + " still has relocations";
            return false;
        }
    }

    bool any = false;
    uint32_t low = 0;
    for (const auto &s : file.segs) {
        if (s.image.empty()) continue;
        if (!any || s.org < low) low = s.org;
        any = true;
    }
    if (!any) {
        out.org = org_set ? org : 0;
        return true;
    }
    uint32_t base = org_set ? org : low;

    struct Span {
        uint64_t at = 0;
        size_t index = 0;
    };
    std::vector<Span> spans;
    uint64_t span = 0;
    for (size_t i = 0; i < file.segs.size(); i++) {
        const OmfSeg &s = file.segs[i];
        if (s.image.empty()) continue;
        if (s.org < base) {
            err = "segment " + seg_label(s, i) + " starts at " + hex_addr(s.org) +
                  ", before org " + hex_addr(base);
            return false;
        }
        uint64_t at = static_cast<uint64_t>(s.org) - base;
        uint64_t end = at + s.image.size();
        if (end > kMaxImage) {
            err = "image is larger than 16MB";
            return false;
        }
        spans.push_back({at, i});
        if (end > span) span = end;
    }
    std::sort(spans.begin(), spans.end(),
              [](const Span &a, const Span &b) { return a.at < b.at; });
    uint64_t covered = 0;
    size_t prev = 0;
    for (size_t n = 0; n < spans.size(); n++) {
        const Span &sp = spans[n];
        if (n > 0 && sp.at < covered) {
            err = "segment " + seg_label(file.segs[sp.index], sp.index) + " overlaps segment " +
                  seg_label(file.segs[prev], prev);
            return false;
        }
        covered = sp.at + file.segs[sp.index].image.size();
        prev = sp.index;
    }

    out.org = base;
    out.bytes.assign(static_cast<size_t>(span), 0);
    for (const auto &sp : spans) {
        const auto &img = file.segs[sp.index].image;
        std::copy(img.begin(), img.end(), out.bytes.begin() + static_cast<std::ptrdiff_t>(sp.at));
    }
    return true;
}

} // namespace qasm
