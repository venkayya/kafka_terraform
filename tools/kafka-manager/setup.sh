#!/bin/bash -xe

# Install Docker and docker-compose
cd /tmp \
&& wget https://download.docker.com/linux/debian/dists/stretch/pool/stable/amd64/docker-ce_18.09.1~3-0~debian-stretch_amd64.deb \
&& wget https://download.docker.com/linux/debian/dists/stretch/pool/stable/amd64/docker-ce-cli_18.09.1~3-0~debian-stretch_amd64.deb \
&& wget https://download.docker.com/linux/debian/dists/stretch/pool/stable/amd64/containerd.io_1.2.2-1_amd64.deb

dpkg -i containerd.io_1.2.2-1_amd64.deb
apt-get install libltdl7
dpkg -i docker-ce-cli_18.09.1~3-0~debian-stretch_amd64.deb
dpkg -i docker-ce_18.09.1~3-0~debian-stretch_amd64.deb
curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Test Kafka Manager
# docker-compose -f kafka-manager.yml up -d


# Install Kafka Manager as Systemd
#sudo mkdir -p /etc/docker/compose/kafka-manager/
#sudo nano /etc/docker/compose/kafka-manager/docker-compose.yml
#sudo systemctl enable docker-compose@kafka-manager # automatically start at boot
#sudo systemctl start docker-compose@kafka-manager
