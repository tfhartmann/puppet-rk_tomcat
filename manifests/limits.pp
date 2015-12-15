# rk_tomcat::limits
#
class rk_tomcat::limits (
  $nofile,
) {
  # PAM limits
  ::limits::fragment { 'tomcat-nofile':
    domain => '*',
    type   => '-',
    item   => 'nofile',
    value  => "$nofile",
    file   => '/etc/security/limits.d/10-rk_tomcat.conf',
  } ->

  # sysctl
  sysctl { 'sys.fs.file-max':
    ensure  => 'present',
    value   => $nofile,
    comment => 'set max open files for Tomcat',
    target  => '/etc/sysctl.d/10-rk_tomcat.conf',
    apply   => false,
  }
}
