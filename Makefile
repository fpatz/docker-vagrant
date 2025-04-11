.PHONY: install

CLI_PLUGIN=~/.docker/cli-plugins/docker-vagrant

install:
	mkdir -p ~/.docker/cli-plugins
	rm -f $(CLI_PLUGIN)
	ln -s `pwd`/docker-vagrant.sh $(CLI_PLUGIN)
