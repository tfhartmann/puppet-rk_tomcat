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
librarian-puppet install

echo "### Running Puppet agent..."
puppet apply --modulepath "modules:${HOME}" -e 'class { "rk_tomcat": }'

echo "### Disabling Puppet agent..."
puppet resource service puppet ensure=stopped enable=false
