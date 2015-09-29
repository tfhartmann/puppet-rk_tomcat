# rk_tomcat::tomcat
#
class rk_tomcat::tomcat (
  $artifacts,
  $catalina_home,
  $cloudant_user,
  $cloudant_password,
  $cloudant_host,
  $deploy_user,
  $deploy_password,
  $logentries_tokens,
  $tomcat_instance,
  $tomcat_pkg,
  $tomcat_svc,
  $tomcat_user,
  $tomcat_group,
  $staging_instance,
) {

  if ( $staging_instance ) {
    $cloudant_suffix = "-${staging_instance}"
    $log_identifier = $staging_instance
  }
  else {
    $cloudant_suffix = ''
    $log_identifiers = $artifacts.map |$pair| { $pair[0] }
    $log_identifier = $log_identifiers[0]
  }

  $logentries_analytics_token = $logentries_tokens['analytics']
  $logentries_applogs_token = $logentries_tokens['applogs']

  File {
    ensure => 'present',
    owner  => 'tomcat',
    group  => 'tomcat',
    mode   => '0640',
    notify => Service[$tomcat_svc],
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
    owner   => 'root',
    group   => 'root',
    mode    => '0750',
  } ->

  file { 'CloudantConfiguration.conf':
    path    => "${catalina_home}/conf/CloudantConfiguration.conf",
    content => template('rk_tomcat/CloudantConfiguration.conf.erb'),
  } ->

  file { 'logbackInclude.xml':
    path    => "${catalina_home}/conf/logbackInclude.xml",
    content => template('rk_tomcat/logbackInclude.xml.erb'),
  } ->

  ::tomcat::service { $tomcat_instance:
    use_jsvc       => false,
    use_init       => true,
    service_name   => $tomcat_svc,
    service_ensure => 'running',
  }
}
