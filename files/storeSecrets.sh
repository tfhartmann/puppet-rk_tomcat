#!/bin/sh
#
# Copy the local secrets.yaml file to S3.

SECRETS_FILE='data/secrets.yaml'
REGION='us-east-1'
TARGET="rk-devops-${REGION}/secrets/secrets.yaml"

if [ ! -r "$SECRETS_FILE" ]; then
  echo "Unable to read '$SECRETS_FILE', exiting."
  exit 1
fi

aws s3 cp $SECRETS_FILE $TARGET
