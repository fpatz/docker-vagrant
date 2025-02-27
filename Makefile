.PHONY: install

CLI_PLUGIN=~/.docker/cli-plugins/docker-vagrant

install:
	rm -f $(CLI_PLUGIN)
	ln -s `pwd`/docker-vagrant.sh $(CLI_PLUGIN)
