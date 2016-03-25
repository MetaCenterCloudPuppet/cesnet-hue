# == Class hue::install
#
# Installation of Apache Hue.
#
class hue::install {
  include ::stdlib
  contain hue::common::postinstall

  ensure_packages($::hue::package_name)
  Package[$::hue::package_name] -> Class['hue::common::postinstall']
}
