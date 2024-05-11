#!/bin/bash

#Clean old data
hdfs dfs -rm -r -skipTrash /user/team24/project/data
hdfs dfs -rm -r -skipTrash /user/team24/project/output/*_predictions.csv
hdfs dfs -rm -r -skipTrash /user/team24/project/output/evaluation.csv
hdfs dfs -rm -r -skipTrash /user/team24/project/models

rm models/*
rm data/*.json
rm output/*_predictions.csv
rm output/evaluation.csv

spark-submit --master yarn scripts/model.py