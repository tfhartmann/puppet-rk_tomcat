# rk_tomcat::goss
#
class rk_tomcat::goss (
  $version,
) {
  wget::fetch { "download_goss":
    source      => "https://github.com/aelsabbahy/goss/releases/download/${version}/goss-linux-amd64",
    destination => '/usr/local/bin/goss',
    mode        => '0755',
    backup      => false,
  }
}
