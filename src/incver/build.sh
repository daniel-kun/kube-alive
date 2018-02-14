#!/bin/sh
set -e
docker build -t ${DOCKER_REPO}/incver:v$1 --build-arg BASEIMG=${DOCKER_REPO}/go_docker_kubectl --build-arg VERSION=$1 --build-arg DOCKER_REPO=${DOCKER_REPO} .

