# Habilita envio de eventos do S3 para EventBridge neste bucket
# (se o bucket já existe, este recurso só liga o EventBridge para ele)
resource "aws_s3_bucket_notification" "landing_to_eventbridge" {
  bucket      = var.landing_bucket
  eventbridge = true
}

# Regra do EventBridge para S3 Object Created no prefixo desejado
resource "aws_cloudwatch_event_rule" "s3_object_created_rule" {
  name        = "s3-object-created-${replace(var.landing_bucket, "/[^a-zA-Z0-9-_]/", "-")}"
  description = "Dispara quando arquivos são criados no prefixo ${var.prefix_filter} do bucket ${var.landing_bucket}"

  event_pattern = jsonencode({
    "source":      ["aws.s3"],
    "detail-type": ["Object Created"],
    "detail": {
      "bucket": { "name": [var.landing_bucket] },
      "object": { "key": [{ "prefix": var.prefix_filter }] }
    }
  })
}

# Alvo: Lambda de ingestão + Input Transformer para montar payload
resource "aws_cloudwatch_event_target" "invoke_ingest_lambda" {
  rule      = aws_cloudwatch_event_rule.s3_object_created_rule.name
  target_id = "ingest-lambda"
  arn       = var.target_lambda_arn

  # Mapeia campos do evento para variáveis e monta o JSON do payload
  input_transformer {
    input_paths = {
      bucket = "$.detail.bucket.name"
      key    = "$.detail.object.key"
    }

    # Payload final enviado para a Lambda
    input_template = <<EOT
{
  "src_bucket": <bucket>,
  "src_key": <key>,
  "dest_db": "${var.dest_db}",
  "dest_table": "${var.dest_table}",
  "partition_col": "${var.partition_col}"
}
EOT
  }

  depends_on = [
    aws_s3_bucket_notification.landing_to_eventbridge
  ]
}

# Permissão para o EventBridge invocar a Lambda
resource "aws_lambda_permission" "allow_events_invoke" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.target_lambda_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_object_created_rule.arn
}
