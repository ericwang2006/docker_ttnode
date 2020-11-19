#!/bin/bash
foundport=0
while true;do
    num=`ps fax | grep '/ttnode' | egrep -v 'grep|echo|rpm|moni|guard' | wc -l`;
    if [ $num -lt 1 ];then
        d=`date '+%F %T'`;
        echo "[$d] ttnode进程不存在,启动ttnode"
        /usr/node/ttnode -p /mnts
        /usr/node/qr.sh

        # sleep 20
        # num=`ps fax | grep '/ttnode' | egrep -v 'grep|echo|rpm|moni|guard' | wc -l`;
        # if [ $num -lt 1 ];then
            # d=`date '+%F %T'`;
            # echo "[$d] ttnode启动失败,再来一次"
            # /usr/node/ttnode -p /mnts
        # fi
    fi

    if [ $foundport -eq 0 ]; then
        netstat -tnlp|grep -v '127\|Proto\|Active'|awk '{print $4}'|sed 's/0.0.0.0://' > /usr/node/port.txt
        len=`sed -n '$=' /usr/node/port.txt`
        if [[ $len -gt 2 ]]; then
            echo "==========================================================================="
            echo "如果UPNP失效，请在路由器上对下面3个端口做转发"
            cat /usr/node/port.txt
            echo "==========================================================================="
            foundport=1
        fi
    fi
    
    if [ $foundport -eq 0 ]; then
        sleep 20
    else
        sleep 60
    fi
done
