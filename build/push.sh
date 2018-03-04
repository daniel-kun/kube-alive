#!/bin/sh
set -e
if [ -z "${KUBEALIVE_BRANCH}" ]; then
    echo "Building for docker repository ${KUBEALIVE_DOCKER_REPO}, without branch suffix."
    BRANCH_SUFFIX=
    # Check for mandatory parameters: 
    if [ ! -n "${KUBEALIVE_DOCKER_REPO}" ]; then
        KUBEALIVE_DOCKER_REPO=kubealive
    fi
else
    if [ ! -n "${KUBEALIVE_DOCKER_REPO}" ]; then
        echo "Env var KUBEALIVE_DOCKER_REPO must be set.";
        exit 1
    fi
    BRANCH_SUFFIX="_${KUBEALIVE_BRANCH}"
    echo "Building for docker repository ${KUBEALIVE_DOCKER_REPO}, with branch suffix ${KUBEALIVE_BRANCH}."
fi

if [ ! -n "${KUBEALIVE_DOCKER_REPO}" ] || [ ! -n "${DOCKER_USERNAME}" ] || [ ! -n "${DOCKER_PASSWORD}" ]; then
  echo "Env vars KUBEALIVE_DOCKER_REPO, DOCKER_USERNAME and DOCKER_PASSWORD must be set.";
  exit 1
fi
docker login -u "${DOCKER_USERNAME}" -p "${DOCKER_PASSWORD}" 
if [ $? != 0 ]; then
    echo "ERROR: Failed to log in to Docker Hub!"
    exit 1;
fi

echo "Successfully logged in as ${DOCKER_USERNAME}, will push to repo ${KUBEALIVE_DOCKER_REPO}"

pushMultiArch ()
{
    TEMPSPEC=`tempfile`
    docker images | grep -e "^${KUBEALIVE_DOCKER_REPO}/$1${BRANCH_SUFFIX}_arm32v7 *$2" > /dev/zero && docker push "${KUBEALIVE_DOCKER_REPO}/$1${BRANCH_SUFFIX}_arm32v7:$2"
    docker images | grep -e "^${KUBEALIVE_DOCKER_REPO}/$1${BRANCH_SUFFIX}_arm64v8 *$2" > /dev/zero && docker push "${KUBEALIVE_DOCKER_REPO}/$1${BRANCH_SUFFIX}_arm64v8:$2"
    docker images | grep -e "^${KUBEALIVE_DOCKER_REPO}/$1${BRANCH_SUFFIX}_amd64 *$2" > /dev/zero && docker push "${KUBEALIVE_DOCKER_REPO}/$1${BRANCH_SUFFIX}_amd64:$2"
    sed "s/%%KUBEALIVE_DOCKER_REPO%%/${KUBEALIVE_DOCKER_REPO}/g" src/$1/multiarch.templspec | sed "s/%%BRANCH_SUFFIX%%/${BRANCH_SUFFIX}/" | \
        sed "s/%%TAG%%/$2/g" > "${TEMPSPEC}" 

    if docker images | grep -E "^${KUBEALIVE_DOCKER_REPO}/$1${BRANCH_SUFFIX}_arm32v7 *$2" && \
        docker images | grep -E "^${KUBEALIVE_DOCKER_REPO}/$1${BRANCH_SUFFIX}_amd64 *$2" && \
           docker images | grep -E "^${KUBEALIVE_DOCKER_REPO}/$1${BRANCH_SUFFIX}_arm64v8 *$2" ; then
        if manifest-tool push from-spec "${TEMPSPEC}"; then
            echo "Successfully pushed '$1' multiarch container."
        else
                echo "Failed pushing '$1' multiarch container."
            exit 1
        fi
    else
        echo "WARNING: Will not push '$1' multiarch container, since not all architectures are available as containers locally."
    fi
    rm -f "${TEMPSPEC}"
}

pushMultiArch "getip" "latest"
pushMultiArch "healthcheck" "latest"
pushMultiArch "cpuhog" "latest"
for i in 1 2 3 4 5
do
    pushMultiArch "incver" "v$i"
done
pushMultiArch "frontend" "latest"

