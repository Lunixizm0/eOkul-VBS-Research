"""Temporary diagnostic addon (NOT part of the normal setup).

Injects a reporter into e-Okul HTML pages so we can see what the Flutter app
does inside its WebView: which elements it reads, what it logs, and JS errors.
Every event is sent as an image request to eokulapp.meb.gov.tr/__dbg, which is
on the MITM allow-list, so the events show up in flows.mitm.
"""
from mitmproxy import http

SNIPPET = """<script>(function(){
  function send(t,v){ try{ new Image().src='https://eokulapp.meb.gov.tr/__dbg?t='+encodeURIComponent(t)+'&v='+encodeURIComponent(String(v).slice(0,400))+'&r='+Math.random(); }catch(e){} }
  send('page', location.href);
  try{
    var g=document.getElementById;
    document.getElementById=function(id){ var r=g.apply(document,arguments);
      send('getById', id+' => '+(r? (r.value!==undefined? r.value : '[no value]') : 'null')); return r; };
    var q=document.querySelectorAll;
    document.querySelectorAll=function(s){ send('qsa', s); return q.apply(document,arguments); };
  }catch(e){}
  function wrapHandler(){
    try{
      var fw=window.flutter_inappwebview;
      if(!fw||fw.__vbsWrapped) return false;
      var orig=fw.callHandler;
      fw.callHandler=function(name){ var a=[]; try{ a=Array.prototype.slice.call(arguments,1); }catch(e){}
        try{ send('callHandler', String(name)+' | '+JSON.stringify(a).slice(0,300)); }catch(e){}
        return orig.apply(fw, arguments); };
      fw.__vbsWrapped=true; send('wrap','ok'); return true;
    }catch(e){ return false; }
  }
  if(!wrapHandler()){ var iv=setInterval(function(){ if(wrapHandler()) clearInterval(iv); },200); }
  window.addEventListener('error', function(e){ send('jserr', (e.message||'')+' @'+(e.filename||'')+':'+(e.lineno||0)); });
  ['log','error','warn'].forEach(function(k){ var o=console[k]; console[k]=function(){ send('console.'+k, Array.prototype.join.call(arguments,' ')); return o.apply(console,arguments); }; });
})();</script>"""


def response(flow: http.HTTPFlow) -> None:
    # The WebView dials the IP, so the flow's host is the address; pretty_host
    # falls back to the Host header / SNI and carries the real name.
    names = {flow.request.host, flow.request.pretty_host}
    if not any(n == "e-okul.meb.gov.tr" for n in names if n):
        return
    ctype = flow.response.headers.get("content-type", "")
    if "text/html" not in ctype:
        return
    body = flow.response.get_text(strict=False)
    if not body:
        return
    i = body.lower().find("<head")
    if i < 0:
        return
    j = body.find(">", i) + 1
    flow.response.set_text(body[:j] + SNIPPET + body[j:])
