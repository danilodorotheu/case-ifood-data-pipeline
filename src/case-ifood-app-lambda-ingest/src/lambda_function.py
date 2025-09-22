import json
import os
import re
from urllib.parse import urlparse
import boto3
import botocore

s3 = boto3.client("s3")
glue = boto3.client("glue")


def _parse_s3_uri(uri: str):
    p = urlparse(uri)
    if p.scheme != "s3":
        raise ValueError(f"Location inválido (esperado s3://...): {uri}")
    return p.netloc, p.path.lstrip("/")


def _extract_partition_value_from_filename(filename: str) -> str:
    """
    Extrai 'YYYYMM' a partir de um 'YYYY-MM' presente no nome do arquivo.
    Ex.: yellow_tripdata_2023-01.parquet -> 202301
    """
    m = re.search(r"(\d{4})-(\d{2})", filename)
    if not m:
        raise ValueError("Não foi possível extrair a partição (YYYY-MM) do nome do arquivo.")
    return f"{m.group(1)}{m.group(2)}"


def _split_key(key: str):
    """
    Divide 'prefix/filename.ext' em ('prefix', 'filename.ext').
    Se não houver '/', prefixo = "".
    """
    parts = key.split("/")
    filename = parts[-1]
    prefix = "/".join(parts[:-1])
    return prefix, filename


def _eventbridge_s3_extract(event: dict):
    """
    Extrai bucket e key de um evento EventBridge (S3 Object Created).
    Espera campos em event['detail']['bucket']['name'] e event['detail']['object']['key'].
    """
    try:
        bucket = event["detail"]["bucket"]["name"]
        key = event["detail"]["object"]["key"]
        return bucket, key
    except Exception:
        return None, None


def lambda_handler(event, context):
    """
    Suporta dois formatos de entrada:

    A) EventBridge (S3 Object Created):
       {
         "version": "...",
         "detail-type": "Object Created",
         "source": "aws.s3",
         "detail": { "bucket": {"name": "..."},
                     "object": {"key": "yellow_tripdata/.../arquivo_2023-01.parquet"} }
       }
       + variáveis fixas em env ou via transformer (dest_db, dest_table, partition_col)

    B) Chamada direta (CLI/Lambda Invoke):
       {
         "src_bucket": "...",
         "src_key": "yellow_tripdata/arquivo_2023-01.parquet",
         "dest_db": "meu_db",
         "dest_table": "minha_tabela",
         "partition_col": "dtref"
       }
    """

    # 1) Tenta extrair do EventBridge, senão usa chamada direta
    src_bucket, src_key = _eventbridge_s3_extract(event)
    if not src_bucket or not src_key:
        src_bucket = (event or {}).get("src_bucket")
        src_key = (event or {}).get("src_key")

    # parâmetros obrigatórios de destino
    dest_db = (event or {}).get("dest_db") or os.getenv("DEST_DB")
    dest_table = (event or {}).get("dest_table") or os.getenv("DEST_TABLE")
    partition_col = (event or {}).get("partition_col") or os.getenv("PARTITION_COL", "dtref")

    # validação
    missing = [k for k, v in {
        "src_bucket": src_bucket,
        "src_key": src_key,
        "dest_db": dest_db,
        "dest_table": dest_table,
        "partition_col": partition_col
    }.items() if not v]
    if missing:
        return {"statusCode": 400, "body": f"Campos obrigatórios ausentes: {', '.join(missing)}"}

    # 2) Se necessário, permita overrides via campos legados (src_prefix/src_filename)
    src_prefix = (event or {}).get("src_prefix")
    src_filename = (event or {}).get("src_filename")
    if not (src_prefix and src_filename):
        sp, sf = _split_key(src_key)
        src_prefix = src_prefix or sp
        src_filename = src_filename or sf

    try:
        # 3) Calcula partição a partir do nome do arquivo
        part_value = _extract_partition_value_from_filename(src_filename)

        # 4) Busca a tabela no Glue para descobrir o location
        table = glue.get_table(DatabaseName=dest_db, Name=dest_table)["Table"]
        table_sd = table["StorageDescriptor"]
        table_loc = table_sd.get("Location")
        if not table_loc:
            raise ValueError("Tabela Glue não possui 'StorageDescriptor.Location'.")

        dest_bucket, dest_prefix = _parse_s3_uri(table_loc)
        dest_part_prefix = f"{dest_prefix.rstrip('/')}/{partition_col}={part_value}/"
        dest_key = f"{dest_part_prefix}{src_filename}"

        # 5) Copia o objeto para o path da partição
        s3.copy_object(
            CopySource={"Bucket": src_bucket, "Key": f"{src_prefix+'/'+src_filename if src_prefix else src_filename}"},
            Bucket=dest_bucket,
            Key=dest_key
        )

        # 6) Cria/atualiza partição no Glue
        partition_input = {
            "Values": [part_value],
            "StorageDescriptor": {
                "Columns": table_sd.get("Columns", []),
                "Location": f"s3://{dest_bucket}/{dest_part_prefix}",
                "InputFormat": table_sd.get("InputFormat"),
                "OutputFormat": table_sd.get("OutputFormat"),
                "SerdeInfo": table_sd.get("SerdeInfo", {}),
                "Compressed": table_sd.get("Compressed", False),
                "NumberOfBuckets": table_sd.get("NumberOfBuckets", -1),
                "BucketColumns": table_sd.get("BucketColumns", []),
                "Parameters": table_sd.get("Parameters", {}),
                "SkewedInfo": table_sd.get("SkewedInfo", {}),
                "SortColumns": table_sd.get("SortColumns", [])
            }
        }

        print(f"informacoes da tabela: {partition_input}")

        try:
            glue.create_partition(
                DatabaseName=dest_db,
                TableName=dest_table,
                PartitionInput=partition_input
            )
            action = "created"
        except glue.exceptions.AlreadyExistsException:
            glue.update_partition(
                DatabaseName=dest_db,
                TableName=dest_table,
                PartitionValueList=[part_value],
                PartitionInput=partition_input
            )
            action = "updated"

        body = {
            "message": f"Ingestão concluída. Partição {action}.",
            "source": {"bucket": src_bucket, "key": f"{src_prefix+'/'+src_filename if src_prefix else src_filename}"},
            "destination": {"bucket": dest_bucket, "key": dest_key},
            "glue": {"db": dest_db, "table": dest_table, "partition_col": partition_col, "partition_value": part_value}
        }
        return {"statusCode": 200, "body": json.dumps(body)}

    except botocore.exceptions.ClientError as e:
        return {"statusCode": 502, "body": f"Erro AWS: {e}"}
    except Exception as e:
        return {"statusCode": 500, "body": f"Erro geral: {e}"}
