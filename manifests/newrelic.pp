# rk_tomcat::newrelic
#
class rk_tomcat::newrelic (
  $catalina_home,
  $mode,
  $tomcat_user,
  $tomcat_group,
) {
  validate_re($mode, '^(provision|deploy)$', "rk_tomcat::newrelic::mode must be 'provision' or 'deploy'")

  $newrelic_dir = "${catalina_home}/newrelic"

  class { "rk_tomcat::newrelic::${mode}": }
}
