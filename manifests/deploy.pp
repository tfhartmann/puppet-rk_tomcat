# rk_tomcat::deploy
#
class rk_tomcat::deploy (
  $catalina_home,
) {
  exec { 'deployLastSuccessfulBuild':
    path      => "${catalina_home}/bin:/usr/bin:/bin:/usr/sbin:/sbin",
    command   => 'deployLastSuccessfulBuild.sh',
    logoutput => 'on_failure',
    unless    => "ls ${catalina_home}/webapps/*.war >/dev/null 2>&1",
  }
}
