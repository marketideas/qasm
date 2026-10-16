#pragma once

/* Apple IIgs OMF 1.0 and 2.0 segments.
   Record bodies follow the layouts read by 6502bench SourceGen
   (faddenSoft, Apache-2.0): CONST, LCONST, DS, GLOBAL/LOCAL, RELEXPR,
   RELOC, and INTERSEG. Numbers are little-endian. NUMLEN is 4.
   Label strings are Pascal (LABLEN 0). */

#include <cstdint>
#include <string>
#include <vector>

namespace qasm {

struct OmfSym {
    std::string name;
    uint32_t offset = 0; /* location counter when the record is seen */
    bool global = true;  /* GLOBAL, or LOCAL when false */
};

/* Object-file patch. The expression is symbol + addend, then integer-divided
   by divisor (1, 256, or 65536). The linker stores the low `width` bytes. */
struct OmfFix {
    uint32_t at = 0;
    uint8_t width = 2;
    std::string symbol;
    int32_t addend = 0;
    int32_t divisor = 1;
};

/* Load-file relocation. file == 0 is a RELOC (add this segment's load
   address). Otherwise it is an INTERSEG to file/seg (both 1-based). */
struct OmfReloc {
    uint32_t at = 0;
    uint8_t width = 2;
    int8_t shift = 0;
    uint32_t disp = 0;
    uint16_t file = 0;
    uint16_t seg = 0;
};

struct OmfSeg {
    std::string name;
    uint16_t kind = 0; /* type in the low 5 bits, attribute flags above */
    uint32_t org = 0;
    uint32_t align = 0;
    uint32_t entry = 0;
    uint16_t segnum = 0;
    std::vector<uint8_t> image;
    std::vector<OmfSym> syms;
    std::vector<OmfFix> fixups;
    std::vector<OmfReloc> relocs;
};

struct OmfFile {
    int version = 2; /* 1 or 2 */
    bool object = false; /* object/library records; otherwise a load file */
    std::vector<OmfSeg> segs;
};

bool omf_write(const OmfFile &file, std::vector<uint8_t> &out, std::string &err);
bool omf_read(const std::vector<uint8_t> &in, OmfFile &file, std::string &err);

} // namespace qasm
