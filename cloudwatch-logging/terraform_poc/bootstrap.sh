#!/bin/bash
sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo yum -y install amazon-cloudwatch-agent
sudo yum install -y collectd
sudo systemctl enable amazon-cloudwatch-agent && sudo systemctl enable collectd
sudo systemctl start collectd
