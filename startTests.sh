#!/bin/bash

set -x

REPO_DIR=$(dirname $0)

echo ${REPO_DIR}

# build image with openJDK 11 + gradle for constant jdk and .jar files
docker image build -t jar-builder:latest -f ${REPO_DIR}/kuttl-test/tests/spark/Dockerfile .
docker run --rm docker.stackable.tech/stackable/gradle:7.3.3-stackable0 \
      -v $PWD/kuttl-test/tests/spark:/stackable:rw jar-builder build

kubectl kuttl test -v 3

