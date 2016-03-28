# == Class: hue
#
# The main configuration class.
#
class hue (
  $alternatives = '::default',
  $defaultFS = undef,
  $group = 'users',
  $hdfs_hostname,
  $httpfs_hostname = undef,
  $hive_server2_hostname = undef,
  $https = false,
  $package_name = $::hue::params::package_name,
  $service_name = $::hue::params::service_name,
  $properties = undef,
  $secret = '',
) inherits ::hue::params {

  if !$secret or $secret == '' {
    warning('$secret parameter is empty, we recommend to set any value')
  }

  $_defaultfs = pick($defaultFS, "hdfs://${hdfs_hostname}:8020")
  $base_properties = {
    'useradmin.default_user_group' => $group,
    'desktop.database.engine' => 'sqlite3',
    'desktop.database.name' => '/var/lib/hue/desktop.db',
    'desktop.secret_key' => $secret,
    'hadoop.hdfs_clusters.default.fs_defaultfs' => $_defaultfs,
    'hadoop.mapred_clusters.default.submit_to' => 'False',
    'hadoop.yarn_clusters.default.submit_to' => 'True',
  }

  if $httpfs_hostname and !empty($httpfs_hostname) {
    $hdfs_properties = {
      'hadoop.hdfs_clusters.default.webhdfs_url' => "http://${httpfs_hostname}:14000/webhdfs/v1/",
    }
  } else {
    if $https {
      $hdfs_properties = {
        'hadoop.hdfs_clusters.default.webhdfs_url' => "https://${hdfs_hostname}:50470/webhdfs/v1/",
      }
    } else {
      $hdfs_properties = {
        'hadoop.hdfs_clusters.default.webhdfs_url' => "http://${hdfs_hostname}:50070/webhdfs/v1/",
      }
    }
  }

  if $hive_server2_hostname {
    $hive_properties = {
      'beeswax.hive_server_host' => $hive_server2_hostname,
    }
  } else {
    $hive_properties = {}
  }

  $_properties = merge($base_properties, $hdfs_properties, $hive_properties, $properties)

  class { '::hue::install': } ->
  class { '::hue::config': } ~>
  class { '::hue::service': } ->
  Class['::hue']
}
