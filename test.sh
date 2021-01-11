#!/bin/sh
docker run -itd \
  -v ~/test:/mnts \
  --name tt \
  --privileged=true \
  --restart=always \
  ericwang2006/ttnode:test
