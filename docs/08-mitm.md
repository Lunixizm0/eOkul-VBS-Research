# 08 - Live MITM (non-rooted device)

Goal: read the app's HTTPS traffic - Flutter/Dart REST calls **and** WebView - on a
device that is not rooted, without requiring root access or changing the original app's
network configuration. The `.env`'s `API_URL` is left untouched, since certificate
pinning was removed and the app talks to the real API directly and we can decrypt it.

## Result

Both layers are decrypted. Verified on a real arm64 device, Android 16:

```
POST https://eokulapp.meb.gov.tr/CihazKayit  ->  200, 181 B
     > user-agent: Dart/3.9 (dart:io)
     < {"GID":"…","CihazId":"…","Test":0,"OgrenciListesi":[],"DurumKodu":200,"Durum":"Tamam",…}
```

`user-agent: Dart/3.9 (dart:io)` is the Flutter HTTP client - i.e. the traffic that the
Android global proxy never sees. At the same time the app keeps working normally

WebView was verified earlier in the same way (e-Devlet login page: 34 requests, all
200, styled render). 

## Architecture

```
phone app  ──tun0 (VpnService)──  mitmdump --mode wireguard  ──  real servers
10.0.0.1                            host, udp/51820
```

* **mitmproxy WireGuard mode** (12.x, `mitmproxy_rs` wireguard backend) is a userspace
  VPN server: no root, no `adb reverse`, no `iptables`, no global proxy setting.
* The phone resolves DNS against `10.0.0.53`, which mitmproxy answers itself
  (`dns_resolver.py`), so **hostnames are preserved** - no `127.0.0.1` rewrite and no
  URL patching in the APK.
* `allow_hosts` limits decryption to the MEB domains. Everything else (Firebase, GMS,
  Google Play) is relayed as raw TCP, so the login screen's Firebase dependency keeps
  working - the failure mode of the old setup simply cannot occur.
* **e-Devlet login traffic is not recorded by default.** A real login carries cookies and
  session tokens, so those hosts are relayed raw and never reach `flows.mitm`, the log or
  the mitmweb UI. Enable it explicitly with `WEBVIEW_CAPTURE=1` (see below).
* Requires one-time user action on the phone: import the config and switch the tunnel
  on (Android forbids starting a `VpnService` without user consent).

## e-Devlet / WebView capture is opt-in

| Mode | Command | Decrypted hosts |
|---|---|---|
| default | `./scripts/mitm.sh start` | `*.meb.gov.tr` - the REST API is fully readable (bodies included) |
| opt-in | `WEBVIEW_CAPTURE=1 ./scripts/mitm.sh start` | adds `*.e-devlet.gov.tr`, `*.turkiye.gov.tr` |

So "default" does **not** mean "nothing is decrypted": every MEB host is intercepted and
readable, only the non-MEB traffic (Firebase, Google, e-Devlet identity pages) is relayed
raw. Anything the app requests from `eokulapp.meb.gov.tr`, including WebView URLs on that
host, is captured in default mode.

Two layers enforce this: the `allow_hosts` list, and `scripts/mitm_guard.py`, which
inspects the TLS ClientHello and sets `ignore_connection` for e-Devlet hostnames unless
`MITM_EDEVLET_CAPTURE=1`. Because the decision happens before decryption, an ignored
connection produces no HTTP flow, no bodies and no hostnames in the log.

Verified on the test device (opening the e-Devlet login page in both modes):

| Mode | Captured | e-Devlet hosts in `flows.mitm` |
|---|---|---|
| default | 2 flows, both `POST https://eokulapp.meb.gov.tr/CihazKayit -> 200` | none |
| `WEBVIEW_CAPTURE=1` | the same 2 plus `GET https://www.turkiye.gov.tr/ogrenci-bilgi-sistemi -> 200, 17,447 B` and the analytics beacon | 2 (`www.turkiye.gov.tr`, `analitik.turkiye.gov.tr`) |

The login page renders identically in both modes - in default mode its TLS is simply
relayed untouched, so the WebView still validates the real certificate and nothing needs
to be decrypted for the app to work.

`./scripts/mitm.sh status` reports the mode of the running server:

```
capture: API only (e-Devlet/WebView ignored)
allow_hosts: meb\.gov\.tr
```

## Setup

```bash
python3 -m venv .venv && ./.venv/bin/pip install mitmproxy   # once, or ./scripts/setup.sh

./scripts/mitm.sh start     # wireguard server + client conf + push to /sdcard/Download
WEBVIEW_CAPTURE=1 ./scripts/mitm.sh start   # also capture the e-Devlet WebView (opt-in)
./scripts/mitm.sh conf      # regenerate and re-push just the client config
./scripts/mitm.sh status
./scripts/mitm.sh stop
./scripts/mitm.sh web       # same mode with the mitmweb UI (:8081)
```

On the phone (one time per session):

1. WireGuard app - **+** - **Import from file or archive**
2. pick `Downloads/eokul-mitm.conf`
3. tap the tunnel to activate

Then `./scripts/verify-mitm.sh` launches the app and prints the decrypted requests;
`./scripts/flows.py --body` dumps everything captured in `build/mitm/flows.mitm`.

## What the APK must still provide

Two things cannot be done from the network side on a non-rooted device:

| Requirement | Why | Where |
|---|---|---|
| `network_security_config` with `<certificates src="user"/>` | app targets SDK 36 and ships no NSC - platform default trusts **system** CAs only, so a user-installed mitmproxy CA is rejected by WebView | `scripts/patch/patch_nsc.py` |
| BoringSSL verify bypass (`ssl_crypto_x509_session_verify_cert_chain`, `X509_verify_cert` - `mov w0,#1 ; ret`) | belt-and-braces: any future pinning cannot reject the proxy | `scripts/engine/cert_bypass.py`, engine already patched in `lib/engine/3.35.6/libflutter-patched.so` |

Everything else - the `.env`, `API_URL`, the reverse proxy - is **not** needed anymore,
because certificate pinning was removed and the app talks to the real API directly.
`apks/VBS-Mod.apk` (default build) points at the real `https://eokulapp.meb.gov.tr/`,
so the `.env`'s `API_URL` is left untouched.

The mitmproxy CA must be present as a **user CA** on the device
(`/sdcard/Download/mitmproxy-ca-cert.cer` - Settings - Security - Encryption &
credentials - Install a certificate - CA certificate).

## mitmproxy flags used

```bash
mitmdump --mode wireguard:build/mitm/wg-keys.conf@51820 \
  --set block_global=false \
  --set validate_inbound_headers=false --set validate_outbound_headers=false \
  --set allow_hosts='meb\.gov\.tr|e-devlet\.gov\.tr|turkiye\.gov\.tr'
```

The `.gov.tr` CDN sends a header value with trailing whitespace (`Edge : HIT, `).
mitmproxy rejects such headers by default and drops the connection, which the WebView
reports as `ERR_EMPTY_RESPONSE` / "css socket not connected".

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `ss -lun` shows nothing on 51820 | mitmdump died; check `build/mitm/mitm.log` |
| phone reaches nothing (handshake never completes) | host firewall dropping udp/51820 - `./scripts/mitm.sh status` prints the endpoint; check with `ping` from the phone first |
| endpoint IP wrong | set `WG_ENDPOINT=<host ip>`; by default the interface sharing the phone's Wi-Fi subnet is chosen (falls back to the default-route source) |
| TCP works but nothing is decrypted | host not in `allow_hosts`; widen it via `MITM_ALLOW=...` |
| app shows a crash on the login page | SecureStorage patch missing - see README §4 |

## Previous approach (superseded)

Until Nov 2026 the capture was tied to the APK: `.env`'s `API_URL` pointed at
`https://127.0.0.1:8083` (a reverse proxy reached through `adb reverse`), while WebView
was captured through the Android global proxy on `:8081`. It worked, but:

* the APK only functioned while the reverse proxy and `adb reverse` were up;
* two proxies had to run;
* the global `http_proxy` broke Firebase, which crashed the login screen
  (`Null check operator used on a null value`, `_GirisPageState.build`).

That path is kept as a fallback: `scripts/mitm-adb.sh` plus
`API_URL="https://127.0.0.1:8083" OUT=… ./scripts/build.sh`.