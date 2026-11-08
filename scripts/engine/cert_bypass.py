#!/usr/bin/env python3
"""Disable TLS certificate verification in libflutter.so (Flutter 3.35.6).

Patches both BoringSSL entry points to `mov w0,#1 ; ret` (0x52800020, 0xD65F03C0):

  ssl_crypto_x509_session_verify_cert_chain   0x716b60
  X509_verify_cert                            0x6fb758

Effect: any server certificate is accepted, so certificate pinning cannot reject a
connection. Addresses are valid for Flutter 3.35.6 (engine d2913632…); re-derive them
with `readelf -sW` for any other revision.

usage: cert_bypass.py [in.so] [out.so]
"""
import struct
import sys

IN = sys.argv[1] if len(sys.argv) > 1 else 'lib/engine/3.35.6/libflutter-unstripped.so'
OUT = sys.argv[2] if len(sys.argv) > 2 else 'lib/engine/3.35.6/libflutter-patched.so'

SYMS = {
    'ssl_crypto_x509_session_verify_cert_chain': 0x716b60,
    'X509_verify_cert': 0x6fb758,
}

d = bytearray(open(IN, 'rb').read())

# ELF program headers -> vaddr/file-offset mapping
e_phoff, = struct.unpack_from('<Q', d, 0x20)
e_phentsize, = struct.unpack_from('<H', d, 0x36)
e_phnum, = struct.unpack_from('<H', d, 0x38)
segs = []
for i in range(e_phnum):
    p_type, _flags, p_off, p_va, _pa, p_fsz, _msz, _al = struct.unpack_from(
        '<IIQQQQQQ', d, e_phoff + i * e_phentsize)
    if p_type == 1:  # PT_LOAD
        segs.append((p_va, p_va + p_fsz, p_off))


def foff(va):
    for vs, ve, off in segs:
        if vs <= va < ve:
            return off + (va - vs)
    raise SystemExit('address is not inside any PT_LOAD: 0x%x' % va)


for name, va in SYMS.items():
    o = foff(va)
    print('%-42s va=0x%-6x off=0x%-6x before=%s' % (name, va, o, d[o:o + 8].hex()))
    d[o:o + 8] = struct.pack('<II', 0x52800020, 0xD65F03C0)
    print('%-42s                      after=%s' % ('', d[o:o + 8].hex()))

open(OUT, 'wb').write(bytes(d))
print('wrote:', OUT)
