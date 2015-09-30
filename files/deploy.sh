#!/bin/bash
#
if [[ "${USER}" -ne 0 ]]; then
  echo "$0 must be run as root."
  exit 1
fi

echo "### Deploying..."

cd rk_tomcat

echo "### Running Puppet agent..."
puppet apply --hiera_config "/etc/hiera/hiera.yaml" --modulepath "$(pwd)/modules:/etc/puppetlabs/code/modules" -e 'class { "rk_tomcat": mode => "deploy" }'

echo "### Disabling Puppet agent..."
puppet resource service puppet ensure=stopped enable=false

echo "### Cleaning up..."
cd ..
rm -rf rk_tomcat
rm -rf /etc/puppetlabs/code/modules/*
yum clean all

echo "### Deploy complete."
