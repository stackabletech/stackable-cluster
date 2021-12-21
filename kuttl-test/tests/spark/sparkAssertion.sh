#!/bin/bash

set -x

export SPARK_MASTER_POD=$(kubectl get pods -o=name | grep master | sed "s/^.\{4\}//")
echo $SPARK_MASTER_POD

export SPARK_SLAVE_POD=$(kubectl get pods -o=name | grep slave | sed "s/^.\{4\}//")
echo $SPARK_SLAVE_POD

#.jar needs to be distributed to pods
kubectl cp $HOME/Repo/stackable/stackable-cluster/spark/minimalSpark/build/libs/minimalSpark.jar $SPARK_MASTER_POD:/tmp
kubectl cp $HOME/Repo/stackable/stackable-cluster/spark/minimalSpark/build/libs/minimalSpark.jar $SPARK_SLAVE_POD:/tmp

#copy start script to master
kubectl cp $HOME/Repo/stackable/stackable-cluster/scripts/spark-submit.sh $SPARK_MASTER_POD:/tmp

#copy resource file to master
kubectl cp $HOME/Repo/stackable/stackable-cluster/spark/minimalSpark/build/resources/main/minimalSpark.txt $SPARK_MASTER_POD:/tmp
kubectl cp $HOME/Repo/stackable/stackable-cluster/spark/minimalSpark/build/resources/main/minimalSpark.txt $SPARK_SLAVE_POD:/tmp

#make submit executable
kubectl exec --stdin $SPARK_MASTER_POD -- /bin/bash -c "chmod 700 /tmp/spark-submit.sh"
kubectl exec $SPARK_MASTER_POD -- /bin/bash -x -v -c /tmp/spark-submit.sh


echo $SPARK_MASTER_POD
echo $SPARK_SLAVE_POD

#kubectl assert exist-enhanced deployment ${SPARK_MASTER_POD} -n $NAMESPACE --field-selector status.readyReplicas=1
#kubectl assert exist-enhanced deployment spark-operator-deployment -n $NAMESPACE --field-selector status.readyReplicas=1