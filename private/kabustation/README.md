# kabuステーション用のWindows

## 接続方法

```bash
# インスタンス作成（引数付与して作成）
terraform -chdir=private apply -var=instance_names=0
# RDP
sh private/kabustation/rdp.sh
# SSH
sh private/kabustation/ssh.sh
```

## destroy

```bash
# 引数無しで削除
terraform -chdir=private apply
```

## 初期設定、ゴールデンイメージの作成手順

### Windows

- user_dataとamiを設定して、terraform apply
- 右サイドパネルのローカル Network を有効にするに yes
- 株ステーションをインストールする。ショートカットをデスクトップに作成する？に yes
- IDとパスワードを入力してログインする（IDは一度のみ入力して、次回からは記憶される、２回目のログインでパスワードを入力する必要がなくなりました、と表示される、以後は両方とも自動フィルされている）
- 右上歯車→右端のAPIタブ→APIを利用するにチェック→APIパスワードの本番用、検証用を設定→OK→指示通り一度アプリを閉じて再起動
- C:\Users\Administrator\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startupへのショートカットをデスクトップに作成して、その中に
kabuステーションのショートカットを入れておく
- `Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))`
- `choco install -y python3`
- `pip install pyautogui` (Powershellでなく、cmdで実行しないとエラーした)
- `scp private/kabustation/login.py kabu-json-windows:"C:/Users/Administrator/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/login.py"`

### Linux

- `sudo dnf -y install redis6 tmux python3.11 python3.11-pip`
- `echo "alias py=python3.11" >> .bashrc`
- `echo "alias pip=pip3.11" >> .bashrc`
- `echo "alias redis-cli=redis6-cli" >> .bashrc`
- `sudo systemctl enable redis6`
- `sudo systemctl start redis6`
- `pip install -r requirements.txt`

## ゴールデンイメージの作成

```bash
sh private/kabustation/create-golden-image.sh
```
