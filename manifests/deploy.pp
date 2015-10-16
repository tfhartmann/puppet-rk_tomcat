# rk_tomcat::deploy
#
class rk_tomcat::deploy (
  $catalina_home,
  $artifacts,
  $tomcat_svc,
) {
  Exec {
    path      => "${catalina_home}/bin:/usr/bin:/bin:/usr/sbin:/sbin",
    logoutput => 'on_failure',
  }

  exec { 'deployLastSuccessfulBuild':
    command => 'deployLastSuccessfulBuild.sh',
    unless  => "ls ${catalina_home}/webapps/*.war >/dev/null 2>&1",
  }

  if ( 'dashboard' in $artifacts ) {
    exec { 'prewarmTomcat':
      command => 'echo "STUB FOR PREWARMING DISK CACHE"',
      require => Service[$tomcat_svc],
    }
  }
}
