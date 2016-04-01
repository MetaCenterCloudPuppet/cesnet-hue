#### Table of Contents

1. [Module Description - What the module does and why it is useful](#module-description)
2. [Setup - The basics of getting started with hue](#setup)
    * [What hue affects](#what-hue-affects)
    * [Setup requirements](#setup-requirements)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
    * [Classes](#classes)
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

There is also needed class *hue::hdfs* on all HDFS Namenodes to authoriation work properly. You can use also *hue::user*, or install *hue-common* package.

## Reference

<a name="classes">
### Classes

* [**`hue`**](#class-hue): The main configuration class
* `hue::common::postinstall`: Preparation steps after installation
* `hue::config`: Configuration of Apache Hue
* [**`hue::hdfs`**](#class-hue-hdfs): HDFS initialiations
* `hue::install`: Installation of Apache Hue
* `hue::params`
* `hue::service`: Ensure the Apache Hue is running
* [**`hue::user`**](#class-hue-user): Create hue system user, if needed

<a name="class-hue">
### Class `hue`

The main configuration class.

####`alternatives`

Switches the alternatives used for the configuration. Default: 'cluster' (Debian
) or undef.

It can be used only when supported (for example with Cloudera distribution).

####`defaultFS`

HDFS defaultFS. Default: undef ("hdfs://${hdfs\_hostname}:8020").

The value is required for HA HDFS cluster. For non-HA cluster the automatic value from *hdfs_hostname* parameter is fine.

####`group`

Default user group for newly created users. Default: 'users'.

####`hdfs_hostname`

Hadoop HDFS hostname. Default: undef.

The value is required for non-HA HDFS cluster (for HDFS HA, the parameters *httpfs_hostname* and *defaultFS* must be used instead).

####`httpfs_hostname`

HTTPFS proxy hostname, if available. Default: undef.

It is required with HDFS High Availability. We recommend to have it on the same machine with Apache Hue.

####`hive_server2_hostname`

Hive Server2 hostname. Default: undef.

####`impala_hostname`

Impala server hostname. Default: undef.

Use one of the impalad.

####`https`

Enable support for https. Default: false.

####`https_cachain`

CA chain file in PEM format. Default: undef.

System default is */etc/hue/cacerts.pem*.

####`https_certificate`

Certificate file in PEM format. Default: '/etc/grid-security/hostcert.pem'.

The certificate file is copied into Hue configuraton directory.

####`https_private_key`

Private key file in PEM format. Default: '/etc/grid-security/hostkey.pem'.

The key file is copied into Hue configuraton directory.

####`https_passphrase`

Default: undef.

####`keytab_hue`

Default: "/etc/security/keytabs/hue.service.keytab".

Hue keytab file with *hue/HOSTNAME@REALM* principal.

####`oozie_hostname`

Oozie server hostname. Default: undef.

####`properties`

"Raw" properties for hadoop cluster. Default: undef.

"::undef" value will remove given property set automatically by this module, empty string sets the empty value.

####`package_name`

Hue package name. Default: 'hue'.

####`service_name`

Hue service name. Default: 'hue'.

####`realm`

Kerberos realm. Default: undef.

Non-empty value enables the security.

####`yarn_hostname`

Hadoop YARN Resourcemanager hostname. Default: undef.

####`yarn_hostname2`

Hadoop YARN Second Resourcemanager hostname, when high availability is used. Default: undef.

####`zookeeper_hostnames`

List of zookeeper hostnames. Default: [].

####`zookeeper_rest_hostname`

Zookeeper REST server hostname. Default: undef.

Not available in Cloudera. Sources are available at [https://github.com/apache/zookeeper](https://github.com/apache/zookeeper/tree/trunk/src/contrib/rest).

<a name="class-hue-hdfs">
### Class `hue::hdfs`

HDFS initialiations. Actions necessary to launch on HDFS namenode: Create hue user, if needed.

This class or *hue::user* class is needed to be launched on all HDFS namenodes.

<a name="class-hue-user">
### Class `hue::user`

Creates hue system user, if needed. The hue user is required on the all HDFS namenodes to autorization work properly and we don't need to install hue just for the user.

It is better to handle creating the user by the packages, so we recommend dependency on installation classes or Hue packages.

## Limitations

No Java is installed nor software repository set (you can use other puppet modules for that: *cesnet-java\_ng* , *puppetlabs::java*, *cesnet::site\_hadoop*, *razorsedge/cloudera*, ...).

## Development

* Repository: [https://github.com/MetaCenterCloudPuppet/cesnet-hue](https://github.com/MetaCenterCloudPuppet/cesnet-hue)
* Tests:
 * basic: see *.travis.yml*
