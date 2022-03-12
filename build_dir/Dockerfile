FROM --platform=$TARGETPLATFORM debian:buster-slim AS builder

RUN sed -i 's/security.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list && \
    sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list && \
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    apt-get update && \
    apt-get install build-essential git ca-certificates wget -y --no-install-recommends

# http://www.acme.com/software/thttpd/
# RUN wget http://www.acme.com/software/thttpd/thttpd-2.29.tar.gz && \
#    tar -zxvf ./thttpd-2.29.tar.gz && \
#    cd thttpd-2.29 && \
#    ./configure && \
#    make

# https://sourceforge.net/projects/shttpd/files/shttpd/1.42/
RUN wget -O ./shttpd-1.42.tar.gz https://github.com/ericwang2006/shttpd/archive/refs/tags/v1.42.tar.gz && \
   tar -zxvf ./shttpd-1.42.tar.gz && \
   cd shttpd-1.42/src && \
   LIBS="-lpthread -ldl " make unix

FROM --platform=$TARGETPLATFORM debian:buster-20220125-slim

LABEL maintainer="eric <ericwang2006@gmail.com>"

ENV TZ=Asia/Shanghai
ENV LANG C.UTF-8

# start.sh用脚本监控ttnode进程,不用cron
RUN sed -i 's/security.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list && \
    sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list && \
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    apt-get update && apt-get install openssl cron procps net-tools iputils-ping ca-certificates curl jq nano bc psmisc traceroute iptables -y --no-install-recommends && \
    echo "alias ls='ls --color=auto'" >> ~/.bashrc && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo 'Asia/Shanghai' >/etc/timezone && \
    rm -rf /var/lib/apt/lists/*

COPY . /usr/node/
COPY --from=builder /shttpd-1.42/src/shttpd /usr/node/
RUN /usr/node/init_arch.sh && rm /usr/node/init_arch.sh && rm /usr/node/Dockerfile

WORKDIR /usr/node

EXPOSE 1043

VOLUME ["/config"]

CMD ["/usr/node/start.sh"]
