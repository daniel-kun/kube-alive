#!/bin/bash
set -e
if [ -z "`kubectl version`" ]; then
    echo "kubectl is not installed, aborting"
    exit 1
fi

export KUBEALIVE_PUBLICIP=`kubectl config view --minify=true | grep "server: http" | sed 's/ *server: http:\/\///' | sed 's/ *server: https:\/\///' | sed 's/:.*//'`
echo "Using ${KUBEALIVE_PUBLICIP} as the exposed IP to access kube-alive."

ARCHSUFFIX=
LOCAL=0
if [ $# -eq 1 ] && [ $1 = "local" ]; then
    LOCAL=1
    if uname -a | grep arm > /dev/null; then
        ARCHSUFFIX=_arm32v7
    else
        ARCHSUFFIX=_amd64
    fi

    echo "Deploying locally for architecture ${ARCHSUFFIX} from deploy/."
    if [ ! -n "${KUBEALIVE_DOCKER_REPO}" ]; then
        echo "\$KUBEALIVE_DOCKER_REPO not set, aborting"
        exit 1
    else
        echo "Using docker repo \"${KUBEALIVE_DOCKER_REPO}\""
    fi
else
    echo "Deploying from github."
    if [ ! -n "${KUBEALIVE_DOCKER_REPO}" ]; then
        echo "\$KUBEALIVE_DOCKER_REPO not set, using \"kubealive\" as a default"
        export KUBEALIVE_DOCKER_REPO=kubealive
    fi
fi

if [ -z "${KUBEALIVE_BRANCH}" ]; then
    BRANCH_SUFFIX=
else
    BRANCH_SUFFIX="_${KUBEALIVE_BRANCH}"
fi
    

for service in `echo "namespace
getip
healthcheck
cpuhog
frontend
incver"`; do
    if [ ${LOCAL} -eq 1 ]; then
        cat "./deploy/${service}.yml" | sed "s/%%KUBEALIVE_PUBLICIP%%/${KUBEALIVE_PUBLICIP}/" | sed "s/%%KUBEALIVE_DOCKER_REPO%%/${KUBEALIVE_DOCKER_REPO}/" | sed "s/%%ARCHSUFFIX%%/${ARCHSUFFIX}/" | sed "s/%%BRANCH_SUFFIX%%/${BRANCH_SUFFIX}/" | kubectl apply -f -
    else
        curl -sSL "https://raw.githubusercontent.com/daniel-kun/kube-alive/master/deploy/${service}.yml" | sed "s/%%KUBEALIVE_PUBLICIP%%/${KUBEALIVE_PUBLICIP}/" | sed "s/%%KUBEALIVE_DOCKER_REPO%%/${KUBEALIVE_DOCKER_REPO}/" | sed "s/%%ARCHSUFFIX%%/${ARCHSUFFIX}/" | sed "s/%%BRANCH_SUFFIX%%/${BRANCH_SUFFIX}/" | kubectl apply -f -
    fi
done

echo "
FINISHED!

You should now be able to access kube-alive at 

    http://${KUBEALIVE_PUBLICIP}/

Also, you can look at all those neat Kubernetes resources that havee been created via

    kubectl get all -n kube-alive
"
