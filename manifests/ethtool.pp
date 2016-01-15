# rk_tomcat::ethtool
#
class rk_tomcat::ethtool (
  $lro,
) {
  validate_bool($lro)

  class { 'ethtool': }

  $::interfaces.each |$interface| {
    if ( $interface =~ /^eth\d+/ ) {
      ethtool { $interface:
        lro => $lro,
      }
    }
  }
}
