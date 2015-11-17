#!/bin/bash
THE_SCRIPT='/root/provision.sh'

LOGGER='logger -t [CLOUDINIT] -p user.info'

if [ -r "/etc/profile.d/aws-apitools-common.sh" ]; then
  . /etc/profile.d/aws-apitools-common.sh
fi

ZONE=$(ec2-metadata --availability-zone | awk '{print $2}')
REGION=$(echo "${ZONE}" | sed 's/[[:alpha:]]$//')
AWS="aws --region $REGION"

INSTANCE_ID=$(ec2-metadata --instance-id | awk '{print $2}')

$LOGGER "Bootstrapping instance ${INSTANCE_ID}"

TRIES=0
LIMIT=6

SOURCE="s3://rk-devops-${REGION}/jenkins/semaphores/${INSTANCE_ID}"
TARGET="$THE_SCRIPT"

while [ "$TRIES" -lt "$LIMIT" ]; do
  $LOGGER "Downloading '$TARGET' from '$SOURCE' [try $TRIES]"

  $AWS s3 cp "$SOURCE" "$TARGET" 2>/dev/null

  if [ -r "$THE_SCRIPT" ]; then
    $LOGGER "Download successful, executing '$THE_SCRIPT'"
    cd /root && chmod +x "$THE_SCRIPT" && /bin/bash -l -c "$THE_SCRIPT"
    exit
  else
    $LOGGER "No semaphore found, sleeping..."
    let TRIES++
    sleep 10
  fi
done

$LOGGER "No semaphore found before timeout, exiting."
exit 1
