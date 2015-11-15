FROM mserrate/storm:0.10.0
MAINTAINER mserrate

RUN /usr/bin/config-supervisord.sh nimbus
RUN /usr/bin/config-supervisord.sh drpc

# nimbus.thrift.port
EXPOSE 6627
# drpc.port
EXPOSE 3772
# drpc.invocations.port
EXPOSE 3773

CMD /usr/bin/start-supervisor.sh
