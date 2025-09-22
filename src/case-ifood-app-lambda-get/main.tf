# Empacota o código Python em um zip
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/build/lambda.zip"
}

# Role para Lambda
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "${var.lambda_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Política de logs básicos
resource "aws_iam_role_policy_attachment" "basic_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Política custom de acesso ao bucket de destino
data "aws_iam_policy_document" "s3_policy" {
  statement {
    sid     = "AllowPutGetOnTargetBucket"
    effect  = "Allow"
    actions = [
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [
      "arn:aws:s3:::${var.target_bucket}",
      "arn:aws:s3:::${var.target_bucket}/*"
    ]
  }
}

resource "aws_iam_policy" "s3_access" {
  name   = "${var.lambda_name}-s3-access"
  policy = data.aws_iam_policy_document.s3_policy.json
}

resource "aws_iam_role_policy_attachment" "s3_access_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.s3_access.arn
}

# (Opcional) Log Group gerenciado
resource "aws_cloudwatch_log_group" "lambda_lg" {
  name              = "/aws/lambda/${var.lambda_name}"
  retention_in_days = 14
}

# Função Lambda
resource "aws_lambda_function" "this" {
  function_name = var.lambda_name
  role          = aws_iam_role.lambda_role.arn
  runtime       = "python3.12"
  handler       = "lambda_function.lambda_handler"
  filename      = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  memory_size = var.lambda_memory_mb
  timeout     = var.lambda_timeout_seconds
  architectures = ["x86_64"]

  environment {
    variables = {
      TARGET_BUCKET = var.target_bucket
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.basic_logs,
    aws_iam_role_policy_attachment.s3_access_attach,
    aws_cloudwatch_log_group.lambda_lg
  ]
}
