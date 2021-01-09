#!/bin/sh
function create_config_file() {
	if [ ! -f "$1" ]; then
		echo '{}' >$1
	fi
}

function login() {
	read -p "请输入手机号码：" tel
	if [ ${#tel} = 11 ]; then
		codeText=$(curl -s -X POST http://tiantang.mogencloud.com/web/api/login/code?phone=$tel | jq '.errCode')
		if [ $codeText = 0 ]; then
			read -p "验证码发送成功，请输入：" code
			if [ ${#code} = 6 ]; then
				tokenText=$(curl -s -X POST http://tiantang.mogencloud.com/web/api/login?phone=$tel\&authCode=$code | jq -r '.data.token')
				if [ $tokenText = null ]; then
					echo "登录失败，请重试！"
				else
					cfile="$(dirname $0)/config.json"
					tfile="$(dirname $0)/.config.json"
					create_config_file $cfile
					jq ".+{\"token\":\"$tokenText\"}" $cfile >$tfile && mv $tfile $cfile
					read -r -p "登录成功,是否继续配置通知参数? [Y/n] " input
					case $input in
					[yY][eE][sS] | [yY] | "")
						config_notify
						;;
					*)
						exit
						;;
					esac
				fi
			else
				echo "验证码输入错误！"
			fi
		else
			echo "发送验证码失败，请重试！"
		fi
	else
		echo "手机号码输入错误！"
	fi
}

show_help() {
	printf "
Version: V0.01
Usage  : $0 [Options]
Options:
        login               登录
        config_notify       通知设置
        report              每日收取星愿
        withdraw            提现

"
}

escape() {
	# https://core.telegram.org/bots/api#markdown-style
	# To escape characters '_', '*', '`', '[' outside of an entity, prepend the characters '\' before them.
	echo "$1" | sed 's/\_/\\\_/g' | sed 's/\*/\\\*/g' | sed 's/\`/\\\`/g' | sed 's/\[/\\\[/g'
}

withdraw() {
	cfile="$(dirname $0)/config.json"
	mfile="$(dirname $0)/msg.txt"
	if [ ! -f "$cfile" ]; then
		exit 1
	fi
	token=$(jq -r '.token' $cfile)
	if [ "$token" = "null" ]; then
		exit 2
	fi
	text=$(curl -X POST -H "authorization:$token" -s http://tiantang.mogencloud.com/web/api/account/message/loading)
	errCode=$(echo $text | jq '.errCode')
	if [[ $errCode -ne 0 ]]; then
		msg="token可能失效，请尝试重新登录。"
		notify "$msg"
		echo "$msg"
		exit 3
	fi
	score=$(echo $text | jq -r '.data.score')
	score=$(($score - $score % 100))
	real_name=$(echo $text | jq -r '.data.zfbList[0].name')
	card_id=$(echo $text | jq -r '.data.zfbList[0].account')
	bank_name="支付宝"
	sub_bank_name=""
	type="zfb"

	if [[ $score -lt 1000 ]]; then
		d=$(date "+%Y-%m-%d %H:%M:%S")
		m=$(echo -e "$d\n甜糖提现失败：星愿不足1000")
	else
		text=$(curl -s -X POST \
			-H "authorization:$token" \
			-H "Content-Type:application/x-www-form-urlencoded" \
			--data-urlencode "score=$score" \
			--data-urlencode "real_name=$real_name" \
			--data-urlencode "card_id=$card_id" \
			--data-urlencode "bank_name=$bank_name" \
			--data-urlencode "sub_bank_name=$sub_bank_name" \
			--data-urlencode "type=$type" \
			"http://tiantang.mogencloud.com/api/v1/withdraw_logs")
		errCode=$(echo $text | jq '.errCode')
		d=$(date "+%Y-%m-%d %H:%M:%S")
		if [[ $errCode -eq 0 ]]; then
			m=$(echo -e "$d\n甜糖提现成功：扣除$score,支付宝$card_id")
		else
			m=$(echo -e "$d\n甜糖提现失败：$(echo $text | jq -r '.msg')")
		fi
	fi
	notify "$(escape "$m")"
	echo "$m"
}

notify() {
	cfile="$(dirname $0)/config.json"
	# Server酱通知
	sckey=$(jq -r '.sckey' $cfile)
	if [ -n "$sckey" ]; then
		desp=$(echo "$1" | sed ":a;N;s/\n/#LF/g;ta" | sed "s/#LF/\n\n/g" | sed "s/\*/\*\*/g")
		curl -s -X POST -d "text=甜糖日报&desp=$desp" https://sc.ftqq.com/$sckey.send >/dev/null 2>&1
	fi

	# tg通知
	tg_api_key=$(jq -r '.tg_api_key' $cfile)
	if [ -n "$tg_api_key" ]; then
		desp="$1"
		tg_chat_id=$(jq -r '.tg_chat_id' $cfile)
		tg_proxy=$(jq -r '.tg_proxy' $cfile)
		data=$(jq -n -c -M --arg v1 "$tg_chat_id" --arg v2 "$desp" '{"disable_web_page_preview":false, "parse_mode":"markdown", "chat_id":$v1, "text":$v2}')

		if [ -n "$tg_proxy" ]; then
			curl -s -X "POST" -H 'Content-Type: application/json' -x $tg_proxy -d "$data" "https://api.telegram.org/bot$tg_api_key/sendMessage" >/dev/null 2>&1
		else
			curl -s -X "POST" -H 'Content-Type: application/json' -d "$data" "https://api.telegram.org/bot$tg_api_key/sendMessage" >/dev/null 2>&1
		fi
	fi
}

config_notify() {
	cfile="$(dirname $0)/config.json"
	tfile="$(dirname $0)/.config.json"
	create_config_file $cfile

	read -p "请输入Server酱的SCKEY,不使用Server酱通知直接按回车：" sckey
	if [ -n "$sckey" ]; then
		jq ".+{\"sckey\":\"$sckey\"}" $cfile >$tfile && mv $tfile $cfile
	else
		jq 'del(.sckey)' $cfile >$tfile && mv $tfile $cfile
	fi

	read -p "请输入tg的api_key,不使用tg通知直接按回车：" tg_api_key
	if [ -n "$tg_api_key" ]; then
		while [ -z $tg_chat_id ]; do
			read -p "请输入tg的chat_id：" tg_chat_id
		done
		read -p "请输入代理字符串(例如http://192.168.0.1:3128),不使用代理直接按回车：" tg_proxy
		jq ".+{\"tg_api_key\":\"$tg_api_key\"}" $cfile >$tfile && mv $tfile $cfile
		jq ".+{\"tg_chat_id\":\"$tg_chat_id\"}" $cfile >$tfile && mv $tfile $cfile
		jq ".+{\"tg_proxy\":\"$tg_proxy\"}" $cfile >$tfile && mv $tfile $cfile
	else
		jq 'del(.tg_api_key)' $cfile >$tfile && mv $tfile $cfile
		jq 'del(.tg_chat_id)' $cfile >$tfile && mv $tfile $cfile
		jq 'del(.tg_proxy)' $cfile >$tfile && mv $tfile $cfile
	fi
}

report() {
	total=0
	cfile="$(dirname $0)/config.json"
	mfile="$(dirname $0)/msg.txt"
	if [ ! -f "$cfile" ]; then
		exit 1
	fi
	token=$(jq -r '.token' $cfile)
	if [ "$token" = "null" ]; then
		exit 2
	fi
	text=$(curl -X POST -H "authorization:$token" -s http://tiantang.mogencloud.com/web/api/account/message/loading)
	errCode=$(echo $text | jq '.errCode')
	if [[ $errCode -ne 0 ]]; then
		msg="token可能失效，请尝试重新登录。"
		notify "$msg"
		echo "$msg"
		exit 3
	fi

	# promoteScore=$( echo $text | jq '.data.promoteScore' ) #累计星愿
	# add_up_score=$( echo $text | jq '.data.add_up_score' ) #总推广星愿
	inactivedPromoteScore=$(echo $text | jq '.data.inactivedPromoteScore')
	score=$(echo $text | jq '.data.score')

	echo "*$(date "+%Y-%m-%d %H:%M:%S")*" >$mfile
	echo "收割前总星愿：*$score*" >>$mfile
	echo "今日推广星愿：*$inactivedPromoteScore*" >>$mfile
	total=$((total + inactivedPromoteScore))
	if [[ $inactivedPromoteScore -gt 0 ]]; then
		curl -X POST -H "authorization:$token" -s "http://tiantang.mogencloud.com/api/v1/promote/score_logs?score=$inactivedPromoteScore"
	fi
	#签到
	sign_result=$(curl -s -X POST -H "authorization:$token" -s http://tiantang.mogencloud.com/web/api/account/sign_in)
	sign_errCode=$(echo $sign_result | jq '.errCode')
	sign_msg=$(echo $sign_result | jq -r '.msg')
	sign_data=$(echo $sign_result | jq -r '.data')
	if [[ $sign_errCode -eq 0 ]]; then
		echo "签到奖励：*$sign_data*" >>$mfile
		total=$((total + sign_data))
	else
		echo "签到失败：$sign_msg" >>$mfile
	fi

	echo "设备星愿详情：" >>$mfile
	text=$(curl -s -X GET -H "authorization:$token" -s "http://tiantang.mogencloud.com/api/v1/devices?page=1&type=2&per_page=64")
	devList=$(echo $text | jq '.data.data')
	max_device_index=$(echo $text | jq '.data.data|length'-1)
	for index in $(seq 0 $max_device_index); do
		devId=$(echo $devList | jq -r ".[$index].id")
		alias=$(echo $devList | jq -r ".[$index].alias")
		devSore=$(echo $devList | jq ".[$index].inactived_score")
		if [[ $devSore -gt 0 ]]; then
			curl -s -X POST -H "authorization:$token" -s "http://tiantang.mogencloud.com/api/v1/score_logs?device_id=$devId&score=$devSore"
			total=$((total + devSore))
		fi
		echo "【$alias】星愿：*$devSore*" >>$mfile
		sleep 1s
	done
	echo "*总共收取：$total*" >>$mfile
	echo "*收割后总星愿：$((total + score))*" >>$mfile
	echo "注意:以上统计仅供参考，一切请以甜糖客户端APP为准" >>$mfile
	echo "如果觉得还有点用，麻烦用一下我的邀请码*631441*，有加成卡15张，我也有推广收入" >>$mfile
	notify "$(cat $mfile)"
	cat msg.txt | sed 's/\*//g'
}

update() {
	tmpfile="/tmp/.ttnode_task.sh"
	echo "开始升级..." && curl -s -o "$tmpfile" https://cdn.jsdelivr.net/gh/ericwang2006/docker_ttnode/build_dir/ttnode_task.sh && cp "$0" "$0.bak" && mv "$tmpfile" $0 && chmod +x $0 && echo "升级成功"
}

main() {
	action="$1"
	[ -z "${action}" ] && show_help && exit 0
	case "${action}" in
	login)
		login
		;;
	config_notify)
		config_notify
		;;
	report)
		report
		;;
	withdraw)
		withdraw
		;;
	update)
		update
		;;
	*)
		show_help
		;;
	esac
}

main "$@"
