#!/bin/sh
set -e
docker push ${KUBEALIVE_DOCKER_REPO}/incver:v$1
