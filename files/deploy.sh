#!/bin/bash -l
#
LOGGER='logger -t [CLOUDINIT] -p user.info'

if [[ "${USER}" -ne 0 ]]; then
  $LOGGER "$0 must be run as root."
  exit 1
fi

if [ -r "/etc/profile.d/aws-apitools-common.sh" ]; then
  . /etc/profile.d/aws-apitools-common.sh
fi

INSTANCE_ID=$(ec2-metadata -i | awk '{print $2}')
# determine AWS region
AZ=$(ec2-metadata -z | awk '{print $2}')
REGION=$(echo "$AZ" | sed 's/[[:alpha:]]$//')

AWS="aws --region $REGION"

INSTANCE_NAME=$($AWS ec2 describe-tags --filters "Name=resource-id,Values=${INSTANCE_ID}" | jq -r '.Tags | map(select(.Key == "Name"))[] | .Value')

LOGGER="logger -t ${INSTANCE_NAME} -p daemon.info"

$LOGGER "Deploying..."

$LOGGER "Copying secrets..."
for i in 'secrets' 'secrets-common'; do
  touch "rk_tomcat/data/${i}.yaml" \
    && chmod 600 "rk_tomcat/data/${i}.yaml"
done
$AWS s3 cp "s3://rk-devops-${REGION}/secrets/secrets-common.yaml" "rk_tomcat/data/secrets-common.yaml"
$AWS s3 cp "s3://rk-devops-${REGION}/secrets/instances/${INSTANCE_ID}.yaml" "rk_tomcat/data/secrets.yaml"

if [ ! -r "rk_tomcat/data/secrets.yaml" ]; then
  $LOGGER "Populate the secrets.yaml file and then run $0 again."
  exit 0
fi

cd rk_tomcat

$LOGGER "Running Puppet agent..."
PUPPET_LOGDIR=/var/log/puppet
PUPPET=$(which puppet 2>/dev/null || echo '/usr/local/bin/puppet')
$PUPPET apply \
  --hiera_config "/etc/hiera/hiera.yaml" \
  --modulepath "$(pwd)/modules:/etc/puppetlabs/code/modules" \
  --logdest "${PUPPET_LOGDIR}/deploy.log" \
  -e 'class { "rk_tomcat": mode => "deploy" }'

if [ -r "${PUPPET_LOGDIR}/deploy.log" ]; then
  $LOGGER "Uploading deploy log to S3..."
  $AWS s3 cp "${PUPPET_LOGDIR}/deploy.log" "s3://rk-devops-${REGION}/jenkins/logs/${INSTANCE_NAME}/deploy.log"
else
  $LOGGER "No deploy log found."
fi

$LOGGER "Disabling Puppet agent..."
$PUPPET resource service puppet ensure=stopped enable=false

# pull PostgreSQL client cert from S3
POSTGRES_CERTDIR='/home/tomcat/.postgresql'
if [ -d "$POSTGRES_CERTDIR" ]; then
  $LOGGER "Copying PostgreSQL client certificates to $POSTGRES_CERTDIR..."
  $AWS s3 sync "s3://rk-devops-${REGION}/secrets/client_certs" "$POSTGRES_CERTDIR" \
    && chmod 600 "${POSTGRES_CERTDIR}/*" \
    && chown -R tomcat:tomcat "$POSTGRES_CERTDIR"
else
  $LOGGER "Directory $POSTGRES_CERTDIR not present, not copying PostgreSQL client certificates."
fi

$LOGGER "Removing semaphore..."
$AWS s3 rm "s3://rk-devops-${REGION}/jenkins/semaphores/${INSTANCE_ID}" 2>/dev/null || true

$LOGGER "Cleaning up..."
$AWS s3 rm "s3://rk-devops-${REGION}/secrets/instances/${INSTANCE_ID}.yaml"
cd ..
rm -rf rk_tomcat
rm -rf /etc/puppetlabs/code/modules/*
yum clean all

$LOGGER "Deploy complete."
