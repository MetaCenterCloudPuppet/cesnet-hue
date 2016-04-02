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

  $defaultdir = "${::osfamily}-${::operatingsystem}" ? {
    /RedHat-Fedora/ => '/etc/sysconfig',
    /Debian|RedHat/ => '/etc/default',
  }

  $package_name = 'hue'

  $service_name = 'hue'
}
