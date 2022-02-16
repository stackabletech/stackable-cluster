kubectl kuttl test
exit_code=$?
./operator-logs.sh spark > /target/spark-operator.log
exit $exit_code
