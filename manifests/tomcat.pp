# rk_tomcat::tomcat
#
class rk_tomcat::tomcat (
  $artifacts,
  $deploy_user,
  $deploy_password,
  $tomcat_instance,
  $tomcat_pkg,
  $tomcat_svc,
  $tomcat_user,
  $tomcat_group,
  $catalina_home,
) {

  File {
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => '0640'
  }

  # install Tomcat package
  class { '::tomcat':
    install_from_source => false,
  } ->

  ::tomcat::instance { $tomcat_instance:
    package_name => $tomcat_pkg,
  } ->

  # populate config files by hand, ugh
  file { 'deployLastSuccessfulBuild.sh':
    path    => "${catalina_home}/bin/deployLastSuccessfulBuild.sh",
    content => template('rk_tomcat/deployLastSuccessfulBuild.sh.erb'),
  } ->

  ::tomcat::service { $tomcat_instance:
    use_jsvc       => false,
    use_init       => true,
    service_name   => $tomcat_svc,
    service_ensure => 'running',
  }
}
