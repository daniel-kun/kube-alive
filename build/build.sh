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

# Find out architecture or read it from command line:
ARCH=$1
if [ -z "${ARCH}" ]; then
    if uname -a | grep arm64 > /dev/null; then
        ARCH=arm64v8
    else
        if uname -a | grep arm > /dev/null; then
            ARCH=arm32v7
        else
            ARCH=amd64
        fi
    fi
fi


# Set appropriate BASEIMG depending on $ARCH:
case $ARCH in
    arm64v8)
            GOLANG_BASEIMG=arm64v8/alpine
            GO_KUBECTL_BASEIMG=danielkun/alpine-kubectl-arm64v8
            NGINX_BASEIMG=arm64v8/nginx
            GOARCH=arm64
            GOARM=
        ;;
    arm32v7)
            GOLANG_BASEIMG=hypriot/rpi-alpine-scratch
            GO_KUBECTL_BASEIMG=danielkun/alpine-kubectl-arm32v7
            NGINX_BASEIMG=arm32v7/nginx
            GOARCH=arm
            GOARM=7
        ;;
    amd64)
            GOLANG_BASEIMG=amd64/alpine
            GO_KUBECTL_BASEIMG=danielkun/alpine-kubectl-x86_64
            NGINX_BASEIMG=amd64/nginx
            GOARCH=amd64
            GOARM=
        ;;
    *)
        echo "Unsupported ARCH ${ARCH}"
        exit 1
        ;;
esac

echo "Building docker images for architecture ${ARCH}."

# Now build the docker containers:
echo "Building getip..."
echo "GOARCH: ${GOARCH}, GOARM: ${GOARM}"
docker build -t "${KUBEALIVE_DOCKER_REPO}/getip${BRANCH_SUFFIX}_${ARCH}" src/getip --build-arg "BASEIMG=${GOLANG_BASEIMG}" --build-arg ARCH=${GOARCH} --build-arg ARM=${GOARM}
echo "Building healthcheck..."
docker build -t "${KUBEALIVE_DOCKER_REPO}/healthcheck${BRANCH_SUFFIX}_${ARCH}" src/healthcheck --build-arg "BASEIMG=${GOLANG_BASEIMG}" --build-arg ARCH=${GOARCH} --build-arg ARM=${GOARM}
echo "Building cpuhog..."
docker build -t "${KUBEALIVE_DOCKER_REPO}/cpuhog${BRANCH_SUFFIX}_${ARCH}" src/cpuhog --build-arg "BASEIMG=${GOLANG_BASEIMG}" --build-arg ARCH=${GOARCH} --build-arg ARM=${GOARM}
echo "Building incver base image..."
export INCVER_BASEIMG="${KUBEALIVE_DOCKER_REPO}/incver${BRANCH_SUFFIX}_${ARCH}:v1"
docker build -t "${INCVER_BASEIMG}" src/incver --build-arg "BASEIMG=${GO_KUBECTL_BASEIMG}" --build-arg VERSION=1 --build-arg ARCH=${GOARCH} --build-arg ARM=${GOARM}
for v in 2 3 4 5
do
    echo "Building incver v$v..."
    docker build -t "${KUBEALIVE_DOCKER_REPO}/incver${BRANCH_SUFFIX}_${ARCH}:v$v" -f src/incver/Dockerfile.vNext src/incver --build-arg "BASEIMG=${INCVER_BASEIMG}" --build-arg VERSION=$v
done
echo "Building frontend..."
docker build -t "${KUBEALIVE_DOCKER_REPO}/frontend${BRANCH_SUFFIX}_${ARCH}" src/frontend --build-arg "BASEIMG=${NGINX_BASEIMG}"
echo "
Build for CPU ${ARCH} finished.
You can now 'make push' to push the built containers to your registry. (You have to set KUBEALIVE_DOCKER_REPO, DOCKER_USERNAME and DOCKER_PASSWORD first.)"

