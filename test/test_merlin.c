#include "merlin.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int fails = 0;

static void expect_ok(const char *src, const uint8_t *want, size_t n, const char *tag)
{
    MerlinOptions opt;
    merlin_options_default(&opt);
    AsmResult r;
    int rc = merlin_assemble_string(src, tag, &opt, &r);
    if (rc != 0) {
        fprintf(stderr, "FAIL %s: assemble errors:\n", tag);
        for (int i = 0; i < r.nerrors; i++)
            fprintf(stderr, "  %s:%d: %s\n", r.errors[i].file, r.errors[i].line, r.errors[i].msg);
        fails++;
        merlin_result_free(&r);
        return;
    }
    if (r.len != n) {
        fprintf(stderr, "FAIL %s: len got %zu want %zu\n", tag, r.len, n);
        fails++;
        merlin_result_free(&r);
        return;
    }
    if (memcmp(r.bytes, want, n) != 0) {
        fprintf(stderr, "FAIL %s: bytes\n  got ", tag);
        for (size_t i = 0; i < n; i++) fprintf(stderr, "%02X ", r.bytes[i]);
        fprintf(stderr, "\n  exp ");
        for (size_t i = 0; i < n; i++) fprintf(stderr, "%02X ", want[i]);
        fprintf(stderr, "\n");
        fails++;
    }
    merlin_result_free(&r);
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

static void test_indy(void)
{
    const char *src =
        "          ORG   $8000\n"
        "          LDA   ($10),Y\n"
        "          LDA   $10,S\n"
        "          PHK\n"
        "          PLB\n";
    const uint8_t want[] = {0xB1, 0x10, 0xA3, 0x10, 0x4B, 0xAB};
    expect_ok(src, want, sizeof(want), "indy/s");
}

int main(void)
{
    test_hello();
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
    test_indy();
    if (fails) {
        fprintf(stderr, "%d test(s) failed\n", fails);
        return 1;
    }
    printf("all tests passed\n");
    return 0;
}
