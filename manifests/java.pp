# rk_tomcat::java
#
class rk_tomcat::java (
  $zulu_package,
  $zulu_version,
) {

  # building variables
  $zulu_rpm = "zulu${zulu_version}-x86lx64.rpm"
  $zulu_rpm_path = "/root/rk_tomcat/files/${zulu_rpm}"

  # install Zulu
  # this is an awful hack
  exec { 'install_zulu_rpm':
    path      => '/bin:/usr/bin:/sbin:/usr/sbin',
    command   => "yum -y localinstall $zulu_rpm_path",
    logoutput => 'on_failure',
    unless    => "rpm -q $zulu_package",
  }
}
