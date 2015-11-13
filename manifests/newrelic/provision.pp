# rk_tomcat::newrelic::provision
#
class rk_tomcat::newrelic::provision inherits rk_tomcat::newrelic {

  File {
    ensure => present,
    owner  => $rk_tomcat::newrelic::tomcat_user,
    group  => $rk_tomcat::newrelic::tomcat_group,
  }

  file { $newrelic_dir:
    ensure       => directory,
    mode         => '0750',
    source       => 'puppet:///modules/rk_tomcat/newrelic',
    recurse      => 'remote',
    recurselimit => 1,
  }

}
