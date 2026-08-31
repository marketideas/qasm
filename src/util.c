#include "merlin.h"

#include <ctype.h>
#include <stdlib.h>
#include <string.h>

void merlin_strlcpy(char *dst, const char *src, size_t n)
{
    if (n == 0) return;
    size_t i = 0;
    while (src[i] && i + 1 < n) {
        dst[i] = src[i];
        i++;
    }
    dst[i] = '\0';
}

int merlin_stricmp(const char *a, const char *b)
{
    for (;;) {
        unsigned char ca = (unsigned char)*a++;
        unsigned char cb = (unsigned char)*b++;
        int d = tolower(ca) - tolower(cb);
        if (d != 0 || ca == 0) return d;
    }
}

int merlin_strnicmp(const char *a, const char *b, size_t n)
{
    while (n--) {
        unsigned char ca = (unsigned char)*a++;
        unsigned char cb = (unsigned char)*b++;
        int d = tolower(ca) - tolower(cb);
        if (d != 0 || ca == 0) return d;
    }
    return 0;
}

int merlin_is_eol(unsigned char c)
{
    /* LF, CR, and Merlin's high-ASCII CR ($8D). */
    return c == 0x0A || c == 0x0D || c == 0x8D;
}

int merlin_is_field_tab(unsigned char c)
{
    /* Native Merlin column tab is $A0 (space with bit 7 set).
       $09 and $89 (TAB, TAB+high) also separate fields. */
    return c == 0xA0 || c == 0x09 || c == 0x89;
}

unsigned char merlin_ascii(unsigned char c)
{
    return (unsigned char)(c & 0x7F);
}

char *merlin_trim(char *s)
{
    while (*s && (isspace((unsigned char)*s) || (unsigned char)*s == 0xA0)) s++;
    if (*s == 0) return s;
    char *e = s + strlen(s);
    while (e > s && (isspace((unsigned char)e[-1]) || (unsigned char)e[-1] == 0xA0)) e--;
    *e = '\0';
    return s;
}

void merlin_strip_high_bit(char *s, size_t n)
{
    for (size_t i = 0; i < n; i++) {
        unsigned char c = merlin_ascii((unsigned char)s[i]);
        s[i] = c ? (char)c : ' ';
    }
}

char *merlin_read_file(const char *path, size_t *len_out)
{
    FILE *fp = fopen(path, "rb");
    if (!fp) return NULL;
    if (fseek(fp, 0, SEEK_END) != 0) {
        fclose(fp);
        return NULL;
    }
    long n = ftell(fp);
    if (n < 0) {
        fclose(fp);
        return NULL;
    }
    rewind(fp);
    char *buf = (char *)malloc((size_t)n + 1);
    if (!buf) {
        fclose(fp);
        return NULL;
    }
    size_t got = fread(buf, 1, (size_t)n, fp);
    fclose(fp);
    buf[got] = '\0';
    /* Leave high bits and $A0 field tabs intact. parse_line_text
       understands native Merlin encoding. */
    if (len_out) *len_out = got;
    return buf;
}
