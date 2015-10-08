#!/bin/bash
#
# Make an image of the running gold master instance.

if [ -r ".env" ]; then
  . .env
else
  echo "Populate .env first."
  exit 1
fi

# find the gold master instance
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=tomcat7-gold-master" "Name=instance-state-name,Values=running" | jq -r '.Reservations[].Instances[].InstanceId')

# create the image
IMAGE_INDEX=$(aws ec2 describe-images --owners self | jq -r '.Images | map(select(.Name | startswith("tomcat7-master-"))) | sort_by(.Name) | last | .Name | ltrimstr("tomcat7-master-")')
let IMAGE_INDEX++

IMAGE_NAME="tomcat7-master-${IMAGE_INDEX}"

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

TERMINATED_INSTANCE_ID=$(aws ec2 terminate-instances --instance-ids $INSTANCE_ID | jq -d '.TerminatingInstances[].InstanceId')
echo $TERMINATED_INSTANCE_ID
