package com.stackable.operator;

import org.apache.spark.sql.Dataset;
import org.apache.spark.sql.Row;
import org.apache.spark.sql.SaveMode;
import org.apache.spark.sql.SparkSession;

public class minimal {

    public static void main(String[] args) {

        // create spark session
        SparkSession spark = SparkSession.builder().appName("minimal").getOrCreate();

        // read some file
        Dataset<Row> logData = spark.read().option("header", "False").option("delimiter", ";").csv("/tmp/minimalSpark.csv").cache();

        // print and save data
        logData.show(false);
        logData.coalesce(1).write()
                .mode(SaveMode.Overwrite)
                .csv("/tmp/stacky");

        spark.stop();
    }
}
