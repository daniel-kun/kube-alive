#!/bin/sh
set -e
docker push ${DOCKER_REPO}/incver:v$1
