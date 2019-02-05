#!/bin/bash -xe

sudo apt-get install wget -y

sudo mkdir -p /opt/prometheus
wget -N -P /opt/prometheus https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.11.0/jmx_prometheus_javaagent-0.11.0.jar
wget -N -P /opt/prometheus https://raw.githubusercontent.com/prometheus/jmx_exporter/master/example_configs/kafka-2_0_0.yml
wget -N -P /opt/prometheus https://raw.githubusercontent.com/prometheus/jmx_exporter/master/example_configs/zookeeper.yaml
