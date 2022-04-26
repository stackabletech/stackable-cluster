#!/bin/bash

set -x

docker run --rm -v $(pwd)/test-jobs-root:/test-jobs-root \
          -w /test-jobs-root maven:3.8.4-jdk-8 mvn clean install

./create_test_cluster.py --debug --kind --operator spark hbase zookeeper hdfs


# Register absolute paths to pass to Ansible so the location of the role is irrelevant
# for the run
TESTDIR="$(pwd)/tests"
WORKDIR="$(pwd)/tests/_work"
PROJECTDIR="$(pwd)"

# Create dirs
mkdir -p tests/ansible/roles
mkdir -p "$WORKDIR"

# Install Ansible role if needed
pushd tests/ansible
ansible-galaxy role install -r requirements.yaml -p ./roles

# TODO: create pipenv in files for script thingy

# Funnel via JSON to ensure that values are escaped properly
echo '{}' | jq '{work_dir: $WORKDIR, test_dir: $TESTDIR, project_dir: $PROJECTDIR}' --arg WORKDIR "$WORKDIR" --arg TESTDIR "$TESTDIR" --arg PROJECTDIR "$PROJECTDIR" > "${WORKDIR}"/vars.json

# Run playbook to generate test scenarios
ansible-playbook playbook.yaml --extra-vars "@${WORKDIR}/vars.json"
popd

# Run tests
pushd tests/_work
kubectl kuttl test -v 3
popd

