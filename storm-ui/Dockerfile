FROM mserrate/storm:0.10.0
MAINTAINER mserrate

# web interface port
EXPOSE 8080

RUN /usr/bin/config-supervisord.sh ui
CMD /usr/bin/start-supervisor.sh
