#!/bin/bash

# Clean old data
rm data/*
rm output/*

# Download dataset
url="https://disk.yandex.ru/d/xYqRP_WhIbowPw"

wget "$(yadisk-direct $url)" -O data/metaverse_transactions_dataset.csv

# Build PostgreSQL database
python3 scripts/build_projectdb.py

password=$(head -n 1 secrets/.psql.pass)

# Import data to HDFS via SQOOP 
sqoop import-all-tables --connect jdbc:postgresql://hadoop-04.uni.innopolis.ru/team24_projectdb --username team24 --password $password --compression-codec=snappy --compress --as-avrodatafile --warehouse-dir=project/warehouse --m 1 --outdir output
