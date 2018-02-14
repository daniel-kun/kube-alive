#!/bin/sh
set -e
docker run -p 0.0.0.0:8080:8080 -v /var/run/docker.sock:/var/run/docker.sock -it ${DOCKER_REPO}/incver:v$1

