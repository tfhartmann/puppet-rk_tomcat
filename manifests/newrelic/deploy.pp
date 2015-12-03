# rk_tomcat::newrelic::deploy
#
class rk_tomcat::newrelic::deploy(
  $app_name,
  $attr_include,
  $attr_exclude,
  $ignore_status_codes,
  $license,
  $newrelic_enabled,
) inherits rk_tomcat::newrelic {
  validate_bool($newrelic_enabled)

  $ensure = $newrelic_enabled ? {
    false   => 'absent',
    default => 'present',
  }

  file { "$newrelic_dir/newrelic.yml":
    ensure  => $ensure,
    owner   => $rk_tomcat::newrelic::tomcat_user,
    group   => $rk_tomcat::newrelic::tomcat_group,
    mode    => '0640',
    content => template('rk_tomcat/newrelic.yml.erb'),
  }
}
