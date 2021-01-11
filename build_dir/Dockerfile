FROM debian:stable-slim

LABEL maintainer="eric <ericwang2006@gmail.com>"

ENV TZ=Asia/Shanghai
ENV LANG C.UTF-8

COPY crash_monitor.sh ttnode_task.sh crontab_list.sh start.sh qr.sh port.sh init_arch.sh /usr/node/

# cron模式
# RUN sed -i 's/security.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list && \
    # sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list && \
    # apt-get update && apt-get install cron procps net-tools nano -y --no-install-recommends && \
    # crontab /usr/node/crontab_list.sh && \
    # echo "alias ls='ls --color=auto'" >> ~/.bashrc && \
    # apt-get clean && \
    # apt-get purge -y --auto-remove
# CMD ["cron", "-f"]

# 由于alpine的libc库有问题不能跑ttnode
# RUN echo "* * * * * /usr/node/crash_monitor.sh" > /etc/crontabs/root && \
# echo "http://mirrors.aliyun.com/alpine/edge/main" > /etc/apk/repositories && \
# echo "http://mirrors.aliyun.com/alpine/edge/community" >> /etc/apk/repositories && \
# apk update && apk add bash g++ libc6-compat

# start.sh用脚本监控ttnode进程,不用cron
RUN sed -i 's/security.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list && \
    sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list && \
    apt-get update && apt-get install cron procps net-tools iputils-ping ca-certificates curl jq nano -y --no-install-recommends && \
    echo "alias ls='ls --color=auto'" >> ~/.bashrc && \
	ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
	echo 'Asia/Shanghai' >/etc/timezone && \
    apt-get clean && \
    apt-get purge -y --auto-remove

RUN /usr/node/init_arch.sh

WORKDIR /usr/node

CMD ["/usr/node/start.sh"]
