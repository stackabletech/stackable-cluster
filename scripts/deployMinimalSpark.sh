#!/bin/bash

set -x

#get master pod name
export SPARK_MASTER_POD=$(kubectl get pods -o=name | grep master | sed "s/^.\{4\}//")
export SPARK_SLAVE_POD=$(kubectl get pods -o=name | grep slave | sed "s/^.\{4\}//")

#.jar needs to be distributed to pods
kubectl cp ~/Repo/stackable/stackable-cluster/spark/minimalSpark/build/libs/minimalSpark-all.jar $SPARK_SLAVE_POD:/tmp
kubectl cp ~/Repo/stackable/stackable-cluster/spark/minimalSpark/build/libs/minimalSpark-all.jar $SPARK_MASTER_POD:/tmp

#copy start script to master
kubectl cp ~/Repo/stackable/stackable-cluster/scripts/spark-submit.sh $SPARK_MASTER_POD:/tmp

#copy resource file to master
kubectl cp ~/Repo/stackable/stackable-cluster/spark/minimalSpark/build/resources/main/minimalSpark.txt $SPARK_MASTER_POD:/tmp
kubectl cp ~/Repo/stackable/stackable-cluster/spark/minimalSpark/build/resources/main/minimalSpark.txt $SPARK_SLAVE_POD:/tmp

#enter pod and start bash
kubectl exec --stdin --tty $SPARK_MASTER_POD -- /bin/bash "chmod 700 /tmp/spark-submit.sh"

#enter pod
kubectl exec --stdin --tty $SPARK_MASTER_POD -- /bin/bash
