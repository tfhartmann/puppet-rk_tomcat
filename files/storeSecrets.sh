#!/bin/sh
#
# Copy the local secrets.yaml file to S3.
REGION='us-east-1'

SCRIPTNAME=$(basename "$0")

if [ -n "$1" ]; then
  TAG="-${1}"
else
  TAG=""
fi

if [ "$SCRIPTNAME" = 'storeSecrets.sh' ]; then
  ACTION='store'
  OBJECT='secrets'
elif [ "$SCRIPTNAME" = 'getSecrets.sh' ]; then
  ACTION='get'
  OBJECT='secrets'
elif [ "$SCRIPTNAME" = 'storeFixtures.sh' ]; then
  ACTION='store'
  OBJECT='fixtures'
elif [ "$SCRIPTNAME" = 'getFixtures.sh' ]; then
  ACTION='get'
  OBJECT='fixtures'
else
  echo "'$SCRIPTNAME' is not an invocation I understand."
  exit 1
fi

if [ "$OBJECT" = "secrets" ]; then
  SUFFIX='yaml'
elif [ "$OBJECT" = "fixtures" ]; then
  SUFFIX='sql'
else
  echo "'$OBJECT' is not an object I understand."
  exit 1
fi

FILENAME="${OBJECT}${TAG}.${SUFFIX}"

LOCAL="data/${FILENAME}"
REMOTE="s3://rk-devops-${REGION}/${OBJECT}/${FILENAME}"

if [[ ("$ACTION" = "store") && (! -r "$LOCAL") ]]; then
  echo "Unable to read '$LOCAL', exiting."
  exit 1
fi

if [ "$ACTION" = "store" ]; then
  SOURCE="$LOCAL"
  TARGET="$REMOTE"
elif [ "$ACTION" = "get" ]; then
  SOURCE="$REMOTE"
  TARGET="$LOCAL"
else
  echo "'$ACTION' is not an action I understand."
  exit 1
fi

aws s3 cp $SOURCE $TARGET
