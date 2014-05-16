# == Define: wlp::installwlp
#
# Downloads from file folder and install weblogic with a silent install on linux and windows servers
#
#

define wlp::installwlp( $version     = undef,
                        $fullJDKName = undef,
                        $oracleHome  = undef,
                        $mdwHome     = undef,
                        $createUser  = true,
                        $user        = 'oracle',
                        $group       = 'dba',
                        $downloadDir = '/install',
                        $remoteFile  = false,
                        $puppetDownloadMntPoint  = undef,
                      ) {

   $wls1036Parameter     = "1036"
   $wlsFile1036          = "wls1036_generic.jar"

   $wlp1034Parameter     = "1034"
   $wlpFile1034          = "portal1030_generic.jar"


   $wlsFileDefault       = $wlpFile1034

   case $operatingsystem {
      CentOS, RedHat, OracleLinux, Ubuntu, Debian, SLES: {
        $execPath        = "/usr/java/${fullJDKName}/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:"
        $path            = $downloadDir
        $beaHome         = $mdwHome
        $javaHome        = "/usr/java/${fullJDKName}"
        $wlHome          = "${mdwHome}/wlserver_10.3"
        $wlwHome         = "${mdwHome}/workshop_10.3"
        $wlpHome         = "${mdwHome}/wlportal_10.3"

        $oraInventory    = "${oracleHome}/oraInventory"
        $oraInstPath     = "/etc"
        $java_statement  = "java"

        Exec { path      => $execPath,
               user      => $user,
               group     => $group,
               logoutput => true,
             }
        File {
               ensure  => present,
               mode    => 0775,
               owner   => $user,
               group   => $group,
               backup  => false,
             }
      }
      Solaris: {

        $execPath        = "/usr/jdk/${fullJDKName}/bin/amd64:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:"
        $path            = $downloadDir
        $beaHome         = $mdwHome

        $oraInventory    = "${oracleHome}/oraInventory"
        $oraInstPath     = "/var/opt"
        $java_statement  = "java -d64"

        Exec { path      => $execPath,
               user      => $user,
               group     => $group,
               logoutput => true,
             }
        File {
               ensure  => present,
               mode    => 0775,
               owner   => $user,
               group   => $group,
               backup  => false,
             }

      }
      windows: {
        $path            = $downloadDir
        $beaHome         = $mdwHome

        $execPath         = "C:\\oracle\\${fullJDKName}\\bin;C:\\unxutils\\bin;C:\\unxutils\\usr\\local\\wbin;C:\\Windows\\system32;C:\\Windows"
        $checkCommand     = "C:\\Windows\\System32\\cmd.exe /c"

        Exec { path      => $execPath,
             }
        File { ensure  => present,
               mode    => 0555,
               backup  => false,
             }
      }
      default: {
        fail("Unrecognized operating system")
      }
   }



    # check weblogic version like 12c
    if $version == undef {
      $wlp_file    =  $wlsFileDefault
    }
    elsif $version == $wlp1034Parameter  {
      $wlp_file    =  $wlpFile1034
    }
    elsif $version == $wls1036Parameter  {
      $wlp_file    =  $wlsFile1036
    }
    else {
      $wlp_file    =  $wlsFileDefault
    }

     # check if the wls already exists
     $found = wls_exists($mdwHome)
     if $found == undef {
       $continue = true
     } else {
       if ( $found ) {
         $continue = false
       } else {
         notify {"wlp::installwlp ${title} ${mdwHome} does not exists":}
         $continue = true
       }
     }

if ( $continue ) {

  if $puppetDownloadMntPoint == undef {
    $mountPoint =  "puppet:///modules/wls/"
  } else {
    $mountPoint = $puppetDownloadMntPoint
  }

  wls::utils::defaultusersfolders{'create wlp home':
    oracleHome      => $oracleHome,
    oraInventory    => $oraInventory,
    createUser      => $createUser,
    user            => $user,
    group           => $group,
    downloadDir     => $path,
  }

  # for performance reasons, download and install or just install it
  if $remoteFile == true {
    file { "wls.jar ${version}":
       path    => "${path}/${wlp_file}",
       ensure  => file,
       source  => "${mountPoint}/${wlp_file}",
       require => Wls::Utils::Defaultusersfolders['create wlp home'],
       replace => false,
       backup  => false,
    }
  }

   # de xml used by the wls installer
   file { "silent.xml ${version}":
     path    => "${path}/silent${version}.xml",
     ensure  => present,
     replace => 'yes',
     content => template("wlp/silent_portal.xml.erb"),
     require => Wls::Utils::Defaultusersfolders['create wlp home'],
   }

   # install weblogic
   case $operatingsystem {
     CentOS, RedHat, OracleLinux, Ubuntu, Debian, SLES, Solaris: {
        if $remoteFile == true {
          exec { "install wlp ${title}":
            command     => "${java_statement} -Xmx1024m -jar ${path}/${wlp_file} -mode=silent -silent_xml=${path}/silent${version}.xml",
            logoutput   => true,
            timeout     => 0,
            require     => [Wls::Utils::Defaultusersfolders['create wlp home'],
                            File ["wls.jar ${version}"],
                            File ["silent.xml ${version}"],
                           ],
          }
        } else {
          exec { "install wlp ${title}":
            command     => "${java_statement} -Xmx1024m -jar ${puppetDownloadMntPoint}/${wlp_file} -mode=silent -silent_xml=${path}/silent${version}.xml",
            logoutput   => true,
            timeout     => 0,
            require     => [Wls::Utils::Defaultusersfolders['create wlp home'],
                            File ["silent.xml ${version}"],
                           ],
          }
        }

     }
     windows: {
        exec { "install wlp ${title}":
          command     => "${checkCommand} /c java -Xmx1024m -jar ${path}/${wlp_file} -mode=silent -silent_xml=${path}/silent${version}.xml",
          timeout     => 0,
          environment => ["JAVA_VENDOR=Sun",
                          "JAVA_HOME=C:\\oracle\\${fullJDKName}"],
          require     => [Wls::Utils::Defaultusersfolders['create wlp home'],File ["wls.jar ${version}"],File ["silent.xml ${version}"]],
        }
     }
   }
 }
}
