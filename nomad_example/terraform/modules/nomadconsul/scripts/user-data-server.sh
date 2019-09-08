#!/bin/bash

set -e

exec > >(sudo tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
apt-get -y install unzip 
wget https://releases.hashicorp.com/consul/1.6.0/consul_1.6.0_linux_amd64.zip
unzip -o consul_1.6.0_linux_amd64.zip -d /usr/local/bin
wget https://releases.hashicorp.com/nomad/0.9.5/nomad_0.9.5_linux_amd64.zip
unzip -o nomad_0.9.5_linux_amd64.zip -d /usr/local/bin
sudo bash /ops/shared/scripts/server.sh "${server_count}" "${region}" "${cluster_tag_value}"
