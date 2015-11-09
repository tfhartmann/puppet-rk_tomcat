#!/bin/sh
#
# Copy the local secrets.yaml file to S3.

SECRETS_FILE='data/secrets.yaml'
REGION='us-east-1'

if [ ! -r "$SECRETS_FILE" ]; then
  echo "Unable to read '$SECRETS_FILE', exiting."
  exit 1
fi

if [ -n "$1" ]; then
  TAG="$1"
  TARGET_FILE="secrets-${TAG}.yaml"
else
  TARGET_FILE="secrets.yaml"
fi

TARGET="s3://rk-devops-${REGION}/secrets/${TARGET_FILE}"

aws s3 cp $SECRETS_FILE $TARGET
