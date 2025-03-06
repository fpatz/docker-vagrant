#!/usr/bin/env bash

set -euo pipefail

if [[ "${1:-}" == "docker-cli-plugin-metadata" ]]; then
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
    echo "Prequisite missing: did not find the 'vagrant' command." >&2
    exit 1
fi

if ! $VAGRANT_CMD plugin list | grep -q vagrant-parallels; then
    echo "Prerequisite missing: install the 'vagrant-parallels' plugin by"\
	 "running 'vagrant plugin install vagrant-parallels'">&2
    exit 1
fi

shift

project_directory=$(dirname `readlink $0`)
cd $project_directory && $VAGRANT_CMD $*
