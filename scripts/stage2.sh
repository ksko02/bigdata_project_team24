#!/bin/bash

# Clean old data
hdfs dfs -rm -r -skipTrash /user/team24/project/hive
hdfs dfs -rm -r -skipTrash /user/team24/project/output


password=$(head -n 1 secrets/.hive.pass)

# Build optimized Hive tables 
beeline -u jdbc:hive2://hadoop-03.uni.innopolis.ru:10001 -n team24 -p $password -f sql/db.hql > output/hive_results.txt 2> /dev/null

# Create q1
beeline -u jdbc:hive2://hadoop-03.uni.innopolis.ru:10001 -n team24 -p $password -f sql/q1.hql
echo "hour_of_day,location_region,risk_score" > output/q1.csv
hdfs dfs -cat project/output/q1/* >> output/q1.csv

# Create q2
beeline -u jdbc:hive2://hadoop-03.uni.innopolis.ru:10001 -n team24 -p $password -f sql/q2.hql
echo "session_duration,risk_score" > output/q2.csv
hdfs dfs -cat project/output/q2/* >> output/q2.csv

# Create q3
beeline -u jdbc:hive2://hadoop-03.uni.innopolis.ru:10001 -n team24 -p $password -f sql/q3.hql
echo "transaction_type,risk_score" > output/q3.csv
hdfs dfs -cat project/output/q3/* >> output/q3.csv

# Create q4
beeline -u jdbc:hive2://hadoop-03.uni.innopolis.ru:10001 -n team24 -p $password -f sql/q4.hql
echo "age_group,low_risk,moderate_risk,high_risk" > output/q4.csv
hdfs dfs -cat project/output/q4/* >> output/q4.csv

# Create q5
beeline -u jdbc:hive2://hadoop-03.uni.innopolis.ru:10001 -n team24 -p $password -f sql/q5.hql
echo "amount,risk_score" > output/q5.csv
hdfs dfs -cat project/output/q5/* >> output/q5.csv