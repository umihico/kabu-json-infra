#!/bin/bash
set -euoxv pipefail

aws s3 cp s3://kabu-json-private-static-data-bucket/.ssh/config.d/kabu-json-linux ~/.ssh/config.d/kabu-json-linux
ssh-keygen -R kabu-json-linux # IPが変わった場合に、~/.ssh/known_hostsから古い方を削除して、Man in the Middle Attack警告を不要に出さない

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
