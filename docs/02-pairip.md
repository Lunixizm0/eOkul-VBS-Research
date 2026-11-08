# PairIP: how the protection works

## Entry points

```
com.pairip.application.Application
├── <clinit>            - VMRunner.invoke("<vmByteCodeFile>", args)
├── attachBaseContext   - SignatureCheck.verifyIntegrity(ctx)
│                          LicenseClient.checkLicense(ctx)
└── (provider)          - com.pairip.licensecheck.LicenseContentProvider.onCreate
```

`VMRunner.<clinit>` calls `System.loadLibrary("pairipcore")`; `VMRunner.invoke` hands a
file name (`assets/<random id>`) to the native VM.

## What the VM does

1. **String recovery** - 916 strings were deleted from the DEX and replaced by
   `sget-object` reads of static fields on 48 "ghost" classes (e.g. `I1/g`, `b0/PL/zVfz`,
   `EMoYyuA`). Only the VM fills those fields.
2. **Native decryption** - `libflutter.so` ships with its first ~50 KB of `.text`
   encrypted and its GOT pruned, so the engine cannot run on its own.

## Signature binding (the hard part)

The decryption key is derived from the APK signature. Evidence:

| Experiment | Result |
|---|---|
| Original APK, re-signed only (zero byte changes) | `SIGSEGV` at `libpairipcore.so+0x47264` |
| Patched APK, original-ish signature | Same crash |
| Original APK, original signature (emulator) | Runs; strings decrypt; engine starts |

The crashing instruction at `0x47264` is a `ldrsb x13, [x9, x10]` inside the VM's
string-hash loop: with the wrong key the index/pointer is garbage, so it faults instead
of failing cleanly. There is no "return true" check to flip - the VM is obfuscated and
the payload is keyed to the signature.

## What we disable, and what we replace

| Component | Action |
|---|---|
| `VMRunner.<clinit>` | `return-void` (never loads `libpairipcore`) |
| `VMRunner.invoke` | returns `null` |
| `SignatureCheck.verifyIntegrity` | `return-void` |
| `LicenseClient.checkLicense` | `return-void` |
| `LicenseContentProvider.onCreate` | returns `true` |
| Ghost strings | embedded as `const-string` (see `03-strings.md`) |
| `libflutter.so` | replaced with the genuine engine (see `04-native-engine.md`) |

With the VM gone, `libpairipcore.so` is never loaded; the APK still contains it (the
Java code references it in unreachable paths), which is harmless.

## License screen

`LicenseActivity` is PairIP's Play-licensing UI. On a Play-less emulator it blocks the
app even when correctly signed - one more reason the emulator is not a valid test
environment.
