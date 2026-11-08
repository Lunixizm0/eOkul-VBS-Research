#!/usr/bin/env bash
# One-shot, idempotent environment bootstrap: tools, keystore, engine, mitmproxy.
#
#   ./scripts/setup.sh
#
# Steps:
#   1. verify required tools
#   2. fetch the apktool jar into tools/apktool.jar (if missing)
#   3. create .venv and install mitmproxy (needed for traffic capture)
#   4. generate keystore/test.keystore and .env (random password)
#   5. verify the apks/original inputs against input-sha256.txt
#   6. build lib/engine/.../libflutter-patched.so (scripts/fetch-engine.sh)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ok()   { printf '  ok    %s\n' "$*"; }
warn() { printf '  warn  %s\n' "$*"; }
die()  { printf '  fail  %s\n' "$*" >&2; exit 1; }

APKTOOL_VER="${APKTOOL_VER:-3.0.3}"
APKTOOL_SHA="${APKTOOL_SHA:-dbf930b076c6b9be08d57c449cacefc3bdd6b71ebd59b3066fc0e1f5b14f9423}"
APKTOOL_URL="https://github.com/iBotPeaches/Apktool/releases/download/v${APKTOOL_VER}/apktool_${APKTOOL_VER}.jar"

echo "== 1/6 tools"
for t in java keytool python3 unzip zip curl sha256sum; do
  command -v "$t" >/dev/null || die "$t not found"
  ok "$t"
done
command -v llvm-strip >/dev/null && ok llvm-strip || warn "llvm-strip missing (engine will not be stripped)"
command -v adb >/dev/null && ok adb || warn "adb missing (install/device tests skipped)"
BT="$(ls -d "${ANDROID_HOME:-$HOME/Android/Sdk}"/build-tools/* /opt/android-sdk/build-tools/* 2>/dev/null | sort -V | tail -1 || true)"
if [ -n "$BT" ]; then ok "build-tools: $BT"; else warn "build-tools missing (zipalign/apksigner required; pass BT=... when building)"; fi

echo "== 2/6 apktool"
mkdir -p tools
verify_apktool() {
  local f="$1"
  local have
  have="$(sha256sum "$f" | cut -d' ' -f1)"
  [ "$have" = "$APKTOOL_SHA" ] || { rm -f "$f"; die "apktool SHA-256 mismatch: $have"; }
}

if [ -n "${APKTOOL_JAR:-}" ] && [ -f "${APKTOOL_JAR}" ]; then
  ok "APKTOOL_JAR=$APKTOOL_JAR"
elif [ -f tools/apktool.jar ]; then
  verify_apktool tools/apktool.jar
  ok "tools/apktool.jar"
elif [ -f "$HOME/tools/apktool_${APKTOOL_VER}.jar" ]; then
  cp "$HOME/tools/apktool_${APKTOOL_VER}.jar" tools/apktool.jar
  verify_apktool tools/apktool.jar
  ok "$HOME/tools/apktool_${APKTOOL_VER}.jar -> tools/apktool.jar"
else
  echo "  downloading: $APKTOOL_URL"
  curl -fL --retry 3 -o tools/apktool.jar.part "$APKTOOL_URL"
  have="$(sha256sum tools/apktool.jar.part | cut -d' ' -f1)"
  if [ "$have" != "$APKTOOL_SHA" ]; then
    rm -f tools/apktool.jar.part
    die "apktool SHA-256 mismatch: $have"
  fi
  mv tools/apktool.jar.part tools/apktool.jar
  ok "sha256 matches"
fi

echo "== 3/6 mitmproxy (.venv)"
if [ -x .venv/bin/mitmdump ]; then
  ok "$(./.venv/bin/mitmdump --version 2>/dev/null | head -1)"
else
  python3 -m venv .venv
  ./.venv/bin/pip install -q --upgrade pip
  echo "  installing mitmproxy..."
  ./.venv/bin/pip install -q mitmproxy
  ok "$(./.venv/bin/mitmdump --version 2>/dev/null | head -1)"
fi

echo "== 4/6 keystore + .env"
if [ -f keystore/test.keystore ]; then
  ok "keystore/test.keystore"
else
  mkdir -p keystore
  PASS="$(head -c 32 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 24)"
  keytool -genkeypair -keystore keystore/test.keystore -alias test \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -storepass "$PASS" -keypass "$PASS" \
    -dname "CN=eOkul Mod, O=research, C=TR" >/dev/null 2>&1
  printf '# apksigner keystore password (keystore/test.keystore, alias "test")\nKEY=%s\n' "$PASS" > .env
  chmod 600 .env
  ok "generated (password stored in .env)"
fi
[ -f .env ] || die ".env missing while keystore exists; restore the keystore password into .env"

echo "== 5/6 original APK inputs"
if [ -f input-sha256.txt ]; then
  sha256sum -c input-sha256.txt >/dev/null 2>&1 && ok "sha256 matches" \
    || die "apks/original/*.apk sha256 mismatch (corrupted or different version)"
else
  die "input-sha256.txt missing"
fi

echo "== 6/6 engine"
./scripts/fetch-engine.sh

echo
echo "ready. Next steps:"
echo "  ./scripts/build.sh                      # -> apks/VBS-Mod.apk"
echo "  adb install -r apks/VBS-Mod.apk"
echo "  ./scripts/mitm.sh start                 # traffic capture (WireGuard)"
