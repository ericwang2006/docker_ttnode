#!/bin/bash
url="https://github.com/ericwang2006/docker_ttnode/raw/master"
arch=$(uname -m)
curl -L -k -o /usr/node/ttnode $url/$arch/ttnode && chmod +x /usr/node/ttnode
curl -L -k -o /usr/node/yfapp.conf $url/$arch/yfapp.conf
if [[ $arch = "armv7l" ]]; then
	cd /lib
	ln -s ld-musl-armhf.so.1 ld-musl-arm.so.1
fi
