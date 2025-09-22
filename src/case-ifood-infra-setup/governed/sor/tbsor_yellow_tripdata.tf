resource "aws_glue_catalog_table" "sor_yellow" {
  database_name = var.database_name
  name          = "tbsor_yellow_tripdata"
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
    location      = "s3://${var.bucket_name}/tbsor_yellow_tripdata/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
    compressed    = false
    number_of_buckets = -1

    ser_de_info {
      name = "parquet"
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
      type = "double"       
      comment = "Passengers"
    }

    columns {
      name = "trip_distance"           
      type = "double"    
      comment = "Miles" 
    }

    columns {
      name = "ratecodeid"
      type = "double"       
      comment = "Rate code" 
    }
  
    columns {
      name = "store_and_fwd_flag"      
      type = "string"    
      comment = "Y/N" 
    }

    columns {
      name = "pulocationid"            
      type = "int"       
      comment = "Pickup LocationID"
    }

    columns {
      name = "dolocationid"            
      type = "int"       
      comment = "Dropoff LocationID"
    }

    columns {
      name = "payment_type"            
      type = "int"       
      comment = "Payment type"
    }

    columns {
      name = "fare_amount"             
      type = "double"    
      comment = "Fare amount"
    }

    columns {
      name = "extra"     
      type = "double"    
      comment = "Extras"
    }

    columns {
      name = "mta_tax"   
      type = "double"    
      comment = "MTA tax"
    }

    columns {
      name = "tip_amount"
      type = "double"    
      comment = "Tip amount" 
    }

    columns {
      name = "tolls_amount"            
      type = "double"    
      comment = "Tolls amount"
    }

    columns {
      name = "improvement_surcharge"   
      type = "double"    
      comment = "Improvement surcharge"
    }
  
    columns {
      name = "total_amount"            
      type = "double"    
      comment = "Total amount"
    }

    columns {
      name = "congestion_surcharge"    
      type = "double"    
      comment = "Congestion surcharge" 
    }

    columns {
      name = "airport_fee"             
      type = "double"    
      comment = "Airport fee"
    }
  }
}
