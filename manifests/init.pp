# == Class: hue
#
# The main deployment class.
#
class hue (
  $hdfs_hostname = undef,
  $httpfs_hostname = undef,
  $hive_server2_hostname = undef,
  $historyserver_hostname = undef,
  $impala_hostname = undef,
  $oozie_hostname = undef,
  $yarn_hostname = undef,
  $yarn_hostname2 = undef,
  $zookeeper_hostnames = [],
  $zookeeper_rest_hostname = undef,
  $alternatives = '::default',
  $db = undef,
  $db_host = 'localhost',
  $db_user = 'hue',
  $db_name = undef,
  $db_password = undef,
  $defaultFS = undef,
  $environment = undef,
  $group = 'users',
  $https = false,
  $https_cachain = undef,
  $https_certificate = '/etc/grid-security/hostcert.pem',
  $https_hue = undef,
  $https_private_key = '/etc/grid-security/hostkey.pem',
  $https_passphrase = undef,
  $keytab_hue = '/etc/security/keytab/hue.service.keytab',
  $package_name = $::hue::params::package_name,
  $service_name = $::hue::params::service_name,
  $properties = undef,
  $realm = undef,
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

  if $realm and !empty($realm) {
    $security_enabled = 'True'
  } else {
    $security_enabled = 'False'
  }

  $_defaultfs = pick($defaultFS, "hdfs://${hdfs_hostname}:8020")
  $base_properties = {
    'useradmin.default_user_group' => $group,
    # IPv6 works out-of-the box, only needs to be enabled here
    'desktop.http_host' => '::',
    'desktop.secret_key' => $secret,
    'hadoop.hdfs_clusters.default.fs_defaultfs' => $_defaultfs,
    'hadoop.mapred_clusters.default.submit_to' => 'False',
  }

  case $db {
    'sqlite', default: {
      $db_base_properties = {
        'desktop.database.engine' => 'sqlite3',
        'desktop.database.name' => pick($db_name, '/var/lib/hue/desktop.db'),
      }
      $db_packages = []
      $external_db = false
    }
    'mariadb', 'mysql': {
      $db_base_properties = {
        'desktop.database.engine' => 'mysql',
        'desktop.database.host' => $db_host,
        'desktop.database.name' => pick($db_name, 'hue'),
        'desktop.database.user' => $db_user,
      }
      $db_packages = []
      $external_db = true
    }
    'oracle': {
      $db_base_properties = {
        'desktop.database.engine' => 'oracle',
        'desktop.database.host' => $db_host,
        'desktop.database.name' => pick($db_name, 'XE'),
        'desktop.database.user' => $db_user,
      }
      $db_packages = []
      $external_db = true
    }
    'postgresql': {
      $db_base_properties = {
        'desktop.database.engine' => 'postgresql_psycopg2',
        'desktop.database.host' => $db_host,
        'desktop.database.name' => pick($db_name, 'hue'),
        'desktop.database.user' => $db_user,
      }
      $db_packages = $::hue::packages_postgresql
      $external_db = true
    }
  }
  if $external_db and $db_password {
    $db_password_properties = {
      'desktop.database.password' => $db_password,
    }
  } else {
    $db_password_properties = {}
  }
  $db_properties = merge($db_base_properties, $db_password_properties)

  if $realm and !empty($realm) {
    $security_properties = {
      'desktop.kerberos.hue_keytab' => $keytab_hue,
      'desktop.kerberos.hue_pricipal' => "hue/${::fqdn}@${realm}",
      'desktop.kerberos.kinit_path' => '/usr/bin/kinit',
      'hadoop.hdfs_clusters.default.security_enabled' => $security_enabled,
    }
  } else {
    $security_properties = {}
  }
  if $https_hue == undef and !("" in [$https_hue]) {
    $_https_hue = $https
  } else {
    $_https_hue = $https_hue
  }
  if $_https_hue {
    $_https_certificate = "${hue::confdir}/hostcert.pem"
    $_https_private_key = "${hue::confdir}/hostkey.pem"
    $https_base_properties = {
      # strict-transport-security disrupts other services on the same host
      'desktop.secure_hsts_seconds' => 0,
      'desktop.ssl_cacerts' => $https_cachain,
      'desktop.ssl_certificate' => $_https_certificate,
      'desktop.ssl_private_key' => $_https_private_key,
    }
    if $https_passphrase and !empty($https_passphrase) {
      $https_pass_properties = {
        'desktop.ssl_password' => $https_passphrase,
      }
    } else {
      $https_pass_properties = {}
    }
    $https_properties = merge($https_base_properties, $https_pass_properties)
  } else {
    $https_properties = {}
  }

  if $httpfs_hostname and !empty($httpfs_hostname) {
    if $https {
      $hdfs_properties = {
        'hadoop.hdfs_clusters.default.webhdfs_url' => "https://${httpfs_hostname}:14000/webhdfs/v1/",
      }
    } else {
      $hdfs_properties = {
        'hadoop.hdfs_clusters.default.webhdfs_url' => "http://${httpfs_hostname}:14000/webhdfs/v1/",
      }
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
    $hive_base_properties = {
      'beeswax.hive_server_host' => $hive_server2_hostname,
    }
    if $https {
      $hive_ssl_properties = {
        'beeswax.ssl.cacerts' => $https_cachain,
        'beeswax.ssl.enabled' => 'True',
      }
    } else {
      $hive_ssl_properties = {}
    }
    $hive_properties = merge($hive_base_properties, $hive_ssl_properties)
  } else {
    $hive_properties = {}
  }

  if $impala_hostname and !empty($impala_hostname) {
    $impala_base_properties = {
      # usefull for authorization (implemented only partially, HDFS
      # impersonation not avaialable in impala)
      'impala.impersonation_enabled' => True,
      'impala.server_host' => $impala_hostname,
      # port needs to be always specified
      'impala.server_port' => 21050,
    }
    if $https {
      $impala_ssl_properties = {
        'impala.ssl.cacerts' => $https_cachain,
        'impala.ssl.enabled' => 'True',
      }
    } else {
      $impala_ssl_properties = {}
    }
    $impala_properties = merge($impala_base_properties, $impala_ssl_properties)
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
      'liboozie.security_enabled' => $security_enabled,
    }
  } else {
    $oozie_properties = {}
  }

  if $yarn_hostname and !empty($yarn_hostname) {
    $_jhs_hostname = pick($historyserver_hostname, $yarn_hostname2, $yarn_hostname)
    if $https {
      $jhs_url = "https://${_jhs_hostname}:19890"
      $rm1_url = "https://${yarn_hostname}:8090"
    } else {
      $jhs_url = "http://${_jhs_hostname}:19888"
      $rm1_url = "http://${yarn_hostname}:8088"
    }
    $yarn_base_properties = {
      'hadoop.yarn_clusters.default.history_server_api_url' => $jhs_url,
      'hadoop.yarn_clusters.default.proxy_api_url' => $rm1_url,
      'hadoop.yarn_clusters.default.resourcemanager_api_url' => $rm1_url,
      'hadoop.yarn_clusters.default.resourcemanager_host' => $yarn_hostname,
      'hadoop.yarn_clusters.default.security_enabled' => $security_enabled,
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
        'hadoop.yarn_clusters.ha.history_server_api_url' => $jhs_url,
        'hadoop.yarn_clusters.ha.logical_name' => 'rm2',
        'hadoop.yarn_clusters.ha.proxy_api_url' => $rm2_url,
        'hadoop.yarn_clusters.ha.resourcemanager_api_url' => $rm2_url,
        'hadoop.yarn_clusters.ha.resourcemanager_host' => $yarn_hostname2,
        'hadoop.yarn_clusters.ha.security_enabled' => $security_enabled,
        'hadoop.yarn_clusters.ha.submit_to' => 'True',
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

  $_environment = merge({}, $environment)
  $_packages = concat($db_packages, $::hue::package_name)
  $_properties = merge($base_properties, $db_properties, $security_properties, $https_properties, $hdfs_properties, $hive_properties, $impala_properties, $oozie_properties, $yarn_properties, $zoo_properties, $properties)

  class { '::hue::install': } ->
  class { '::hue::config': } ~>
  class { '::hue::service': } ->
  Class['::hue']
}
