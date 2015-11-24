# rk_tomcat::rsyslog
#
class rk_tomcat::rsyslog(
  $datahub_host,
  $datahub_port,
) {

  File {
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  # default logging to DataHub
  file { '/etc/rsyslog.d':
    ensure => directory,
    mode   => '0755',
  }

  file { "datahub-default":
    path    => '/etc/rsyslog.d/50-datahub-default.conf',
    content => template('rk_tomcat/datahub-default.conf.erb'),
  }
}
