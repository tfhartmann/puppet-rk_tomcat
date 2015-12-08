# rk_tomcat::rsyslog::deploy
#
class rk_tomcat::rsyslog::deploy(
  $catalina_home,
  $application_tag,
) {

  File {
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  $rsyslog_tag = "datahub-${application_tag}"
  file { $rsyslog_tag:
    path    => "/etc/rsyslog.d/55-${rsyslog_tag}.conf",
    content => template('rk_tomcat/datahub-tomcat.conf.erb'),
  }
}
