#!/bin/sh
set -e
docker build -t ${KUBEALIVE_DOCKER_REPO}/incver:v$1 --build-arg BASEIMG=${KUBEALIVE_DOCKER_REPO}/go_docker_kubectl --build-arg VERSION=$1 --build-arg KUBEALIVE_DOCKER_REPO=${KUBEALIVE_DOCKER_REPO} .

