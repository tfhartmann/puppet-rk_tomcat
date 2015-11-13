# rk_tomcat::newrelic
#
class rk_tomcat::newrelic (
  $catalina_home,
  $tomcat_user,
  $tomcat_group,
) {
  $newrelic_dir = "${catalina_home}/newrelic"
}
