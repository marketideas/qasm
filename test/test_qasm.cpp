#include "qasm.hpp"
#include "pcode.hpp"
#include <cstdint>
#include <cstring>
#include <string>
#include <vector>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int fails = 0;

static void expect_ok(const char *src, const uint8_t *want, size_t n, const char *tag)
{
    qasm::Options opt;
    qasm::Result r = qasm::assemble_string(src, tag, opt);
    if (!r.ok()) {
        fprintf(stderr, "FAIL %s: assemble errors:\n", tag);
        for (const auto &e : r.errors)
            fprintf(stderr, "  %s:%d: %s\n", e.file.c_str(), e.line, e.msg.c_str());
        fails++;
        return;
    }
    if (r.bytes.size() != n) {
        fprintf(stderr, "FAIL %s: len got %zu want %zu\n", tag, r.bytes.size(), n);
        fails++;
        return;
    }
    if (memcmp(r.bytes.data(), want, n) != 0) {
        fprintf(stderr, "FAIL %s: bytes\n  got ", tag);
        for (size_t i = 0; i < n; i++) fprintf(stderr, "%02X ", r.bytes[i]);
        fprintf(stderr, "\n  exp ");
        for (size_t i = 0; i < n; i++) fprintf(stderr, "%02X ", want[i]);
        fprintf(stderr, "\n");
        fails++;
    }
}

static void append_hi(char *dst, size_t *o, size_t max, const char *s)
{
    while (*s && *o + 1 < max)
        dst[(*o)++] = (char)(((unsigned char)*s++) | 0x80);
}

static void test_native_merlin_format(void)
{
    char src[512];
    size_t o = 0;

    /* unlabeled ORG $8000  (leading $A0 = tab to opcode) */
    src[o++] = (char)0xA0;
    append_hi(src, &o, sizeof src, "ORG");
    src[o++] = (char)0xA0;
    append_hi(src, &o, sizeof src, "$8000");
    src[o++] = (char)0x8D;

    append_hi(src, &o, sizeof src, "BELL");
    src[o++] = (char)0xA0;
    append_hi(src, &o, sizeof src, "EQU");
    src[o++] = (char)0xA0;
    append_hi(src, &o, sizeof src, "$FBDD");
    src[o++] = (char)0x8D;

    append_hi(src, &o, sizeof src, "START");
    src[o++] = (char)0xA0;
    append_hi(src, &o, sizeof src, "JSR");
    src[o++] = (char)0xA0;
    append_hi(src, &o, sizeof src, "BELL");
    src[o++] = (char)0xA0;
    src[o++] = (char)(';' | 0x80);
    src[o++] = ' '; /* $20 in the comment, not a field tab */
    append_hi(src, &o, sizeof src, "RING");
    src[o++] = (char)0x8D;

    src[o++] = (char)0xA0;
    append_hi(src, &o, sizeof src, "RTS");
    src[o++] = (char)0x8D;
    src[o] = '\0';

    const uint8_t want[] = {0x20, 0xDD, 0xFB, 0x60};
    expect_ok(src, want, sizeof(want), "native-a0");
}

static void test_native_string_space(void)
{
    /* $A0 tabs between columns; $20 is a real space inside the string. */
    char src[256];
    size_t o = 0;
    src[o++] = (char)0xA0;
    append_hi(src, &o, sizeof src, "ORG");
    src[o++] = (char)0xA0;
    append_hi(src, &o, sizeof src, "$8000");
    src[o++] = (char)0x8D;

    src[o++] = (char)0xA0;
    append_hi(src, &o, sizeof src, "ASC");
    src[o++] = (char)0xA0;
    src[o++] = (char)('\'' | 0x80);
    append_hi(src, &o, sizeof src, "Hello");
    src[o++] = 0x20;
    append_hi(src, &o, sizeof src, "World");
    src[o++] = (char)('\'' | 0x80);
    src[o++] = (char)0x8D;
    src[o] = '\0';

    const uint8_t want[] = {'H', 'e', 'l', 'l', 'o', ' ', 'W', 'o', 'r', 'l', 'd'};
    expect_ok(src, want, sizeof(want), "native-str-space");
}

static void test_force_prefixes(void)
{
    const char *src =
        "     XC\n"
        "     XC\n"
        "     ORG   $2000\n"
        "     LDA   <$FFF0\n"
        "     LDA   |$FFF0\n"
        "     LDA   >$FFF0\n"
        "     LDA:  $00\n"
        "     LDAL  $FFF0+24\n";
    /* A5 F0 | AD F0 FF | AF F0 FF 00 | AD 00 00 | AF 08 00 01 */
    const uint8_t want[] = {
        0xA5, 0xF0,
        0xAD, 0xF0, 0xFF,
        0xAF, 0xF0, 0xFF, 0x00,
        0xAD, 0x00, 0x00,
        0xAF, 0x08, 0x00, 0x01
    };
    expect_ok(src, want, sizeof(want), "force-prefix");
}

static void test_macro_semicolon(void)
{
    const char *src =
        "     XC\n"
        "     XC\n"
        "     ORG   $2000\n"
        "_M        MAC\n"
        "          LDAL  ]1\n"
        "          LDAL  ]2\n"
        "          EOM\n"
        "          _M    *;1\n";
    /* ldal * at $2000 = AF 00 20 00; ldal 1 = AF 01 00 00
       After first 4 bytes PC is $2004, so ldal * → AF 04 20 00 */
    const uint8_t want[] = {
        0xAF, 0x00, 0x20, 0x00,
        0xAF, 0x01, 0x00, 0x00
    };
    expect_ok(src, want, sizeof(want), "macro-semi");
}

static void test_hello(void)
{
    const char *src =
        "              ORG   $8000\n"
        "BELL          EQU   $FBDD\n"
        "START         JSR   BELL\n"
        "              RTS\n";
    const uint8_t want[] = {0x20, 0xDD, 0xFB, 0x60};
    expect_ok(src, want, sizeof(want), "hello");
}

static void test_mx_imm(void)
{
    const char *src8 =
        "     MX    %11\n"
        "     ORG   $8000\n"
        "     LDA   #1\n";
    const uint8_t w8[] = {0xA9, 0x01};
    expect_ok(src8, w8, sizeof(w8), "imm8");

    const char *src16 =
        "     MX    %00\n"
        "     ORG   $8000\n"
        "     LDA   #1\n";
    const uint8_t w16[] = {0xA9, 0x01, 0x00};
    expect_ok(src16, w16, sizeof(w16), "imm16");
}

static void test_sep_rep(void)
{
    const char *src =
        "     MX    %11\n"
        "     ORG   $8000\n"
        "     REP   #$30\n"
        "     LDA   #1\n"
        "     SEP   #$30\n"
        "     LDA   #1\n";
    const uint8_t want[] = {0xC2, 0x30, 0xA9, 0x01, 0x00, 0xE2, 0x30, 0xA9, 0x01};
    expect_ok(src, want, sizeof(want), "sep/rep");
}

static void test_hex_asc(void)
{
    const char *src =
        "     ORG   $8000\n"
        "     HEX   00,01,0203\n"
        "     ASC   'Hi'\n"
        "     ASC   \"Hi\"\n";
    const uint8_t want[] = {0x00, 0x01, 0x02, 0x03, 'H', 'i', (uint8_t)('H'|0x80), (uint8_t)('i'|0x80)};
    expect_ok(src, want, sizeof(want), "hex/asc");
}

static void test_expr_ltr(void)
{
    const char *src =
        "     ORG   $8000\n"
        "     DFB   1+2*3\n"      /* LTR = 9 */
        "     DFB   {1+2*3}\n";   /* alg = 7 */
    const uint8_t want[] = {9, 7};
    expect_ok(src, want, sizeof(want), "expr");
}

static void test_dp_vs_abs(void)
{
    const char *src =
        "     ORG   $8000\n"
        "ZP        EQU   $10\n"
        "     LDA   ZP\n"
        "     LDA:  ZP\n"
        "     LDA   $C000\n";
    const uint8_t want[] = {0xA5, 0x10, 0xAD, 0x10, 0x00, 0xAD, 0x00, 0xC0};
    expect_ok(src, want, sizeof(want), "dp/abs");
}

static void test_branch(void)
{
    const char *src =
        "     ORG   $8000\n"
        "LOOP      NOP\n"
        "          BRA   LOOP\n";
    const uint8_t want[] = {0xEA, 0x80, 0xFD};
    expect_ok(src, want, sizeof(want), "branch");
}

static void test_do(void)
{
    const char *src =
        "     ORG   $8000\n"
        "     DO    0\n"
        "     LDA   #1\n"
        "     ELSE\n"
        "     LDA   #2\n"
        "     FIN\n";
    const uint8_t want[] = {0xA9, 0x02};
    expect_ok(src, want, sizeof(want), "do/else");
}

static void test_macro(void)
{
    const char *src =
        "WAIT      MAC\n"
        "          LDA   $C000\n"
        "          <<<\n"
        "          ORG   $8000\n"
        "          WAIT\n"
        "          RTS\n";
    const uint8_t want[] = {0xAD, 0x00, 0xC0, 0x60};
    expect_ok(src, want, sizeof(want), "macro");
}

static void test_local(void)
{
    const char *src =
        "          ORG   $8000\n"
        "          LDX   #0\n"
        "]LOOP     INX\n"
        "          BNE   ]LOOP\n"
        "          RTS\n";
    const uint8_t want[] = {0xA2, 0x00, 0xE8, 0xD0, 0xFD, 0x60};
    expect_ok(src, want, sizeof(want), "local");
}

static void test_long(void)
{
    const char *src =
        "          MX    %00\n"
        "          ORG   $8000\n"
        "          LDAL  $E12000\n"
        "          JSL   $E10000\n";
    const uint8_t want[] = {0xAF, 0x00, 0x20, 0xE1, 0x22, 0x00, 0x00, 0xE1};
    expect_ok(src, want, sizeof(want), "long");
}

static void test_ds_da(void)
{
    const char *src =
        "          ORG   $8000\n"
        "          DA    $FDF0\n"
        "          DS    2,$EE\n";
    const uint8_t want[] = {0xF0, 0xFD, 0xEE, 0xEE};
    expect_ok(src, want, sizeof(want), "da/ds");
}

static void test_strl(void)
{
    const char *src =
        "          ORG   $8000\n"
        "          STRL  'Hi'\n";
    const uint8_t want[] = {0x02, 0x00, 'H', 'i'};
    expect_ok(src, want, sizeof(want), "strl");
}

static void test_lup(void)
{
    const char *src =
        "          ORG   $8000\n"
        "]N        =     0\n"
        "          LUP   3\n"
        "          DFB   ]N\n"
        "]N        =     ]N+1\n"
        "          --^\n";
    const uint8_t want[] = {0x00, 0x01, 0x02};
    expect_ok(src, want, sizeof(want), "lup");
}

static void test_lup_at(void)
{
    const char *src =
        "          ORG   $8000\n"
        "          LUP   2\n"
        "KBD_@     LDA   $C000\n"
        "          BPL   KBD_@\n"
        "          --^\n";
    const uint8_t want[] = {
        0xAD, 0x00, 0xC0, 0x10, 0xFB,
        0xAD, 0x00, 0xC0, 0x10, 0xFB
    };
    expect_ok(src, want, sizeof(want), "lup-at");
}

static void test_macro_uniquify(void)
{
    const char *src =
        "INCL      MAC\n"
        "FOO       INC\n"
        "          BNE   FOO\n"
        "          <<<\n"
        "          ORG   $8000\n"
        "          INCL\n"
        "          INCL\n";
    const uint8_t want[] = {0x1A, 0xD0, 0xFD, 0x1A, 0xD0, 0xFD};
    expect_ok(src, want, sizeof(want), "mac-uniquify");
}

static void test_put(void)
{
    const char *src =
        "          ORG   $8000\n"
        "          PUT   test/fixtures/put_inc.s\n"
        "          RTS\n";
    const uint8_t want[] = {0xA9, 0x01, 0x60};
    expect_ok(src, want, sizeof(want), "put");
}

static void test_use(void)
{
    const char *src =
        "          USE   test/fixtures/use_macs.s\n"
        "          ORG   $8000\n"
        "          BELL\n"
        "          RTS\n";
    const uint8_t want[] = {0x20, 0xDD, 0xFB, 0x60};
    expect_ok(src, want, sizeof(want), "use");
}

static void test_var_put(void)
{
    const char *src =
        "          ORG   $8000\n"
        "          VAR   $10;$12\n"
        "          PUT   test/fixtures/var_put.s\n";
    const uint8_t want[] = {0xA5, 0x10, 0x85, 0x12};
    expect_ok(src, want, sizeof(want), "var-put");
}

static void test_flo(void)
{
    const char *src =
        "          ORG   $8000\n"
        "          FLO   1.0\n"
        "          FLO   '2.0'\n";
    const uint8_t want[] = {
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xFF, 0x3F,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x00, 0x40
    };
    expect_ok(src, want, sizeof(want), "flo");
}

static void test_date(void)
{
    const char *src =
        "          ORG   $8000\n"
        "          DATE  1\n"
        "          DATE  5\n";
    qasm::Options opt;
    qasm::Result r = qasm::assemble_string(src, "date", opt);
    if (!r.ok() || r.bytes.size() != 18) {
        fprintf(stderr, "FAIL date: len %zu errors %zu\n", r.bytes.size(), r.errors.size());
        fails++;
        return;
    }
    /* mode 1 high-ASCII, mode 5 positive; both "dd-MMM-yy" */
    if ((r.bytes[0] & 0x80) == 0 || (r.bytes[9] & 0x80) != 0) {
        fprintf(stderr, "FAIL date: high-bit convention\n");
        fails++;
    }
}

static void test_indy(void)
{
    const char *src =
        "          ORG   $8000\n"
        "          LDA   ($10),Y\n"
        "          LDA   $10,S\n"
        "          LDA   ($10,S),Y\n"
        "          PHK\n"
        "          PLB\n";
    const uint8_t want[] = {0xB1, 0x10, 0xA3, 0x10, 0xB3, 0x10, 0x4B, 0xAB};
    expect_ok(src, want, sizeof(want), "indy/s");
}

static void test_brk_wdm(void)
{
    const char *src =
        "          ORG   $8000\n"
        "          BRK   $00\n"
        "          BRK   #$DB\n"
        "          WDM   $FF\n"
        "          COP   $12\n";
    const uint8_t want[] = {0x00, 0x00, 0x00, 0xDB, 0x42, 0xFF, 0x02, 0x12};
    expect_ok(src, want, sizeof(want), "brk/wdm");
}

static void test_jml_jsl_abs(void)
{
    const char *src =
        "          ORG   $10E3\n"
        "          JML   L10E7\n"
        "L10E7     NOP\n"
        "          JSL   $000000\n"
        "LONG      EQU   $000000\n"
        "          JSL   LONG\n"
        "ABS       EQU   $0000\n"
        "          JML   [ABS]\n";
    const uint8_t want[] = {
        0x5C, 0xE7, 0x10, 0x00,
        0xEA,
        0x22, 0x00, 0x00, 0x00,
        0x22, 0x00, 0x00, 0x00,
        0xDC, 0x00, 0x00
    };
    expect_ok(src, want, sizeof(want), "jml/jsl-abs");
}

static void test_acc_a(void)
{
    const char *src =
        "          ORG   $8000\n"
        "          ROR   A\n"
        "          ROL   A\n"
        "          ASL   A\n"
        "          LSR\n";
    const uint8_t want[] = {0x6A, 0x2A, 0x0A, 0x4A};
    expect_ok(src, want, sizeof(want), "acc-a");
}

static void test_dfb_hash_sel(void)
{
    const char *src =
        "          ORG   $8000\n"
        "ABS       EQU   $FEFF\n"
        "          DFB   $0C,#<ABS,#>ABS\n"
        "          DW    |$01A55A,|$011234\n"
        "          DB    >$01A55A,<$01A55A\n";
    const uint8_t want[] = {
        0x0C, 0xFF, 0xFE,
        0x5A, 0xA5, 0x34, 0x12,
        0xA5, 0x5A
    };
    expect_ok(src, want, sizeof(want), "dfb-hash");
}

static void test_ldaz(void)
{
    const char *src =
        "          ORG   $8000\n"
        "          LDAZ  $2345\n"
        "          ORAZ  $FFFF\n"
        "          LDA:  $05\n";
    const uint8_t want[] = {0xA5, 0x45, 0x05, 0xFF, 0xAD, 0x05, 0x00};
    expect_ok(src, want, sizeof(want), "ldaz");
}

static void test_org_resume(void)
{
    const char *src =
        "          ORG   $8000\n"
        "          NOP\n"
        "          ORG   $00BC\n"
        "L00BC     BIT   L00BC\n"
        "          ORG\n"
        "          RTS\n";
    /* ORG changes PC but object bytes stay sequential, so BIT is stored.
       L00BC=$BC encodes as DP BIT. */
    const uint8_t want[] = {0xEA, 0x24, 0xBC, 0x60};
    expect_ok(src, want, sizeof(want), "org-resume");
}

static void test_ext_list(void)
{
    const char *src =
        "          ORG   $8000\n"
        "          EXT   a,b,c,d\n"
        "          DW    a,b,c,d\n";
    const uint8_t want[] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
    expect_ok(src, want, sizeof(want), "ext-list");
}

static void test_usr_width(void)
{
    const char *src =
        "          ORG   $8000\n"
        "CODES     USR   ADC\n"
        "          ERR   *-CODES-2\n";
    const uint8_t want[] = {0x00, 0x00};
    expect_ok(src, want, sizeof(want), "usr-width");
}

static void expect_syn(const char *src, const uint8_t *want, size_t n,
                       const char *tag, const char *syn)
{
    qasm::Options opt;
    qasm::Result r = qasm::assemble_string(src, tag, opt);
    if (!r.ok()) {
        fprintf(stderr, "FAIL %s: assemble errors:\n", tag);
        for (const auto &e : r.errors)
            fprintf(stderr, "  %s:%d: %s\n", e.file.c_str(), e.line, e.msg.c_str());
        fails++;
        return;
    }
    if (r.syntax != syn) {
        fprintf(stderr, "FAIL %s: syntax got %s want %s\n", tag, r.syntax.c_str(), syn);
        fails++;
    }
    if (r.bytes.size() != n || memcmp(r.bytes.data(), want, n) != 0) {
        fprintf(stderr, "FAIL %s: bytes\n  got ", tag);
        for (size_t i = 0; i < r.bytes.size(); i++) fprintf(stderr, "%02X ", r.bytes[i]);
        fprintf(stderr, "\n  exp ");
        for (size_t i = 0; i < n; i++) fprintf(stderr, "%02X ", want[i]);
        fprintf(stderr, "\n");
        fails++;
    }
}

static void test_rel_ext(void)
{
    const char *src =
        "          REL\n"
        "          LDA   #gequ1\n"
        "          LDY   #equ1\n"
        "          EXT   gequ2\n"
        "          LDX   #gequ2\n"
        "          RTL\n";
    const uint8_t want[] = {0xA9, 0x00, 0xA0, 0x00, 0xA2, 0x00, 0x6B};
    expect_ok(src, want, sizeof(want), "rel-ext");
}

static void test_expr_cmp(void)
{
    const char *src =
        "          ORG   $8000\n"
        "          DFB   1=1,1#2\n"
        "          DFB   1+2*3\n"
        "          DFB   {1+2*3}\n";
    const uint8_t want[] = {0x01, 0x01, 0x09, 0x07};
    expect_syn(src, want, sizeof(want), "expr-cmp", "merlin");
}

static void test_syntax_cross(void)
{
    const uint8_t bell[] = {0x20, 0xDD, 0xFB, 0x60};
    expect_syn(
        "              ORG   $8000\n"
        "BELL          EQU   $FBDD\n"
        "START         JSR   BELL\n"
        "              RTS\n",
        bell, sizeof(bell), "syn-merlin", "merlin");
    expect_syn(
        ".p816\n"
        ".org $8000\n"
        "bell = $fbdd\n"
        "start:\n"
        "jsr bell\n"
        "rts\n",
        bell, sizeof(bell), "syn-ca65", "ca65");
    expect_syn(
        " org $8000\n"
        " longa off\n"
        "bell equ $fbdd\n"
        "start anop\n"
        " jsr bell\n"
        " rts\n"
        " end\n",
        bell, sizeof(bell), "syn-orca", "orca");
    expect_syn(
        ".OR $8000\n"
        "BELL .EQ $FBDD\n"
        "START JSR BELL\n"
        " RTS\n"
        ".EN\n",
        bell, sizeof(bell), "syn-lisa", "lisa");

    const uint8_t alg[] = {0x07, 0x09, 0x03};
    expect_syn(
        ".p816\n"
        ".org $8000\n"
        ".byte 1+2*3,(1+2)*3,1|2\n",
        alg, sizeof(alg), "ca65-alg", "ca65");

    const uint8_t imm16[] = {0xA9, 0x01, 0x00};
    expect_syn(
        ".p816\n"
        ".a16\n"
        ".org $8000\n"
        "lda #1\n",
        imm16, sizeof(imm16), "ca65-a16", "ca65");
    expect_syn(
        " org $8000\n"
        " longa on\n"
        " lda #1\n"
        " end\n",
        imm16, sizeof(imm16), "orca-longa", "orca");

    const uint8_t dp[] = {0xA5, 0x34};
    expect_syn(
        ".OR $8000\n"
        "ZP .EPZ $1234\n"
        " LDA ZP\n"
        ".EN\n",
        dp, sizeof(dp), "lisa-epz", "lisa");

    const uint8_t dc[] = {0x01, 0x02, 0x10, 0x00, 0x41, 0x0D};
    expect_syn(
        " org $8000\n"
        " longa off\n"
        " dc i1'1,2',i2'$10',c'A',h'0d'\n"
        " end\n",
        dc, sizeof(dc), "orca-dc", "orca");

    const uint8_t inc[] = {0xE6, 0x10};
    expect_syn(
        ".p816\n"
        ".org $8000\n"
        ".macro bump addr\n"
        "    inc addr\n"
        ".endmacro\n"
        "    bump $10\n",
        inc, sizeof(inc), "ca65-mac", "ca65");
    expect_syn(
        " org $8000\n"
        " longa off\n"
        " macro\n"
        "&lab bump &addr\n"
        " inc &addr\n"
        " mend\n"
        " bump $10\n"
        " end\n",
        inc, sizeof(inc), "orca-mac", "orca");

    const uint8_t oloc[] = {0xEA, 0xEA, 0x80, 0xFD, 0xAD, 0x01, 0x80, 0xFE};
    expect_syn(
        " org $8000\n"
        " longa off\n"
        "glob entry\n"
        " nop\n"
        "~loop anop\n"
        " nop\n"
        " bra ~loop\n"
        " lda ~loop\n"
        " dc i1'~1'\n"
        " end\n",
        oloc, sizeof(oloc), "orca-local", "orca");

    /* The lda before the second global must keep the first ~loop. */
    const uint8_t oscope[] = {0xEA, 0xAD, 0x00, 0x80, 0xEA, 0xAD, 0x04, 0x80};
    expect_syn(
        " org $8000\n"
        " longa off\n"
        "one entry\n"
        "~loop anop\n"
        " nop\n"
        " lda ~loop\n"
        "two entry\n"
        "~loop anop\n"
        " nop\n"
        " lda ~loop\n"
        " end\n",
        oscope, sizeof(oscope), "orca-local-scope", "orca");

    const uint8_t cnot[] = {0xFE};
    expect_syn(
        ".org $8000\n"
        ".byte ~1\n",
        cnot, sizeof(cnot), "ca65-not", "ca65");
}

static void test_apw(void)
{
    const uint8_t abs_on[] = {
        0xA5, 0x40,
        0xAD, 0x40, 0x00,
        0xBD, 0x40, 0x00,
        0xA9, 0x40,
        0xA5, 0x40,
        0x60
    };
    expect_syn(
        "* Assembler: APW\n"
        "         longa  off\n"
        "         org    $8000\n"
        "slot     equ    $40\n"
        "         absaddr off\n"
        "         lda    slot\n"
        "         absaddr on\n"
        "         lda    slot\n"
        "         lda    slot,x\n"
        "         lda    #slot\n"
        "         lda    <slot\n"
        "         rts\n",
        abs_on, sizeof(abs_on), "apw-absaddr", "apw");

    const uint8_t msb[] = {0x41, 0xC1, 0xE2, 0x43};
    expect_syn(
        "* Assembler: MPW\n"
        "         org    $8000\n"
        "         msb    off\n"
        "         dc     c'A'\n"
        "         msb    on\n"
        "         dc     c'Ab'\n"
        "         msb    no\n"
        "         dc     c'C'\n",
        msb, sizeof(msb), "apw-msb", "apw");

    const uint8_t nops[] = {0x60};
    expect_syn(
        "* Assembler: APW\n"
        "         org    $8000\n"
        "         kind   $06\n"
        "         rename old,new\n"
        "         setcom 0\n"
        "         direct on\n"
        "         codecheck on\n"
        "         instime on\n"
        "         ieee   on\n"
        "         title  Hello\n"
        "         printer off\n"
        "         list   off\n"
        "         6502\n"
        "         65c02\n"
        "         65816\n"
        "         rts\n",
        nops, sizeof(nops), "apw-nops", "apw");

    const uint8_t col0[] = {0xAD, 0x40, 0x00, 0x60};
    expect_syn(
        "* Assembler: APW\n"
        "absaddr  on\n"
        "longa    off\n"
        "org      $8000\n"
        "slot     equ $40\n"
        "         lda slot\n"
        "         rts\n",
        col0, sizeof(col0), "apw-col0", "apw");

    /* ABSADDR is applied while lowering, so a false IF does not hide it. */
    const uint8_t hidden[] = {0xAD, 0x40, 0x00};
    expect_syn(
        "* Assembler: APW\n"
        "         org    $8000\n"
        "slot     equ    $40\n"
        "         if     0\n"
        "         absaddr on\n"
        "         endc\n"
        "         lda    slot\n",
        hidden, sizeof(hidden), "apw-absaddr-if", "apw");

    /* Column-1 directive names are labels when the next field is an
       instruction. DC.B strings are bytes. DS.B reserves bytes. #AD is
       the symbol AD, not Merlin's bank prefix. */
    const uint8_t labels[] = {
        0x08,
        0xEA,
        0xEA,
        0xFF,
        0x53, 0x41,
        0xC1,
        0xA9, 0x80,
        0xD0, 0xF7,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00,
        0x60
    };
    expect_syn(
        "* Assembler: APW\n"
        "         org    $8000\n"
        "         longa  off\n"
        "append   php\n"
        "call     nop\n"
        "print    nop\n"
        "         dc.b   call-print,'SA'\n"
        "         msb    on\n"
        "         dc.b   'A'\n"
        "         msb    off\n"
        "ad       equ    $80\n"
        "         lda    #ad\n"
        "         bne    print\n"
        "buf      ds.b   4\n"
        "         ds.w   1\n"
        "         rts\n",
        labels, sizeof(labels), "apw-main-forms", "apw");

    const uint8_t temporg[] = {0xA9, 0x42, 0x60};
    expect_syn(
        "* Assembler: APW\n"
        "main     proc   temporg $9A00\n"
        "         longa  off\n"
        "         lda    #$42\n"
        "         rts\n",
        temporg, sizeof(temporg), "apw-temporg", "apw");
    {
        qasm::Options opt;
        qasm::Result r = qasm::assemble_string(
            "* Assembler: APW\n"
            "main     proc   temporg $9A00\n"
            "         rts\n",
            "apw-temporg-org", opt);
        if (!r.ok() || r.org != 0x9A00) {
            fprintf(stderr, "FAIL apw-temporg-org org=$%X ok=%d\n", r.org, r.ok() ? 1 : 0);
            fails++;
        }
    }
    {
        qasm::Options opt;
        qasm::Result r = qasm::assemble_string(
            "* Assembler: APW\n"
            "glbl     proc   entry,org $BE00\n"
            "         longa  off\n"
            "         rts\n",
            "apw-proc-org", opt);
        if (!r.ok() || r.org != 0xBE00 || r.bytes.size() != 1 || r.bytes[0] != 0x60) {
            fprintf(stderr, "FAIL apw-proc-org org=$%X bytes=%zu ok=%d\n",
                    r.org, r.bytes.size(), r.ok() ? 1 : 0);
            for (const auto &e : r.errors)
                fprintf(stderr, "  %s\n", e.msg.c_str());
            fails++;
        }
    }

    /* Forward direct-page operands are absolute on pass 1. That moves
       later labels. A backward branch must be remeasured after they settle. */
    {
        std::string src =
            "* Assembler: APW\n"
            "         org    $8000\n"
            "         longa  off\n";
        for (int i = 0; i < 40; i++)
            src += "         lda    zp\n";
        src += "syn      nop\n";
        for (int i = 0; i < 90; i++)
            src += "         nop\n";
        src +=
            "         bne    syn\n"
            "zp       equ    $10\n"
            "         rts\n";
        qasm::Options opt;
        qasm::Result r = qasm::assemble_string(src, "apw-phase-branch", opt);
        if (!r.ok() || r.bytes.size() < 3 || r.bytes[r.bytes.size() - 3] != 0xD0 ||
            r.bytes.back() != 0x60) {
            fprintf(stderr, "FAIL apw-phase-branch ok=%d len=%zu\n",
                    r.ok() ? 1 : 0, r.bytes.size());
            for (const auto &e : r.errors)
                fprintf(stderr, "  %s:%d: %s\n", e.file.c_str(), e.line, e.msg.c_str());
            fails++;
        }
    }
    /* `base equ *` is the same address as the next label. Both have to move
       together, or mark-base becomes the pass-1 inflation instead of 1. */
    {
        std::string src =
            "* Assembler: APW\n"
            "         org    $8000\n"
            "         longa  off\n";
        for (int i = 0; i < 40; i++)
            src += "         lda    zp\n";
        src +=
            "base     equ    *\n"
            "         nop\n"
            "mark     nop\n"
            "         dc.b   mark-base\n"
            "zp       equ    $10\n"
            "         rts\n";
        qasm::Options opt;
        qasm::Result r = qasm::assemble_string(src, "apw-phase-equ", opt);
        /* 40 direct-page LDA, two NOP, the difference byte, RTS. */
        if (!r.ok() || r.bytes.size() != 84 || r.bytes[82] != 0x01 || r.bytes.back() != 0x60) {
            fprintf(stderr, "FAIL apw-phase-equ ok=%d len=%zu byte=%02X\n",
                    r.ok() ? 1 : 0, r.bytes.size(),
                    r.bytes.size() > 82 ? r.bytes[82] : 0);
            for (const auto &e : r.errors)
                fprintf(stderr, "  %s:%d: %s\n", e.file.c_str(), e.line, e.msg.c_str());
            fails++;
        }
    }
    {
        qasm::Options opt;
        qasm::Result r = qasm::assemble_string(
            ".p816\n"
            ".org $8000\n"
            ".set STEP, 1\n"
            ".set STEP, STEP+1\n"
            ".byte STEP\n",
            "ca65-set-freeze", opt);
        if (!r.ok() || r.bytes.size() != 1 || r.bytes[0] != 0x02) {
            fprintf(stderr, "FAIL ca65-set-freeze ok=%d len=%zu byte=%02X\n",
                    r.ok() ? 1 : 0, r.bytes.size(),
                    r.bytes.empty() ? 0 : r.bytes[0]);
            for (const auto &e : r.errors)
                fprintf(stderr, "  %s:%d: %s\n", e.file.c_str(), e.line, e.msg.c_str());
            fails++;
        }
    }

    const uint8_t bank[] = {0xA9, 0x12};
    expect_ok(
        "         org    $8000\n"
        "         lda    #A$123456\n",
        bank, sizeof(bank), "merlin-hash-a");

    const uint8_t mpw[] = {0xEA, 0x20, 0x00, 0x00, 0x00, 0x00, 0x6B, 0x60};
    expect_syn(
        "* Assembler: MPW\n"
        "         machine m65816\n"
        "         org    $8000\n"
        "one      proc\n"
        "         nop\n"
        "         endp\n"
        "code     proc\n"
        "         import hook\n"
        "         jsr    hook\n"
        "         dc.w   hook\n"
        "         rtl\n"
        "         endp\n"
        "         rts\n",
        mpw, sizeof(mpw), "apw-mpw-proc", "apw");

    if (qasm::identify_syntax(
            " longa off\n longi off\n anop\n dc i1'$01'\n") != qasm::Syntax::Orca) {
        fprintf(stderr, "FAIL identify orca stays orca\n");
        fails++;
    }
    if (qasm::identify_syntax(
            " absaddr off\n longa off\n dc i1'$01'\n") != qasm::Syntax::Apw) {
        fprintf(stderr, "FAIL identify absaddr is apw\n");
        fails++;
    }
    if (qasm::identify_syntax(
            ".p816\n.org $8000\nabsaddr: .byte 1\n") != qasm::Syntax::Ca65) {
        fprintf(stderr, "FAIL identify ca65 keeps absaddr label\n");
        fails++;
    }

    qasm::Options mpw_opt;
    mpw_opt.syntax = "mpw";
    qasm::Result rm = qasm::assemble_string(" org $8000\n rts\n", "mpw-opt", mpw_opt);
    if (!rm.ok() || rm.syntax != "apw" || rm.bytes.size() != 1 || rm.bytes[0] != 0x60) {
        fprintf(stderr, "FAIL --syntax mpw syntax=%s bytes=%zu\n",
                rm.syntax.c_str(), rm.bytes.size());
        for (const auto &e : rm.errors)
            fprintf(stderr, "  %s\n", e.msg.c_str());
        fails++;
    }

    const uint8_t thenb[] = {0xA9, 0x42, 0x60};
    expect_syn(
        "* Assembler: APW\n"
        "         org    $8000\n"
        "         longa  off\n"
        "         if     0 then\n"
        "         lda    #$ff\n"
        "         endif\n"
        "         if     1 then\n"
        "         lda    #$42\n"
        "         else\n"
        "         lda    #$00\n"
        "         endif\n"
        "         rts\n",
        thenb, sizeof(thenb), "apw-if-then", "apw");

    const uint8_t gotob[] = {0xA9, 0x01, 0x60};
    expect_syn(
        "* Assembler: APW\n"
        "         org    $8000\n"
        "         longa  off\n"
        "         lda    #$01\n"
        "         if     1 goto .skip\n"
        "         lda    #$ff\n"
        ".skip\n"
        "         rts\n",
        gotob, sizeof(gotob), "apw-if-goto", "apw");

    /* A GOTO inside a false IF must not jump past the ENDIF. */
    const uint8_t nest[] = {0xA9, 0x42, 0x60};
    expect_syn(
        "* Assembler: APW\n"
        "         org    $8000\n"
        "         longa  off\n"
        "         if     0 then\n"
        "         if     1 goto .after\n"
        "         nop\n"
        "         endif\n"
        "         lda    #$42\n"
        ".after\n"
        "         rts\n",
        nest, sizeof(nest), "apw-goto-nested", "apw");

    const uint8_t dcbb[] = {0xEE, 0xEE, 0xEE};
    expect_syn(
        "* Assembler: APW\n"
        "         org    $8000\n"
        "         dcb.b  3,$ee\n",
        dcbb, sizeof(dcbb), "apw-dcb-b", "apw");

    const uint8_t semi[] = {0x41, 0x42};
    expect_syn(
        "* Assembler: APW\n"
        "         org    $8000\n"
        "         msb    off\n"
        "         dc.b   'AB';\n",
        semi, sizeof(semi), "apw-semi", "apw");

    const uint8_t lenb[] = {0x01};
    expect_syn(
        "* Assembler: APW\n"
        "         org    $8000\n"
        "meslen   equ    &len('AB')-1\n"
        "         dc.b   meslen\n",
        lenb, sizeof(lenb), "apw-len", "apw");

    const uint8_t modb[] = {0x05};
    expect_syn(
        "* Assembler: APW\n"
        "         org    $8000\n"
        "         dc.b   ($105 mod $100)\n",
        modb, sizeof(modb), "apw-mod", "apw");

    const uint8_t dca[] = {0x56, 0x34, 0x12};
    expect_syn(
        "* Assembler: APW\n"
        "         org    $8000\n"
        "         dc.a   $123456\n",
        dca, sizeof(dca), "apw-dc-a", "apw");

    /* MacRoman 0xB3 is '>=' in an APW source. */
    const uint8_t geb[] = {0x42};
    expect_syn(
        "* Assembler: APW\n"
        "         org    $8000\n"
        "         if     $10 \xB3 $10 goto .ok\n"
        "         dc.b   $ff\n"
        ".ok\n"
        "         dc.b   $42\n",
        geb, sizeof(geb), "apw-macroman-ge", "apw");

    {
        qasm::Options opt;
        qasm::Result r = qasm::assemble_string(
            "* Assembler: APW\n"
            "         org    $8000\n"
            "         if     0 then\n"
            "         aerror 'nope'\n"
            "         endif\n"
            "         rts\n",
            "apw-aerror-hidden", opt);
        if (!r.ok() || r.bytes.size() != 1 || r.bytes[0] != 0x60) {
            fprintf(stderr, "FAIL apw-aerror-hidden ok=%d\n", r.ok() ? 1 : 0);
            for (const auto &e : r.errors)
                fprintf(stderr, "  %s\n", e.msg.c_str());
            fails++;
        }
    }
    {
        qasm::Options opt;
        qasm::Result r = qasm::assemble_string(
            "* Assembler: APW\n"
            "         org    $8000\n"
            "         aerror 'boom'\n"
            "         rts\n",
            "apw-aerror", opt);
        if (r.ok() || r.errors.empty() ||
            r.errors[0].msg.find("boom") == std::string::npos) {
            fprintf(stderr, "FAIL apw-aerror\n");
            for (const auto &e : r.errors)
                fprintf(stderr, "  %s\n", e.msg.c_str());
            fails++;
        }
    }

    /* IMPORT after the label must not collapse the address to direct page. */
    const uint8_t imp[] = {0x4C, 0x03, 0x80, 0x60, 0xAD, 0x00, 0x80};
    expect_syn(
        "* Assembler: APW\n"
        "         org    $8000\n"
        "         longa  off\n"
        "warmdos  jmp    next\n"
        "next     rts\n"
        "         import warmdos\n"
        "         lda    warmdos\n",
        imp, sizeof(imp), "apw-import-after", "apw");

    /* A repeated EQU is visible to the next line, not only the last value. */
    const uint8_t requ[] = {0x10, 0x20};
    expect_syn(
        "* Assembler: APW\n"
        "         org    $8000\n"
        "max      equ    $10\n"
        "         dc.b   max\n"
        "max      equ    $20\n"
        "         dc.b   max\n",
        requ, sizeof(requ), "apw-requ", "apw");

    /* APW `>>` is a logical shift. The high byte of $02FF is $02. */
    const uint8_t shb[] = {0xA9, 0x02};
    expect_syn(
        "* Assembler: APW\n"
        "         org    $8000\n"
        "         lda    #inline>>8\n"
        "inline   equ    $02ff\n",
        shb, sizeof(shb), "apw-shift", "apw");

    /* Each PROC keeps its own procstart. A shared symbol would be 30 30. */
    const uint8_t psb[] = {0x20, 0x30};
    expect_syn(
        "* Assembler: APW\n"
        "         org    $2000\n"
        "a        proc\n"
        "procstart dc.b  >procstart\n"
        "         endp\n"
        "         org    $3000\n"
        "b        proc\n"
        "procstart dc.b  >procstart\n"
        "         endp\n",
        psb, sizeof(psb), "apw-procstart", "apw");

    /* Two `@1` labels in one proc. The far one would be out of range. */
    {
        qasm::Options opt;
        qasm::Result r = qasm::assemble_string(
            "* Assembler: APW\n"
            "         org    $8000\n"
            "one      proc\n"
            "         bcc    @1\n"
            "@1       rts\n"
            "mid      nop\n"
            "         ds.b   200\n"
            "         bcc    @1\n"
            "@1       rts\n"
            "         endp\n",
            "apw-at", opt);
        const uint8_t head[] = {0x90, 0x00, 0x60, 0xEA};
        const uint8_t tail[] = {0x90, 0x00, 0x60};
        bool bad = !r.ok() || r.bytes.size() != 207 ||
                   memcmp(r.bytes.data(), head, 4) != 0 ||
                   memcmp(r.bytes.data() + 204, tail, 3) != 0;
        if (!bad) {
            for (size_t i = 4; i < 204; i++)
                if (r.bytes[i] != 0) bad = true;
        }
        if (bad) {
            fprintf(stderr, "FAIL apw-at ok=%d bytes=%zu\n", r.ok() ? 1 : 0, r.bytes.size());
            for (const auto &e : r.errors)
                fprintf(stderr, "  %s\n", e.msg.c_str());
            fails++;
        }
    }

    /* EXPORT keeps the name global. An unexported name stays in its proc. */
    const uint8_t exb[] = {0x11, 0x20};
    expect_syn(
        "* Assembler: APW\n"
        "         org    $2000\n"
        "a        proc\n"
        "         export seen\n"
        "seen     dc.b   $11\n"
        "         endp\n"
        "b        proc\n"
        "         dc.b   >seen\n"
        "         endp\n",
        exb, sizeof(exb), "apw-export", "apw");
    {
        qasm::Options opt;
        qasm::Result r = qasm::assemble_string(
            "* Assembler: APW\n"
            "         org    $2000\n"
            "a        proc\n"
            "hidden   dc.b   $22\n"
            "         endp\n"
            "b        proc\n"
            "         dc.b   hidden\n"
            "         endp\n",
            "apw-proc-hide", opt);
        if (r.ok()) {
            fprintf(stderr, "FAIL apw-proc-hide: hidden label leaked\n");
            fails++;
        }
    }

    qasm::Options orc;
    orc.syntax = "orca";
    qasm::Result ro = qasm::assemble_string(
        " longa off\n org $8000\n absaddr on\n rts\n", "orca-abs", orc);
    if (ro.ok() || ro.syntax != "orca") {
        fprintf(stderr, "FAIL orca rejects absaddr ok=%d syntax=%s\n",
                ro.ok() ? 1 : 0, ro.syntax.c_str());
        fails++;
    }
}

static void test_pcode_dump(void)
{
    const char *src =
        "              ORG   $8000\n"
        "BELL          EQU   $FBDD\n"
        "START         JSR   BELL\n"
        "              RTS\n";
    qasm::Options opt;
    opt.dump_pcode = true;
    qasm::Result r = qasm::assemble_string(src, "hello", opt);
    if (!r.ok() || r.syntax != "merlin" ||
        r.pcode.find("syntax=merlin") == std::string::npos ||
        r.pcode.find("P_ORG") == std::string::npos ||
        r.pcode.find("P_EQU") == std::string::npos ||
        r.pcode.find("P_INST") == std::string::npos) {
        fprintf(stderr, "FAIL pcode-dump syntax=%s\n%s\n", r.syntax.c_str(), r.pcode.c_str());
        fails++;
    }

    const char *m32 =
        "* Assembler: Merlin 32\n"
        "          ORG   $8000\n"
        "          RTS\n";
    qasm::Result r2 = qasm::assemble_string(m32, "m32", opt);
    if (!r2.ok() || r2.syntax != "merlin32" || r2.bytes.size() != 1 || r2.bytes[0] != 0x60) {
        fprintf(stderr, "FAIL merlin32 marker syntax=%s bytes=%zu errors=%zu\n",
                r2.syntax.c_str(), r2.bytes.size(), r2.errors.size());
        for (const auto &e : r2.errors)
            fprintf(stderr, "  %s\n", e.msg.c_str());
        fails++;
    }

    if (qasm::identify_syntax(" ORG $8000\n JSR $FBDD\n RTS\n") != qasm::Syntax::Merlin) {
        fprintf(stderr, "FAIL identify plain merlin\n");
        fails++;
    }

    qasm::Options bad;
    bad.syntax = "z80";
    qasm::Result r3 = qasm::assemble_string(" RTS\n", "bad", bad);
    if (r3.ok() || r3.errors.empty() ||
        r3.errors[0].msg.find("unknown syntax") == std::string::npos) {
        fprintf(stderr, "FAIL unknown syntax\n");
        fails++;
    }

    qasm::Options au;
    au.syntax = "auto";
    qasm::Result r4 = qasm::assemble_string(
        ".p816\n.org $8000\nbell = $fbdd\njsr bell\nrts\n", "auto-ca", au);
    if (!r4.ok() || r4.syntax != "ca65" || r4.bytes.size() != 4 ||
        r4.bytes[0] != 0x20 || r4.bytes[3] != 0x60) {
        fprintf(stderr, "FAIL syntax auto ca65 syntax=%s len=%zu\n",
                r4.syntax.c_str(), r4.bytes.size());
        for (const auto &e : r4.errors)
            fprintf(stderr, "  %s\n", e.msg.c_str());
        fails++;
    }
}

int main(void)
{
    test_hello();
    test_force_prefixes();
    test_macro_semicolon();
    test_native_merlin_format();
    test_native_string_space();
    test_mx_imm();
    test_sep_rep();
    test_hex_asc();
    test_expr_ltr();
    test_dp_vs_abs();
    test_branch();
    test_do();
    test_macro();
    test_local();
    test_long();
    test_ds_da();
    test_strl();
    test_lup();
    test_lup_at();
    test_macro_uniquify();
    test_put();
    test_use();
    test_var_put();
    test_flo();
    test_date();
    test_indy();
    test_brk_wdm();
    test_jml_jsl_abs();
    test_acc_a();
    test_dfb_hash_sel();
    test_ldaz();
    test_org_resume();
    test_ext_list();
    test_usr_width();
    test_rel_ext();
    test_expr_cmp();
    test_syntax_cross();
    test_apw();
    test_pcode_dump();
    if (fails) {
        fprintf(stderr, "%d test(s) failed\n", fails);
        return 1;
    }
    printf("all tests passed\n");
    return 0;
}
