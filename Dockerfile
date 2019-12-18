FROM centos:7
MAINTAINER DevOps "pawank.kamboj@gmail.com"

#- update base image and install require RPMs
RUN yum -y install iproute net-tools wget sudo bind-utils tcpdump && \
        yum install -y readline readline-devel openssl-devel pcre-devel make gcc ca-certificates zlib && \
        yum clean all

#- install lua

RUN wget -q -O lua-5.3.5.tar.gz https://www.lua.org/ftp/lua-5.3.5.tar.gz && \
    tar xf lua-5.3.5.tar.gz && \
    cd lua-5.3.5 && make INSTALL_TOP=/opt/lua-5.3.5 linux install && \
    rm -rf lua-5.3.5 lua-5.3.5.tar.gz

#- install haproxy
RUN wget -q -O haproxy-2.0.9.tar.gz https://www.haproxy.org/download/2.0/src/haproxy-2.0.9.tar.gz && \
    tar xf haproxy-2.0.9.tar.gz && \
    cd haproxy-2.0.9 && \
    make -j $(nproc) TARGET=linux-glibc USE_GETADDRINFO=1 USE_LUA=1 LUA_INC=/opt/lua-5.3.5/include LUA_LIB=/opt/lua-5.3.5/lib/ USE_OPENSSL=1 \
    USE_PCRE=1 USE_PCRE_JIT=1 USE_ZLIB=1 EXTRA_OBJS="contrib/prometheus-exporter/service-prometheus.o"  && \
    make install && \
    groupadd -g 188 haproxy && \
    useradd -s /sbin/nologin -u 188 -g 188 -d /var/lib/haproxy haproxy && \
    rm -rf haproxy-2.0.9.tar.gz haproxy-2.0.9

#- copy haproxy config file
COPY haproxy.cfg /etc/haproxy/haproxy.cfg

#- set current date/time
ARG BUILD_DATE
LABEL org.opencontainers.image.created=$BUILD_DATE 

#- WORKDIR
WORKDIR /etc/haproxy

#- entrypoint script
ENTRYPOINT ["/usr/local/sbin/haproxy"]

#- command
CMD  ["-f", "/etc/haproxy/haproxy.cfg", "-p", "/run/haproxy.pid", "-W", "-db"]

