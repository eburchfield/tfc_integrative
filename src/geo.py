import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
import numpy as np, struct, tifffile

def lzw_decode(data):
    # TIFF LZW (MSB-first, early change)
    out = bytearray()
    table = [bytes([i]) for i in range(256)] + [b'', b'']
    bitpos = 0; nbits = 9; prev = None
    n = len(data) * 8
    val = int.from_bytes(data, 'big')
    total = len(data) * 8
    while bitpos + nbits <= total:
        code = (val >> (total - bitpos - nbits)) & ((1 << nbits) - 1)
        bitpos += nbits
        if code == 256:
            table = table[:258]; nbits = 9; prev = None; continue
        if code == 257: break
        if prev is None:
            entry = table[code]; out += entry; prev = entry; continue
        if code < len(table):
            entry = table[code]; table.append(prev + entry[:1])
        else:
            entry = prev + prev[:1]; table.append(entry)
        out += entry; prev = entry
        ln = len(table) + 1
        if ln >= 512 and nbits == 9: nbits = 10
        elif ln >= 1024 and nbits == 10: nbits = 11
        elif ln >= 2048 and nbits == 11: nbits = 12
    return bytes(out)

def read_tif(path):
    t = tifffile.TiffFile(path); p = t.pages[0]
    w, h = p.imagewidth, p.imagelength
    spp = p.samplesperpixel
    offs = p.tags['StripOffsets'].value; cnts = p.tags['StripByteCounts'].value
    rps = p.tags['RowsPerStrip'].value
    fh = t.filehandle
    buf = bytearray()
    for o, c in zip(offs, cnts):
        fh.seek(o); raw = fh.read(c)
        buf += lzw_decode(raw) if p.compression == 5 else raw
    a = np.frombuffer(bytes(buf[:w*h*spp*4]), dtype='<f4').reshape(h, w, spp)
    sc = p.tags['ModelPixelScaleTag'].value; tp = p.tags['ModelTiepointTag'].value
    x0, y0 = tp[3], tp[4]
    extent = (x0, x0 + w*sc[0], y0 - h*sc[1], y0)
    return a, extent, sc

def read_shp(path):
    d = open(path, 'rb').read()
    pos = 100; shapes = []
    while pos < len(d):
        rec_len = struct.unpack('>i', d[pos+4:pos+8])[0]*2
        c = d[pos+8:pos+8+rec_len]; pos += 8 + rec_len
        st = struct.unpack('<i', c[:4])[0]
        if st not in (5, 15, 25): shapes.append([]); continue
        nparts, npts = struct.unpack('<2i', c[36:44])
        parts = struct.unpack(f'<{nparts}i', c[44:44+4*nparts])
        pts = np.frombuffer(c[44+4*nparts:44+4*nparts+16*npts], dtype='<f8').reshape(npts, 2)
        idx = list(parts) + [npts]
        shapes.append([pts[idx[i]:idx[i+1]] for i in range(nparts)])
    return shapes

def read_dbf(path):
    d = open(path, 'rb').read()
    n, hl, rl = struct.unpack('<IHH', d[4:12])
    fields = []; p = 32
    while d[p] != 0x0D:
        name = d[p:p+11].split(b'\0')[0].decode(); ln = d[p+16]
        fields.append((name, ln)); p += 32
    recs = []
    for i in range(n):
        r = d[hl + i*rl + 1: hl + (i+1)*rl]; o = 0; rec = {}
        for name, ln in fields:
            rec[name] = r[o:o+ln].decode('latin1').strip(); o += ln
        recs.append(rec)
    return recs
