#!/bin/bash
set -euoxv pipefail

cp private/kabustation/kabu-json-kabustation.pem ~/.ssh/
chmod 600 ~/.ssh/kabu-json-kabustation.pem
windows_hostname=$(cat private/kabustation/windows_hostname.json)
echo "Host kabu-json-windows" > ~/.ssh/config.d/kabu-json-windows
# hostnameにしておくと外からはパブリックIPで中からはプライベートIPで接続できる
echo "  HostName ${windows_hostname}" >> ~/.ssh/config.d/kabu-json-windows
echo "  RequestTTY no" >> ~/.ssh/config.d/kabu-json-windows
echo "  User Administrator" >> ~/.ssh/config.d/kabu-json-windows
echo "  IdentityFile ~/.ssh/kabu-json-kabustation.pem" >> ~/.ssh/config.d/kabu-json-windows
echo "  StrictHostKeyChecking no" >> ~/.ssh/config.d/kabu-json-windows
echo "  LocalForward 3389 localhost:3389" >> ~/.ssh/config.d/kabu-json-windows
echo "  LocalForward 18080 localhost:18080" >> ~/.ssh/config.d/kabu-json-windows
echo "  LocalForward 18081 localhost:18081" >> ~/.ssh/config.d/kabu-json-windows
echo "  ServerAliveInterval 10" >> ~/.ssh/config.d/kabu-json-windows
echo "  ServerAliveCountMax 10" >> ~/.ssh/config.d/kabu-json-windows

ssh kabu-json-windows $@
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
