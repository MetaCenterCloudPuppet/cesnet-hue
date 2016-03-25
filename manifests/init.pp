# == Class: hue
#
# The main configuration class.
#
class hue (
  $alternatives = '::default',
  $defaultFS = undef,
  $hdfs_hostname,
  $hdfs_enable = true,
  $hive_server2_hostname = undef,
  $httpfs_enable = false,
  $https = false,
  $package_name = $::hue::params::package_name,
  $service_name = $::hue::params::service_name,
  $properties = undef,
) inherits ::hue::params {

  if !$hdfs_enable and !$httpfs_enable {
    err('WebHDFS ($hdfs_enable) or HTTPFS ($httpfs_enable) needs to be enabled')
  }

  $_defaultfs = pick("hdfs://${hdfs_hostname}:8020", $defaultFS)
  $base_properties = {
    'hadoop.hdfs_clusters.default.fs_defaultfs' => $_defaultfs,
  }
  if $hdfs_enable {
    if $https {
      $hdfs_properties = {
        'hadoop.hdfs_clusters.default.webhdfs_url' => "https://${hdfs_hostname}:50470/webhdfs/v1/",
      }
    } else {
      $hdfs_properties = {
        'hadoop.hdfs_clusters.default.webhdfs_url' => "http://${hdfs_hostname}:50070/webhdfs/v1/",
      }
    }
  } else {
    # TODO: https?
    $hdfs_properties = {
      'hadoop.hdfs_clusters.default.webhdfs_url' => "http://${hdfs_hostname}:14000/webhdfs/v1/",
    }
  }

  if $hive_server2_hostname {
    $hive_properties = {
      'beeswax.hive_server_host' => $hive_server2_hostname,
    }
  } else {
    $hive_properties = {}
  }

  $_properties = merge($hdfs_properties, $hive_properties, $properties)

  class { '::hue::install': } ->
  class { '::hue::config': } ~>
  class { '::hue::service': } ->
  Class['::hue']
}
