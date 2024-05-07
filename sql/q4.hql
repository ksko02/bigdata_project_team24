USE team24_projectdb;

DROP TABLE IF EXISTS q4_results;

CREATE EXTERNAL TABLE q4_results(
  age_group VARCHAR(15),
  low_risk INTEGER,
  moderate_risk INTEGER,
  high_risk INTEGER
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
location 'project/hive/warehouse/q4';

SET hive.resultset.use.unique.column.names = false;

INSERT INTO q4_results
SELECT age_group, 
CASE WHEN anomaly = 'low_risk' THEN 1 ELSE 0 END AS low_risk,
CASE WHEN anomaly = 'moderate_risk' THEN 1 ELSE 0 END AS moderate_risk,
CASE WHEN anomaly = 'high_risk' THEN 1 ELSE 0 END AS high_risk
FROM transactions_part_buck;

INSERT OVERWRITE DIRECTORY 'project/output/q4' 
ROW FORMAT DELIMITED FIELDS 
TERMINATED BY ',' 
SELECT * FROM q4_results;