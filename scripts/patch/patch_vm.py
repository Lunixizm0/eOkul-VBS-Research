#!/usr/bin/env python3
import re, sys, os

SMALI = sys.argv[1] if len(sys.argv) > 1 else "rebuild/smali"
path = os.path.join(SMALI, "com/pairip/VMRunner.smali")

with open(path) as f:
    lines = f.readlines()

out = []
i = 0
n = len(lines)
patched = {"<clinit>": False, "invoke": False}

while i < n:
    line = lines[i]
    m = re.match(r"\.method\s+.*?(<clinit>|invoke)\(", line)
    if m and not patched[m.group(1)]:
        kind = m.group(1)
        out.append(line)
        i += 1
        while i < n and lines[i].strip().startswith((".locals", ".registers")):
            out.append(lines[i]); i += 1
        while i < n and lines[i].strip().startswith(".annotation"):
            while i < n and not lines[i].strip().startswith(".end annotation"):
                out.append(lines[i]); i += 1
            if i < n:
                out.append(lines[i]); i += 1
        if kind == "<clinit>":
            out.append("    return-void\n")
        else:
            out.append("    const/4 v0, 0x0\n\n    return-object v0\n")
        patched[kind] = True
        continue
    out.append(line)
    i += 1

if not (patched["<clinit>"] and patched["invoke"]):
    print("!! eksik yama:", patched)
    sys.exit(1)

with open(path, "w") as f:
    f.writelines(out)
print("OK: VMRunner.<clinit> -> no-op, VMRunner.invoke -> null")
