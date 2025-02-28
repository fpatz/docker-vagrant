#!/bin/sh
docker context rm -f docker-parallels || true
if [ $1 == "deploy" ]; then
    docker context import docker-parallels docker-parallels.dockercontext
    docker context use docker-parallels
fi
