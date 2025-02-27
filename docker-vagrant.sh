#!/usr/bin/env bash

if [[ "$1" == "docker-cli-plugin-metadata" ]]; then
    cat <<EOF
{
     "SchemaVersion": "0.1.0",
     "Vendor": "me",
     "Version": "v0.1",
     "ShortDescription": "Manage Parallels Docker Machine"
}
EOF
    exit 0
fi

VAGRANT_CMD=vagrant

if ! command -v $VAGRANT_CMD &> /dev/null; then
    echo "Please install Vagrant." 2>&1
    exit -1
fi

if ! $VAGRANT_CMD plugin list | grep -q vagrant-parallels; then
    echo "Please install the vagrant-parallels plugin." 2>&1
    exit -1
fi

shift

VAGRANT_CWD=$(dirname `readlink $0`)
cd $VAGRANT_CWD
$VAGRANT_CMD $*
