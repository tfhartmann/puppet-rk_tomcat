#!/bin/bash
#
if [[ "${USER}" -ne 0 ]]; then
  echo "$0 must be run as root."
  exit 1
fi

# determine AWS region
AZ=$(ec2-metadata -z | awk '{print $2}')
REGION=$(echo "$AZ" | sed 's/[[:alpha:]]$//')

AWS="aws --region $REGION"

echo "### Deploying..."

echo "### Copying secrets..."
touch rk_tomcat/data/secrets.yaml \
  && chmod 600 rk_tomcat/data/secrets.yaml \
  && $AWS s3 cp s3://rk-devops-${REGION}/secrets/secrets.yaml rk_tomcat/data/secrets.yaml

if [ ! -r "rk_tomcat/data/secrets.yaml" ]; then
  echo "Populate the secrets.yaml file and then run $0 again."
  exit 0
fi

cd rk_tomcat

echo "### Running Puppet agent..."
puppet apply --hiera_config "/etc/hiera/hiera.yaml" --modulepath "$(pwd)/modules:/etc/puppetlabs/code/modules" -e 'class { "rk_tomcat": mode => "deploy" }'

echo "### Restarting Tomcat..."
service tomcat restart

echo "### Disabling Puppet agent..."
puppet resource service puppet ensure=stopped enable=false

echo "### Cleaning up..."
cd ..
rm -rf rk_tomcat
rm -rf /etc/puppetlabs/code/modules/*
yum clean all

echo "### Deploy complete."
