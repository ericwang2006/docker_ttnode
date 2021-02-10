#!/bin/sh
docker run -itd \
  -v ~/test:/mnts \
  --name tt \
  --net=host \
  --privileged=true \
  --restart=always \
  ericwang2006/ttnode:test
