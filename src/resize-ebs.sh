#!/bin/bash

# exit when any command fails
set -e

echo Resizing EBS volume to 16 GB...
EC2_INSTANCE_ID="`wget -q -O - http://169.254.169.254/latest/meta-data/instance-id || die \"wget instance-id has failed: $?\"`"
VOLUME_ID="`aws ec2 describe-volumes  --filters Name=attachment.device,Values=/dev/xvda Name=attachment.instance-id,Values=$EC2_INSTANCE_ID --query 'Volumes[*].{ID:VolumeId}' --output text`"
aws ec2 modify-volume --volume-id $VOLUME_ID --size 16

echo Growing partition...
sudo growpart /dev/nvme0n1 1

echo Resizing filesystem...
sudo resize2fs /dev/nvme0n1p1

echo Resize complete:
df -h