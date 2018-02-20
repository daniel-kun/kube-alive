#!/bin/sh
set -e
kubectl -n kube-alive set image deployment/incver-deployment incver=${KUBEALIVE_DOCKER_REPO}/incver${BRANCH_SUFFIX}${ARCHSUFFIX}:v$1
