import re, sys

# Historical (first attempt) patch set; the current build uses patch_gates.py + patch_vm.py.
ROOT = (sys.argv[1] if len(sys.argv) > 1 else 'build/apktool/smali').rstrip('/') + '/'

def patch(path, signature, body):
    p = ROOT + path
    src = open(p, encoding='utf-8').read()
    pat = re.compile(r'\.method [^\n]*' + re.escape(signature) + r'\n.*?\.end method', re.S)
    m = pat.search(src)
    if not m:
        print('!! NOT FOUND:', path, signature)
        return False
    new = '.method ' + body.strip() + '\n.end method'
    src = src[:m.start()] + new + src[m.end():]
    open(p, 'w', encoding='utf-8').write(src)
    print('ok:', path, '->', signature)
    return True

ok = True
ok &= patch('com/pairip/VMRunner.smali',
            '<clinit>()V',
            'static constructor <clinit>()V\n    .locals 0\n\n    return-void')

ok &= patch('com/pairip/VMRunner.smali',
            'invoke(Ljava/lang/String;[Ljava/lang/Object;)Ljava/lang/Object;',
            'public static invoke(Ljava/lang/String;[Ljava/lang/Object;)Ljava/lang/Object;\n    .locals 1\n\n    const/4 v0, 0x0\n\n    return-object v0')

ok &= patch('com/pairip/SignatureCheck.smali',
            'verifyIntegrity(Landroid/content/Context;)V',
            'public static verifyIntegrity(Landroid/content/Context;)V\n    .locals 0\n\n    return-void')

ok &= patch('com/pairip/licensecheck/LicenseClient.smali',
            'checkLicense(Landroid/content/Context;)V',
            'public static checkLicense(Landroid/content/Context;)V\n    .locals 0\n\n    return-void')

ok &= patch('com/pairip/licensecheck/LicenseClient.smali',
            'initializeLicenseCheck()V',
            'public initializeLicenseCheck()V\n    .locals 0\n\n    return-void')

ok &= patch('com/pairip/licensecheck/LicenseContentProvider.smali',
            'onCreate()Z',
            'public onCreate()Z\n    .locals 1\n\n    const/4 v0, 0x1\n\n    return v0')

sys.exit(0 if ok else 1)
