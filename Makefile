all: build

build:
ifndef DOCKER_REPO
	$(error DOCKER_REPO is not defined)
endif
	build/build.sh

cross-build:
ifndef DOCKER_REPO
	$(error DOCKER_REPO is not defined)
endif
	build/build.sh arm32v7
	build/build.sh amd64

push:
ifndef DOCKER_REPO
	$(error DOCKER_REPO is not defined)
	$(error DOCKER_PASSWORD is not defined)
endif
	build/push.sh

.PHONY: build build-cross push
