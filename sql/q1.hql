USE team24_projectdb;

DROP TABLE IF EXISTS q1_results;

CREATE EXTERNAL TABLE q1_results(
  hour_of_day INTEGER,
  risk_score FLOAT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
location 'project/hive/warehouse/q1';

SET hive.resultset.use.unique.column.names = false;

INSERT INTO q1_results
SELECT hour_of_day, risk_score
FROM transactions_part_buck;

INSERT OVERWRITE DIRECTORY 'project/output/q1' 
ROW FORMAT DELIMITED FIELDS 
TERMINATED BY ',' 
SELECT * FROM q1_results;