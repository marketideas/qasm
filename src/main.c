#include "merlin.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void usage(void)
{
    fprintf(stderr,
            "usage: merlin [options] file.s\n"
            "  -o FILE            object output\n"
            "  -l FILE            listing (hex dump)\n"
            "  --dialect 16+|16|8  (default 16+)\n"
            "  --case-sensitive\n"
            "  --algebraic\n");
}

int main(int argc, char **argv)
{
    MerlinOptions opt;
    merlin_options_default(&opt);
    const char *infile = NULL;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-h") == 0 || strcmp(argv[i], "--help") == 0) {
            usage();
            return 0;
        }
        if (strcmp(argv[i], "-o") == 0 && i + 1 < argc) {
            opt.output_path = argv[++i];
        } else if (strcmp(argv[i], "-l") == 0 && i + 1 < argc) {
            opt.listing_path = argv[++i];
        } else if (strcmp(argv[i], "--dialect") == 0 && i + 1 < argc) {
            const char *d = argv[++i];
            if (strcmp(d, "8") == 0) {
                opt.dialect = DIALECT_8;
                opt.start_xc = 0;
            } else if (strcmp(d, "16") == 0) {
                opt.dialect = DIALECT_16;
                opt.start_xc = 2;
            } else if (strcmp(d, "16+") == 0 || strcmp(d, "16plus") == 0) {
                opt.dialect = DIALECT_16PLUS;
                opt.start_xc = 2;
            } else {
                fprintf(stderr, "unknown dialect '%s'\n", d);
                return 2;
            }
        } else if (strcmp(argv[i], "--case-sensitive") == 0) {
            opt.case_sensitive = true;
        } else if (strcmp(argv[i], "--algebraic") == 0) {
            opt.algebraic = true;
        } else if (argv[i][0] == '-') {
            fprintf(stderr, "unknown option %s\n", argv[i]);
            usage();
            return 2;
        } else {
            infile = argv[i];
        }
    }
    if (!infile) {
        usage();
        return 2;
    }

    AsmResult r;
    int rc = merlin_assemble_file(infile, &opt, &r);
    for (int i = 0; i < r.nerrors; i++) {
        fprintf(stderr, "%s:%d: %s\n",
                r.errors[i].file[0] ? r.errors[i].file : infile,
                r.errors[i].line, r.errors[i].msg);
    }
    if (rc != 0) {
        merlin_result_free(&r);
        return 1;
    }

    const char *outpath = opt.output_path;
    char tmpout[512];
    if (!outpath) {
        if (r.dsk_name[0]) {
            outpath = r.dsk_name;
        } else {
            merlin_strlcpy(tmpout, infile, sizeof(tmpout));
            char *dot = strrchr(tmpout, '.');
            if (dot) strcpy(dot, ".bin");
            else strcat(tmpout, ".bin");
            outpath = tmpout;
        }
    }

    FILE *fp = fopen(outpath, "wb");
    if (!fp) {
        perror(outpath);
        merlin_result_free(&r);
        return 1;
    }
    fwrite(r.bytes, 1, r.len, fp);
    fclose(fp);
    printf("assembled %zu bytes at $%06X -> %s (typ $%02X)\n",
           r.len, r.org, outpath, r.filetype);

    if (opt.listing_path) {
        FILE *lf = fopen(opt.listing_path, "w");
        if (!lf) {
            perror(opt.listing_path);
        } else {
            fprintf(lf, "Merlin 16+ listing  org=$%06X  len=%zu\n", r.org, r.len);
            for (size_t i = 0; i < r.len; i += 16) {
                fprintf(lf, "%06X:", (unsigned)(r.org + (uint32_t)i));
                for (size_t j = 0; j < 16 && i + j < r.len; j++)
                    fprintf(lf, " %02X", r.bytes[i + j]);
                fprintf(lf, "\n");
            }
            fclose(lf);
        }
    }
    merlin_result_free(&r);
    return 0;
}
