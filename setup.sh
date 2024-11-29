#!/bin/bash
set -euoxv pipefail

terraform -chdir=private apply -auto-approve -var=instance_names=0
WINDOWS_INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=kabu-json-windows" "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].InstanceId' --output text)
LINUX_INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=kabu-json-linux" "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].InstanceId' --output text)
aws ec2 wait instance-status-ok --instance-ids ${WINDOWS_INSTANCE_ID} ${LINUX_INSTANCE_ID}
sh private/kabustation/ssh-windows.sh pwd
sh private/kabustation/ssh-linux.sh tmux new -d -s winssh ssh kabu-json-windows
