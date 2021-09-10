#!/bin/bash

# 本程序官方发布地址https://github.com/ericwang2006/docker_ttnode
# 使用本程序前请先阅读说明文件https://github.com/ericwang2006/docker_ttnode/blob/master/AutoNode.md
# 此说明文件是本程序不可分割的一部分，您一旦开始使用视为已同意里面的使用条款

if [ -f "/.dockerenv" ]; then
	CONFIG_DIR="/config"
else
	CONFIG_DIR=$(dirname $(readlink -f $0))
fi

# https协议接口目前不可用,暂时用http协议
PROTOCOL="http"

function sleep300() {
	seconds_left=$((RANDOM % 300 + 1))
	echo "错峰延时执行$seconds_left秒，请耐心等待"
	while [ $seconds_left -gt 0 ]; do
		echo -n $seconds_left
		sleep 1
		seconds_left=$(($seconds_left - 1))
		echo -ne "\r     \r"
	done
}

function move_config() {
	OLD_DIR=$(dirname $0)
	if [[ $OLD_DIR != $CONFIG_DIR ]]; then
		mkdir -p "$CONFIG_DIR"
		f="config.json"
		if [ -f "$OLD_DIR/$f" ]; then
			if [ ! -f "$CONFIG_DIR/$f" ]; then
				cp "$OLD_DIR/$f" "$CONFIG_DIR/$f"
			fi
			mv "$OLD_DIR/$f" "$OLD_DIR/$f.bak"
			echo "迁移$OLD_DIR/$f到$CONFIG_DIR/$f"
		fi
	fi
}

function create_config_file() {
	if [ ! -f "$1" ]; then
		echo '{}' >$1
	fi
}

function login() {
	read -p "请输入手机号码：" tel
	if [ ${#tel} = 11 ]; then
		codeText=$(curl -s -k -X POST $PROTOCOL://tiantang.mogencloud.com/web/api/login/code?phone=$tel | jq '.errCode')
		if [ $codeText = 0 ]; then
			read -p "验证码发送成功，请输入：" code
			if [ ${#code} = 6 ]; then
				tokenText=$(curl -s -k -X POST $PROTOCOL://tiantang.mogencloud.com/web/api/login?phone=$tel\&authCode=$code | jq -r '.data.token')
				if [ $tokenText = null ]; then
					echo "登录失败，请重试！"
				else
					cfile="$CONFIG_DIR/config.json"
					tfile="$CONFIG_DIR/.config.json"
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
Version: V0.03
Usage  : $0 [Options]
Options:
        login               登录
        config_notify       通知设置
        report              每日收取星愿
        auto_turbo          自动使用加成卡
        withdraw            提现

"
}

escape() {
	# https://core.telegram.org/bots/api#markdown-style
	# To escape characters '_', '*', '`', '[' outside of an entity, prepend the characters '\' before them.
	echo "$1" | sed 's/\_/\\\_/g' | sed 's/\*/\\\*/g' | sed 's/`/\\\`/g' | sed 's/\[/\\\[/g'
}

withdraw() {
	cfile="$CONFIG_DIR/config.json"
	mfile="$CONFIG_DIR/msg.txt"
	if [ ! -f "$cfile" ]; then
		exit 1
	fi
	token=$(jq -r '.token' $cfile)
	if [ "$token" = "null" ]; then
		exit 2
	fi

	auto_withdraw=$(jq -r '.auto_withdraw' $cfile)
	# 为0 或者为 null 启用自动提现
	if [ "$auto_withdraw" = "null" ] || [ "$auto_withdraw" = "0" ]; then
		sleep300
		text=$(curl -k -X POST -H "authorization:$token" -s $PROTOCOL://tiantang.mogencloud.com/web/api/account/message/loading)
		errCode=$(echo $text | jq '.errCode')
		if [[ -z $errCode ]] || [[ $errCode -ne 0 ]]; then
			msg="token可能失效，请尝试重新登录。"
			notify "$msg"
			echo "$msg"
			exit 3
		fi
		score=$(echo $text | jq -r '.data.score')
		score=$(($score - $score % 100))

		if [[ $score -lt 1000 ]]; then
			d=$(date "+%Y-%m-%d %H:%M:%S")
			m=$(echo -e "$d\n甜糖提现失败：星愿不足1000")
		else
			isEContract=$(echo $text | jq .data.isEContract)
			if [ $isEContract = "true" ]; then
				#已签电子合同
				bankCardCount=$(echo $text | jq '.data.bankCardList|length')
				if [[ $bankCardCount -eq 0 ]]; then
					d=$(date "+%Y-%m-%d %H:%M:%S")
					m=$(echo -e "$d\n银行卡提现失败，原因是未绑定银行卡")
				else
					real_name=$(echo $text | jq -r '.data.bankCardList[0].name')
					card_id=$(echo $text | jq -r '.data.bankCardList[0].bankCardNum')
					bank_name=$(echo $text | jq -r '.data.bankCardList[0].bankName')
					sub_bank_name=$(echo $text | jq -r '.data.bankCardList[0].subBankName')
					type="bank_card"
					text=$(
						curl -s -k -X POST \
							-H "authorization:$token" \
							-H "Content-Type:application/x-www-form-urlencoded" \
							--data-urlencode "score=$score" \
							--data-urlencode "real_name=$real_name" \
							--data-urlencode "card_id=$card_id" \
							--data-urlencode "bank_name=$bank_name" \
							--data-urlencode "sub_bank_name=$sub_bank_name" \
							--data-urlencode "type=$type" \
							"$PROTOCOL://tiantang.mogencloud.com/api/v2/withdraw_logs"
					)
					errCode=$(echo $text | jq '.errCode')
					d=$(date "+%Y-%m-%d %H:%M:%S")
					if [[ $errCode -eq 0 ]]; then
						m=$(echo -e "$d\n甜糖提现成功：扣除$score,银行卡$card_id")
					else
						m=$(echo -e "$d\n甜糖提现失败：$(echo $text | jq -r '.msg')")
					fi
				fi
			else
				#未签电子合同,使用支付宝提现
				zfbCount=$(echo $text | jq '.data.zfbList|length')
				if [[ $zfbCount -eq 0 ]]; then
					d=$(date "+%Y-%m-%d %H:%M:%S")
					m=$(echo -e "$d\n支付宝提现失败，原因是未绑定支付宝")
				else
					real_name=$(echo $text | jq -r '.data.zfbList[0].name')
					card_id=$(echo $text | jq -r '.data.zfbList[0].account')
					bank_name="支付宝"
					sub_bank_name=""
					type="zfb"
					if [[ $score -gt 10000 ]]; then
						score=9900
					fi
					text=$(
						curl -s -k -X POST \
							-H "authorization:$token" \
							-H "Content-Type:application/x-www-form-urlencoded" \
							--data-urlencode "score=$score" \
							--data-urlencode "real_name=$real_name" \
							--data-urlencode "card_id=$card_id" \
							--data-urlencode "bank_name=$bank_name" \
							--data-urlencode "sub_bank_name=$sub_bank_name" \
							--data-urlencode "type=$type" \
							"$PROTOCOL://tiantang.mogencloud.com/api/v1/withdraw_logs"
					)
					errCode=$(echo $text | jq '.errCode')
					d=$(date "+%Y-%m-%d %H:%M:%S")
					if [[ $errCode -eq 0 ]]; then
						m=$(echo -e "$d\n甜糖提现成功：扣除$score,支付宝$card_id")
					else
						m=$(echo -e "$d\n甜糖提现失败：$(echo $text | jq -r '.msg')")
					fi
				fi
			fi
		fi
		notify "$(escape "$m")"
		echo "$m"
	fi
}

notify() {
	cfile="$CONFIG_DIR/config.json"
	# Server酱通知
	sckey=$(jq -r '.sckey' $cfile)
	if [ -n "$sckey" ]; then
		desp=$(echo "$1" | sed ":a;N;s/\n/#LF/g;ta" | sed "s/#LF/\n\n/g" | sed "s/\*/\*\*/g")
		if [[ $sckey == SCT* ]]; then #$sckey以SCT开头(Turbo版)
			curl -s -k -X POST -d "title=甜糖日报&desp=$desp" https://sctapi.ftqq.com/$sckey.send >/dev/null 2>&1
		else
			curl -s -k -X POST -d "text=甜糖日报&desp=$desp" https://sc.ftqq.com/$sckey.send >/dev/null 2>&1
		fi
	fi

	# tg通知
	tg_api_key=$(jq -r '.tg_api_key' $cfile)
	if [ -n "$tg_api_key" ]; then
		desp="$1"
		tg_chat_id=$(jq -r '.tg_chat_id' $cfile)
		tg_proxy=$(jq -r '.tg_proxy' $cfile)
		data=$(jq -n -c -M --arg v1 "$tg_chat_id" --arg v2 "$desp" '{"disable_web_page_preview":false, "parse_mode":"markdown", "chat_id":$v1, "text":$v2}')

		if [ -n "$tg_proxy" ]; then
			curl -s -k -X "POST" -H 'Content-Type: application/json' -x $tg_proxy -d "$data" "https://api.telegram.org/bot$tg_api_key/sendMessage" >/dev/null 2>&1
		else
			curl -s -k -X "POST" -H 'Content-Type: application/json' -d "$data" "https://api.telegram.org/bot$tg_api_key/sendMessage" >/dev/null 2>&1
		fi
	fi
}

config_notify() {
	cfile="$CONFIG_DIR/config.json"
	tfile="$CONFIG_DIR/.config.json"
	create_config_file $cfile

	read -p "请输入Server酱的key(支持Turbo版key,会自动判断),不使用Server酱通知直接按回车：" sckey
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

	read -p "请输入自动使用加成卡方案 1-使用速率最高的加成卡 2-只使用\"星愿加成卡\" ,不自动使用加成卡直接按回车：" auto_turbo
	if [ -z "$auto_turbo" ]; then
		jq 'del(.auto_turbo)' $cfile >$tfile && mv $tfile $cfile
	else
		if [ $auto_turbo == "1" -o $auto_turbo == "2" ]; then
			jq ".+{\"auto_turbo\":$auto_turbo}" $cfile >$tfile && mv $tfile $cfile
		else
			jq 'del(.auto_turbo)' $cfile >$tfile && mv $tfile $cfile
		fi
	fi
}

report() {
	total=0
	cfile="$CONFIG_DIR/config.json"
	mfile="$CONFIG_DIR/msg.txt"
	if [ ! -f "$cfile" ]; then
		exit 1
	fi
	token=$(jq -r '.token' $cfile)
	if [ "$token" = "null" ]; then
		exit 2
	fi
	sleep300
	text=$(curl -k -X POST -H "authorization:$token" -s $PROTOCOL://tiantang.mogencloud.com/web/api/account/message/loading)
	errCode=$(echo $text | jq '.errCode')
	if [[ -z $errCode ]] || [[ $errCode -ne 0 ]]; then
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
		curl -k -X POST -H "authorization:$token" -s "$PROTOCOL://tiantang.mogencloud.com/api/v1/promote/score_logs?score=$inactivedPromoteScore" >/dev/null 2>&1
	fi
	#签到
	sign_result=$(curl -s -k -X POST -H "authorization:$token" -s $PROTOCOL://tiantang.mogencloud.com/web/api/account/sign_in)
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
	text=$(curl -s -k -X GET -H "authorization:$token" -s "$PROTOCOL://tiantang.mogencloud.com/api/v1/devices?page=1&type=2&per_page=64")
	devList=$(echo $text | jq '.data.data')
	max_device_index=$(echo $text | jq '.data.data|length'-1)
	for index in $(seq 0 $max_device_index); do
		devId=$(echo $devList | jq -r ".[$index].id")
		alias=$(echo $devList | jq -r ".[$index].alias")
		devSore=$(echo $devList | jq ".[$index].inactived_score")
		if [[ $devSore -gt 0 ]]; then
			curl -s -k -X POST -H "authorization:$token" -s "$PROTOCOL://tiantang.mogencloud.com/api/v1/score_logs?device_id=$devId&score=$devSore" >/dev/null 2>&1
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
	cat $mfile | sed 's/\*//g'
}

auto_turbo() {
	cfile="$CONFIG_DIR/config.json"
	mfile="$CONFIG_DIR/msg.txt"
	if [ ! -f "$cfile" ]; then
		exit 1
	fi
	token=$(jq -r '.token' $cfile)
	if [ "$token" = "null" ]; then
		exit 2
	fi
	auto_turbo=$(jq -r '.auto_turbo' $cfile)
	# 为0 或者为 null 都不执行
	if [ "$auto_turbo" = "null" ] || [ "$auto_turbo" = "0" ]; then
		exit 0
	fi

	sleep300
	# 获取加成卡信息
	text=$(curl -k -X GET -H "authorization:$token" -s $PROTOCOL://tiantang.mogencloud.com/api/v1/user_props)
	errCode=$(echo $text | jq '.errCode')
	if [[ -z $errCode ]] || [[ $errCode -ne 0 ]]; then
		msg="token可能失效，请尝试重新登录。"
		notify "$msg"
		echo "$msg"
		exit 3
	fi
	echo "*$(date "+%Y-%m-%d %H:%M:%S")*" >$mfile
	propsList=$(echo $text | jq '.data')
	max_props_index=$(echo $text | jq '.data|length'-1)
	current_id="unknown"
	current_name="未使用卡"
	current_rate="0"
	for index in $(seq 0 $max_props_index); do
		prop_id=$(echo $propsList | jq -r ".[$index].prop_id")
		prop_name=$(echo $propsList | jq -r ".[$index].name")
		prop_count=$(echo $propsList | jq -r ".[$index].count")
		prop_rate=$(echo $propsList | jq -r ".[$index].config.earnings_rate")
		echo "*发现 $prop_name ： $prop_count 张*" >>$mfile
		if [ $auto_turbo == "1" ]; then
			# 方案1 使用 速率最高的 加速卡 此方案需要 apt install bc
			if [ "$prop_count" -gt "0" ] && [ $(echo "$prop_rate > $current_rate" | bc) -eq 1 ]; then
				current_id=$(echo $prop_id)
				current_name=$(echo $prop_name)
				current_rate=$(echo $prop_rate)
			fi
		else
			# 方案2 默认使用 只使用 ‘星愿加成卡’ 不知道那种方案更适合
			if [ "$prop_count" -gt "0" ] && [ $prop_name == "星愿加成卡" ]; then
				current_id=$(echo $prop_id)
				current_name=$(echo $prop_name)
			fi
		fi
	done
	# 使用 遍历出来的最高加速卡
	if [ "$current_id" != "unknown" ]; then
		curl -s -k -X PUT -H "authorization:$token" -s "$PROTOCOL://tiantang.mogencloud.com/api/v1/user_props/$current_id/actived" >/dev/null 2>&1
		echo "*已自动使用：$current_name*" >>$mfile
	else
		echo "*错误 ：$current_name*" >>$mfile
	fi
	notify "$(cat $mfile)"
	cat $mfile | sed 's/\*//g'
}

update() {
	sleep300
	if [ `grep -c "https://tiantang" /usr/node/htdocs/get_info.cgi` -ne '0' ];then
		sed -i "s/https:\/\/tiantang/http:\/\/tiantang/g" /usr/node/htdocs/get_info.cgi
	fi
	tmpfile="/tmp/.ttnode_task.sh"
	echo "开始升级..." && curl -s -k -o "$tmpfile" https://cdn.jsdelivr.net/gh/ericwang2006/docker_ttnode/build_dir/ttnode_task.sh && cp "$0" "$0.bak" && mv "$tmpfile" $0 && chmod +x $0 && echo "升级成功"
}

main() {
	action="$1"
	[ -z "${action}" ] && show_help && exit 0
	case "${action}" in
	login)
		move_config
		login
		;;
	config_notify)
		move_config
		config_notify
		;;
	report)
		move_config
		report
		;;
	auto_turbo)
		move_config
		auto_turbo
		;;
	withdraw)
		move_config
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
