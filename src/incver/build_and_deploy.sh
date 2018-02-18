#!/bin/sh
set -e
./build.sh $1 && ./push.sh $1 && ./deploy.sh $1

