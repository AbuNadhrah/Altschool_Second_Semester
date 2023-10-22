#!/bin/bash

#Initialize the vagrant file
vagrant init ubuntu/focal64

#Copy the configuration details for setting up the master / slave into the vagrant file

cat <<EOF > Vagrantfile

Vagrant.configure("2") do |config|

  config.vm.define "slave" do |slave|

    slave.vm.hostname = "slave"
    slave.vm.box = "ubuntu/focal64"
    slave.vm.network "private_network", ip: "192.168.56.107"

    slave.vm.provision "shell", inline: <<-SHELL
    sudo apt-get update && sudo apt-get upgrade -y
    sudo apt install sshpass -y
    sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sudo systemctl restart sshd
    SHELL
  end

  config.vm.define "master" do |master|

    master.vm.hostname = "master"
    master.vm.box = "ubuntu/focal64"
    master.vm.network "private_network", ip: "192.168.56.106"

    master.vm.provision "shell", path: "master-lamp.sh" 
  end

    config.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = "2"
    end
end
EOF

vagrant up

