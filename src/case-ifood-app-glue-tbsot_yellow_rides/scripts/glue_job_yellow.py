import sys
import boto3
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.context import SparkContext
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.functions import col
from awsglue.transforms import ApplyMapping

# Parâmetros do job
args = getResolvedOptions(sys.argv, [
    "JOB_NAME",
    "source_db",
    "source_table",
    "dest_db",
    "dest_table",
    "partition_value"
])

source_db       = args["source_db"]
source_table    = args["source_table"]
dest_db         = args["dest_db"]
dest_table      = args["dest_table"]
partition_value = args["partition_value"]

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# Lê da tabela de origem (Catálogo Glue)
dyf_src = glueContext.create_dynamic_frame.from_catalog(
    database=source_db,
    table_name=source_table,
    push_down_predicate=f"dtref = {partition_value}"
)

dyf_forced = ApplyMapping.apply(
    frame=dyf_src,
    mappings=[
        ("VendorID", "int", "vendorid", "bigint"),
        ("tpep_pickup_datetime",  "timestamp", "tpep_pickup_datetime",  "timestamp"),
        ("tpep_dropoff_datetime", "timestamp", "tpep_dropoff_datetime", "timestamp"),
        ("passenger_count", "int", "passenger_count", "double"),
        ("total_amount", "double", "total_amount", "double"),
        ("dtref", "int", "dtref", "int"),
    ]
)

# Converte DynamicFrame -> DataFrame
df = dyf_src.toDF()

# Cast (se e somente se o catálogo já estiver com int)
df_select = df.select(
    col("vendorid").cast('bigint').alias('vendorid'),
    col("tpep_pickup_datetime"),
    col("tpep_dropoff_datetime"),
    col("passenger_count").cast('int').alias('passenger_count'),
    col("total_amount"),
    col("dtref")
)

# Removendo registros duplicados
df_dedup = df_select.dropDuplicates()

# DataFrame -> DynamicFrame
dyf_out = DynamicFrame.fromDF(df_dedup, glueContext, "dyf_out")

# Descobre o 'location' da tabela de destino via Glue (para escrever no caminho correto)
glue = boto3.client("glue")
table = glue.get_table(DatabaseName=dest_db, Name=dest_table)["Table"]
dest_loc = table["StorageDescriptor"]["Location"]

# Sinker: grava em S3 usando o location da tabela de destino e atualiza o Catálogo/partições
sink = glueContext.getSink(
    path=dest_loc,
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=['dtref'],
    enableUpdateCatalog=True
)

sink.setFormat("glueparquet")
sink.setCatalogInfo(
    catalogDatabase=dest_db,
    catalogTableName=dest_table
)

sink.writeFrame(dyf_out)

job.commit()
