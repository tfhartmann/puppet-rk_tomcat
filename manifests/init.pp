# Class: rk_tomcat
# ===========================
#
# Deploy the Runkeeper Tomcat platform onto an instance.
#
# Parameters
# ----------
#
# Document parameters here.
#
# * `sample parameter`
# Explanation of what this parameter affects and what it defaults to.
# e.g. "Specify one or more upstream ntp servers as an array."
#
# Variables
# ----------
#
# Here you should define a list of variables that this module would require.
#
# * `sample variable`
#  Explanation of how this variable affects the function of this class and if
#  it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#  External Node Classifier as a comma separated list of hostnames." (Note,
#  global variables should be avoided in favor of class parameters as
#  of Puppet 2.6.)
#
# Examples
# --------
#
# @example
#    class { 'rk_tomcat':
#      servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#    }
#
# Authors
# -------
#
# Steve Huff <shuff@runkeeper.com>
#
# Copyright
# ---------
#
# Copyright 2015 Your name here, unless otherwise noted.
#
class rk_tomcat (
  $mode = 'deploy'
) {
  validate_re($mode, '^(provision|deploy)$')

  if ( $mode == 'provision' ) {
    class { 'rk_tomcat::java':
      before => Class[rk_tomcat::tomcat],
    }
  }

  class { 'rk_tomcat::tomcat': }

  if ( $mode == 'deploy' ) {
    class { 'rk_tomcat::signal':
      require => Class[rk_tomcat::tomcat],
    } ->

    class { 'rk_tomcat::deploy': }
  }

}
