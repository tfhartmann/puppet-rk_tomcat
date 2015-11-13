# rk_tomcat::newrelic::deploy
#
class rk_tomcat::newrelic::deploy(
  $app_names,
  $artifacts,
  $attr_include,
  $attr_exclude,
  $license,
) inherits rk_tomcat::newrelic {
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

  file { "$newrelic_dir/newrelic.yml":
    ensure  => present,
    owner   => $rk_tomcat::newrelic::tomcat_user,
    group   => $rk_tomcat::newrelic::tomcat_group,
    mode    => '0640',
    content => template('rk_tomcat/newrelic.yml.erb'),
  }
}
