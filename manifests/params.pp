# == Class hue::params
#
# This class is meant to be called from hue.
# It sets variables according to platform.
#
class hue::params {
  case "${::osfamily}-${::operatingsystem}" {
    /Debian/: {
      $packages_postgresql = ['python-psycopg2']
    }
    /RedHat/: {
      $packages_postgresql = ['python-psycopg2']
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

  # not real homedir, just a directory for hue-specific data
  $homedir = '/var/lib/hue'

  $package_name = 'hue'

  $service_name = 'hue'
}
