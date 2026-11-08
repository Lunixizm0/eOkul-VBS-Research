# Build

## Requirements

From a fresh clone run `./scripts/setup.sh` once; it installs everything below
except the Android SDK (see `09-reproduce.md`).

| Tool | Notes |
|---|---|
| JDK 17+ | `apktool` / `apksigner` |
| `tools/apktool.jar` | created by `setup.sh`; override with `APKTOOL_JAR=…` (`~/tools/apktool_3.0.3.jar` is also picked up) |
| Android build-tools | `zipalign`, `apksigner` (auto-detected under `/opt/android-sdk`) |
| Python 3.10+ | patch scripts |
| `lib/engine/3.35.6/libflutter-patched.so` | `./scripts/fetch-engine.sh` (pinned sha256, gitignored) |
| `.env` with `KEY=<keystore password>` | used by `apksigner` (never echoed) |
| `mitmproxy` in `.venv` | only for capture: `python3 -m venv .venv && ./.venv/bin/pip install mitmproxy` |

## Pipeline

```bash
./scripts/build.sh

# inspection variant (adds android:debuggable="true" so run-as can read app data)
DEBUGGABLE=1 OUT=apks/VBS-Mod-debug.apk ./scripts/build.sh
```

The debuggable build exists only for storage verification (see `07-verification.md`); it
is not meant as a daily driver.

| Step | What happens |
|---|---|---|
| 1 | `apktool d apks/original/base.apk -o build/apktool` (only if missing, or `--fresh`) - original APK supplied manually (not committed) |
| 2 | `scripts/patch/patch_gates.py` - `SignatureCheck`, `LicenseClient`, license provider - no-op |
| 3 | `scripts/patch/patch_vm.py` - `VMRunner.<clinit>`/`invoke` disabled |
| 4 | `scripts/patch/patch_storage.py` - `k2/a.smali` (flutter_secure_storage) replaced with the
  vendored plain-`SharedPreferences` implementation, hash-pinned to app 3.3.2 |
| 5 | `scripts/patch/patch_strings.py` - 1357 ghost-field reads - `const-string` |
| 6 | `scripts/patch/patch_nsc.py` - `res/xml/network_security_config.xml` with `system` + `user`
  trust anchors, referenced from `<application android:networkSecurityConfig>` |
| 7 | `.env` is **re-seeded from the original APK** every run, then `ENABLE_CERT_PINNING=false`;
  `API_URL=…` rewrites the URL only when set (legacy adb-proxy path) |
| 8 | Manifest - `requiredSplitTypes`/`splitTypes` removed (single APK) |
| 9 | `apktool b` - `build/out/base-unsigned.apk` |
| 10 | native libs from `apks/original/split_config.arm64_v8a.apk` + `lib/engine/3.35.6/libflutter-patched.so`, stored (`-0`) |
| 11 | `zipalign -p 4` (`.so` must be page-aligned, `extractNativeLibs=false`) |
| 12 | `apksigner` v1+v2+v3 - `apks/VBS-Mod.apk` |

Because step 6 always starts from the original `.env`, the default build points at the real
`https://eokulapp.meb.gov.tr/` and works standalone - no proxy/reverse-tunnel required.
Traffic capture is a purely external concern (`scripts/mitm.sh`, WireGuard mode).

## Output

```
apks/VBS-Mod.apk                 26.9 MB, test key
build/out/base-unsigned.apk      apktool output (before libs)
build/out/mod-aligned.apk        aligned, unsigned
```

## Install

```bash
adb uninstall com.meb.vbsmobil     # signature differs from MEB's
adb install apks/VBS-Mod.apk
```

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | old (MEB-signed) app still installed - uninstall first |
| App crashes at `.plt` / `0xa3c080` | engine replaced with the PairIP-pruned one; use `lib/engine/3.35.6/libflutter-patched.so` |
| `Failure [INSTALL_FAILED_INVALID_APK]` | `.so` not stored/aligned; re-run `zipalign -f -p 4` before signing |
| Empty `KEY` | password missing in `.env` (`KEY=...`) |
| Emulator differences | x86 ARM translation is unreliable here; test on hardware |

## Excluded from version control

The following paths are gitignored (see `.gitignore` in the repo root):

| Path | Reason |
|---|---|
| `.env` / `.env.local` | Keystore password (`KEY=…`) |
| `build/out/`, `build/apktool/`, `build/split/` | Derived build trees |
| `lib/candidates/` | Downloadable engine candidates |
| `research/analysis/`, `research/leftovers/`, `research/tools/` | Bulky research output |
| `apks/intermediate/` | Historical build attempts |
| `apks/*.apk`, `apks/*.apk.idsig` | Produced APKs and signing artifacts |
| `keystore/` | Signing material |
| `dump/` | Memory dumps and raw artifacts |
| `.venv/`, `build/mitm/` | Local mitmproxy env, WireGuard keys, captured flows |

## Rebuilding the engine (optional)

```bash
unzip -p lib/engine/3.35.6/artifacts.zip flutter.jar > /tmp/flutter.jar
unzip -p /tmp/flutter.jar lib/arm64-v8a/libflutter.so > lib/engine/3.35.6/libflutter-unstripped.so
python3 scripts/engine/cert_bypass.py lib/engine/3.35.6/libflutter-unstripped.so \
        lib/engine/3.35.6/libflutter-patched.so
llvm-strip --strip-unneeded lib/engine/3.35.6/libflutter-patched.so
```
