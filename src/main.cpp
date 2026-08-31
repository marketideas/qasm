#include "merlin.hpp"

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
        << "  --algebraic\n";
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

    {
        std::lock_guard<std::mutex> g(io_mu);
        char org[16];
        std::snprintf(org, sizeof(org), "%06X", jr.r.org);
        std::cout << src << ": assembled " << jr.r.bytes.size() << " bytes at $"
                  << org << " -> " << jr.bin_path;
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
