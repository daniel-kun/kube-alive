#!/bin/bash
if [ -z "`kubectl version`" ]; then
    echo "kubectl is not installed, aborting"
    exit 1
fi

export KUBEALIVE_PUBLICIP=`kubectl config view --minify=true | grep server | sed 's/.*http[s]:\/\/\(.*\):.*/\1/'`
echo "Using ${KUBEALIVE_PUBLICIP} as the exposed IP to access kube-alive."

LOCAL=0
if [ $# -eq 1 ] && [ $1 = "local" ]; then
    LOCAL=1
    echo "Deploying locally from deploy/."
    if [ ! -n "${DOCKER_REPO}" ]; then
        echo "\$DOCKER_REPO not set, aborting"
        exit 1
    else
        echo "Using docker repo \"${DOCKER_REPO}\""
    fi
else
    echo "Deploying from github."
    if [ ! -n "${DOCKER_REPO}" ]; then
        echo "\$DOCKER_REPO not set, using \"kubealive\" as a default"
        export DOCKER_REPO=kubealive
    fi
fi

for service in `echo "namespace
getip
healthcheck
cpuhog
frontend
incver"`; do
    if [ ${LOCAL} -eq 1 ]; then
        cat "./deploy/${service}.yml" | sed "s/%%KUBEALIVE_PUBLICIP%%/${KUBEALIVE_PUBLICIP}/" | sed "s/%%DOCKER_REPO%%/${DOCKER_REPO}/" | kubectl apply -f -
    else
        curl -sSL "https://raw.githubusercontent.com/daniel-kun/kube-alive/master/deploy/${service}.yml" | sed "s/%%KUBEALIVE_PUBLICIP%%/${KUBEALIVE_PUBLICIP}/" | sed "s/%%DOCKER_REPO%%/${DOCKER_REPO}/" | kubectl apply -f -
    fi
done

echo "
FINISHED!

You should now be able to access kube-alive at 

    http://${KUBEALIVE_PUBLICIP}/

Also, you can look at all those neat Kubernetes resources that havee been created via

    kubectl get all -n kube-alive
"
