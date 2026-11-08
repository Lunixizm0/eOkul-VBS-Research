#!/usr/bin/env python3
"""libflutter.so: add real JUMP_SLOT relocations for the GOT slots PairIP's VM
used to fill (the linker resolves all of them up front with BIND_NOW)."""
import struct, subprocess, sys, shutil

SRC = sys.argv[1] if len(sys.argv) > 1 else 'split/lib/arm64-v8a/libflutter.so'
DST = sys.argv[2] if len(sys.argv) > 2 else 'libflutter-gotpatched.so'

d = bytearray(open(SRC, 'rb').read())

e_shoff, = struct.unpack_from('<Q', d, 0x28)
e_shentsize, = struct.unpack_from('<H', d, 0x3a)
e_shnum, = struct.unpack_from('<H', d, 0x3c)
e_shstrndx, = struct.unpack_from('<H', d, 0x3e)

secs = {}
for i in range(e_shnum):
    v = struct.unpack_from('<IIQQQQIIQQ', d, e_shoff + i * e_shentsize)
    secs[i] = dict(nameoff=v[0], typ=v[1], addr=v[3], off=v[4], size=v[5], link=v[6], entsize=v[9])
shstr = secs[e_shstrndx]['off']
for i in secs:
    o = shstr + secs[i]['nameoff']
    secs[i]['name'] = d[o:d.index(b'\0', o)].decode()
byname = {s['name']: s for s in secs.values()}

ds, st_, rp, ro, dy = byname['.dynsym'], byname['.dynstr'], byname['.rela.plt'], byname['.rodata'], byname['.dynamic']

# --- dynsym ---
syms = []
for i in range(ds['size'] // 24):
    o = ds['off'] + i * 24
    nmoff, info, other, shndx, value, size = struct.unpack_from('<IBBHQQ', d, o)
    nm = d[st_['off'] + nmoff: d.index(b'\0', st_['off'] + nmoff)].decode('utf-8', 'replace')
    syms.append((nm, shndx))

# --- existing relocations ---
jmp = []
for i in range(rp['size'] // 24):
    off, info, add = struct.unpack_from('<QQq', d, rp['off'] + i * 24)
    jmp.append((off, info >> 32, info & 0xffffffff, add))
resolved = {x[0] for x in jmp}

# name -> dynsym index (learned from the existing relocations)
name2idx = {}
for off, si, t, add in jmp:
    name2idx.setdefault(syms[si][0], si)

# --- .plt stub names ---
out = subprocess.run(['llvm-objdump', '-d', '--section=.plt', SRC], capture_output=True, text=True).stdout
stubs = {}  # addr -> name
for line in out.splitlines():
    line = line.strip()
    if line.startswith('0000') and '<' in line and line.endswith(':'):
        addr = int(line.split()[0], 16)
        name = line[line.index('<') + 1: line.rindex('>')]
        stubs[addr] = name

# --- stub -> got slot (adrp/ldr) ---
plt = byname['.plt']
slot_of = {}
for i in range(plt['size'] // 16):
    a = plt['addr'] + i * 16
    o = plt['off'] + i * 16
    i0, i1 = struct.unpack_from('<II', d, o)
    if (i0 & 0x9f00001f) == 0x90000010 and (i1 & 0xffc003ff) == 0xf9400211:
        imm = (((i0 >> 5) & 0x7ffff) << 2) | ((i0 >> 29) & 3)
        if imm & (1 << 20):
            imm -= 1 << 21
        slot_of[a] = ((a & ~0xfff) + (imm << 12)) + ((i1 >> 10) & 0xfff) * 8

# --- .text icindeki cagrilar ---
text = byname['.text']
callers = {}
for o in range(text['off'], text['off'] + text['size'], 4):
    insn, = struct.unpack_from('<I', d, o)
    if (insn & 0xFC000000) == 0x94000000:
        imm = insn & 0x03FFFFFF
        if imm & (1 << 25):
            imm -= 1 << 26
        tgt = text['addr'] + (o - text['off']) + imm * 4
        callers[tgt] = callers.get(tgt, 0) + 1

# --- eksik + cagrilan slotlar ---
need = []
for a, name in sorted(stubs.items()):
    slot = slot_of.get(a)
    if slot is None or slot in resolved:
        continue
    if callers.get(a, 0) == 0:
        continue
    base = name.replace('@plt', '').split('@')[0]
    idx = name2idx.get(base)
    if idx is None:
        cands = [i for i, (nm, sh) in enumerate(syms) if nm == base and sh == 0]
        if len(cands) == 1:
            idx = cands[0]
        elif cands:
            idx = cands[0]
    if idx is None:
        print(f"SKIPPED (no symbol): {name} slot=0x{slot:x}")
        continue
    need.append((slot, idx, base))

gap = ro['off'] - (rp['off'] + rp['size'])
print(f"relocations to add: {len(need)}  free space: {gap} bytes (max {gap//24})")
if len(need) * 24 > gap:
    sys.exit("ERROR: not enough free space")

# --- write ---
base_off = rp['off'] + rp['size']
for k, (slot, idx, nm) in enumerate(need):
    struct.pack_into('<QQq', d, base_off + k * 24, slot, (idx << 32) | 257, 0)

newsize = rp['size'] + len(need) * 24
# --- update DT_PLTRELSZ ---
dyn = {}
for i in range(dy['size'] // 16):
    tag, val = struct.unpack_from('<qQ', d, dy['off'] + i * 16)
    dyn.setdefault(tag, []).append((i, val))
if 2 not in dyn:
    sys.exit("DT_PLTRELSZ not found")
idx_dyn = dyn[2][0][0]
old = dyn[2][0][1]
struct.pack_into('<Q', d, dy['off'] + idx_dyn * 16 + 8, newsize)
print(f"DT_PLTRELSZ: {old} -> {newsize}")
print("last relocation file offset:", hex(base_off + len(need) * 24), "rodata start:", hex(ro['off']))

open(DST, 'wb').write(bytes(d))
print("wrote:", DST)
