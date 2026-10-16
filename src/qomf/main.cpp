/* qomf: print an OMF file, including its relocation records. */

#include "qomf.hpp"

#include <fstream>
#include <iostream>
#include <string>
#include <vector>

const char *qomf_version_string();

namespace {

void usage()
{
    std::cerr << "usage: qomf [options] file [file...]\n"
              << "  -V, --version      print version and exit\n"
              << "  -h, --help         print this help and exit\n";
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

} // namespace

int main(int argc, char **argv)
{
    std::vector<std::string> files;
    for (int i = 1; i < argc; i++) {
        std::string a = argv[i];
        if (a == "-h" || a == "--help") {
            usage();
            return 0;
        }
        if (a == "-V" || a == "--version") {
            std::cout << qomf_version_string() << "\n";
            return 0;
        }
        if (!a.empty() && a[0] == '-') {
            std::cerr << "unknown option " << a << "\n";
            usage();
            return 2;
        }
        files.push_back(a);
    }
    if (files.empty()) {
        usage();
        return 2;
    }

    int rc = 0;
    bool any = false;
    for (const auto &path : files) {
        if (any) std::cout << "\n";
        any = true;
        std::vector<uint8_t> buf;
        std::string err;
        if (!read_file(path, buf, err)) {
            std::cerr << err << "\n";
            rc = 1;
            continue;
        }
        if (!qasm::omf_dump(buf, path, std::cout, err)) {
            std::cerr << path << ": " << err << "\n";
            rc = 1;
        }
    }
    return rc;
}
