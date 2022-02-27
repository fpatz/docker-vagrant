#!/bin/sh
docker context rm -f docker-parallels || true
docker context import docker-parallels docker-parallels.dockercontext
docker context use docker-parallels
