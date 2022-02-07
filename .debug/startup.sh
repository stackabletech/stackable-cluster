#!/bin/bash

set -x

export HOST_WORKSPACE='/Users/Simon/Repo/stackable/stackable-cluster'
export DOCKER_UID_GID="$(id -u):$(id -g)"
export GIT_LOCAL_BRANCH="jenkins-setup"
export REPO_DIR='/stackable-cluster'
docker pull docker.stackable.tech/t2-testdriver

# execute gradle build
sh ../gradle-build.sh $HOST_WORKSPACE

docker run --rm \
    --volume "$HOST_WORKSPACE/target/:/target/" \
    --volume "$HOST_WORKSPACE/.ci/debug/cluster.yaml:/cluster.yaml" \
    --volume "$HOST_WORKSPACE/.ci/debug/test.sh:/test.sh" \
    --volume "$HOST_WORKSPACE/kuttl-test/tests/spark/minimalSpark/distribution:/tmp" \
    --env T2_TOKEN=$T2_TOKEN \
    --env T2_URL=https://t2.stackable.tech \
    --env UID_GID="$DOCKER_UID_GID" \
    --env DRY_RUN=false \
    --env SPARK_OPERATOR_VERSION=NIGHTLY \
    --env GIT_BRANCH=$GIT_LOCAL_BRANCH \
    --env INTERACTIVE_MODE=true \
    --env REPO_DIR=$REPO_DIR \
    docker.stackable.tech/t2-testdriver


    # replace GIT branch in test script
#    sed "s#\$GIT_BRANCH#$GIT_BRANCH#g" hdfs-operator/.ci/integration-tests/hcloud-centos-8/test.sh > _test.sh
