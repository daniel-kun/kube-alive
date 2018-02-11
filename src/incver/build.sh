#!/bin/sh
docker build -t incver:v$1 --build-arg BASEIMG=192.168.178.87:5000/go_docker --build-arg VERSION=$1 .

