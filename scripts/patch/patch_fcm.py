#!/usr/bin/env python3
"""Make Messaging#getToken always answer, so a null FCM token cannot abort login.

The stock app asks Firebase for a registration token before it calls the API. In a
re-signed build Firebase cannot always produce one, `getToken()` resolves to null and
the app stops with "Bildirim kimliği alınamadı" - leaving the WebView open and never
saving the session. Push cannot work in a modded build anyway, so this answers the
channel call with a stable placeholder instead of null.

The patch is idempotent and verifiable: it rewrites the method-channel entry point of
the Firebase Messaging plugin and re-reads the result.
"""
import hashlib
import re
import sys
from pathlib import Path

ROOT = Path(sys.argv[1] if len(sys.argv) > 1 else "build/apktool/smali")
TOKEN = sys.argv[2] if len(sys.argv) > 2 else "cVBSmodNoFcmTokenAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"

MARK = "vbs_fcm_token_bypass"

NEEDLE = 'const-string v7, "Messaging#getToken"'

BLOCK = f"""
    # {MARK}: answer Messaging#getToken without touching Firebase.
    iget-object v5, p1, LC2/k;->a:Ljava/lang/String;
    const-string v7, "Messaging#getToken"
    invoke-virtual {{v5, v7}}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v7
    if-eqz v7, :{MARK}_cont
    const-string v7, "VBSFCM"
    const-string v8, "Messaging#getToken intercepted"
    invoke-static {{v7, v8}}, Landroid/util/Log;->d(Ljava/lang/String;Ljava/lang/String;)I
    const-string v7, "{TOKEN}"
    invoke-interface {{p2, v7}}, LC2/m;->success(Ljava/lang/Object;)V
    return-void
    :{MARK}_cont
"""


def find_target() -> Path:
    hits = [p for p in ROOT.rglob("*.smali") if NEEDLE in p.read_text(encoding="utf-8", errors="ignore")]
    if not hits:
        raise SystemExit(f"error: no smali file dispatches {NEEDLE}")
    for p in hits:
        if ".method public final onMethodCall(LC2/k;LC2/m;)V" in p.read_text(encoding="utf-8", errors="ignore"):
            return p
    return hits[0]


def main() -> None:
    target = find_target()
    text = target.read_text(encoding="utf-8")

    if MARK in text:
        print(f"  fcm token bypass: already applied ({target})")
        return

    m = re.search(r"^\.method public final onMethodCall\(LC2/k;LC2/m;\)V\n(?:\s*\.locals \d+\n)", text, re.M)
    if not m:
        raise SystemExit(f"error: onMethodCall(LC2/k;LC2/m;)V not found in {target}")

    patched = text[:m.end()] + BLOCK + text[m.end():]
    target.write_text(patched, encoding="utf-8")

    # verify: marker present inside onMethodCall, file still has the dispatch string
    check = target.read_text(encoding="utf-8")
    start = check.find(".method public final onMethodCall(LC2/k;LC2/m;)V")
    if MARK not in check[start:start + 2000] or NEEDLE not in check:
        raise SystemExit("error: patch verification failed")

    print(f"  fcm token bypass -> {target}")
    print(f"  sha256 {hashlib.sha256(patched.encode()).hexdigest()[:16]}…")


if __name__ == "__main__":
    main()
