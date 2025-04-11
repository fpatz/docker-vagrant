# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANT_VM_NAME = "dockerhost"
PREFERRED_BOX = "docker-vagrant-base"
FALLBACK_BOX  = "bento/ubuntu-24.04"
BOX_INSTALLED = `vagrant box list`.lines.any? { |line| line.start_with?(PREFERRED_BOX) }

Vagrant.configure("2") do |config|
  config.vm.define VAGRANT_VM_NAME do |vm|
    vm.vm.box = BOX_INSTALLED ? PREFERRED_BOX : FALLBACK_BOX
    vm.vm.hostname = VAGRANT_VM_NAME

    # Share an additional folder to the guest VM. The first argument is
    # the path on the host to the actual folder. The second argument is
    # the path on the guest to mount the folder. And the optional third
    # argument is a set of non-required options.
    vm.vm.synced_folder "/Users", "/Users"

    # Create a forwarded port mapping which allows access to a specific port
    # within the machine from a port on the host machine. In the example below,
    # accessing "localhost:8080" will access port 80 on the guest machine.
    # NOTE: This will enable public access to the opened port
    # vm.vm.network "forwarded_port", guest: 80, host: 8080

    # Create a forwarded port mapping which allows access to a specific port
    # within the machine from a port on the host machine and only allow access
    # via 127.0.0.1 to disable public access
    # vm.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

    vm.vm.provider "parallels" do |prl|
      prl.memory = "8192"
      prl.cpus = 8
      prl.name = VAGRANT_VM_NAME
      prl.update_guest_tools = true
    end

    vm.vm.provision "shell", path: "provision.sh"

    vm.trigger.after [:up, :provision, :resume] do |trigger|
      trigger.info = "Deploying client certificate"
      trigger.run = {path: "host.sh", args: "deploy"}
    end

    vm.trigger.after [:suspend, :halt, :destroy] do |trigger|
      trigger.info = "Undeploying client certificate"
      trigger.run = {path: "host.sh", args: "undeploy" }
    end
  end
end
