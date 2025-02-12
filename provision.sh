#!/bin/bash
#
# This script provisions an Ubuntu machine with the latest Docker
# daemon from download.docker.com, set up TCP/TLS and generate a
# dockercontext to be consumed by clients.

set -xeuo pipefail

# About this virtual machine
ARCH=$(dpkg --print-architecture)
MYIP=$(hostname -I | awk '{print $1}')

# Constants for installing Docker from docker.com
DOCKER_GPG_URL=https://download.docker.com/linux/ubuntu/gpg
DOCKER_GPG=/usr/share/keyrings/docker-archive-keyring.gpg
DOCKER_REPO=https://download.docker.com/linux/ubuntu
DOCKER_APT_SRCS=/etc/apt/sources.list.d/docker.list

# Where to put the dockercontext file
HOSTSHARE=/vagrant

# We use 'mkcert' to generate server and client certificates
MKCERT_URL=https://dl.filippo.io/mkcert/latest?for=linux/amd64
MKCERT_PATH=/usr/bin/mkcert


# Silently install APT packages
function apt_install () {
    apt-get -q update -q
    apt-get -y -qq install "$@"
}


# Install Docker daemon if necessary
function ensure_docker () {
    if ! which dockerd; then
	# Prerequisites for docker installation
	apt_install ca-certificates curl gnupg lsb-release

	# Get Docker GPG key and add docker repo to APT
	curl -fsSL ${DOCKER_GPG_URL} | gpg --dearmor -o ${DOCKER_GPG}
	echo "deb [arch=${ARCH} signed-by=${DOCKER_GPG}] ${DOCKER_REPO} \
	  $( lsb_release -cs) stable" > ${DOCKER_APT_SRCS}

	# Install Docker
	apt_install docker-ce docker-ce-cli containerd.io
    fi
}


# Install mkcert if necessary; mkcert generates locally valid
# certificates (https://github.com/FiloSottile/mkcert)
function ensure_mkcert () {
    if ! which mkcert; then
	curl -JLO ${MKCERT_URL}
	chmod +x mkcert-v*-linux-amd64
	cp mkcert-v*-linux-amd64 ${MKCERT_PATH}
    fi
}


function make_dockercontext () {
    [ -f meta.json ] || cat > meta.json <<EOF
{
  "Name": "docker-parallels",
  "Metadata": {"Description": "dockerhost"},
  "Endpoints": {
    "docker":{
      "Host": "tcp://$MYIP:2376",
      "SkipTLSVerify":false
    }
  }
}
EOF
    mkdir -p tls/docker
    [ -f tls/docker/cert.pem ] || mkcert -client -cert-file tls/docker/cert.pem -key-file tls/docker/key.pem host
    [ -f tls/docker/ca.pem ] || cp /root/.local/share/mkcert/rootCA.pem tls/docker/ca.pem
    tar cvf ${HOSTSHARE}/docker-parallels.dockercontext meta.json tls
}

function configure_docker () {
    [ -f server.pem ] || mkcert -cert-file server.pem -key-file server-key.pem $MYIP
    echo "Updating /etc/docker/daemon.json"
    cat > /etc/docker/daemon.json <<EOF
{
   "experimental": false,
   "builder": { "gc": { "enabled": true, "defaultKeepStorage": "20GB" } },
   "features": { "buildkit": true },
   "registry-mirrors": ["https://dockerhub.contact.de"],
   "tls": true,
   "tlsverify": true,
   "tlscacert": "/root/.local/share/mkcert/rootCA.pem",
   "tlscert": "/home/vagrant/server.pem",
   "tlskey": "/home/vagrant/server-key.pem",
   "hosts": [ "fd://", "tcp://0.0.0.0:2376" ],
   "containerd": "/run/containerd/containerd.sock"
}
EOF

    mkdir -p /etc/systemd/system/docker.service.d
    cat > /etc/systemd/system/docker.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd
EOF

    systemctl daemon-reload
    systemctl restart docker
}

cd /home/vagrant

ensure_docker
ensure_mkcert
configure_docker
make_dockercontext
