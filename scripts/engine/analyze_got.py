#!/usr/bin/env python3
import struct, sys

P = sys.argv[1] if len(sys.argv) > 1 else 'split/lib/arm64-v8a/libflutter.so'
d = open(P, 'rb').read()

# ---- ELF64 section headers ----
e_shoff, = struct.unpack_from('<Q', d, 0x28)
e_shentsize, = struct.unpack_from('<H', d, 0x3a)
e_shnum, = struct.unpack_from('<H', d, 0x3c)
e_shstrndx, = struct.unpack_from('<H', d, 0x3e)

secs = {}
for i in range(e_shnum):
    nameoff, typ, flags, addr, off, size, link, info, align, entsize = struct.unpack_from('<IIQQQQIIQQ', d, e_shoff + i * e_shentsize)
    secs.setdefault(i, dict(nameoff=nameoff, typ=typ, addr=addr, off=off, size=size, link=link, info=info, entsize=entsize))

shstr_off = secs[e_shstrndx]['off']
def sname(i):
    o = shstr_off + secs[i]['nameoff']
    return d[o:d.index(b'\0', o)].decode()

byname = {}
for i in secs:
    n = sname(i)
    secs[i]['name'] = n
    byname[n] = secs[i]

def sec(n):
    return byname[n]

# ---- dynsym ----
ds = sec('.dynsym')
strtab = sec('.dynstr')
nsym = ds['size'] // ds['entsize']
syms = []
for i in range(nsym):
    o = ds['off'] + i * ds['entsize']
    nameoff, info, other, shndx, value, size = struct.unpack_from('<IBBHQQ', d, o)
    nm = d[strtab['off'] + nameoff: d.index(b'\0', strtab['off'] + nameoff)].decode('utf-8', 'replace')
    syms.append(dict(name=nm, shndx=shndx, value=value))

# ---- JUMP_SLOT relocations ----
def relas(name):
    s = sec(name)
    out = []
    for i in range(s['size'] // 24):
        off, info, add = struct.unpack_from('<QQq', d, s['off'] + i * 24)
        out.append((off, info >> 32, info & 0xffffffff, add))
    return out

jmp = relas('.rela.plt')
resolved_slots = sorted(x[0] for x in jmp)

# ---- .plt stubs: map GOT slot -> (stub addr, symbol) ----
plt = sec('.plt')
gotplt = sec('.got.plt')
stubs = []  # (stub_addr, slot_addr)
nstub = plt['size'] // 16
for i in range(nstub):
    a = plt['addr'] + i * 16
    o = plt['off'] + i * 16
    # entry 0 is PLT0 (resolver); rest: adrp x16, page ; ldr x17,[x16,#imm]
    i0, i1 = struct.unpack_from('<II', d, o)
    if (i0 & 0x9f00001f) == 0x90000010 and (i1 & 0xffc003ff) == 0xf9400211:
        immhi = (i0 >> 5) & 0x7ffff
        immlo = (i0 >> 29) & 3
        imm = (immhi << 2) | immlo
        if imm & (1 << 20):
            imm -= 1 << 21
        page = (a & ~0xfff) + (imm << 12)
        off12 = (i1 >> 10) & 0xfff
        slot = page + off12 * 8
        stubs.append((a, slot))
    else:
        stubs.append((a, None))

slot2stub = {s: a for a, s in stubs if s}

# ---- callers of stubs in .text ----
text = sec('.text')
tstart, tend = text['addr'], text['addr'] + text['size']
callers = {}
for o in range(text['off'], text['off'] + text['size'], 4):
    insn, = struct.unpack_from('<I', d, o)
    if (insn & 0xFC000000) == 0x94000000:  # bl
        imm = insn & 0x03FFFFFF
        if imm & (1 << 25):
            imm -= 1 << 26
        tgt = (tstart + (o - text['off'])) + imm * 4
        callers[tgt] = callers.get(tgt, 0) + 1

resolved_set = set(resolved_slots)
missing = []
for a, s in stubs:
    if s is None:
        continue
    if s in resolved_set:
        continue
    # find symbol name: the stub index corresponds to dynsym order for named stubs
    missing.append((s, a, callers.get(a, 0)))

print(f"stub sayisi: {len(stubs)}  JUMP_SLOT: {len(jmp)}  GOT slot araligi: 0x{gotplt['addr']:x}-0x{gotplt['addr']+gotplt['size']:x}")
print(f"relokasyonsuz slot: {len(missing)}")
unused = [m for m in missing if m[2] == 0]
print(f"  bunlardan hic cagrilmayan: {len(unused)}")
print(f"  cagrilan: {len(missing)-len(unused)}")
# GOT slot -> dynsym: named stubs are in dynsym order after PLT0? print mapping via objdump names is complex;
# instead map slot index to dynsym by matching relocation ordering when possible.
print("\nornek cagrilan eksik slotlar (slot, stub, caller):")
for s, a, c in [m for m in missing if m[2] > 0][:10]:
    print(f"  slot=0x{s:x} stub=0x{a:x} caller={c}")
print("\nBosluk analizi:")
gap = sec('.rodata')['off'] - (sec('.rela.plt')['off'] + sec('.rela.plt')['size'])
print(f"  free space after .rela.plt: {gap} bytes -> {gap//24} more entries")
