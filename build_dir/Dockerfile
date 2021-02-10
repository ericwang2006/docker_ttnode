FROM --platform=$TARGETPLATFORM debian:stable-slim AS builder

RUN sed -i 's/security.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list && \
    sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list && \
    apt-get update && \
	apt-get install build-essential git ca-certificates wget -y --no-install-recommends
	
# http://www.acme.com/software/thttpd/
RUN wget http://www.acme.com/software/thttpd/thttpd-2.29.tar.gz && \
    tar -zxvf ./thttpd-2.29.tar.gz && \
    cd thttpd-2.29 && \
    ./configure && \
    make

FROM --platform=$TARGETPLATFORM debian:stable-slim

LABEL maintainer="eric <ericwang2006@gmail.com>"

ENV TZ=Asia/Shanghai
ENV LANG C.UTF-8

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
    apt-get update && apt-get install cron procps net-tools iputils-ping ca-certificates curl jq nano bc -y --no-install-recommends && \
    echo "alias ls='ls --color=auto'" >> ~/.bashrc && \
	ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
	echo 'Asia/Shanghai' >/etc/timezone && \
    apt-get clean && \
    apt-get purge -y --auto-remove

COPY ttnode_task.sh start.sh qr.sh port.sh init_arch.sh /usr/node/

COPY --from=builder /thttpd-2.29/thttpd /usr/node/
COPY htdocs /usr/node/htdocs/

RUN /usr/node/init_arch.sh && rm /usr/node/init_arch.sh

WORKDIR /usr/node

VOLUME ["/config"]

CMD ["/usr/node/start.sh"]
