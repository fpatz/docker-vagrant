# Docker for Vagrant

This projects provisions a virtual machine that runs the Docker daemon
on macOS. The provisioning is automated using Vagrant and Parallels
Desktop. It is intended as a replacement for Docker Desktop,
docker-machine etc. to quickly set up Docker without running a
separate hypervisor.

Advantages:

- more up-to-date Docker version than projects that rely on
    `boot2docker`
- re-uses existing Parallels Desktop hypervisor
- folder sharing with Parallels Desktop, which is enormously faster
  than other hypervisors

# Prerequisites

- Parallels Desktop for Mac (Pro edition)
- Docker CLI on your Mac
- Vagrant
- The Parallels provider for Vagrant
  ``` shell
  brew install docker vagrant
  vagrant plugin install vagrant-parallels
  ```

# Installation

Clone this repository and run `make install` in the project
directory. This will create a new Docker CLI subcommand `docker
vagrant` that manages the Docker virtual machine.

# Usage

`docker vagrant` is a relatively simple wrapper over Vagrant itself
and offers the same subcommands, arguments and options. To start a
virtual docker machine simply run `docker vagrant up` and you are
ready to go:

``` shell
$ docker vagrant up
Bringing machine 'default' up with 'parallels' provider...
... lots of output ...
$ docker context ls
NAME                 DESCRIPTION   DOCKER ENDPOINT
docker-parallels *   dockerhost    tcp://10.211.55.91:2376
$ docker run -it --rm alpine
/ # 
```

`docker vagrant up` will provision a new VM based on
`bento/ubuntu-24.04`, installs an up-to-date Docker daemon, generates
TLS certificates and creates a new Docker context named
`docker-parallels` on your Mac, that is activated automatically.

To shut down Docker run `docker vagrant halt`.

# Notes

-   **Bug 2025-02-01** Parallels 20.2 discontinues the `prl_fs`
    fstype. Update the `vagrant-parallels` plugin to at least version
    2.4.4 for a workaround that uses `prlfsd` fuse instead.
-   The VM is provisioned to share `/Users` with the Mac; this makes
    it easy to add volumes from home directories to Docker containers
    using the same paths as on the Mac:
    ``` shell
    docker run -it -v `pwd`:`pwd` alpine
    ```
-   Parallels will automatically add the VM to `/etc/hosts` on the Mac
    under the name `dockerhost`; thus servers in Docker containers can
    be reached from the Mac as `dockerhost:<port>`, e.g. this container:
    ``` shell
    docker run -p 8080:80 nginx
    ```
    ... would be here <http://dockerhost:8080>
-   implementation: the VM is provisioned by `provision.sh`; adding the
    Docker context to the Mac is done by `host.sh`. Both scripts are
    automatically run by Vagrant on `up` and `provision`. Reprovisioning
    can be done while the VM is already running and will recreate the
    Docker context.

    Feel free to hack on the scripts and drop me a MR.
