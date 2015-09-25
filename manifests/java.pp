# rk_tomcat::java
#
class rk_tomcat::java (
  $system_java,
  $zulu_package,
  $zulu_version,
) inherits rk_tomcat::params {

  # building variables
  $zulu_rpm = "zulu${zulu_version}-x86lx64.rpm"
  $zulu_rpm_path = "/root/${zulu_rpm}"

  # uninstall system Java
  package { $system_java: ensure => 'absent' } ->

  # install Zulu
  file { $zulu_rpm_path:
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => "puppet:///rk_tomcat/${zulu_rpm}",
  } ->

  exec { 'install_zulu_rpm':
    path      => '/bin:/usr/bin:/sbin:/usr/sbin',
    command   => "yum -y localinstall $zulu_rpm_path",
    logoutput => 'on_failure',
    unless    => "rpm -q $zulu_package",
  }

}
