#!/bin/bash

set -x

#TODO create check if KIND cluster already exists or needs to be created.
kind create cluster --config=kind/kindConfig.yaml

#TODO check if neccessary operator is installed + if repo is added
#helm repo add stackable-dev https://repo.stackable.tech/repository/helm-dev
helm upgrade spark-operator stackable-dev/spark-operator --version="0.5.0-mr216" --install

#get master pod name
export SPARK_MASTER_POD=$(kubectl get pods -o=name | grep master | sed "s/^.\{4\}//")
export SPARK_SLAVE_POD=$(kubectl get pods -o=name | grep slave | sed "s/^.\{4\}//")

#.jar needs to be distributed to pods
kubectl cp ~/Repo/stackable/stackable-cluster/spark/minimalSpark/build/libs/minimalSpark.jar $SPARK_SLAVE_POD:/tmp
kubectl cp ~/Repo/stackable/stackable-cluster/spark/minimalSpark/build/libs/minimalSpark.jar $SPARK_MASTER_POD:/tmp

#copy start script to master
kubectl cp ~/Repo/stackable/stackable-cluster/scripts/spark-submit.sh $SPARK_MASTER_POD:/tmp

#copy resource file to master
kubectl cp ~/Repo/stackable/stackable-cluster/spark/minimalSpark/build/resources/main/minimalSpark.txt $SPARK_MASTER_POD:/tmp
kubectl cp ~/Repo/stackable/stackable-cluster/spark/minimalSpark/build/resources/main/minimalSpark.txt $SPARK_SLAVE_POD:/tmp

#make submit executable
kubectl exec --stdin --tty $SPARK_MASTER_POD -- /bin/bash -c "chmod 700 /tmp/spark-submit.sh"

#enter pod
kubectl exec --stdin --tty $SPARK_MASTER_POD -- /bin/bash
