# 【株JSON】 データ保存・配信用インフラ

AWS x Terraform

暫定URL: https://d1rrtoo3h22gy6.cloudfront.net/

## トラブルシューティング

### AMIイメージをロストした際の復旧手順

TerraformでEC2インスタンスを起動する際、カスタムAMI（`kabu-json-windows`、`kabu-json-linux`）が見つからない場合は、バックアップAMIから復旧します。

#### 1. バックアップAMIの確認

```bash
# バックアップAMIの一覧表示
aws ec2 describe-images \
  --owners self \
  --filters "Name=name,Values=kabu-json-*-backup" \
  --query 'Images[*].[ImageId,Name,State,CreationDate]' \
  --output table

# バックアップAMIのIDを変数に格納
WINDOWS_BACKUP_AMI=$(aws ec2 describe-images \
  --owners self \
  --filters "Name=name,Values=kabu-json-windows-backup" \
  --query 'Images[0].ImageId' \
  --output text)

LINUX_BACKUP_AMI=$(aws ec2 describe-images \
  --owners self \
  --filters "Name=name,Values=kabu-json-linux-backup" \
  --query 'Images[0].ImageId' \
  --output text)

echo "Windows Backup AMI: $WINDOWS_BACKUP_AMI"
echo "Linux Backup AMI: $LINUX_BACKUP_AMI"
```

#### 2. バックアップからAMIをコピー

```bash
# Windows AMIをコピー
aws ec2 copy-image \
  --source-image-id $WINDOWS_BACKUP_AMI \
  --source-region ap-northeast-1 \
  --region ap-northeast-1 \
  --name "kabu-json-windows" \
  --description "Copied from kabu-json-windows-backup"

# Linux AMIをコピー
aws ec2 copy-image \
  --source-image-id $LINUX_BACKUP_AMI \
  --source-region ap-northeast-1 \
  --region ap-northeast-1 \
  --name "kabu-json-linux" \
  --description "Copied from kabu-json-linux-backup"
```

#### 3. コピー完了の確認

```bash
# コピー状態の確認（pendingからavailableになるまで待機）
aws ec2 describe-images \
  --owners self \
  --filters "Name=name,Values=kabu-json-windows,kabu-json-linux" \
  --query 'Images[*].[ImageId,Name,State]' \
  --output table

# 定期的に状態を監視
watch -n 10 'aws ec2 describe-images \
  --owners self \
  --filters "Name=name,Values=kabu-json-windows,kabu-json-linux" \
  --query "Images[*].[Name,State]" \
  --output table'
```

#### 4. Terraformの再実行

AMIが`available`状態になったら、Terraformを再実行できます：

```bash
terraform -chdir=private apply -var=instance_names=0
```
