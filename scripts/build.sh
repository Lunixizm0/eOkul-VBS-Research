#!/usr/bin/env bash
# Build apks/VBS-Mod.apk from apks/original/base.apk.
#
#   ./scripts/build.sh           # reuse build/apktool if present
#   ./scripts/build.sh --fresh   # re-decompile from the original APK
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# NOTE: pipefail is on; an unmatched glob makes ls exit 2 -> "|| true" is required.
BT="${BT:-$(ls -d "${ANDROID_HOME:-$HOME/Android/Sdk}"/build-tools/* /opt/android-sdk/build-tools/* 2>/dev/null | sort -V | tail -1 || true)}"
: "${APKTOOL_JAR:=$ROOT/tools/apktool.jar}"
[ -f "$APKTOOL_JAR" ] || APKTOOL_JAR="$HOME/tools/apktool_3.0.3.jar"
ORIG="apks/original"
TREE="build/apktool"
OUTDIR="build/out"
ENGINE="lib/engine/3.35.6/libflutter-patched.so"
KEYSTORE="keystore/test.keystore"
KEY_ALIAS="${KEY_ALIAS:-test}"
OUT="${OUT:-apks/VBS-Mod.apk}"
# Default: .env keeps the original URL (MITM happens at the network layer, via WireGuard).
# If API_URL=... is set (legacy adb-proxy path only) the .env is redirected.
API_URL="${API_URL:-}"

[ -n "$BT" ] || { echo "build-tools not found (pass BT=/path/to/build-tools/x.y.z)"; exit 1; }
[ -f "$APKTOOL_JAR" ] || { echo "missing apktool: $APKTOOL_JAR  ->  ./scripts/setup.sh"; exit 1; }
if [ ! -f "$ENGINE" ]; then
  echo "missing engine: $ENGINE  ->  ./scripts/fetch-engine.sh"
  exit 1
fi
for f in "$ORIG/base.apk" "$ORIG/split_config.arm64_v8a.apk"; do
  [ -f "$f" ] || { echo "missing input: $f (see docs/09-reproduce.md)"; exit 1; }
done

export KS_PASS="${KS_PASS:-$(grep '^KEY=' .env 2>/dev/null | cut -d= -f2-)}"
[ -n "$KS_PASS" ] || { echo "KEY=... not found in .env"; exit 1; }

if [ "${1:-}" = "--fresh" ] || [ ! -d "$TREE" ]; then
  echo "== apktool d =="
  rm -rf "$TREE"
  java -jar "$APKTOOL_JAR" d "$ORIG/base.apk" -o "$TREE" -f >/dev/null
fi

echo "== smali patches =="
python3 scripts/patch/patch_gates.py "$TREE/smali"
python3 scripts/patch/patch_vm.py "$TREE/smali"
# storage patch first: it replaces k2/a.smali wholesale (strings already resolved there)
python3 scripts/patch/patch_storage.py "$TREE/smali"
python3 scripts/patch/patch_strings.py "$TREE/smali" dump/strings_dump.json
# A modded build cannot rely on a Firebase token; answer the channel call instead.
python3 scripts/patch/patch_fcm.py "$TREE/smali"
python3 scripts/patch/patch_nsc.py "$TREE"

echo "== reset .env (from the original APK) =="
mkdir -p "$TREE/assets/flutter_assets"
unzip -p "$ORIG/base.apk" assets/flutter_assets/.env > "$TREE/assets/flutter_assets/.env"

# Without API_URL the .env keeps the original (real) address -> the APK works standalone.
echo "== .env + manifest =="
python3 - "$TREE" <<'PY'
import os, re, sys, pathlib
tree = pathlib.Path(sys.argv[1])

env = tree / "assets/flutter_assets/.env"
s = env.read_text(encoding="utf-8").replace("ENABLE_CERT_PINNING=true", "ENABLE_CERT_PINNING=false")
api = os.environ.get("API_URL", "").strip()
if api:
    s, n = re.subn(r"(?m)^API_URL=.*$", "API_URL=" + api, s)
    print(f"  API_URL -> {api} ({n} lines)")
env.write_text(s, encoding="utf-8")

m = tree / "AndroidManifest.xml"
x = m.read_text(encoding="utf-8")
# The decompiled tree is reused between builds: drop an attribute from a previous
# DEBUGGABLE=1 run first, otherwise aapt2 rejects the duplicate.
x = re.sub(r'\s+android:debuggable="[^"]*"', "", x)
if os.environ.get("DEBUGGABLE") == "1":
    x = x.replace('<application ', '<application android:debuggable="true" ', 1)
    print("  debuggable build (run-as enabled)")
x = x.replace(' android:requiredSplitTypes="base__abi,base__density"', "").replace(' android:splitTypes=""', "")
m.write_text(x, encoding="utf-8")
print("  .env pinning=false, requiredSplitTypes removed")
PY

echo "== apktool b =="
mkdir -p "$OUTDIR"
java -jar "$APKTOOL_JAR" b "$TREE" -o "$OUTDIR/base-unsigned.apk" >/dev/null

echo "== native libs =="
rm -rf "$OUTDIR/native" && mkdir -p "$OUTDIR/native/lib/arm64-v8a"
unzip -o -q "$ORIG/split_config.arm64_v8a.apk" 'lib/arm64-v8a/*' -d "$OUTDIR/native"
cp "$ENGINE" "$OUTDIR/native/lib/arm64-v8a/libflutter.so"

cp "$OUTDIR/base-unsigned.apk" "$OUTDIR/mod-unsigned.apk"
if unzip -l "$OUTDIR/mod-unsigned.apk" | grep -q 'lib/arm64-v8a/'; then
  zip -q -d "$OUTDIR/mod-unsigned.apk" 'lib/arm64-v8a/*' >/dev/null 2>&1 || true
fi
( cd "$OUTDIR/native" && zip -X -0 -q "../mod-unsigned.apk" lib/arm64-v8a/*.so )

echo "== zipalign + sign =="
"$BT/zipalign" -f -p 4 "$OUTDIR/mod-unsigned.apk" "$OUTDIR/mod-aligned.apk"
"$BT/apksigner" sign \
  --ks "$KEYSTORE" --ks-key-alias "$KEY_ALIAS" \
  --ks-pass env:KS_PASS --key-pass env:KS_PASS \
  --v1-signing-enabled true --v2-signing-enabled true --v3-signing-enabled true \
  --out "$OUT" "$OUTDIR/mod-aligned.apk"
"$BT/apksigner" verify "$OUT"

echo "OK: $OUT ($(du -h "$OUT" | cut -f1))"
