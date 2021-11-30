#!/bin/bash
uid=$(/usr/node/ttnode -p /mnts | grep uid)
uid=${uid:6:32}
len=${#uid}
if [ $len -lt 32 ]; then
	echo "获取二维码失败"
else
	echo $uid >/usr/node/uid.txt
	echo "==========================================================================="
	echo "如果觉得还有点用，麻烦用一下我的邀请码631441，有加成卡15张，我也有推广收入"
	echo "视频教程:"
	echo "https://www.youtube.com/playlist?list=PLTes8sqjACw1MY4Pq_QgBLN-I4cEE-wcO"
	echo "https://www.bilibili.com/video/BV1G64y117Na"
	# echo -e "甜糖客户端如果不能扫描到您的设备，请在浏览器访问\nhttps://ericwang2006.github.io/docker_ttnode/qrgen.htm?str=$uid\n获取二维码并用甜糖客户端扫描添加(纯js实现,不会发生数据泄露)"
	# dev=$(find /sys/class/net -type l -not -lname '*virtual*' -printf '%f\n' | head -n 1)
	dev=$(route | grep defaul | awk '{print $8}' | head -n 1)
	lan_ip=$(ifconfig $dev | awk -F'[ ]+|:' '/inet /{print $3}')
	echo -e "请在浏览器访问【http://$lan_ip:1043】甜糖控制面板，在这里可以扫码添加客户端，也可进行通知设置"
	echo "如有任何担心，可将此【$uid】UID复制，选择您信任的工具生成二维码并用甜糖客户端扫描添加"
	# qrencode -t ANSI $uid
fi
