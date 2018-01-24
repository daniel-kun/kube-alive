#!/bin/sh
if [ ! -n "${DOCKER_REPO}" ] || [ ! -n "${DOCKER_PASSWORD}" ]; then
  echo "Env vars DOCKER_REPO and DOCKER_PASSWORD must be set.";
  exit 1
fi
docker login -u "${DOCKER_REPO}" -p "${DOCKER_PASSWORD}"

# Service 'getip'
docker images | grep -e "^${DOCKER_REPO}/getip_arm32v7" >/dev/zero && docker push "${DOCKER_REPO}/getip_arm32v7"
docker images | grep -e "^${DOCKER_REPO}/getip_amd64" >/dev/zero && docker push "${DOCKER_REPO}/getip_amd64"
docker images | grep -E "^${DOCKER_REPO}/getip_(arm32v7|amd64)" && \
    manifest-tool push from-spec src/getip/multiarch.spec && echo "Successfully pushed 'getip' multiarch container." || \
    echo "WARNING: Will not push 'getip' multiarch container, since none of the architectures are available als containers locally."
# Service 'healthcheck'
docker images | grep -e "^${DOCKER_REPO}/healthcheck_arm32v7" >/dev/zero && docker push "${DOCKER_REPO}/healthcheck_arm32v7"
docker images | grep -e "^${DOCKER_REPO}/healthcheck_amd64" >/dev/zero && docker push "${DOCKER_REPO}/healthcheck_amd64"
docker images | grep -E "^${DOCKER_REPO}/healthcheck_(arm32v7|amd64)" && \
    manifest-tool push from-spec src/healthcheck/multiarch.spec && echo "Successfully pushed 'healthcheck' multiarch container." || \
    echo "WARNING: Will not push 'healthcheck' multiarch container, since none of the architectures are available als containers locally."
# Service 'cpuhog'
docker images | grep -e "^${DOCKER_REPO}/cpuhog_arm32v7" >/dev/zero && docker push "${DOCKER_REPO}/cpuhog_arm32v7"
docker images | grep -e "^${DOCKER_REPO}/cpuhog_amd64" >/dev/zero && docker push "${DOCKER_REPO}/cpuhog_amd64"
docker images | grep -E "^${DOCKER_REPO}/cpuhog_(arm32v7|amd64)" && \
    manifest-tool push from-spec src/cpuhog/multiarch.spec && echo "Successfully pushed 'cpuhog' multiarch container." || \
    echo "WARNING: Will not push 'cpuhog' multiarch container, since none of the architectures are available als containers locally."
# Service 'frontend'
docker images | grep -e "^${DOCKER_REPO}/frontend_arm32v7" >/dev/zero && docker push "${DOCKER_REPO}/frontend_arm32v7"
docker images | grep -e "^${DOCKER_REPO}/frontend_amd64" >/dev/zero && docker push "${DOCKER_REPO}/frontend_amd64"
docker images | grep -E "^${DOCKER_REPO}/frontend_(arm32v7|amd64)" && \
    manifest-tool push from-spec src/frontend/multiarch.spec && echo "Successfully pushed 'frontend' multiarch container." || \
    echo "WARNING: Will not push 'frontend' multiarch container, since none of the architectures are available als containers locally."

