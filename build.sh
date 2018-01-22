#!/bin/sh

# Find out architecture or read it from command line:
ARCH=$1
if [ -z "${ARCH}" ]; then
    if uname -a | grep arm > /dev/null; then
        ARCH=arm32v7
    else
        ARCH=amd64
    fi
fi

echo "Building docker images for architecture ${ARCH}."

# Check for mandatory parameters: 
if [ ! -n "${DOCKER_USERNAME}" ]; then
    echo "Env var DOCKER_USERNAME must be set.";
    exit 1
fi

# Now build the docker containers:
echo "Building getip..."
docker build -t "${DOCKER_USERNAME}/getip_${ARCH}" src/getip --build-arg "ARCH=${ARCH}"
echo "Building healthcheck..."
# docker build -t "${DOCKER_USERNAME}/healthcheck_${ARCH}" src/healthcheck --build-arg "ARCH=${ARCH}"
echo "Building cpuhog..."
# docker build -t "${DOCKER_USERNAME}/cpuhog_${ARCH}" src/cpuhog --build-arg "ARCH=${ARCH}"
echo "Building frontend..."
#docker build -t "${DOCKER_USERNAME}/frontend_${ARCH}" src/frontend --build-arg "ARCH=${ARCH}"
echo "Build finished."

