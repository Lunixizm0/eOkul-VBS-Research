# Overview

Target: **MEB eOkul VBS** (`com.meb.vbsmobil`) - Flutter 3.35.6 + Google PairIP.

## Artifacts

| File | What | State |
|---|---|---|
| `apks/original/base.apk` | Original MEB-signed base APK (DEX + assets) - *not committed; place manually* | Decoded, patched |
| `apks/original/split_config.arm64_v8a.apk` | Native libs (`libflutter`, `libapp`, `libpairipcore`) - *not committed* | Analysed; engine replaced |
| `apks/original/split_config.{ar,tr,xxhdpi}.apk` | Language/density resources - *not committed* | Not merged (fallback resources) |
| PairIP VM | `com.pairip.*` + `libpairipcore.so` | Disabled (VMRunner no-op) |
| `libapp.so` | Dart AOT snapshot | Untouched |
| `k2/a.smali` | flutter_secure_storage Android impl | Patched (plain prefs fallback) |
| `apks/VBS-Mod.apk` | Produced mod (real `API_URL`, works standalone) | Builds/launches; authenticated login hand-off not yet working |
| mitmproxy WireGuard server | `scripts/mitm.sh` | Dart REST and WebView traffic decryption on a non-rooted device |

## How the protection is wired

- `AndroidManifest` - `android:name="com.pairip.application.Application"`.
- `<clinit>` - `VMRunner.invoke(...)`: starts the native VM, loads `libpairipcore.so`.
- The VM decrypts the static fields of 48 ghost classes and the first ~50 KB of
  `libflutter.so`'s `.text`. The key is **bound to the APK signature** (re-signing -
  SIGSEGV).
- `attachBaseContext` - `SignatureCheck.verifyIntegrity` + `LicenseClient.checkLicense`.
- Additionally `LicenseActivity` (Play licensing screen) and Dart-side cert pinning.

## Approach

PairIP is removed completely; everything it used to provide is rebuilt outside the VM:

1. Strings are embedded into smali (works without the VM).
2. The native engine is replaced with the genuine Flutter 3.35.6 `libflutter.so`.
3. Java gates (`SignatureCheck`, `LicenseClient`, license provider) are no-ops.
4. `.env` keeps the real `API_URL` (pinning flag set to `false`) and TLS certificate
   verification is disabled in the engine; a `network_security_config` adds `user`
   trust anchors so a mitmproxy CA is honoured.
5. `flutter_secure_storage` is patched to fall back to plain `SharedPreferences`
   on Android 16 (Tink protobuf NPE).
6. Traffic capture is external to the APK: mitmproxy in WireGuard mode, with
   `allow_hosts` limiting decryption to the MEB/e-Devlet domains.

## Repo map

| Path | Contents |
|---|---|
| `docs/` | Method, PairIP, string recovery, native engine, pinning, build, verification, MITM |
| `scripts/build.sh` | End-to-end build |
| `scripts/mitm.sh` | WireGuard-mode capture server + client config (`start/conf/status/stop/web`) |
| `scripts/mitm-adb.sh`, `scripts/verify-mitm.sh`, `scripts/flows.py` | Legacy adb-proxy path, launch-and-verify helper, flow dumper |
| `scripts/patch/` | smali/XML patches (gates, VM, strings, NSC) |
| `.venv/` | local mitmproxy install (gitignored) |
| `scripts/engine/` | GOT analysis, engine patches, memory dump |
| `scripts/dump/` | Frida/gadget dump scripts (historical) |
| `dump/` | `strings_dump.json`, decrypted `.text`, maps, symbol lists |
| `lib/engine/3.35.6/` | artifacts.zip + stripped/patched/unstripped engine |
| `build/` | apktool tree and split contents (derived) |
| `research/` | aotopsy/jadx output, frida tooling, older attempts |
