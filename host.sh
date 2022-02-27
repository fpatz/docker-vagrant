#!/bin/sh
vagrant ssh -c "cat docker-parallels.dockercontext" > docker-parallels.dockercontext
docker context rm -f docker-parallels || true
docker context import docker-parallels docker-parallels.dockercontext
docker context use docker-parallels
