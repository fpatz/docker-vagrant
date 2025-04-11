#!/bin/sh
docker context rm -f docker-parallels > /dev/null
if [ $1 == "deploy" ]; then
    docker context import docker-parallels docker-parallels.dockercontext > /dev/null
    docker context use docker-parallels > /dev/null
fi
