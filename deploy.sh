#!/bin/bash
if [ -z "`kubectl version`" ]; then
    echo "kubectl is not installed, aborting";
    exit 1;
fi

export KUBEALIVE_PUBLICIP=`kubectl config view | grep server | sed 's/.*http[s]:\/\/\(.*\):.*/\1/'`
echo "Using ${KUBEALIVE_PUBLICIP} as the exposed IP to access kube-alive."

LOCAL=0
if [ $# -eq 1 ] && [ $1 = "local" ]; then
    LOCAL=1
    echo "Deploying locally from deploy/."
else
    echo "Deploying from github."
fi

for service in `echo "getip
healthcheck
cpuhog
frontend"`; do
    if [ ${LOCAL} -eq 1 ]; then
        cat "./deploy/${service}.yml" | sed "s/%%KUBEALIVE_PUBLICIP%%/${KUBEALIVE_PUBLICIP}/" | kubectl apply -f -
    else
        curl -sSL "https://raw.githubusercontent.com/daniel-kun/kube-alive/master/deploy/${service}.yml" | sed "s/%%KUBEALIVE_PUBLICIP%%/${KUBEALIVE_PUBLICIP}/" | kubectl apply -f -
    fi
done

echo "

    INFO:
    In case you don't see any pods listed in the colored boxes, it might be because your
    service account does not have enough privileges to list the pods. You can use this
    extreme mnd highly unsecure method to grant the default service account access to everything:

    kubectl create clusterrolebinding add-on-cluster-admin-default --clusterrole=cluster-admin  --serviceaccount=default:default

    After executing this, you should be able to reload the browser and see the pods.)

FINISHED!
You should now be able to access kube-alive at http://${KUBEALIVE_PUBLICIP}/.
";
