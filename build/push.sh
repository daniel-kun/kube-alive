#!/bin/sh
if [ ! -n "${DOCKER_REPO}" ] || [ ! -n "${DOCKER_USERNAME}" ] || [ ! -n "${DOCKER_PASSWORD}" ]; then
  echo "Env vars DOCKER_REPO, DOCKER_USERNAME and DOCKER_PASSWORD must be set.";
  exit 1
fi
docker login -u "${DOCKER_USERNAME}" -p "${DOCKER_PASSWORD}" 
if [ $? != 0 ]; then
    echo "ERROR: Failed to log in to Docker Hub!"
    exit 1;
fi

echo "Successfully logged in as ${DOCKER_USERNAME}, will push to repo ${DOCKER_REPO}"

pushMultiArch ()
{
    TEMPSPEC=`tempfile`
    docker images | grep -e "^${DOCKER_REPO}/$1_arm32v7" >/dev/zero && docker push "${DOCKER_REPO}/$1_arm32v7"
    docker images | grep -e "^${DOCKER_REPO}/$1_amd64" >/dev/zero && docker push "${DOCKER_REPO}/$1_amd64"
    sed "s/%%DOCKER_REPO%%/${DOCKER_REPO}/g" src/$1/multiarch.templspec > "${TEMPSPEC}" 

    docker images | grep -E "^${DOCKER_REPO}/$1_(arm32v7|amd64)" && \
        manifest-tool push from-spec "${TEMPSPEC}" && \
        echo "Successfully pushed '$1' multiarch container." || \
        echo "WARNING: Will not push '$1' multiarch container, since none of the architectures are available als containers locally."
    rm -f "${TEMPSPEC}"
}

pushMultiArch "getip"
pushMultiArch "healthcheck"
pushMultiArch "cpuhog"
pushMultiArch "frontend"

