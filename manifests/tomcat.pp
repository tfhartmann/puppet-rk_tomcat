# rk_tomcat::tomcat
#
class rk_tomcat::tomcat (
  $tomcat_instance,
  $tomcat_pkg,
  $tomcat_svc,
) {

  # install Tomcat package
  class { '::tomcat':
    install_from_source => false,
  } ->

  ::tomcat::instance { $tomcat_instance:
    package_name => $tomcat_pkg,
  } ->

  ::tomcat::service { $tomcat_instance:
    use_jsvc     => false,
    use_init     => true,
    service_name => $tomcat_svc,
    service_name => 'running',
  }
}
