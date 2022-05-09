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
* [Maven](https://maven.apache.org/install.html)
* [(KubeAssert)](https://morningspace.github.io/kubeassert/docs/#/getting-started) currently saved in the project. Could be a krew plugin
  
#Where do I start?

1. Installing all the above tools
2. Execute the ```./start-local-tests.sh```

#How to debug CI Pipeline?

The CI Pipeline depends on T2 and runs on Jenkins.
For debugging purposes we use the directory ```.interactive```
1. Set your T2_Token created by Nikolaus ```export T2_TOKEN=<YOUR_TOKEN>```
2. Go to ```.interactive``` and run ```.startup.sh```
3. Open a new terminal session and list your running docker containers with ```docker ps```
4. Log into you docker container with ```docker exec -it <YOUR_CONTAINER_NAME> bash```
5. In case you lose your connection you can restore it with ```stackable -i .cluster/key api-tunnel 6443```

Now you are in a container which is next to the created k8 cluster defined in ```.interactive/cluster.yaml```
From here you can execute all your kubectl commands. In the container you can find the ```.kubeconfig``` of the k8s cluster you are connected with.   

To tear down the k8s cluster execute the following ```touch /cluster_lock```    