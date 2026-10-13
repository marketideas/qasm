#include "merlin.hpp"
#include "intern.hpp"

#include <algorithm>
#include <cstdio>
#include <fstream>
#include <future>
#include <iostream>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

namespace {

std::mutex io_mu;

void usage()
{
    std::cerr
        << "usage: merlin [options] file.s [file2.s ...]\n"
        << "  -o FILE            object output (single file only)\n"
        << "  -l FILE            listing path (single file only; default: <src>.lst)\n"
        << "  --no-lst           do not write a listing\n"
        << "  -j N, --jobs N     max parallel assemblies (default: HW threads)\n"
        << "  -I DIR              add PUT/USE search directory\n"
        << "  --case-sensitive\n"
        << "  --algebraic\n"
        << "  --syntax NAME      merlin, merlin32, orca, lisa, ca65, or auto\n"
        << "  --dump-pcode       write <file>.pcode beside the source\n";
}

bool write_file(const std::string &path, const void *data, size_t n, bool binary)
{
    std::ofstream out(path, binary ? std::ios::binary : std::ios::out);
    if (!out) {
        std::lock_guard<std::mutex> g(io_mu);
        std::cerr << path << ": cannot write\n";
        return false;
    }
    if (n)
        out.write(static_cast<const char *>(data), static_cast<std::streamsize>(n));
    return static_cast<bool>(out);
}

struct JobResult {
    std::string src;
    merlin::Result r;
    std::string bin_path;
    std::string lst_path;
};

JobResult assemble_one(std::string src, merlin::Options opt)
{
    JobResult jr;
    jr.src = src;
    jr.r = merlin::assemble_file(src, opt);

    {
        std::lock_guard<std::mutex> g(io_mu);
        for (const auto &e : jr.r.errors)
            std::cerr << (e.file.empty() ? src : e.file) << ":" << e.line
                      << ": " << e.msg << "\n";
    }

    if (opt.write_object) {
        jr.bin_path = opt.output_path.empty()
                          ? merlin::default_bin_path(src, jr.r)
                          : opt.output_path;
        if (!write_file(jr.bin_path, jr.r.bytes.data(), jr.r.bytes.size(), true))
            jr.r.errors.push_back({src, 0, "cannot write object"});
    }
    if (opt.write_listing) {
        jr.lst_path = opt.listing_path.empty()
                          ? merlin::default_lst_path(src)
                          : opt.listing_path;
        if (!write_file(jr.lst_path, jr.r.listing.data(), jr.r.listing.size(), false))
            jr.r.errors.push_back({src, 0, "cannot write listing"});
    }
    if (opt.dump_pcode) {
        std::string ppath = merlin::replace_ext(src, ".pcode");
        if (!write_file(ppath, jr.r.pcode.data(), jr.r.pcode.size(), false))
            jr.r.errors.push_back({src, 0, "cannot write pcode"});
    }

    {
        std::lock_guard<std::mutex> g(io_mu);
        char org[16];
        std::snprintf(org, sizeof(org), "%06X", jr.r.org);
        std::cout << src << ": assembled " << jr.r.bytes.size() << " bytes at $"
                  << org << " syntax=" << jr.r.syntax << " -> " << jr.bin_path;
        if (opt.write_listing)
            std::cout << "  lst " << jr.lst_path;
        char typ[8];
        std::snprintf(typ, sizeof(typ), "%02X", jr.r.filetype);
        std::cout << " (typ $" << typ << ")\n";
    }
    return jr;
}

} // namespace

int main(int argc, char **argv)
{
    merlin::Options opt;
    std::vector<std::string> files;
    unsigned jobs = std::thread::hardware_concurrency();
    if (jobs == 0) jobs = 1;

    for (int i = 1; i < argc; i++) {
        std::string a = argv[i];
        if (a == "-h" || a == "--help") {
            usage();
            return 0;
        }
        if (a == "-o" && i + 1 < argc) {
            opt.output_path = argv[++i];
        } else if (a == "-l" && i + 1 < argc) {
            opt.listing_path = argv[++i];
        } else if (a == "--no-lst") {
            opt.write_listing = false;
        } else if ((a == "-j" || a == "--jobs") && i + 1 < argc) {
            jobs = static_cast<unsigned>(std::stoul(argv[++i]));
            if (jobs == 0) jobs = 1;
        } else if (a == "-I" && i + 1 < argc) {
            opt.include_dirs.push_back(argv[++i]);
        } else if (a == "--case-sensitive") {
            opt.case_sensitive = true;
        } else if (a == "--algebraic") {
            opt.algebraic = true;
        } else if (a == "--syntax" && i + 1 < argc) {
            opt.syntax = argv[++i];
        } else if (a == "--dump-pcode") {
            opt.dump_pcode = true;
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
    if (files.size() > 1) {
        opt.output_path.clear();
        opt.listing_path.clear();
        /* PUT/USE fragments (allops-common-*.S, etc.) are not standalone.
           If they are also on the command line, skip them as top-level jobs. */
        auto basename = [](std::string p) {
            auto s = p.find_last_of("/\\");
            if (s != std::string::npos) p = p.substr(s + 1);
            return p;
        };
        std::vector<std::string> inc_names;
        for (const auto &src : files) {
            std::string err;
            std::string text = merlin::read_file(src, &err);
            if (text.empty() && !err.empty()) continue;
            for (const auto &ln : merlin::parse_source(text, src)) {
                if (merlin::icmp(ln.opcode, "PUT") != 0 &&
                    merlin::icmp(ln.opcode, "USE") != 0)
                    continue;
                std::string name = merlin::strip_quotes(ln.operand);
                if (name.empty()) continue;
                inc_names.push_back(name);
                inc_names.push_back(basename(name));
                std::string resolved =
                    merlin::resolve_include(name, src, opt.include_dirs);
                if (!resolved.empty()) {
                    inc_names.push_back(resolved);
                    inc_names.push_back(basename(resolved));
                }
            }
        }
        auto is_include = [&](const std::string &f) {
            std::string b = basename(f);
            for (const auto &n : inc_names) {
                if (merlin::icmp(f, n) == 0 || merlin::icmp(b, n) == 0 ||
                    merlin::icmp(b, basename(n)) == 0)
                    return true;
            }
            return false;
        };
        std::vector<std::string> top;
        top.reserve(files.size());
        for (const auto &f : files)
            if (!is_include(f)) top.push_back(f);
        if (!top.empty()) files = std::move(top);
    }

    std::vector<std::future<JobResult>> futs;
    std::vector<JobResult> done;
    size_t next = 0;
    int rc = 0;

    auto launch = [&]() {
        while (futs.size() < jobs && next < files.size()) {
            merlin::Options o = opt;
            futs.push_back(std::async(std::launch::async, assemble_one, files[next++], o));
        }
    };

    launch();
    while (!futs.empty()) {
        auto jr = futs.front().get();
        futs.erase(futs.begin());
        if (!jr.r.ok()) rc = 1;
        launch();
    }
    (void)done;
    return rc;
}
