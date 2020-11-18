#!/bin/bash
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
    sleep 60
done
