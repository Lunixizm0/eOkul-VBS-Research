#!/usr/bin/env python3
"""Make WebView trust user-installed CAs (no root required).

Apps targeting SDK >= 24 trust only the system CA store by default, so a user CA
such as mitmproxy's is rejected by WebView. Fix: give the APK its own network
security config declaring `<certificates src="user"/>` on top of the system store.

usage: patch_nsc.py [apktool_tree]
"""
import sys
import pathlib

TREE = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else 'build/apktool')

XML = '''<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="true">
        <trust-anchors>
            <certificates src="system"/>
            <certificates src="user"/>
        </trust-anchors>
    </base-config>
</network-security-config>
'''

xml_dir = TREE / 'res' / 'xml'
xml_dir.mkdir(parents=True, exist_ok=True)
nsc = xml_dir / 'network_security_config.xml'
nsc.write_text(XML, encoding='utf-8')

manifest = TREE / 'AndroidManifest.xml'
s = manifest.read_text(encoding='utf-8')

ATTR = ' android:networkSecurityConfig="@xml/network_security_config"'
if ATTR.strip() in s:
    print('  NSC already referenced in manifest')
else:
    idx = s.find('<application')
    if idx < 0:
        sys.exit('ERROR: <application> tag not found')
    end = s.index('>', idx)
    # append the attribute at the end of the tag
    s = s[:end] + ATTR + s[end:]
    manifest.write_text(s, encoding='utf-8')
    print('  NSC added to manifest')

print('  wrote:', nsc)
