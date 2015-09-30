# class rk_tomcat::signal
#
class rk_tomcat::signal (
  $stack,
  $resource,
) {
  $cfn_signal_cmd = "/opt/aws/bin/cfn-signal -e 0 --stack ${stack} --resource ${resource}"

  exec { 'tomcat-cfn-signal':
    path      => '/usr/bin:/bin:/usr/sbin:/sbin',
    command   => "echo '${cfn_signal_cmd}' >> /etc/rc.local",
    logoutput => 'on_failure',
    unless    => 'grep -q cfn-signal /etc/rc.local'
  }
}
