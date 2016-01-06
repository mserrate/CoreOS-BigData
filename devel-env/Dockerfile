FROM mserrate/storm:0.10.0
# based on endocode
MAINTAINER mserrate

ENV KAFKA_VERSION="0.8.2.2" SCALA_VERSION="2.10"

RUN wget -q -O - https://debian.datastax.com/debian/repo_key | apt-key add -
RUN echo "deb http://debian.datastax.com/community stable main" | tee -a /etc/apt/sources.list.d/cassandra.sources.list
RUN apt-get update && apt-get install cassandra=2.2.4 dsc22=2.2.4-1 maven openjdk-7-jdk leiningen git devscripts python-stdeb python-all-dev build-essential python-dev libev4 libev-dev python-blist python-twisted python-yaml thrift-compiler scala vim screen tcpdump telnet zookeeper thrift-compiler -y

RUN wget -q http://wwwftp.ciril.fr/pub/apache/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz -O /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz
RUN tar xfz /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz -C /opt

ENV KAFKA_HOME /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}

WORKDIR /root

# cleanup image
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD start-shell.sh /usr/bin/start-shell.sh

RUN wget -q -O - https://github.com/coreos/fleet/releases/download/v0.10.2/fleet-v0.10.2-linux-amd64.tar.gz | tar --strip-components=1 -xzf - -C /usr/local/bin
RUN wget -q -O - https://github.com/coreos/etcd/releases/download/v2.1.2/etcd-v2.1.2-linux-amd64.tar.gz | tar --strip-components=1 -xzf - -C /usr/local/bin
CMD /usr/bin/start-shell.sh
