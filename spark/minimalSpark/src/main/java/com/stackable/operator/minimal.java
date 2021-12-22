package com.stackable.operator;


import org.apache.spark.sql.Dataset;
import org.apache.spark.sql.SaveMode;
import org.apache.spark.sql.SparkSession;

public class minimal {

    public static void main(String[] args) {

        String logFile = "/tmp/minimalSpark.txt";

        // create spark session
        SparkSession spark = SparkSession.builder().appName("minimal").getOrCreate();

        // read some file
        Dataset<String> logData = spark.read().textFile(logFile).cache();

        // print and save data
        logData.show(false);
        logData.write()
                .format("text")
                .mode(SaveMode.Overwrite)
                .save("/tmp/StackyMcStackfaceSaysHello/");

    }
}
