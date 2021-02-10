#!/bin/bash
function create_config_file() {
	if [ ! -f "$1" ]; then
		echo '{}' >$1
	fi
}

echo "Content-Type: application/json"
echo
read -n $CONTENT_LENGTH data
CONFIG_FILE="/config/config.json"
create_config_file $CONFIG_FILE
token=$(jq -r '.token' $CONFIG_FILE)
echo $data | jq ".+{\"token\":\"$token\"}" >$CONFIG_FILE
echo '{"code":1, "msg": "保存成功！"}'
