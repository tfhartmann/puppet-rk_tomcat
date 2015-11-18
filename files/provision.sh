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

$LOGGER "Provisioning..."

$LOGGER "Patching system..."
yum -y update

$LOGGER "Uninstalling upstream Puppet..."
yum -y erase puppet

$LOGGER "Installing utilities..."
yum -y install git jq

cd ~

$LOGGER "Cloning Tomcat platform configuration..."
git clone https://github.com/FitnessKeeper/puppet-rk_tomcat.git rk_tomcat

$LOGGER "Copying secrets..."
# only copy secrets-common to gold master image
for i in 'secrets-common'; do
  touch "rk_tomcat/data/${i}.yaml" \
    && chmod 600 "rk_tomcat/data/${i}.yaml" \
    && $AWS s3 cp "s3://rk-devops-${REGION}/secrets/${i}.yaml" "rk_tomcat/data/${i}.yaml"
done

if [ ! -r "rk_tomcat/data/secrets-common.yaml" ]; then
  $LOGGER "Populate the secrets-common.yaml file and then run $0 again."
  exit 0
fi

cd rk_tomcat

$LOGGER "Configuring RubyGems..."
yum -y install ruby-devel glibc-devel gcc
cat > /root/.gemrc << 'GEMRC'
---
install: --nodocument --bindir /usr/local/bin
GEMRC

$LOGGER "Installing Bundler..."
gem install io-console bundler

$LOGGER "Installing other gem dependencies..."
BUNDLE=$(which bundle 2>/dev/null || echo '/usr/local/bin/bundle')
$BUNDLE install

$LOGGER "Installing Puppet dependencies..."
export PUPPET_MODULE_DIR='/etc/puppetlabs/code/modules'
yum -y install ruby20-augeas

LIBRARIAN_PUPPET=$(which librarian-puppet 2>/dev/null || echo '/usr/local/bin/librarian-puppet')
$LIBRARIAN_PUPPET config path "$PUPPET_MODULE_DIR" --global
$LIBRARIAN_PUPPET install

ln -s /root/rk_tomcat "${PUPPET_MODULE_DIR}/rk_tomcat"

$LOGGER "Running Puppet agent..."
mkdir -p /etc/hiera
cat > /etc/hiera/hiera.yaml << 'HIERA'
---
:backends:
  - module_data
HIERA
mkdir -p /var/log/puppet

PUPPET=$(which puppet 2>/dev/null || echo '/usr/local/bin/puppet')
$PUPPET apply \
  --hiera_config "/etc/hiera/hiera.yaml" \
  --modulepath "$(pwd)/modules:/etc/puppetlabs/code/modules" \
  --logdest /var/log/puppet/provision.log \
  -e 'class { "rk_tomcat": mode => "provision" }'

$LOGGER "Disabling Puppet agent..."
$PUPPET resource service puppet ensure=stopped enable=false

$LOGGER "Removing semaphore..."
$AWS s3 rm "s3://rk-devops-${REGION}/jenkins/semaphores/${INSTANCE_ID}" 2>/dev/null || true

cd ..

$LOGGER "Provision complete."
