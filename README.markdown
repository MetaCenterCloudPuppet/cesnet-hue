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

Default: "hdfs://${hdfs\_hostname}:8020".

####`hdfs_hostname`

Hadoop HDFS hostname. Required.

####`hdfs_enable`

Default: true.

####`httpfs_enable`

Default: false.

####`hive_server2_hostname`

Hive Server2 hostname. Default: undef.

####`https`

Enable support for https. Default: false.

####`properties`

"Raw" properties for hadoop cluster. Default: undef.

"::undef" value will remove given property set automatically by this module, empty string sets the empty value.

####`package_name`

Hue package name. Default: 'hue'.

####`service_name`

Hue service name. Default: 'hue'.

## Limitations

No Java is installed nor software repository set (you can use other puppet modules for that: *cesnet-java\_ng* , *puppetlabs::java*, *cesnet::site\_hadoop*, *razorsedge/cloudera*, ...).

## Development

* Repository: [https://github.com/MetaCenterCloudPuppet/cesnet-hue](https://github.com/MetaCenterCloudPuppet/cesnet-hue)
* Tests:
 * basic: see *.travis.yml*
