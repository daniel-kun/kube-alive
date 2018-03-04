#!/bin/bash
set -e
if [ -z "`kubectl version`" ]; then
    echo "kubectl is not installed, aborting"
    exit 1
fi

echo "Detecting Kubernetes installation..."
KUBECFG=`kubectl config view --minify=true`
USEINGRESS=false

if echo "${KUBECFG}" | grep "name: minikube"  > /dev/zero; then
    echo "Kubernetes on Minikube detected!"
else
    if echo "${KUBECFG}" | grep -e '^ *server:.*azmk8s\.io:443$' > /dev/zero; then
        echo "Kubernetes on AKS detected!"
        USEINGRESS=true
    else
        if echo "${KUBECFG}" | grep "name: gke_" > /dev/zero; then
            echo "Kubernetes on GKE detected!"
            USEINGRESS=true
        else
            echo "No specific Kubernetes provider detected, assuming Kubernetes runs on bare metal!"
        fi
    fi
fi

if [ ${USEINGRESS} = true ]
then
    echo "Will use an ingress to enable access to kube-alive."
else
    export KUBEALIVE_PUBLICIP=`kubectl config view --minify=true | grep "server: http" | sed 's/ *server: http:\/\///' | sed 's/ *server: https:\/\///' | sed 's/:.*//'`
    echo "Will use a Service with external IP ${KUBEALIVE_PUBLICIP} to enable access to kube-alive."
fi

ARCHSUFFIX=
LOCAL=0
if [ $# -eq 1 ] && [ $1 = "local" ]; then
    LOCAL=1
    if uname -a | grep arm64 > /dev/null; then
        ARCHSUFFIX=_arm64v8
    else
        if uname -a | grep arm > /dev/null; then
            ARCHSUFFIX=_arm32v7
        else
            ARCHSUFFIX=_amd64
        fi
    fi

    echo "Deploying locally for architecture ${ARCHSUFFIX} from deploy/."
    if [ ! -n "${KUBEALIVE_DOCKER_REPO}" ]; then
        echo "\$KUBEALIVE_DOCKER_REPO not set, aborting."
        exit 1
    else
        echo "Using docker repo \"${KUBEALIVE_DOCKER_REPO}\"."
    fi
else
    echo "Deploying from github."
    if [ ! -n "${KUBEALIVE_DOCKER_REPO}" ]; then
        echo "\$KUBEALIVE_DOCKER_REPO not set, using \"kubealive\" as a default."
        export KUBEALIVE_DOCKER_REPO=kubealive
    else
        echo "Using docker repo \"${KUBEALIVE_DOCKER_REPO}\"."
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
incver
frontend"`; do
    if [ ${LOCAL} -eq 1 ]; then
        cat "./deploy/${service}.yml" | sed "s/%%KUBEALIVE_DOCKER_REPO%%/${KUBEALIVE_DOCKER_REPO}/" | sed "s/%%ARCHSUFFIX%%/${ARCHSUFFIX}/" | sed "s/%%BRANCH_SUFFIX%%/${BRANCH_SUFFIX}/" | kubectl apply -f -
    else
        curl -sSL "https://raw.githubusercontent.com/daniel-kun/kube-alive/master/deploy/${service}.yml" | sed "s/%%KUBEALIVE_DOCKER_REPO%%/${KUBEALIVE_DOCKER_REPO}/" | sed "s/%%ARCHSUFFIX%%/${ARCHSUFFIX}/" | sed "s/%%BRANCH_SUFFIX%%/${BRANCH_SUFFIX}/" | kubectl apply -f -
    fi
done

if [ ${USEINGRESS} = true ]
then
    if [ ${LOCAL} -eq 1 ]; then
        kubectl apply -f ./deploy/ingress.yml
    else
        kubectl apply -f "https://raw.githubusercontent.com/daniel-kun/kube-alive/master/deploy/ingress.yml"
    fi

    echo "
    FINISHED!

    If you have an ingress controller installed, you should be able to access kube-alive through the ingresses external IP soon.

    THIS CAN TAKE UP TO 10 MINUTES to work properly and requests may result in 500s or 404s in the meantime.

    If you don't have an ingress controller installed, yet, you should install one now. 
    
    Either using helm:

       helm install stable/nginx-ingress

    or using the official nginx-ingress docs on

        https://github.com/kubernetes/ingress-nginx/blob/master/deploy/README.md

"

else
    if [ ${LOCAL} -eq 1 ]; then
         cat ./deploy/external-ip.yml | sed "s/%%KUBEALIVE_PUBLICIP%%/${KUBEALIVE_PUBLICIP}/"  | kubectl apply -f -
    else
        curl -sSL "https://raw.githubusercontent.com/daniel-kun/kube-alive/master/deploy/external-ip.yml" | sed "s/%%KUBEALIVE_PUBLICIP%%/${KUBEALIVE_PUBLICIP}/" | kubectl apply -f -
    fi
    echo "
    FINISHED!

    You should now be able to access kube-alive at 

        http://${KUBEALIVE_PUBLICIP}/

"

fi

echo "Also, you can look at all those neat Kubernetes resources that havee been created via

    kubectl get all -n kube-alive
"
