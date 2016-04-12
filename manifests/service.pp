# == Class hue::service
#
# Ensure the Apache Hue is running.
#
class hue::service {
  service { $::hue::service_name:
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }

  if $::hue::external_db {
    $path = '/sbin:/usr/sbin:/bin:/usr/bin'
    $touch1 = "${hue::homedir}/.puppet-init1-syncdb"
    $touch2 = "${hue::homedir}/.puppet-init2-migrate"

    exec { 'hue syncdb':
      command => "/usr/lib/hue/build/env/bin/hue syncdb --noinput && touch ${touch1}",
      creates => $touch1,
      cwd     => $::hue::homedir,
      path    => $path,
      user    => 'hue',
    }
    ->
    exec { 'hue migrate':
      command => "/usr/lib/hue/build/env/bin/hue migrate && touch ${touch2}",
      creates => $touch2,
      cwd     => $::hue::homedir,
      path    => $path,
      user    => 'hue',
    }
    ->
    Service[$::hue::service_name]
  }
}
