#!/bin/sh
if [ ! -n "${DOCKER_USERNAME}" ] || [ ! -n "${DOCKER_PASSWORD}" ]; then
  echo "Env vars DOCKER_USERNAME and DOCKER_PASSWORD must be set.";
  exit 1
fi
docker login -u "$DOCKER_USERNAME" -p "$DOCKER_PASSWORD"

# Service 'getip'
docker push "$DOCKER_USERNAME"/getip_arm32v7
docker push "$DOCKER_USERNAME"/getip_amd64
manifest-tool push from-spec src/getip/multiarch.spec
# Service 'healthcheck'
docker push "$DOCKER_USERNAME"/healthcheck_arm32v7
docker push "$DOCKER_USERNAME"/healthcheck_amd64
manifest-tool push from-spec src/healthcheck/multiarch.spec
# Service 'cpuhog'
docker push "$DOCKER_USERNAME"/cpuhog_arm32v7
docker push "$DOCKER_USERNAME"/cpuhog_amd64
manifest-tool push from-spec src/cpuhog/multiarch.spec
# Service 'frontend'
docker push "$DOCKER_USERNAME"/frontend_arm32v7
docker push "$DOCKER_USERNAME"/frontend_amd64
manifest-tool push from-spec src/frontend/multiarch.spec

