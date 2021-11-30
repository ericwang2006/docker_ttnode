#!/bin/bash
url="https://github.com/ericwang2006/docker_ttnode/raw/armbian"
arch=$(uname -m)
curl -L -k -o /usr/node/ttnode $url/$arch/ttnode && chmod +x /usr/node/ttnode
curl -L -k -o /usr/node/yfapp.conf $url/$arch/yfapp.conf
