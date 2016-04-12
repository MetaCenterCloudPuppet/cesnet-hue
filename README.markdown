## Apache Hue Web Interface

[![Build Status](https://travis-ci.org/MetaCenterCloudPuppet/cesnet-hue.svg?branch=master)](https://travis-ci.org/MetaCenterCloudPuppet/cesnet-hue)

#### Table of Contents

1. [Module Description - What the module does and why it is useful](#module-description)
2. [Setup - The basics of getting started with hue](#setup)
    * [What hue affects](#what-hue-affects)
    * [Setup requirements](#setup-requirements)
3. [Usage - Configuration options and additional functionality](#usage)
    * [Basic cluster usage](#basic-cluster-usage)
    * [High availability cluster usage](#high-availability-cluster-usage)
    * [Enable security](#enable-security)
    * [Enable SPNEGO authentization](#enable-spnego-authentization)
    * [MySQL backend](#mysql-backend)
    * [PostgreSQL backend](#postgresql-backend)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
    * [Classes](#classes)
    * [Module Parameters (hue class)](#class-hue)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Module Description

Installs Apache Hue - web user interface for Hadoop environment.

## Setup

### What hue affects

* Alternatives:
 * alternatives are used for */etc/hue/conf* in Cloudera
 * this module switches to the new alternative by default, so the original configuration can be kept intact
* Files modified:
 * */etc/hue/conf/hue.ini*
 * */etc/security/keytab/hue.service.keytab* ownership changed (only when security is enabled, the path can be changed by *keytab_hue* parameter)
 * */etc/grid-security/hostcert.pem* copied to */etc/hue/conf/* (only with *https*)
 * */etc/grid-security/hostkey.pem* copied to */etc/hue/conf/* (only with *https*)
 * when using external database, the import logs in */var/lib/hue/logs/* are kept
* Helper files:
 * */var/lib/hue/.puppet-init1-syncdb*
 * */var/lib/hue/.puppet-init1-migrate*
* Packages: *hue*, *python-psycopg2* (when postgres DB is used)
* Services: *hue*
* Users and groups:
 * *hue::hdfs* and *hue::user* classes creates the user *hue* and group *hue*
* When using external database: data are imported using hue tools

### Setup Requirements

* Hadoop cluster with WebHDFS or httpfs (httpfs is required for HDFS HA)
* HBase with thrift server (optional)
* Hive Server2 (optional)
* Oozie Server (optional)
* Authorizations set
 * 'hue' user must be enabled in *security.client.protocol.acl*, default '*' is OK
* Proxy users set for Hadoop core, Hadoop httpfs, Ozzie server and Hive
 * for *cesnet::hadoop* puppet module: parameters *hue\_hostnames* and *httpfs\_hostnames*
 * for *cesnet::oozie* puppet module: parameter *hue\_hostnames*
 * for *cesnet::hive* puppet module:
  * add 'oozie' and 'hive' to *hadoop.proxyuser.hive.groups*
  * set also *hadoop.proxyuser.hive.hosts* as needed
* with security:
 * secured cluster
 * Oozie property (among the others): *oozie.credentials.credentialclasses*

## Usage

### Basic cluster usage

    $master_hostname = 'hdfs.example.com'
    $hue_hostname = 'hue.example.com'
    $secret = 'I sleep with my cats.'

    class { '::hadoop':
      ...
      hue_hostnames => ['hue.example.com'],
      #oozie_hostnames => [...],
    }

    node 'hdfs.example.com' {
      include ::hadoop::namenode
      ...
      include ::hue::hdfs
    }

    node 'hue.example.com' {
      class { '::hue':
        hdfs_hostname => $master_hostname,
        #yarn_hostname  => ...,
        #oozie_hostname => ...,
        secret        => $secret,
      }
    }

### High availability cluster usage

    $cluster_name = 'cluster',
    $master_hostnames = [
      'master1.example.com',
      'master2.example.com',
    ]
    $hue_hostname = 'hue.example.com'
    $secret = "Trump's real name is Drumph."

    class { '::hadoop':
      ...
      cluster_name     => $cluster_name,
      hdfs_hostname    => $master_hostnames[0],
      hdfs_hostname2   => $master_hostnames[1],
      hue_hostnames    => [$hue_hostname],
      httpfs_hostnames => [$hue_hostname],
      yarn_hostname    => $master_hostnames[0],
      yarn_hostname2   => $master_hostnames[1],
      #oozie_hostnames => [...],
    }

    node 'master1.example.com' {
      include ::hadoop::namenode
      ...
      include ::hue::hdfs
    }

    node 'master2.example.com' {
      include ::hadoop::namenode
      ...
      include ::hue::user
    }

    node 'hue.example.com' {
      include ::hadoop::httpfs
      class { '::hue':
        defaultFS       => "hdfs://${cluster_name}",
        httpfs_hostname => $hue_hostname,
        yarn_hostname   => $master_hostnames[0],
        yarn_hostname2  => $master_hostnames[1],
        #oozie_hostname => ...,
        secret          => $secret,
      }
    }

There is also needed class *hue::hdfs* on all HDFS Namenodes to authorization work properly. You can use *hue::user* instead, or install *hue-common* package.

It is recommended to set properties *hadoop.yarn\_clusters.default.logical\_name* and *hadoop.yarn\_clusters.ha.logical\_name* according to the *yarn.resourcemanager.ha.rm-ids* from Hadoop YARN. *cesnet-hue* module uses 'rm1' and 'rm2' values, which is *cesnet-hadoop* puppet module default.

### Enable security

Use *realm* parameter to set the Kerberos realm and enable security. *https* parameter will enable SSL support.

Useful parameters:

* [*https*](#https)
* [*https\_cachain*](#https_cachain)
* [*https\_certificate*](#https_certificate)
* [*https\_private\_key*](#https_private_key)
* [*https\_passphrase*](#https_passphrase)
* [*keytab\_hue*](#keytab_hue)
* [*realm*](#realm)

Default credential files locations:

* */etc/security/keytab/hue.service.keytab*
* */etc/grid-security/hostcert.pem*
* */etc/grid-security/hostkey.pem*
* */etc/hue/cacerts.pem* (system default)

### Enable SPNEGO authentization

You can authenticate over HTTPS using Kerberos ticket.

For that is needed kerberos keytab with principals (replace *HOSTNAME* and *REALM* by real values):

* hue/*HOSTNAME*@*REALM*
* HTTP/*HOSTNAME*@*REALM*

You will need to set *KRB5\_KTNAME* in *environment* parameter.

Also you will need to set the auth backend to *desktop.auth.backend.SpnegoDjangoBackend*.

**Example** (hiera yaml format):

    hue::environment:
     KRB5_KTNAME:  /etc/security/keytab/hue-http.service.keytab
    hue::keytab_hue: /etc/security/keytab/hue.service.keytab
    hue::properties:
     desktop.auth.backend: desktop.auth.backend.SpnegoDjangoBackend

### MySQL backend

It is recommended to use a full database instead of sqlite.

Example of using MySQL with *puppetlabs-mysql* puppet module:

    node 'hue.example.com' {
      ...

      class{'::hue':
        ...
        db          => 'mysql',
        db_password => 'huepassword',
      }

      class { '::mysql::server':
        root_password  => 'strongpassword',
      }

      mysql::db { 'hue':
        user     => 'hue',
        password => 'huepassword',
        grant    => ['ALL'],
      }

      # database import in the hue::service, database also required for hue
      Mysql::Db['hue'] -> Class['hue::service']
    }

### PostgreSQL backend

It is recommended to use a full database instead of sqlite.

Example of using PostgreSQL with *puppetlabs-postgresql* puppet module:

    node 'hue.example.com' {
      ...

      class{'::hue':
        ...
        db          => 'postgresql',
        db_password => 'huepassword',
      }

      class { '::postgresql::server':
        postgres_password  => 'strongpassword',
      }

      postgresql::server::db { 'hue':
        user     => 'hue',
        password => postgresql_password('hue', 'huepassword'),
      }

      # database import in the hue::service, database also required for hue
      Postgresql::Server::Db['hue'] -> Class['hue::service']
    }

## Reference

<a name="classes">
### Classes

* [**`hue`**](#class-hue): The main configuration class
* `hue::common::postinstall`: Preparation steps after installation
* `hue::config`: Configuration of Apache Hue
* [**`hue::hdfs`**](#class-hue-hdfs): HDFS initialization
* `hue::install`: Installation of Apache Hue
* `hue::params`
* `hue::service`: Ensure the Apache Hue is running
* [**`hue::user`**](#class-hue-user): Create hue system user, if needed

<a name="class-hue">
### Class `hue`

The main deployment class.

####`alternatives`

Switches the alternatives used for the configuration. Default: 'cluster' (Debian
) or undef.

It can be used only when supported (for example with Cloudera distribution).

####`db`

Database backend for Hue. Default: undef.

The default is the *sqlite* database, but it is recommended to use a full database.

Values:

* **sqlite** (default): database in the file
* **mariadb**, **mysql**: MySQL/MariaDB
* **oracle**: Oracle database
* **postgresql**: PostgreSQL

It can be overridden by *desktop.database.engine* property.

####`db_host`

Database hostname for *mariadb*, *mysql*, *postgresql*. Default: 'localhost'.

It can be overridden by *desktop.database.host* property.

####`db_name`

The file for *sqlite*, database name for *mariadb*, *mysql* and *postgresql*, or database name or SID for *oracle*. Default: undef.

Default values:

* *sqlite*: */var/lib/hue/desktop.db*
* *mariadb*, *mysql*, *postgresql*: *hue*
* *oracle*: *XE*

It can be overridden by *desktop.database.name* property.

####`db_user`

Database user for *mariadb*, *mysql*, and *postgresql*. Default: 'hue'.

####`db_password`

Database password for *mariadb*, *mysql*, and *postgresql*. Default: undef.

####`defaultFS`

HDFS defaultFS. Default: undef ("hdfs://${hdfs\_hostname}:8020").

The value is required for HA HDFS cluster. For non-HA cluster the automatic value from *hdfs\_hostname* parameter is fine.

####`environment`

Environment to set for Hue daemon. Default: undef.

    environment => {
      'KRB5_KTNAME' => '/var/lib/hue/hue.keytab',
    }

####`group`

Default user group for newly created users. Default: 'users'.

####`hdfs_hostname`

Hadoop HDFS hostname. Default: undef.

The value is required for non-HA HDFS cluster (for HDFS HA, the parameters *httpfs\_hostname* and *defaultFS* must be used instead).

####`historyserver_hostname`

Hadoop MapReduce Job History hostname. Default: undef.

By default, the value is *yarn\_hostname2*, or *yarn\_hostname*.

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

The certificate file is copied into Hue configuration directory.

####`https_private_key`

Private key file in PEM format. Default: '/etc/grid-security/hostkey.pem'.

The key file is copied into Hue configuration directory.

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

HDFS initialization. Actions necessary to launch on HDFS namenode: Create hue user, if needed.

This class or *hue::user* class is needed to be launched on all HDFS namenodes.

<a name="class-hue-user">
### Class `hue::user`

Creates hue system user, if needed. The hue user is required on the all HDFS namenodes to authorization work properly and we don't need to install hue just for the user.

It is better to handle creating the user by the packages, so we recommend dependency on installation classes or Hue packages.

## Limitations

No Java is installed nor software repository set (you can use other puppet modules for that: *cesnet-java\_ng* , *puppetlabs::java*, *cesnet::site\_hadoop*, *razorsedge/cloudera*, ...).

## Development

* Repository: [https://github.com/MetaCenterCloudPuppet/cesnet-hue](https://github.com/MetaCenterCloudPuppet/cesnet-hue)
* Tests:
 * basic: see *.travis.yml*
