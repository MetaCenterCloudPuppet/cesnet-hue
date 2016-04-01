# == Class hue::user
#
# Creates hue system user, if needed. The hue user is required on the all HDFS namenodes to autorization work properly and we don't need to install hue just for the user.
#
# It is better to handle creating the user by the packages, so we recommend dependency on installation classes or Hue packages.
#
class hue::user {
  group { 'hue':
    ensure => present,
    system => true,
  }
  case "${::osfamily}-${::operatingsystem}" {
    /RedHat-Fedora/: {
      user { 'hue':
        ensure     => present,
        system     => true,
        comment    => 'Apache Hue',
        gid        => 'hue',
        home       => '/var/lib/hue',
        managehome => true,
        password   => '!!',
        shell      => '/sbin/nologin',
      }
    }
    /Debian|RedHat/: {
      user { 'hue':
        ensure     => present,
        system     => true,
        comment    => 'Hue daemon',
        gid        => 'hue',
        home       => '/usr/lib/hue',
        managehome => true,
        password   => '!!',
        shell      => '/bin/false',
      }
    }
    default: {
      notice("${::osfamily} not supported")
    }
  }
  Group['hue'] -> User['hue']
}
