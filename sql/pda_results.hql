USE team24_projectdb;

DROP TABLE IF EXISTS evaluation;
CREATE EXTERNAL TABLE evaluation (
    model STRING, 
    RMSE FLOAT, 
    R2 FLOAT
) 
row format SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
STORED AS TEXTFILE
LOCATION 'project/output/evaluation.csv'
TBLPROPERTIES ("skip.header.line.count" = "1");

DROP TABLE IF EXISTS model1_predictions;
CREATE EXTERNAL TABLE model1_predictions(
    label FLOAT,
    prediction FLOAT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION 'project/output/model1_predictions.csv'
TBLPROPERTIES ("skip.header.line.count" = "1");


DROP TABLE IF EXISTS model2_predictions;
CREATE EXTERNAL TABLE model2_predictions(
    label FLOAT,
    prediction FLOAT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION 'project/output/model2_predictions.csv'
TBLPROPERTIES ("skip.header.line.count" = "1");