#!/bin/bash

set -x

ENV=${1:-local}

if [ "${ENV}" == "local" ]; then
  REPO_DIR=$(pwd)
  else
  REPO_DIR=$(dirname ${0})
fi
echo ${REPO_DIR}

docker run --rm -v "$REPO_DIR"/kuttl-test/tests/spark:/spark/minimalSpark:rw -w /spark/minimalSpark gradle:7.3.3-jdk11 gradle clean build

kubectl kuttl test -v 3


