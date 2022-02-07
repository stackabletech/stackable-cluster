#!/bin/bash

set -x

REPO_DIR=$(dirname $0)

echo ${REPO_DIR}

docker run --rm -v kuttl-test/tests/spark:/spark/minimalSpark:rw -w /spark/minimalSpark gradle:7.3.3-jdk11 gradle clean build

kubectl kuttl test --kind-config ./kind.yaml --kind-context stkbl-cntxt


