# == Class hue::install
#
# Installation of Apache Hue.
#
class hue::install {
  include ::stdlib
  contain hue::common::postinstall

  ensure_packages($::hue::_packages)
  Package[$::hue::_packages] -> Class['hue::common::postinstall']
}
