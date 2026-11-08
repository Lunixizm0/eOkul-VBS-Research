# eOkul VBS (`com.meb.vbsmobil`) - PairIP mod research

> **Security warning:** This modified build disables TLS certificate verification in
> the Flutter engine and replaces encrypted storage with plaintext SharedPreferences.
> It is intended exclusively for isolated research environments. Do not use real
> credentials, e-Devlet accounts, or sensitive student data with this build.

Flutter + **Google PairIP**-protected MEB eOkul VBS app. The goal is to analyse and
reproduce selected parts of the application's runtime behaviour, including its
PairIP protection and TLS traffic handling. The modified build is experimental and
does not currently complete the authenticated login hand-off to the native Flutter
interface.

**Status:** built and verified on a real arm64 Android device (Android 16).
The app launches, **protection is off**, it talks to the real `https://eokulapp.meb.gov.tr/`
and Dart REST traffic is **decrypted** by default. WebView traffic can also be decrypted
through an explicit opt-in capture mode.

Current behaviour: the app opens and runs. Device-uid persistence in SharedPreferences is verified (see docs/07-verification.md); what is not yet working is the authenticated login hand-off from the WebView back to the native Flutter UI.
The e-Devlet login performed inside the WebView *does* remember the session (the
WebView layer keeps its own persistence), however after logging in through the
WebView the app does not continue inside the native Flutter UI - instead the
WebView interface stays open and the flow does not hand back to the app. Fixing
the in-app persistence / hand-off is the remaining work.

Start with [`docs/01-overview.md`](docs/01-overview.md). Method notes:
[`docs/00-method.md`](docs/00-method.md). Traffic capture: [`docs/08-mitm.md`](docs/08-mitm.md).
Reproducing everything from a fresh clone: [`docs/09-reproduce.md`](docs/09-reproduce.md).

## Why it is not a simple repackage

PairIP decrypts both Java strings and **native code** (the first 50 KB of
`libflutter.so`'s `.text`) at runtime with a VM. The key is **bound to the APK
signature**: re-signing the APK makes the native VM read with a wrong key and crash
at `libpairipcore.so+0x47264` (SIGSEGV). "Just disable the protection" is therefore
impossible; strings and the engine had to be recovered separately.

## Reproduce from scratch

```bash
git clone https://github.com/Lunixizm0/eOkul-VBS-Research.git && cd eta
# place the original MEB APKs under apks/original/ (not committed; sha: input-sha256.txt)
# Obtain the original MEB eOkul VBS APK (version 3.3.2, versionCode 69) split files
# and place them under apks/original/ before running setup.sh.
./scripts/setup.sh      # apktool + .venv/mitmproxy + keystore/.env + engine + input hashes
./scripts/build.sh      # -> apks/VBS-Mod.apk
adb install -r -d apks/VBS-Mod.apk
```

Prerequisites: JDK 17+, Python 3.10+, Android build-tools (`zipalign`, `apksigner`),
`curl`, `unzip`, `zip`; `llvm-strip` only for regenerating the engine. `make setup`,
`make build`, `make capture` wrap the same steps.

## Findings

### 1. Hidden strings (DEX)
916 strings were removed from the DEX and moved into static fields of 48 ghost
classes, populated only by the PairIP VM. The original, correctly signed app was run
on an emulator and **48 classes / 1526 fields / 1489 values** were dumped from memory,
then written back into smali (`scripts/patch/patch_strings.py`, 1361 `sget-object`
replacements). See [`docs/03-strings.md`](docs/03-strings.md).

### 2. Native engine
VA `0x464080–0x47082f` in `libflutter.so` is encrypted (50,877 bytes). The decrypted
image was dumped, but PairIP also fills **200 of the library's 362 GOT slots** through
its VM (their symbols are stripped from `.dynsym`) - a patched library jumps to `.plt`
and dies.

Solution: the exact engine was identified as **Flutter 3.35.6**
(engine `d2913632a4578ee4d0b8b1c4a69888c8a0672c4b`; `.rodata`, `.eh_frame`, the rest of
`.text` and `.data` all match byte-for-byte). The app now ships that revision's
**genuine `libflutter.so`**, which removes the GOT problem entirely.
See [`docs/04-native-engine.md`](docs/04-native-engine.md).

### 3. Certificate pinning
`ENABLE_CERT_PINNING` in `.env` is ignored in release builds (the Dart log still prints
"Certificate Pinning: Aktif"). Pinning is neutralised at the TLS layer:
`ssl_crypto_x509_session_verify_cert_chain` and `X509_verify_cert` are patched to
`mov w0,#1 ; ret`. See [`docs/05-cert-pinning.md`](docs/05-cert-pinning.md).

### 4. Storage / device identity
`flutter_secure_storage` uses `EncryptedSharedPreferences` (AndroidX Security + Google
Tink); on Android 16 Tink's protobuf reflection throws `NullPointerException: name ==
null`, so the encrypted path cannot be used.

Measured on device (debuggable build + `run-as`): the device identity sent as `uid` in
`POST /CihazKayit` is a locally generated UUID kept in **shared_preferences**, not in the
secure store:

```
shared_prefs/FlutterSharedPreferences.xml
    <string name="flutter.eokulvbstkn">[the uid]</string>
shared_prefs/FlutterSecureStorage.xml
    <map />          <- empty
```

It survives process restarts and `install -r` upgrades, and changes only after
`adb shell pm clear` - i.e. app storage persistence works and is not re-derived from
hardware each launch. `eokulvbstkn` is the key used by `getTokenFromDevice` /
`setTokenToDevice` (AOT xref).

So the storage patch below is a **safety net**, not what keeps the session alive today:
`scripts/patch/patch_storage.py` replaces the plugin implementation (`k2/a.smali`) with a
vendored, hash-pinned rewrite that always uses plain `SharedPreferences`
(`c()` init -> `getSharedPreferences("FlutterSecureStorage", 0)`, `e()` -> `TRUE`,
`i()` -> `putString`, `b()`/`h()` -> raw read). It is wired into `./scripts/build.sh`
(it used to be a manual edit that `--fresh` would lose), so any code path that does use
secure storage keeps working instead of failing on Tink.

Details, evidence table and the `run-as` repro: [`docs/07-verification.md`](docs/07-verification.md).
Persistence check after a login: `./scripts/check-storage.sh`.

### 5. MITM / traffic capture
Capture is **independent of the APK**. mitmproxy runs in WireGuard mode (userspace VPN,
no root): the phone routes its traffic through mitmproxy, mitmproxy answers DNS, decrypts
only the MEB domains (`allow_hosts`) and relays everything else untouched. Both layers
were verified decrypted on a non-rooted device - the Flutter client
(`user-agent: Dart/3.9 (dart:io)` - `POST /CihazKayit 200`) and the e-Devlet WebView.

**e-Devlet login capture is opt-in.** By default only `*.meb.gov.tr` is decrypted;
`*.e-devlet.gov.tr` / `*.turkiye.gov.tr` are relayed raw (no flows, no cookies, no tokens),
because a real login is the thing you are least likely to want on disk. Turn it on with
`WEBVIEW_CAPTURE=1 ./scripts/mitm.sh start` (`scripts/mitm_guard.py` enforces this at the
TLS ClientHello).

The APK only needs the `network_security_config` patch that adds `user` trust anchors
(`scripts/patch/patch_nsc.py`), since targeting SDK 36 without an NSC means user CAs are
ignored.

```bash
./scripts/mitm.sh start        # wireguard server + client conf -> /sdcard/Download
WEBVIEW_CAPTURE=1 ./scripts/mitm.sh start   # + e-Devlet WebView (opt-in)
./scripts/verify-mitm.sh       # launch app, print decrypted requests
./scripts/flows.py --body      # dump captured flows
```

See [`docs/08-mitm.md`](docs/08-mitm.md).

## Build

```bash
./scripts/build.sh          # -> apks/VBS-Mod.apk (real API_URL, works standalone)
```

The `.env` is always re-seeded from the original APK, so builds are reproducible;
`API_URL=…` / `OUT=…` still override.

Requirements (all handled by `./scripts/setup.sh`): JDK, `tools/apktool.jar`,
Android build-tools (`zipalign`, `apksigner`), Python 3, `curl`/`unzip`/`zip`,
`llvm-strip` (only to regenerate the engine), mitmproxy in `.venv` (capture only).

## Install

The original app is signed with a different key, so it has to be removed first:

```bash
adb uninstall com.meb.vbsmobil
adb install apks/VBS-Mod.apk
```

## License

Code, scripts and docs are MIT (see [`LICENSE`](LICENSE)). The third-party application
(`com.meb.vbsmobil`) is **not** licensed here; its original APKs are **not** included in
this repository (proprietary input). Place them under `apks/original/` manually; their
SHA-256 values are pinned in `input-sha256.txt` and verified by `scripts/setup.sh`.
They remain the property of MEB.

## Scope and limits

- Personal mod for your own device; not meant for redistribution.
- Signed with a test key - no Play Store updates, app data is reset.
- `Certificate Pinning: Aktif` still logged - message compiled into Dart AOT; release
  build ignores the `.env` flag.
- MITM covers Dart REST by default and WebView traffic on request (`WEBVIEW_CAPTURE=1`),
  without touching `API_URL` in the app's .env. Firebase/GMS
  traffic is deliberately passed through un-decrypted (it uses the system CA store and
  the API key is bound to MEB's signing certificate), so it keeps working.
- Activating the WireGuard tunnel needs one tap on the device; Android does not allow a
  `VpnService` to be started silently.
- The x86 emulator (ARM translation) is unreliable for this app; verification was done
  on real hardware.