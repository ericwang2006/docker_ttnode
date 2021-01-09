#!/bin/bash
service cron start
crontab /usr/node/crontab_list.sh

foundport=0
last=$(date +%s)
while true; do
	num=$(ps fax | grep '/ttnode' | egrep -v 'grep|echo|rpm|moni|guard' | wc -l)
	if [ $num -lt 1 ]; then
		d=$(date '+%F %T')
		echo "[$d] ttnode进程不存在,启动ttnode"
		/usr/node/ttnode -p /mnts
		/usr/node/qr.sh

		# sleep 20
		# num=`ps fax | grep '/ttnode' | egrep -v 'grep|echo|rpm|moni|guard' | wc -l`;
		# if [ $num -lt 1 ];then
		# d=`date '+%F %T'`;
		# echo "[$d] ttnode启动失败,再来一次"
		# /usr/node/ttnode -p /mnts
		# fi
	fi

	if [ $foundport -eq 0 ]; then
		netstat -nlp | grep "$(ps fax | grep '/ttnode' | egrep -v 'grep|echo|rpm|moni|guard' | awk '{print $1}')/" | grep -v '127.0.0.1\|17331' | awk '{sub(/0.0.0.0:/,""); print $1,$4}' | sort -k 2n -k 1 >/usr/node/port.txt
		len=$(sed -n '$=' /usr/node/port.txt)
		if [[ $len -gt 4 ]]; then
			echo "==========================================================================="
			d=$(date '+%F %T')
			echo "[$d] 如果UPNP失效，请在路由器上对下列端口做转发"
			cat /usr/node/port.txt | awk '{print $1,$2" "}'
			echo "==========================================================================="
			foundport=1
			last=$(date +%s)
		else
			d=$(date '+%F %T')
			echo "[$d] 正在获取端口信息..."
		fi
	fi

	if [ $foundport -eq 0 ]; then
		sleep 20
	else
		sleep 60
		now=$(date +%s)
		diff=$(($now - $last))
		if [[ $diff -gt 43200 ]]; then #12 hour
			foundport=0
		fi
	fi
done
