'''
Python script for stage 3 (ml module)
'''

import os
import math
from pyspark.sql import SparkSession
from pyspark.ml import Pipeline
from pyspark.ml.feature import OneHotEncoder, StringIndexer, VectorAssembler
from pyspark.ml import Transformer
from pyspark.ml.util import DefaultParamsReadable, DefaultParamsWritable
from pyspark.sql import DataFrame
from pyspark.sql.types import FloatType
import pyspark.sql.functions as F
from pyspark.ml.linalg import Vectors, VectorUDT
from pyspark.ml.regression import GBTRegressor, RandomForestRegressor
from pyspark.ml.evaluation import RegressionEvaluator
from pyspark.ml.tuning import ParamGridBuilder, CrossValidator

TEAM = 'team24'

# location of Hive database in HDFS
WAREHOUSE = "project/hive/warehouse"

spark = SparkSession.builder\
        .appName(f"{TEAM} - spark ML")\
        .master("yarn")\
        .config("hive.metastore.uris",
                "thrift://hadoop-02.uni.innopolis.ru:9883")\
        .config("spark.sql.warehouse.dir", WAREHOUSE)\
        .config("spark.sql.avro.compression.codec", "snappy")\
        .enableHiveSupport()\
        .getOrCreate()


transactions = spark.read.format("avro")\
                    .table('team24_projectdb.transactions_part_buck')

transactions = transactions.dropna()


def cos_sin_time(list_time):
    '''
    Convert each datetime components into sin and cos components
    '''
    output = []
    parm = [0, 12, 31, 24, 60, 60]

    for i, item in enumerate(list_time):
        if i == 0:
            output.append(float(item))
        else:
            cos = math.cos((2*item*math.pi)/parm[i])
            sin = math.sin((2*item*math.pi)/parm[i])
            output.append(cos)
            output.append(sin)
    return Vectors.dense(output)


class CustomTransformer(Transformer, DefaultParamsReadable,
                        DefaultParamsWritable):

    """
    Class of pyspark transformer for datetime data type
    """

    def _transform(self, dataset: DataFrame):
        input_col = dataset['time']
        transform_udf = F.udf(lambda x: cos_sin_time(
                            list(map(int, ':'.join('-'.join(str(x).split())
                                                   .split('-'))
                                     .split(':')))
                        ), VectorUDT())
        return dataset.withColumn("sin_cos_time", transform_udf(input_col))


categorical_features = ['transaction_type', 'location_region',
                        'purchase_pattern']
numerical_features = ['amount', 'login_frequency', 'session_duration',
                      'ip_prefix']

# Convert from string to float type column 'ip_prefix'
transactions = transactions.withColumn('ip_prefix', F.col('ip_prefix')
                                       .cast(FloatType()))

# Create string indexer for categorical features
indexers = [StringIndexer(inputCol=col, outputCol=col+"_index",
                          handleInvalid="skip") for col in categorical_features]

# One-hot encode categorical features
onehot_encoders = [OneHotEncoder(inputCol=col+"_index",
                                 outputCol=col+"_onehot")
                   for col in categorical_features]

custom_transformer = CustomTransformer()

# Assemble all features into a single vector
assembler = VectorAssembler(
    inputCols=[col+"_onehot" for col in categorical_features]
    + numerical_features + ["sin_cos_time"] + ['risk_score'],
    outputCol="features")

# Create pipeline
pipeline = Pipeline(stages=indexers + onehot_encoders + [custom_transformer]
                    + [assembler])

# Fit pipeline to data
pipeline_model = pipeline.fit(transactions)

# Transform data using the fitted pipeline
transformed_data = pipeline_model.transform(transactions)

df = transformed_data['features', 'risk_score']

df.cache()

# Split the data into training and testing sets
train_data, test_data = df.randomSplit([0.7, 0.3], seed=42)


def run(command):
    '''
    Function to run command in terminal
    '''
    return os.popen(command).read()


train_data.select("features", "risk_score")\
    .coalesce(1)\
    .write\
    .mode("overwrite")\
    .format("json")\
    .save("project/data/train")

test_data.select("features", "risk_score")\
    .coalesce(1)\
    .write\
    .mode("overwrite")\
    .format("json")\
    .save("project/data/test")

run("hdfs dfs -cat project/data/train/*.json > data/train.json")
run("hdfs dfs -cat project/data/test/*.json > data/test.json")

grid = ParamGridBuilder()

evaluator_rmse = RegressionEvaluator(labelCol="risk_score",
                                     predictionCol="prediction",
                                     metricName="rmse")

evaluator_r2 = RegressionEvaluator(labelCol="risk_score",
                                   predictionCol="prediction", metricName="r2")

# Model 1 (GBTRegressor)
gbt = GBTRegressor(featuresCol="features", labelCol="risk_score")
model_gbt = gbt.fit(train_data)

predictions_gbt = model_gbt.transform(test_data)

rmse_gbt = evaluator_rmse.evaluate(predictions_gbt)
r2_gbt = evaluator_r2.evaluate(predictions_gbt)

param_grid_gbt = grid.addGrid(model_gbt.maxDepth, [2, 4, 6]) \
    .addGrid(model_gbt.maxIter, [10, 20, 30]) \
    .build()

cv_gbt = CrossValidator(estimator=gbt,
                        estimatorParamMaps=param_grid_gbt,
                        evaluator=evaluator_rmse,
                        parallelism=5,
                        numFolds=3)

cvModel_gbt = cv_gbt.fit(train_data)

model_best_gbt = cvModel_gbt.bestModel

model_best_gbt.write().overwrite().save("project/models/model1")

run("hdfs dfs -get project/models/model1 models/model1")

predictions_best_gbt = model_best_gbt.transform(test_data)

predictions_best_gbt.select("risk_score", "prediction")\
    .coalesce(1)\
    .write\
    .mode("overwrite")\
    .format("csv")\
    .option("sep", ",")\
    .option("header", "true")\
    .save("project/output/model1_predictions.csv")

run("hdfs dfs -cat project/output/model1_predictions.csv/*.csv >\
    output/model1_predictions.csv")

rmse_best_gbt = evaluator_rmse.evaluate(predictions_best_gbt)
r2_best_gbt = evaluator_r2.evaluate(predictions_best_gbt)

# Model 2 (RandomForestRegressor)
rf = RandomForestRegressor(featuresCol="features", labelCol="risk_score")

model_rf = rf.fit(train_data)

predictions_rf = model_rf.transform(test_data)

rmse_rf = evaluator_rmse.evaluate(predictions_rf)
r2_rf = evaluator_r2.evaluate(predictions_rf)

param_grid_rf = grid.addGrid(model_rf.maxDepth, [2, 4, 6]) \
    .addGrid(model_rf.numTrees, [10, 20, 30]) \
    .build()

cv_rf = CrossValidator(estimator=rf,
                       estimatorParamMaps=param_grid_rf,
                       evaluator=evaluator_rmse,
                       parallelism=5,
                       numFolds=3)

cvModel_rf = cv_rf.fit(train_data)

model_best_rf = cvModel_rf.bestModel

model_best_rf.write().overwrite().save("project/models/model2")

run("hdfs dfs -get project/models/model2 models/model2")

predictions_best_rf = model_best_rf.transform(test_data)

predictions_best_rf.select("risk_score", "prediction")\
    .coalesce(1)\
    .write\
    .mode("overwrite")\
    .format("csv")\
    .option("sep", ",")\
    .option("header", "true")\
    .save("project/output/model2_predictions.csv")

run("hdfs dfs -cat project/output/model2_predictions.csv/*.csv >\
    output/model2_predictions.csv")

rmse_best_rf = evaluator_rmse.evaluate(predictions_best_rf)
r2_best_rf = evaluator_r2.evaluate(predictions_best_rf)

# Compare the best models
models = [[str(model_best_gbt), rmse_best_gbt, r2_best_gbt],
          [str(model_best_rf), rmse_best_rf, r2_best_rf]]

comp_models = spark.createDataFrame(models, ["model", "RMSE", "R2"])

comp_models.coalesce(1)\
    .write\
    .mode("overwrite")\
    .format("csv")\
    .option("sep", ",")\
    .option("header", "true")\
    .save("project/output/evaluation.csv")

run("hdfs dfs -cat project/output/evaluation.csv/*.csv >\
    output/evaluation.csv")

# Stop spark
spark.stop()
