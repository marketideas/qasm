#include "intern.hpp"

#include <algorithm>
#include <cctype>
#include <fstream>
#include <iterator>

namespace qasm {

int icmp(const char *a, const char *b)
{
    if (!a) a = "";
    if (!b) b = "";
    for (;;) {
        unsigned char ca = static_cast<unsigned char>(*a++);
        unsigned char cb = static_cast<unsigned char>(*b++);
        int d = std::tolower(ca) - std::tolower(cb);
        if (d != 0 || ca == 0) return d;
    }
}

int icmp(const std::string &a, const std::string &b)
{
    return icmp(a.c_str(), b.c_str());
}

int nicmp(const std::string &a, const char *b, size_t n)
{
    size_t i = 0;
    while (i < n) {
        unsigned char ca = i < a.size() ? static_cast<unsigned char>(a[i]) : 0;
        unsigned char cb = static_cast<unsigned char>(b[i]);
        int d = std::tolower(ca) - std::tolower(cb);
        if (d != 0 || ca == 0) return d;
        i++;
    }
    return 0;
}

std::string trim_copy(std::string s)
{
    auto notsp = [](unsigned char c) {
        return !(std::isspace(c) || c == 0xA0);
    };
    while (!s.empty() && !notsp(static_cast<unsigned char>(s.front())))
        s.erase(s.begin());
    while (!s.empty() && !notsp(static_cast<unsigned char>(s.back())))
        s.pop_back();
    return s;
}

bool is_eol(unsigned char c)
{
    return c == 0x0A || c == 0x0D || c == 0x8D;
}

bool is_field_tab(unsigned char c)
{
    return c == 0xA0 || c == 0x09 || c == 0x89;
}

unsigned char to_ascii(unsigned char c)
{
    return static_cast<unsigned char>(c & 0x7F);
}

std::string read_file(const std::string &path, std::string *err)
{
    std::ifstream in(path, std::ios::binary);
    if (!in) {
        if (err) *err = "cannot read file";
        return {};
    }
    std::string data((std::istreambuf_iterator<char>(in)),
                     std::istreambuf_iterator<char>());
    return data;
}

std::string replace_ext(const std::string &path, const std::string &ext)
{
    auto slash = path.find_last_of("/\\");
    auto dot = path.find_last_of('.');
    if (dot != std::string::npos && (slash == std::string::npos || dot > slash))
        return path.substr(0, dot) + ext;
    return path + ext;
}

std::string default_bin_path(const std::string &src, const Result &r)
{
    if (!r.dsk_name.empty()) return r.dsk_name;
    return replace_ext(src, ".bin");
}

std::string default_lst_path(const std::string &src)
{
    return replace_ext(src, ".lst");
}

std::string dirname_of(const std::string &path)
{
    auto s = path.find_last_of("/\\");
    if (s == std::string::npos) return ".";
    if (s == 0) return "/";
    return path.substr(0, s);
}

std::string strip_quotes(std::string s)
{
    s = trim_copy(std::move(s));
    if (s.size() >= 2 && (s.front() == '"' || s.front() == '\'') && s.back() == s.front())
        return s.substr(1, s.size() - 2);
    return s;
}

bool file_readable(const std::string &path)
{
    std::ifstream in(path, std::ios::binary);
    return static_cast<bool>(in);
}

static std::string join_path(const std::string &dir, const std::string &name)
{
    if (dir.empty() || dir == ".") return name;
    char sep = '/';
    if (!dir.empty() && (dir.back() == '/' || dir.back() == '\\'))
        return dir + name;
    return dir + sep + name;
}

std::string resolve_include(const std::string &name0, const std::string &from_file,
                            const std::vector<std::string> &include_dirs)
{
    std::string name = strip_quotes(name0);
    if (name.empty()) return {};

    /* Merlin 16+ prefix form "4/Mem.Macs" — also try without the N/ */
    std::string stripped = name;
    if (name.size() >= 3 && std::isdigit(static_cast<unsigned char>(name[0])) &&
        name[1] == '/')
        stripped = name.substr(2);

    std::vector<std::string> dirs;
    dirs.push_back(dirname_of(from_file));
    dirs.insert(dirs.end(), include_dirs.begin(), include_dirs.end());
    dirs.push_back(".");

    std::vector<std::string> cands;
    auto add = [&](const std::string &n) {
        if (n.empty()) return;
        cands.push_back(n);
        cands.push_back(n + ".s");
        cands.push_back(n + ".S");
        cands.push_back(n + ".Macs");
        cands.push_back(n + ".Macs.s");
    };
    add(name);
    if (stripped != name) add(stripped);

    for (const auto &d : dirs) {
        for (const auto &c : cands) {
            std::string p = join_path(d, c);
            if (file_readable(p)) return p;
        }
    }
    /* absolute / already-relative last try */
    for (const auto &c : cands)
        if (file_readable(c)) return c;
    return {};
}

} // namespace qasm
