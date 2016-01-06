#!/bin/bash

if [[ -z "${ZK_ID}" || -z "${ZK_SERVERS}" || -z "${MEDIA_STORAGE}" ]]; then
	echo "Please set ZK_ID, ZK_SERVERS & MEDIA_STORAGE environment variables first."
	exit 1
fi

echo "${ZK_SERVERS}" | tr ' ' '\n' | tee -a /etc/zookeeper/conf/zoo.cfg
sed -i -e "s/^dataDir.*/dataDir=\\$MEDIA_STORAGE/g" /etc/zookeeper/conf/zoo.cfg
echo "${ZK_ID}" | tee $MEDIA_STORAGE/myid
/usr/share/zookeeper/bin/zkServer.sh start-foreground
