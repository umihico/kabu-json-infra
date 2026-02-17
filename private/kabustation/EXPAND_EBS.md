# EBSボリューム容量増強手順

kabu-json-windowsインスタンスのディスク容量が不足した場合の対処手順。

## 現状確認

## 容量増強手順

### 1. 事前確認

```bash
# インスタンスIDとボリュームID取得
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=kabu-json-windows" \
  --query 'Reservations[0].Instances[0].[InstanceId,BlockDeviceMappings[0].Ebs.VolumeId]' \
  --output text

# 現在のボリュームサイズ確認
aws ec2 describe-volumes --volume-ids <VOLUME_ID> \
  --query 'Volumes[0].[Size,State,VolumeType]' \
  --output table
```

### 2. EBSボリューム拡張（起動中でも可能）

```bash
# 例: 60GB → 80GB に拡張
aws ec2 modify-volume --volume-id <VOLUME_ID> --size 80
```

### 3. 拡張完了確認

```bash
# 状態確認（optimizing または completed になるまで待つ）
aws ec2 describe-volumes-modifications --volume-ids <VOLUME_ID> \
  --query 'VolumesModifications[0].ModificationState' \
  --output text
```

### 4. Windows側でパーティション拡張

```powershell
# SSH経由でWindows PowerShellコマンド実行
ssh kabu-json-windows "Resize-Partition -DriveLetter C -Size (Get-PartitionSupportedSize -DriveLetter C).SizeMax"

# 確認
ssh kabu-json-windows "Get-PSDrive -PSProvider FileSystem | Where-Object Name -eq 'C' | Select-Object Name, @{Name='UsedGB';Expression={\$_.Used/1GB}}, @{Name='FreeGB';Expression={\$_.Free/1GB}}"
```

### 5. WSL側確認（自動拡張される）

```bash
# WSL内で確認
ssh kabu-json-windows "wsl -d Ubuntu -- df -h /mnt/c"
```

## 新しいAMIへの反映

容量変更後、新しいAMIを作成すれば拡張後のサイズが焼き込まれる：

```bash
# 既存AMIの登録解除（バックアップ取得後）
aws ec2 deregister-image --image-id <OLD_AMI_ID>

# 新しいAMI作成
aws ec2 create-image \
  --instance-id <INSTANCE_ID> \
  --name "kabu-json-windows" \
  --description "Windows Server with 80GB EBS"
```

次回インスタンス起動時は、新しいAMIのサイズ（80GB）で自動的に起動する。

## 注意事項

- EBSボリュームは**拡張のみ可能**（縮小不可）
- 起動中のインスタンスでも拡張可能（ダウンタイムなし）
- Windows側のパーティション拡張は**必須**（自動では拡張されない）
- WSLは自動的に拡張された領域を認識する

## 所要時間

- EBSボリューム拡張: 数秒～1分
- パーティション拡張: 数秒
- 合計: **2-3分程度**