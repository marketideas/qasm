#pragma once

/* Print an Apple IIgs OMF 1.0 or 2.0 file. The dump includes the segment
   header fields and every body record, including RELOC and INTERSEG. */

#include <cstdint>
#include <iosfwd>
#include <string>
#include <vector>

namespace qasm {

bool omf_dump(const std::vector<uint8_t> &in, const std::string &label,
              std::ostream &out, std::string &err);

} // namespace qasm
