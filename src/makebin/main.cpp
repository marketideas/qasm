/* makeBin: raw image from an OMF load file. */

#include "makebin.hpp"

#include <cstdio>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

const char *makebin_version_string();

namespace {

void usage()
{
    std::cerr
        << "usage: makeBin [options] loadfile [loadfile...]\n"
        << "  -o FILE            output image (one load file only; - or stdout)\n"
        << "  -org ADDR          address of the first output byte ($2000, 0x2000, or hex)\n"
        << "                     default: the lowest segment address\n"
        << "  -V, --version      print version and exit\n"
        << "  -h, --help         print this help and exit\n"
        << "  With no -o, each load file is replaced by its raw image.\n";
}

bool is_stdout_name(const std::string &path)
{
    if (path == "-") return true;
    if (path.size() != 6) return false;
    const char *s = "stdout";
    for (size_t i = 0; i < 6; i++) {
        char c = path[i];
        if (c >= 'A' && c <= 'Z') c = static_cast<char>(c - 'A' + 'a');
        if (c != s[i]) return false;
    }
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

bool write_file(const std::string &path, const std::vector<uint8_t> &bytes, std::string &err)
{
    std::ofstream out(path, std::ios::binary);
    if (!out) {
        err = path + ": cannot write";
        return false;
    }
    if (!bytes.empty())
        out.write(reinterpret_cast<const char *>(bytes.data()),
                  static_cast<std::streamsize>(bytes.size()));
    if (!out) {
        err = path + ": cannot write";
        return false;
    }
    return true;
}

bool write_stdout(const std::vector<uint8_t> &bytes)
{
    if (bytes.empty()) return true;
    size_t n = std::fwrite(bytes.data(), 1, bytes.size(), stdout);
    return n == bytes.size() && std::fflush(stdout) == 0;
}

void print_summary(std::ostream &out, const std::string &src, const qasm::BinImage &image,
                   const std::string &dest)
{
    char org[16];
    std::snprintf(org, sizeof(org), "%06X", image.org);
    out << src << ": " << image.bytes.size() << " bytes at $" << org << " -> " << dest << "\n";
}

} // namespace

int main(int argc, char **argv)
{
    std::vector<std::string> files;
    std::string out_path;
    bool out_set = false;
    bool org_set = false;
    uint32_t org = 0;

    for (int i = 1; i < argc; i++) {
        std::string a = argv[i];
        if (a == "-h" || a == "--help") {
            usage();
            return 0;
        }
        if (a == "-V" || a == "--version") {
            std::cout << makebin_version_string() << "\n";
            return 0;
        }
        if (a == "-o" && i + 1 < argc) {
            out_path = argv[++i];
            out_set = true;
        } else if (a == "-org" && i + 1 < argc) {
            std::string err;
            if (!qasm::parse_address(argv[++i], org, err)) {
                std::cerr << err << "\n";
                return 2;
            }
            org_set = true;
        } else if (!a.empty() && a[0] == '-') {
            std::cerr << "unknown option " << a << "\n";
            usage();
            return 2;
        } else {
            files.push_back(a);
        }
    }
    if (files.empty()) {
        usage();
        return 2;
    }
    if (out_set && files.size() != 1) {
        std::cerr << "-o applies to a single load file\n";
        return 2;
    }

    int rc = 0;
    for (const auto &path : files) {
        std::vector<uint8_t> buf;
        std::string err;
        if (!read_file(path, buf, err)) {
            std::cerr << err << "\n";
            rc = 1;
            continue;
        }
        qasm::OmfFile file;
        if (!qasm::omf_read(buf, file, err)) {
            std::cerr << path << ": " << err << "\n";
            rc = 1;
            continue;
        }
        qasm::BinImage image;
        if (!qasm::make_bin(file, org_set, org, image, err)) {
            std::cerr << path << ": " << err << "\n";
            rc = 1;
            continue;
        }

        bool to_stdout = out_set && is_stdout_name(out_path);
        std::string dest = to_stdout ? "stdout" : (out_set ? out_path : path);
        if (to_stdout) {
            if (!write_stdout(image.bytes)) {
                std::cerr << "stdout: cannot write\n";
                rc = 1;
                continue;
            }
            print_summary(std::cerr, path, image, dest);
            continue;
        }
        if (!out_set || dest == path) {
            std::string tmp = path + ".makebin-tmp";
            if (!write_file(tmp, image.bytes, err) || std::rename(tmp.c_str(), path.c_str()) != 0) {
                std::remove(tmp.c_str());
                std::cerr << (err.empty() ? path + ": cannot replace" : err) << "\n";
                rc = 1;
                continue;
            }
        } else if (!write_file(dest, image.bytes, err)) {
            std::cerr << err << "\n";
            rc = 1;
            continue;
        }
        print_summary(std::cout, path, image, dest);
    }
    return rc;
}
