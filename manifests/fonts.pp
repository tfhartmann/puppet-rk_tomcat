# rk_tomcat::fonts

class rk_tomcat::fonts (
  $packages,
) {
  package { $packages:
    ensure => present,
  }
}
