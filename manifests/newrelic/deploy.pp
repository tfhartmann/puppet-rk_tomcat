# rk_tomcat::newrelic::deploy
#
class rk_tomcat::newrelic::deploy(
  $app_names,
  $attr_include,
  $attr_exclude,
  $artifacts,
  $catalina_home,
  $license,
  $tomcat_user,
  $tomcat_group,
) {
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
    owner   => $tomcat_user,
    group   => $tomcat_group,
    mode    => '0640',
    content => template('rk_tomcat/newrelic.yml.erb'),
  }
}
