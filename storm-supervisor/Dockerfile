FROM mserrate/storm:0.10.0
MAINTAINER mserrate

# worker 1 port
EXPOSE 6700
# worker 2 port
EXPOSE 6701
# worker 3 port
EXPOSE 6702
# worker 4 port
EXPOSE 6703
# logviewer port
EXPOSE 8000

RUN /usr/bin/config-supervisord.sh supervisor
RUN /usr/bin/config-supervisord.sh logviewer

CMD /usr/bin/start-supervisor.sh
