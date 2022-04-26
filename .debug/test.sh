set -x

#stackable -i ~/.ssh/id_rsa api-tunnel 6443

#git clone -b $GIT_BRANCH https://github.com/stackabletech/stackable-cluster.git

# the gradle-build.sh created a .jar file in the path $HOST_WORKSPACE/kuttl-test/tests/spark/minimalSpark/distribution/ on the jenkins machine
# $HOST_WORKSPACE/kuttl-test/tests/spark/minimalSpark/distribution/ gets mounted into the t2-driver docker container
# the t2-driver clones the stackable-cluster repo into the docker container. And thus, the .jar is not in the right place yet.
# This could be done better with the array wormhole pattern (see https://ro14nd.de/Docker-Wormhole-Pattern)
#mkdir ${REPO_DIR}/kuttl-test/tests/spark/minimalSpark/distribution

#cp /tmp/minimalSpark.jar ${REPO_DIR}/kuttl-test/tests/spark/minimalSpark/distribution

#(cd ${REPO_DIR}/.ci/debug && kubectl kuttl test)
#exit_code=$?
#./operator-logs.sh spark > /target/spark-operator.log
#exit $exit_code

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

