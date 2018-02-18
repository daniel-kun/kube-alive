#!/bin/bash

if [ "${TRAVIS_BRANCH}" = "master" ];
then
    echo "WARNING: Building master for live kubealive repo" 
    KUBEALIVE_BRANCH="" KUBEALIVE_DOCKER_REPO=kubealive make $1
else
    KUBEALIVE_BRANCH="${TRAVIS_BRANCH}" make $1
fi
