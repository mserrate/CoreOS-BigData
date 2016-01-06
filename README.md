*That's basically a copy of: https://github.com/endocode/CoreOS-Kafka-Storm-Cassandra-cluster-demo adapted to my needs*


##CoreOS instances

Install Vagrant (>= 1.6) and VirtualBox, then run

```
git clone https://github.com/mserrate/CoreOS-BigData
cd CoreOS-Kafka-Storm-Cassandra-cluster-demo/coreos-vagrant
vagrant up
```

Vagrant will create three CoreOS VMs with the following IPs: 172.17.8.101, 172.17.8.102, 172.17.8.103

Then login to your first Vagrant instance and submit fleet units:
```
vagrant ssh core-01 -- -A
fleetctl submit share/*.service share/*.mount
```
##Load the persisted data storage

```
fleetctl load media-storage.mount
```

##Run Zookeeper cluster

```
fleetctl start zookeeper@{1..3}.service
```

##Run Kafka cluster

```
fleetctl start kafka@{1..3}.service
```

##Run Cassandra luster

```
fleetctl start cassandra@{1..3}.service
```

##Run Storm cluster

```
fleetctl start storm-nimbus.service
# storm-ui (not required) will listen on http://172.17.8.101:8080
fleetctl start storm-ui.service
fleetctl start storm-supervisor@{1..3}.service
```

##Run development container inside CoreOS VM (storm, kafka, maven, scala, python, zookeeper, cassandra, etc)

```docker run --rm -ti -v /home/core/share:/root/share -e BROKER_LIST=`fleetctl list-machines -no-legend=true -fields=ip | sed 's/$/:9092/' | paste -s -d ','` -e NIMBUS_HOST=`etcdctl get /storm-nimbus` -e ZK=`fleetctl list-machines -no-legend=true -fields=ip | paste -s -d ','` mserrate/devel-env start-shell.sh bash```

###Test Kafka cluster

Run these commands in devel-node container to test your Kafka cluster.

Create topic

```$KAFKA_HOME/bin/kafka-topics.sh --create --topic test --partitions 3 --zookeeper $ZK --replication-factor 2```

Show topic info

```$KAFKA_HOME/bin/kafka-topics.sh --describe --topic test --zookeeper $ZK```

Send some data to topic

```$KAFKA_HOME/bin/kafka-console-producer.sh --topic test --broker-list="$BROKER_LIST"```

Get some data from topic

```$KAFKA_HOME/bin/kafka-console-consumer.sh --zookeeper $ZK --topic test --from-beginning```

Remove topic (valid only with KAFKA_DELETE_TOPIC_ENABLE=true environment)

```$KAFKA_HOME/bin/kafka-topics.sh --zookeeper $ZK --delete --topic test```

###Cassandra

####Cassandra cluster CLI


```cqlsh 172.17.8.101```

####Cassandra queries

You can view and manage your Cassandra table's content with the following queries:

```
SELECT * FROM testkeyspace.meter_data;
#Delete content from table
TRUNCATE testkeyspace.meter_data;
SELECT COUNT(*) FROM testkeyspace.meter_data LIMIT 1000000;
```

####Storm topology

Take a look to https://github.com/mserrate/twitter-streaming-app for a sample topology

```

```

##Troubleshooting:
To be able to use fleetctl ssh 
```
#start user agent by typng:
eval $(ssh-agent)
#add the private key to the agent:
ssh-add

#if it's vagrant:
ssh-add ~/.vagrant.d/insecure_private_key
vagrant ssh core-01 -- -A
```

To shell a session on a running container:
```
#in this case container cassandra-1
sudo docker exec -i -t cassandra-1 bash
```

Restart unit:
```
sudo systemctl start kafka@3.service
```


To not type Vagrant password each time for shared folders:
```
#On MacOS
sudo visudo
#Place the following at the bottom of the file
Cmnd_Alias VAGRANT_EXPORTS_ADD = /usr/bin/tee -a /etc/exports
Cmnd_Alias VAGRANT_NFSD = /sbin/nfsd restart
Cmnd_Alias VAGRANT_EXPORTS_REMOVE = /usr/bin/sed -E -e /*/ d -ibak /etc/exports
%admin ALL=(root) NOPASSWD: VAGRANT_EXPORTS_ADD, VAGRANT_NFSD, VAGRANT_EXPORTS_REMOVE
```
