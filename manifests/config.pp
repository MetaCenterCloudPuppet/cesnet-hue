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
}
