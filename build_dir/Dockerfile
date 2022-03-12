FROM --platform=$TARGETPLATFORM alpine:3.9 AS builder

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories && \
    apk add build-base

# https://sourceforge.net/projects/shttpd/files/shttpd/1.42/
RUN wget -O ./shttpd-1.42.tar.gz https://github.com/ericwang2006/shttpd/archive/refs/tags/v1.42.tar.gz && \
   tar -zxvf ./shttpd-1.42.tar.gz && \
   cd shttpd-1.42/src && \
   LIBS="-lpthread -ldl " make unix

FROM --platform=$TARGETPLATFORM alpine

LABEL maintainer="eric <ericwang2006@gmail.com>"

# ENV TZ=Asia/Shanghai
# ENV LANG C.UTF-8

# start.sh用脚本监控ttnode进程,不用cron
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories && \
    apk update && apk add tzdata bash libstdc++ openssl ca-certificates curl jq nano bc iptables ip6tables && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/*

COPY . /usr/node/
COPY --from=builder /shttpd-1.42/src/shttpd /usr/node/
RUN /usr/node/init_arch.sh && rm /usr/node/init_arch.sh && rm /usr/node/Dockerfile

WORKDIR /usr/node

EXPOSE 1043

VOLUME ["/config"]

CMD ["/usr/node/start.sh"]
