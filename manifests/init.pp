# == Class: hue
#
# The main configuration class.
#
class hue (
  $hdfs_hostname = undef,
  $httpfs_hostname = undef,
  $hive_server2_hostname = undef,
  $impala_hostname = undef,
  $oozie_hostname = undef,
  $yarn_hostname = undef,
  $yarn_hostname2 = undef,
  $zookeeper_hostnames = [],
  $zookeeper_rest_hostname = undef,
  $alternatives = '::default',
  $defaultFS = undef,
  $group = 'users',
  $https = false,
  $package_name = $::hue::params::package_name,
  $service_name = $::hue::params::service_name,
  $properties = undef,
  $secret = '',
) inherits ::hue::params {
  include ::stdlib

  validate_array($zookeeper_hostnames)
  if (!$hdfs_hostname or empty($hdfs_hostname)) {
    if (!$defaultFS or empty($defaultFS)) {
      fail('$hdfs_hostname or $defaultFS parameter is required')
    }
    if (!$httpfs_hostname or empty($httpfs_hostname)) {
      fail('$hdfs_hostname or $httpfs_hostname parameter is required')
    }
  }

  if !$secret or $secret == '' {
    warning('$secret parameter is empty, we recommend to set any value')
  }

  if $https {
    $security = 'True'
  } else {
    $security = 'False'
  }

  $_defaultfs = pick($defaultFS, "hdfs://${hdfs_hostname}:8020")
  $base_properties = {
    'useradmin.default_user_group' => $group,
    'desktop.database.engine' => 'sqlite3',
    'desktop.database.name' => '/var/lib/hue/desktop.db',
    'desktop.secret_key' => $secret,
    'hadoop.hdfs_clusters.default.fs_defaultfs' => $_defaultfs,
    'hadoop.mapred_clusters.default.submit_to' => 'False',
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

  if $hive_server2_hostname and !empty($hive_server2_hostname) {
    $hive_properties = {
      'beeswax.hive_server_host' => $hive_server2_hostname,
    }
  } else {
    $hive_properties = {}
  }

  if $impala_hostname and !empty($impala_hostname) {
    $impala_properties = {
      'impala.server_host' => $impala_hostname,
      # port needs to be specified
      'impala.server_port' => 21050,
    }
  } else {
    $impala_properties = {}
  }

  if $oozie_hostname and !empty($oozie_hostname) {
    if $https {
      $oozie_url = "https://${oozie_hostname}:11443/oozie"
    } else {
      $oozie_url = "http://${oozie_hostname}:11000/oozie"
    }
    $oozie_properties = {
      'liboozie.oozie_url' => $oozie_url,
      'liboozie.security_enabled' => $security,
    }
  } else {
    $oozie_properties = {}
  }

  if $yarn_hostname and !empty($yarn_hostname) {
    if $https {
      $jhs_url = "https://${yarn_hostname}:19890"
      $rm1_url = "https://${yarn_hostname}:8090"
    } else {
      $jhs_url = "http://${yarn_hostname}:19888"
      $rm1_url = "http://${yarn_hostname}:8088"
    }
    $yarn_base_properties = {
      'hadoop.yarn_clusters.default.history_server_api_url' => $jhs_url,
      'hadoop.yarn_clusters.default.proxy_api_url' => $rm1_url,
      'hadoop.yarn_clusters.default.resourcemanager_api_url' => $rm1_url,
      'hadoop.yarn_clusters.default.resourcemanager_host' => $yarn_hostname,
      'hadoop.yarn_clusters.default.security_enabled' => $security,
      'hadoop.yarn_clusters.default.submit_to' => 'True',
    }
    if $yarn_hostname2 and !empty($yarn_hostname2) {
      if $https {
        $rm2_url = "https://${yarn_hostname2}:8090"
      } else {
        $rm2_url = "http://${yarn_hostname2}:8088"
      }
      $yarn_ha_properties = {
        'hadoop.yarn_clusters.default.logical_name' => 'rm1',
        'hadoop.yarn_clusters.ha.logical_name' => 'rm2',
        'hadoop.yarn_clusters.ha.proxy_api_url' => $rm2_url,
        'hadoop.yarn_clusters.ha.resourcemanager_api_url' => $rm2_url,
      }
    }

    $yarn_properties = merge($yarn_base_properties, $yarn_ha_properties)
  } else {
    $yarn_properties = {}
  }

  if $zookeeper_hostnames and !empty($zookeeper_hostnames) {
    $zoo_base_properties = {
      'zookeeper.clusters.default.host_ports' => join($zookeeper_hostnames, ':2181,') + ':2181',
    }
    if $zookeeper_rest_hostname and !empty($zookeeper_rest_hostname) {
      $zoo_rest_properties = {
        'zookeeper.clusters.default.rest_url' => "http://${zookeeper_rest_hostname}:9998",
      }
    } else  {
      $zoo_rest_properties = {}
    }

    $zoo_properties = merge($zoo_base_properties, $zoo_rest_properties)
  } else {
    $zoo_properties = {}
  }

  $_properties = merge($base_properties, $hdfs_properties, $hive_properties, $impala_properties, $oozie_properties, $yarn_properties, $zoo_properties, $properties)

  class { '::hue::install': } ->
  class { '::hue::config': } ~>
  class { '::hue::service': } ->
  Class['::hue']
}
