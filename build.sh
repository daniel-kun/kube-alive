#!/bin/sh

# Check for mandatory parameters: 
if [ ! -n "${DOCKER_USERNAME}" ]; then
    echo "Env var DOCKER_USERNAME must be set.";
    exit 1
fi

# Find out architecture or read it from command line:
ARCH=$1
if [ -z "${ARCH}" ]; then
    if uname -a | grep arm > /dev/null; then
        ARCH=arm32v7
    else
        ARCH=amd64
    fi
fi

# Set appropriate BASEIMG depending on $ARCH:
case $ARCH in
    arm32v7)
            # We need these base images, because they contain qemu-armhf-satic
            GOLANG_BASEIMG=resin/raspberrypi3-golang 
            NGINX_BASEIMG=alexellis2/nginx-arm
        ;;
    amd64)
            GOLANG_BASEIMG=golang
            NGINX_BASEIMG=nginx
        ;;
    *)
        echo "Unsupported ARCH ${ARCH}"
        exit 1
        ;;
esac

echo "Building docker images for architecture ${ARCH}."

# Now build the docker containers:
echo "Building getip..."
docker build -t "${DOCKER_USERNAME}/getip_${ARCH}" src/getip --build-arg "BASEIMG=${GOLANG_BASEIMG}" && \
echo "Building healthcheck..." && \
docker build -t "${DOCKER_USERNAME}/healthcheck_${ARCH}" src/healthcheck --build-arg "BASEIMG=${GOLANG_BASEIMG}" && \
echo "Building cpuhog..." && \
docker build -t "${DOCKER_USERNAME}/cpuhog_${ARCH}" src/cpuhog --build-arg "BASEIMG=${GOLANG_BASEIMG}" && \
echo "Building frontend..." && \
docker build -t "${DOCKER_USERNAME}/frontend_${ARCH}" src/frontend --build-arg "BASEIMG=${NGINX_BASEIMG}" && \
echo "Build finished." && exit 0  || echo "Build failed" && exit 1

