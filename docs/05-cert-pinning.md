# Certificate pinning

## What the app does

`libapp.so` (Dart AOT) contains:

- `_setupCertificatePinning@767431753`
- `_onBadCertificateWrapper`, `registerBadCertificateCallback`,
  `SecureSocket_RegisterBadCertificateCallback`, `SecurityContext_TrustBuiltinRoots`
- the log string `Certificate Pinning: Aktif`
- the key name `ENABLE_CERT_PINNING`

`.env` (bundled as `assets/flutter_assets/.env`) ships:

```
# Certificate Pinning Test (debug modda aktif etmek için)
ENABLE_CERT_PINNING=true
```

## What was tried

| Change | Result |
|---|---|
| `.env` - `ENABLE_CERT_PINNING=false` (verified inside the installed APK) | Log still says `Certificate Pinning: Aktif` |

The comment ("to enable in debug mode") matches the behaviour: in release the flag is
irrelevant, the pinning path is compiled in. The `.env` value alone cannot switch it off.

## What is shipped

TLS certificate validation is disabled in the engine instead:

| Symbol | Address (3.35.6) | Patch |
|---|---|---|
| `ssl_crypto_x509_session_verify_cert_chain` | `0x716b60` | `mov w0,#1 ; ret` |
| `X509_verify_cert` | `0x6fb758` | `mov w0,#1 ; ret` |

Encoded bytes: `20 00 80 52 c0 03 5f d6`.

Consequence: any server certificate is accepted, so a MITM proxy no longer has to
present the pinned certificate. Because BoringSSL accepts the chain, the Dart
`badCertificateCallback` (which would compare fingerprints on a rejection) is never
invoked.

## Status

- Patch is applied and verified in the APK (`lib/engine/3.35.6/libflutter-patched.so`).
- App runs with the patched engine (see `07-verification.md`).
- **End-to-end MITM verified for both layers** (mitmproxy WireGuard mode, non-rooted):
  Dart REST - `POST https://eokulapp.meb.gov.tr/CihazKayit - 200` with
  `user-agent: Dart/3.9 (dart:io)`; WebView - `www.turkiye.gov.tr/ogrenci-bilgi-sistemi
  - 200, 17,328 B` plus 30 CDN assets, all 200, page rendered styled. See `08-mitm.md`.
- No Dart-level pinning exists (`badCertificateCallback`, `SecurityContext`,
  fingerprint strings are absent from the AOT). The `Certificate Pinning: Aktif`
  log line is a plain string; the `.env` flag is ignored in release builds.
- The engine patch is belt-and-braces: in practice the user-installed mitmproxy CA plus
  the `network_security_config` patch is what makes interception work.

## Reproduce

```bash
python3 scripts/engine/cert_bypass.py \
  lib/engine/3.35.6/libflutter-unstripped.so \
  lib/engine/3.35.6/libflutter-patched.so
llvm-strip --strip-unneeded lib/engine/3.35.6/libflutter-patched.so
```
