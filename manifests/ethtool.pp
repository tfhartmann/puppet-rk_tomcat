# rk_tomcat::ethtool
#
class rk_tomcat::ethtool (
  $gso,
  $tso,
) {
  validate_bool($gso)
  validate_bool($tso)

  class { 'ethtool': }

  $::interfaces.each |$interface| {
    if ( $interface =~ /^eth\d+/ ) {
      ethtool { $interface:
        gso => $gso,
        tso => $tso,
      }
    }
  }
}
