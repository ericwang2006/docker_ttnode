#!/bin/bash
case "$(uname -m)" in
x86_64)
	qemu="/usr/bin/qemu-arm-static"
	;;
aarch64)
	qemu=""
	;;
armv7l)
	qemu=""
	;;
*)
	echo "不支持的处理器平台!!!"
	exit 1
	;;
esac
uid=$($qemu /usr/node/ttnode -p /mnts | grep uid)
uid=${uid:6:32}
len=${#uid}
if [ $len -lt 32 ]; then
	echo "获取二维码失败"
else
	echo "==========================================================================="
	echo "如果觉得还有点用，麻烦用一下我的邀请码631441，有加成卡15张，我也有推广收入"
	echo "请将此UID $uid 生成二维码并用甜糖客户端扫描添加"
	echo "==========================================================================="
	# qrencode -t ANSI $uid
fi
