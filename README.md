## 如果觉得还有点用，麻烦用一下我的邀请码631441，有加成卡15张，我也有推广收入。

### 迄今为止最小的甜糖星愿镜像

方法一：

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
方法二： 直接主网络运行（替换路径）
```
docker run -itd \
  -v /mnt/data/ttnode:/mnts \
  --name ttnode \
  --net=host \
  --privileged=true \
  --restart=always \
  ericwang2006/ttnode
```
进入容器：
```
docker attach ttnode
or
docker exec -it ttnode /bin/bash 
```
查询UUID：
```
./usr/node/ttnode -p /mnts
or
#容器外执行
docker logs ttnode
```
