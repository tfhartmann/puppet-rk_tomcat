#!/bin/bash
#
# Make an image of the running deploy instance.

if [ -r ".env" ]; then
  . .env
else
  echo "Populate .env first."
  exit 1
fi

# create the image
GOLD_MASTER_AMI=$(aws ec2 describe-images --owners self | jq -r '.Images | map(select(.Name | startswith("tomcat7-master-"))) | sort_by(.CreationDate) | last | .ImageId')

INSTANCE_DATA=$(aws ec2 describe-instances --filters "Name=image-id,Values=${GOLD_MASTER_AMI}" "Name=instance-state-name,Values=running")
INSTANCE_ID=$(echo "$INSTANCE_DATA" | jq -r '.Reservations[].Instances[].InstanceId')
IMAGE_NAME=$(echo "$INSTANCE_DATA" | jq -r '.Reservations[].Instances[].Tags | from_entries | .Name')

IMAGE_ID=$(aws ec2 create-image --instance-id $INSTANCE_ID --name $IMAGE_NAME --reboot | jq -r '.ImageId')
echo $IMAGE_ID

if [ -z "$IMAGE_ID" ]; then
  exit 1
fi

IMAGE_STATE=''
while [ "$IMAGE_STATE" != "available" ]; do
  sleep 2
  IMAGE_STATE=$(aws ec2 describe-images --image-ids $IMAGE_ID --owners self | jq -r '.Images[].State')
done
echo $IMAGE_STATE

TERMINATED_INSTANCE_ID=$(aws ec2 terminate-instances --instance-ids $INSTANCE_ID | jq -r '.TerminatingInstances[].InstanceId')
echo $TERMINATED_INSTANCE_ID
