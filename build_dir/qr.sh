#!/bin/bash
uid=$(/usr/node/ttnode -p /mnts|grep uid)
uid=${uid:6:32}
len=${#uid}
if [ $len -lt 32 ];then
    echo "获取二维码失败"
else
    echo "如果不能自动发现设备,请将此UID $uid 生成二维码并用甜糖客户端扫描添加"
    # qrencode -t ANSI $uid
fi