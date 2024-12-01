#!/bin/bash
set -euoxv pipefail

# scp private/kabustation/setup_ssh_in_linux.sh kabu-json-linux:~/

WINDOWS_INTERNAL_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=kabu-json-windows" "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)
echo "Host kabu-json-windows" > ~/.ssh/config
echo "  HostName ${WINDOWS_INTERNAL_IP}" >> ~/.ssh/config
echo "  RequestTTY no" >> ~/.ssh/config
echo "  User Administrator" >> ~/.ssh/config
echo "  IdentityFile ~/.ssh/kabu-json-kabustation.pem" >> ~/.ssh/config
echo "  StrictHostKeyChecking no" >> ~/.ssh/config
echo "  LocalForward 3389 localhost:3389" >> ~/.ssh/config
echo "  LocalForward 18080 localhost:18080" >> ~/.ssh/config
echo "  LocalForward 18081 localhost:18081" >> ~/.ssh/config
echo "  ServerAliveInterval 10" >> ~/.ssh/config
echo "  ServerAliveCountMax 10" >> ~/.ssh/config
chmod 600 ~/.ssh/config
