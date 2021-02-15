<img src="https://img.shields.io/docker/stars/ericwang2006/ttnode.svg"/><img src="https://img.shields.io/docker/pulls/ericwang2006/ttnode.svg"/><img src="https://img.shields.io/docker/image-size/ericwang2006/ttnode/latest"/>

<!--[![nodesource/node](http://dockeri.co/image/ericwang2006/ttnode)](https://hub.docker.com/r/ericwang2006/ttnode/)-->

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


# 已知问题

- 日志中会提示**cannot create /proc/sys/net/core/wmem_max: Directory nonexistent**，是因为在daocker中不能设置Linux内核参数，不影响使用
- ~~docker中ttnode第一次启动后大约20秒后有自动退出的概率，不用理会，脚本会再次启动ttnode~~(这是由于ttnode自动升级导致的)

```
[2020-11-18 10:25:12] ttnode进程不存在,启动ttnode,
/bin/sh: 1: cannot create /proc/sys/net/core/wmem_max: Directory nonexistent,
如果不能自动发现设备,请将此UID e1c8191de1e1e16a67e05ab3d7bc86ba 生成二维码并用甜糖客户端扫描添加,
[2020-11-18 10:25:34] ttnode启动失败,再来一次,
/bin/sh: 1: cannot create /proc/sys/net/core/wmem_max: Directory nonexistent,
```
- 在x86架构下，重新创建容器，即使是同样的IP和mac地址，也会导致ttnode的uid变化
	根据日志`utility.cpp(2511)-GetMacFromIfreq: ioctl error = 19!`推测，ttnode内部应该是使用ioctl函数来获取mac地址的，在qemu中不支持ioctl调用是个已知问题
	可以参考[这里](https://github.com/multiarch/qemu-user-static/issues/101)，这个问题可以用下面的方法证实
	```
	$ docker run --rm --privileged multiarch/qemu-user-static --reset -p yes -c yes
	$ docker run --privileged -t -i armv7/armhf-ubuntu /bin/bash
	$ apt-get update
	$ apt-get install uml-utilities
	$ tunctl
	Unsupported ioctl: cmd=0x400454ca
	TUNSETIFF: Function not implemented
	```
- ~~在x86架构下，UPnP功能无效，需要手动在路由器上做端口转发~~
	最新的方案改用qemu模拟arm32架构(原来是模拟arm64架构)，大大改善了x86下路由器UPnP不生效的问题，如果使用最新镜像UPnP还是有问题，请继续使用端口映射的方案

#### 如果觉得还有点用，麻烦用一下我的邀请码631441，有加成卡15张，我也有推广收入
