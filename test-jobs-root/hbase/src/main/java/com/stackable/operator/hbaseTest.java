package com.stackable.operator;

import org.apache.commons.cli.*;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.hbase.HBaseConfiguration;
import org.apache.hadoop.hbase.MasterNotRunningException;
import org.apache.hadoop.hbase.TableName;
import org.apache.hadoop.hbase.client.*;
import org.apache.hadoop.hbase.util.Bytes;
import org.apache.log4j.LogManager;
import org.apache.log4j.Logger;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;


public class hbaseTest {
    private static final TableName TABLE_NAME = TableName.valueOf("stackable");
    private static final byte[] COLUMN_FAMILY_NAME = Bytes.toBytes("family");
    private static final byte[] COLUMN = Bytes.toBytes("open_source");
    private static final byte[] ROW_ID = Bytes.toBytes("row01");

    private static final String CMD_INPUT = "input";
    private static final String CMD_TARGET_TABLE = "targetTable";
    private static final String CMD_HBASE_SITE = "hbaseSite";
    private static final String CMD_CORE_SITE = "coreSite";
    private static final String CMD_HDFS_SITE = "hdfsSite";

    private static final Logger LOGGER = LogManager.getLogger(hbaseTest.class);

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
        //table.put();
    }

    public static void readData(final Path path, Configuration configuration) {
        try {

            FileSystem fs = FileSystem.get(configuration);
            BufferedReader br=new BufferedReader(new InputStreamReader(fs.open(path)));

            String line;
            line=br.readLine();
            while (line != null){
                System.out.println(line);
                line=br.readLine();
            }
          } catch (Exception e) {
            LOGGER.info("*** Error Message ***: " + e.getMessage());
            e.printStackTrace();
            }
    }

    public static void main(String[] args) throws IOException, ParseException {

        // parse input parameters
        final CommandLine commandLine = buildCommandLineParser(args);

        final String inputPath = String.valueOf(commandLine.getOptionValue(CMD_INPUT));
        final String targetTable = String.valueOf(commandLine.getOptionValue(CMD_TARGET_TABLE));
        final String hbaseSite = String.valueOf(commandLine.getOptionValue(CMD_HBASE_SITE));
        final String coreSite = String.valueOf(commandLine.getOptionValue(CMD_CORE_SITE));
        final String hdfsSite = String.valueOf(commandLine.getOptionValue(CMD_HDFS_SITE));

        LOGGER.info("*** inputPath ***: " + inputPath);
        LOGGER.info("*** targetTable ***: " + targetTable);
        LOGGER.info("*** hbaseSite ***: " + hbaseSite);
        LOGGER.info("*** coreSite ***: " + coreSite);
        LOGGER.info("*** hdfsSite ***: " + hdfsSite);

        Configuration config = HBaseConfiguration.create();
        config.addResource(new Path(hbaseSite));
        config.addResource(new Path(coreSite));
        config.addResource(new Path(hdfsSite));
        config.set("fs.AbstractFileSystem.hdfs.impl", "org.apache.hadoop.fs.Hdfs");
        config.writeXml(System.out);
        config.set("hbase.table.name", targetTable);

        try {
            HBaseAdmin.available(config);
        } catch (MasterNotRunningException e) {
            System.out.println("HBase is not running." + e.getMessage());
            return;
        }

        try (Connection connection = ConnectionFactory.createConnection(config); Admin admin = connection.getAdmin()) {
            Path path = new Path(inputPath);
            readData(path, config);
            createTable(admin);

            try(Table table = connection.getTable(TABLE_NAME)) {
                putRow(table);
            }
        }
    }

    static final CommandLine buildCommandLineParser(final String[] args) throws ParseException
    {
        final Options options = new Options();

        options.addOption(
                OptionBuilder
                        .hasArg()
                        .withLongOpt(CMD_INPUT)
                        .withArgName(CMD_INPUT)
                        .withDescription("HDFS input path.")
                        .isRequired()
                        .create());

        options.addOption(
                OptionBuilder
                        .hasArg()
                        .withLongOpt(CMD_CORE_SITE)
                        .withArgName(CMD_CORE_SITE)
                        .withDescription("Config file for hdfs connection.")
                        .isRequired()
                        .create());

        options.addOption(
                OptionBuilder
                        .hasArg()
                        .withLongOpt(CMD_HBASE_SITE)
                        .withArgName(CMD_HBASE_SITE)
                        .withDescription("Config file for zookeeper.")
                        .isRequired()
                        .create());

        options.addOption(
                OptionBuilder
                        .hasArg()
                        .withLongOpt(CMD_HDFS_SITE)
                        .withArgName(CMD_HDFS_SITE)
                        .withDescription("Config file for HDFS.")
                        .isRequired()
                        .create());

        options.addOption(
                OptionBuilder
                        .hasArg()
                        .withLongOpt(CMD_TARGET_TABLE)
                        .withArgName(CMD_TARGET_TABLE)
                        .withDescription("Target table name in hbase.")
                        .isRequired()
                        .create());

        final CommandLineParser parser = new BasicParser();

        return parser.parse(options, args);

    }
}