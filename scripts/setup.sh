#!/bin/bash

set -x

kind create cluster --config=kind/kindConfig.yaml

helm repo add stackable-dev https://repo.stackable.tech/repository/helm-dev

#helm repo ls

helm upgrade spark-operator stackable-dev/spark-operator --version="0.5.0-mr216" --install

kubectl create -f kind/spark.yaml