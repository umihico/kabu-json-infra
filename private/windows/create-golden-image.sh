#!/bin/bash
set -euoxv pipefail

INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=kabu-json-windows" "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].InstanceId' --output text)
echo $INSTANCE_ID
aws ec2 stop-instances --instance-ids ${INSTANCE_ID}
aws ec2 wait instance-stopped --instance-ids ${INSTANCE_ID}
aws ec2 deregister-image --image-id $(aws ec2 describe-images --filters "Name=name,Values=kabu-json-windows" --query 'Images[*].ImageId' --output text)
aws ec2 create-image --instance-id ${INSTANCE_ID} --name "kabu-json-windows" --reboot
aws ec2 wait image-available --image-ids $(aws ec2 describe-images --filters "Name=name,Values=kabu-json-windows" --query 'Images[*].ImageId' --output text)
