# == Class hue::config
#
# Configuration of Apache Hue.
#
class hue::config {
  file { "${hue::confdir}/hue.ini":
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('hue/hue.ini.erb'),
  }

  if $hue::realm and !empty($hue::realm) {
    file { $hue::keytab_hue:
      owner => 'hue',
      group => 'hue',
      mode  => '0600',
    }
  }

  if $hue::https {
    file { $hue::_https_certificate:
      owner  => 'hue',
      group  => 'hue',
      mode   => '0644',
      source => $hue::https_certificate,
    }

    file { $hue::_https_private_key:
      owner  => 'hue',
      group  => 'hue',
      mode   => '0400',
      source => $hue::https_private_key,
    }
  }
}
