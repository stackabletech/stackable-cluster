#!/bin/bash

set -x

REPO_DIR=$(dirname $0)

echo ${REPO_DIR}

# build image with openJDK 11 + gradle for constant jdk and .jar files
docker image build --no-cache -t gradle-build:latest -f ${REPO_DIR}/kuttl-test/tests/spark/Dockerfile .
docker container run -d --name jarBuilder -t gradle-build bash
export CONTAINER_ID=$(docker ps -aqf "name=^jarBuilder$")
docker exec -it ${CONTAINER_ID} bash -c "gradle build"

mkdir ${REPO_DIR}/kuttl-test/tests/spark/minimalSpark/docker-gradle-build
docker cp ${CONTAINER_ID}:/stackable/minimalSpark/build/libs/minimalSpark.jar ${REPO_DIR}/kuttl-test/tests/spark/minimalSpark/docker-gradle-build
#chown 700 ${REPO_DIR}/kuttl-test/tests/spark/minimalSpark/docker-gradle-build/minimalSpark.jar

docker stop ${CONTAINER_ID}
docker rm ${CONTAINER_ID}

kubectl kuttl test -v 3

rm -r -f ${REPO_DIR}/kuttl-test/tests/spark/minimalSpark/docker-gradle-build