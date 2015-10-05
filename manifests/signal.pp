# class rk_tomcat::signal
#
class rk_tomcat::signal {
  $cfn_signal_cmd = "/usr/local/bin/signalResource.sh"

  file { 'signalResource.sh':
    path    => $cfn_signal_cmd,
    source  => 'puppet:///modules/rk_tomcat/signalResource.sh',
    owner   => 'root',
    group   => 'root',
    mode    => '0750',
  } ->

  exec { 'tomcat-cfn-signal':
    path      => '/usr/bin:/bin:/usr/sbin:/sbin',
    command   => "echo '${cfn_signal_cmd}' >> /etc/rc.local",
    logoutput => 'on_failure',
    unless    => "grep -q '${cfn_signal_cmd}' /etc/rc.local"
  }
}
