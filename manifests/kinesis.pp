# rk_tomcat::kinesis
#
class rk_tomcat::kinesis (
  $agent_cfg,
  $agent_pkg,
  $agent_svc,
  $ensure = 'present',
) {
  $flows = hiera_array('rk_tomcat::kinesis::flows')
  validate_array($flows)

  package { $agent_pkg:
    ensure => $ensure,
  } ->

  file { $agent_cfg:
    ensure  => $ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('rk_tomcat/kinesis_agent_cfg.erb'),
  }

  if ( $ensure == 'present' ) {
    service { $agent_svc:
      ensure  => 'stopped',
      enable  => true,
      require => File[$agent_cfg],
    }
  }
}
