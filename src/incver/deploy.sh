#/bin/sh
kubectl -n kube-alive set image deployment/incver-deployment incver=$DOCKER_REPO/incver:v$1
