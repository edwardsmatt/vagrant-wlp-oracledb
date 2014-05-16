# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.define "wlpdb" , primary: true do |wlpdb|
    wlpdb.vm.box = "centos-6.5-x86_64"
    wlpdb.vm.box_url = "https://dl.dropboxusercontent.com/s/np39xdpw05wfmv4/centos-6.5-x86_64.box"

    wlpdb.vm.hostname = "wlpdb.example.com"
    wlpdb.vm.network :private_network, ip: "10.10.10.5"

    wlpdb.vm.synced_folder ".", "/vagrant", :mount_options => ["dmode=777","fmode=777"]
    wlpdb.vm.synced_folder "~/software", "/software"
    #wlpdb.vm.synced_folder ".", "/vagrant", type: "nfs"
    #wlpdb.vm.synced_folder "/Users/edwin/software", "/software", type: "nfs"

    wlpdb.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm"     , :id, "--memory", "2000"]
      vb.customize ["modifyvm"     , :id, "--name"  , "wlpdb"]
    end


    wlpdb.vm.provision :shell, :inline => "ln -sf /vagrant/puppet/hiera.yaml /etc/puppet/hiera.yaml"

    wlpdb.vm.provision :puppet do |puppet|
      puppet.manifests_path    = "puppet/manifests"
      puppet.module_path       = "puppet/modules"
      puppet.manifest_file     = "wlpdb.pp"
      puppet.options           = "--verbose --hiera_config /vagrant/puppet/hiera.yaml"

      puppet.facter = {
        "environment" => "development",
        "vm_type"     => "vagrant",
      }

    end
  end

 config.vm.define "wlp" , primary: true do |wlp|
  wlp.vm.box = "centos-6.5-x86_64"
    #wlp.vm.box_url ="/Users/edwin/Downloads/centos-6.5-x86_64.box"
    wlp.vm.box_url = "https://dl.dropboxusercontent.com/s/np39xdpw05wfmv4/centos-6.5-x86_64.box"

    wlp.vm.hostname = "wlp.example.com"

    wlp.vm.synced_folder "."                    , "/vagrant", :mount_options => ["dmode=777","fmode=777"]
    wlp.vm.synced_folder "~/software", "/software"


    wlp.vm.network :private_network, ip: "10.10.10.20"

    wlp.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "2000"]
      vb.customize ["modifyvm", :id, "--name"  , "wlp"]
    end

    wlp.vm.provision :shell, :inline => "ln -sf /vagrant/puppet/hiera.yaml /etc/puppet/hiera.yaml"

    wlp.vm.provision :puppet do |puppet|
      puppet.manifests_path    = "puppet/manifests"
      puppet.module_path       = "puppet/modules"
      puppet.manifest_file     = "wlp.pp"
      puppet.options           = "--verbose --hiera_config /vagrant/puppet/hiera.yaml"

      puppet.facter = {
        "environment"                     => "development",
        "vm_type"                         => "vagrant",
      }
    end
  end
end

