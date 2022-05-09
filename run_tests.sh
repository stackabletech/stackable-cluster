#!/bin/bash

set -x

# Register absolute paths to pass to Ansible so the location of the role is irrelevant
# for the run
TESTDIR="$(pwd)/tests"
WORKDIR="$(pwd)/tests/_work"
PROJECTDIR="$(pwd)"

# Create dirs
mkdir -p tests/ansible/roles
mkdir -p "$WORKDIR"
mkdir -p "$WORKDIR/test-jobs-root"

# Install Ansible role if needed
pushd tests/ansible
ansible-galaxy role install -r requirements.yaml -p ./roles

# TODO: create pipenv in files for script thingy

# Funnel via JSON to ensure that values are escaped properly
echo '{}' | jq '{work_dir: $WORKDIR, test_dir: $TESTDIR, project_dir: $PROJECTDIR}' --arg WORKDIR "$WORKDIR" --arg TESTDIR "$TESTDIR" --arg PROJECTDIR "$PROJECTDIR" > "${WORKDIR}"/vars.json

# Run playbook to generate test scenarios
ansible-playbook playbook.yaml --extra-vars "@${WORKDIR}/vars.json"
popd

# copy resources to the _work dir.
# This is the first but not final solution. May be create zip file and then move.
mkdir -p "$WORKDIR/test-jobs-root/spark-standalone"
cp test-jobs-root/spark-standalone/spark-submit.sh test-jobs-root/spark-standalone/sparkPreparation.sh test-jobs-root/spark-standalone/spark-standalone-1.0.jar test-jobs-root/spark-standalone/src/main/resources/minimalSpark.csv "$WORKDIR/test-jobs-root/spark-standalone"
mkdir -p "$WORKDIR/test-jobs-root/spark-hdfs"
cp test-jobs-root/spark-hdfs/spark-hdfs-submit.sh test-jobs-root/spark-hdfs/sparkPreparation.sh test-jobs-root/spark-hdfs/spark-hdfs-1.0.jar "$WORKDIR/test-jobs-root/spark-hdfs"
mkdir -p "$WORKDIR/test-jobs-root/hbase"
cp test-jobs-root/hbase/hbasePreparation.sh test-jobs-root/hbase/hbase-1.0.jar "$WORKDIR/test-jobs-root/hbase"

# copy assert files to _work
cp -R "$PROJECTDIR/kubeassert" "$WORKDIR"



# Run tests
pushd tests/_work
kubectl kuttl test -v 3
popd

