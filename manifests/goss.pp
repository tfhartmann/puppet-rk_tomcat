# rk_tomcat::goss
#
class rk_tomcat::goss (
  $version,
  $destination,
) {
  wget::fetch { "download_goss":
    source      => "https://github.com/aelsabbahy/goss/releases/download/${version}/goss-linux-amd64",
    destination => $destination,
  } ->

  file { $destination:
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    backup => false,
  }
}
