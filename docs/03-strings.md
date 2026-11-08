# Hidden string recovery

## Where the strings went

916 strings were removed from `classes*.dex` and replaced by static fields on 48
ghost classes, for example:

```smali
sget-object v0, LI1/g;->a:Ljava/lang/String;   # was: const-string v0, "..."
```

Those classes have no code of their own; the PairIP VM fills their static fields during
`Application.<clinit>`. With the VM disabled the app NPEs (e.g. `FirebaseApp` name null
- `trim()` on null in `I1/g.i`).

## How the values were recovered

1. Original MEB-signed APKs installed on the emulator `root34` (x86_64 image with 64-bit
   ARM translation enabled through `native.bridge` build properties).
2. App started; `LicenseActivity` appears but the VM already ran and populated the
   fields, so the values are in memory.
3. Root via `su 0` (never `adb root` - PairIP detects it), then read the fields through
   `/proc/<pid>/mem` per `/proc/<pid>/maps`.
4. Result: **48 classes, 1526 fields, 1489 values** - `dump/strings_dump.json`

Format:

```json
{ "I1.g": { "a": "FirebaseApp", "b": "…" }, "b0.PL.zVfz": { … } }
```

`null`/missing values (9 fields) stayed as-is; they are genuinely null at runtime.

## Patching

`scripts/patch/patch_strings.py` walks the smali tree and rewrites every field read:

| Before | After |
|---|---|
| `sget-object v0, Lx/y;->z:Ljava/lang/String;` | `const-string v0, "<dumped value>"` |

Result on the shipped tree: **1361 replacements across 512 files**, 9 skipped.

```bash
python3 scripts/patch/patch_strings.py build/apktool/smali dump/strings_dump.json
```

## Why this is safe

`const-string` is always legal where `sget-object` of a `String` was, and the constants
are the exact runtime values - no behaviour change beyond no longer needing the VM.

## Related files

- `dump/strings_dump.json` - the table itself
- `dump/holders.txt`, `dump/holder_classes.json` - ghost class list
- `dump/pairip_strings.txt` - raw strings seen in the VM payload
- `scripts/dump/` - the frida/gadget scripts used while probing (historical)
