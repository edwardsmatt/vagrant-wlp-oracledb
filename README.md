#vagrant-wlp-oracledb 
Forked from biemond/biemond-wls-vagrant-wc - All credit goes there ;)

Oracle WebLogic Portal 10.3.0.0, Oracle Database 11.2.0.4

Modified implementation of https://github.com/biemond/biemond-wls-vagrant-wc  to build WebLogic Portal

uses a CentOS 6.5 vagrant box for Virtualbox which includes puppet 3.4.2

##Delivers
- creates a patched 10.3.0.0 WebLogic Server Portal Domain ( wlp )
- creates a Oracle SE database 11.2.0.4 with Portal Content Repository ( wlpdb )

##Software
Add the all the Oracle binaris to /software, edit Vagrantfile and update
- wlp.vm.synced_folder "~/software", "/software"
- wlpdb.vm.synced_folder "~/software", "/softare"

###Java
- jdk-7u51-linux-x51.tar.gz

###WebLogic
- portal1030_generic.jar

###Database 11.2.0.4
- p13390677_112040_Linux-x86-64_1of2.zip
- p13390677_112040_Linux-x86-64_2of7.zip

##Running from Vagrant

Download the latest version of Vagrant & Oracle Virtualbox

###Oracle Database server  
vagrant up wlpdb

###WebLogic Portal Application AdminServer  
vagrant up wlp

