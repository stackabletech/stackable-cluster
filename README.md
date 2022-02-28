#Stackable-cluster
A collection of scripts and configs to deploy and test the stackable-cluster

We want to create a complete Cluster which could serve a minimal production cluster.
While doing this, we want to make use of a many as possible components of stackable.
In the first step, we are going to create the cluster with t2 for each operator individually
In the second step, we will create a complete cluster where operators and location depend on each other. (see the layout in the appendix)

* spark
* kafka
* nifi
* hbase
* zookeeper
* superset
* druid
* trino
* hive
* hdfs

<img width="1526" alt="grafik" src="https://user-images.githubusercontent.com/9850483/141151184-b54c86ed-83fc-451e-ac66-50615066a1d3.png">

#Objectives

We are testing the individual Stackable Operators for functionality and working properply in a cluster setup.
The Stackable Operator can show their potential best when using the operators together in a cluster environment.
Therefore, we are doing functionality and cluster tests with KUTTL and KubeAssert

#Prerequisites for Tests with KUTTL and KubeAssert

Install the following components for local tests:
* [Docker](https://docs.docker.com/get-docker/)
* [Helm](https://helm.sh/docs/intro/install/)
* [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
* [KIND](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) 
* [Krew](https://krew.sigs.k8s.io/docs/user-guide/setup/install/)
* [KUTTL](https://kuttl.dev/docs/cli.html)
* [Gradle](https://gradle.org/install/)
* [(KubeAssert)](https://morningspace.github.io/kubeassert/docs/#/getting-started) currently saved in the project. Could be a krew plugin
  
#Where do I start?

1. Installing all the above tools
2. Execute the ```./start-local-tests.sh```