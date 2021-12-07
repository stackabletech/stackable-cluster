#!/bin/bash

set -x

# create array Kind Cluster
kind create cluster --config=kind/kindConfig.yaml

# add Helm repo
helm repo add stackable-dev https://repo.stackable.tech/repository/helm-dev

# install the spark operator
helm upgrade spark-operator stackable-dev/spark-operator --version="0.5.0-mr216" --install

# create a simple spark cluster
kubectl create -f kind/spark.yaml