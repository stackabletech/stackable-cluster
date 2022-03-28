package com.stackable.operator;

import org.apache.spark.sql.Dataset;
import org.apache.spark.sql.SparkSession;

public class hbaseSpark {

    public static void main(String[] args) {
        String logFile = "/testdata.txt";

        // create spark session
        SparkSession spark = SparkSession.builder().appName("sparkHdfs").getOrCreate();

        // read some file
        Dataset<String> logData = spark.read().textFile(logFile).cache();

        // print and save data to hbase
        logData.show(false);
//        logData.write()
//                .format("text")
//                .mode(SaveMode.Overwrite)
//                .save("/tmp/processedTestdata.txt");

    }

}



