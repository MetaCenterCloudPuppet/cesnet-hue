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
}
