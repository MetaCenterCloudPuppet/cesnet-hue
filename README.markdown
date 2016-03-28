#### Table of Contents

1. [Module Description - What the module does and why it is useful](#module-description)
2. [Setup - The basics of getting started with hue](#setup)
    * [What hue affects](#what-hue-affects)
    * [Setup requirements](#setup-requirements)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Module Description

Installs Apache Hue - web user interface for Hadoop.

## Setup

### What hue affects

* Alternatives:
 * alternatives are used for */etc/hue/conf* in Cloudera
 * this module switches to the new alternative by default, so the original configuration can be kept intact
* Files modified: */etc/hue/conf/hue.ini*
* Packages: *hue*

### Setup Requirements

* Hadoop cluster with WebHDFS or httpfs
* ...

## Usage

    class { '::hue':
      hdfs_hostname => 'hdfs.example.com',
    }

## Reference

### Classes

* [**`hue`**](#class-hue): The main configuration class
* `hue::common::postinstall`: Preparation steps after installation
* `hue::config`: Configuration of Apache Hue
* `hue::install`: Installation of Apache Hue
* `hue::params`
* `hue::service`: Ensure the Apache Hue is running

<a name="class-hue">
### Class `hue`

The main configuration class.

####`alternatives`

Switches the alternatives used for the configuration. Default: 'cluster' (Debian
) or undef.

It can be used only when supported (for example with Cloudera distribution).

####`defaultFS`

Default: undef ("hdfs://${hdfs\_hostname}:8020").

####`group`

Default user group for newly created users. Default: 'users'.

####`hdfs_hostname`

Hadoop HDFS hostname. Required.

####`httpfs_hostname`

HTTPFS proxy hostname, if available. Default: true.

It is required with HDFS High Availability. It should be the same machine as Apache Hue.

####`hive_server2_hostname`

Hive Server2 hostname. Default: undef.

####`https`

Enable support for https. Default: false.

####`oozie_hostname`

Oozie server hostname. Default: undef.

####`properties`

"Raw" properties for hadoop cluster. Default: undef.

"::undef" value will remove given property set automatically by this module, empty string sets the empty value.

####`package_name`

Hue package name. Default: 'hue'.

####`service_name`

Hue service name. Default: 'hue'.

####`yarn_hostname`

Hadoop YARN Resourcemanager hostname. Default: undef.

####`yarn_hostname2`

Hadoop YARN Second Resourcemanager hostname, when high availability is used. Default: undef.

####`zookeeper_hostnames`

List of zookeeper hostnames. Default: [].

####`zookeeper_rest_hostname`

Zookeeper REST server hostname. Default: undef.

Not available in Cloudera. Sources are available at [https://github.com/apache/zookeeper](https://github.com/apache/zookeeper/tree/trunk/src/contrib/rest).

## Limitations

No Java is installed nor software repository set (you can use other puppet modules for that: *cesnet-java\_ng* , *puppetlabs::java*, *cesnet::site\_hadoop*, *razorsedge/cloudera*, ...).

## Development

* Repository: [https://github.com/MetaCenterCloudPuppet/cesnet-hue](https://github.com/MetaCenterCloudPuppet/cesnet-hue)
* Tests:
 * basic: see *.travis.yml*
