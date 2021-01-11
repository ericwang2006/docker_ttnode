#!/bin/bash

case "$(uname -m)" in
x86_64)
	dpkg --add-architecture arm64
	apt-get update
	apt-get -y --no-install-recommends install libc6:arm64 libstdc++6:arm64
	apt-get clean
	apt-get purge -y --auto-remove

	qemu="/usr/bin/qemu-arm-static"
	curl -L -s -o $qemu https://github.com/multiarch/qemu-user-static/releases/download/v5.2.0-2/qemu-aarch64-static && chmod +x $qemu
	# curl -k -o /usr/node/ttnode https://cdn.jsdelivr.net/gh/ericwang2006/docker_ttnode/$(uname -m)/ttnode
	curl -L -k -o /usr/node/ttnode http://o7coj731m.bkt.clouddn.com/tiantang/arm64/ttnode_177 && chmod +x /usr/node/ttnode
	;;
aarch64)
	curl -L -k -o /usr/node/ttnode http://o7coj731m.bkt.clouddn.com/tiantang/arm64/ttnode_177 && chmod +x /usr/node/ttnode
	;;
armv7l)
	curl -L -k -o /usr/node/ttnode http://o7coj731m.bkt.clouddn.com/tiantang/arm32/ttnode_177 && chmod +x /usr/node/ttnode
	;;
*)
	echo "不支持的处理器平台!!!"
	exit 1
	;;
esac
