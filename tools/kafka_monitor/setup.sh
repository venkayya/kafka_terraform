#!/bin/bash -xe

####################################
####        ADMIN MACHINE   ########
####################################

# Install Requirements
sudo apt-get update -y
sudo apt-get install -y git


# Install Kafka-Monitor
git clone https://github.com/linkedin/kafka-monitor.git
cd kafka-monitor
./gradlew jar

# Start kafka monitor
./bin/kafka-monitor-start.sh config/kafka-monitor.properties


# Setup as Systemd component
tee /etc/systemd/system/kafka-monitor.service <<EOF
# /etc/systemd/system/kafka-monitor.service
[Unit]
Description=Kafka Monitor
After=network.target

[Service]
User=ec2-user
Group=ec2-user
WorkingDirectory=/opt/kafka-monitor
ExecStart=/opt/kafka-monitor/bin/kafka-monitor-start.sh /opt/kafka-monitor/config/kafka-monitor.properties
SuccessExitStatus=143

[Install]
WantedBy=multi-user.target
EOF
