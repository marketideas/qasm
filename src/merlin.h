#ifndef MERLIN_H
#define MERLIN_H

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>

#define MERLIN_MAX_LINE  256
#define MERLIN_MAX_LABEL 80
#define MERLIN_MAX_OP    32
#define MERLIN_MAX_ERR   256
#define MERLIN_MAX_COND  16
#define MERLIN_MAX_MACNEST 16

typedef enum {
    DIALECT_8 = 8,
    DIALECT_16 = 16,
    DIALECT_16PLUS = 17
} Dialect;

typedef struct MerlinOptions {
    Dialect dialect;
    bool case_sensitive;
    bool algebraic;
    int start_mx;     /* 0–3; default 3 = %11 emulation */
    int start_xc;     /* 0=6502, 1=65C02, 2=65816 */
    const char *output_path;
    const char *listing_path;
} MerlinOptions;

typedef struct AsmError {
    char file[256];
    int line;
    char msg[256];
} AsmError;

typedef struct AsmResult {
    uint8_t *bytes;
    size_t len;
    uint32_t org;
    uint16_t filetype;     /* ProDOS type; 0x06 BIN default */
    char dsk_name[256];    /* from DSK/SAV if any */
    char *listing;
    AsmError errors[MERLIN_MAX_ERR];
    int nerrors;
} AsmResult;

void merlin_options_default(MerlinOptions *o);
int  merlin_assemble_file(const char *path, const MerlinOptions *opt, AsmResult *out);
int  merlin_assemble_string(const char *src, const char *name,
                            const MerlinOptions *opt, AsmResult *out);
void merlin_result_free(AsmResult *r);

/* --- internals shared by translation units --- */

enum {
    CPU_6502 = 0,
    CPU_65C02 = 1,
    CPU_65816 = 2
};

typedef enum {
    AM_NONE = 0,
    AM_IMP,
    AM_IMM,      /* size from M or X */
    AM_IMM8,
    AM_IMM16,    /* PEA */
    AM_DP,
    AM_DPX,
    AM_DPY,
    AM_IND,      /* (dp) */
    AM_INDX,     /* (dp,X) */
    AM_INDY,     /* (dp),Y */
    AM_INDL,     /* [dp] */
    AM_INDLY,    /* [dp],Y */
    AM_ABS,
    AM_ABSX,
    AM_ABSY,
    AM_LONG,
    AM_LONGX,
    AM_SR,
    AM_SRIY,
    AM_REL,
    AM_RELL,
    AM_ABSIND,   /* (abs) */
    AM_ABSINDX,  /* (abs,X) */
    AM_ABSINDL,  /* [abs] */
    AM_BLK,
    AM_COUNT
} AddrMode;

enum {
    SYN_IMP = 0,
    SYN_IMM,
    SYN_ABS,     /* bare expression */
    SYN_X,
    SYN_Y,
    SYN_S,
    SYN_IND,
    SYN_INDX,
    SYN_INDY,
    SYN_INDL,
    SYN_INDLY,
    SYN_SIY,
    SYN_BLK
};

enum {
    FORCE_NONE = 0,
    FORCE_DP,
    FORCE_ABS,
    FORCE_LONG
};

typedef struct SrcLine {
    char *file;
    int lineno;
    char *raw;
    char label[MERLIN_MAX_LABEL];
    char opcode[MERLIN_MAX_OP];
    char operand[MERLIN_MAX_LINE];
    bool has_label;
    bool is_comment;
} SrcLine;

typedef struct OperandForm {
    int syntax;
    int force;
    int byte_sel;          /* 0 or '<' '>' '^' */
    char expr[MERLIN_MAX_LINE];
    char expr2[MERLIN_MAX_LINE];
} OperandForm;

typedef struct ExprCtx ExprCtx;

void  merlin_strlcpy(char *dst, const char *src, size_t n);
int   merlin_stricmp(const char *a, const char *b);
int   merlin_strnicmp(const char *a, const char *b, size_t n);
char *merlin_trim(char *s);
char *merlin_read_file(const char *path, size_t *len_out);
void  merlin_strip_high_bit(char *s, size_t n);
int   merlin_is_eol(unsigned char c);
int   merlin_is_field_tab(unsigned char c);
unsigned char merlin_ascii(unsigned char c);

int   parse_source(const char *src, const char *name, SrcLine **lines, int *nlines);
void  free_source(SrcLine *lines, int nlines);
int   parse_line_text(const char *text, SrcLine *out);
int   parse_operand_form(const char *operand, OperandForm *form);

void  expr_init(ExprCtx *ctx);
int   eval_expr(ExprCtx *ctx, const char *expr, int64_t *out, char *err, size_t errn);

const char *opcode_canonical(const char *name, char *tmp, size_t tmpn,
                             int *force_out, bool *long_mn);
int  opcode_encode(const char *cname, AddrMode am, int cpu, uint8_t *opc);
bool opcode_supports(const char *cname, AddrMode am, int cpu);
bool is_branch(const char *cname);
bool is_branch_long(const char *cname);
bool is_alu_acc(const char *cname); /* ASL/LSR/ROL/ROR/DEC/INC implied */
int  imm_width_reg(const char *cname); /* 0=M, 1=X, -1=n/a, 8=always8, 16=always16 */

int assemble_lines(SrcLine *lines, int nlines, const MerlinOptions *opt, AsmResult *out);

struct ExprCtx {
    uint32_t pc;
    int mx;
    bool algebraic;
    bool case_sensitive;
    int pass;
    void *asm_ptr; /* Asm * */
    int (*lookup)(void *asm_ptr, const char *name, int64_t *val, bool *known);
};

#endif
