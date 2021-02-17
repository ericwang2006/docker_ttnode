#!/bin/bash
if [ -f "/.dockerenv" ]; then
	CONFIG_DIR="/config"
else
	CONFIG_DIR=$(dirname $0)
fi

function move_config() {
	OLD_DIR=$(dirname $0)
	if [[ $OLD_DIR != $CONFIG_DIR ]]; then
		mkdir -p "$CONFIG_DIR"
		f="crontab_list.sh"
		if [ -f "$OLD_DIR/$f" ]; then
			if [ ! -f "$CONFIG_DIR/$f" ]; then
				cp "$OLD_DIR/$f" "$CONFIG_DIR/$f"
			fi
			mv "$OLD_DIR/$f" "$OLD_DIR/$f.bak"
			echo "迁移$OLD_DIR/$f到$CONFIG_DIR/$f"
		fi
	fi
}

maskdigits() {
	a=$(echo "$1" | awk -F "." '{print $1" "$2" "$3" "$4}')
	for num in $a; do
		while [ $num != 0 ]; do
			echo -n $(($num % 2)) >>/tmp/num
			num=$(($num / 2))
		done
	done
	echo $(grep -o "1" /tmp/num | wc -l)
	rm /tmp/num
}

if [[ $DISABLE_ATUO_TASK != "1" ]]; then
	service cron start
	move_config
	if [ ! -f "$CONFIG_DIR/crontab_list.sh" ]; then
		echo '0 0 * * *  /usr/node/ttnode_task.sh update' >$CONFIG_DIR/crontab_list.sh
		echo '8 20 * * * /usr/node/ttnode_task.sh auto_turbo' >>$CONFIG_DIR/crontab_list.sh
		echo '8 4 * * *  /usr/node/ttnode_task.sh report' >>$CONFIG_DIR/crontab_list.sh
		echo '15 4 * * 3 /usr/node/ttnode_task.sh withdraw' >>$CONFIG_DIR/crontab_list.sh
	fi
	crontab $CONFIG_DIR/crontab_list.sh
fi

/usr/node/thttpd -u root -p 1043 -d /usr/node/htdocs -c "**.cgi"

foundport=0
last=$(date +%s)
while true; do
	num=$(ps fax | grep '/ttnode' | egrep -v 'grep|echo|rpm|moni|guard' | wc -l)
	if [ $num -lt 1 ]; then
		d=$(date '+%F %T')
		echo "[$d] ttnode进程不存在,启动ttnode"
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
			echo "unsupported CPU architecture!"
			exit 1
			;;
		esac
		$qemu /usr/node/ttnode -p /mnts
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
		netstat -tunlp | grep "$(ps fax | grep '/ttnode' | egrep -v 'grep|echo|rpm|moni|guard' | awk '{print $1}')/" | grep -v '127.0.0.1\|17331' | awk '{sub(/0.0.0.0:/,""); print $1,$4}' | sort -k 2n -k 1 >/usr/node/port.txt
		len=$(sed -n '$=' /usr/node/port.txt)
		if [[ $len -gt 4 ]]; then
			echo "==========================================================================="
			echo $($qemu /usr/node/ttnode -h | head -n 1)
			d=$(date '+%F %T')
			echo "[$d] 如果UPNP失效，请在路由器上对下列端口做转发"
			cat /usr/node/port.txt | awk '{print $1,$2" "}'
			# awk '{x[$2]=x[$2]" "$1} END {for(i in x){print i x[i]}}' /usr/node/port.txt |awk '{print $2","$3,$1" "}'|sed 's/, / /'

			lan_dev="eth0"
			lan_ip=$(ifconfig $lan_dev | awk -F'[ ]+|:' '/inet /{print $3}')
			lan_mask=$(ifconfig $lan_dev | awk -F'[ ]+|:' '/inet /{print $5}')

			iptables_script="/usr/node/iptables.txt"
			rm -rf $iptables_script
			echo "# 如果路由器支持自定义防火墙,可以用以下命令代替端口转发设置" >>$iptables_script
			echo "# 此功能为实验性质,仅供高级用户使用" >>$iptables_script
			echo "# 以下shell命令仅供参考,需要根据路由器实际情况修改" >>$iptables_script
			echo "# 需要特别注意iptables防火墙规则的顺序非常关键,要合理安排执行顺序" >>$iptables_script
			echo -e "wan_dev='pppoe-wan' # 外网设备名\n" >>$iptables_script
			while read line; do
				protocol=$(echo $line | cut -d ' ' -f 1)
				port=$(echo $line | cut -d ' ' -f 2)
				echo "iptables -t nat -A PREROUTING -i \$wan_dev -p $protocol -m $protocol --dport $port -j DNAT --to-destination $lan_ip" >>$iptables_script
				echo -e "iptables -A FORWARD -d $lan_ip/32 -i \$wan_dev -p $protocol -m $protocol --dport $port -j ACCEPT\n" >>$iptables_script
			done </usr/node/port.txt

			len=$(maskdigits "$lan_mask")
			for i in $(seq 1 4); do
				a=$(echo $lan_ip | cut -d '.' -f $i)
				b=$(echo $lan_mask | cut -d '.' -f $i)
				d=$((a & b))

				if [ $i == 1 ]; then
					ip="$d"
				else
					ip=$ip".$d"
				fi
			done

			echo "iptables -t nat -A POSTROUTING -s $ip/$len -o \$wan_dev -j MASQUERADE" >>$iptables_script
			# cat $iptables_script
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
