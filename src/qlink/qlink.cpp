/* qlink: OMF 1.0 and 2.0 linker. Reads a link script directly. */

#include "link.hpp"

#include <iostream>
#include <string>
#include <vector>

const char *qlink_version_string();

namespace {

void usage()
{
    std::cerr
        << "usage: qlink [options] script.link [script2.link ...]\n"
        << "  -V, --version      print version and exit\n"
        << "  -h, --help         print this help and exit\n";
}

} // namespace

int main(int argc, char **argv)
{
    std::vector<std::string> scripts;
    for (int i = 1; i < argc; i++) {
        std::string a = argv[i];
        if (a == "-h" || a == "--help") {
            usage();
            return 0;
        }
        if (a == "-V" || a == "--version") {
            std::cout << qlink_version_string() << "\n";
            return 0;
        }
        if (!a.empty() && a[0] == '-') {
            std::cerr << "unknown option " << a << "\n";
            usage();
            return 2;
        }
        scripts.push_back(a);
    }
    if (scripts.empty()) {
        usage();
        return 2;
    }
    int rc = 0;
    for (const auto &path : scripts) {
        qasm::LinkOutput out = qasm::link_script(path, std::cout);
        if (!out.ok()) {
            for (const auto &e : out.errors)
                std::cerr << e << "\n";
            rc = 1;
        }
    }
    return rc;
}
