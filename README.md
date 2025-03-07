# docker-vagrant: Seamless Docker VM Provisioning for macOS

This Docker CLI plugin lets you manage a Vagrant-powered Docker host
directly from the Docker CLI. The current implementation uses
Parallels Desktop, but feel free to adapt my Vagrantfile to other
Hypervisors -- the user interface will be the same.

## Why?
Docker on macOS can be tricky — Docker Desktop comes with licensing
concerns, performance issues, and hidden magic. This plugin lets you:

✅ Provision a dedicated Linux VM with your perfect Docker setup.

✅ Seamlessly switch your Docker CLI to use the VM via Docker Contexts.

✅ Manage the VM directly through Docker CLI: `docker vagrant up`,
`docker vagrant ssh`, etc.

## Install
Clone this repository and run `make install` in the project
directory. This will create a new Docker CLI subcommand `docker
vagrant` that manages the Docker virtual machine.


## Usage
Works just like Vagrant, but scoped to Docker:

```bash
docker vagrant up          # Start the VM and configure Docker context
docker vagrant ssh         # SSH into the VM (you will rarely need this)
docker vagrant suspend     # Pause the VM
docker vagrant resume      # Unpause the VM
docker vagrant halt        # Stop the VM
docker vagrant destroy     # Remove the VM
```

All commands will automatically set up or tear down an appropriate
Docker context, so you can immediately use docker:

```bash
$ docker vagrant up
Bringing machine 'default' up with 'parallels' provider...
... lots of output ...
$ docker context ls
NAME                 DESCRIPTION   DOCKER ENDPOINT
docker-parallels *   dockerhost    tcp://10.211.55.91:2376
$ docker run -it --rm alpine
/ # 
```


## Prerequisites

- Parallels Desktop for Mac (Pro edition)
- Docker CLI on your Mac
- Vagrant
- The Parallels provider for Vagrant
  ``` shell
  brew install docker vagrant
  vagrant plugin install vagrant-parallels
  ```

## Details

- `docker vagrant up` will provision a new VM based on
  `bento/ubuntu-24.04`, installs an up-to-date Docker daemon,
  generates TLS certificates and creates a new Docker context named
  `docker-parallels` on your Mac, that is activated automatically.

- implementation: the VM is provisioned by `provision.sh`; adding the
  Docker context to the Mac is done by `host.sh`. Both scripts are
  automatically run by Vagrant for all lifecycle commands.

- The VM is provisioned to share `/Users` with the Mac; this makes
  it easy to add volumes from home directories to Docker containers
  using the same paths as on the Mac:
  ``` shell
  docker run -it -v `pwd`:`pwd` alpine
  ```

- Parallels will automatically add the VM to `/etc/hosts` on the Mac
  under the name `dockerhost`; thus servers in Docker containers can
  be reached from the Mac as `dockerhost:<port>`, e.g. this container:
  ``` shell
  docker run -p 8080:80 nginx
  ```
  ... would be here <http://dockerhost:8080>

- **Bug 2025-02-01** Parallels 20.2 discontinues the `prl_fs`
  fstype. Update the `vagrant-parallels` plugin to at least version
  2.4.4 for a workaround that uses `prlfsd` and FUSE instead.

Feel free to hack on the scripts and drop me a MR.
