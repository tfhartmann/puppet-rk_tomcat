# rk_tomcat::newrelic
#
class rk_tomcat::newrelic (
  $catalina_home,
  $tomcat_user,
  $tomcat_group,
  $version,
) {
  $newrelic_dir = "${catalina_home}/newrelic"

  File {
    ensure => present,
    owner  => $tomcat_user,
    group  => $tomcat_group,
  }

  file { $newrelic_dir:
    ensure       => directory,
    mode         => '0750',
    source       => 'puppet:///modules/rk_tomcat/newrelic',
    recurse      => 'remote',
    recurselimit => 1,
  }

}
