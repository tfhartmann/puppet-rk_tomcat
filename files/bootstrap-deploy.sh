#!/bin/bash
THE_SCRIPT='/root/deploy.sh'

LOGGER='logger -t [CLOUDINIT] -p user.info'

if [ -r "/etc/profile.d/aws-apitools-common.sh" ]; then
  . /etc/profile.d/aws-apitools-common.sh
fi

if [ -x "$THE_SCRIPT" ]; then
  $LOGGER "Executing '$THE_SCRIPT'"
  cd /root && /bin/bash -l -c "$THE_SCRIPT"
  exit
else
  $LOGGER "'$THE_SCRIPT' not executable, exiting."
  exit 1
fi