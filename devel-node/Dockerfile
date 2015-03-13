FROM endocode/storm:0.9.2
MAINTAINER Anton Khramov <anton@endocode.com>

RUN apt-get update && apt-get install maven openjdk-7-jdk leiningen git devscripts python-stdeb python-all-dev build-essential python-dev libev4 libev-dev python-blist python-twisted python-yaml thrift-compiler scala vim screen tcpdump telnet zookeeper thrift-compiler -y
ADD python-kafka-python_0.9.3-1_all.deb /tmp/python-kafka-python_0.9.3-1_all.deb
ADD python-cassandra-driver_2.1.4-1_amd64.deb /tmp/python-cassandra-driver_2.1.4-1_amd64.deb
ADD kafka_cassandra_topology /root/kafka_cassandra_topology

RUN dpkg -i /tmp/*.deb || apt-get install -fy
# python libs were created using:
# py2dsc -m 'name' pypi_archive.tar.gz
# debuild -i -us -uc -b

RUN wget -q http://artfiles.org/apache.org/kafka/0.8.2.0/kafka_2.10-0.8.2.0.tgz -O /tmp/kafka_2.10-0.8.2.0.tgz
RUN tar xfz /tmp/kafka_2.10-0.8.2.0.tgz -C /opt

ENV KAFKA_HOME /opt/kafka_2.10-0.8.2.0

WORKDIR /root

RUN pip install pyleus

# cleanup image
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD start-shell.sh /usr/bin/start-shell.sh
CMD /usr/bin/start-shell.sh
