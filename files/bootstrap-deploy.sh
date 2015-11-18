#!/bin/bash -l
THE_SCRIPT='/root/deploy.sh'

export PATH="/usr/local/bin:${PATH}"

LOGGER='logger -t [CLOUDINIT] -p user.info'

if [ -r "/etc/profile.d/aws-apitools-common.sh" ]; then
  . /etc/profile.d/aws-apitools-common.sh
fi

if [ -x "$THE_SCRIPT" ]; then
  $LOGGER "Executing '$THE_SCRIPT'"
  cd /root && "$THE_SCRIPT" > "${THE_SCRIPT}.log" 2>&1
  exit
else
  $LOGGER "'$THE_SCRIPT' not executable, exiting."
  exit 1
fi
