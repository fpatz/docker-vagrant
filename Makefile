.PHONY: install test prebuilt-box

CLI_PLUGIN=~/.docker/cli-plugins/docker-vagrant
PREBUILT_BOX_NAME=docker-vagrant-base
PREBUILT_BOX_FILE=$(PREBUILT_BOX_NAME).parallels.box
PREBUILT_BOX_VAGRANT=prebuilt-box.vagrant

install:
	mkdir -p ~/.docker/cli-plugins
	rm -f $(CLI_PLUGIN)
	ln -s `pwd`/docker-vagrant.sh $(CLI_PLUGIN)

test:
	bash test.sh

prebuilt-box: $(PREBUILT_BOX_FILE)

$(PREBUILT_BOX_FILE):
	-vagrant halt
	-prlctl stop ubuntu-basebox
	-prlctl delete ubuntu-basebox
	(\
		VAGRANT_VAGRANTFILE=$(PREBUILT_BOX_VAGRANT) \
		vagrant up && \
		vagrant halt && \
		vagrant package --output $(PREBUILT_BOX_FILE) \
	)
	-vagrant box remove $(PREBUILT_BOX_NAME)
	vagrant box add $(PREBUILT_BOX_NAME) $(PREBUILT_BOX_FILE)
