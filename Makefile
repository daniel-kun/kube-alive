all: build

build:
ifndef KUBEALIVE_DOCKER_REPO
	$(error KUBEALIVE_DOCKER_REPO is not defined)
endif
	build/build.sh

cross-build:
ifndef KUBEALIVE_DOCKER_REPO
	$(error KUBEALIVE_DOCKER_REPO is not defined)
endif
	build/build.sh arm32v7
	build/build.sh amd64

push:
ifndef KUBEALIVE_DOCKER_REPO
	$(error KUBEALIVE_DOCKER_REPO is not defined)
endif
ifndef DOCKER_USERNAME
	$(error DOCKER_USERNAME is not defined)
endif
ifndef DOCKER_PASSWORD
	$(error DOCKER_PASSWORD is not defined)
endif
	build/push.sh

deploy:
ifndef KUBEALIVE_DOCKER_REPO
	$(error KUBEALIVE_DOCKER_REPO is not defined)
endif
	./deploy.sh local

.PHONY: build build-cross push deploy

