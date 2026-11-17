#include <stdint.h>
#include <string.h>
#include <stdlib.h>

/* TIFF LZW decode (MSB-first, early change). Returns bytes written. */
long lzw_decode(const uint8_t *in, long inlen, uint8_t *out, long outcap) {
    static uint16_t prefix[4096]; static uint8_t suffix[4096], first[4096]; static uint16_t len[4096];
    static uint8_t stack[4097];
    long op = 0; long bitpos = 0, total = inlen * 8;
    int nbits = 9, next = 258, prev = -1;
    for (int i = 0; i < 256; i++) { prefix[i] = 0xFFFF; suffix[i] = i; first[i] = i; len[i] = 1; }
    while (bitpos + nbits <= total) {
        int code = 0;
        for (int b = 0; b < nbits; b++) {
            long bp = bitpos + b;
            code = (code << 1) | ((in[bp >> 3] >> (7 - (bp & 7))) & 1);
        }
        bitpos += nbits;
        if (code == 256) { next = 258; nbits = 9; prev = -1; continue; }
        if (code == 257) break;
        if (prev == -1) {
            if (op < outcap) out[op++] = (uint8_t)code;
            prev = code; continue;
        }
        int c; uint8_t fc;
        if (code < next) { c = code; fc = first[code]; }
        else { c = prev; fc = first[prev]; }
        /* emit string for c */
        int sp = 0; int k = c;
        while (k != 0xFFFF && sp < 4097) { stack[sp++] = suffix[k]; k = prefix[k]; }
        while (sp > 0 && op < outcap) out[op++] = stack[--sp];
        if (code >= next && op < outcap) out[op++] = fc;
        if (next < 4096) {
            prefix[next] = prev; suffix[next] = fc; first[next] = first[prev]; len[next] = len[prev] + 1; next++;
        }
        prev = code;
        if (next + 1 >= 512 && nbits == 9) nbits = 10;
        else if (next + 1 >= 1024 && nbits == 10) nbits = 11;
        else if (next + 1 >= 2048 && nbits == 11) nbits = 12;
    }
    return op;
}

/* randomForest classification votes. Arrays are (ntree, nrnodes) row-major.
   X is (n, p) row-major doubles. votes[i] += 1 when terminal nodepred == target. */
void rf_votes(const int32_t *status, const int32_t *var, const int32_t *left, const int32_t *right,
              const int32_t *pred, const double *split, int ntree, int nrnodes,
              const double *X, long n, int p, int target, int32_t *votes) {
    for (int t = 0; t < ntree; t++) {
        const int32_t *st = status + (long)t * nrnodes, *vr = var + (long)t * nrnodes,
                      *L = left + (long)t * nrnodes, *R = right + (long)t * nrnodes, *pr = pred + (long)t * nrnodes;
        const double *sp = split + (long)t * nrnodes;
        for (long i = 0; i < n; i++) {
            int k = 0; const double *x = X + i * p;
            while (st[k] != -1) k = (x[vr[k]] <= sp[k]) ? L[k] : R[k];
            if (pr[k] == target) votes[i]++;
        }
    }
}
