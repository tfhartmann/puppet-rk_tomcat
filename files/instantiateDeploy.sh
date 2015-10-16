#!/bin/bash
#
# Spin up an instance to make a new deploy image.

if [ -r ".env" ]; then
  . .env
else
  echo "Populate .env first."
  exit 1
fi

echo "Starting instance for '$BUILD_TARGET' image."

# create instance
GOLD_MASTER_AMI=$(aws ec2 describe-images --owners self | jq -r '.Images | map(select(.Name | startswith("tomcat7-master-"))) | sort_by(.CreationDate) | last | .ImageId')

INSTANCE_DATA=$(aws ec2 run-instances \
  --image-id "$GOLD_MASTER_AMI" \
  --key-name "$BUILD_SSH_KEYPAIR" \
  --security-group-ids "$BUILD_SECURITY_GROUP" \
  --instance-type "$BUILD_INSTANCE_TYPE" \
  --subnet-id "$BUILD_SUBNET" \
  --iam-instance-profile "Name=${BUILD_PROFILE_NAME}")

INSTANCE_ID=$(echo $INSTANCE_DATA | jq -r '.Instances[].InstanceId')
sleep 5

# tag instance
IMAGE_INDEX=$(aws ec2 describe-images --owners self | jq -r ".Images | map(select(.Name | startswith(\"tomcat7-${BUILD_TARGET}-\"))) | sort_by(.CreationDate) | last | .Name | ltrimstr(\"tomcat7-${BUILD_TARGET}-\")")
let IMAGE_INDEX++
aws ec2 create-tags --resources $INSTANCE_ID --tags "Key=Name,Value=tomcat7-${BUILD_TARGET}-${IMAGE_INDEX}"

echo $INSTANCE_ID
INSTANCE_HOSTNAME=''

# wait for hostname
while [ -z "$INSTANCE_HOSTNAME" ]; do
  sleep 2
  INSTANCE_HOSTNAME=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID | jq -r '.Reservations[].Instances[].PrivateDnsName')

  if [ "$INSTANCE_HOSTNAME" = "null" ]; then
    INSTANCE_HOSTNAME=''
  fi
done

# wait for the instance to be up
INSTANCE_STATE=''
while [ "$INSTANCE_STATE" != 'running' ]; do
  sleep 2
  INSTANCE_STATE=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID | jq -r '.Reservations[].Instances[].State.Name')
done

echo $INSTANCE_HOSTNAME
