#pragma once

/* Flatten an OMF load file into the raw image MakeBinIIGS writes.
   Byte 0 of the image is `org`. Gaps between segments are zero.
   A segment below `org`, an object file, or a segment that still has
   relocations is an error. */

#include "omf.hpp"

#include <cstdint>
#include <string>
#include <vector>

namespace qasm {

struct BinImage {
    uint32_t org = 0;
    std::vector<uint8_t> bytes;
};

/* `org_set` false uses the lowest segment address as byte 0. */
bool make_bin(const OmfFile &file, bool org_set, uint32_t org, BinImage &out, std::string &err);

/* `$2000`, `0x2000`, or hex digits. */
bool parse_address(const std::string &text, uint32_t &out, std::string &err);

} // namespace qasm
