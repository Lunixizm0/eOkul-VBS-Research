#!/usr/bin/env python3
"""Point flutter_secure_storage at plain SharedPreferences.

On Android 16 `EncryptedSharedPreferences` (AndroidX Security + Tink) fails during
protobuf reflection with `NullPointerException: name == null`, so every write throws and
the session (e-Devlet token, selected student) is lost on each launch.

The replacement is vendored as `assets/k2_a.smali` (the plugin's obfuscated
implementation, class `Lk2/a;`) because it is a hand-verified rewrite of five methods:

  c()  init        -> always Context.getSharedPreferences(name, 0) and set the
                      "plain/cipherless" flag (`i`) to TRUE
  e()  isEncrypted -> TRUE when that flag is set, so write/read/readAll take the
                      plaintext branch
  i()  write       -> Editor.putString(key, value) with no cipher
  b()  read        -> returns the raw stored string when the storage cipher is null
  h()  readAll     -> same, via e()

Net effect: values live unencrypted in `shared_prefs/FlutterSecureStorage.xml`, which
is what makes the session survive process restarts. Data written by an *earlier* build
(encrypted blobs) is unreadable; clear app data once after switching builds.

The vendored file also carries the resolved ghost-class strings, so this patch must run
after `patch_strings.py`. Both hashes below pin the exact app version (3.3.2 / 69).

usage: patch_storage.py [smali_dir]
"""
import hashlib
import pathlib
import shutil
import sys

SMALI = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else 'build/apktool/smali')
TARGET = SMALI / 'k2' / 'a.smali'
VENDOR = pathlib.Path(__file__).resolve().parent / 'assets' / 'k2_a.smali'

# k2/a.smali as decoded from apks/original/base.apk (3.3.2)
ORIG_SHA = 'b5bd9828eb976899d392246b5b5ea3bcf0ad25722ceb872cc88b54a45dfc66ae'
# vendored patched version (also includes the patch_strings replacements)
PATCHED_SHA = '15a6a6ad5c6b73c651d70712d573c15902d1a56efd0f7fe747e2bb85f3701bc4'


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


if not TARGET.exists():
    sys.exit('ERROR: %s not found' % TARGET)
if not VENDOR.exists():
    sys.exit('ERROR: vendored file missing: %s' % VENDOR)

have = sha256(TARGET)
if have == PATCHED_SHA:
    print('  storage already patched')
    sys.exit(0)
if have != ORIG_SHA:
    sys.exit('ERROR: unexpected k2/a.smali (sha256 %s)\n'
             '       expected the 3.3.2 original or the patched version.\n'
             '       A different app version needs a new patch + vendored file.' % have)

shutil.copyfile(VENDOR, TARGET)
if sha256(TARGET) != PATCHED_SHA:
    sys.exit('ERROR: copy verification failed')
print('  storage -> plain SharedPreferences (k2/a.smali)')
