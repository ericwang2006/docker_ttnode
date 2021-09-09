<img src="https://img.shields.io/docker/stars/ericwang2006/ttnode.svg"/><img src="https://img.shields.io/docker/pulls/ericwang2006/ttnode.svg"/><img src="https://img.shields.io/docker/image-size/ericwang2006/ttnode/latest"/>

<!--[![nodesource/node](http://dockeri.co/image/ericwang2006/ttnode)](https://hub.docker.com/r/ericwang2006/ttnode/)-->

# 视频教程

[youtube](https://www.youtube.com/playlist?list=PLTes8sqjACw1MY4Pq_QgBLN-I4cEE-wcO)
[哔哩哔哩](https://www.bilibili.com/video/BV1G64y117Na)

视频教程比较详细，欢迎大家点赞订阅支持一下
# 甜糖星愿镜像

- 基于debian:stable-slim构建
- 多架构支持,目前支持linux/amd64,linux/arm/v7,linux/arm64(其中amd64镜像内部使用QEMU模拟arm32)
- 去除了crontab任务，改用脚本监控ttndoe进程
- 提供网页控制面板查询UID,设置通知参数,只需访问 [http://容器IP:1043](http://容器IP:1043) ,网页的web服务使用[thttpd](http://www.acme.com/software/thttpd/),一个开源的轻量级的HTTP服务，只有100多K
- docker日志中直接查询UID
- docker日志中直接查看UPNP端口号
- 显示可替代端口转发的iptables命令(仅供高级用户使用)
- 自动收取星愿，基于Shell脚本，参见[自动收取星愿配置说明](AutoNode.md)（SHELL脚本参考了yjce1314大神的[代码](https://www.right.com.cn/forum/thread-4065542-1-1.html)）
- 自动使用加成卡功能，感谢[houfukude](https://github.com/houfukude)
- 完全开源

# 使用条款

- 本程序唯一发布地址https://github.com/ericwang2006/docker_ttnode
- 本程序仅用于测试和学习研究目的，不能保证其准确性，有效性，可用性和可靠性，	本作者对使用此程序带来的任何直接或间接的损失不承担任何责任
- 请勿将本程序的任何内容用于商业或非法目的，否则后果自行承担
- 作者保留随时更改或补充此使用条款的权利
- 一旦您开始使用本程序则视为您已接受此使用条款

# 食用方法

~~如果是arm架构（例如N1盒子），可直接使用，如果是x86平台，是不支持arm架构镜像，因此我们可以运行一个新的容器让其支持该特性。~~
已经实现多架构自适应，这步可以省略了。以后只要无脑`docker pull ericwang2006/ttnode`，就是这么方便。

```
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
```

## 方法一

打开混杂(这步可以省略,如果不能正常工作再打开)
```
ip link set eth0 promisc on
```
创建网络（自行替换网关以及网段）
```
docker network create -d macvlan --subnet=192.168.2.0/24 --gateway=192.168.2.88 -o parent=eth0 -o macvlan_mode=bridge macnet
```
运行容器（自行替换路径、IP以及可选替换dns）

```
docker run -itd \
  -v /mnt/data/ttnode:/mnts \
  --name ttnode \
  --hostname ttnode1 \
  --net=macnet --ip=192.168.2.2 --dns=114.114.114.114 --mac-address C2:F2:9C:C5:B2:94 \
  --privileged=true \
  --restart=always \
  ericwang2006/ttnode
```

## 方法二： 直接主网络运行（替换路径）
```
docker run -itd \
  -v /mnt/data/ttnode:/mnts \
  --name ttnode \
  --hostname ttnode1 \
  --net=host \
  --privileged=true \
  --restart=always \
  ericwang2006/ttnode
```

## 方法三: docker-compose

```
version: '2'

services:     
  ttnode:
    image: ericwang2006/ttnode
    container_name: ttnode
    hostname: ttnode1
    privileged: true
    restart: always
    mac_address: C2:F2:9C:C5:B2:94
    dns: 114.114.114.114
    networks: 
      macvlan:
        ipv4_address: 192.168.2.2
    volumes:
      - /mnt/data/ttnode:/mnts

networks:
  macvlan:
    driver: macvlan
    driver_opts:
      parent: eth0
    ipam:
      config:
        - subnet: 192.168.2.0/24
          gateway: 192.168.2.1
```

## 进入容器：

```
docker attach ttnode
or
docker exec -it ttnode /bin/bash 
```

## 查询UUID：

- 浏览器地址栏输入 `http：//容器IP:1043` (推荐)

- 容器内执行`./usr/node/ttnode -p /mnts`

- 容器外执行`docker logs ttnode`

## 环境变量

| 名称 | | 值 | 说明 | 值 | 说明 |
| :--- | --- | ---- | :--- | :--- | :--- |
| DISABLE_ATUO_TASK | 自动收星愿 | 1 | 禁用 | 非1 | 启用 |
| DISABLE_CONTROL_PANEL | 控制面板 | 1 | 禁用 | 非1 | 启用 |
| DISABLE_IPDBCF | 禁用ipdbcf进程 | 1 | 禁用ipdbcf进程 | 非1 | 不做任何处理 |

## FAQ
1. 怎么多开?

	使用方法一macvlan，友情提示：不是开得越多越好。

2. 主路由就是docker宿主机，为啥macvlan用不了？

	劝你们放过软路由吧，如果不服到恩山翻翻其他大神的贴子，有解决方案，但是路由器真的不是这么玩的。

3. 升级镜像如何保持uid不变？

	uid和mac地址，hostname高度相关，缓存目录也尽可能和原来保持一致，建议按照以下步骤操作，如果不幸uid还是变化了，那就随缘吧。
	- 记录原来的mac地址，hostname和缓存目录(hostname可以进入容器执行`hostname`命令获取)
	- 记录/config/config.json文件中的配置参数
	- 删除原来容器
	- 执行`docker pull ericwang2006/ttnode`获取最新镜像
	- 创建新的容器，mac地址，hostname和缓存目录要和原来一样
	- 更新了最新的镜像后,配置参数可以在控制面板中设置
	- 建议将/config目录映射到宿主机目录，下次再更新就不需要设置配置参数了
	- 即使uid发生了变化也不要紧，只要缓存目录不变，在手机客户端重新绑定新的uid就可以了

4. 我不用自动收割星愿，不用控制面板，可以不启用这两项功能吗？

	参看环境变量，如果你不懂啥叫环境变量，那就开着吧，基本不占用啥资源。

5. 为什么我是优质网络，但却一直没有流量？

	CDN流量去如黄鹤，来如晨风。玩玩就好，何必认真。
	
5. 内存占用过多，机器跑死

	执行下面命令限制一下容器内存，其中ttnodeA是容器名称，1024M是限制内存使用的上限，这个参数要根据自己机器配置调整。

```
docker update ttnodeA --memory-swap -1 -m 1024M
```

## 已知问题

- 日志中会提示**cannot create /proc/sys/net/core/wmem_max: Directory nonexistent**，是因为在docker中不能设置Linux内核参数，不影响使用
- ~~docker中ttnode第一次启动后大约20秒后有自动退出的概率，不用理会，脚本会再次启动ttnode~~(这是由于ttnode自动升级导致的)

```
[2020-11-18 10:25:12] ttnode进程不存在,启动ttnode,
/bin/sh: 1: cannot create /proc/sys/net/core/wmem_max: Directory nonexistent,
如果不能自动发现设备,请将此UID e1c8191de1e1e16a67e05ab3d7bc86ba 生成二维码并用甜糖客户端扫描添加,
[2020-11-18 10:25:34] ttnode启动失败,再来一次,
/bin/sh: 1: cannot create /proc/sys/net/core/wmem_max: Directory nonexistent,
```
- ~~在x86架构下，重新创建容器，即使是同样的IP和mac地址，也会导致ttnode的uid变化
	根据日志`utility.cpp(2511)-GetMacFromIfreq: ioctl error = 19!`推测，ttnode内部应该是使用ioctl函数来获取mac地址的，在qemu中不支持ioctl调用是个已知问题
	可以参考[这里](https://github.com/multiarch/qemu-user-static/issues/101)，这个问题可以用下面的方法证实~~
	```
	$ docker run --rm --privileged multiarch/qemu-user-static --reset -p yes -c yes
	$ docker run --privileged -t -i armv7/armhf-ubuntu /bin/bash
	$ apt-get update
	$ apt-get install uml-utilities
	$ tunctl
	Unsupported ioctl: cmd=0x400454ca
	TUNSETIFF: Function not implemented
	```
	这个问题目前有了最新**进展**，经过多次测试发现ttnode的uid和以下因素同时相关
	- **hostname**
	- **网卡的mac地址**

	由于此前创建docker容器时并未指定hostname，所以每次创建容器都是随机的hostname，导致出现了随机的uid，目前已经修改了相关示例代码，创建容器时指定了hostname

- ~~在x86架构下，UPnP功能无效，需要手动在路由器上做端口转发~~
	最新的方案改用qemu模拟arm32架构(原来是模拟arm64架构)，大大改善了x86下路由器UPnP不生效的问题，如果使用最新镜像UPnP还是有问题，请继续使用端口映射的方案

- ericwang2006/ttnode:x86_arm64这个镜像是x86架构下模拟arm64，据说这种模式效率高，我还没有很好的方法测试，UPnP是确定不支持，其它问题未知，不建议普通用户碰


**特别说明**

2021年3月30日测试，ipdbcf文件已经不会自动自动下载并运行了，新版本镜像默认将不再处理ipdbcf的行为，如果需要，请参看环境变量DISABLE_IPDBCF。

2021年3月19日官方升级了新版本（v194），使用之前的镜像会报错`sh: 1: /mnts/ipdbcf: Exec format error`，目前最新镜像已经做了针对性修改，但请知悉以下问题

1. 这个错误目前只涉及x86架构设备，arm架构(玩客云,N1,树莓派等)设备不受影响。

2. 请尝试更新**GMT+8 2021-03-21 10:00:00**后的最新镜像，注意不要使用国内的docker的镜像服务器(缓存更新缓慢，不能保证下载到的是最新版本)，如果无法拉取最新版本可以尝试我发布的离线镜像 https://wws.lanzous.com/b01zvsbwj 密码:h92y

3. 关于x86架构镜像长时间运行后CPU和内存占用过高的说明

   一句话，都是ipdbcf惹的祸。

   - ipdbcf的作用目前尚不明确，由ttnode进程动态下载到/mnts目录并启动，未监听任何端口

   - ttnode进程每分钟会检查一次ipdbcf进程是否存在，如果没有会尝试启动
   - 在arm架构下ipdbcf进程只会启动一个，不会占用过多资源
   - 在x86架构下，使用qemu模拟器运行，ttnode似乎不能判断ipdbcf进程是否存在，所以会不断启动新的ipdbcf进程（猜测）
   - 目前暂时用了点雕虫小技把ipdbcf禁用了，**副作用尚不明确**
   - x86架构下，使用qemu模拟器运行ttnode非官方建议做法，**不能保证完美运行**，且用且珍惜
   - 也希望官方尽早推出x86原生程序，x86设备众多，性能和稳定性都有一定优势

#### 如果觉得还有点用，麻烦用一下我的邀请码631441，有加成卡15张，我也有推广收入
