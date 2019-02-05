#!/bin/bash -xe

####################################
####        ADMIN MACHINE   ########
####################################

# Install requirements
sudo apt-get install wget -y

# Download and install grafana
cd
wget https://dl.grafana.com/oss/release/grafana-5.4.3.linux-amd64.tar.gz
tar -zxvf grafana-*.gz
rm grafana-*.gz
mv grafana-5.4.3 grafana

# Start grafana:
#./bin/grafana-server
