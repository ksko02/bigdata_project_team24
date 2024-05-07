USE team24_projectdb;

DROP TABLE IF EXISTS q2_results;

CREATE EXTERNAL TABLE q2_results(
  session_duration INTEGER,
  risk_score FLOAT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
location 'project/hive/warehouse/q2';

SET hive.resultset.use.unique.column.names = false;

INSERT INTO q2_results
SELECT session_duration, risk_score
FROM transactions_part_buck;

INSERT OVERWRITE DIRECTORY 'project/output/q2' 
ROW FORMAT DELIMITED FIELDS 
TERMINATED BY ',' 
SELECT * FROM q2_results;