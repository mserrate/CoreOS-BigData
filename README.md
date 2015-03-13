##CoreOS instances

CoreOS VM instances should be called:
* coreos1
* coreos2
* coreos3

Run empty VMs (4Gb RAM and 20Gb HDD for each) with CoreOS live ISO image (http://stable.release.core-os.net/amd64-usr/current/coreos_production_iso_image.iso), set temporarily root password through the VM console: ```sudo passwd```

First run of ```coreos_install``` will create ```coreos.inc``` file at current directory. ```coreos.inc``` file will contain new ETCD discovery ID and public key path.

Then run installation process:
```
./coreos_install %IP_ADDR_1% coreos1
./coreos_install %IP_ADDR_2% coreos2
./coreos_install %IP_ADDR_3% coreos3
```

By default ```coreos_install``` script uses ```~/.ssh/id_psa.pub``` public key. You can specify your own path (public key path should ends on ```*.pub``` to avoid private keys submit), i.e.:

```
./coreos_install %IP_ADDR_1% coreos1 ~/.ssh/my_special_key.pub
```

This path will be stored after first run of ```coreos_install``` inside the *coreos.inc* file.

VMs will be halted after installation. Eject ISO from VM and start VMs.

Install script will create ```hosts``` file at current directory with your CoreOS VMs' IP addresses and hostnames. You can update your systems' ```/etc/hosts``` with the following command: ```cat ./hosts | sudo tee -a /etc/hosts```

###fleet

CoreOS installation script set specific metadata to each coreos host:
* coreos1: metadata: zookeeperid=1
* coreos2: metadata: zookeeperid=2
* coreos3: metadata: zookeeperid=3

This metadata will be used to run each zookeeper instance on corresponding coreos VM.

####download and unpack fleet binaries

* Linux binaries - https://github.com/coreos/fleet/releases/download/v0.9.1/fleet-v0.9.1-linux-amd64.tar.gz
* Darwin binaries - https://github.com/coreos/fleet/releases/download/v0.9.1/fleet-v0.9.1-darwin-amd64.zip

####fleet configuration on local machine

Export the FLEETCTL_ENDPOINT environment:
```export FLEETCTL_ENDPOINT=http://coreos1:4001```

or create alias for fleetct:
```alias fleetctl="%PATH_TO_FLEETCTL_BINARIES%/fleetctl --endpoint=http://coreos1:4001"```

to run fleetctl on your local machine, not only on CoreOS VMs.

####view containters' journals 

fleetctl journal -f %service%@%instance%.service

##run zookeeper on each host

```
fleetctl submit fleet/zookeeper@.service
fleetctl start zookeeper@{1..3}.service
```

##run kafka on each host

```
fleetctl submit fleet/kafka@.service
fleetctl start kafka@{1..3}.service
```

##run cassandra on each host

```
fleetctl submit fleet/cassandra@.service
fleetctl start cassandra@1.service
# wait until first node is up and ready (Listening for thrift clients...)
fleetctl start cassandra@2.service
fleetctl start cassandra@3.service
```

##run storm cluster

```
fleetctl submit fleet/storm-nimbus.service
fleetctl start storm-nimbus.service
# wait until nimbus node is up and ready
# start storm UI
fleetctl submit fleet/storm-ui.service
# storm-ui will listen on http://coreos1:8080
fleetctl start storm-ui.service
# submit storm-supervisor template
fleetctl submit fleet/storm-supervisor@.service
fleetctl start storm-supervisor@{1..3}.service
```

##run development container inside coreos VM (storm, kafka, maven, scala, python, zookeeper, etc)

```docker run --rm -ti -v /home/core/devel:/root/devel -e JVMFLAGS="-Xmx64m -Xms64M" -e KAFKA_ADVERTISED_PORT=9092 -e HOST_IP=`hostname -i` -e ZK=`hostname -i` -e BROKER_LIST=`fleetctl list-machines -no-legend=true -fields=ip | sed 's/$/:9092/' | tr '\n' ','` -e HOST_NAME=`hostname -i` -e NIMBUS_HOST="%NIMBUS_HOST%" -e ZK=`fleetctl list-machines -no-legend=true -fields=ip | tr '\n' ','` endocode/devel-node:0.9.2```

###test kafka

Run these commands in devel-node container.

Create topic

```$KAFKA_HOME/bin/kafka-topics.sh --create --topic topic --partitions 4 --zookeeper $ZK --replication-factor 2```

Show topic info

```$KAFKA_HOME/bin/kafka-topics.sh --describe --topic topic --zookeeper $ZK```

Send some data to topic

```$KAFKA_HOME/bin/kafka-console-producer.sh --topic=topic --broker-list="$BROKER_LIST"```

Get some data from topic

```$KAFKA_HOME/bin/kafka-console-consumer.sh --zookeeper $ZK --topic topic --from-beginning```

Remove topic (valid only with KAFKA_DELETE_TOPIC_ENABLE=true environment)

```$KAFKA_HOME/bin/kafka-topics.sh --zookeeper $ZK --delete --topic topic```

###cassandra

####show cassandra cluster status

```docker run --rm -ti --entrypoint=/bin/bash endocode/cassandra nodetool -hcoreos1 status```

####cassandra cluster CLI

```docker run --rm -ti --entrypoint=/bin/bash endocode/cassandra cassandra-cli -hcoreos1```

```docker run --rm -ti --entrypoint=/bin/bash endocode/cassandra /usr/bin/cqlsh coreos1```

####basic cassandra queries

Execute queries in ```docker run --rm -ti --entrypoint=/bin/bash endocode/cassandra /usr/bin/cqlsh coreos1``` docker container.

```
SELECT * FROM system.schema_keyspaces;
CREATE KEYSPACE testkeyspace WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 3 };
CREATE TABLE IF NOT EXISTS testkeyspace.meter_data ( id uuid, Timestamp timestamp, P_1 float, P_2 float, P_3 float, Q_1 float, Q_2 float, Q_3 float, HARM list<int>, PRIMARY KEY (id, Timestamp) );
INSERT INTO testkeyspace.meter_data (id, P_1, P_2, P_3, Q_1, Q_2, Q_3, HARM, timestamp) VALUES(f21d2312-ba1b-4d2c-8cfa-817bf783cbe6,1,2,3,4,5,6,[1,2],1425398075000);
SELECT * FROM testkeyspace.meter_data;
TRUNCATE testkeyspace.meter_data;
DESCRIBE KEYSPACE testkeyspace;
copy testkeyspace.meter_data to stdout;
```

####storm topology

We will use Pyleus (http://yelp.github.io/pyleus/) framework to manage Storm topologies in pure python. Unfortunately current Pyleus version (0.2.4) doesn't support latest Storm 0.9.3 (https://github.com/Yelp/pyleus/issues/86). That is why we use Storm 0.9.2 in this example.
endocode/devel-node:0.9.2 Docker container contains sample kafka-storm-cassandra Storm topology. Follow these steps to build and submit Storm topology into Storm cluster:

* Create Kafka ```topic``` topic, Cassandra ```testkeyspace``` keyspace and ```meter_data``` table.
* 

```
docker run --rm -ti -v /home/core/devel:/root/devel -e JVMFLAGS="-Xmx64m -Xms64M" -e KAFKA_ADVERTISED_PORT=9092 -e HOST_IP=`hostname -i` -e ZK=`hostname -i` -e BROKER_LIST=`fleetctl list-machines -no-legend=true -fields=ip | sed 's/$/:9092/' | tr '\n' ','` -e HOST_NAME=`hostname -i` -e NIMBUS_HOST=`etcdctl get /storm-nimbus` -e ZK=`fleetctl list-machines -no-legend=true -fields=ip | tr '\n' ','` endocode/devel-node:0.9.2
cd ~/kafka_cassandra_topology
pyleus build
pyleus submit -n $NIMBUS_HOST kafka-cassandra.jar
```

It will run kafka-cassandra topology in Storm cluster. You can run ```single_python_producer.py``` python script to produce random test data into Kafka ```topic``` topic. All this data will be stored in Cassandra cluster.

###fix invalid etcd configuration.

UPD: Another solution is to use single-node etcd:
* https://coreos.com/docs/cluster-management/setup/cluster-architectures/#easy-development/testing-cluster
* https://gist.github.com/kelseyhightower/c36b9bac064a5e4356e4
* https://www.youtube.com/watch?v=duUTk8xxGbU

When it is necessary to reboot all CoreOS VMs in your cluster simultaneously, make sure you've made an etcd backup:

https://github.com/coreos/etcd/blob/master/Documentation/admin_guide.md#disaster-recovery

Otherwise you should create new etcd configuration (it will remove all stored data from your ETCD!):
Please run these commands on first machine:

```
sudo -i -H
systemctl stop etcd
rm -rf /var/lib/etcd/
sed -ri 's#(discovery:\s*).*#\1'`curl -s https://discovery.etcd.io/new`'#g' /var/lib/coreos-install/user_data
grep discovery /var/lib/coreos-install/user_data
```
And these on the rest:

```
sudo -i -H
export NEW_DISCOVERY_URL="https://discovery.etcd.io/b6e4ab9dedf211f21934825472ae6c6e"
systemctl stop etcd
rm -rf /var/lib/etcd/
sed -ri "s#(discovery:\s*).*#\1$NEW_DISCOVERY_URL#g" /var/lib/coreos-install/user_data
```

Then reboot all machines.

###btrfs insufficient space

https://coreos.com/docs/cluster-management/debugging/btrfs-troubleshooting/

###Fix invalid fleet units

```
rm /run/fleet/units/%invalid_unit%
rm /run/systemd/system/%invalid_unit%
systemctl restart fleet
systemctl daemon-reload
```
