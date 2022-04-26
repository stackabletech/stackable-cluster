package com.stackable.operator;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.hbase.HBaseConfiguration;
import org.apache.hadoop.hbase.TableName;
import org.apache.hadoop.hbase.client.*;
import org.apache.hadoop.hbase.util.Bytes;

import java.io.IOException;


public class hbaseTest {
    private static final TableName TABLE_NAME = TableName.valueOf("stackable");
    private static final byte[] COLUMN_FAMILY_NAME = Bytes.toBytes("family");
    private static final byte[] COLUMN = Bytes.toBytes("open_source");
    private static final byte[] ROW_ID = Bytes.toBytes("row01");

    public static void createTable(final Admin admin) throws IOException {
        if(!admin.tableExists(TABLE_NAME)) {
            TableDescriptor desc = TableDescriptorBuilder.newBuilder(TABLE_NAME)
                    .setColumnFamily(ColumnFamilyDescriptorBuilder.of(COLUMN_FAMILY_NAME))
                    .build();
            admin.createTable(desc);
        }
    }

    public static void putRow(final Table table) throws IOException {
        table.put(new Put(ROW_ID).addColumn(COLUMN_FAMILY_NAME, COLUMN, Bytes.toBytes("Hello Stackable Data Platform")));
    }

    public static void main(String[] args) throws IOException {
        Configuration config = HBaseConfiguration.create();

        try (Connection connection = ConnectionFactory.createConnection(config); Admin admin = connection.getAdmin()) {
            createTable(admin);

            try(Table table = connection.getTable(TABLE_NAME)) {
                putRow(table);
            }
        }
    }
}