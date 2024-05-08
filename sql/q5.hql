USE team24_projectdb;

DROP TABLE IF EXISTS q5_results;

CREATE EXTERNAL TABLE q5_results(
  anomaly VARCHAR(15),
  amount FLOAT 
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
location 'project/hive/warehouse/q5';

SET hive.resultset.use.unique.column.names = false;

INSERT INTO q5_results
SELECT anomaly, amount
FROM transactions_part_buck;

INSERT OVERWRITE DIRECTORY 'project/output/q5' 
ROW FORMAT DELIMITED FIELDS 
TERMINATED BY ',' 
SELECT * FROM q5_results;