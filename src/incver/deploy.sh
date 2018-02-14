#!/bin/sh
set -e
kubectl -n kube-alive set image deployment/incver-deployment incver=$DOCKER_REPO/incver:v$1
