# kabuステーション用のWindows

## 接続方法

```bash
# インスタンス作成
terraform -chdir=private apply
# RDP
sh private/windows/rdp.sh
# SSH
sh private/windows/ssh.sh
```

## destroy

```bash
terraform -chdir=private destroy -target='module.windows.aws_instance.this'
```

## 初期設定、ゴールデンイメージの作成手順

- user_dataとamiを設定して、terraform apply
- 右サイドパネルのローカル Network を有効にするに yes
- 株ステーションをインストールする。ショートカットをデスクトップに作成する？に yes
- IDとパスワードを入力してログインする（IDは一度のみ入力して、次回からは記憶される、２回目のログインでパスワードを入力する必要がなくなりました、と表示される、以後は両方とも自動フィルされている）
- 右上歯車→右端のAPIタブ→APIを利用するにチェック→APIパスワードの本番用、検証用を設定→OK→指示通り一度アプリを閉じて再起動

## ゴールデンイメージの作成

```bash

INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=kabu-json-windows" "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].InstanceId' --output text)
echo $INSTANCE_ID
aws ec2 stop-instances --instance-ids ${INSTANCE_ID}
aws ec2 wait instance-stopped --instance-ids ${INSTANCE_ID}
aws ec2 deregister-image --image-id $(aws ec2 describe-images --filters "Name=name,Values=kabu-json-windows" --query 'Images[*].ImageId' --output text)
aws ec2 create-image --instance-id ${INSTANCE_ID} --name "kabu-json-windows" --reboot
aws ec2 wait image-available --image-ids $(aws ec2 describe-images --filters "Name=name,Values=kabu-json-windows" --query 'Images[*].ImageId' --output text)
```
