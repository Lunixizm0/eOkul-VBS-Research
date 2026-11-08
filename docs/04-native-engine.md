# Native engine: encrypted `.text` and the GOT problem

## What PairIP does to `libflutter.so`

| Section | Fact |
|---|---|
| `.text` | `0x464080–0x47082f` encrypted - **50,877 bytes** differ from the runtime image |
| `.init_array[0]`, `.init_array[1]` | `0x46f5d0`, `0x46fc04` - the two encrypted entry points |
| `.got.plt` | 364 slots, **362 of them preset to `0xa3c080`** (= `.plt` base) |
| `.rela.plt` | only **162** `R_AARCH64_JUMP_SLOT` entries for 362 stubs |

`.dynsym` still holds 273 undefined symbols, but 111 of them (mostly `gl*`) have no
relocation and ~89 have no symbol at all - those are the ones the VM resolves at
runtime (its own import table), which is exactly the part that would have to be
reconstructed by hand.

## What was tried

| Attempt | Result |
|---|---|
| Restore decrypted `.text` from a live process | Byte-exact for `0x5ca000` range, but the app crashes at `.plt` (`SEGV` at `0xa3c080`) |
| Same + `init_array` functions patched to `ret` | Identical crash |
| Add `JUMP_SLOT` relocations for missing slots (`scripts/engine/patch_got.py`) | 192 slots are actually called, and the gap after `.rela.plt` fits 199 entries - but the symbol names are gone, so the entries cannot be emitted |
| Replace the library with a stock engine | **works** (see below) |

## Engine identification

Procedure: compare our (patched) library against engine artifacts from
`storage.googleapis.com/flutter_infra_release/flutter/<engine>/android-arm64-release/artifacts.zip`
(`flutter.jar` - `lib/arm64-v8a/libflutter.so`), ignoring the region PairIP rewrote.

Dart version string in the app: `3.9.2 (stable) (Wed Aug 27 03:49:40 2025 -0700)` -
Flutter 3.35.3 … 3.35.7.

| Candidate | `.rodata` | `.eh_frame` | rest of `.text` | `.data` |
|---|---|---|---|---|
| 3.35.3 | 1058 diffs | 22594 | 93598 | 472 |
| 3.35.4 | 1199 | 22594 | 93598 | 449 |
| 3.35.5 | 7 | 22594 | 93598 | 449 |
| **3.35.6** | **0** | **0** | **0** | **0** |
| 3.35.7 | 46 | 0 | 145 | 0 |

So the app ships **Flutter 3.35.6**, engine `d2913632a4578ee4d0b8b1c4a69888c8a0672c4b`.
The only remaining differences are exactly PairIP's edits (encrypted `.text`, pruned
`.dynsym`/`.dynstr`, GOT/`.rela.plt`).

## What the build uses

`lib/engine/3.35.6/`

| File | Purpose |
|---|---|
| `artifacts.zip` | Original Flutter artifact (contains unstripped `libflutter.so` in `flutter.jar`) |
| `libflutter-unstripped.so` | 147 MB, unstripped - needed to locate symbols for patching |
| `libflutter.so` | `llvm-strip --strip-unneeded` output (11 MB), sections identical |
| `libflutter-patched.so` | `libflutter.so` + certificate-verification patch (`05-cert-pinning.md`) |

The genuine library has all **361** `JUMP_SLOT` relocations and a normal GOT, so the
`.plt` crash disappears without touching PairIP's stub layout.

`libflare.so` is the app's own `libapp.so` (Dart AOT) and stays untouched - it was
compiled by exactly this engine revision, so the snapshot matches.

Regenerate the patched engine with:

```bash
python3 scripts/engine/cert_bypass.py lib/engine/3.35.6/libflutter-unstripped.so \
        lib/engine/3.35.6/libflutter-patched.so
llvm-strip --strip-unneeded lib/engine/3.35.6/libflutter-patched.so
```
