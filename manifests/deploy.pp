# rk_tomcat::deploy
#
class rk_tomcat::deploy (
  $artifacts,
  $aws_keys,
  $catalina_home,
  $cloudant_host,
  $cloudant_user,
  $cloudant_password,
  $logentries_tokens,
  $redis_host,
  $redis_port,
  $redis_pushnotif_db,
  $redis_queue_db,
  $s3_path,
  $stack,
  $staging_instance,
  $tomcat_svc,
) {

  if ( $staging_instance ) {
    if ( $staging_instance =~ /loadtest/ ) {
      $cloudant_suffix  = "-loadtest"
      $log_identifiers  = $artifacts.map |$pair| { $pair[0] }
      $log_identifier   = "loadtest-${log_identifiers[0]}"
      $queue_identifier = 'loadtest'
      $tier             = 'loadtest'
      $newrelic_env     = 'loadtest'
    }
    else {
      $cloudant_suffix  = "-${staging_instance}"
      $log_identifiers  = $artifacts.map |$pair| { $pair[0] }
      $log_identifier   = "$staging_instance-${log_identifiers[0]}"
      $queue_identifier = $staging_instance
      $tier             = 'staging'
      $newrelic_env     = 'staging'
    }
  }
  else {
    $cloudant_suffix  = ''
    $log_identifiers  = $artifacts.map |$pair| { $pair[0] }
    $log_identifier   = $log_identifiers[0]
    $queue_identifier = ''
    $tier             = 'production'
    $newrelic_env     = 'production'
  }

  # Postgres
  $postgres = lookup('rk_tomcat::deploy::postgres', { 'value_type' => Hash })
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
  }

  Exec {
    path      => "${catalina_home}/bin:/usr/bin:/bin:/usr/sbin:/sbin",
    logoutput => 'on_failure',
  }

  # populate config files by hand, ugh
  file { 'deployBuild.sh':
    path    => "${catalina_home}/bin/deployBuild.sh",
    content => template('rk_tomcat/deployBuild.sh.erb'),
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

  file { 'tomcat7.conf':
    path    => "${catalina_home}/conf/tomcat7.conf",
    content => template('rk_tomcat/tomcat7.conf.erb'),
  } ->

  exec { 'deployBuild':
    command => 'deployBuild.sh',
    unless  => "ls ${catalina_home}/webapps/*.war >/dev/null 2>&1",
  }

  class { 'rk_tomcat::newrelic::deploy': }

  if ( 'dashboard' in $artifacts ) {
    exec { 'prewarmTomcat':
      command => 'echo "STUB FOR PREWARMING DISK CACHE"',
    }
  }
}
