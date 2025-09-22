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
    """
    AWS Lambda que baixa um arquivo a partir de uma URL e grava no
    Amazon S3 sob o prefixo do workload

    Parâmetros
    ----------
    event : dict
        Payload de invocação contendo:
          - "url" (str, obrigatório): URL HTTP/HTTPS do arquivo de origem.
          - "workload" (str, obrigatório): nome do workload; compõe a chave S3 no formato
            "{workload}/{arquivo}".
          - "bucket" (str, opcional): bucket de destino no S3. Se ausente, é usado o valor
            padrão configurado na variável global/ambiente `BUCKET`.

    context : LambdaContext
        Objeto de contexto da execução da Lambda (não utilizado pela função).

    Comportamento
    -------------
    1) Valida a presença de "url" e "workload" no evento.
    2) Extrai o nome do arquivo a partir do path da URL; se não houver, usa "download.bin".
    3) Abre um stream HTTP com `urllib.request.urlopen(url)` e envia o conteúdo diretamente
       para o S3 com `s3.upload_fileobj(...)`, evitando escrita em disco local (/tmp).
    4) A chave final no S3 é construída como "{workload}/{arquivo_extraido_da_url}".

    Retorno
    -------
    dict
        Objeto de resposta no padrão (statusCode, body), onde:
          - statusCode = 200 em caso de sucesso; o body contém JSON com
            {"message", "bucket", "key", "source_url"}.
          - statusCode = 400 quando parâmetros obrigatórios estão ausentes.
          - statusCode = 502 para erros do S3 (ex.: permissões/URI inválida/destino).
          - statusCode = 500 para outras exceções (ex.: falhas de rede/HTTP).

    Exemplo
    -------
    >>> event = {
    ...   "url": "https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2023-01.parquet",
    ...   "bucket": "ifood-case-landing-6f957c",
    ...   "workload": "yellow_tripdata"
    ... }
    >>> lambda_handler(event, None)
    {'statusCode': 200,
     'body': '{"message": "Download concluído e enviado ao S3.", '
             '"bucket": "ifood-case-landing-6f957c", '
             '"key": "yellow_tripdata/yellow_tripdata_2023-01.parquet", '
             '"source_url": "https://.../yellow_tripdata_2023-01.parquet"}'}

    Requisitos
    ----------
    - Credenciais/permite IAM com `s3:PutObject` (e `s3:AbortMultipartUpload`).
    - Variável global/ambiente `BUCKET` definida caso "bucket" não seja informado.

    Possíveis exceções tratadas
    ---------------------------
    - botocore.exceptions.ClientError -> retorna 502 (erro do S3).
    - Demais exceções (ex.: erro de rede/timeout) -> retorna 500.
    """
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

