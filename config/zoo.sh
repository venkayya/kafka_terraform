#!/usr/bin/env bash

# Configure Second disk for zkdata directory
{ [ mkdir -p /tmp/testmount && sudo mount /dev/sdb1 /tmp/testmount && sudo umount /tmp/testmount && sudo rm -rf /tmp/testmount ]; } \
|| { sudo parted --script /dev/sdb mklabel gpt && sudo parted --script --align optimal /dev/sdb mkpart primary ext4 0% 100% && sudo mkfs.ext4 /dev/sdb1 && sudo mkdir -p ${zkdata_dir} && sudo mount /dev/sdb1 ${zkdata_dir}; }

# Install JAVA
sudo apt-get update -y
sudo dpkg --purge --force-depends ca-certificates-java \
&& sudo apt-get install -y ca-certificates-java \
&& sudo apt-get install -y openjdk-8-jdk \
&& sudo apt-get install -y krb5-user wget

cd /tmp \
&& curl -O http://mirrors.advancedhosters.com/apache/zookeeper/stable/zookeeper-${zk_version}.tar.gz

cd /opt \
&& tar xzf /tmp/zookeeper-${zk_version}.tar.gz

# Assuming that the zookeeper nodes belong to same cidr range because we use last octet as ZK ID
# They need to be unique in the range (1 - 255)
zk_id="$(curl -s 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip' -H 'Metadata-Flavor: Google' | awk -F. '{print $NF}')"
zk_id1=$(echo "${zk1_ip}" | awk -F. '{print $NF}')
zk_id2=$(echo "${zk2_ip}" | awk -F. '{print $NF}')
zk_id3=$(echo "${zk3_ip}" | awk -F. '{print $NF}')

########################## Krb5 Config (for sasl) ##############################
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

############################## Zookeeper Config ################################
tee /opt/zookeeper-${zk_version}/conf/zoo.cfg <<EOF
# The number of milliseconds of each tick
tickTime=2000
# The number of ticks that the initial
# synchronization phase can take
initLimit=10
# The number of ticks that can pass between
# sending a request and getting an acknowledgement
syncLimit=5
# the directory where the snapshot is stored.
# do not use /tmp for storage, /tmp here is just
# example sakes.
dataDir=${zkdata_dir}
# the port at which the clients will connect
clientPort=2181
# the maximum number of client connections.
# increase this if you need to handle more clients
#maxClientCnxns=60
#
# Be sure to read the maintenance section of the
# administrator guide before turning on autopurge.
#
# http://zookeeper.apache.org/doc/current/zookeeperAdmin.html#sc_maintenance
#
# The number of snapshots to retain in dataDir
#autopurge.snapRetainCount=3
# Purge task interval in hours
# Set to "0" to disable auto purge feature
#autopurge.purgeInterval=1
########################### Zookeeper to kafka Sasl ############################
authProvider.$zk_id1=org.apache.zookeeper.server.auth.SASLAuthenticationProvider
authProvider.$zk_id2=org.apache.zookeeper.server.auth.SASLAuthenticationProvider
authProvider.$zk_id3=org.apache.zookeeper.server.auth.SASLAuthenticationProvider
requireClientAuthScheme=sasl
jaasLoginRenew=3600000

############################# Quorum sasl config ###############################
#quorum.auth.enableSasl=true
#quorum.auth.learnerRequireSasl=true
#quorum.auth.serverRequireSasl=true
#quorum.auth.learner.loginContext=QuorumLearner
#quorum.auth.server.loginContext=QuorumServer
#quorum.auth.kerberos.servicePrincipal=zookeeper/$(hostname -f)
#quorum.cnxn.threads.size=20

server.$zk_id1=zk1.c.terraformkafka.internal:2888:3888
server.$zk_id2=zk2.c.terraformkafka.internal:2888:3888
server.$zk_id3=zk3.c.terraformkafka.internal:2888:3888
EOF

############################### Zookeeper id ###################################
echo $zk_id > ${zkdata_dir}/myid

########################### Zookeeper Jaas Config ##############################
tee /opt/zookeeper-${zk_version}/conf/zk_server_jass.conf <<EOF
Server {
    com.sun.security.auth.module.Krb5LoginModule required
    useKeyTab=true
    keyTab="/opt/security/keytabs/zookeeper.service.$(hostname).keytab"
    storeKey=true
    useTicketCache=false
    principal="zookeeper/$(hostname -f)@KAFKASECURITY.POC";
};
EOF
#QuorumServer {
#    com.sun.security.auth.module.Krb5LoginModule required
#    useKeyTab=true
#    keyTab="/opt/security/keytabs/zookeeper.service.$(hostname).keytab"
#    storeKey=true
#    useTicketCache=false
#    principal="zookeeper/$(hostname -f)@KAFKASECURITY.POC";
#};

#QuorumLearner {
#    com.sun.security.auth.module.Krb5LoginModule required
#    useKeyTab=true
#    keyTab="/opt/security/keytabs/zookeeper.service.$(hostname).keytab"
#    storeKey=true
#    useTicketCache=false
#    principal="zookeeper/$(hostname -f)@KAFKASECURITY.POC";
#};
############################ Zookeeper Environment #############################
tee /opt/zookeeper-${zk_version}/conf/zookeeper-env.sh <<EOF
JMXLOCALONLY=true
SERVER_JVMFLAGS="-Djava.security.auth.login.config=/opt/zookeeper-${zk_version}/conf/zk_server_jass.conf -Dsun.security.krb5.debug=true -javaagent:/opt/prometheus/jmx_prometheus_javaagent-0.11.0.jar=8080:/opt/prometheus/zookeeper.yaml"
EOF

########################### Zookeeper krb5 Keytabs #############################
mkdir -p /opt/security/keytabs/
cd /opt/security/keytabs/
kadmin -q "xst -kt /opt/security/keytabs/zookeeper.service.$(hostname).keytab zookeeper/$(hostname -f)" -w "unsecurekrb5pass" -p venkayyanaidu/admin

####################### Zookeeper Prometheus Jmx Config ########################
sudo mkdir -p /opt/prometheus
wget -N -P /opt/prometheus https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.11.0/jmx_prometheus_javaagent-0.11.0.jar
wget -N -P /opt/prometheus https://raw.githubusercontent.com/prometheus/jmx_exporter/master/example_configs/zookeeper.yaml

########################## Zookeeper Systemd config ############################
tee /etc/systemd/system/zookeeper.service <<EOF
[Unit]
Description=Zookeeper Service

[Service]
Type=forking
User=root
Group=root
ExecStart=/opt/zookeeper-3.4.12/bin/zkServer.sh start
ExecStop=/opt/zookeeper-3.4.12/bin/zkServer.sh stop
SuccessExitStatus=130 143

[Install]
WantedBy=multi-user.target
EOF

############################## Start Zookeeper #################################
sudo systemctl daemon-reload
sudo systemctl enable zookeeper
sudo systemctl start zookeeper
