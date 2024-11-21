# kabuステーション用のWindows

## 接続方法

```bash
# インスタンス作成（引数付与して作成）
terraform -chdir=private apply -var=instance_names=0
# RDP
sh private/windows/rdp.sh
# SSH
sh private/windows/ssh.sh
```

## destroy

```bash
# 引数無しで削除
terraform -chdir=private apply
```

## 初期設定、ゴールデンイメージの作成手順

- user_dataとamiを設定して、terraform apply
- 右サイドパネルのローカル Network を有効にするに yes
- 株ステーションをインストールする。ショートカットをデスクトップに作成する？に yes
- IDとパスワードを入力してログインする（IDは一度のみ入力して、次回からは記憶される、２回目のログインでパスワードを入力する必要がなくなりました、と表示される、以後は両方とも自動フィルされている）
- 右上歯車→右端のAPIタブ→APIを利用するにチェック→APIパスワードの本番用、検証用を設定→OK→指示通り一度アプリを閉じて再起動
- C:\Users\Administrator\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startupへのショートカットをデスクトップに作成して、その中に
kabuステーションのショートカットを入れておく
- powershellから`wsl --install`

## ゴールデンイメージの作成

```bash
sh private/windows/create-golden-image.sh
```
