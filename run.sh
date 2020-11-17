#!/bin/sh
docker run -itd \
  -v /mnt/data/ttnode:/mnts \
  --name ttnode \
  --net=macnet --ip=192.168.2.2 --dns=114.114.114.114 --mac-address C2:F2:9C:C5:B2:94 \
  --privileged=true \
  --restart=always \
  ericwang2006/ttnode