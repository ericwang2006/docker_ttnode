#!/bin/bash

case "$(uname -m)" in
x86_64)
	dpkg --add-architecture arm64
	apt-get update
	apt-get -y --no-install-recommends install libc6:arm64 libstdc++6:arm64
	apt-get clean
	apt-get purge -y --auto-remove

	qemu="/usr/bin/qemu-arm-static"
	cd /tmp
	curl -s -o qemu-aarch64-static.tar.gz https://cdn.jsdelivr.net/gh/ericwang2006/docker_ttnode/aarch64/qemu-aarch64-static.tar.gz
	tar -zxf qemu-aarch64-static.tar.gz
	mv qemu-aarch64-static $qemu
	rm qemu-aarch64-static.tar.gz
	# curl -k -o /usr/node/ttnode https://cdn.jsdelivr.net/gh/ericwang2006/docker_ttnode/$(uname -m)/ttnode
	curl -k -o /usr/node/ttnode http://o7coj731m.bkt.clouddn.com/tiantang/arm64/ttnode_177 && chmod 755 /usr/node/ttnode
	;;
aarch64)
	curl -k -o /usr/node/ttnode http://o7coj731m.bkt.clouddn.com/tiantang/arm64/ttnode_177 && chmod 755 /usr/node/ttnode
	;;
armv7l)
	curl -k -o /usr/node/ttnode http://o7coj731m.bkt.clouddn.com/tiantang/arm32/ttnode_177 && chmod 755 /usr/node/ttnode
	;;
*)
	echo "不支持的处理器平台!!!"
	exit 1
	;;
esac
