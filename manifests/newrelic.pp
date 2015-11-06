# rk_tomcat::newrelic
#
class rk_tomcat::newrelic (
  $app_names,
  $artifacts,
  $catalina_home,
  $license,
  $tomcat_user,
  $tomcat_group,
  $version,
) {
  $newrelic_dir = "${catalina_home}/newrelic"

  if ( size($artifacts) == 1 ) {
    $newrelic_environment = 'production'
    if has_key($app_names, $artifacts[0]) {
      $app_name = $app_names[$artifacts[0]]
    }
    else {
      $app_name = 'Unknown'
    }
  }
  else {
    $newrelic_environment = 'staging'
    $app_name = 'Runkeeper Applications'
  }

  File {
    ensure => present,
    owner  => $tomcat_user,
    group  => $tomcat_group,
  }

  file { $newrelic_dir:
    ensure       => directory,
    mode         => '0750',
    source       => 'puppet:///modules/rk_tomcat/newrelic',
    recurse      => 'remote',
    recurselimit => 1,
  } ->

  file { "$newrelic_dir/newrelic.yml":
    mode    => '0640',
    content => template('rk_tomcat/newrelic.yml.erb'),
  }

}
