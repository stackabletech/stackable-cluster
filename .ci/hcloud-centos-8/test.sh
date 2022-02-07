# the gradle-build.sh created a .jar file in the path $HOST_WORKSPACE/kuttl-test/tests/spark/minimalSpark/distribution/ on the jenkins machine
# $HOST_WORKSPACE/kuttl-test/tests/spark/minimalSpark/distribution/ gets mounted into the t2-driver docker container
# the t2-driver clones the stackable-cluster repo into the docker container. And thus, the .jar is not in the right place yet.
# This could be done better with the array wormhole pattern (see https://ro14nd.de/Docker-Wormhole-Pattern)
#mkdir ${REPO_DIR}/kuttl-test/tests/spark/minimalSpark/distribution
kubectl kuttl test
exit_code=$?
./operator-logs.sh spark > /target/spark-operator.log
exit $exit_code
