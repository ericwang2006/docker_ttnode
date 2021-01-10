# 自动收取星愿Shell脚本配置说明

1. 运行环境 **curl ca-certificates jq**
	- Debian/Ubuntu可以参考以下代码
	`sudo apt-get update && sudo apt-get install curl ca-certificates jq -y --no-install-recommends`
	- Centos/RedHat
	`sudo yum install curl ca-certificates jq -y`
	- 其他Linux系统请自行查找对应发行版的安装方法，也可以从[这里](https://github.com/stedolan/jq/releases)直接下载对应的二进制文件，并复制到/usr/bin目录
	- docker镜像ericwang2006/ttnode自带运行环境，只需更新到最新版本镜像
2. 设置定时任务
	- docker版需要进入容器`docker exec -it ttnode /bin/bash` ，修改/usr/node/crontab_list.sh文件，以下内容供参考，修改后需重启容器。
	```
	#自动更新
	0 0 * * *  /usr/node/ttnode_task.sh update
	#每日自动收取星愿
	8 4 * * *  /usr/node/ttnode_task.sh report
	#每周三自动提现
	15 4 * * 3 /usr/node/ttnode_task.sh withdraw
	```
	- Linux版本运行`crontab -e`，参考以上内容，自行编辑自动运行任务
3. 配置
	- docker版直接进入容器
		```
		docker exec -it ttnode /bin/bash
		```
	- Linux版下载Shell脚本
		```
		mkdir -p /usr/node
		cd /usr/node
		wget https://cdn.jsdelivr.net/gh/ericwang2006/docker_ttnode/build_dir/ttnode_task.sh
		```
	- 以下操作docker版本和linxu版本相同
		- 执行`/usr/node/ttnode_task.sh login`，根据提示输入手机号码和验证码登录
		- 提示"登录成功,是否继续配置通知参数? [Y/n] "，可直接按回车继续配置通知参数，如果徐需要通知可以直接选n。
		- 如果以后需要继续配置通知，可以重新执行`/usr/node/ttnode_task.sh config_notify`
		- 目前通知支持Server酱和tg，可以根据自己情况配置
		- 配置文件存放在/usr/node/config.json,也可以直接修改配置文件
			```
			{
			  "token": "token"
			  "sckey": "SCU5698Tbe90d0c286dba9fac97c25352211d3658f20e3e9c585",
			  "tg_api_key": "15692865:AAFnsuBwkD_8Ft-L5527HYF8uPs86ZtQjjs",
			  "tg_chat_id": "55225892",
			  "tg_proxy": "http://192.168.0.1:3128"
			}
			```
	- 下面就可以坐享其成了