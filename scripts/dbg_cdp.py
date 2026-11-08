#!/usr/bin/env python3
"""Temporary diagnostic: watch what the Flutter app does inside its WebView.

Attaches to the WebView's Chrome DevTools socket, reloads the current page and
records every script the app evaluates, every console message and every JS
exception. Evaluated snippets show up as scripts without a URL, which is exactly
the code the app injects from Dart.
"""
import json
import sys
import time

import websocket

PORT = 9222
SECONDS = float(sys.argv[1]) if len(sys.argv) > 1 else 25.0


def targets():
    import urllib.request

    with urllib.request.urlopen(f"http://127.0.0.1:{PORT}/json", timeout=5) as r:
        return [t for t in json.load(r) if t.get("type") == "page" and t.get("url")]


def main() -> None:
    pages = targets()
    if not pages:
        raise SystemExit("no page target")
    page = pages[0]
    print(f"page: {page['url']}")
    ws = websocket.create_connection(page["webSocketDebuggerUrl"], timeout=10, suppress_origin=True)

    mid = 0
    pending_src = {}

    def send(method, params=None):
        nonlocal mid
        mid += 1
        ws.send(json.dumps({"id": mid, "method": method, "params": params or {}}))
        return mid

    for m in ("Runtime.enable", "Debugger.enable", "Log.enable", "Page.enable"):
        send(m)

    send("Runtime.evaluate", {"expression": "location.reload()"})
    deadline = time.time() + SECONDS
    ws.settimeout(1.0)
    seen = set()

    while time.time() < deadline:
        try:
            msg = json.loads(ws.recv())
        except websocket.WebSocketTimeoutException:
            continue
        if "method" not in msg:
            continue
        m = msg["method"]
        p = msg.get("params", {})
        if m == "Debugger.scriptParsed":
            url = p.get("url") or ""
            if url and not url.startswith("https://e-okul"):
                continue
            if url:
                continue
            sid = p.get("scriptId")
            pending_src[sid] = True
            send("Debugger.getScriptSource", {"scriptId": sid})
        elif m == "Runtime.consoleAPICalled":
            args = " ".join(str(a.get("value", a.get("description", "")))[:160] for a in p.get("args", []))
            key = ("console", p.get("type"), args)
            if key not in seen:
                seen.add(key)
                print(f"[console.{p.get('type')}] {args}")
        elif m == "Runtime.exceptionThrown":
            d = p.get("exceptionDetails", {})
            txt = (d.get("exception", {}).get("description") or d.get("text") or "")[:300]
            key = ("exc", txt[:80])
            if key not in seen:
                seen.add(key)
                print(f"[exception] {txt}")
        elif m == "Log.entryAdded":
            e = p.get("entry", {})
            print(f"[log:{e.get('level')}] {str(e.get('text'))[:200]}")
        if "id" in msg and isinstance(msg.get("result"), dict) and "scriptSource" in msg["result"]:
            src = msg["result"]["scriptSource"]
            pending_src.pop(str(msg.get("id")), None)
            head = " ".join(src.split())[:300]
            print(f"[eval] {head}")

    ws.close()


if __name__ == "__main__":
    main()
