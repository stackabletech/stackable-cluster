package com.stackable.operator;


import org.apache.spark.sql.Dataset;
import org.apache.spark.sql.SparkSession;

public class minimal {

    public static void main(String[] args) {
        String logFile = "/tmp/minimalSpark.txt";
        SparkSession spark = SparkSession.builder().appName("minimal").getOrCreate();
        //JavaSparkContext sparkContext = new JavaSparkContext(conf);
        Dataset<String> logData = spark.read().textFile(logFile).cache();

        logData.show(false);
        logData.write().save("/tmp/StackyMcStackfaceSaysHello.txt");

    }
}
