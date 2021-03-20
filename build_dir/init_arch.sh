#!/bin/bash
case "$(uname -m)" in
x86_64)
	if [ $EMULATION_PLATFORM = "arm32" ]; then
		dpkg --add-architecture armhf
		apt-get update
		apt-get -y --no-install-recommends install libc6:armhf libstdc++6:armhf
		rm -rf /var/lib/apt/lists/*

		qemu="/usr/bin/qemu-arm-static"
		curl -L -o $qemu https://github.com/multiarch/qemu-user-static/releases/download/v5.2.0-2/qemu-arm-static && chmod +x $qemu
		# curl -L -k -o /usr/node/ttnode https://cdn.jsdelivr.net/gh/ericwang2006/docker_ttnode/$(uname -m)/ttnode
		# curl -L -k -o /usr/node/ttnode http://o7coj731m.bkt.clouddn.com/tiantang/arm64/$ttnode_filename
		curl -L -k -o /usr/node/ttnode https://github.com/ericwang2006/docker_ttnode/raw/master/armv7l/ttnode && chmod +x /usr/node/ttnode
	elif [ $EMULATION_PLATFORM = "arm64" ]; then
		dpkg --add-architecture arm64
		apt-get update
		apt-get -y --no-install-recommends install libc6:arm64 libstdc++6:arm64
		rm -rf /var/lib/apt/lists/*

		qemu="/usr/bin/qemu-aarch64-static"
		curl -L -o $qemu https://github.com/multiarch/qemu-user-static/releases/download/v5.2.0-2/qemu-aarch64-static && chmod +x $qemu
		curl -L -k -o /usr/node/ttnode https://github.com/ericwang2006/docker_ttnode/raw/master/aarch64/ttnode && chmod +x /usr/node/ttnode
	else
		echo "$EMULATION_PLATFORM unsupported param!"
		exit 1
	fi
	;;
aarch64)
	curl -L -k -o /usr/node/ttnode https://github.com/ericwang2006/docker_ttnode/raw/master/aarch64/ttnode && chmod +x /usr/node/ttnode
	;;
armv7l)
	curl -L -k -o /usr/node/ttnode https://github.com/ericwang2006/docker_ttnode/raw/master/armv7l/ttnode && chmod +x /usr/node/ttnode
	;;
*)
	echo "unsupported CPU architecture!"
	exit 1
	;;
esac
