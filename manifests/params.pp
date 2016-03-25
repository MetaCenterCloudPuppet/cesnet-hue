# == Class hue::params
#
# This class is meant to be called from hue.
# It sets variables according to platform.
#
class hue::params {
  case "${::osfamily}-${::operatingsystem}" {
    /Debian/: {
    }
    /RedHat/: {
    }
    default: {
      fail("${::osfamily}/${::operatingsystem} not supported")
    }
  }

  $confdir = '/etc/hue/conf'
  $package_name = 'hue'
  $service_name = 'hue'
}
