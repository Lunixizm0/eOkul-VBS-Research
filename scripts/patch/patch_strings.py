#!/usr/bin/env python3
"""Ghost class static fields -> const-string (values from the memory dump).

usage: patch_strings.py [smali_dir] [strings_dump.json]
"""
import json, os, re, sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else 'build/apktool/smali'
DUMP = sys.argv[2] if len(sys.argv) > 2 else 'dump/strings_dump.json'

dump = json.load(open(DUMP))


def dotted(cls):
    return cls[1:-1].replace('/', '.')


def val_for(cls, field):
    return dump.get(dotted(cls), {}).get(field)


def esc(s):
    out = []
    for ch in s:
        if ch == '\\':
            out.append('\\\\')
        elif ch == '"':
            out.append('\\"')
        elif ch == '\n':
            out.append('\\n')
        elif ch == '\r':
            out.append('\\r')
        elif ch == '\t':
            out.append('\\t')
        else:
            out.append(ch)
    return ''.join(out)


PAT = re.compile(r'^(\s*)sget-object (v\d+), (L[^;]+;)->([A-Za-z0-9_$]+):Ljava/lang/String;\s*$')

EXPECTED = 1361

# First pass: scan only, count matches, do not touch files.
replaced = 0
skipped = 0
targets = []  # list of (filepath, line_index, new_line)

for dirpath, _, names in os.walk(ROOT):
    for n in names:
        if not n.endswith('.smali'):
            continue
        p = os.path.join(dirpath, n)
        lines = open(p, encoding='utf-8').read().split('\n')
        for i, line in enumerate(lines):
            m = PAT.match(line)
            if not m:
                continue
            indent, reg, cls, fld = m.groups()
            v = val_for(cls, fld)
            if v is None:
                skipped += 1
                continue
            targets.append((p, i, '%sconst-string %s, "%s"' % (indent, reg, esc(v))))
            replaced += 1

if replaced != EXPECTED:
    print('ERROR: expected %d replacements, found %d (skipped %d)' % (EXPECTED, replaced, skipped), file=sys.stderr)
    sys.exit(1)

# Second pass: apply changes only after validation.
by_file = {}
for p, i, newline in targets:
    by_file.setdefault(p, {})[i] = newline

files_touched = 0
for p, changes in by_file.items():
    lines = open(p, encoding='utf-8').read().split('\n')
    for i, nl in changes.items():
        lines[i] = nl
    open(p, 'w', encoding='utf-8').write('\n'.join(lines))
    files_touched += 1

print('replaced sget-object:', replaced)
print('skipped (null/no data):', skipped)
print('files:', files_touched)