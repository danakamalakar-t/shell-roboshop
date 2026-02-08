#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-08ae1eafe91ce777b" # replace with your

for instance in $@ # mongodb redis mysql
do
    INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --security-group-ids $SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query 'Instances[0].InstanceId' --output text)
    echo "Launched $instance with Instance ID: $INSTANCE_ID"
    # Get Private IP
    if [ $instance != "frontend" ]; then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
        echo "$instance: $IP (Private IP)"
    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
        echo "$instance: $IP (Public IP)"
    fi

   
done