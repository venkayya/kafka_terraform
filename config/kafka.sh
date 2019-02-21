#!/usr/bin/env bash

################################################################################
######################    Required for Settingup Kafka    ######################
################################################################################

# Install JAVA and Kerberos user packages
sudo apt-get update -y
sudo dpkg --purge --force-depends ca-certificates-java \
&& sudo apt-get install -y ca-certificates-java \
&& sudo apt-get install -y openjdk-11-jdk \
&& sudo apt-get install wget -y \
&& export DEBAIN_FRONTEND=noninteractive; sudo apt-get install -y krb5-user


cd /tmp \
&& curl -O http://apache.cs.utah.edu/kafka/${kafka_version}/kafka_2.11-${kafka_version}.tgz

cd /opt \
&& tar xzf /tmp/kafka_2.11-${kafka_version}.tgz

# Assuming that the kafka nodes belong to same cidr range because we use last octet as Broker ID
# They need to be unique in the range (1 - 255)
broker_id="$(curl -s 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip' -H 'Metadata-Flavor: Google' | awk -F. '{print $NF}')"

# Kafka Logs Directory
mkdir -p ${kafka_log_dir}

############################# Krb5 Config (for sasl) ###########################
tee /etc/krb5.conf <<EOF
[libdefaults]
    default_realm = KAFKASECURITY.POC
# The following krb5.conf variables are only for MIT Kerberos.
    kdc_timesync = 1
    ccache_type = 4
    forwardable = true
    proxiable = true
# The following libdefaults parameters are only for Heimdal Kerberos.
    fcc-mit-ticketflags = true
[realms]
    KAFKASECURITY.POC = {
      kdc = kerberos.c.terraformkafka.internal
      admin_server = kerberos.c.terraformkafka.internal
    }
[domain_realm]
    .kafkasecurity.poc = KAFKASECURITY.POC
    kafkasecurity.poc = KAFKASECURITY.POC
EOF

############################## Config (for ssl) ################################

SRVPASS=2019@Naidu
mkdir -p /opt/security/ssl
cd /opt/security/ssl
openssl req \
  -newkey rsa:4096 \
  -days 365 \
  -x509 \
  -subj "/CN=Kafka-Security-CA" \
  -keyout ca-key \
  -out ca-cert \
  -nodes

keytool -genkey \
  -keystore kafka.server.keystore.jks \
  -validity 365 \
  -storepass $SRVPASS \
  -keypass $SRVPASS \
  -dname "CN = Kafka-Security-CA" \
  -storetype pkcs12

keytool -keystore kafka.server.keystore.jks \
  -certreq -file cert-file \
  -storepass $SRVPASS \
  -keypass $SRVPASS

openssl x509 \
  -req \
  -CA ca-cert \
  -CAkey ca-key \
  -in cert-file \
  -out ca-signed \
  -days 365 \
  -CAcreateserial \
  -passin pass:$SRVPASS

keytool -keystore kafka.server.truststore.jks \
  -alias CARoot \
  -import -file ca-cert \
  -storepass $SRVPASS \
  -keypass $SRVPASS \
  -noprompt

keytool -keystore kafka.server.keystore.jks \
  -alias CARoot \
  -import -file ca-cert \
  -storepass $SRVPASS \
  -keypass $SRVPASS \
  -noprompt

keytool -keystore kafka.server.keystore.jks \
  -import -file ca-signed \
  -storepass $SRVPASS \
  -keypass $SRVPASS \
  -noprompt

######################## Kafka server secure properties ########################
tee /opt/kafka_2.11-${kafka_version}/config/server.properties <<EOF
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# see kafka.server.KafkaConfig for additional details and defaults

############################# Server Basics #############################

# The id of the broker. This must be set to a unique integer for each broker.
broker.id=$broker_id

############################# Socket Server Settings #############################

# The address the socket server listens on. It will get the value returned from
# java.net.InetAddress.getCanonicalHostName() if not configured.
#   FORMAT:
#     listeners = listener_name://host_name:port
#   EXAMPLE:
#     listeners = PLAINTEXT://your.host.name:9092
listeners=SSL://$(hostname -f):9092,SASL_SSL://$(hostname -f):9093

# Hostname and port the broker will advertise to producers and consumers. If not set,
# it uses the value for "listeners" if configured.  Otherwise, it will use the value
# returned from java.net.InetAddress.getCanonicalHostName().
advertised.listeners=SSL://$(hostname -f):9092,SASL_SSL://$(hostname -f):9093

# Maps listener names to security protocols, the default is for them to be the same. See the config documentation for more details
#listener.security.protocol.map=PLAINTEXT:PLAINTEXT,SSL:SSL,SASL_PLAINTEXT:SASL_PLAINTEXT,SASL_SSL:SASL_SSL

# ssl specific configuration
ssl.client.auth=required
ssl.enabled.protocols=TLSv1.2,TLSv1.1,TLSv1
ssl.keystore.location=/opt/security/ssl/kafka.server.keystore.jks
ssl.keystore.password=serversecret
ssl.key.password=serversecret
ssl.truststore.location=/opt/security/ssl/kafka.server.truststore.jks
ssl.truststore.password=serversecret
ssl.endpoint.identification.algorithm=HTTPS

# sasl specific configuration
security.inter.broker.protocol=SSL
#security.inter.broker.protocol=SASL_PLAINTEXT
#security.inter.broker.protocol=SSL
sasl.mechanism.inter.broker.protocol=GSSAPI
sasl.enabled.mechanism=GSSAPI
sasl.kerberos.service.name=kafka


# The number of threads that the server uses for receiving requests from the network and sending responses to the network
num.network.threads=10

# The number of threads that the server uses for processing requests, which may include disk I/O
num.io.threads=8

# The send buffer (SO_SNDBUF) used by the socket server
socket.send.buffer.bytes=102400

# The receive buffer (SO_RCVBUF) used by the socket server
socket.receive.buffer.bytes=102400

# The maximum size of a request that the socket server will accept (protection against OOM)
socket.request.max.bytes=104857600


############################# Log Basics #############################

# A comma separated list of directories under which to store log files
log.dirs=${kafka_log_dir}

# The default number of log partitions per topic. More partitions allow greater
# parallelism for consumption, but this will also result in more files across
# the brokers.
num.partitions=1

# The number of threads per data directory to be used for log recovery at startup and flushing at shutdown.
# This value is recommended to be increased for installations with data dirs located in RAID array.
num.recovery.threads.per.data.dir=1

############################# Internal Topic Settings  #############################
# The replication factor for the group metadata internal topics "__consumer_offsets" and "__transaction_state"
# For anything other than development testing, a value greater than 1 is recommended for to ensure availability such as 3.
offsets.topic.replication.factor=3
transaction.state.log.replication.factor=3
transaction.state.log.min.isr=3

############################# Log Flush Policy #############################

# Messages are immediately written to the filesystem but by default we only fsync() to sync
# the OS cache lazily. The following configurations control the flush of data to disk.
# There are a few important trade-offs here:
#    1. Durability: Unflushed data may be lost if you are not using replication.
#    2. Latency: Very large flush intervals may lead to latency spikes when the flush does occur as there will be a lot of data to flush.
#    3. Throughput: The flush is generally the most expensive operation, and a small flush interval may lead to excessive seeks.
# The settings below allow one to configure the flush policy to flush data after a period of time or
# every N messages (or both). This can be done globally and overridden on a per-topic basis.

# The number of messages to accept before forcing a flush of data to disk
#log.flush.interval.messages=10000

# The maximum amount of time a message can sit in a log before we force a flush
#log.flush.interval.ms=1000

############################# Log Retention Policy #############################

# The following configurations control the disposal of log segments. The policy can
# be set to delete segments after a period of time, or after a given size has accumulated.
# A segment will be deleted whenever *either* of these criteria are met. Deletion always happens
# from the end of the log.

# The minimum age of a log file to be eligible for deletion due to age
log.retention.hours=168

# A size-based retention policy for logs. Segments are pruned from the log unless the remaining
# segments drop below log.retention.bytes. Functions independently of log.retention.hours.
#log.retention.bytes=1073741824

# The maximum size of a log segment file. When this size is reached a new log segment will be created.
log.segment.bytes=1073741824

# The interval at which log segments are checked to see if they can be deleted according
# to the retention policies
log.retention.check.interval.ms=300000

############################# Zookeeper #############################

# Zookeeper connection string (see zookeeper docs for details)
zookeeper.connect=zk1.c.terraformkafka.internal:2181,zk2.c.terraformkafka.internal:2181,zk3.c.terraformkafka.internal:2181

#Zookeeper Acl for broker binding
#zookeeper.acl.set=true

# Timeout in ms for connecting to zookeeper
zookeeper.connection.timeout.ms=6000

############################# Group Coordinator Settings #############################

# The following configuration specifies the time, in milliseconds, that the GroupCoordinator will delay the initial consumer rebalance.
# The rebalance will be further delayed by the value of group.initial.rebalance.delay.ms as new members join the group, up to a maximum of max.poll.interval.ms.
# The default value for this is 3 seconds.
# We override this to 0 here as it makes for a better out-of-the-box experience for development and testing.
# However, in production environments the default value of 3 seconds is more suitable as this will help to avoid unnecessary, and potentially expensive, rebalances during application startup.
group.initial.rebalance.delay.ms=0
EOF

############################### kafka jass config ##############################
mkdir -p /opt/security/keytabs/
tee /opt/kafka_2.11-${kafka_version}/config/kafka_server_jass.conf <<EOF
KafkaServer{
  com.sun.security.auth.module.Krb5LoginModule required
  useKeyTab=true
  storeKey=true
  keyTab="/opt/security/keytabs/kafka.service.$(hostname).keytab"
  principal="kafka/$(hostname -f)@KAFKASECURITY.POC";
};

// ZooKeeper client authentication
Client {
    com.sun.security.auth.module.Krb5LoginModule required
    useKeyTab=true
    storeKey=true
    keyTab="/opt/security/keytabs/kafka.service.$(hostname).keytab"
    principal="kafka/$(hostname -f)@KAFKASECURITY.POC";
};
EOF

############################# Kafka krb5 Keytabs ###############################
mkdir -p /opt/security/keytabs/
kadmin -q "xst -kt /opt/security/keytabs/kafka.service.$(hostname).keytab kafka/$(hostname -f)" -w "unsecurekrb5pass" -p venkayyanaidu/admin

########################## Kafka prometheus JMX Agent ##########################
mkdir -p /opt/prometheus
wget -N -P /opt/prometheus https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.11.0/jmx_prometheus_javaagent-0.11.0.jar
wget -N -P /opt/prometheus https://raw.githubusercontent.com/prometheus/jmx_exporter/master/example_configs/kafka-2_0_0.yml

############################ Kafka systemd service #############################
tee /etc/systemd/system/kafka.service <<EOF
[Unit]
Description=Apache Kafka server (broker)
Requires=network.target remote-fs.target
After=network.target remote-fs.target

[Service]
Type=simple
User=root
Group=root
Environment="KAFKA_OPTS=-Djava.security.auth.login.config=/opt/kafka_2.11-${kafka_version}/config/kafka_server_jass.conf -Dsun.security.krb5.debug=true -Dzookeeper.sasl.client.username=zookeeper -javaagent:/opt/prometheus/jmx_prometheus_javaagent-0.11.0.jar=8080:/opt/prometheus/kafka-2_0_0.yml"
ExecStart=/opt/kafka_2.11-${kafka_version}/bin/kafka-server-start.sh /opt/kafka_2.11-${kafka_version}/config/server.properties
ExecStop=/opt/kafka_2.11-${kafka_version}/bin/kafka-server-stop.sh
SuccessExitStatus=143

[Install]
WantedBy=multi-user.target
EOF

############################ Enable and Restart kafka ##########################
sudo systemctl daemon-reload
sudo systemctl enable kafka
sudo systemctl start kafka
