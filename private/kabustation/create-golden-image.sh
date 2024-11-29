#!/bin/bash
set -euoxv pipefail

WINDOWS_INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=kabu-json-windows" "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].InstanceId' --output text)
LINUX_INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=kabu-json-linux" "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].InstanceId' --output text)
echo $WINDOWS_INSTANCE_ID
echo $LINUX_INSTANCE_ID
aws ec2 stop-instances --instance-ids ${WINDOWS_INSTANCE_ID}
aws ec2 stop-instances --instance-ids ${LINUX_INSTANCE_ID}
aws ec2 deregister-image --image-id $(aws ec2 describe-images --filters "Name=name,Values=kabu-json-windows-backup" --query 'Images[*].ImageId' --output text)
aws ec2 deregister-image --image-id $(aws ec2 describe-images --filters "Name=name,Values=kabu-json-linux-backup" --query 'Images[*].ImageId' --output text)
aws ec2 copy-image --name kabu-json-windows-backup --source-image-id $(aws ec2 describe-images --filters "Name=name,Values=kabu-json-windows" --query 'Images[*].ImageId' --output text) --source-region ap-northeast-1
aws ec2 copy-image --name kabu-json-linux-backup --source-image-id $(aws ec2 describe-images --filters "Name=name,Values=kabu-json-linux" --query 'Images[*].ImageId' --output text) --source-region ap-northeast-1
aws ec2 wait instance-stopped --instance-ids ${WINDOWS_INSTANCE_ID}
aws ec2 wait instance-stopped --instance-ids ${LINUX_INSTANCE_ID}
aws ec2 deregister-image --image-id $(aws ec2 describe-images --filters "Name=name,Values=kabu-json-windows" --query 'Images[*].ImageId' --output text)
aws ec2 deregister-image --image-id $(aws ec2 describe-images --filters "Name=name,Values=kabu-json-linux" --query 'Images[*].ImageId' --output text)
aws ec2 create-image --instance-id ${WINDOWS_INSTANCE_ID} --name "kabu-json-windows" --reboot
aws ec2 create-image --instance-id ${LINUX_INSTANCE_ID} --name "kabu-json-linux" --reboot
aws ec2 wait image-available --image-ids $(aws ec2 describe-images --filters "Name=name,Values=kabu-json-windows" --query 'Images[*].ImageId' --output text)
aws ec2 wait image-available --image-ids $(aws ec2 describe-images --filters "Name=name,Values=kabu-json-linux" --query 'Images[*].ImageId' --output text)
aws ec2 terminate-instances --instance-ids ${WINDOWS_INSTANCE_ID}
aws ec2 terminate-instances --instance-ids ${LINUX_INSTANCE_ID}
