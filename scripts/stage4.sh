#!/bin/bash

password=$(head -n 1 secrets/.hive.pass)

beeline -u jdbc:hive2://hadoop-03.uni.innopolis.ru:10001 -n team24 -p $password -f sql/pda_results.hql