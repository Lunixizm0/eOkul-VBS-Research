# Small convenience wrapper. Everything here also runs as plain scripts.

.PHONY: setup build install capture capture-stop verify flows clean

setup:            ## apktool + .venv/mitmproxy + keystore + engine + input check
	./scripts/setup.sh

build:            ## -> apks/VBS-Mod.apk
	./scripts/build.sh

build-fresh:      ## full re-decode from apks/original/base.apk
	./scripts/build.sh --fresh

install:          ## install onto the connected device
	adb install -r -d apks/VBS-Mod.apk

capture:          ## start mitmproxy WireGuard server + client config
	./scripts/mitm.sh start

capture-stop:
	./scripts/mitm.sh stop

verify:           ## launch the app and print decrypted requests
	./scripts/verify-mitm.sh

flows:            ## dump captured flows
	./.venv/bin/python scripts/flows.py --body

check-storage:    ## does the e-Devlet session survive a restart?
	./scripts/check-storage.sh

clean:            ## remove derived build trees (keeps apks/, dump/, engine)
	rm -rf build/out build/apktool build/split build/mitm
