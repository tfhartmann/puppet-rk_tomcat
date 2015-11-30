# rk_tomcat::newrelic::deploy
#
class rk_tomcat::newrelic::deploy(
  $app_name,
  $attr_include,
  $attr_exclude,
  $ignore_status_codes,
  $license,
) inherits rk_tomcat::newrelic {

  file { "$newrelic_dir/newrelic.yml":
    ensure  => present,
    owner   => $rk_tomcat::newrelic::tomcat_user,
    group   => $rk_tomcat::newrelic::tomcat_group,
    mode    => '0640',
    content => template('rk_tomcat/newrelic.yml.erb'),
  }
}
