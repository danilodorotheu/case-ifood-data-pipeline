import os
import json
import urllib.request
import urllib.parse
import boto3
import botocore
from datetime import datetime, timezone

s3 = boto3.client("s3")

BUCKET = os.environ.get("TARGET_BUCKET", "ifood-case-landing-6f957c")

def lambda_handler(event, context):
    url = (event or {}).get("url")
    if not url:
        return {"statusCode": 400, "body": "Campo 'url' é obrigatório no evento."}
    
    workload = (event or {}).get("workload")
    if not url:
        return {"statusCode": 400, "body": "Campo 'workload' é obrigatório no evento."}

    bucket   = (event or {}).get("bucket") or BUCKET

    base = os.path.basename(urllib.parse.urlparse(url).path) or "download.bin"
    key = f"{workload}/{base}"

    try:
        # Abre stream HTTP sem baixar para /tmp
        with urllib.request.urlopen(url) as response:
            # Faz upload streaming direto para S3
            s3.upload_fileobj(response, bucket, key)

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Download concluído e enviado ao S3.",
                "bucket": bucket,
                "key": key,
                "source_url": url
            })
        }
    except botocore.exceptions.ClientError as e:
        return {"statusCode": 502, "body": f"Erro S3: {e}"}

    except Exception as e:
        return {"statusCode": 500, "body": f"Erro geral: {e}"}

