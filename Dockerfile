FROM mariadb:10.1.16
MAINTAINER Bjorge Staijen <bjorge.staijen@mariadb.com>

ENV CONFD_VERSION=0.10.0

RUN apt-get update && apt-get install -y galera-arbitrator-3 --no-install-recommends ca-certificates wget curl && \
    rm -rf /var/lib/apt/lists/* && \
    wget https://github.com/bstaijen/mariadb-galera-discovery-tool/releases/download/0.4/discovery-tool-0.4-linux-amd64 && \
    mv discovery-tool-0.4-linux-amd64 /docker-entrypoint-initdb.d/discovery-tool && \
    chmod +x /docker-entrypoint-initdb.d/discovery-tool

# install github.com/kelseyhightower/confd
RUN \
  curl -sSL https://github.com/kelseyhightower/confd/releases/download/v${CONFD_VERSION}/confd-${CONFD_VERSION}-linux-amd64 \
    -o /usr/local/bin/confd \
    && chmod +x /usr/local/bin/confd

COPY galera-entrypoint.sh /

ADD . /app

RUN chown mysql:mysql /etc/mysql/my.cnf

EXPOSE 3306 4444 4567 4567/udp 4568

ENTRYPOINT ["/galera-entrypoint.sh"]
CMD ["mysqld"]