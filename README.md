##CoreOS instances

Install Vagrant (>= 1.6) and VirtualBox, then run ```vagrant up```

```
git clone https://github.com/endocode/CoreOS-Kafka-Storm-Cassandra-cluster-demo
cd CoreOS-Kafka-Storm-Cassandra-cluster-demo/coreos-vagrant
vagrant up
```

Then login to your first Vagrant instance and submit fleet units:
```
vagrant ssh core-01
fleetctl submit /tmp/fleet/*
```

###fleet

fleetctl journal -f %service%@%instance%.service

##run zookeeper on each host

```
fleetctl start zookeeper@{1..3}.service
```

##run kafka on each host

```
fleetctl start kafka@{1..3}.service
```

##run cassandra on each host

```
fleetctl start cassandra@{1..3}.service
```

##run storm cluster

```
fleetctl start storm-nimbus.service
# storm-ui will listen on http://172.17.8.101:8080
fleetctl start storm-ui.service
fleetctl start storm-supervisor@{1..3}.service
```

##run development container inside coreos VM (storm, kafka, maven, scala, python, zookeeper, etc)

```docker run --rm -ti -v /home/core/devel:/root/devel -e BROKER_LIST=`fleetctl list-machines -no-legend=true -fields=ip | sed 's/$/:9092/' | tr '\n' ','` -e NIMBUS_HOST=`etcdctl get /storm-nimbus` -e ZK=`fleetctl list-machines -no-legend=true -fields=ip | tr '\n' ','` endocode/devel-node:0.9.2 start-shell.sh bash```

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

```docker run --rm -ti --entrypoint=/bin/bash endocode/cassandra nodetool -h172.17.8.101 status```

####cassandra cluster CLI

```docker run --rm -ti --entrypoint=/bin/bash endocode/cassandra cassandra-cli -h172.17.8.101```

```docker run --rm -ti --entrypoint=/bin/bash endocode/cassandra /usr/bin/cqlsh 172.17.8.101```

####basic cassandra queries

Execute queries in ```docker run --rm -ti --entrypoint=/bin/bash endocode/cassandra /usr/bin/cqlsh 172.17.8.101``` docker container.

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
docker run --rm -ti -v /home/core/devel:/root/devel -e BROKER_LIST=`fleetctl list-machines -no-legend=true -fields=ip | sed 's/$/:9092/' | tr '\n' ','` -e NIMBUS_HOST=`etcdctl get /storm-nimbus` -e ZK=`fleetctl list-machines -no-legend=true -fields=ip | tr '\n' ','` endocode/devel-node:0.9.2 start-shell.sh bash
cd ~/kafka_cassandra_topology
pyleus build
pyleus submit -n $NIMBUS_HOST kafka-cassandra.jar
#Run Kafka random data producer
./single_python_producer.py
```

It will run kafka-cassandra topology in Storm cluster and Kafka producer. All this data will be stored in Cassandra cluster using Storm topology. You can monitor Cassandra table in CQL shell:

```
docker run --rm -ti --entrypoint=/bin/bash endocode/cassandra /usr/bin/cqlsh 172.17.8.101
Connected to cluster at 172.17.8.101:9160.
[cqlsh 4.1.1 | Cassandra 2.0.12 | CQL spec 3.1.1 | Thrift protocol 19.39.0]
Use HELP for help.
cqlsh> SELECT COUNT(*) FROM testkeyspace.meter_data LIMIT 1000000;

 count
-------
  1175

(1 rows)

cqlsh>
```
