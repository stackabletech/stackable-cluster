# stackable-cluster
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