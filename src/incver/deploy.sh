#/bin/sh
kubectl set image deployment/incver incver=$DOCKER_REPO/incver:v$1
