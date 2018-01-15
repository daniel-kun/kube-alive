#!/bin/sh
if [ ! -n "${DOCKER_USERNAME}" ] || [ ! -n "${DOCKER_PASSWORD}" ]; then
  echo "Env vars DOCKER_USERNAME and DOCKER_PASSWORD must be set.";
  exit 1
fi
docker login -u "$DOCKER_USERNAME" -p "$DOCKER_PASSWORD"
docker push "$DOCKER_USERNAME"/getip
docker push "$DOCKER_USERNAME"/healthcheck
docker push "$DOCKER_USERNAME"/cpuhog
docker push "$DOCKER_USERNAME"/frontend

