#pragma once

/* qlink script and OMF placement.
   The script is not assembled and is not handed to make. '#' comments run
   to the end of the line. `name = value` and `$(name)` are variables.
   `include file` pastes another script. A target is `output: inputs`.
   The indented body is ver, typ, org, entry, lib, seg, +file, ds, and end. */

#include "omf.hpp"

#include <iosfwd>
#include <string>
#include <vector>

namespace qasm {

struct LinkProduct {
    std::string path;
    uint32_t typ = 0;
    uint32_t aux = 0;
    bool typ_set = false;
    OmfFile file;
};

struct LinkOutput {
    std::vector<LinkProduct> products;
    std::vector<std::string> errors;
    bool ok() const { return errors.empty(); }
};

/* Paths in the script are relative to the script file. Outputs are written
   as each target is finished, so a later target can read an earlier one. */
LinkOutput link_script(const std::string &path, std::ostream &log);

} // namespace qasm
