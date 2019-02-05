#!/usr/bin/env bash

sudo apt-get update -y
sudo apt-get install -y wget git openjdk-8-jdk

####################################################################################
######################    Required for Settingup Prometheus   ######################
####################################################################################

# Download Prometheus
cd /tmp \
&& wget https://github.com/prometheus/prometheus/releases/download/v2.7.1/prometheus-2.7.1.linux-amd64.tar.gz

cd /opt \
&& tar -xvzf /tmp/prometheus-2.7.1.linux-amd64.tar.gz \
&& rm prometheus-2.7.1.linux-amd64.tar.gz

#Prometheus as Systemd Service
tee /etc/systemd/system/prometheus.service <<EOF
# /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus Server
Documentation=https://prometheus.io/docs/introduction/overview/
After=network-online.target

[Service]
User=root
Group=root
WorkingDirectory=/opt/prometheus-2.7.1.linux-amd64
ExecStart=/opt/prometheus-2.7.1.linux-amd64/prometheus

[Install]
WantedBy=multi-user.target
EOF

# Prometheus Scape jobs
tee /opt/prometheus-2.7.1.linux-amd64/prometheus.yml <<EOF
global:
  scrape_interval: 10s
  evaluation_interval: 10s
scrape_configs:
  - job_name: 'kafka'
    static_configs:
    - targets:
      - kafka1:8080   #Broker 1
      - kafka2:8080   #Broker 2
      - kafka3:8080   #Broker 3
  - job_name: 'zookeeper'
    static_configs:
    - targets:
      - zk1:8080  #Zookeeper1
      - zk2:8080  #Zookeeper2
      - zk3:8080  #Zookeeper3
EOF
#Start Prometheus Server
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

####################################################################################
######################     Required for Settingup Grafana     ######################
####################################################################################
# Download Grafana
cd /tmp \
&& wget https://dl.grafana.com/oss/release/grafana-5.4.3.linux-amd64.tar.gz

cd /opt \
&& tar -xvzf /tmp/grafana-5.4.3.linux-amd64.tar.gz \
&& rm grafana-5.4.3.linux-amd64.tar.gz

# Grafana as Systemd Service
tee /etc/systemd/system/grafana.service <<EOF
# /etc/systemd/system/grafana.service
[Unit]
Description=Grafana Server
Documentation=http://docs.grafana.org/guides/getting_started/
After=network-online.target

[Service]
User=root
Group=root
WorkingDirectory=/opt/grafana-5.4.3
ExecStart=/opt/grafana-5.4.3/bin/grafana-server

[Install]
WantedBy=multi-user.target
EOF

# Start Grafana Server
sudo systemctl daemon-reload
sudo systemctl enable grafana
sudo systemctl start grafana

####################################################################################
######################  Required for Settingup Kafka-monitor  ######################
####################################################################################

# Build Kafka monitor jar
cd /opt \
&& git clone https://github.com/linkedin/kafka-monitor.git
cd kafka-monitor
./gradlew jar

# Copy Kafka monitor properties
tee /opt/kafka-monitor/config/kafka-monitor.properties <<EOF
{
  "single-cluster-monitor": {
    "class.name": "com.linkedin.kmf.apps.SingleClusterMonitor",
    "topic": "kafka-monitor-topic",
    "zookeeper.connect": "zk1:2181,zk2:2181,zk3:2181",
    "bootstrap.servers": "kafka1:9092,kafka2:9092,kafka3:9092",
    "produce.record.delay.ms": 100,
    "topic-management.topicCreationEnabled": true,
    "topic-management.replicationFactor" : 3,
    "topic-management.partitionsToBrokersRatio" : 2.0,
    "topic-management.rebalance.interval.ms" : 600000,
    "topic-management.topicFactory.props": {
    },
    "topic-management.topic.props": {
      "retention.ms": "3600000"
    },
    "produce.producer.props": {
      "client.id": "kmf-client-id"
    },

    "consume.latency.sla.ms": "20000",
    "consume.consumer.props": {

    }

  },

  "jetty-service": {
    "class.name": "com.linkedin.kmf.services.JettyService",
    "jetty.port": 8000
  },

  "jolokia-service": {
    "class.name": "com.linkedin.kmf.services.JolokiaService"
  },


  "reporter-service": {
    "class.name": "com.linkedin.kmf.services.DefaultMetricsReporterService",
    "report.interval.sec": 1,
    "report.metrics.list": [
      "kmf:type=kafka-monitor:offline-runnable-count",
      "kmf.services:type=produce-service,name=*:produce-availability-avg",
      "kmf.services:type=consume-service,name=*:consume-availability-avg",
      "kmf.services:type=produce-service,name=*:records-produced-total",
      "kmf.services:type=consume-service,name=*:records-consumed-total",
      "kmf.services:type=consume-service,name=*:records-lost-total",
      "kmf.services:type=consume-service,name=*:records-duplicated-total",
      "kmf.services:type=consume-service,name=*:records-delay-ms-avg",
      "kmf.services:type=produce-service,name=*:records-produced-rate",
      "kmf.services:type=produce-service,name=*:produce-error-rate",
      "kmf.services:type=consume-service,name=*:consume-error-rate"
    ]
  }

}
EOF
# Setup as Systemd component
tee /etc/systemd/system/kafka-monitor.service <<EOF
# /etc/systemd/system/kafka-monitor.service
[Unit]
Description=Kafka Monitor
After=network.target

[Service]
User=root
Group=root
WorkingDirectory=/opt/kafka-monitor
ExecStart=/opt/kafka-monitor/bin/kafka-monitor-start.sh /opt/kafka-monitor/config/kafka-monitor.properties
SuccessExitStatus=143

[Install]
WantedBy=multi-user.target
EOF

# Start Grafana Server
sudo systemctl daemon-reload
sudo systemctl enable kafka-monitor
sudo systemctl start kafka-monitor

####################################################################################
######################  Required for Settingup Kafka-manager  ######################
####################################################################################

# Install Docker and docker-compose
cd /tmp \
&& wget ${DOCKER_URL}/docker-ce_18.09.1~3-0~debian-stretch_amd64.deb \
&& wget ${DOCKER_URL}/docker-ce-cli_18.09.1~3-0~debian-stretch_amd64.deb \
&& wget ${DOCKER_URL}/containerd.io_1.2.2-1_amd64.deb

dpkg -i containerd.io_1.2.2-1_amd64.deb
apt-get install libltdl7
dpkg -i docker-ce-cli_18.09.1~3-0~debian-stretch_amd64.deb
dpkg -i docker-ce_18.09.1~3-0~debian-stretch_amd64.deb
curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" \
     -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
usermod -a -G docker venkayyanaidu
sudo systemctl restart docker

# Kafka manager compose file
mkdir /opt/kafka-manager
tee /opt/kafka-manager/kafka-manager.yml <<EOF
# /opt/kafka-manager/kafka-manager.yml
version: '3.6'
services:
  kafka_manager:
    image: hlebalbau/kafka-manager
    ports:
      - "9000:9000"
    environment:
      ZK_HOSTS: "10.0.0.2:2181,10.0.0.3:2181,10.0.0.4:2181"
      APPLICATION_SECRET: "random-secret"
    command: -Dpidfile.path=/dev/null
EOF

# Start Kafka manager
docker-compose -f /opt/kafka-manager/kafka-manager.yml up -d

####################################################################################
######################  Required for Settingup Kafka-manager  ######################
####################################################################################

# Zoonavigator compose file
mkdir /opt/zoonavigator/
tee /opt/zoonavigator/zoonavigator.yml <<EOF
version: '2.1'
services:
  web:
    image: elkozmon/zoonavigator-web
    container_name: zoonavigator-web
    ports:
     - "7070:7070"
    environment:
      WEB_HTTP_PORT: 7070
      API_HOST: "api"
      API_PORT: 7072
    depends_on:
     - api
  api:
    image: elkozmon/zoonavigator-api
    container_name: zoonavigator-api
    environment:
      API_HTTP_PORT: 7072
EOF

# Start Zoonavigator
docker-compose -f /opt/zoonavigator/zoonavigator.yml up -d
