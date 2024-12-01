#!/bin/bash
set -euoxv pipefail


WINDOWS_INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=kabu-json-windows" "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].InstanceId' --output text)
LINUX_INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=kabu-json-linux" "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].InstanceId' --output text)
aws ec2 wait instance-status-ok --instance-ids ${WINDOWS_INSTANCE_ID} ${LINUX_INSTANCE_ID}

WINDOWS_INTERNAL_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=kabu-json-windows" "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)
echo "Host kabu-json-windows" > ~/.ssh/config.d/kabu-json-windows
# hostnameにしておくと外からはパブリックIPで中からはプライベートIPで接続できる
echo "  HostName ${WINDOWS_INTERNAL_IP}" >> ~/.ssh/config.d/kabu-json-windows
echo "  RequestTTY no" >> ~/.ssh/config.d/kabu-json-windows
echo "  User Administrator" >> ~/.ssh/config.d/kabu-json-windows
echo "  IdentityFile ~/.ssh/kabu-json-kabustation.pem" >> ~/.ssh/config.d/kabu-json-windows
echo "  StrictHostKeyChecking no" >> ~/.ssh/config.d/kabu-json-windows
echo "  LocalForward 3389 localhost:3389" >> ~/.ssh/config.d/kabu-json-windows
echo "  LocalForward 18080 localhost:18080" >> ~/.ssh/config.d/kabu-json-windows
echo "  LocalForward 18081 localhost:18081" >> ~/.ssh/config.d/kabu-json-windows
echo "  ServerAliveInterval 10" >> ~/.ssh/config.d/kabu-json-windows
echo "  ServerAliveCountMax 10" >> ~/.ssh/config.d/kabu-json-windows

LINUX_PUBLIC_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=kabu-json-linux" "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)
echo "Host kabu-json-linux" > ~/.ssh/config.d/kabu-json-linux
echo "  HostName ${LINUX_PUBLIC_IP}" >> ~/.ssh/config.d/kabu-json-linux
echo "  User ec2-user" >> ~/.ssh/config.d/kabu-json-linux
echo "  IdentityFile ~/.ssh/kabu-json-kabustation.pem" >> ~/.ssh/config.d/kabu-json-linux
echo "  RequestTTY yes" >> ~/.ssh/config.d/kabu-json-linux # forceにするとrsyncがコケるようになった: protocol version mismatch -- is your shell clean? rsync error: protocol incompatibility (code 2) at compat.c(626) [sender=3.3.0]
echo "  StrictHostKeyChecking no" >> ~/.ssh/config.d/kabu-json-linux
echo "  ServerAliveInterval 10" >> ~/.ssh/config.d/kabu-json-linux
echo "  ServerAliveCountMax 10" >> ~/.ssh/config.d/kabu-json-linux
echo "  LocalForward 18080 localhost:18080" >> ~/.ssh/config.d/kabu-json-linux
echo "  LocalForward 18081 localhost:18081" >> ~/.ssh/config.d/kabu-json-linux
echo "  LocalForward 3389 ${WINDOWS_INTERNAL_IP}:3389" >> ~/.ssh/config.d/kabu-json-linux
scp ~/.ssh/config.d/kabu-json-windows kabu-json-linux:~/.ssh/config

# イメージがリセットされたら、秘密鍵を再度設定する必要がある
# 多段SSHはProxyJumpの方が好ましいが、ローカル端末抜きでLinuxがWindowsに常時接続、売買を実行してほしいので、秘密鍵含め各クレデンシャルをWindowsに持たせる
# echo "KABU_STATION_API_PROD_PASSWORD=${KABU_STATION_API_PROD_PASSWORD}" > private/kabustation/.env.linux
# echo "KABU_COM_PASSWORD=${KABU_COM_PASSWORD}" >> private/kabustation/.env.linux
# echo "WINDOWS_HOSTNAME=${WINDOWS_INTERNAL_IP}" >> private/kabustation/.env.linux
# scp private/kabustation/kabu-json-kabustation.pem kabu-json-linux:~/.ssh/
# ssh kabu-json-linux 'chmod 600 ~/.ssh/kabu-json-kabustation.pem;'
# scp private/kabustation/.env.linux kabu-json-linux:~/.env.linux



# 公開鍵を変更してしまうと、以下のエラーがでるため、ユーザーデータを参考に再度公開鍵を設定し、ゴールデンイメージにして固める
# Permission denied (publickey,keyboard-interactive)
# 以下のコマンドをRDPしてPowerShellで実行する
# $administratorsKeyPath = Join-Path $env:ProgramData 'ssh\administrators_authorized_keys'
# $params = @{
#     Headers = @{
#         "X-aws-ec2-metadata-token" = Invoke-RestMethod 'http://169.254.169.254/latest/api/token' -Method Put -Headers @{ "X-aws-ec2-metadata-token-ttl-seconds" = 60 }
#     }
#     Uri     = 'http://169.254.169.254/latest/meta-data/public-keys/0/openssh-key/'
# }
# Invoke-RestMethod @params | Out-File -FilePath $administratorsKeyPath -Encoding ascii
