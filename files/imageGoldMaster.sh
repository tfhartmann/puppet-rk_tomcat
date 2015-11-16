#!/bin/bash
#
# Make an image of the running gold master instance.
if [ -r "/etc/profile.d/aws-apitools-common.sh" ]; then
  . /etc/profile.d/aws-apitools-common.sh
fi

if [ -r ".env" ]; then
  . .env
else
  echo "Populate .env first."
  exit 1
fi

# determine region
if [ -z "$REGION" ]; then
  REGION=us-east-1
fi

AWS="aws --region $REGION"

if [ -z "$INSTANCE_ID" ]; then
  echo "Querying AWS to determine gold master instance."
  # find the gold master instance
  INSTANCE_ID=$($AWS ec2 describe-instances --filters "Name=tag:Name,Values=tomcat7-gold-master" "Name=instance-state-name,Values=running" | jq -r '.Reservations[].Instances[].InstanceId')
fi

if [ -z "$INSTANCE_ID" ]; then
  echo "Unable to determine gold master instance ID, exiting."
  exit 1
fi

# create the image
IMAGE_INDEX=$($AWS ec2 describe-images --owners self | jq -r '.Images | map(select(.Name | startswith("tomcat7-master-"))) | sort_by(.CreationDate) | last | .Name | ltrimstr("tomcat7-master-")')
let IMAGE_INDEX++

IMAGE_NAME="tomcat7-master-${IMAGE_INDEX}"

IMAGE_ID=$($AWS ec2 create-image --instance-id $INSTANCE_ID --name $IMAGE_NAME --reboot | jq -r '.ImageId')
echo $IMAGE_ID

if [ -z "$IMAGE_ID" ]; then
  exit 1
fi

IMAGE_STATE=''
while [ "$IMAGE_STATE" != "available" ]; do
  sleep 2
  IMAGE_STATE=$($AWS ec2 describe-images --image-ids $IMAGE_ID --owners self | jq -r '.Images[].State')
done
echo $IMAGE_STATE

TERMINATED_INSTANCE_ID=$($AWS ec2 terminate-instances --instance-ids $INSTANCE_ID | jq -r '.TerminatingInstances[].InstanceId')

# save state for the next script
echo > $STATE <<STATE
IMAGE_ID=$IMAGE_ID
STATE
