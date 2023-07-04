# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "bento/ubuntu-22.04"

  config.vm.provider "virtualbox" do |vb|
    # Display the VirtualBox GUI when booting the machine
    # vb.gui = true

    # Customize the amount of memory on the VM:
    vb.memory = 10096 # MB
    vb.cpus = 7
  end

  # Enable provisioning with a shell script. Additional provisioners such as
  # Ansible, Chef, Docker, Puppet and Salt are also available. Please see the
  # documentation for more information about their specific syntax and use.
  config.vm.provision "shell", inline: <<-SHELL
    echo "* speed up provision"
    sudo apt-get remove -y --purge man-db # no need for man

    echo "* install dependencies"
    apt-get update
    sudo apt-get remove docker docker-engine docker.io containerd runc
    apt-get install -y make git gcc build-essential jq python3-pip  apt-transport-https ca-certificates curl gnupg-agent software-properties-common zip unzip golang-cfssl libseccomp2 net-tools
    sudo pip install pyyaml

    echo "* install go"
    GO_VERSION=1.19
    wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz
    tar -xf go${GO_VERSION}.linux-amd64.tar.gz
    sudo rm -rf /usr/local/go && sudo mv go /usr/local
    rm go${GO_VERSION}.linux-amd64.tar.gz
    echo "export PATH=\$PATH:/usr/local/go/bin:$HOME/go/bin" >> /home/vagrant/.profile
    echo "export PATH=\$PATH:/usr/local/go/bin:$HOME/go/bin" >> /root/.profile
    export PATH=$PATH:/usr/local/go/bin:/home/vagrant/go/bin

    echo "* install cri-containerd"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    sudo usermod -aG docker vagrant
    sudo systemctl start containerd

    echo "* lttng setup"
    sudo apt install -y linux-headers-$(uname -r)
    sudo apt install -y lttng-modules-dkms lttng-tools liblttng-ust-*
    usermod -a -G tracing vagrant
  SHELL
end
