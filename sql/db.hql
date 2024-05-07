SET hive.exec.dynamic.partition.mode = nonstrict;
SET hive.exec.dynamic.partition = true;
SET hive.enforce.bucketing = true;

-- Drop the databases if exists
DROP DATABASE IF EXISTS team24_projectdb CASCADE;

-- Create a database and access it
CREATE DATABASE team24_projectdb LOCATION "project/hive/warehouse";
USE team24_projectdb;

-- Create transactions table
CREATE EXTERNAL TABLE transactions STORED AS AVRO LOCATION 'project/warehouse/transactions' TBLPROPERTIES ('avro.schema.url'='project/warehouse/avsc/transactions.avsc');

-- Checking the content of table
SELECT * FROM transactions LIMIT 5;

-- Create external, partitioned and bucketing Hive table
CREATE EXTERNAL TABLE transactions_part_buck(
	`time` TIMESTAMP,
	hour_of_day INT,
	sending_address VARCHAR(50),
	receiving_address VARCHAR(50),
	amount FLOAT,
	location_region VARCHAR(15),
	ip_prefix VARCHAR(7),
	login_frequency INT,
	session_duration INT,
	purchase_pattern VARCHAR(10),
	age_group VARCHAR(15),
	risk_score FLOAT,
	anomaly VARCHAR(15)
)
PARTITIONED BY (transaction_type VARCHAR(10))
CLUSTERED BY (age_group) into 5 buckets 
STORED AS AVRO 
LOCATION 'project/hive/warehouse/transactions_part_buck' 
TBLPROPERTIES ('AVRO.COMPRESS'='SNAPPY');

-- Insert data from unpartitioned table
INSERT INTO transactions_part_buck
PARTITION (
    transaction_type
)
SELECT `time`, hour_of_day, sending_address, receiving_address,
    amount, location_region, ip_prefix, login_frequency,
    session_duration, purchase_pattern, age_group,
    risk_score, anomaly, transaction_type
FROM transactions;

-- Checking the content of table
SELECT * FROM transactions_part_buck WHERE transaction_type = 'sale' LIMIT 5;

DROP TABLE transactions;