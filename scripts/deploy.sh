#!/bin/bash
#
if [[ "${USER}" -ne 0 ]]; then
  echo "$0 must be run as root."
  exit 1
fi

echo "### Patching system..."
yum -y update

echo "### Uninstalling upstream Puppet..."
yum -y erase puppet

echo "### Installing git..."
yum -y install git

cd ~

echo "### Cloning Tomcat platform configuration..."
git clone https://github.com/FitnessKeeper/puppet-rk_tomcat.git rk_tomcat

cd rk_tomcat

echo "### Configuring RubyGems..."
yum -y install ruby-devel glibc-devel gcc
cat > /root/.gemrc << 'GEMRC'
---
install: --nodocument --bindir /usr/local/bin
GEMRC

echo "### Installing Bundler..."
gem install io-console bundler

echo "### Installing other gem dependencies..."
bundle install

echo "### Installing Puppet dependencies..."
puppet module install ripienaar-module_data
librarian-puppet install
ln -s /root/rk_tomcat /etc/puppet/code/modules/rk_tomcat

echo "### Running Puppet agent..."
mkdir -p /etc/hiera
cat > /etc/hiera/hiera.yaml << 'HIERA'
---
:backends:
  - module_data
HIERA
puppet apply --hiera_config "/etc/hiera/hiera.yaml" --modulepath "$(pwd)/modules:/etc/puppetlabs/code/modules" -e 'class { "rk_tomcat": }'

echo "### Disabling Puppet agent..."
puppet resource service puppet ensure=stopped enable=false
