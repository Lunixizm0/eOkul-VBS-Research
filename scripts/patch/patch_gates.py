#!/usr/bin/env python3
"""Disable the PairIP protection gates. Does not touch the VM/decryptor.

Only these three methods are turned into no-ops:
  - SignatureCheck.verifyIntegrity   (signature check -> throw)
  - LicenseClient.checkLicense       (license check)
  - LicenseContentProvider.onCreate  (provider that kicks off the license check)
"""
import re, sys, os

SMALI = sys.argv[1] if len(sys.argv) > 1 else "rebuild/smali"


def patch(path, method_regex, inject):
    with open(path) as f:
        lines = f.readlines()
    out = []
    i = 0
    n = len(lines)
    done = False
    while i < n:
        line = lines[i]
        if not done and line.startswith(".method") and re.search(method_regex, line):
            out.append(line)
            i += 1
            # 1) .locals / .registers (girintili olabilir)
            while i < n and lines[i].strip().startswith((".locals", ".registers")):
                out.append(lines[i])
                i += 1
            # 2) annotation bloklari
            while i < n and lines[i].strip().startswith(".annotation"):
                while i < n and not lines[i].strip().startswith(".end annotation"):
                    out.append(lines[i])
                    i += 1
                if i < n:
                    out.append(lines[i])
                    i += 1
            # 3) govdeye gir
            out.append(inject)
            done = True
            continue
        out.append(line)
        i += 1
    if not done:
        print(f"  !! METHOD NOT FOUND: {method_regex} in {path}")
        return False
    with open(path, "w") as f:
        f.writelines(out)
    print(f"  OK: {path} :: {method_regex}")
    return True


ok = True
ok &= patch(os.path.join(SMALI, "com/pairip/SignatureCheck.smali"),
            r"verifyIntegrity\(Landroid/content/Context;\)V",
            "    return-void\n")
ok &= patch(os.path.join(SMALI, "com/pairip/licensecheck/LicenseClient.smali"),
            r"checkLicense\(Landroid/content/Context;\)V",
            "    return-void\n")
ok &= patch(os.path.join(SMALI, "com/pairip/licensecheck/LicenseContentProvider.smali"),
            r"onCreate\(\)Z",
            "    const/4 v0, 0x1\n\n    return v0\n")

sys.exit(0 if ok else 1)
