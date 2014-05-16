define wlp::database_properties ($version       = '1030',
                                 $wlp_dir       = undef,
                                 $full_jdk_name = undef,
                                 $user          = 'oracle',
                                 $group         = 'dba',
                                 $wlp_db        = 'oracle',
                                 $wlp_db_user   = 'weblogic',
                                 $wlp_db_pwd    = 'weblogic',
                                 $wlp_db_driver = 'oracle.jdbc.OracleDriver',
                                 $wlp_db_url    = 'jdbc:oracle:thin:@wcdb.example.com:1521/test.oracle.com',
                                 $logOutput     = false,
                                ) {

  if $wlp_dir == undef {
    notify {"wlp::database_properties Domain '${$wlp_dir}' does does not exist.":}

  }
case $operatingsystem {
     CentOS, RedHat, OracleLinux, Ubuntu, Debian, SLES: {

        $execPath         = "/usr/java/${full_jdk_name}/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:"
        $JAVA_HOME        = "/usr/java/${full_jdk_name}"

        Exec { path      => $execPath,
               user      => $user,
               group     => $group,
               logoutput => $logOutput,
             }
        File {
               ensure  => present,
               replace => true,
               mode    => 0555,
               owner   => $user,
               group   => $group,
               backup  => false,
             }
     }
     Solaris: {

        $execPath         = "/usr/jdk/${full_jdk_name}/bin/amd64:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:"
        $JAVA_HOME        = "/usr/jdk/${full_jdk_name}"

        Exec { path      => $execPath,
               user      => $user,
               group     => $group,
               logoutput => $logOutput,
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

        $execPath         = "C:\\oracle\\${full_jdk_name}\\bin;C:\\unxutils\\bin;C:\\unxutils\\usr\\local\\wbin;C:\\Windows\\system32;C:\\Windows"
        $JAVA_HOME        = "c:\\oracle\\${full_jdk_name}"

        Exec { path      => $execPath,
               logoutput => $logOutput,
             }
        File { ensure  => present,
               replace => true,
               mode    => 0777,
               backup  => false,
             }
     }
   }


  # the database.properties file used to setup the portal schema
  file { "${wlp_dir}/database.properties":
    path    => "${wlp_dir}/database.properties",
    content => template("wlp/database.properties.erb"),
  }

  Exec {
    environment => ["JAVA_HOME=${JAVA_HOME}"],
    require     => File["${wlp_dir}/database.properties"],
    creates     => "${wlp_dir}/create_db.log"
  }
  case $operatingsystem {
    CentOS, RedHat, OracleLinux, Ubuntu, Debian, SLES, Solaris: {

      exec { "exec ${wlp_dir}/create_db.sh":
        command     => "${wlp_dir}/create_db.sh",
      }
   }
   windows: {
      exec { "execwlst ${title}${script}":
        command     => "${wlp_dir}/create_db.bat"
      }
    }
  }
}