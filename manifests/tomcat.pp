# rk_tomcat::tomcat
#
class rk_tomcat::tomcat (
  $catalina_home,
  $datahub_host,
  $datahub_port,
  $postgres_driver,
  $postgres_tls,
  $tomcat_instance,
  $tomcat_pkg,
  $tomcat_native_pkg,
  $tomcat_svc,
  $tomcat_user,
  $tomcat_group,
) {

  # Postgres
  $postgres_driver_jarfile = "${postgres_driver}.jar"

  validate_bool($postgres_tls)
  case $postgres_tls {
    true : {
      $postgres_certdir_state = 'directory'
      $postgres_certdir_mode = '0600'
    }
    default : {
      $postgres_certdir_state = 'absent'
      $postgres_certdir_mode = undef
    }
  }

  File {
    ensure => 'present',
    owner  => $tomcat_user,
    group  => $tomcat_group,
    mode   => '0640',
    notify => Service[$tomcat_svc],
  }

  # configure rsyslog to log to DataHub
  class { 'rk_tomcat::rsyslog': } ->

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

  file { "/home/${tomcat_user}/.postgresql":
    ensure => $postgres_certdir_state,
    mode   => $postgres_certdir_mode,
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

  file { '/etc/rsyslog.d':
    ensure => directory,
  } ->

  file { 'datahub-default.conf':
    path    => '/etc/rsyslog.d/datahub-default.conf',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('rk_tomcat/datahub-default.conf.erb'),
  } ->

  # apr for performance
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
