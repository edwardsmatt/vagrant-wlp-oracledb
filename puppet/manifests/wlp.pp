# test
#
# one machine setup with WebLogic Portal 10.3.0.0
# needs jdk7, orawls, orautils, fiddyspence-sysctl, erwbgy-limits puppet modules
#

node 'wlp.example.com' {

   include os, java, ssh, orautils
   include wlp1030
   include wlp1030_domain
   include maintenance

   Class['os']  ->
     Class['ssh']  ->
       Class['java']  ->
         Class['wlp1030'] ->
           Class['wlp1030_domain']
}

# operating settings for Middleware
class os {

  notice "class os ${operatingsystem}"

  $default_params = {}
  $host_instances = hiera('hosts', [])
  create_resources('host',$host_instances, $default_params)

  exec { "create swap file":
    command => "/bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=8192",
    creates => "/var/swap.1",
  }

  exec { "attach swap file":
    command => "/sbin/mkswap /var/swap.1 && /sbin/swapon /var/swap.1",
    require => Exec["create swap file"],
    unless => "/sbin/swapon -s | grep /var/swap.1",
  }

  #add swap file entry to fstab
  exec {"add swapfile entry to fstab":
    command => "/bin/echo >>/etc/fstab /var/swap.1 swap swap defaults 0 0",
    require => Exec["attach swap file"],
    user => root,
    unless => "/bin/grep '^/var/swap.1' /etc/fstab 2>/dev/null",
  }

  service { iptables:
        enable    => false,
        ensure    => false,
        hasstatus => true,
  }

  group { 'dba' :
    ensure => present,
  }

  # http://raftaman.net/?p=1311 for generating password
  # password = oracle
  user { 'oracle' :
    ensure     => present,
    groups     => 'dba',
    shell      => '/bin/bash',
    password   => '$1$DSJ51vh6$4XzzwyIOk6Bi/54kglGk3.',
    home       => "/home/oracle",
    comment    => 'oracle user created by Puppet',
    managehome => true,
    require    => Group['dba'],
  }

  $install = [ 'binutils.x86_64','unzip.x86_64', 'lsb']

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
               '*'       => {  'nofile'  => { soft => '2048'   , hard => '8192',   },},
               'oracle'  => {  'nofile'  => { soft => '65536'  , hard => '65536',  },
                               'nproc'   => { soft => '2048'   , hard => '16384',   },
                               'memlock' => { soft => '1048576', hard => '1048576',},
                               'stack'   => { soft => '10240'  ,},},
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

class ssh {
  require os

  notice 'class ssh'

  file { "/home/oracle/.ssh/":
    owner  => "oracle",
    group  => "dba",
    mode   => "700",
    ensure => "directory",
    alias  => "oracle-ssh-dir",
  }

  file { "/home/oracle/.ssh/id_rsa.pub":
    ensure  => present,
    owner   => "oracle",
    group   => "dba",
    mode    => "644",
    source  => "/vagrant/ssh/id_rsa.pub",
    require => File["oracle-ssh-dir"],
  }

  file { "/home/oracle/.ssh/id_rsa":
    ensure  => present,
    owner   => "oracle",
    group   => "dba",
    mode    => "600",
    source  => "/vagrant/ssh/id_rsa",
    require => File["oracle-ssh-dir"],
  }

  file { "/home/oracle/.ssh/authorized_keys":
    ensure  => present,
    owner   => "oracle",
    group   => "dba",
    mode    => "644",
    source  => "/vagrant/ssh/id_rsa.pub",
    require => File["oracle-ssh-dir"],
  }
}

class java {
  require os

  notice 'class java'

  $remove = [ "java-1.7.0-openjdk.x86_64", "java-1.6.0-openjdk.x86_64" ]

  package { $remove:
    ensure  => absent,
  }

  include jdk7

  jdk7::install7{ 'jdk1.7.0_51':
      version              => "7u51" ,
      fullVersion          => "jdk1.7.0_51",
      alternativesPriority => 18000,
      x64                  => true,
      downloadDir          => hiera('wls_download_dir'),
      urandomJavaFix       => true,
      sourcePath           => hiera('wls_source'),
  }

}

class wlp1030{

   class { 'wls::urandomfix' :}

   $wlp_jdk_version  = hiera('wls_jdk_version')
   $wlp_version = hiera('wls_version')

   $puppetDownloadMntPoint = hiera('wls_source')

   $osOracleHome = hiera('wls_oracle_base_home_dir')
   $osMdwHome    = hiera('wls_middleware_home_dir')
   $osWlHome     = hiera('wls_weblogic_home_dir')
   $osWlWHome    = hiera('wls_weblogic_workshop_dir')
   $osWlPHome    = hiera('wls_weblogic_portal_dir')
   $user         = hiera('wls_os_user')
   $group        = hiera('wls_os_group')
   $downloadDir  = hiera('wls_download_dir')
   $logDir       = hiera('wls_log_dir')


  # install WebLogic Portal
  wlp::installwlp{'10g':
    version                => $wlp_version,
    fullJDKName            => $wlp_jdk_version,
    oracleHome             => $osOracleHome,
    mdwHome                => $osMdwHome,
    user                   => $user,
    group                  => $group,
    downloadDir            => $downloadDir,
    puppetDownloadMntPoint => $puppetDownloadMntPoint,
    createUser             => false,
  }

  #nodemanager configuration and starting
  wls::nodemanager{'nodemanager10g':
    wlHome        => $osWlHome,
    fullJDKName   => $wlp_jdk_version,
    user          => $user,
    group         => $group,
    serviceName   => $serviceName,
    downloadDir   => $downloadDir,
    listenPort    => hiera('domain_nodemanager_port'),
    listenAddress => hiera('domain_adminserver_address'),
    logDir        => $logDir,
    require       => Wlp::Installwlp['10g'],
  }

}

class wlp1030_domain{


  $wlsDomainName   = hiera('domain_name')
  $wlsDomainsPath  = hiera('wls_domains_path_dir')
  $osTemplate      = hiera('domain_template')

  $adminListenPort = hiera('domain_adminserver_port')
  $nodemanagerPort = hiera('domain_nodemanager_port')
  $address         = hiera('domain_adminserver_address')

  $userConfigDir   = hiera('wls_user_config_dir')
  $wlp_jdk_version    = hiera('wls_jdk_version')

  $osOracleHome = hiera('wls_oracle_base_home_dir')
  $osMdwHome    = hiera('wls_middleware_home_dir')
  $osWlHome     = hiera('wls_weblogic_home_dir')
  $osWlWHome    = hiera('wls_weblogic_workshop_dir')
  $osWlPHome    = hiera('wls_weblogic_portal_dir')
  $user         = hiera('wls_os_user')
  $group        = hiera('wls_os_group')
  $downloadDir  = hiera('wls_download_dir')
  $logDir       = hiera('wls_log_dir')

 orautils::nodemanagerautostart{"autostart ${wlsDomainName}":
    version     => "1030",
    wlHome      => $osWlHome,
    user        => $user,
    logDir      => $logDir,
  }

  service {'nodemanager_1030':
    enable    => true,
    ensure    => running,
    hasstatus => true,
    require   => Orautils::Nodemanagerautostart["autostart ${wlsDomainName}"],
  }

  # install Weblogic Portal Domain
  wlp::wlpdomain{'portal_domain':
    version         => "1030",
    wlHome          => $osWlHome,
    wlpHome         => $osWlPHome,
    wlwHome         => $osWlWHome,
    mdwHome         => $osMdwHome,
    fullJDKName     => $wlp_jdk_version,
    wlsTemplate     => $osTemplate,
    domain          => $wlsDomainName,
    developmentMode => false,
    adminServerName => hiera('domain_adminserver'),
    adminListenAdr  => $address,
    adminListenPort => $adminListenPort,
    nodemanagerPort => $nodemanagerPort,
    wlsUser         => hiera('wls_weblogic_user'),
    password        => hiera('domain_wls_password'),
    user            => $user,
    group           => $group,
    logDir          => $logDir,
    downloadDir     => $downloadDir,
  }

  wlp::database_properties { 'database_properties':
    wlp_dir       => "${wlsDomainsPath}/${wlsDomainName}",
    full_jdk_name => $wlp_jdk_version,
    user          => $user,
    group         => $group,
    require       => Wlp::Wlpdomain['portal_domain'],
  }

 # default parameters for the wlst scripts
 Wls::Wlstexec {
   version      => '1030',
   wlHome       => $osWlHome,
   fullJDKName  => $wlp_jdk_version,
   user         => $user,
   group        => $group,
   downloadDir  => $downloadDir,
   templateDir  => 'wlp/wlst'
}


  # create jdbc cgDataSource datasource
  wls::wlstexec {'cgDataSource':
     script        => 'createJdbcDatasourceOffline.py',
     params        => [
                      "domainPath                  = '${wlsDomainsPath}/${wlsDomainName}'",
                      "dsName                      = 'cgDataSource'",
                      "jdbcDatasourceTargets       = 'AdminServer'",
                      "dsDriverName                = 'oracle.jdbc.OracleDriver'",
                      "dsURL                       = 'jdbc:oracle:thin:@wcdb.example.com:1521/test.oracle.com'",
                      "dsUserName                  = 'weblogic'",
                      "dsPassword                  = 'weblogic'",
                      "datasourceTargetType        = 'Server'",
                      "globalTransactionsProtocol  = 'EmulateTwoPhaseCommit'",
                      "dsJndiNames                 = ['cgDataSource']",
                      "dsConnectionPoolParams      = {'InitialCapacity': 5, 'MaxCapacity': 20, 'TestConnectionsOnReserve': true, 'TestTableName': 'SQL SELECT 1 FROM DUAL'}"
                      ],
     require       => Wlp::Database_properties ['database_properties'],
  }

  # create jdbc cgDataSource-nonXA datasource
  wls::wlstexec {'cgDataSource-nonXA':
     script        => 'createJdbcDatasourceOffline.py',
     params        => [
                      "domainPath                  = '${wlsDomainsPath}/${wlsDomainName}'",
                      "dsName                      = 'cgDataSource-nonXA'",
                      "jdbcDatasourceTargets       = 'AdminServer'",
                      "dsDriverName                = 'oracle.jdbc.OracleDriver'",
                      "dsURL                       = 'jdbc:oracle:thin:@wcdb.example.com:1521/test.oracle.com'",
                      "dsUserName                  = 'weblogic'",
                      "dsPassword                  = 'weblogic'",
                      "datasourceTargetType        = 'Server'",
                      "globalTransactionsProtocol  = 'None'",
                      "dsJndiNames                 = ['cgDataSource-nonXA']",
                      "dsConnectionPoolParams      = {'InitialCapacity': 5, 'MaxCapacity': 20, 'TestConnectionsOnReserve': true, 'TestTableName': 'SQL SELECT 1 FROM DUAL'}"
                      ],
     require       => Wlp::Database_properties ['database_properties'],
  }

  # create jdbc p13nDataSource datasource
  wls::wlstexec {'p13nDataSource':
     script        => 'createJdbcDatasourceOffline.py',
     params        => [
                      "domainPath                  = '${wlsDomainsPath}/${wlsDomainName}'",
                      "dsName                      = 'p13nDataSource'",
                      "jdbcDatasourceTargets       = 'AdminServer'",
                      "dsDriverName                = 'oracle.jdbc.OracleDriver'",
                      "dsURL                       = 'jdbc:oracle:thin:@wcdb.example.com:1521/test.oracle.com'",
                      "dsUserName                  = 'weblogic'",
                      "dsPassword                  = 'weblogic'",
                      "datasourceTargetType        = 'Server'",
                      "globalTransactionsProtocol  = 'None'",
                      "dsJndiNames                 = ['p13n.trackingDataSource','p13n.sequencerDataSource','p13n.leasemanager','p13n.dataSyncDataSource','p13n.entitlementsDataSource','p13n.quiescenceDataSource','p13n.credentialsDataSource']",
                      "dsConnectionPoolParams      = {'InitialCapacity': 5, 'MaxCapacity': 20, 'TestConnectionsOnReserve': true, 'TestTableName': 'SQL SELECT 1 FROM DUAL'}"
                      ],
     require       => Wlp::Database_properties ['database_properties'],
  }

  # create jdbc portalDataSource datasource
  wls::wlstexec {'portalDataSource':
     script        => 'createJdbcDatasourceOffline.py',
     params        => [
                      "domainPath                  = '${wlsDomainsPath}/${wlsDomainName}'",
                      "dsName                      = 'portalDataSource'",
                      "jdbcDatasourceTargets       = 'AdminServer'",
                      "dsDriverName                = 'oracle.jdbc.OracleDriver'",
                      "dsURL                       = 'jdbc:oracle:thin:@wcdb.example.com:1521/test.oracle.com'",
                      "dsUserName                  = 'weblogic'",
                      "dsPassword                  = 'weblogic'",
                      "datasourceTargetType        = 'Server'",
                      "globalTransactionsProtocol  = 'LoggingLastResource'",
                      "dsJndiNames                 = ['weblogic.jdbc.jts.commercePool','contentDataSource','contentVersioningDataSource','portalFrameworkPool']",
                      "dsConnectionPoolParams      = {'InitialCapacity': 5, 'MaxCapacity': 20, 'TestConnectionsOnReserve': true, 'TestTableName': 'SQL SELECT 1 FROM DUAL'}"
                      ],
     require       => Wlp::Database_properties ['database_properties'],
  }

  # create jdbc portalDataSourceAlwaysXA datasource
  wls::wlstexec {'portalDataSourceAlwaysXA':
     script        => 'createJdbcDatasourceOffline.py',
     params        => [
                      "domainPath                  = '${wlsDomainsPath}/${wlsDomainName}'",
                      "dsName                      = 'portalDataSourceAlwaysXA'",
                      "jdbcDatasourceTargets       = 'AdminServer'",
                      "dsDriverName                = 'oracle.jdbc.xa.client.OracleXADataSource'",
                      "dsURL                       = 'jdbc:oracle:thin:@wcdb.example.com:1521/test.oracle.com'",
                      "dsUserName                  = 'weblogic'",
                      "dsPassword                  = 'weblogic'",
                      "datasourceTargetType        = 'Server'",
                      "globalTransactionsProtocol  = 'TwoPhaseCommit'",
                      "dsJndiNames                 = ['portalFrameworkPoolAlwaysXA']",
                      "dsConnectionPoolParams      = {'InitialCapacity': 5, 'MaxCapacity': 20, 'TestConnectionsOnReserve': true, 'TestTableName': 'SQL SELECT 1 FROM DUAL'}"
                      ],
     require       => Wlp::Database_properties ['database_properties'],
  }

  # create jdbc portalDataSourceNeverXA datasource
  wls::wlstexec {'portalDataSourceNeverXA':
     script        => 'createJdbcDatasourceOffline.py',
     params        => [
                      "domainPath                  = '${wlsDomainsPath}/${wlsDomainName}'",
                      "dsName                      = 'portalDataSourceNeverXA'",
                      "jdbcDatasourceTargets       = 'AdminServer'",
                      "dsDriverName                = 'oracle.jdbc.OracleDriver'",
                      "dsURL                       = 'jdbc:oracle:thin:@wcdb.example.com:1521/test.oracle.com'",
                      "dsUserName                  = 'weblogic'",
                      "dsPassword                  = 'weblogic'",
                      "datasourceTargetType        = 'Server'",
                      "globalTransactionsProtocol  = 'OnePhaseCommit'",
                      "dsJndiNames                 = ['portalFrameworkNeverAlwaysXA']",
                      "dsConnectionPoolParams      = {'InitialCapacity': 5, 'MaxCapacity': 20, 'TestConnectionsOnReserve': true, 'TestTableName': 'SQL SELECT 1 FROM DUAL'}"
                      ],
     require       => Wlp::Database_properties ['database_properties'],
  }

  Wls::Wlscontrol{
    wlsDomain     => $wlsDomainName,
    wlsDomainPath => "${wlsDomainsPath}/${wlsDomainName}",
    wlHome        => $osWlHome,
    fullJDKName   => $wlp_jdk_version,
    wlsUser       => hiera('wls_weblogic_user'),
    password      => hiera('domain_wls_password'),
    address       => $address,
    user          => $user,
    group         => $group,
    downloadDir   => $downloadDir,
    logOutput     => true,
  }

  # start AdminServers for configuration of WebLogic Portal Domain
  wls::wlscontrol{'startAdminServer':
    wlsServerType => 'admin',
    wlsServer     => "AdminServer",
    action        => 'start',
    port          => $nodemanagerPort,
    require       => Wls::Wlstexec['cgDataSource','cgDataSource-nonXA', 'p13nDataSource', 'portalDataSource','portalDataSourceAlwaysXA','portalDataSourceNeverXA'],
  }

  # create keystores for automatic WLST login
  wls::storeuserconfig{"${wlsDomainName}_keys":
    wlHome        => $osWlHome,
    fullJDKName   => $wlp_jdk_version,
    domain        => $wlsDomainName,
    address       => $address,
    wlsUser       => hiera('wls_weblogic_user'),
    password      => hiera('domain_wls_password'),
    port          => $adminListenPort,
    user          => $user,
    group         => $group,
    userConfigDir => $userConfigDir,
    downloadDir   => $downloadDir,
    require       => Wls::Wlscontrol['startAdminServer'],
  }
}

class maintenance {

  $osOracleHome = hiera('wls_oracle_base_home_dir')
  $osMdwHome    = hiera('wls_middleware_home_dir')
  $osWlHome     = hiera('wls_weblogic_home_dir')
  $user         = hiera('wls_os_user')
  $group        = hiera('wls_os_group')
  $downloadDir  = hiera('wls_download_dir')
  $logDir       = hiera('wls_log_dir')

  $mtimeParam = "1"


  cron { 'cleanwlstmp' :
        command => "find /tmp -name '*.tmp' -mtime ${mtimeParam} -exec rm {} \\; >> /tmp/tmp_purge.log 2>&1",
        user    => oracle,
        hour    => 06,
        minute  => 25,
  }

  cron { 'mdwlogs' :
        command => "find ${osMdwHome}/logs -name 'wlst_*.*' -mtime ${mtimeParam} -exec rm {} \\; >> /tmp/wlst_purge.log 2>&1",
        user    => oracle,
        hour    => 06,
        minute  => 30,
  }

  cron { 'oracle_common_lsinv' :
        command => "find ${osMdwHome}/oracle_common/cfgtoollogs/opatch/lsinv -name 'lsinventory*.txt' -mtime ${mtimeParam} -exec rm {} \\; >> /tmp/opatch_lsinv_common_purge.log 2>&1",
        user    => oracle,
        hour    => 06,
        minute  => 31,
  }


  cron { 'oracle_soa1_lsinv' :
        command => "find ${osMdwHome}/Oracle_SOA1/cfgtoollogs/opatch/lsinv -name 'lsinventory*.txt' -mtime ${mtimeParam} -exec rm {} \\; >> /tmp/opatch_lsinv_soa1_purge.log 2>&1",
        user    => oracle,
        hour    => 06,
        minute  => 33,
  }

  cron { 'oracle_common_opatch' :
        command => "find ${osMdwHome}/oracle_common/cfgtoollogs/opatch -name 'opatch*.log' -mtime ${mtimeParam} -exec rm {} \\; >> /tmp/opatch_common_purge.log 2>&1",
        user    => oracle,
        hour    => 06,
        minute  => 34,
  }


  cron { 'oracle_soa1_opatch' :
        command => "find ${osMdwHome}/Oracle_SOA1/cfgtoollogs/opatch -name 'opatch*.log' -mtime ${mtimeParam} -exec rm {} \\; >> /tmp/opatch_soa_purge.log 2>&1",
        user    => oracle,
        hour    => 06,
        minute  => 35,
  }


}


