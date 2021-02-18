#!/bin/bash
function create_config_file() {
	if [ ! -f "$1" ]; then
		echo '{}' >$1
	fi
}

echo "Content-Type: application/json"
echo
eval $(./proccgi.sh $*)
case $FORM_m in
1)
	if [ -f "/usr/node/uid.txt" ]; then
		uid=$(cat /usr/node/uid.txt)
	else
		uid=""
	fi

	if [ -f "/usr/node/iptables.txt" ]; then
		iptables=$(cat /usr/node/iptables.txt)
	else
		iptables=""
	fi

	if [ -f "/usr/node/port.txt" ]; then
		port=$(cat /usr/node/port.txt)
	else
		port=""
	fi

	data=$(jq -n -c -M --arg v1 "$uid" --arg v2 "$port" --arg v3 "$iptables" '{"uid":$v1, "port":$v2, "iptables":$v3}')
	echo $data
	;;
2)
	CONFIG_FILE="/config/config.json"
	create_config_file $CONFIG_FILE
	# jq 'del(.token)' $CONFIG_FILE
	cat $CONFIG_FILE
	;;
3)
	curl -s -X POST "https://tiantang.mogencloud.com/web/api/login/code?phone=$FORM_phone"
	;;
4)
	tokenText=$(curl -s -X POST https://tiantang.mogencloud.com/web/api/login?phone=$FORM_tel\&authCode=$FORM_code | jq -r '.data.token')
	if [ $tokenText = null ]; then
		echo '{"errCode": 1 , "msg":"登录失败，请重试！"}'
	else
		CONFIG_DIR="/config"
		cfile="$CONFIG_DIR/config.json"
		tfile="$CONFIG_DIR/.config.json"
		create_config_file $cfile
		jq ".+{\"token\":\"$tokenText\"}" $cfile >$tfile && mv $tfile $cfile
		echo '{"errCode": 0}'
	fi
	;;
*)
	echo ""
	;;
esac
