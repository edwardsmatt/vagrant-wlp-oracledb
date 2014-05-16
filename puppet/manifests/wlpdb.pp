node 'wlpdb'  {
   include wlpdb_os
   include wlpdb_11g
   include wlpdb_maintenance
   include wlpdb_java

}

# operating settings for Database & Middleware
class wlpdb_os {

  service { iptables:
        enable    => false,
        ensure    => false,
        hasstatus => true,
  }


  group { 'oper' :
    ensure      => present,
  }

  group { 'oinstall' :
    ensure      => present,
  }

  group { 'dba' :
    ensure      => present,
  }

  user { 'oracle' :
    ensure      => present,
    gid         => 'dba',
    groups      => 'dba',
    shell       => '/bin/bash',
    password    => '$1$DSJ51vh6$4XzzwyIOk6Bi/54kglGk3.',
    home        => "/home/oracle",
    comment     => "This user ${user} was created by Puppet",
    require     => Group['dba', 'oinstall','oper'],
    managehome  => true,
  }

  $install = [ 'binutils.x86_64', 'compat-libstdc++-33.x86_64', 'glibc.x86_64','ksh.x86_64','libaio.x86_64',
               'libgcc.x86_64', 'libstdc++.x86_64', 'make.x86_64','compat-libcap1.x86_64', 'gcc.x86_64',
               'gcc-c++.x86_64','glibc-devel.x86_64','libaio-devel.x86_64','libstdc++-devel.x86_64',
               'sysstat.x86_64','unixODBC-devel','glibc.i686','libXext.i686','libXtst.i686']


  augeas {'yum_conf':
    context   => "/files/etc/yum.conf",
    changes   => [ "set main/proxy http://10.0.2.2:3128" ],
  }

  package { $install:
    ensure  => present,
    require => Augeas['yum_conf'],
  }

  class { 'limits':
         config => {
                    '*'       => { 'nofile'  => { soft => '2048'   , hard => '8192',   },},
                    'oracle'  => { 'nofile'  => { soft => '65536'  , hard => '65536',  },
                                    'nproc'  => { soft => '2048'   , hard => '16384',  },
                                    'stack'  => { soft => '10240'  ,},},
                    },
         use_hiera => false,
  }

  sysctl { 'kernel.msgmnb':                 ensure => 'present', permanent => 'yes', value => '65536',}
  sysctl { 'kernel.msgmax':                 ensure => 'present', permanent => 'yes', value => '65536',}
  sysctl { 'kernel.shmmax':                 ensure => 'present', permanent => 'yes', value => '2588483584',}
  sysctl { 'kernel.shmall':                 ensure => 'present', permanent => 'yes', value => '2097152',}
  sysctl { 'fs.file-max':                   ensure => 'present', permanent => 'yes', value => '6815744',}
  sysctl { 'net.ipv4.tcp_keepalive_time':   ensure => 'present', permanent => 'yes', value => '1800',}
  sysctl { 'net.ipv4.tcp_keepalive_intvl':  ensure => 'present', permanent => 'yes', value => '30',}
  sysctl { 'net.ipv4.tcp_keepalive_probes': ensure => 'present', permanent => 'yes', value => '5',}
  sysctl { 'net.ipv4.tcp_fin_timeout':      ensure => 'present', permanent => 'yes', value => '30',}
  sysctl { 'kernel.shmmni':                 ensure => 'present', permanent => 'yes', value => '4096', }
  sysctl { 'fs.aio-max-nr':                 ensure => 'present', permanent => 'yes', value => '1048576',}
  sysctl { 'kernel.sem':                    ensure => 'present', permanent => 'yes', value => '250 32000 100 128',}
  sysctl { 'net.ipv4.ip_local_port_range':  ensure => 'present', permanent => 'yes', value => '9000 65500',}
  sysctl { 'net.core.rmem_default':         ensure => 'present', permanent => 'yes', value => '262144',}
  sysctl { 'net.core.rmem_max':             ensure => 'present', permanent => 'yes', value => '4194304', }
  sysctl { 'net.core.wmem_default':         ensure => 'present', permanent => 'yes', value => '262144',}
  sysctl { 'net.core.wmem_max':             ensure => 'present', permanent => 'yes', value => '1048576',}

}

class wlpdb_11g {
  require wlpdb_os

    oradb::installdb{ '11.2_linux-x64':
            version                => '11.2.0.4',
            file                   => 'p13390677_112040_Linux-x86-64',
            databaseType           => 'SE',
            oracleBase             => hiera('oracle_base_dir'),
            oracleHome             => hiera('oracle_home_dir'),
            userBaseDir            => '/home',
            createUser             => true,
            user                   => hiera('oracle_os_user'),
            group                  => hiera('oracle_os_group'),
            downloadDir            => hiera('oracle_download_dir'),
            remoteFile             => false,
            puppetDownloadMntPoint => hiera('oracle_source'),
            # group_install          => 'oinstall',
            # group_oper             => 'oper',
    }

   oradb::net{ 'config net8':
            oracleHome   => hiera('oracle_home_dir'),
            version      => hiera('oracle_version'),
            user         => hiera('oracle_os_user'),
            group        => hiera('oracle_os_group'),
            downloadDir  => hiera('oracle_download_dir'),
            require      => Oradb::Installdb['11.2_linux-x64'],
   }

   oradb::listener{'start listener':
            oracleBase   => hiera('oracle_base_dir'),
            oracleHome   => hiera('oracle_home_dir'),
            user         => hiera('oracle_os_user'),
            group        => hiera('oracle_os_group'),
            action       => 'start',
            require      => Oradb::Net['config net8'],
   }

   oradb::database{ 'wlpdb':
                    oracleBase              => hiera('oracle_base_dir'),
                    oracleHome              => hiera('oracle_home_dir'),
                    version                 => hiera('oracle_version'),
                    user                    => hiera('oracle_os_user'),
                    group                   => hiera('oracle_os_group'),
                    downloadDir             => hiera('oracle_download_dir'),
                    action                  => 'create',
                    dbName                  => hiera('oracle_database_name'),
                    dbDomain                => hiera('oracle_database_domain_name'),
                    sysPassword             => hiera('oracle_database_sys_password'),
                    systemPassword          => hiera('oracle_database_system_password'),
                    dataFileDestination     => "/oracle/oradata",
                    recoveryAreaDestination => "/oracle/flash_recovery_area",
                    characterSet            => "AL32UTF8",
                    nationalCharacterSet    => "UTF8",
                    initParams              => "open_cursors=1000,processes=600,job_queue_processes=4",
                    sampleSchema            => 'FALSE',
                    memoryPercentage        => "40",
                    memoryTotal             => "800",
                    databaseType            => "MULTIPURPOSE",
                    require                 => Oradb::Listener['start listener'],
   }

   oradb::dbactions{ 'start wlpdb':
                   oracleHome              => hiera('oracle_home_dir'),
                   user                    => hiera('oracle_os_user'),
                   group                   => hiera('oracle_os_group'),
                   action                  => 'start',
                   dbName                  => hiera('oracle_database_name'),
                   require                 => Oradb::Database['wlpdb'],
   }

   oradb::autostartdatabase{ 'autostart oracle':
                   oracleHome              => hiera('oracle_home_dir'),
                   user                    => hiera('oracle_os_user'),
                   dbName                  => hiera('oracle_database_name'),
                   require                 => Oradb::Dbactions['start wlpdb'],
   }

  tablespace {'weblogic_portal':
    ensure                    => present,
    size                      => 300M,
    datafile                  => 'weblogic_portal.dbf',
    logging                   => yes,
    autoextend                => on,
    next                      => 100M,
    max_size                  => 12288M,
    extent_management         => local,
    segment_space_management  => auto,
    require                   => Oradb::Autostartdatabase['autostart oracle'],
  }

  oracle_user{'weblogic':
    temporary_tablespace      => temp,
    default_tablespace        => 'weblogic_portal',
    password                  => 'weblogic',
    grants                    => ['CREATE TABLE, CREATE VIEW, CREATE TRIGGER, CREATE SEQUENCE, CREATE SESSION'],
    quotas                    => { "weblogic_portal" => 'unlimited'},
    require                   => Tablespace['weblogic_portal'],
  }
}

class wlpdb_maintenance {
  require wlpdb_11g

  $mtimeParam = "1"

  cron { 'oracle_db_opatch' :
    command => "find /oracle/product/11.2/db/cfgtoollogs/opatch -name 'opatch*.log' -mtime ${mtimeParam} -exec rm {} \\; >> /tmp/opatch_db_purge.log 2>&1",
    user    => oracle,
    hour    => 06,
    minute  => 34,
  }

  cron { 'oracle_db_lsinv' :
    command => "find /oracle/product/11.2/db/cfgtoollogs/opatch/lsinv -name 'lsinventory*.txt' -mtime ${mtimeParam} -exec rm {} \\; >> /tmp/opatch_lsinv_db_purge.log 2>&1",
    user    => oracle,
    hour    => 06,
    minute  => 32,
  }


}

class wlpdb_java {
  require wlpdb_os

  include jdk7

  jdk7::install7{ 'jdk1.7.0_51':
    version              => "7u51" ,
    fullVersion          => "jdk1.7.0_51",
    alternativesPriority => 18000,
    x64                  => true,
    downloadDir          => "/data/install",
    urandomJavaFix       => false,
    sourcePath           => "/software"
  }

  class { 'jdk7::urandomfix' :}


}
