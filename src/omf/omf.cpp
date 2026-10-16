#include "omf.hpp"

namespace qasm {
namespace {

void put_u8(std::vector<uint8_t> &b, uint8_t v) { b.push_back(v); }

void put_u16(std::vector<uint8_t> &b, uint16_t v)
{
    b.push_back(static_cast<uint8_t>(v & 0xFF));
    b.push_back(static_cast<uint8_t>((v >> 8) & 0xFF));
}

void put_u32(std::vector<uint8_t> &b, uint32_t v)
{
    b.push_back(static_cast<uint8_t>(v & 0xFF));
    b.push_back(static_cast<uint8_t>((v >> 8) & 0xFF));
    b.push_back(static_cast<uint8_t>((v >> 16) & 0xFF));
    b.push_back(static_cast<uint8_t>((v >> 24) & 0xFF));
}

void patch_u32(std::vector<uint8_t> &b, size_t at, uint32_t v)
{
    b[at] = static_cast<uint8_t>(v & 0xFF);
    b[at + 1] = static_cast<uint8_t>((v >> 8) & 0xFF);
    b[at + 2] = static_cast<uint8_t>((v >> 16) & 0xFF);
    b[at + 3] = static_cast<uint8_t>((v >> 24) & 0xFF);
}

uint32_t get_u32(const std::vector<uint8_t> &b, size_t at)
{
    return static_cast<uint32_t>(b[at]) |
           (static_cast<uint32_t>(b[at + 1]) << 8) |
           (static_cast<uint32_t>(b[at + 2]) << 16) |
           (static_cast<uint32_t>(b[at + 3]) << 24);
}

uint16_t get_u16(const std::vector<uint8_t> &b, size_t at)
{
    return static_cast<uint16_t>(b[at] | (b[at + 1] << 8));
}

bool put_label(std::vector<uint8_t> &b, const std::string &name, std::string &err)
{
    if (name.size() > 255) {
        err = "OMF label longer than 255 bytes";
        return false;
    }
    put_u8(b, static_cast<uint8_t>(name.size()));
    b.insert(b.end(), name.begin(), name.end());
    return true;
}

/* v1 TYPE packs the segment type and three attribute bits.
   Dynamic is $8000, private $4000, position-independent $2000.
   The other v2 attribute bits do not fit. */
bool v1_type(uint16_t kind, uint8_t &type, std::string &err)
{
    if (kind & 0x1F00) {
        err = "OMF 1.0 cannot store this segment kind";
        return false;
    }
    type = static_cast<uint8_t>(kind & 0x1F);
    if (kind & 0x2000) type = static_cast<uint8_t>(type | 0x20);
    if (kind & 0x4000) type = static_cast<uint8_t>(type | 0x40);
    if (kind & 0x8000) type = static_cast<uint8_t>(type | 0x80);
    return true;
}

bool write_expr(std::vector<uint8_t> &b, const OmfFix &fx, std::string &err)
{
    put_u8(b, 0x83); /* push label value */
    if (!put_label(b, fx.symbol, err)) return false;
    if (fx.addend != 0) {
        put_u8(b, 0x81); /* push constant */
        put_u32(b, static_cast<uint32_t>(fx.addend));
        put_u8(b, 0x01); /* add */
    }
    if (fx.divisor == 256 || fx.divisor == 65536) {
        put_u8(b, 0x81);
        put_u32(b, static_cast<uint32_t>(fx.divisor));
        put_u8(b, 0x04); /* integer divide */
    } else if (fx.divisor != 1) {
        err = "OMF fixup divisor is not 1, 256, or 65536";
        return false;
    }
    put_u8(b, 0x00); /* end expression */
    return true;
}

bool write_object_body(std::vector<uint8_t> &b, const OmfSeg &seg, int version, std::string &err)
{
    std::vector<OmfSym> syms = seg.syms;
    /* Stable by offset; equal offsets keep source order. */
    for (size_t i = 1; i < syms.size(); i++) {
        OmfSym s = syms[i];
        size_t j = i;
        while (j > 0 && syms[j - 1].offset > s.offset) {
            syms[j] = syms[j - 1];
            j--;
        }
        syms[j] = s;
    }
    size_t pos = 0, si = 0;
    while (pos < seg.image.size() || si < syms.size()) {
        while (si < syms.size() && syms[si].offset <= pos) {
            if (syms[si].offset != pos) {
                err = "symbol offset is past the bytes already written";
                return false;
            }
            put_u8(b, syms[si].global ? 0xE6 : 0xEF);
            if (!put_label(b, syms[si].name, err)) return false;
            if (version <= 1) {
                put_u8(b, 0); /* length unknown */
            } else {
                put_u16(b, 0);
            }
            put_u8(b, 0x4E); /* type 'N' */
            put_u8(b, 0);
            si++;
        }
        if (pos >= seg.image.size()) break;
        size_t next = seg.image.size();
        if (si < syms.size() && syms[si].offset < next) next = syms[si].offset;
        while (pos < next) {
            size_t n = next - pos;
            if (n > 0xDF) n = 0xDF;
            put_u8(b, static_cast<uint8_t>(n));
            b.insert(b.end(), seg.image.begin() + static_cast<std::ptrdiff_t>(pos),
                     seg.image.begin() + static_cast<std::ptrdiff_t>(pos + n));
            pos += n;
        }
    }
    for (const auto &fx : seg.fixups) {
        if (fx.width < 1 || fx.width > 4) {
            err = "fixup width must be 1 to 4";
            return false;
        }
        put_u8(b, 0xEE); /* RELEXPR */
        put_u8(b, fx.width);
        put_u32(b, fx.at);
        if (!write_expr(b, fx, err)) return false;
    }
    put_u8(b, 0x00); /* END */
    return true;
}

bool write_load_body(std::vector<uint8_t> &b, const OmfSeg &seg, std::string &err)
{
    put_u8(b, 0xF2); /* LCONST */
    put_u32(b, static_cast<uint32_t>(seg.image.size()));
    b.insert(b.end(), seg.image.begin(), seg.image.end());
    for (const auto &r : seg.relocs) {
        if (r.width < 1 || r.width > 4) {
            err = "relocation width must be 1 to 4";
            return false;
        }
        if (r.file == 0) {
            put_u8(b, 0xE2); /* RELOC */
            put_u8(b, r.width);
            put_u8(b, static_cast<uint8_t>(r.shift));
            put_u32(b, r.at);
            put_u32(b, r.disp);
        } else {
            put_u8(b, 0xE3); /* INTERSEG */
            put_u8(b, r.width);
            put_u8(b, static_cast<uint8_t>(r.shift));
            put_u32(b, r.at);
            put_u16(b, r.file);
            put_u16(b, r.seg);
            put_u32(b, r.disp);
        }
    }
    put_u8(b, 0x00);
    return true;
}

struct Ev {
    bool is_sym = false;
    std::string sym;
    int32_t addend = 0;
    int32_t divisor = 1;
};

bool read_label(const std::vector<uint8_t> &in, size_t &i, size_t end, int lablen,
                std::string &name, std::string &err)
{
    size_t n = static_cast<size_t>(lablen);
    if (lablen == 0) {
        if (i >= end) {
            err = "OMF label runs off the record";
            return false;
        }
        n = in[i++];
    }
    if (i + n > end) {
        err = "OMF label runs off the record";
        return false;
    }
    name.assign(reinterpret_cast<const char *>(&in[i]), n);
    /* Fixed-width names are space padded. */
    while (!name.empty() && name.back() == ' ') name.pop_back();
    i += n;
    return true;
}

bool read_expr(const std::vector<uint8_t> &in, size_t &i, size_t end, int lablen,
               OmfFix &fx, std::string &err)
{
    std::vector<Ev> st;
    while (i < end) {
        uint8_t op = in[i++];
        if (op == 0x00) {
            if (st.size() != 1 || !st[0].is_sym) {
                err = "OMF expression is not a single label";
                return false;
            }
            fx.symbol = st[0].sym;
            fx.addend = st[0].addend;
            fx.divisor = st[0].divisor;
            return true;
        }
        if (op == 0x81) {
            if (i + 4 > end) {
                err = "OMF constant runs off the expression";
                return false;
            }
            Ev e;
            e.addend = static_cast<int32_t>(get_u32(in, i));
            i += 4;
            st.push_back(e);
            continue;
        }
        if (op == 0x83 || op == 0x82) {
            Ev e;
            e.is_sym = true;
            if (!read_label(in, i, end, lablen, e.sym, err)) return false;
            st.push_back(e);
            continue;
        }
        if (op == 0x01 || op == 0x02 || op == 0x04) {
            if (st.size() < 2) {
                err = "OMF expression stack underflow";
                return false;
            }
            Ev b = st.back();
            st.pop_back();
            Ev a = st.back();
            st.pop_back();
            Ev r;
            if (op == 0x04) {
                if (b.is_sym || b.addend == 0) {
                    err = "OMF divisor is not a constant";
                    return false;
                }
                if (!a.is_sym) {
                    r.addend = a.addend / b.addend;
                } else if (a.divisor == 1 && (b.addend == 256 || b.addend == 65536)) {
                    r = a;
                    r.divisor = b.addend;
                } else {
                    err = "OMF expression divide is too complex";
                    return false;
                }
            } else if (!a.is_sym && !b.is_sym) {
                r.addend = op == 0x01 ? a.addend + b.addend : a.addend - b.addend;
            } else if (a.is_sym && !b.is_sym && op == 0x01) {
                r = a;
                r.addend += b.addend;
            } else if (!a.is_sym && b.is_sym && op == 0x01) {
                r = b;
                r.addend += a.addend;
            } else if (a.is_sym && !b.is_sym && op == 0x02) {
                r = a;
                r.addend -= b.addend;
            } else {
                err = "OMF expression is too complex to link";
                return false;
            }
            st.push_back(r);
            continue;
        }
        err = "unsupported OMF expression operator";
        return false;
    }
    err = "OMF expression has no end";
    return false;
}

} // namespace

bool omf_write(const OmfFile &file, std::vector<uint8_t> &out, std::string &err)
{
    out.clear();
    if (file.version != 1 && file.version != 2) {
        err = "OMF version must be 1 or 2";
        return false;
    }
    if (file.segs.empty()) {
        err = "OMF file has no segments";
        return false;
    }
    for (size_t si = 0; si < file.segs.size(); si++) {
        const OmfSeg &seg = file.segs[si];
        if (seg.align > 0x10000) {
            err = "ALIGN is larger than $10000";
            return false;
        }
        size_t start = out.size();
        for (int i = 0; i < 0x2C; i++) out.push_back(0);
        for (int i = 0; i < 10; i++) out.push_back(0x20); /* LOADNAME */
        if (!put_label(out, seg.name, err)) return false;

        uint16_t dispname = 0x2C;
        uint16_t dispdata = static_cast<uint16_t>(out.size() - start);
        if (!file.object) {
            if (!write_load_body(out, seg, err)) return false;
        } else {
            if (!write_object_body(out, seg, file.version, err)) return false;
        }

        bool blocks = file.version == 1 && !file.object;
        if (blocks) {
            while ((out.size() - start) % 512) out.push_back(0);
        }
        uint32_t span = static_cast<uint32_t>(out.size() - start);
        uint32_t count = blocks ? span / 512 : span;

        patch_u32(out, start + 0x00, count);
        patch_u32(out, start + 0x04, 0); /* RESSPC */
        patch_u32(out, start + 0x08, static_cast<uint32_t>(seg.image.size()));
        out[start + 0x0D] = 0; /* LABLEN: Pascal strings */
        out[start + 0x0E] = 4; /* NUMLEN */
        out[start + 0x0F] = static_cast<uint8_t>(file.version);
        patch_u32(out, start + 0x10, 0x00010000); /* BANKSIZE */
        if (file.version == 1) {
            uint8_t type = 0;
            if (!v1_type(seg.kind, type, err)) return false;
            out[start + 0x0C] = type;
        } else {
            out[start + 0x14] = static_cast<uint8_t>(seg.kind & 0xFF);
            out[start + 0x15] = static_cast<uint8_t>((seg.kind >> 8) & 0xFF);
        }
        patch_u32(out, start + 0x18, seg.org);
        patch_u32(out, start + 0x1C, seg.align);
        out[start + 0x20] = 0; /* NUMSEX */
        uint16_t segnum = seg.segnum ? seg.segnum : static_cast<uint16_t>(si + 1);
        out[start + 0x22] = static_cast<uint8_t>(segnum & 0xFF);
        out[start + 0x23] = static_cast<uint8_t>((segnum >> 8) & 0xFF);
        patch_u32(out, start + 0x24, seg.entry);
        out[start + 0x28] = static_cast<uint8_t>(dispname & 0xFF);
        out[start + 0x29] = static_cast<uint8_t>((dispname >> 8) & 0xFF);
        out[start + 0x2A] = static_cast<uint8_t>(dispdata & 0xFF);
        out[start + 0x2B] = static_cast<uint8_t>((dispdata >> 8) & 0xFF);
    }
    return true;
}

namespace {

bool parse_body(const std::vector<uint8_t> &in, size_t i, size_t end, int version, int lablen,
                OmfSeg &seg, std::string &err)
{
    uint32_t lc = 0;
    while (i < end) {
        uint8_t op = in[i++];
        if (op == 0x00) return true;
        if (op >= 0x01 && op <= 0xDF) {
            if (i + op > end) {
                err = "CONST record runs off the segment";
                return false;
            }
            seg.image.insert(seg.image.end(), in.begin() + static_cast<std::ptrdiff_t>(i),
                             in.begin() + static_cast<std::ptrdiff_t>(i + op));
            i += op;
            lc += op;
            continue;
        }
        if (op == 0xE6 || op == 0xEF) {
            OmfSym sym;
            sym.global = op == 0xE6;
            sym.offset = lc;
            if (!read_label(in, i, end, lablen, sym.name, err)) return false;
            if (version >= 2) {
                if (i + 4 > end) {
                    err = "GLOBAL record runs off the segment";
                    return false;
                }
                i += 4; /* length word, type, private */
            } else if (version == 1) {
                if (i + 3 > end) {
                    err = "GLOBAL record runs off the segment";
                    return false;
                }
                i += 3;
            } else {
                err = "unsupported OMF version in GLOBAL";
                return false;
            }
            seg.syms.push_back(std::move(sym));
            continue;
        }
        if (op == 0xEE) {
            if (i + 1 + 4 > end) {
                err = "RELEXPR record runs off the segment";
                return false;
            }
            OmfFix fx;
            fx.width = in[i++];
            fx.at = get_u32(in, i);
            i += 4;
            if (!read_expr(in, i, end, lablen, fx, err)) return false;
            seg.fixups.push_back(std::move(fx));
            continue;
        }
        if (op == 0xF1) {
            if (i + 4 > end) {
                err = "DS record runs off the segment";
                return false;
            }
            uint32_t n = get_u32(in, i);
            i += 4;
            seg.image.insert(seg.image.end(), n, 0);
            lc += n;
            continue;
        }
        if (op == 0xF2) {
            if (i + 4 > end) {
                err = "LCONST record runs off the segment";
                return false;
            }
            uint32_t n = get_u32(in, i);
            i += 4;
            if (i + n > end) {
                err = "LCONST data runs off the segment";
                return false;
            }
            seg.image.insert(seg.image.end(), in.begin() + static_cast<std::ptrdiff_t>(i),
                             in.begin() + static_cast<std::ptrdiff_t>(i + n));
            i += n;
            lc += n;
            continue;
        }
        if (op == 0xE2) {
            if (i + 10 > end) {
                err = "RELOC record runs off the segment";
                return false;
            }
            OmfReloc r;
            r.width = in[i];
            r.shift = static_cast<int8_t>(in[i + 1]);
            r.at = get_u32(in, i + 2);
            r.disp = get_u32(in, i + 6);
            i += 10;
            seg.relocs.push_back(r);
            continue;
        }
        if (op == 0xE3) {
            if (i + 14 > end) {
                err = "INTERSEG record runs off the segment";
                return false;
            }
            OmfReloc r;
            r.width = in[i];
            r.shift = static_cast<int8_t>(in[i + 1]);
            r.at = get_u32(in, i + 2);
            r.file = get_u16(in, i + 6);
            r.seg = get_u16(in, i + 8);
            r.disp = get_u32(in, i + 10);
            i += 14;
            seg.relocs.push_back(r);
            continue;
        }
        err = "unsupported OMF record";
        return false;
    }
    err = "segment has no END record";
    return false;
}

uint16_t kind_from_v1(uint8_t type)
{
    uint16_t kind = static_cast<uint16_t>(type & 0x1F);
    if (type & 0x20) kind = static_cast<uint16_t>(kind | 0x2000);
    if (type & 0x40) kind = static_cast<uint16_t>(kind | 0x4000);
    if (type & 0x80) kind = static_cast<uint16_t>(kind | 0x8000);
    return kind;
}

} // namespace

bool omf_read(const std::vector<uint8_t> &in, OmfFile &file, std::string &err)
{
    file = OmfFile{};
    size_t off = 0;
    if (in.size() < 0x30) {
        err = "file is too small to be OMF";
        return false;
    }
    int version = in[0x0F];
    if (version != 1 && version != 2) {
        err = "OMF version is not 1 or 2";
        return false;
    }
    file.version = version;
    bool saw_object = false;
    bool saw_load = false;
    while (off + 0x2C + 10 < in.size()) {
        if (in[off + 0x0E] != 4 || in[off + 0x20] != 0) {
            err = "OMF NUMLEN must be 4 and NUMSEX must be 0";
            return false;
        }
        if (in[off + 0x0F] != version) {
            err = "OMF segments disagree on version";
            return false;
        }
        uint32_t field = get_u32(in, off);
        uint32_t seglen = field;
        if (version == 1) {
            uint64_t blocks = static_cast<uint64_t>(field) * 512;
            if (field >= 1 && off + blocks <= in.size())
                seglen = static_cast<uint32_t>(blocks);
        }
        if (seglen < 0x30 || off + seglen > in.size()) {
            err = "OMF segment length runs off the file";
            return false;
        }
        OmfSeg seg;
        seg.org = get_u32(in, off + 0x18);
        seg.align = get_u32(in, off + 0x1C);
        seg.segnum = get_u16(in, off + 0x22);
        seg.entry = get_u32(in, off + 0x24);
        uint16_t dispname = get_u16(in, off + 0x28);
        uint16_t dispdata = get_u16(in, off + 0x2A);
        if (version == 1)
            seg.kind = kind_from_v1(in[off + 0x0C]);
        else
            seg.kind = get_u16(in, off + 0x14);
        int lablen = in[off + 0x0D];
        if (dispname < 0x2C || dispdata <= dispname || off + dispdata >= off + seglen) {
            err = "OMF DISPNAME or DISPDATA is out of range";
            return false;
        }
        size_t name_at = off + dispname + 10;
        if (lablen == 0) {
            if (name_at >= in.size()) {
                err = "OMF segment name is missing";
                return false;
            }
            size_t n = in[name_at];
            if (name_at + 1 + n > off + seglen) {
                err = "OMF segment name runs off the segment";
                return false;
            }
            seg.name.assign(reinterpret_cast<const char *>(&in[name_at + 1]), n);
        } else {
            if (name_at + static_cast<size_t>(lablen) > off + seglen) {
                err = "OMF segment name runs off the segment";
                return false;
            }
            seg.name.assign(reinterpret_cast<const char *>(&in[name_at]),
                            static_cast<size_t>(lablen));
            while (!seg.name.empty() && seg.name.back() == ' ') seg.name.pop_back();
        }
        if (!parse_body(in, off + dispdata, off + seglen, version, lablen, seg, err))
            return false;
        if (!seg.syms.empty() || !seg.fixups.empty()) saw_object = true;
        if (!seg.relocs.empty()) saw_load = true;
        /* A load file's body is LCONST, which leaves syms and fixups empty.
           An object uses CONST and may have neither if it is only bytes.
           Prefer the caller's later classification: object when any GLOBAL
           or RELEXPR was seen in the file. */
        file.segs.push_back(std::move(seg));
        off += seglen;
        if (off == in.size()) break;
    }
    if (file.segs.empty()) {
        err = "OMF file has no segments";
        return false;
    }
    file.object = saw_object && !saw_load;
    if (saw_object && saw_load) {
        err = "OMF file mixes object records and load records";
        return false;
    }
    /* Byte-only object segments still count as objects when the body used
       CONST (opcode $01-$DF) rather than LCONST. parse_body does not say
       which. A segment with no relocs and no syms that came from LCONST is
       a load image. qlink writes one or the other, and a later target reads
       libraries by their GLOBAL records. A raw load image has relocs or
       neither; treat "neither" as a load image so absolute files paste as
       bytes. Object files we write always carry at least the segment label
       when the assembler had one. An empty-symbol object is still object
       format if we set the flag from the writer. Readers of our libraries
       see GLOBAL. */
    if (!saw_object && !saw_load) file.object = false;
    return err.empty();
}

} // namespace qasm
