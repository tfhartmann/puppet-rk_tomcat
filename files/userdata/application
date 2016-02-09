#!/bin/bash -l
THE_SCRIPT='/root/deploy.sh'

export PATH="/usr/local/bin:${PATH}"

LOGGER='logger -t [CLOUDINIT] -p user.info'

if [ -r "/etc/profile.d/aws-apitools-common.sh" ]; then
  . /etc/profile.d/aws-apitools-common.sh
fi

AZ=$(ec2-metadata --availability-zone | awk '{print $2}')
REGION=$(echo "${AZ}" | sed 's/[[:alpha:]]$//')
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
    cd $(dirname "$THE_SCRIPT") && chmod +x "$THE_SCRIPT" && "$THE_SCRIPT" > "${THE_SCRIPT}.log" 2>&1
    exit
  else
    $LOGGER "No semaphore found, sleeping..."
    let TRIES++
    sleep 10
  fi
done

$LOGGER "No semaphore found before timeout, exiting."
exit 1
