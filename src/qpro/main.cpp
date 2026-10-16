/* qpro: ProDOS volumes, directories, and file types. */

#include "qpro.hpp"

#include <cstdint>
#include <cstdio>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

const char *qpro_version_string();

namespace {

void usage()
{
    std::cerr
        << "usage: qpro create VOLUME -name NAME (-blocks N | -size SPEC)\n"
        << "       qpro cat VOLUME [PATH]\n"
        << "       qpro add VOLUME PATH HOSTFILE [-t TYPE] [-a AUX]\n"
        << "       qpro get VOLUME PATH HOSTFILE\n"
        << "       qpro rm VOLUME PATH\n"
        << "       qpro mkdir VOLUME PATH\n"
        << "       qpro typ VOLUME PATH [-t TYPE] [-a AUX]\n"
        << "       qpro boot VOLUME FILE\n"
        << "  -name NAME         volume name\n"
        << "  -blocks N          decimal block count (7 to 65535)\n"
        << "  -size SPEC         140k, 800k, or 32m\n"
        << "  -t TYPE            file type ($06, 0x06, or hex); add defaults to $06\n"
        << "  -a AUX             auxiliary type; add defaults to $0000\n"
        << "  -V, --version      print version and exit\n"
        << "  -h, --help         print this help and exit\n";
}

bool parse_hex(const std::string &text, uint32_t limit, uint32_t &out, std::string &err)
{
    std::string s = text;
    size_t a = 0;
    while (a < s.size() && (s[a] == ' ' || s[a] == '\t')) a++;
    size_t b = s.size();
    while (b > a && (s[b - 1] == ' ' || s[b - 1] == '\t')) b--;
    s = s.substr(a, b - a);
    if (s.empty()) {
        err = "missing value";
        return false;
    }
    if (s[0] == '$') s.erase(s.begin());
    else if (s.size() > 2 && s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) s.erase(0, 2);
    if (s.empty()) {
        err = "missing value";
        return false;
    }
    uint32_t v = 0;
    for (char c : s) {
        unsigned d;
        if (c >= '0' && c <= '9') d = static_cast<unsigned>(c - '0');
        else if (c >= 'a' && c <= 'f') d = static_cast<unsigned>(c - 'a' + 10);
        else if (c >= 'A' && c <= 'F') d = static_cast<unsigned>(c - 'A' + 10);
        else {
            err = "bad value " + text;
            return false;
        }
        if (v > (limit >> 4)) {
            err = "bad value " + text;
            return false;
        }
        v = (v << 4) | d;
        if (v > limit) {
            err = "bad value " + text;
            return false;
        }
    }
    out = v;
    return true;
}

bool parse_dec(const std::string &text, uint32_t &out, std::string &err)
{
    if (text.empty()) {
        err = "bad block count";
        return false;
    }
    uint32_t v = 0;
    for (char c : text) {
        if (c < '0' || c > '9') {
            err = "bad block count";
            return false;
        }
        unsigned d = static_cast<unsigned>(c - '0');
        if (v > (0xFFFFFFFFu - d) / 10u) {
            err = "bad block count";
            return false;
        }
        v = v * 10u + d;
    }
    out = v;
    return true;
}

bool read_file(const std::string &path, std::vector<uint8_t> &buf, std::string &err)
{
    std::ifstream in(path, std::ios::binary);
    if (!in) {
        err = path + ": cannot open";
        return false;
    }
    buf.assign(std::istreambuf_iterator<char>(in), std::istreambuf_iterator<char>());
    return true;
}

bool write_file(const std::string &path, const std::vector<uint8_t> &buf, std::string &err)
{
    std::ofstream out(path, std::ios::binary);
    if (!out) {
        err = path + ": cannot write";
        return false;
    }
    if (!buf.empty())
        out.write(reinterpret_cast<const char *>(buf.data()),
                  static_cast<std::streamsize>(buf.size()));
    if (!out) {
        err = path + ": cannot write";
        return false;
    }
    return true;
}

bool exists(const std::string &path)
{
    std::ifstream in(path, std::ios::binary);
    return static_cast<bool>(in);
}

std::string upper_copy(const std::string &s)
{
    std::string o = s;
    for (char &c : o) {
        if (c >= 'a' && c <= 'z') c = static_cast<char>(c - 'a' + 'A');
    }
    return o;
}

std::string catalog_title(const qasm::ProVolume &vol, const std::string &path)
{
    std::string name = qasm::pro_volume_name(vol);
    bool absolute = !path.empty() && path[0] == '/';
    std::vector<std::string> parts;
    std::string cur;
    auto flush = [&]() {
        if (cur.empty()) return;
        std::string u = upper_copy(cur);
        cur.clear();
        if (parts.empty() && absolute && u == name) return;
        parts.push_back(u);
    };
    for (char c : path) {
        if (c == '/') flush();
        else cur.push_back(c);
    }
    flush();
    std::string title = "/" + name;
    for (const auto &p : parts) title += "/" + p;
    return title;
}

void print_catalog(const qasm::ProVolume &vol, const std::string &path,
                   const std::vector<qasm::ProFileInfo> &ents)
{
    std::cout << catalog_title(vol, path) << "\n";
    std::cout << qasm::pro_total_blocks(vol) << " blocks, " << qasm::pro_free_blocks(vol)
              << " free\n\n";
    std::cout << " NAME             TYPE   AUX      EOF  BLOCKS\n";
    for (const auto &e : ents) {
        char line[80];
        std::snprintf(line, sizeof(line), " %-15s  %02X  %04X  %8u  %6u\n", e.name.c_str(), e.type,
                      e.aux, e.eof, static_cast<unsigned>(e.blocks));
        std::cout << line;
    }
}

struct Opt {
    std::vector<std::string> pos;
    std::string name;
    std::string size;
    bool blocks_set = false;
    uint32_t blocks = 0;
    bool type_set = false;
    uint32_t type = 0;
    bool aux_set = false;
    uint32_t aux = 0;
};

bool take_args(int argc, char **argv, int begin, Opt &opt, std::string &err)
{
    for (int i = begin; i < argc; i++) {
        std::string a = argv[i];
        if (a == "-name" && i + 1 < argc) opt.name = argv[++i];
        else if (a == "-blocks" && i + 1 < argc) {
            if (!parse_dec(argv[++i], opt.blocks, err)) return false;
            opt.blocks_set = true;
        } else if (a == "-size" && i + 1 < argc) opt.size = argv[++i];
        else if (a == "-t" && i + 1 < argc) {
            if (!parse_hex(argv[++i], 0xFF, opt.type, err)) return false;
            opt.type_set = true;
        } else if (a == "-a" && i + 1 < argc) {
            if (!parse_hex(argv[++i], 0xFFFF, opt.aux, err)) return false;
            opt.aux_set = true;
        } else if (!a.empty() && a[0] == '-') {
            err = "unknown option " + a;
            return false;
        } else opt.pos.push_back(a);
    }
    return true;
}

void op_error(const std::string &path, const std::string &err)
{
    if (err.compare(0, path.size() + 2, path + ": ") == 0) std::cerr << err << "\n";
    else std::cerr << path << ": " << err << "\n";
}

int cmd_create(const Opt &opt)
{
    bool have_blocks = opt.blocks_set;
    bool have_size = !opt.size.empty();
    if (opt.pos.size() != 1 || opt.name.empty() || have_blocks == have_size) {
        usage();
        return 2;
    }
    const std::string &path = opt.pos[0];
    if (exists(path)) {
        std::cerr << path << ": already exists\n";
        return 1;
    }
    uint16_t blocks = 0;
    std::string err;
    if (opt.blocks_set) {
        if (opt.blocks < 7) {
            std::cerr << path << ": volume too small\n";
            return 1;
        }
        if (opt.blocks > 65535) {
            std::cerr << path << ": block count out of range\n";
            return 1;
        }
        blocks = static_cast<uint16_t>(opt.blocks);
    } else if (!qasm::pro_parse_size(opt.size, blocks, err)) {
        std::cerr << err << "\n";
        usage();
        return 2;
    }
    qasm::ProVolume vol;
    if (!qasm::pro_create(vol, opt.name, blocks, err)) {
        op_error(path, err);
        return 1;
    }
    if (!qasm::pro_save(vol, path, err)) {
        op_error(path, err);
        return 1;
    }
    std::cout << path << ": created volume " << qasm::pro_volume_name(vol) << ", " << blocks
              << " blocks\n";
    return 0;
}

int cmd_cat(const Opt &opt)
{
    if (opt.pos.size() < 1 || opt.pos.size() > 2) {
        usage();
        return 2;
    }
    qasm::ProVolume vol;
    std::string err;
    if (!qasm::pro_load(vol, opt.pos[0], err)) {
        op_error(opt.pos[0], err);
        return 1;
    }
    std::string path = opt.pos.size() == 2 ? opt.pos[1] : "";
    std::vector<qasm::ProFileInfo> ents;
    if (!qasm::pro_catalog(vol, path, ents, err)) {
        op_error(opt.pos[0], err);
        return 1;
    }
    print_catalog(vol, path, ents);
    return 0;
}

int cmd_add(const Opt &opt)
{
    if (opt.pos.size() != 3) {
        usage();
        return 2;
    }
    qasm::ProVolume vol;
    std::string err;
    if (!qasm::pro_load(vol, opt.pos[0], err)) {
        op_error(opt.pos[0], err);
        return 1;
    }
    std::vector<uint8_t> data;
    if (!read_file(opt.pos[2], data, err)) {
        std::cerr << err << "\n";
        return 1;
    }
    uint8_t type = opt.type_set ? static_cast<uint8_t>(opt.type) : 0x06;
    uint16_t aux = opt.aux_set ? static_cast<uint16_t>(opt.aux) : 0;
    if (!qasm::pro_add(vol, opt.pos[1], data, type, aux, err)) {
        op_error(opt.pos[0], err);
        return 1;
    }
    if (!qasm::pro_save(vol, opt.pos[0], err)) {
        op_error(opt.pos[0], err);
        return 1;
    }
    std::cout << opt.pos[0] << ": added " << catalog_title(vol, opt.pos[1]) << ", " << data.size()
              << " bytes\n";
    return 0;
}

int cmd_get(const Opt &opt)
{
    if (opt.pos.size() != 3) {
        usage();
        return 2;
    }
    qasm::ProVolume vol;
    std::string err;
    if (!qasm::pro_load(vol, opt.pos[0], err)) {
        op_error(opt.pos[0], err);
        return 1;
    }
    std::vector<uint8_t> data;
    if (!qasm::pro_get(vol, opt.pos[1], data, err)) {
        op_error(opt.pos[0], err);
        return 1;
    }
    if (!write_file(opt.pos[2], data, err)) {
        std::cerr << err << "\n";
        return 1;
    }
    std::cout << opt.pos[0] << ": " << catalog_title(vol, opt.pos[1]) << " -> " << opt.pos[2]
              << ", " << data.size() << " bytes\n";
    return 0;
}

int cmd_rm(const Opt &opt)
{
    if (opt.pos.size() != 2) {
        usage();
        return 2;
    }
    qasm::ProVolume vol;
    std::string err;
    if (!qasm::pro_load(vol, opt.pos[0], err)) {
        op_error(opt.pos[0], err);
        return 1;
    }
    if (!qasm::pro_remove(vol, opt.pos[1], err)) {
        op_error(opt.pos[0], err);
        return 1;
    }
    if (!qasm::pro_save(vol, opt.pos[0], err)) {
        op_error(opt.pos[0], err);
        return 1;
    }
    std::cout << opt.pos[0] << ": removed " << catalog_title(vol, opt.pos[1]) << "\n";
    return 0;
}

int cmd_mkdir(const Opt &opt)
{
    if (opt.pos.size() != 2) {
        usage();
        return 2;
    }
    qasm::ProVolume vol;
    std::string err;
    if (!qasm::pro_load(vol, opt.pos[0], err)) {
        op_error(opt.pos[0], err);
        return 1;
    }
    if (!qasm::pro_mkdir(vol, opt.pos[1], err)) {
        op_error(opt.pos[0], err);
        return 1;
    }
    if (!qasm::pro_save(vol, opt.pos[0], err)) {
        op_error(opt.pos[0], err);
        return 1;
    }
    std::cout << opt.pos[0] << ": created " << catalog_title(vol, opt.pos[1]) << "\n";
    return 0;
}

int cmd_typ(const Opt &opt)
{
    if (opt.pos.size() != 2 || (!opt.type_set && !opt.aux_set)) {
        usage();
        return 2;
    }
    qasm::ProVolume vol;
    std::string err;
    if (!qasm::pro_load(vol, opt.pos[0], err)) {
        op_error(opt.pos[0], err);
        return 1;
    }
    if (!qasm::pro_set_type(vol, opt.pos[1], opt.type_set, static_cast<uint8_t>(opt.type),
                            opt.aux_set, static_cast<uint16_t>(opt.aux), err)) {
        op_error(opt.pos[0], err);
        return 1;
    }
    if (!qasm::pro_save(vol, opt.pos[0], err)) {
        op_error(opt.pos[0], err);
        return 1;
    }
    std::vector<qasm::ProFileInfo> ents;
    if (!qasm::pro_catalog(vol, opt.pos[1], ents, err) || ents.size() != 1) {
        std::cout << opt.pos[0] << ": set type\n";
        return 0;
    }
    char buf[64];
    std::snprintf(buf, sizeof(buf), "type $%02X aux $%04X", ents[0].type, ents[0].aux);
    std::cout << opt.pos[0] << ": " << catalog_title(vol, opt.pos[1]) << " " << buf << "\n";
    return 0;
}

int cmd_boot(const Opt &opt)
{
    if (opt.pos.size() != 2) {
        usage();
        return 2;
    }
    qasm::ProVolume vol;
    std::string err;
    if (!qasm::pro_load(vol, opt.pos[0], err)) {
        op_error(opt.pos[0], err);
        return 1;
    }
    std::vector<uint8_t> boot;
    if (!read_file(opt.pos[1], boot, err)) {
        std::cerr << err << "\n";
        return 1;
    }
    if (!qasm::pro_write_boot(vol, boot, err)) {
        op_error(opt.pos[0], err);
        return 1;
    }
    if (!qasm::pro_save(vol, opt.pos[0], err)) {
        op_error(opt.pos[0], err);
        return 1;
    }
    std::cout << opt.pos[0] << ": boot blocks, " << boot.size() << " bytes\n";
    return 0;
}

} // namespace

int main(int argc, char **argv)
{
    for (int i = 1; i < argc; i++) {
        std::string a = argv[i];
        if (a == "-h" || a == "--help") {
            usage();
            return 0;
        }
        if (a == "-V" || a == "--version") {
            std::cout << qpro_version_string() << "\n";
            return 0;
        }
    }
    if (argc < 2) {
        usage();
        return 2;
    }
    std::string cmd = argv[1];
    Opt opt;
    std::string err;
    if (!take_args(argc, argv, 2, opt, err)) {
        std::cerr << err << "\n";
        usage();
        return 2;
    }
    if (cmd == "create") return cmd_create(opt);
    if (cmd == "cat") return cmd_cat(opt);
    if (cmd == "add") return cmd_add(opt);
    if (cmd == "get") return cmd_get(opt);
    if (cmd == "rm") return cmd_rm(opt);
    if (cmd == "mkdir") return cmd_mkdir(opt);
    if (cmd == "typ") return cmd_typ(opt);
    if (cmd == "boot") return cmd_boot(opt);
    std::cerr << "unknown command " << cmd << "\n";
    usage();
    return 2;
}
