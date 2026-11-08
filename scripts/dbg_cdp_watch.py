#!/usr/bin/env python3
"""Temporary diagnostic: watch a freshly created WebView from its first request.

Polls the WebView's DevTools endpoint, attaches to every page target as soon as
it appears, then records:
  * every script the app evaluates from Dart (scripts without a URL),
  * console output and JS exceptions,
  * every window.flutter_inappwebview.callHandler() call with its caller stack.
"""
import json
import sys
import time
import urllib.request

import websocket

PORT = 9222
SECONDS = float(sys.argv[1]) if len(sys.argv) > 1 else 120.0

HOOK = r"""
(function(){
  if (window.__vbsHook) return; window.__vbsHook = 1;
  function rep(t, v){ try{ (new Image()).src='https://eokulapp.meb.gov.tr/__dbg?t='+encodeURIComponent(t)+'&v='+encodeURIComponent(String(v).slice(0,400))+'&r='+Math.random(); }catch(e){} }
  rep('cdp', 'hook installed ' + location.href);
  function wrap(){
    try {
      var v = window.flutter_inappwebview, orig = v && v.callHandler;
      if (typeof orig !== 'function' || orig.__vbs) return;
      var w = function(name){
        var st = ''; try { st = (new Error()).stack.split('\n').slice(1,5).join(' <- '); } catch(e){}
        rep('ch', name + ' :: ' + st);
        return orig.apply(v, arguments);
      };
      w.__vbs = 1;
      v.callHandler = w;
      rep('wrapped', 'callHandler');
    } catch(e){ rep('hookerr', String(e)); }
  }
  wrap();
  // The plugin redefines callHandler on every navigation, so keep re-wrapping.
  setInterval(wrap, 250);
})();
"""


def pages():
    try:
        with urllib.request.urlopen(f"http://127.0.0.1:{PORT}/json", timeout=3) as r:
            return json.load(r)
    except Exception:
        return []


class Session:
    def __init__(self, target):
        self.ws = websocket.create_connection(target["webSocketDebuggerUrl"], timeout=10, suppress_origin=True)
        self.ws.settimeout(0.5)
        self.mid = 0
        self.target = target
        self.seen_evals = set()
        self.dead = False
        self.seen_msgs = set()

    def send(self, method, params=None):
        self.mid += 1
        try:
            self.ws.send(json.dumps({"id": self.mid, "method": method, "params": params or {}}))
        except Exception:
            self.dead = True
        return self.mid

    def start(self):
        for m in ("Runtime.enable", "Debugger.enable", "Page.enable", "Log.enable"):
            self.send(m)
        self.send("Page.addScriptToEvaluateOnNewDocument", {"source": HOOK})
        self.send("Runtime.evaluate", {"expression": HOOK})
        print(f"attached :: {self.target.get('url')}", flush=True)

    def pump(self):
        if self.dead:
            return
        try:
            msg = json.loads(self.ws.recv())
        except websocket.WebSocketTimeoutException:
            return
        except Exception:
            self.dead = True
            return
        if "id" in msg and isinstance(msg.get("result"), dict) and "scriptSource" in msg["result"]:
            src = " ".join(msg["result"]["scriptSource"].split())
            key = src[:120]
            if key not in self.seen_evals:
                self.seen_evals.add(key)
                print(f"[eval] {src[:400]}", flush=True)
            return
        m = msg.get("method")
        if not m:
            return
        p = msg.get("params", {})
        if m == "Debugger.scriptParsed":
            if not p.get("url"):
                self.send("Debugger.getScriptSource", {"scriptId": p.get("scriptId")})
        elif m == "Runtime.consoleAPICalled":
            args = " ".join(str(a.get("value", a.get("description", "")))[:160] for a in p.get("args", []))
            key = ("c", p.get("type"), args[:80])
            if key not in self.seen_msgs:
                self.seen_msgs.add(key)
                print(f"[console.{p.get('type')}] {args}", flush=True)
        elif m == "Runtime.exceptionThrown":
            d = p.get("exceptionDetails", {})
            txt = (d.get("exception", {}).get("description") or d.get("text") or "")[:240]
            print(f"[exception] {' '.join(txt.split())}", flush=True)


def main() -> None:
    deadline = time.time() + SECONDS
    sessions = {}
    print("watching for WebView targets…", flush=True)
    while time.time() < deadline:
        for t in pages():
            if t.get("type") != "page":
                continue
            tid = t.get("id")
            if tid in sessions:
                continue
            try:
                s = Session(t)
                s.start()
                sessions[tid] = s
            except Exception as e:
                print(f"attach failed: {e}", flush=True)
        for tid, s in list(sessions.items()):
            for _ in range(4):
                s.pump()
        time.sleep(0.2)
    print("done", flush=True)


if __name__ == "__main__":
    main()
