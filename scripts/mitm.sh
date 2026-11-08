#!/usr/bin/env bash
# Root-free MITM that leaves the APK untouched: mitmproxy WireGuard mode.
#
# The phone routes its traffic through the tunnel via VpnService (Flutter/Dart,
# WebView and Java alike); mitmproxy answers DNS and decrypts only the connections
# matching `allow_hosts`, relaying everything else raw. No `.env` API_URL rewrite,
# no `adb reverse`, no device-wide http_proxy.
#
#   ./scripts/mitm.sh start    # WireGuard server + targeted MITM (UDP 51820)
#   ./scripts/mitm.sh conf     # regenerate client .conf, push it to the phone
#   ./scripts/mitm.sh status
#   ./scripts/mitm.sh stop
#   ./scripts/mitm.sh purge    # stop and delete captured flows/logs
#   ./scripts/mitm.sh web      # same mode with the mitmweb UI (http://127.0.0.1:8081)
#
# Environment: WG_PORT(51820)  WG_ENDPOINT(auto)  MITM_ALLOW(regex)  MITM_VENV(.venv)
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PY="${MITM_VENV:-$ROOT/.venv}"
MITMDUMP="$PY/bin/mitmdump"
MITMWEB="$PY/bin/mitmweb"
RUN="$ROOT/build/mitm"
PORT="${WG_PORT:-51820}"
KEYS="$RUN/wg-keys.conf"
CONF="$RUN/wireguard-client.conf"
PIDF="$RUN/mitm.pid"
LOGF="$RUN/mitm.log"

# e-Devlet login traffic is NOT recorded by default: a real login carries cookies and
# session tokens. Only *.meb.gov.tr is decrypted unless WEBVIEW_CAPTURE=1.
WEBVIEW_CAPTURE="${WEBVIEW_CAPTURE:-0}"
if [ "$WEBVIEW_CAPTURE" = "1" ]; then
  ALLOW="${MITM_ALLOW:-meb\.gov\.tr|e-devlet\.gov\.tr|turkiye\.gov\.tr}"
  CAPTURE_NOTE="MEB hosts + e-Devlet login DECRYPTED (opt-in; cookies/tokens are recorded)"
else
  ALLOW="${MITM_ALLOW:-meb\.gov\.tr}"
  CAPTURE_NOTE="MEB hosts DECRYPTED (API readable); everything else raw - incl. e-Devlet"
fi
export MITM_EDEVLET_CAPTURE="$WEBVIEW_CAPTURE"

# The .gov.tr CDN sends header values with trailing whitespace -> validation off.
FLAGS=(--set block_global=false
       --set validate_inbound_headers=false
       --set validate_outbound_headers=false
       --set allow_hosts="$ALLOW"
       -s "$ROOT/scripts/mitm_guard.py")

ADB=(adb)
SERIAL="${SERIAL:-$(adb get-serialno 2>/dev/null)}"
if [ -n "$SERIAL" ] && [ "$SERIAL" != "unknown" ]; then ADB=(adb -s "$SERIAL"); fi

mkdir -p "$RUN"

need_venv() {
  if [ ! -x "$MITMDUMP" ]; then
    echo "error: mitmproxy not found ($MITMDUMP). Install: python3 -m venv .venv && ./.venv/bin/pip install mitmproxy" >&2
    exit 1
  fi
}

running_pid() {
  local p
  p="$( [ -f "$PIDF" ] && cat "$PIDF" 2>/dev/null )"
  if [ -n "${p:-}" ] && kill -0 "$p" 2>/dev/null; then echo "$p"; return 0; fi
  return 1
}

udp_listening() { ss -lun 2>/dev/null | grep -q ":$PORT "; }

# Local IP the phone can reach: prefer the interface sharing the phone's Wi-Fi subnet,
# fall back to any shared subnet, then to the default-route source.
host_ip_for() {
  ip -4 -o addr show scope global | awk -v pfx="${1%.*}" '
    { split($4, a, "/"); split(a[1], o, ".");
      if ((o[1] "." o[2] "." o[3]) == pfx) { print a[1]; exit } }'
}

auto_endpoint() {
  local list name ip h
  list="$("${ADB[@]}" shell ip -4 -o addr show 2>/dev/null | awk '{print $2, $4}' | cut -d/ -f1)"
  # 1) wlan*: keep the tunnel on Wi-Fi instead of the link carrying the host's uplink
  while read -r name ip; do
    [ -n "${ip:-}" ] || continue
    case "$name" in wlan*) h="$(host_ip_for "$ip")"; [ -n "$h" ] && { echo "$h"; return; } ;; esac
  done <<< "$list"
  # 2) any shared subnet
  while read -r name ip; do
    [ -n "${ip:-}" ] || continue
    h="$(host_ip_for "$ip")"; [ -n "$h" ] && { echo "$h"; return; }
  done <<< "$list"
  # 3) default-route source
  ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}'
}

endpoint() { echo "${WG_ENDPOINT:-$(auto_endpoint)}"; }

start_server() {
  need_venv
  if running_pid >/dev/null; then echo "already running (pid $(running_pid)), :$PORT"; return 0; fi
  setsid "$MITMDUMP" --mode "wireguard:$KEYS@$PORT" "${FLAGS[@]}" \
    -w "$RUN/flows.mitm" >"$LOGF" 2>&1 < /dev/null &
  local p=$!
  echo "$p" >"$PIDF"
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    sleep 0.4
    udp_listening && break
  done
  if ! udp_listening; then
    echo "error: $PORT/udp is not listening" >&2; tail -20 "$LOGF" >&2; exit 1
  fi
  echo "$WEBVIEW_CAPTURE" >"$RUN/capture.mode"
  echo "wireguard mitm ready  udp/$PORT  endpoint $(endpoint):$PORT  pid $p"
  echo "  capture: $CAPTURE_NOTE"
  echo "  log: $LOGF   flows: $RUN/flows.mitm"
}

make_conf() {
  need_venv
  [ -f "$KEYS" ] || { echo "error: $KEYS missing; run './scripts/mitm.sh start' first" >&2; exit 1; }
  local ep; ep="$(endpoint)"
  [ -n "$ep" ] || { echo "error: no endpoint IP found (set WG_ENDPOINT=...)" >&2; exit 1; }
  "$PY/bin/python" - "$KEYS" "$CONF" "$ep" "$PORT" <<'PY'
import json, sys
import mitmproxy_rs.wireguard as wg
keys_path, out, ep, port = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
k = json.load(open(keys_path))
conf = f"""[Interface]
PrivateKey = {k['client_key']}
Address = 10.0.0.1/32
DNS = 10.0.0.53

[Peer]
PublicKey = {wg.pubkey(k['server_key'])}
AllowedIPs = 0.0.0.0/0
Endpoint = {ep}:{port}
"""
open(out, "w").write(conf)
print(out)
PY
  local ok=0
  "${ADB[@]}" push "$CONF" /sdcard/Download/eokul-mitm.conf >/dev/null 2>&1 && ok=1
  echo "client config: $CONF"
  [ "$ok" = 1 ] && echo "pushed to device: /sdcard/Download/eokul-mitm.conf"
  return 0
}

push_conf() {
  make_conf
  "${ADB[@]}" shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE \
    -d file:///sdcard/Download/eokul-mitm.conf >/dev/null 2>&1
}

case "${1:-status}" in
  start)
    start_server
    make_conf
    ;;

  conf)
    push_conf
    echo
    echo "On the phone: WireGuard app -> + -> 'Import from file or archive' -> Downloads/eokul-mitm.conf"
    ;;

  stop)
    if p="$(running_pid)"; then kill "$p" 2>/dev/null; sleep 1; kill -9 "$p" 2>/dev/null; fi
    rm -f "$PIDF"
    udp_listening && echo "warning: :$PORT still listening" || echo "mitm stopped"
    ;;

  status)
    MODE="$(cat "$RUN/capture.mode" 2>/dev/null || echo "$WEBVIEW_CAPTURE")"
    if [ "$MODE" = "1" ]; then
      STATUS_ALLOW="${MITM_ALLOW:-meb\.gov\.tr|e-devlet\.gov\.tr|turkiye\.gov\.tr}"
      STATUS_NOTE="MEB hosts + e-Devlet login DECRYPTED (opt-in)"
    else
      STATUS_ALLOW="${MITM_ALLOW:-meb\.gov\.tr}"
      STATUS_NOTE="MEB hosts DECRYPTED (API readable); everything else raw, incl. e-Devlet"
    fi
    if p="$(running_pid)"; then echo "mitm: running (pid $p)"; else echo "mitm: stopped"; fi
    udp_listening && echo "udp/$PORT: listening" || echo "udp/$PORT: not listening"
    echo "endpoint: $(endpoint)"
    echo "capture: $STATUS_NOTE"
    echo "allow_hosts: $STATUS_ALLOW"
    [ -f "$CONF" ] && echo "client config: $CONF"
    if [ -f "$LOGF" ]; then
      n="$(grep -c -E "server connect|client connect" "$LOGF" 2>/dev/null || echo 0)"
      echo "log connect lines: $n"
    fi
    ;;

  purge)
    if p="$(running_pid)"; then kill "$p" 2>/dev/null; sleep 1; kill -9 "$p" 2>/dev/null; fi
    rm -f "$PIDF" "$RUN/flows.mitm" "$RUN/reverse.mitm" "$LOGF" "$RUN/reverse.log"
    echo "captured flows and logs deleted"
    ;;

  web)
    need_venv
    echo "mitmweb: http://127.0.0.1:8081   (Ctrl-C to stop)"
    echo "$WEBVIEW_CAPTURE" >"$RUN/capture.mode"
    exec "$MITMWEB" --mode "wireguard:$KEYS@$PORT" "${FLAGS[@]}" -w "$RUN/flows.mitm"
    ;;

  *)
    echo "usage: $0 {start|conf|status|stop|purge|web}"; exit 1
    ;;
esac
