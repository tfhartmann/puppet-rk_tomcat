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
  $warname,
) {

  case $staging_instance {
    /loadtest/: {
      $cloudant_suffix  = "-loadtest"
      $log_identifiers  = $artifacts.map |$pair| { $pair[0] }
      $log_identifier   = "loadtest-${log_identifiers[0]}"
      $queue_identifier = 'loadtest'
      $tier             = 'loadtest'
      $newrelic_env     = 'loadtest'
      $conf_tier        = 'stage'
      $platform_env     = 'STAGE'
    }
    /^stage/: {
      $cloudant_suffix  = "-${staging_instance}"
      $log_identifiers  = $artifacts.map |$pair| { $pair[0] }
      $log_identifier   = "$staging_instance-${log_identifiers[0]}"
      $queue_identifier = $staging_instance
      $tier             = 'staging'
      $newrelic_env     = 'staging'
      $conf_tier        = 'stage'
      $platform_env     = 'STAGE'
    }
    '': {
      $cloudant_suffix  = ''
      $log_identifiers  = $artifacts.map |$pair| { $pair[0] }
      $log_identifier   = $log_identifiers[0]
      $queue_identifier = ''
      $tier             = 'production'
      $newrelic_env     = 'production'
      $conf_tier        = 'production'
      $platform_env     = 'PRODUCTION'
    }
    default: {
      fail("Unable to parse staging_instance parameter '${staging_instance}'.")
    }
  }

  # Postgres
  $postgres = lookup('rk_tomcat::deploy::postgres', { 'value_type' => Hash })
  $postgres_resources = $postgres.map |$key,$values| {
    {
      'name'      => $values[name],
      'url'       => "jdbc:postgresql://${values[host]}:${values[port]}/${values[db]}${values[opts]}",
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

  # S3
  $logback_access_key = $aws_keys['s3']['analytics']['access_key']
  $logback_secret_key = $aws_keys['s3']['analytics']['secret_key']

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

  class { 'rk_tomcat::rsyslog::deploy':
    application_tag => $log_identifier
  }

  # make a directory for PostgreSQL client certs on prod deploys only
  case $tier {
    'production': {
      $postgres_certdir_ensure = 'directory'
      $postgres_certdir_mode   = '0750'
    }
    default: {
      $postgres_certdir_ensure = 'absent'
      $postgres_certdir_mode   = undef
    }
  }

  file { "${catalina_home}/.postgresql":
    ensure => $postgres_certdir_ensure,
    mode   => $postgres_certdir_mode,
  }
}
