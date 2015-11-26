#!/bin/bash

export HOSTIP=$HOST_NAME
export ZKHOST=$ZK

/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf