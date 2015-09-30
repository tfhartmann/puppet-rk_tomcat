# rk_tomcat::tomcat
#
class rk_tomcat::tomcat (
  $artifacts,
  $aws_keys,
  $catalina_home,
  $cloudant_user,
  $cloudant_password,
  $cloudant_host,
  $deploy_user,
  $deploy_password,
  $logentries_tokens,
  $redis_host,
  $redis_port,
  $redis_pushnotif_db,
  $redis_queue_db,
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
    $queue_identifier = $staging_instance
  }
  else {
    $cloudant_suffix = ''
    $log_identifiers = $artifacts.map |$pair| { $pair[0] }
    $log_identifier = $log_identifiers[0]
    $queue_identifier = ''
  }

  # Postgres
  $postgres = lookup('postgres', { 'merge' => { 'strategy' => 'deep' }, 'value_type' => Hash })
  $postgres_resources = $postgres.map |$key,$values| {
    {
      'name'      => $values[name],
      'url'       => "jdbc:postgresql://${values[host]}:${values[port]}/${values[db]}",
      'username'  => $values[user],
      'password'  => $values[password],
      'maxactive' => $values[max_conn],
      'maxidle'   => $values[max_conn],
    }
  }

  # Logentries
  $logentries_analytics_token = $logentries_tokens['analytics']
  $logentries_applogs_token = $logentries_tokens['applogs']

  # Redis
  $redis_pushnotif_uri = "redis://${redis_host}:${redis_port}/${redis_pushnotif_db}"
  $redis_queue_uri = "redis://${redis_host}:${redis_port}/${redis_queue_db}"

  # SQS
  $sqs_access_key = $aws_keys['sqs']['access_key']
  $sqs_secret_key = $aws_keys['sqs']['secret_key']

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

  file { 'MessageQueueingConfiguration.conf':
    path    => "${catalina_home}/conf/MessageQueueingConfiguration.conf",
    content => template('rk_tomcat/MessageQueueingConfiguration.conf.erb'),
  } ->

  file { 'PushNotificationTrackingConfiguration.conf':
    path    => "${catalina_home}/conf/PushNotificationTrackingConfiguration.conf",
    content => template('rk_tomcat/PushNotificationTrackingConfiguration.conf.erb'),
  } ->

  file { 'server.xml':
    path    => "${catalina_home}/conf/server.xml",
    content => template('rk_tomcat/server.xml.erb'),
  } ->

  ::tomcat::service { $tomcat_instance:
    use_jsvc       => false,
    use_init       => true,
    service_name   => $tomcat_svc,
    service_ensure => 'running',
  }
}
