# Verification

Tested on a real arm64 Android device (Android 16). Device serial redacted.

## Install

```
adb uninstall com.meb.vbsmobil          # MEB signature differs
adb install apks/VBS-Mod.apk            # -> Success (6.1 s, incremental)
```

## Runtime

| Check | Evidence |
|---|---|
| Process alive | `pidof com.meb.vbsmobil` - alive |
| Activity focused | `mCurrentFocus=Window{… com.meb.vbsmobil/com.meb.vbsmobil.MainActivity}` |
| First frame rendered | `SurfaceFlinger: [SurfaceView[…MainActivity]…] setTransactionState with the first frame` |
| Activity displayed | `ActivityTaskManager: Displayed com.meb.vbsmobil/.MainActivity for user 0` |
| Crash buffer | empty (no `FATAL`/`SIGSEGV`/`SIGILL`) |
| ANR | none |

Earlier failing build, for contrast: `Fatal signal 11 (SIGSEGV), code 1, fault addr
0xa3c080 in tid … (flutter-worker-)` - the encrypted/GOT-pruned engine.

## Checked inside the APK

| Item | Result |
|---|---|
| `assets/flutter_assets/.env` | `ENABLE_CERT_PINNING=false` (read back from the installed APK) |
| `classes*.dex` | ghost fields replaced by `const-string` (1361) |
| `lib/arm64-v8a/libflutter.so` | Flutter 3.35.6, 361 `JUMP_SLOT`, cert-verify patch at `0x716b60`/`0x6fb758` |
| Signature | `apksigner verify` OK, v1+v2+v3, test key |
| `k2/a.smali` | SecureStorage patched: plain `SharedPreferences` fallback on Android 16 |

## Current build (Nov 2026, WireGuard setup)

Default build (`apks/VBS-Mod.apk`, real `API_URL`) on the same device:

| Check | Evidence |
|---|---|
| Installs over the patched app | `adb install -r -d` - `Success` (incremental, 1.1 s) |
| Launches, protection off | `topResumedActivity=com.meb.vbsmobil/.MainActivity` |
| App works standalone (no tunnel, no proxy) | app opens and runs; device UUID persistence verified, WebView session persistence verified, authenticated WebView - native Flutter hand-off not working |
| Same APK through the tunnel | identical UI, list still loads |
| Dart REST decrypted | `POST https://eokulapp.meb.gov.tr/CihazKayit - 200, 181 B`, `user-agent: Dart/3.9 (dart:io)` |
| WebView decrypted | `www.turkiye.gov.tr/ogrenci-bilgi-sistemi - 200, 17,328 B` + 30 CDN assets (CSS/JS/fonts/webp), all 200 |
| Totals | 37 captured flows, all `200`; 403 tunnel connections in one session |

Reproduce: `./scripts/mitm.sh start`, activate the tunnel on the device, then
`./scripts/verify-mitm.sh`. The default capture covers only `*.meb.gov.tr`; the e-Devlet
WebView rows above were produced with `WEBVIEW_CAPTURE=1 ./scripts/mitm.sh start`
(see `08-mitm.md`).

## Device identity and storage (measured on device)

How the app identifies a device: `POST /CihazKayit` carries
`{"sifre":…,"uid":"<uuid>","p":"3.3.2","pid":""}`. The `uid` is a **locally generated
UUID stored in the app's own preferences**, not derived from hardware.

Measured on a real device with a debuggable build (`DEBUGGABLE=1`, needed for `run-as`):

| Step | `uid` |
|---|---|
| launch 1, build A | <UUID-A> |
| force-stop, launch 2 | <UUID-A> (unchanged) |
| `adb install -r` a new build, launch | <UUID-A> (unchanged) |
| `adb shell pm clear com.meb.vbsmobil`, launch | <UUID-B> (new) |
| force-stop, launch again | <UUID-B> (unchanged) |

Where it lives:

```
shared_prefs/FlutterSharedPreferences.xml
    <string name="flutter.eokulvbstkn">id</string>

shared_prefs/FlutterSecureStorage.xml
    <map />            <- empty on this install
```

`eokulvbstkn` is the key read/written by `getTokenFromDevice` / `setTokenToDevice`
(AOT string xref), i.e. the device token that is sent as `uid`.

Conclusions:

1. The id survives process restarts and `install -r` upgrades, and is regenerated only by
   `pm clear` - so **app storage persistence works**, and it is not re-derived from the
   device on every launch.
2. That value travels through **shared_preferences** (`FlutterSharedPreferences.xml`), which
   never depended on the Android 16 Tink problem.
3. `flutter_secure_storage` is present in the APK but nothing has been written through it on
   this install, so the storage patch is currently a **safety net**, not the thing keeping
   the session alive. If a real login starts writing secure keys, the patch is what keeps
   them working (plain `SharedPreferences`, see `scripts/patch/patch_storage.py`).

Reproduce the inspection:

```bash
DEBUGGABLE=1 OUT=apks/VBS-Mod-debug.apk ./scripts/build.sh
adb install -r apks/VBS-Mod-debug.apk
adb shell run-as com.meb.vbsmobil ls -l shared_prefs
adb shell run-as com.meb.vbsmobil cat shared_prefs/FlutterSharedPreferences.xml
adb shell run-as com.meb.vbsmobil cat shared_prefs/FlutterSecureStorage.xml
```

After a real e-Devlet login, re-run the last command: if `FlutterSecureStorage.xml` now
contains keys, those keys are stored in plaintext by the patch. `./scripts/check-storage.sh`
force-stops/relaunches the app and reports storage errors plus whether the student list
survived.

## Known gaps

| Gap | Why |
|---|---|
| `Certificate Pinning: Aktif` still logged | message compiled into Dart AOT; release build ignores the `.env` flag |
| SecureStorage on Android 16 | `EncryptedSharedPreferences` (AndroidX Security + Tink) throws `NullPointerException: name == null` in Tink protobuf reflection. Patched to plain `SharedPreferences`; currently no secure keys are written, so this is untested against a real login |
| In-app persistence / hand-off | app opens and runs, but in-app persistence is not yet working. The e-Devlet login inside the WebView remembers its own session, but after logging in through the WebView the app does not continue in the native Flutter UI - the WebView interface stays open instead of handing back to the app |
| Tunnel activation is manual | Android forbids starting a `VpnService` without user consent - one tap per session |
| Firebase/GMS traffic is not decrypted | passed through untouched so it keeps working; intercepting it would need a system-store CA (root) |
| Play licensing / `LicenseActivity` | not exercised in the final build (provider no-op); not re-tested on a Play-enabled setup |
| Emulator | unusable for behavioural checks (stalls on `LicenseActivity`, ARM translation crashes) |