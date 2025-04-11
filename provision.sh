#!/bin/bash
#
# This script provisions an Ubuntu machine with the latest Docker
# daemon from download.docker.com, set up TCP/TLS and generate a
# dockercontext to be consumed by clients.

set -euo pipefail

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
MKCERT_URL=https://dl.filippo.io/mkcert/latest?for=linux/$ARCH
MKCERT_PATH=/usr/bin/mkcert


# Silently install APT packages
function apt_install () {
    DEBIAN_FRONTEND=noninteractive apt-get -q update -q > /dev/null
    if ! DEBIAN_FRONTEND=noninteractive apt-get -y -qq install "$@" &>apt-install.log ; then
        echo "apt-get install $@ failed:"
        cat apt-install.log >&2
        exit 1
    fi
}

# Run mkcert without the cruft
function run_mkcert() {
    if $MKCERT_PATH $@ 2>mkcert-stderr.log; then
        rm -f mkcert-stderr.log
    else
        cat mkcert-stderr.log >&2
        exit 1
    fi
}

# Install Docker daemon if necessary
function ensure_docker () {
    if ! command -v dockerd &>/dev/null ; then
        # Prerequisites for docker installation
        echo "Installing containerd prerequisites ..."
        apt_install ca-certificates curl gnupg lsb-release

        # Get Docker GPG key and add docker repo to APT
        echo "Adding docker repo ${DOCKER_REPO} ..."
        curl -fsSL ${DOCKER_GPG_URL} | gpg --dearmor -o ${DOCKER_GPG}
        echo "deb [arch=${ARCH} signed-by=${DOCKER_GPG}] ${DOCKER_REPO} \
          $( lsb_release -cs) stable" > ${DOCKER_APT_SRCS}

        # Install Docker
        echo "Installing docker CLI & containerd ..."
        apt_install docker-ce docker-ce-cli containerd.io
    fi
}


# Install mkcert if necessary; mkcert generates locally valid
# certificates (https://github.com/FiloSottile/mkcert)
function ensure_mkcert () {
    if ! command -v mkcert &>/dev/null ; then
        echo "Installing mkcert ..."
        rm -f mkcert-v*-linux-$ARCH
        curl -o ${MKCERT_PATH} -sJL ${MKCERT_URL}
        chmod +x ${MKCERT_PATH}
    fi
}

function make_dockercontext () {
    if [ ! -f meta.json ]; then
        echo "Creating docker context ..."
        cat > meta.json <<EOF
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
        echo "Creating client certificate ..."
        [ -f tls/docker/cert.pem ] || run_mkcert -client -cert-file tls/docker/cert.pem -key-file tls/docker/key.pem host
        [ -f tls/docker/ca.pem ] || cp /root/.local/share/mkcert/rootCA.pem tls/docker/ca.pem
        tar cf ${HOSTSHARE}/docker-parallels.dockercontext meta.json tls
    fi
}

function configure_docker () {
    if [ ! -f server.pem ]; then
        echo "Creating server certificate ..."
        run_mkcert -cert-file server.pem -key-file server-key.pem $MYIP
        echo "Updating /etc/docker/daemon.json"
        DAEMON_EXTRA_JSON=""
        if [ -f /vagrant/daemon-extra.json ]; then
            DAEMON_EXTRA_JSON=$(cat /vagrant/daemon-extra.json)
        fi

        cat > /etc/docker/daemon.json <<EOF
{
   "experimental": false,
   "builder": { "gc": { "enabled": true, "defaultKeepStorage": "20GB" } },
   "features": { "buildkit": true },
   $DAEMON_EXTRA_JSON
   "tls": true,
   "tlsverify": true,
   "tlscacert": "/root/.local/share/mkcert/rootCA.pem",
   "tlscert": "/home/vagrant/server.pem",
   "tlskey": "/home/vagrant/server-key.pem",
   "hosts": [ "fd://", "tcp://0.0.0.0:2376" ],
   "containerd": "/run/containerd/containerd.sock"
}
EOF
        echo "Updating & restarting docker.service ..."
        mkdir -p /etc/systemd/system/docker.service.d
        cat > /etc/systemd/system/docker.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd
EOF

        systemctl daemon-reload
        systemctl restart docker
    fi

    echo "Installing binfmt support..."
    chmod +x /vagrant/setup-binfmt.sh
    cp /vagrant/binfmt-setup.service /etc/systemd/system/
    systemctl enable binfmt-setup.service
    systemctl start binfmt-setup.service
}

cd /home/vagrant

ensure_docker
ensure_mkcert
configure_docker
make_dockercontext
