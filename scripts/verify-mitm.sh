#!/usr/bin/env bash
# MITM verification (WireGuard path): is the server up, does the app launch, and
# which requests are being decrypted?
#
#   ./scripts/verify-mitm.sh [serial]
#
# Requires: ./scripts/mitm.sh start + an active WireGuard tunnel on the phone.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
RUN="$ROOT/build/mitm"
LOG="$RUN/mitm.log"
FLOWS="$RUN/flows.mitm"
PY="$ROOT/.venv/bin/python"

ADB=(adb)
SERIAL="${1:-${SERIAL:-}}"
[ -n "$SERIAL" ] && ADB=(adb -s "$SERIAL")

if ! ss -lun 2>/dev/null | grep -q ":${WG_PORT:-51820} "; then
  echo "!! wireguard mitm is down: run ./scripts/mitm.sh start" >&2
  exit 2
fi

"${ADB[@]}" shell input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
"${ADB[@]}" shell wm dismiss-keyguard >/dev/null 2>&1
sleep 1

focus="$("${ADB[@]}" shell dumpsys window 2>/dev/null | grep -m1 mCurrentFocus)"
case "$focus" in
  *NotificationShade*|*Keyguard*) echo "!! device is locked: unlock it first" >&2; exit 3 ;;
esac

tun="$("${ADB[@]}" shell ip -4 -o addr show 2>/dev/null | grep -c 'tun0')"
[ "$tun" -eq 0 ] && echo "!! no tun0 on the device: activate the WireGuard tunnel" >&2

before=0
[ -f "$LOG" ] && before=$(grep -cE "client connect" "$LOG" 2>/dev/null || echo 0)

"${ADB[@]}" shell am force-stop com.meb.vbsmobil
"${ADB[@]}" shell monkey -p com.meb.vbsmobil -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep 10

after=0
[ -f "$LOG" ] && after=$(grep -cE "client connect" "$LOG" 2>/dev/null || echo 0)
echo "== new tunnel connections: $((after - before))"
echo
echo "== decrypted requests =="
if [ -x "$PY" ]; then
  "$PY" scripts/flows.py --host 'meb\.gov\.tr|e-devlet|turkiye\.gov' | tail -40
else
  grep -E 'GET |POST |<< ' "$LOG" | tail -40
fi
echo
echo "== flow file =="
ls -l "$FLOWS" 2>/dev/null
echo "all flows: ./scripts/flows.py --body"
