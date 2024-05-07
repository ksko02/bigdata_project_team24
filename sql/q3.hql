USE team24_projectdb;

DROP TABLE IF EXISTS q3_results;

CREATE EXTERNAL TABLE q3_results(
  transaction_type VARCHAR(10),
  risk_score FLOAT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
location 'project/hive/warehouse/q3';

SET hive.resultset.use.unique.column.names = false;

INSERT INTO q3_results
SELECT transaction_type, risk_score
FROM transactions_part_buck;

INSERT OVERWRITE DIRECTORY 'project/output/q3' 
ROW FORMAT DELIMITED FIELDS 
TERMINATED BY ',' 
SELECT * FROM q3_results;