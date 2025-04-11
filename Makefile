.PHONY: install test prebuilt-box

CLI_PLUGIN=~/.docker/cli-plugins/docker-vagrant

install:
	mkdir -p ~/.docker/cli-plugins
	rm -f $(CLI_PLUGIN)
	ln -s `pwd`/docker-vagrant.sh $(CLI_PLUGIN)

test:
	bash test.sh

prebuilt-box:
	-vagrant halt
	-prlctl delete ubuntu-basebox
	VAGRANT_VAGRANTFILE=prebuilt-box.vagrant vagrant up
	VAGRANT_VAGRANTFILE=prebuilt-box.vagrant vagrant halt
	VAGRANT_VAGRANTFILE=prebuilt-box.vagrant vagrant package --output docker-vagrant-base.parallels.box
	-vagrant box remove docker-vagrant-base
	vagrant box add docker-vagrant-base docker-vagrant-base.parallels.box
