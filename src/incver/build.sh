#!/bin/sh
docker build -t incver:v$1 --build-arg BASEIMG=go_docker --build-arg VERSION=$1 .

