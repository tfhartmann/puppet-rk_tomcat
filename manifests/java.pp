# rk_tomcat::java
#
class rk_tomcat::java (
  $zulu_package,
  $zulu_version,
) {

  # building variables
  $zulu_rpm = "zulu${zulu_version}-x86lx64.rpm"
  # $zulu_rpm_path = "/root/rk_tomcat/files/${zulu_rpm}"
  $zulu_rpm_path = "/root/${zulu_rpm}"

  # install Zulu
  file { 'zulu_rpm':
    path   => $zulu_rpm_path,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => "puppet:///modules/rk_tomcat/${zulu_rpm}",
  } ->

  exec { 'install_zulu_rpm':
    path      => '/bin:/usr/bin:/sbin:/usr/sbin',
    command   => "yum -y localinstall $zulu_rpm_path",
    logoutput => 'on_failure',
    unless    => "rpm -q $zulu_package",
  }
}
