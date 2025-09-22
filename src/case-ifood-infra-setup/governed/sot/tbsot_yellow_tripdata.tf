resource "aws_glue_catalog_table" "tbsot_yellow_rides" {
  database_name = var.database_name
  name          = "tbsot_yellow_rides"
  table_type    = "EXTERNAL_TABLE"

  parameters    = {
    classification = "parquet"
    EXTERNAL = "TRUE" 
  }

  partition_keys {
    name    = "dtref"
    type    = "int"
    comment = "Data de referência (YYYYMM)"
  }

  storage_descriptor {
    location      = "s3://${var.bucket_name}/tbsot_yellow_rides/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
    compressed    = false
    number_of_buckets = -1

    ser_de_info {
      name                  = "parquet"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
      parameters = {
        "parquet.compress" = "SNAPPY"
      }
    }

    columns {
      name = "vendorid"                
      type = "bigint"       
      comment = "Vendor ID" 
    }

    columns {
      name = "tpep_pickup_datetime"    
      type = "timestamp" 
      comment = "Pickup timestamp" 
    }

    columns {
      name = "tpep_dropoff_datetime"   
      type = "timestamp" 
      comment = "Dropoff timestamp" 
    }

    columns {
      name = "passenger_count"         
      type = "int"       
      comment = "Passengers"
    }

    columns {
      name = "total_amount"            
      type = "double"    
      comment = "Total amount"
    }
  }
}
