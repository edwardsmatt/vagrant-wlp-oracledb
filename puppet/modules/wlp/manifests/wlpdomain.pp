# == Define: wls::wlsdomain
#
# install a new weblogic domain
# support a normal WebLogic Domain , OSB , OSB plus SOA, OSB plus SOA & BPM , ADF , Webcenter, Webcenter + Content + BPM
# use parameter wlsTemplate to control this
#
# in weblogic 12.1.2 the domain creation will also create a nodemanager inside the domain folder
# other version need to manually create a nodemanager.
#
# === Examples
#
#  $jdkWls11gJDK = 'jdk1.7.0_09'
#
#  $wlsDomainName   = "osbDomain"
#  $osTemplate      = "osb"
#  $osTemplate      = "standard"
#  $adminListenPort = "7001"
#  $nodemanagerPort = "5556"
#  $address         = "localhost"
#  $wlsUser         = "weblogic"
#  $password        = "weblogic1"
#
#
#  case $operatingsystem {
#     centos, redhat, OracleLinux, Ubuntu, debian: {
#       $osMdwHome    = "/opt/oracle/wls/wls11g"
#       $osWlHome     = "/opt/oracle/wls/wls11g/wlserver_10.3"
#       $user         = "oracle"
#       $group        = "dba"
#     }
#     windows: {
#       $osMdwHome    = "c:/oracle/wls/wls11g"
#       $osWlHome     = "c:/oracle/wls/wls11g/wlserver_10.3"
#       $user         = "Administrator"
#       $group        = "Administrators"
#       $serviceName  = "C_oracle_wls_wls11g_wlserver_10.3"
#     }
#  }
#
#  # set the defaults
#
#  Wls::Wlsdomain {
#    wlHome       => $osWlHome,
#    mdwHome      => $osMdwHome,
#    fullJDKName  => $jdkWls11gJDK,
#    user         => $user,
#    group        => $group,
#  }
#
# # install OSB domain
# wls::wlsdomain{
#
#   'osbDomain':
#   wlsTemplate     => $osTemplate,
#   domain          => $wlsDomainName,
#   domainPath      => $osDomainPath,
#   adminListenPort => $adminListenPort,
#   nodemanagerPort => $nodemanagerPort,
# }
##
#

define wlp::wlpdomain ($version         = '1030',
                       $wlHome          = undef,
                       $wlpHome         = undef,
                       $wlwHome         = undef,
                       $mdwHome         = undef,
                       $fullJDKName     = undef,
                       $wlsTemplate     = "wlp",
                       $domain          = undef,
                       $developmentMode = true,
                       $adminServerName = "AdminServer",
                       $adminListenAdr  = "localhost",
                       $adminListenPort = '7001',
                       $nodemanagerPort = '5556',
                       $wlsUser         = undef,
                       $password        = undef,
                       $user            = 'oracle',
                       $group           = 'dba',
                       $logDir          = undef,
                       $downloadDir     = '/install',
                       $reposDbUrl      = undef,
                       $reposPrefix     = undef,
                       $reposPassword   = undef,
                       $dbUrl           = undef,
                       $sysPassword     = undef,
                       ) {


  if $::override_weblogic_domain_folder == undef {
    $domainPath = "${mdwHome}/user_projects/domains"
    $appPath    = "${mdwHome}/user_projects/applications"
  } else {
    $domainPath = "${::override_weblogic_domain_folder}/domains"
    $appPath    = "${::override_weblogic_domain_folder}/applications"
  }


  # check if the domain already exists
  $found = domain_exists("${domainPath}/${domain}",$version, $domainPath)
  if $found == undef {
     $continue = true
  } else {
    if ( $found ) {
      $continue = false
    } else {
      notify {"wlp::wlpdomain ${title} ${domainPath}/${domain} ${version} does not exist":}
      $continue = true
    }
  }


  if ( $continue ) {

    if $version == "1030" {
      $template             = "${wlHome}/common/templates/domains/wls.jar"
      $templateWS           = "${wlHome}/common/templates/applications/wls_webservice.jar"

      $templateWLP          = "${wlpHome}/common/templates/applications/wlp.jar"
      $templateP13N         = "${wlpHome}/common/templates/applications/p13n.jar"
      $templateWSRP         = "${wlpHome}/common/templates/applications/wsrp-simple-producer.jar"
      $templateCONTENT      = "${wlpHome}/common/templates/applications/content.jar"
      $templateLWPF         = "${wlpHome}/common/templates/applications/lwpf_internal.jar"

      $templateWORKSHOP     = "${wlwHome}/common/templates/applications/workshop_wl.jar"

      $templateFile  = "wlp/domains/domain_wlp_10300.xml.erb"

    } else {

      $template             = "${wlHome}/common/templates/domains/wls.jar"
      $templateWS           = "${wlHome}/common/templates/applications/wls_webservice.jar"

      $templateWLP          = "${wlpHome}/common/templates/applications/wlp.jar"
      $templateP13N         = "${wlpHome}/common/templates/applications/p13n.jar"
      $templateWSRP         = "${wlpHome}/common/templates/applications/wsrp-simple-producer.jar"
      $templateCONTENT      = "${wlpHome}/common/templates/applications/content.jar"
      $templateLWPF         = "${wlpHome}/common/templates/applications/lwpf_internal.jar"

      $templateWORKSHOP     = "${wlwHome}/common/templates/applications/workshop_wl.jar"

    }
    $wlstPath      = "${wlHome}/common/bin"



   case $operatingsystem {
     CentOS, RedHat, OracleLinux, Ubuntu, Debian, SLES: {

        $execPath         = "/usr/java/${fullJDKName}/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin"
        $path             = $downloadDir
        $JAVA_HOME        = "/usr/java/${fullJDKName}"
        $nodeMgrMachine   = "UnixMachine"


        Exec { path      => $execPath,
               user      => $user,
               group     => $group,
               logoutput => true,
             }
        File {
               ensure  => present,
               replace => true,
               mode    => 0775,
               owner   => $user,
               group   => $group,
               backup  => false,
             }
     }
     Solaris: {

        $execPath         = "/usr/jdk/${fullJDKName}/bin/amd64:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin"
        $path             = $downloadDir
        $JAVA_HOME        = "/usr/jdk/${fullJDKName}"
        $nodeMgrMachine   = "UnixMachine"


        Exec { path      => $execPath,
               user      => $user,
               group     => $group,
               logoutput => true,
             }
        File {
               ensure  => present,
               replace => true,
               mode    => 0775,
               owner   => $user,
               group   => $group,
               backup  => false,
             }

     }
     windows: {

        $execPath         = "C:\\oracle\\${fullJDKName}\\bin;C:\\unxutils\\bin;C:\\unxutils\\usr\\local\\wbin;C:\\Windows\\system32;C:\\Windows"
        $path             = $downloadDir
        $JAVA_HOME        = "c:\\oracle\\${fullJDKName}"
        $nodeMgrMachine   = "Machine"
        $checkCommand     = "C:\\Windows\\System32\\cmd.exe /c"

        Exec { path      => $execPath,
               logoutput => true,
             }
        File { ensure  => present,
               replace => true,
               mode    => 0777,
               backup  => false,
             }
     }
   }


  if $logDir == undef {
    $adminNodeMgrLogDir             = "${domainPath}/${domain}/servers/${adminServerName}/logs"
    $nodeMgrLogDir                  = "${domainPath}/${domain}/nodemanager/nodemanager.log"
  } else {
    $adminNodeMgrLogDir             = "${logDir}"
    $nodeMgrLogDir                  = "${logDir}/nodemanager_${domain}.log"

    # create all log folders
    case $operatingsystem {
       CentOS, RedHat, OracleLinux, Ubuntu, Debian, SLES, Solaris: {
         if ! defined(Exec["create ${logDir} directory"]) {
           exec { "create ${logDir} directory":
                   command => "mkdir -p ${logDir}",
                   unless  => "test -d ${logDir}",
                   user    => 'root',
           }
         }
       }
       windows: {
         $logDirWin = slash_replace( $logDir )
         if ! defined(Exec["create ${logDir} directory"]) {
           exec { "create ${logDir} directory":
                command => "${checkCommand} mkdir ${logDirWin}",
                unless  => "${checkCommand} dir ${logDirWin}",
           }
         }
       }
       default: {
         fail("Unrecognized operating system")
       }
    }

    if ! defined(File["${logDir}"]) {
         file { "${logDir}" :
           ensure  => directory,
           recurse => false,
           replace => false,
           require => Exec["create ${logDir} directory"],
         }
      }
   }

   # the domain.py used by the wlst
   file { "domain.py ${domain} ${title}":
     path    => "${path}/domain_${domain}.py",
     content => template($templateFile),
   }

    if $::override_weblogic_domain_folder == undef {
      # make the default domain folders
      if !defined(File["weblogic_domain_folder"]) {
        # check oracle install folder
        file { "weblogic_domain_folder":
          path    => "${mdwHome}/user_projects",
          ensure  => directory,
          recurse => false,
          replace => false,
        }
      }
    } else {
      # make override domain folders
      if !defined(File["weblogic_domain_folder"]) {
        # check oracle install folder
        file { "weblogic_domain_folder":
          path    => $::override_weblogic_domain_folder,
          ensure  => directory,
          recurse => false,
          replace => false,
        }
      }
    }

    if !defined(File[$domainPath]) {
      # check oracle install folder
      file { $domainPath:
        ensure  => directory,
        recurse => false,
        replace => false,
        require => File["weblogic_domain_folder"],
      }
    }

    if !defined(File[$appPath]) {
      # check oracle install folder
      file { $appPath:
        ensure  => directory,
        recurse => false,
        replace => false,
        require => File["weblogic_domain_folder"],
      }
    }

   case $operatingsystem {
     CentOS, RedHat, OracleLinux, Ubuntu, Debian, SLES, Solaris: {

        exec { "execwlst ${domain} ${title}":
          command     => "${wlstPath}/wlst.sh ${path}/domain_${domain}.py",
          environment => ["JAVA_HOME=${JAVA_HOME}"],
          unless      => "/usr/bin/test -e ${domainPath}/${domain}",
          creates     => "${domainPath}/${domain}",
          require     => [File["domain.py ${domain} ${title}"],
                          File[$domainPath],
                          File[$appPath]],
          timeout     => 0,
        }

        case $operatingsystem {
           CentOS, RedHat, OracleLinux, Ubuntu, Debian, SLES: {
              exec { "setDebugFlagOnFalse ${domain} ${title}":
                command => "sed -i -e's/debugFlag=\"true\"/debugFlag=\"false\"/g' ${domainPath}/${domain}/bin/setDomainEnv.sh",
                onlyif  => "/bin/grep debugFlag=\"true\" ${domainPath}/${domain}/bin/setDomainEnv.sh | /usr/bin/wc -l",
                require => Exec["execwlst ${domain} ${title}"],
              }

              exec { "domain.py ${domain} ${title}":
                command     => "rm ${path}/domain_${domain}.py",
                require     => Exec["execwlst ${domain} ${title}"],
              }
           }
           Solaris: {
             exec { "setDebugFlagOnFalse ${domain} ${title}":
               command => "sed -e's/debugFlag=\"true\"/debugFlag=\"false\"/g' ${domainPath}/${domain}/bin/setDomainEnv.sh > /tmp/test.tmp && mv /tmp/test.tmp ${domainPath}/${domain}/bin/setDomainEnv.sh",
               onlyif  => "/bin/grep debugFlag=\"true\" ${domainPath}/${domain}/bin/setDomainEnv.sh | /usr/bin/wc -l",
               require => Exec["execwlst ${domain} ${title}"],
             }

             exec { "domain.py ${domain} ${title}":
                command     => "rm ${path}/domain_${domain}.py",
                require     => Exec["execwlst ${domain} ${title}"],
             }
           }
        }


     }
     windows: {

        notify{"${domainPath}/${domain} ${title}":}

        exec { "execwlst ${domain} ${title}":
          command     => "C:\\Windows\\System32\\cmd.exe /c ${wlstPath}/wlst.cmd ${path}/domain_${domain}.py",
          environment => ["CLASSPATH=${wlHome}\\server\\lib\\weblogic.jar",
                          "JAVA_HOME=${JAVA_HOME}"],
          creates     => "${domainPath}/${domain}",
          require     => [File["domain.py ${domain} ${title}"],
                          File[$domainPath],
                          File[$appPath]],
          timeout     => 0,
        }

        exec {"icacls domain ${title}":
           command    => "C:\\Windows\\System32\\cmd.exe /c  icacls ${domainPath}/${domain} /T /C /grant Administrator:F Administrators:F",
           logoutput  => false,
           require   => Exec["execwlst ${domain} ${title}"],
        }

        exec { "domain.py ${domain} ${title}":
           command     => "C:\\Windows\\System32\\cmd.exe /c rm ${path}/domain_${domain}.py",
           require   => Exec["icacls domain ${title}"],
          }


     }
   }

   $nodeMgrHome  = "${domainPath}/${domain}/nodemanager"
   $listenPort   = $nodemanagerPort
}
}
