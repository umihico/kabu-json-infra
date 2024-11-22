#!/bin/bash
set -euoxv pipefail

cp private/windows/kabu-json-windows.pem ~/.ssh/
chmod 600 ~/.ssh/kabu-json-windows.pem
ip=$(cat private/windows/ip.json)
echo "Host kabu-json-windows" > ~/.ssh/config.d/kabu-json-windows
echo "  HostName ${ip}" >> ~/.ssh/config.d/kabu-json-windows
echo "  RequestTTY no" >> ~/.ssh/config.d/kabu-json-windows
echo "  User Administrator" >> ~/.ssh/config.d/kabu-json-windows
echo "  IdentityFile ~/.ssh/kabu-json-windows.pem" >> ~/.ssh/config.d/kabu-json-windows
echo "  LocalForward 18080 localhost:18080" >> ~/.ssh/config.d/kabu-json-windows
echo "  LocalForward 18081 localhost:18081" >> ~/.ssh/config.d/kabu-json-windows
echo "  ServerAliveInterval 60" >> ~/.ssh/config.d/kabu-json-windows
echo "  ServerAliveCountMax 0" >> ~/.ssh/config.d/kabu-json-windows

ssh kabu-json-windows
