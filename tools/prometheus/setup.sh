#!/bin/bash -xe

####################################
####        ADMIN MACHINE   ########
####################################

# Install requirements
sudo apt-get install wget -y

# Download and install prometheus
cd
wget https://github.com/prometheus/prometheus/releases/download/v2.7.1/prometheus-2.7.1.linux-amd64.tar.gz
tar -xvzf prometheus-*.tar.gz
rm prometheus-*.tar.gz
mv prometheus-2.7.1.linux-amd64 prometheus

# Start Prometheus:
#./prometheus
