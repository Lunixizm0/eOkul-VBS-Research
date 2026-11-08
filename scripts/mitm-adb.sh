#!/usr/bin/env bash
# LEGACY / FALLBACK PATH: 8081 = regular proxy (WebView/Java), 8083 = reverse proxy (Flutter/Dart API_URL).
# Current method: scripts/mitm.sh (WireGuard, leaves the APK untouched). This path additionally
# requires an APK built with
#   API_URL="https://127.0.0.1:8083" ./scripts/build.sh
#
#   ./scripts/mitm-adb.sh start [serial] [port]   # proxy + adb reverse + device proxy (8081)
#   ./scripts/mitm-adb.sh rev   [serial] [port]   # reverse proxy -> https://eokulapp.meb.gov.tr (8083)
#   ./scripts/mitm-adb.sh stop                    # tear everything down
#   ./scripts/mitm-adb.sh status [serial]
#   ./scripts/mitm-adb.sh web   [serial] [port]   # mitmweb UI (8081)
#
# Environment: MITM_VENV (default <project>/.venv), REV_UPSTREAM, REV_PORT.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACTION="${1:-status}"
SERIAL="${2:-}"
PORT="${3:-8081}"
PYDIR="${MITM_VENV:-$ROOT/.venv}"
RUN="$ROOT/build/mitm"

export PATH="$PATH:${ANDROID_HOME:-$HOME/Android/Sdk}/platform-tools"
ADB=(adb)
[ -n "$SERIAL" ] && ADB=(adb -s "$SERIAL")

mkdir -p "$RUN"

# The .gov.tr CDN sends header values with trailing whitespace; validation must be off.
FLAGS=(--set block_global=false --set http2=false
       --set validate_inbound_headers=false --set validate_outbound_headers=false)

have_device() {
  local s
  s="$("${ADB[@]}" get-serialno 2>/dev/null)"
  if [ -z "$s" ] || [ "$s" = "unknown" ]; then
    echo "error: no device connected" >&2
    return 1
  fi
}

mitmdump_bin() { if [ -x "$PYDIR/bin/mitmdump" ]; then echo "$PYDIR/bin/mitmdump"; else echo mitmdump; fi; }

port_open() { ss -ltn 2>/dev/null | grep -q ":$1 "; }

case "$ACTION" in
  start)
    have_device || exit 1
    if port_open "$PORT"; then
      echo "proxy already listening: :$PORT"
    else
      setsid "$(mitmdump_bin)" -p "$PORT" "${FLAGS[@]}" \
        -w "$RUN/flows.mitm" >"$RUN/mitm.log" 2>&1 < /dev/null &
      sleep 3
      port_open "$PORT" || { echo "error: proxy did not start"; tail -5 "$RUN/mitm.log"; exit 1; }
    fi
    "${ADB[@]}" reverse "tcp:$PORT" "tcp:$PORT" >/dev/null
    "${ADB[@]}" shell settings put global http_proxy "127.0.0.1:$PORT"
    echo "proxy :$PORT ready  log=$RUN/mitm.log"
    ;;

  rev)
    have_device || exit 1
    REV_PORT="${REV_PORT:-8083}"
    REV_UPSTREAM="${REV_UPSTREAM:-https://eokulapp.meb.gov.tr}"
    if port_open "$REV_PORT"; then
      echo "reverse proxy already listening: :$REV_PORT"
    else
      setsid "$(mitmdump_bin)" --mode "reverse:$REV_UPSTREAM" \
        --listen-host 0.0.0.0 --listen-port "$REV_PORT" "${FLAGS[@]}" \
        -w "$RUN/reverse.mitm" >"$RUN/reverse.log" 2>&1 < /dev/null &
      sleep 3
      port_open "$REV_PORT" || { echo "error: reverse proxy did not start"; tail -5 "$RUN/reverse.log"; exit 1; }
    fi
    "${ADB[@]}" reverse "tcp:$REV_PORT" "tcp:$REV_PORT" >/dev/null
    echo "reverse proxy :$REV_PORT -> $REV_UPSTREAM  log=$RUN/reverse.log"
    ;;

  stop)
    for p in "$PORT" "${REV_PORT:-8083}"; do
      "${ADB[@]}" reverse --remove "tcp:$p" >/dev/null 2>&1
      pkill -9 -f "mitmdump" 2>/dev/null
      pkill -9 -f "mitmweb" 2>/dev/null
    done
    for i in 1 2 3; do
      cur=$("${ADB[@]}" shell settings get global http_proxy 2>/dev/null | tr -d '\r')
      [ "$cur" = ":0" ] && break
      "${ADB[@]}" shell settings put global http_proxy :0 >/dev/null 2>&1
      sleep 0.5
    done
    echo "MITM disabled (device proxy reset)"
    ;;

  status)
    for p in "$PORT" "${REV_PORT:-8083}"; do
      if port_open "$p"; then echo ":$p listening"; else echo ":$p closed"; fi
    done
    "${ADB[@]}" reverse --list 2>/dev/null
    echo "http_proxy=$("${ADB[@]}" shell settings get global http_proxy 2>/dev/null | tr -d '\r')"
    ;;

  web)
    have_device || exit 1
    "${ADB[@]}" reverse "tcp:$PORT" "tcp:$PORT" >/dev/null
    "${ADB[@]}" shell settings put global http_proxy "127.0.0.1:$PORT"
    echo "mitmweb: http://127.0.0.1:$PORT  (run '$0 stop' after Ctrl-C)"
    if [ -x "$PYDIR/bin/mitmweb" ]; then exec "$PYDIR/bin/mitmweb" -p "$PORT" "${FLAGS[@]}"; fi
    exec mitmweb -p "$PORT" "${FLAGS[@]}"
    ;;

  *)
    echo "usage: $0 {start|rev|stop|status|web} [serial] [port]"; exit 1
    ;;
esac
