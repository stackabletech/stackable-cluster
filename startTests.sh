#!/bin/bash

set -x

REPO_DIR=$(dirname $0)

docker image build --no-cache -t gradle-build:latest -f ${REPO_DIR}/kuttl-test/tests/spark/Dockerfile .
docker container run -d --name jarBuilder -t gradle-build bash
export CONTAINER_ID=$(docker ps -aqf "name=^jarBuilder$")

docker exec -it ${CONTAINER_ID} bash -c "gradle build"

docker cp ${CONTAINER_ID}:/stackable/minimalSpark/build/libs/minimalSpark.jar /tmp/

docker stop ${CONTAINER_ID}
docker rm ${CONTAINER_ID}

#docker run -iv${PWD}:/stackable/minimalSpark/build/libs gradle-build sh -s <<EOF
#chown -v $(id -u):$(id -g) minimalSpark.jar
#cp -va minimalSpark.jar /tmp
#EOF

#kubectl kuttl test -v 3