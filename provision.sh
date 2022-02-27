#!/bin/sh
if [ ! -d /etc/docker ]; then
    echo "Install up-to-date docker from docker.com"
    apt-get -q update -q
    apt-get -y -qq install -q \
	    ca-certificates \
	    curl \
	    gnupg \
	    lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo \
	"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
	  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get -q update -q
    apt-get -y -qq install docker-ce docker-ce-cli containerd.io
else
    echo "Docker is already installed"
fi

if [ ! -x mkcert ]; then
    echo "Downloading mkcert"
    curl -L https://github.com/FiloSottile/mkcert/releases/download/v1.4.3/mkcert-v1.4.3-linux-amd64 -o mkcert
    chmod +x mkcert
fi

IP=$(hostname -I | awk '{print $1}')

if [ ! -f server.pem ]; then
    ./mkcert -cert-file server.pem -key-file server-key.pem $IP
fi
mkdir -p tls/docker
if [ ! -f tls/docker/cert.pem ]; then
    ./mkcert -client -cert-file tls/docker/cert.pem -key-file tls/docker/key.pem host
    cp /root/.local/share/mkcert/rootCA.pem tls/docker/ca.pem
fi

cat > meta.json <<EOF
{
  "Name": "docker-parallels",
  "Metadata": {"Description": "dockerhost"},
  "Endpoints": {
    "docker":{
      "Host": "tcp://$IP:2376",
      "SkipTLSVerify":false
    }
  }
}
EOF

tar cvf docker-parallels.dockercontext meta.json tls

echo "Updating /etc/docker/daemon.json"
cat > /etc/docker/daemon.json <<'EOF'
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
