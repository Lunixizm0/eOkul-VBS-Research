# Method notes

Toolchain and workflow used to repackage and run a PairIP-protected Flutter app.

## Toolchain

| Tool | Used for |
|---|---|
| `apktool` | Decoding / rebuilding the APK |
| build-tools 37.0.0 | `zipalign -p 4`, `apksigner` (v1+v2+v3) |
| `readelf` / `llvm-objdump` | ELF sections, `.plt`/`.got.plt`, relocations |
| `llvm-strip` | Shrinking the 147 MB unstripped engine to APK size |
| `adb` | Install, logcat, UI driving, `/proc/<pid>/maps`, `/proc/<pid>/mem` |
| `mitmproxy` 12.x (`.venv`) | Traffic capture via WireGuard mode - see `docs/08-mitm.md` |
| Frida (gadget) | Limited use only - PairIP's anti-debug catches ptrace |
| Emulator `root34` | x86_64 + ARM translation (exec64) - used **only** for dumps |
| Real Android device (arm64) | The only valid test environment |

## Workflow

1. **Install the original** (`apks/original/`, supplied manually — not committed) and run it.
2. **Dump strings**: on the rooted emulator, read the ghost classes' static fields via
   `/proc/<pid>/mem` - `dump/strings_dump.json`.
3. **Native analysis**: sections, `.plt`/`.got.plt`, relocation counts, encrypted
   `.text` range - `docs/04-native-engine.md`.
4. **Identify the engine**: compare `.rodata`, `.eh_frame`, the rest of `.text` and
   `.data` against Flutter engine candidates; the matching revision goes to `lib/engine/`.
5. **Patch**: smali gates (`scripts/patch/`), string injection, `network_security_config`
   with `user` trust anchors (`patch_nsc.py`), `.env`, manifest
   (`requiredSplitTypes` removal), engine certificate-verification patch
   (`scripts/engine/cert_bypass.py`), SecureStorage fallback (`k2/a.smali`).
6. **Build**: `scripts/build.sh` - `apks/VBS-Mod.apk` (real `API_URL`, works standalone).
7. **Verify**: install + `logcat` + first-frame check (`docs/07-verification.md`).
8. **Capture**: `scripts/mitm.sh start` (WireGuard) -> `scripts/verify-mitm.sh` /
   `scripts/flows.py` (`docs/08-mitm.md`). Interception is external to the APK.

## Practical notes

- `frida-server` is caught through ptrace by PairIP; `wrap.` + gadget attempts are not
  stable either. All dumps were taken through `/proc/<pid>/mem`.
- `adb root` triggers PairIP on the emulator; root has to be obtained with `su 0`.
- On the emulator the original app stalls on `LicenseActivity` (no Play licensing), so
  emulator results only prove that code paths execute.
- The device library is mapped from the split APK (`extractNativeLibs=false`), so
  `/proc/<pid>/maps` shows the APK path, not `libflutter.so`.
