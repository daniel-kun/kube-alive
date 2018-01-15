#!/bin/sh
if [ ! -n "${DOCKER_USERNAME}" ]; then
  echo "Env var DOCKER_USERNAME must be set.";
  exit 1
fi
docker build -t "${DOCKER_USERNAME}"/getip src/getip
docker build -t "${DOCKER_USERNAME}"/healthcheck src/healthcheck
docker build -t "${DOCKER_USERNAME}"/cpuhog src/cpuhog
docker build -t "${DOCKER_USERNAME}"/frontend src/frontend

