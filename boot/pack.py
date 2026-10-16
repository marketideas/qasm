#!/usr/bin/env python3
"""Pack the ProDOS 8 kernel and BASIC.SYSTEM, and check boot.2mg.

The assembler concatenates each PROC. The listing PC is the address the
bytes occupy. This script places those bytes at the file offsets the
ProDOS 8 loader expects.

  python3 boot/pack.py join-basic -o OUT LOADER MAIN GLOBALS
  python3 boot/pack.py prodos OUT mli.lst ram.lst clock.lst
  python3 boot/pack.py basic OUT basic.lst --oracle BASIC.SYSTEM
  python3 boot/pack.py check IMAGE PRODOS BASIC.SYSTEM
"""

import argparse
import sys

PRODOS_SIZE = 0x4300
# Apple's BASIC.SYSTEM is $2800. The alias page at $BD00 adds one page,
# and the globals move from file $2700 to $2800.
ORACLE_BASIC_SIZE = 0x2800
BASIC_SIZE = 0x2900
# LDX #CILEN in the loader. $23 becomes $24 so the alias page is copied.
CILEN_OFF = 0x56
# LDX #ZLDREND-COPRIT-1. The copyright line grew from 32 to 34 characters.
COPRIT_LEN_OFF = 0x1AC
# Third instruction of the globals page: JMP EXTRNCMD target.
EXTRN_LO = 7
BLOCK = 512


class PackError(Exception):
    pass


def die(msg):
    raise PackError(msg)


def read_text(path):
    data = open(path, "rb").read()
    data = data.replace(b"\r\n", b"\n").replace(b"\r", b"\n")
    return data.decode("latin1")


def strip_code(line):
    """Drop an APW ';' comment. A full-line '*' comment stays a comment."""
    if line.lstrip().startswith("*"):
        return None
    out = []
    sq = False
    dq = False
    for c in line:
        if not sq and not dq and c == ";":
            break
        if not sq and not dq:
            if c == "'":
                sq = True
            elif c == '"':
                dq = True
        elif sq and c == "'":
            sq = False
        elif dq and c == '"':
            dq = False
        out.append(c)
    return "".join(out).strip()


def is_end_directive(line):
    body = strip_code(line.rstrip("\n"))
    if body is None:
        return False
    parts = body.split()
    if len(parts) == 1 and parts[0].upper() == "END":
        return True
    if len(parts) == 2 and parts[1].upper() == "END":
        return True
    return False


def cmd_join_basic(out_path, sources):
    chunks = ["* Assembler: APW\n", "        org $2000\n"]
    for path in sources:
        text = read_text(path)
        kept = []
        for line in text.split("\n"):
            if is_end_directive(line):
                continue
            kept.append(line)
        body = "\n".join(kept)
        if body and not body.endswith("\n"):
            body += "\n"
        chunks.append(body)
    open(out_path, "w", encoding="latin1", newline="\n").write("".join(chunks))


def parse_hex_bytes(field):
    out = []
    i = 0
    while i + 2 <= len(field):
        tok = field[i:i + 2]
        if tok == "..":
            break
        if len(tok) != 2 or any(c not in "0123456789ABCDEF" for c in tok):
            break
        if i + 2 < len(field) and field[i + 2] not in " .":
            break
        out.append(int(tok, 16))
        i += 3
    return out


def parse_listing(path):
    text = read_text(path)
    lines = text.split("\n")
    if not lines or "bytes=" not in lines[0] or "errors=" not in lines[0]:
        die(path + ": not a qasm listing")
    header = lines[0]
    try:
        nbytes = int(header.split("bytes=", 1)[1].split()[0])
        nerr = int(header.split("errors=", 1)[1].split()[0])
    except (IndexError, ValueError):
        die(path + ": bad listing header")
    if nerr != 0:
        shown = []
        for line in lines:
            if line.startswith(";  "):
                shown.append(line[3:].rstrip())
            if len(shown) >= 12:
                break
        extra = ""
        if shown:
            extra = "\n" + "\n".join(shown)
        die(path + ": listing reports " + str(nerr) + " errors" + extra)

    mem = {}
    count = 0
    i = 0
    while i < len(lines):
        line = lines[i]
        if len(line) < 8 or not _is_pc_line(line):
            i += 1
            continue
        pc = int(line[0:6], 16)
        field = line[8:24] if len(line) >= 24 else line[8:]
        chunk = parse_hex_bytes(field)
        i += 1
        while i < len(lines) and lines[i].startswith("        "):
            more = parse_hex_bytes(lines[i][8:])
            if not more:
                break
            chunk.extend(more)
            i += 1
        for n, b in enumerate(chunk):
            addr = pc + n
            # `org *-n` rewrites a placeholder (jmp 0 / jsr 0). The same byte
            # is not a second piece of code. A different byte is a real overlap.
            if addr in mem and mem[addr] != b:
                die("%s: overlap at $%06X" % (path, addr))
            mem[addr] = b
            count += 1
    if count != nbytes:
        die("%s: parsed %d bytes, listing says %d" % (path, count, nbytes))
    return mem


def _is_pc_line(line):
    if len(line) < 8 or line[6:8] != "  ":
        return False
    for c in line[0:6]:
        if c not in "0123456789ABCDEF":
            return False
    return True


def take_range(mem, name, start, maxlen, exact):
    end = start
    limit = start + maxlen
    while end < limit and end in mem:
        end += 1
    holes = [a for a in mem if start <= a < limit and a >= end]
    if holes:
        die("%s: hole at $%04X before $%04X" % (name, end, holes[0]))
    n = end - start
    if n == 0:
        die("%s: no bytes at $%04X" % (name, start))
    if exact and n != maxlen:
        die("%s: $%X bytes at $%04X, expected $%X" % (name, n, start, maxlen))
    if n > maxlen:
        die("%s: $%X bytes exceeds $%X" % (name, n, maxlen))
    return bytes(mem[start + i] for i in range(n)), set(range(start, end))


def place(image, owner, name, blob, offset, slot):
    if offset < 0 or offset + slot > len(image):
        die("%s: file slot $%X+$%X does not fit" % (name, offset, slot))
    if len(blob) > slot:
        die("%s: $%X bytes does not fit in $%X" % (name, len(blob), slot))
    for i in range(slot):
        if owner[offset + i] is not None:
            die("%s overlaps %s at file offset $%X" % (name, owner[offset + i], offset + i))
        owner[offset + i] = name
    image[offset:offset + len(blob)] = blob


def pack_ranges(listings, groups, size):
    """listings is a list of (tag, mem). groups[tag] is the slice list."""
    image = bytearray(size)
    owner = [None] * size
    for tag, mem in listings:
        seen = set()
        for name, start, maxlen, offset, exact in groups[tag]:
            blob, addrs = take_range(mem, tag + " " + name, start, maxlen, exact)
            place(image, owner, name, blob, offset, maxlen)
            seen |= addrs
        stray = sorted(a for a in mem if a not in seen)
        if stray:
            die("%s: %d unexpected bytes, first at $%06X" % (tag, len(stray), stray[0]))
    return bytes(image)


# name, runtime PC, exact-or-max length, file offset, exact
PRODOS_GROUPS = {
    "mli": [
        ("PROCONE", 0x2000, 0xC80, 0x0000, True),
        ("PROCTWO", 0xBF00, 0x100, 0x0E00, True),
        ("PROCTHREE", 0xDE00, 0x2100, 0x1000, True),
        ("PROCFOUR", 0xFF9B, 0x65, 0x0D9B, True),
    ],
    "ram": [
        ("RAM2", 0x2C80, 0x80, 0x0C80, False),
        ("RAM3", 0xFF00, 0x9B, 0x0D00, False),
        ("RAM1", 0x0200, 0x200, 0x3100, False),
    ],
    "clock": [
        ("CCLOCK", 0xD742, 125, 0x0F80, True),
    ],
}

BASIC_GROUPS = {
    "basic": [
        ("LOADER", 0x2000, 0x400, 0x0000, True),
        ("MAIN", 0x9A00, 0x2400, 0x0400, False),
        ("GLOBALS", 0xBE00, 0x100, 0x2800, False),
    ],
}


def cmd_prodos(out_path, mli, ram, clock):
    listings = [
        ("mli", parse_listing(mli)),
        ("ram", parse_listing(ram)),
        ("clock", parse_listing(clock)),
    ]
    image = pack_ranges(listings, PRODOS_GROUPS, PRODOS_SIZE)
    if len(image) != PRODOS_SIZE:
        die("PRODOS size")
    open(out_path, "wb").write(image)
    print("PRODOS: %d bytes ($%X)" % (len(image), len(image)))


def pc_of_basic(offset):
    if offset < 0x400:
        return 0x2000 + offset
    if offset < 0x2800:
        return 0x9A00 + (offset - 0x400)
    return 0xBE00 + (offset - 0x2800)


def _same(image, img_at, oracle, ora_at, n, skip=()):
    diffs = []
    for i in range(n):
        if i in skip:
            continue
        if image[img_at + i] == oracle[ora_at + i]:
            continue
        if len(diffs) < 8:
            off = img_at + i
            diffs.append("  $%04X (pc $%04X): got $%02X want $%02X" % (
                off, pc_of_basic(off), image[off], oracle[ora_at + i]))
    return diffs


SPLASH_VER = b"            PRODOS BASIC 2.0 "
SPLASH_COP = b"        COPYRIGHT APPLE  1983-2026"


def _splash_span(loader):
    """Byte range of the two high-bit splash lines in the loader."""
    text = bytes(b & 0x7F for b in loader)
    ver = text.find(SPLASH_VER)
    cop = text.find(SPLASH_COP)
    if ver < 0 or cop != ver + len(SPLASH_VER):
        return None
    return range(ver, cop + len(SPLASH_COP))


def cmd_basic(out_path, listing, oracle_path):
    """Keep Apple's bytes. The loader length, the splash lines, the alias
    page, and the EXTRNCMD vector are the intended differences."""
    image = pack_ranges([("basic", parse_listing(listing))], BASIC_GROUPS, BASIC_SIZE)
    oracle = open(oracle_path, "rb").read()
    if len(oracle) != ORACLE_BASIC_SIZE:
        die("oracle is %d bytes, expected %d" % (len(oracle), ORACLE_BASIC_SIZE))
    if len(image) != BASIC_SIZE:
        die("BASIC.SYSTEM is %d bytes, expected %d" % (len(image), BASIC_SIZE))
    diffs = []
    if not (image[CILEN_OFF] == 0x24 and oracle[CILEN_OFF] == 0x23
            and image[CILEN_OFF - 1] == 0xA2):
        diffs.append("  CILEN at $%04X: got $%02X want $24" % (
            CILEN_OFF, image[CILEN_OFF]))
    splash = _splash_span(image[:0x400])
    if splash is None:
        diffs.append("  splash is not PRODOS BASIC 2.0 / 1983-2026")
        splash = range(0)
    coprit_len = len(SPLASH_COP) - 1
    if not (image[COPRIT_LEN_OFF] == coprit_len
            and image[COPRIT_LEN_OFF - 1] == 0xA2
            and oracle[COPRIT_LEN_OFF] == 0x1F):
        diffs.append("  copyright length at $%04X: got $%02X want $%02X" % (
            COPRIT_LEN_OFF, image[COPRIT_LEN_OFF], coprit_len))
    diffs += _same(image, 0, oracle, 0, 0x400,
                   skip=set(splash) | {CILEN_OFF, COPRIT_LEN_OFF})
    diffs += _same(image, 0x400, oracle, 0x400, 0x2300)
    diffs += _same(image, 0x2800, oracle, 0x2700, 0x100, skip=(EXTRN_LO, EXTRN_LO + 1))
    jmp = image[0x2806:0x2809]
    target = jmp[1] | (jmp[2] << 8)
    if jmp[0] != 0x4C or not (0xBD00 <= target < 0xBE00):
        diffs.append("  EXTRNCMD is %s, want JMP into $BD00" % jmp.hex())
    if image[0x2700] == 0:
        diffs.append("  alias page at $BD00 is empty")
    if diffs:
        die("BASIC.SYSTEM drifted from the oracle\n" + "\n".join(diffs))
    open(out_path, "wb").write(image)
    print("BASIC.SYSTEM: %d bytes, aliases at $%04X" % (len(image), target))


def r16(b, off):
    return b[off] | (b[off + 1] << 8)


def r24(b, off):
    return b[off] | (b[off + 1] << 8) | (b[off + 2] << 16)


def r32(b, off):
    return b[off] | (b[off + 1] << 8) | (b[off + 2] << 16) | (b[off + 3] << 24)


def load_2mg(path):
    file = open(path, "rb").read()
    if len(file) < 64 or file[0:4] != b"2IMG":
        die(path + ": not a 2MG image")
    if r32(file, 0x0C) != 1:
        die(path + ": not a ProDOS-order image")
    blocks = r32(file, 0x14)
    off = r32(file, 0x18)
    length = r32(file, 0x1C)
    if blocks != 1600 or off != 64 or length != 1600 * BLOCK:
        die("%s: expected 1600 blocks at offset 64, got blocks=%d off=%d len=%d" % (
            path, blocks, off, length))
    if off + length > len(file):
        die(path + ": truncated image")
    data = file[off:off + length]
    return [data[i * BLOCK:(i + 1) * BLOCK] for i in range(blocks)]


def index_ptr(block, i):
    return block[i] | (block[256 + i] << 8)


def read_prodos_file(blocks, storage, key, eof):
    if storage == 1:
        if eof > BLOCK or key == 0 or key >= len(blocks):
            die("bad seedling")
        return bytes(blocks[key][:eof])
    if storage not in (2, 3) or key == 0 or key >= len(blocks):
        die("unsupported storage $%X" % storage)
    master = blocks[key]
    out = bytearray(eof)
    pos = 0
    while pos < eof:
        n = eof - pos
        if n > BLOCK:
            n = BLOCK
        index = pos // BLOCK
        if storage == 2:
            if index >= 256:
                die("sapling index")
            db = index_ptr(master, index)
        else:
            sub = index // 256
            ix = index % 256
            if sub >= 128:
                die("tree index")
            ib = index_ptr(master, sub)
            if ib == 0:
                db = 0
            elif ib >= len(blocks):
                die("bad index block")
            else:
                db = index_ptr(blocks[ib], ix)
        if db != 0:
            if db >= len(blocks):
                die("bad data block")
            out[pos:pos + n] = blocks[db][:n]
        pos += n
    return bytes(out)


def volume_files(blocks):
    files = []
    b = 2
    guard = 0
    while b:
        if b >= len(blocks) or guard > len(blocks):
            die("bad directory")
        guard += 1
        blk = blocks[b]
        for i in range(13):
            if b == 2 and i == 0:
                continue
            ent = blk[4 + i * 0x27:4 + (i + 1) * 0x27]
            storage = ent[0] >> 4
            if storage == 0:
                continue
            nlen = ent[0] & 0x0F
            name = ent[1:1 + nlen].decode("latin1")
            files.append({
                "name": name,
                "storage": storage,
                "type": ent[0x10],
                "key": r16(ent, 0x11),
                "eof": r24(ent, 0x15),
                "aux": r16(ent, 0x1F),
            })
        b = r16(blk, 2)
    return files


def cmd_check(image, prodos_path, basic_path):
    blocks = load_2mg(image)
    vol = blocks[2]
    nlen = vol[4] & 0x0F
    name = vol[5:5 + nlen].decode("latin1")
    if (vol[4] >> 4) != 0x0F or name != "BASIC":
        die("volume name is %r, expected BASIC" % name)
    if r16(vol, 0x29) != 1600:
        die("volume header block count is %d" % r16(vol, 0x29))
    if vol[0x23] != 0x27 or vol[0x24] != 0x0D:
        die("directory entry size is not $27 / $0D")
    if blocks[0][0] != 0xD8 or blocks[0][1] != 0xD8:
        die("boot block does not start with CLD CLD")
    files = volume_files(blocks)
    if len(files) != 2:
        die("volume has %d files, expected PRODOS and BASIC.SYSTEM" % len(files))
    expect = [
        ("PRODOS", 0xFF, 0x0000, PRODOS_SIZE, prodos_path),
        ("BASIC.SYSTEM", 0xFF, 0x2000, BASIC_SIZE, basic_path),
    ]
    for got, (ename, etype, eaux, eeof, host) in zip(files, expect):
        if got["name"] != ename or got["type"] != etype or got["aux"] != eaux or got["eof"] != eeof:
            die("%s: type $%02X aux $%04X eof $%X (want %s $%02X $%04X $%X)" % (
                got["name"], got["type"], got["aux"], got["eof"], ename, etype, eaux, eeof))
        if got["storage"] != 2:
            die("%s: storage $%X, expected a sapling" % (ename, got["storage"]))
        data = read_prodos_file(blocks, got["storage"], got["key"], got["eof"])
        want = open(host, "rb").read()
        if data != want:
            die("%s on the image does not match %s" % (ename, host))
    print("boot.2mg: BASIC, 1600 blocks, PRODOS $%X, BASIC.SYSTEM $%X" % (
        PRODOS_SIZE, BASIC_SIZE))


def main(argv):
    p = argparse.ArgumentParser(prog="pack.py")
    sub = p.add_subparsers(dest="cmd", required=True)

    j = sub.add_parser("join-basic")
    j.add_argument("-o", required=True)
    j.add_argument("sources", nargs=3)

    pr = sub.add_parser("prodos")
    pr.add_argument("out")
    pr.add_argument("mli")
    pr.add_argument("ram")
    pr.add_argument("clock")

    b = sub.add_parser("basic")
    b.add_argument("out")
    b.add_argument("listing")
    b.add_argument("--oracle", required=True)

    c = sub.add_parser("check")
    c.add_argument("image")
    c.add_argument("prodos")
    c.add_argument("basic")

    args = p.parse_args(argv)
    try:
        if args.cmd == "join-basic":
            cmd_join_basic(args.o, args.sources)
        elif args.cmd == "prodos":
            cmd_prodos(args.out, args.mli, args.ram, args.clock)
        elif args.cmd == "basic":
            cmd_basic(args.out, args.listing, args.oracle)
        elif args.cmd == "check":
            cmd_check(args.image, args.prodos, args.basic)
    except PackError as exc:
        print("pack.py: " + str(exc), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
