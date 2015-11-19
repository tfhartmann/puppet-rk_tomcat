# rk_tomcat::tomcat
#
class rk_tomcat::tomcat (
  $catalina_home,
  $postgres_driver,
  $tomcat_instance,
  $tomcat_pkg,
  $tomcat_native_pkg,
  $tomcat_svc,
  $tomcat_user,
  $tomcat_group,
) {

  # Postgres
  $postgres_driver_jarfile = "${postgres_driver}.jar"

  File {
    ensure => 'present',
    owner  => 'tomcat',
    group  => 'tomcat',
    mode   => '0640',
    notify => Service[$tomcat_svc],
  }

  # apr for performance

  # install Tomcat package
  class { '::tomcat':
    install_from_source => false,
  } ->

  ::tomcat::instance { $tomcat_instance:
    package_name => $tomcat_pkg,
  } ->

  class { 'rk_tomcat::newrelic::provision': } ->

  file { 'postgres_driver':
    path   => "${catalina_home}/lib/${postgres_driver_jarfile}",
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => "puppet:///modules/rk_tomcat/${postgres_driver_jarfile}",
  } ->

  file { 'provision.sh':
    path   => '/root/provision.sh',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/rk_tomcat/provision.sh',
  } ->

  file { 'deploy.sh':
    path   => '/root/deploy.sh',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/rk_tomcat/deploy.sh',
  } ->

  package { $tomcat_native_pkg:
    ensure => present,
  } ->

  ::tomcat::service { $tomcat_instance:
    use_jsvc       => false,
    use_init       => true,
    service_name   => $tomcat_svc,
    service_ensure => 'stopped',
    service_enable => true,
  }
}
