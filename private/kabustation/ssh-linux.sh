#!/bin/bash
set -euoxv pipefail

cp private/kabustation/kabu-json-kabustation.pem ~/.ssh/
chmod 600 ~/.ssh/kabu-json-kabustation.pem
ip=$(cat private/kabustation/linux_ip.json)
windows_hostname=$(cat private/kabustation/windows_hostname.json)
echo "Host kabu-json-linux" > ~/.ssh/config.d/kabu-json-linux
echo "  HostName ${ip}" >> ~/.ssh/config.d/kabu-json-linux
echo "  User ec2-user" >> ~/.ssh/config.d/kabu-json-linux
echo "  IdentityFile ~/.ssh/kabu-json-kabustation.pem" >> ~/.ssh/config.d/kabu-json-linux
echo "  StrictHostKeyChecking no" >> ~/.ssh/config.d/kabu-json-linux
echo "  ServerAliveInterval 10" >> ~/.ssh/config.d/kabu-json-linux
echo "  ServerAliveCountMax 10" >> ~/.ssh/config.d/kabu-json-linux

echo "KABU_STATION_API_PROD_PASSWORD=${KABU_STATION_API_PROD_PASSWORD}" > private/kabustation/.env.linux
echo "KABU_COM_PASSWORD=${KABU_COM_PASSWORD}" >> private/kabustation/.env.linux
echo "WINDOWS_HOSTNAME=${windows_hostname}" >> private/kabustation/.env.linux

# 多段SSHはProxyJumpの方が好ましいが、ローカル端末抜きでLinuxがWindowsに常時接続、売買を実行してほしいので、秘密鍵含め各クレデンシャルをWindowsに持たせる
scp private/kabustation/kabu-json-kabustation.pem kabu-json-linux:~/.ssh/
ssh kabu-json-linux 'chmod 600 ~/.ssh/kabu-json-kabustation.pem;'
scp ~/.ssh/config.d/kabu-json-windows kabu-json-linux:~/.ssh/config
scp private/kabustation/.env.linux kabu-json-linux:~/.env.linux
ssh kabu-json-linux $@
