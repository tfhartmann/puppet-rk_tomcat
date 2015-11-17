#!/bin/bash
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
REGION=$($LOGGER "$AZ" | sed 's/[[:alpha:]]$//')

AWS="aws --region $REGION"

$LOGGER "Deploying..."

$LOGGER "Copying secrets..."
for i in 'secrets' 'secrets-common'; do
  touch "rk_tomcat/data/${i}.yaml" \
    && chmod 600 "rk_tomcat/data/${i}.yaml" \
    && $AWS s3 cp "s3://rk-devops-${REGION}/secrets/${i}.yaml" "rk_tomcat/data/${i}.yaml"
done

if [ ! -r "rk_tomcat/data/secrets.yaml" ]; then
  $LOGGER "Populate the secrets.yaml file and then run $0 again."
  exit 0
fi

cd rk_tomcat

$LOGGER "Running Puppet agent..."
puppet apply \
  --hiera_config "/etc/hiera/hiera.yaml" \
  --modulepath "$(pwd)/modules:/etc/puppetlabs/code/modules" \
  --verbose \
  --logdest syslog \
  -e 'class { "rk_tomcat": mode => "deploy" }' || exit 1

$LOGGER "Disabling Puppet agent..."
puppet resource service puppet ensure=stopped enable=false

$LOGGER "Removing semaphore..."
$AWS s3 rm "s3://rk-devops-${REGION}/jenkins/semaphores/${INSTANCE_ID}" 2>/dev/null || true

$LOGGER "Cleaning up..."
cd ..
rm -rf rk_tomcat
rm -rf /etc/puppetlabs/code/modules/*
yum clean all

$LOGGER "Deploy complete."
