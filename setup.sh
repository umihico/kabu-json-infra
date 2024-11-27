#!/bin/bash
set -euoxv pipefail

terraform -chdir=private apply -auto-approve -var=instance_names=0
sleep 30 # インスタンスが立ち上がるまで待つ
sh private/kabustation/ssh-windows.sh pwd
sh private/kabustation/ssh-linux.sh tmux new -d -s winssh ssh kabu-json-windows
sh private/kabustation/rdp.sh
sh private/kabustation/ssh-linux.sh
