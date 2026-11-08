#!/usr/bin/env python3
"""Dump the HTTP flows captured in build/mitm/flows.mitm in a readable form.

  ./scripts/flows.py                 # everything
  ./scripts/flows.py --last 10       # only the last 10 flows
  ./scripts/flows.py --host meb      # only URLs matching the regex
  ./scripts/flows.py --body          # include request/response bodies
  ./scripts/flows.py --json          # machine-readable output
"""
import argparse
import json
import os
import re
import sys

try:
    from mitmproxy import http
    from mitmproxy.io import FlowReader
except ImportError:
    sys.exit("mitmproxy not found: use ./.venv/bin/python scripts/flows.py ... "
             "(install: python3 -m venv .venv && ./.venv/bin/pip install mitmproxy)")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT = os.path.join(ROOT, "build", "mitm", "flows.mitm")


def load(path):
    if not os.path.exists(path) or os.path.getsize(path) == 0:
        return []
    out = []
    with open(path, "rb") as f:
        for fl in FlowReader(f).stream():
            if isinstance(fl, http.HTTPFlow):
                out.append(fl)
    return out


def as_dict(fl):
    req, res = fl.request, fl.response
    return {
        "method": req.method,
        "url": req.pretty_url,
        "status": res.status_code if res else None,
        "request_headers": dict(req.headers),
        "request_body": req.get_text(strict=False) if req.content else None,
        "response_headers": dict(res.headers) if res else None,
        "response_body": res.get_text(strict=False) if res and res.content else None,
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("path", nargs="?", default=DEFAULT)
    ap.add_argument("--last", type=int, default=0, help="only the last N flows")
    ap.add_argument("--host", default="", help="regex matched against the URL")
    ap.add_argument("--body", action="store_true", help="also print bodies")
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args()

    flows = load(a.path)
    if a.host:
        r = re.compile(a.host, re.I)
        flows = [f for f in flows if r.search(f.request.pretty_url)]
    if a.last:
        flows = flows[-a.last:]

    if a.json:
        json.dump([as_dict(f) for f in flows], sys.stdout, ensure_ascii=False, indent=2)
        print()
        return

    for fl in flows:
        req, res = fl.request, fl.response
        status = res.status_code if res else "-"
        size = len(res.content or b"") if res else 0
        print(f"{req.method:6} {req.pretty_url}  ->  {status} {size}b")
        if a.body:
            if req.content:
                print("   >", req.get_text(strict=False)[:800].replace("\n", " "))
            if res and res.content:
                print("   <", res.get_text(strict=False)[:800].replace("\n", " "))
    print(f"total {len(flows)} flows ({a.path})", file=sys.stderr)


if __name__ == "__main__":
    main()
