FROM ubuntu:trusty
MAINTAINER Anton Khramov <anton@endocode.com>

RUN apt-get update && apt-get dist-upgrade -y
RUN apt-get install -y zookeeper

# cleanup image
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD ./configuration.xsl /etc/zookeeper/conf/
ADD ./environment /etc/zookeeper/conf/
ADD ./log4j.properties /etc/zookeeper/conf/
ADD ./zoo.cfg /etc/zookeeper/conf/
ADD ./start.sh /

VOLUME ["/var/lib/zookeeper"]

# Zookeeper client port
EXPOSE 2181
# Zookeeper peer port
EXPOSE 2888
# Zookeeper leader (election) port
EXPOSE 3888

CMD ["/start.sh"]
