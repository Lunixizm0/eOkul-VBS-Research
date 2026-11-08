"""Keep e-Devlet / WebView traffic out of the capture unless explicitly opted in.

The REST API (`*.meb.gov.tr`) is captured by default; a real e-Devlet login is not.
Because the decision is made at the TLS ClientHello, opting out relays the connection
raw: no HTTP flow, no request/response bodies, no cookies or session tokens in
`flows.mitm` and no hostnames in the log.

Opt in with:  WEBVIEW_CAPTURE=1 ./scripts/mitm.sh start
"""
import os
import re

from mitmproxy import ctx

OPT_IN = os.environ.get("MITM_EDEVLET_CAPTURE", "0") == "1"
PATTERN = re.compile(r"(?:^|\.)(?:e-devlet\.gov\.tr|turkiye\.gov\.tr)$", re.I)


def load(loader):
    if OPT_IN:
        ctx.log.info(
            "e-Devlet/WebView capture: ON - login traffic (cookies, session tokens) "
            "will be written to build/mitm/flows.mitm"
        )
    else:
        ctx.log.info(
            "e-Devlet/WebView capture: off - only *.meb.gov.tr is decrypted "
            "(enable with WEBVIEW_CAPTURE=1)"
        )


def tls_clienthello(data):
    if OPT_IN:
        return
    sni = (data.client_hello.sni or "").lower()
    if sni and PATTERN.search(sni):
        data.ignore_connection = True
