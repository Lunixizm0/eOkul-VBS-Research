#!/usr/bin/env python3
"""Dump the libflutter .got.plt of the running original app from memory (page-aligned reads)."""
import subprocess, struct, sys, zipfile, re

S = ['adb', '-s', 'emulator-5554']
PKG = 'com.meb.vbsmobil'
APK = '../split_config.arm64_v8a.apk'

def sh(cmd, timeout=60):
    return subprocess.run(S + ['shell', cmd], capture_output=True, text=True, timeout=timeout).stdout

pid = sh(f'pidof {PKG}').strip().split()
if not pid:
    sys.exit('app is not running')
pid = pid[0]
maps = sh(f'su 0 cat /proc/{pid}/maps')
open('/tmp/maps_live.txt', 'w').write(maps)

zf = zipfile.ZipFile(APK)
info = zf.getinfo('lib/arm64-v8a/libflutter.so')
with open(APK, 'rb') as f:
    f.seek(info.header_offset)
    hdr = f.read(30)
    nlen, elen = struct.unpack_from('<HH', hdr, 26)
data_off = info.header_offset + 30 + nlen + elen
print('APK veri offseti: 0x%x' % data_off)

regions = []
for line in maps.splitlines():
    m = re.match(r'([0-9a-f]+)-([0-9a-f]+) (.{4}) ([0-9a-f]+) \S+ \S+\s*(.*)', line)
    if not m: continue
    regions.append(dict(st=int(m.group(1),16), en=int(m.group(2),16), perms=m.group(3),
                        off=int(m.group(4),16), path=m.group(5)))

def read(addr, n):
    out = bytearray()
    cur = addr
    end = addr + n
    while cur < end:
        page = cur & ~0xfff
        cnt = 1
        # stay within a single page
        while (page + cnt*4096) < end and cnt < 16:
            cnt += 1
        r = subprocess.run(S + ['shell', f'su 0 dd if=/proc/{pid}/mem bs=4096 skip={page//4096} count={cnt} 2>/dev/null'],
                           capture_output=True, timeout=40).stdout
        if not r:
            return bytes(out)
        out += r
        cur = page + len(r)
    return bytes(out[:n])

base = None
for r in sorted(regions, key=lambda x: x['st']):
    if r['off'] < data_off: continue
    cand = r['st'] - (r['off'] - data_off)
    if read(cand, 4) != b'\x7fELF':
        continue
    probe = read(cand + 0x46f5d0, 8)
    if probe == bytes.fromhex('3f2303d5ffc301d1'):
        base = cand
        print('libflutter base = 0x%x (region 0x%x off 0x%x %s)' % (base, r['st'], r['off'], r['perms']))
        break
if base is None:
    print('base not found; first region candidates:')
    for r in sorted(regions, key=lambda x: x['st'])[:10]:
        print('  0x%x off=0x%x %s %s' % (r['st'], r['off'], r['perms'], r['path'][:60]))
    sys.exit(1)

got = read(base + 0xaa39a0, 2912)
print('dump:', len(got), 'bytes')
open('/tmp/got_live.bin','wb').write(got)
open('/tmp/base_live.txt','w').write('%x' % base)
vals = struct.unpack('<%dQ' % (len(got)//8), got)
plt0 = base + 0xa3c080
print('PLT0 =', hex(plt0), '| cozulmemis slot:', sum(1 for v in vals[3:] if v == plt0))

def module_of(addr):
    for r in regions:
        if r['st'] <= addr < r['en'] and r['path']:
            return r['path'], r['off'] + (addr - r['st'])
    return None, None

for i, v in enumerate(vals[3:], start=3):
    if v == plt0 or v == 0:
        continue
    p, off = module_of(v)
    if p:
        print('  slot %3d -> %s + 0x%x' % (i, p.split('/')[-1], off))
    else:
        print('  slot %3d -> anon 0x%x' % (i, v))
