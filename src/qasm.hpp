#pragma once

#include <cstdint>
#include <string>
#include <vector>

namespace qasm {

struct Options {
    bool case_sensitive = false;
    bool algebraic = false;
    int start_mx = 3;     /* 0–3; default %11 emulation */
    int start_xc = 2;     /* 0=6502, 1=65C02, 2=65816 */
    std::string output_path;    /* empty → <src>.bin or DSK name */
    std::string listing_path;   /* empty → <src>.lst */
    bool write_listing = true;
    bool write_object = true;
    std::vector<std::string> include_dirs; /* PUT/USE search path (-I) */
    std::string syntax; /* empty = identify. merlin, merlin32, orca, lisa, ca65 */
    bool dump_pcode = false;
};

struct Error {
    std::string file;
    int line = 0;
    std::string msg;
};

struct Result {
    std::vector<uint8_t> bytes;
    uint32_t org = 0;
    uint16_t filetype = 0x06;
    std::string dsk_name;
    std::string listing;
    std::string syntax; /* dialect that was lowered to pcode */
    std::string pcode;  /* filled when Options::dump_pcode is set */
    std::vector<Error> errors;
    bool ok() const { return errors.empty(); }
};

Result assemble_file(const std::string &path, const Options &opt = {});
Result assemble_string(const std::string &src, const std::string &name,
                       const Options &opt = {});

std::string default_bin_path(const std::string &src, const Result &r);
std::string default_lst_path(const std::string &src);

} // namespace qasm
