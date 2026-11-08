#!/usr/bin/env bash
# Flutter engine artifacts -> lib/engine/<rev>/libflutter-patched.so
#
# The libflutter.so the build needs is the original library whose first 50 KB of
# .text is encrypted by PairIP. This script downloads the official artifacts archive
# of the same revision, patches BoringSSL certificate verification and strips it.
#
#   ./scripts/fetch-engine.sh          # download/build if missing
#   ./scripts/fetch-engine.sh --force  # rebuild from scratch
#
# Environment: ENGINE_REV, ENGINE_DIR
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

REV="${ENGINE_REV:-d2913632a4578ee4d0b8b1c4a69888c8a0672c4b}"
DEST="${ENGINE_DIR:-$ROOT/lib/engine/3.35.6}"
URL="https://storage.googleapis.com/flutter_infra_release/flutter/$REV/android-arm64-release/artifacts.zip"
ZIP_SHA="830d0570586ba54c4db260971f6eedb0a921307b8a289ea5e3de660be7c45197"
OUT="$DEST/libflutter-patched.so"

if [ -f "$OUT" ] && [ "${1:-}" != "--force" ]; then
  echo "engine already present: $OUT"
  exit 0
fi

mkdir -p "$DEST"

if [ ! -f "$DEST/artifacts.zip" ] || [ "${1:-}" = "--force" ]; then
  echo "== downloading: $URL"
  curl -fL --retry 3 -o "$DEST/artifacts.zip.part" "$URL"
  have="$(sha256sum "$DEST/artifacts.zip.part" | cut -d' ' -f1)"
  if [ "$have" != "$ZIP_SHA" ]; then
    rm -f "$DEST/artifacts.zip.part"
    echo "error: artifacts.zip sha256 mismatch" >&2
    echo "  expected: $ZIP_SHA" >&2
    echo "  actual  : $have" >&2
    exit 1
  fi
  mv "$DEST/artifacts.zip.part" "$DEST/artifacts.zip"
fi
echo "== artifacts.zip sha256 verified"

echo "== flutter.jar -> lib/arm64-v8a/libflutter.so"
unzip -p "$DEST/artifacts.zip" flutter.jar > "$DEST/flutter.jar"
unzip -p "$DEST/flutter.jar" lib/arm64-v8a/libflutter.so > "$DEST/libflutter-unstripped.so"
rm -f "$DEST/flutter.jar"

echo "== applying cert-verify patch"
python3 scripts/engine/cert_bypass.py "$DEST/libflutter-unstripped.so" "$OUT"

if command -v llvm-strip >/dev/null; then
  llvm-strip --strip-unneeded "$OUT"
else
  echo "warning: llvm-strip missing; engine left unstripped (larger APK)" >&2
fi

echo "== verifying patch bytes"
python3 - "$OUT" <<'PY'
import struct, sys
d = open(sys.argv[1], 'rb').read()
e_phoff, = struct.unpack_from('<Q', d, 0x20)
e_phentsize, = struct.unpack_from('<H', d, 0x36)
e_phnum, = struct.unpack_from('<H', d, 0x38)
segs = []
for i in range(e_phnum):
    t, _f, off, va, _pa, fsz, _msz, _al = struct.unpack_from('<IIQQQQQQ', d, e_phoff + i * e_phentsize)
    if t == 1:
        segs.append((va, va + fsz, off))

def foff(va):
    for s, e, o in segs:
        if s <= va < e:
            return o + (va - s)
    raise SystemExit('address not inside any PT_LOAD: 0x%x' % va)

want = bytes.fromhex('20008052c0035fd6')
for name, va in (('ssl_crypto_x509_session_verify_cert_chain', 0x716b60), ('X509_verify_cert', 0x6fb758)):
    got = d[foff(va):foff(va) + 8]
    if got != want:
        raise SystemExit('patch verification failed: %s @0x%x -> %s' % (name, va, got.hex()))
    print('  ok  %-42s 0x%x' % (name, va))
PY

ls -l "$OUT"
echo "ready: $OUT"
