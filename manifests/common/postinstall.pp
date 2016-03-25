# == Class hue::common::postinstall
#
# Preparation steps after installation. It switches hue-conf alternative, if enabled.
#
class hue::common::postinstall {
  ::hadoop_lib::postinstall{ 'hue':
    alternatives => $::hue::alternatives,
  }
}
