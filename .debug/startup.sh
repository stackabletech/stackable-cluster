#!/bin/bash

set -x

export HOST_WORKSPACE=$(pwd)
export DOCKER_UID_GID="$(id -u):$(id -g)"
export GIT_LOCAL_BRANCH="jenkins-setup"
export REPO_DIR='/stackable-cluster'
docker pull docker.stackable.tech/t2-testdriver

# execute gradle build
#sh ./mvn-build.sh $HOST_WORKSPACE

docker run --rm \
    --volume "$HOST_WORKSPACE/target/:/target/" \
    --volume "$HOST_WORKSPACE/cluster.yaml:/cluster.yaml" \
    --volume "$HOST_WORKSPACE/kuttl-test.yaml:/kuttl-test.yaml" \
    --volume "$HOST_WORKSPACE/kuttl-test:/kuttl-test" \
    --env T2_TOKEN=$T2_TOKEN \
    --env T2_URL=https://t2.stackable.tech \
    --env UID_GID="$DOCKER_UID_GID" \
    --env DRY_RUN=false \
    --env SPARK_OPERATOR_VERSION=NIGHTLY \
    --env GIT_BRANCH=$GIT_LOCAL_BRANCH \
    --env INTERACTIVE_MODE=true \
    docker.stackable.tech/t2-testdriver
