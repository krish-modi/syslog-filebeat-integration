#!/bin/bash

FILEBEAT_VERSION=${FILEBEAT_VERSION:-7.17.8}
FILEBEAT_ARCH=$(uname -m)

echo "Installing dependencies..."
yum install -y curl

echo "Installing Filebeat $FILEBEAT_VERSION..."
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-$FILEBEAT_VERSION-$FILEBEAT_ARCH.rpm
rpm -vi filebeat-$FILEBEAT_VERSION-$FILEBEAT_ARCH.rpm
rm filebeat-$FILEBEAT_VERSION-$FILEBEAT_ARCH.rpm

echo "Copying configuration file..."
cp $(dirname $0)/filebeat.yml /etc/filebeat/filebeat.yml
chown root:root /etc/filebeat/filebeat.yml
chmod 600 /etc/filebeat/filebeat.yml

echo "Downloading SSL certificate..."
mkdir -p /etc/pki/ca-trust/coralogix
curl -o /etc/pki/ca-trust/coralogix/ca.pem \
     https://www.amazontrust.com/repository/AmazonRootCA1.pem

echo "Starting Filebeat..."
systemctl enable filebeat
systemctl start filebeat
systemctl status filebeat