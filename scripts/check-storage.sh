#!/usr/bin/env bash
# Verify that the patched storage keeps the e-Devlet session across a restart.
#
#   ./scripts/check-storage.sh [serial]
#
# Does: clear logcat -> force-stop -> relaunch -> wait -> report storage errors and
# whether the student list is still populated.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PKG="com.meb.vbsmobil"
ADB=(adb)
SERIAL="${1:-${SERIAL:-}}"
[ -n "$SERIAL" ] && ADB=(adb -s "$SERIAL")

"${ADB[@]}" get-serialno >/dev/null 2>&1 || { echo "error: no device" >&2; exit 1; }

echo "== relaunching $PKG"
"${ADB[@]}" logcat -c >/dev/null 2>&1
"${ADB[@]}" shell am force-stop "$PKG"
"${ADB[@]}" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep 12

echo "== storage errors in logcat"
errs="$("${ADB[@]}" logcat -d -t 4000 2>/dev/null |
        grep -iE "SecureStorage|StorageCipher|EncryptedSharedPreferences|NullPointerException" |
        head -10)"
if [ -n "$errs" ]; then echo "$errs"; else echo "  none"; fi

echo "== UI state"
"${ADB[@]}" shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1
ui="$("${ADB[@]}" shell cat /sdcard/ui.xml 2>/dev/null)"
if echo "$ui" | grep -q "Listenizde öğrenci bulunmamaktadır"; then
  echo "  student list is EMPTY (either no student added yet, or the session was lost)"
elif echo "$ui" | grep -q "ÖĞRENCİ EKLE"; then
  echo "  student list appears populated (session survived the restart)"
else
  echo "  could not determine UI state"
fi

echo
echo "If the list is empty after a successful login: adb shell pm clear $PKG (once),"
echo "then log in again and re-run this script."
