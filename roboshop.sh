#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-08ae1eafe91ce777b"

for instance in $@
do
INSTANCE_ID=$(aws ec2 run-instances   --image-id $AMI_ID   
--instance-type t2.micro --security-group-ids $SG_ID   
--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value='$instance'}]' 
--query "Instances[0].InstanceId"   --output text)
echo "Launched Instance ID: $INSTANCE_ID for $instance"

if [$instance != "frontend"]
then
PRIVATE_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query "Reservations[0].Instances[0].PrivateIpAddress" \
  --output text)
echo "$instance: $PRIVATE_IP"
else
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text)

echo "$instance: $PUBLIC_IP"
done

