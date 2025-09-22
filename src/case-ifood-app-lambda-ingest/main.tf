# Empacota o código Python em ZIP
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/build/lambda.zip"
}

# Role de execução
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

# Logs básicos
resource "aws_iam_role_policy_attachment" "basic_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Permissões S3 (genéricas; restrinja em produção)
data "aws_iam_policy_document" "s3_rw" {
  statement {
    sid     = "AllowReadAnyBucket"
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:ListBucket"]
    resources = ["arn:aws:s3:::*", "arn:aws:s3:::*/*"]
  }
  statement {
    sid     = "AllowWriteAnyBucket"
    effect  = "Allow"
    actions = ["s3:PutObject", "s3:AbortMultipartUpload"]
    resources = ["arn:aws:s3:::*/*"]
  }
}

resource "aws_iam_policy" "s3_rw" {
  name   = "${var.lambda_name}-s3-rw"
  policy = data.aws_iam_policy_document.s3_rw.json
}

resource "aws_iam_role_policy_attachment" "s3_rw_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.s3_rw.arn
}

# Permissões Glue necessárias
data "aws_iam_policy_document" "glue_access" {
  statement {
    sid    = "GlueReadTable"
    effect = "Allow"
    actions = [
      "glue:GetTable",
      "glue:GetTables",
      "glue:GetDatabase",
      "glue:GetDatabases"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "GlueManagePartitions"
    effect = "Allow"
    actions = [
      "glue:CreatePartition",
      "glue:UpdatePartition",
      "glue:BatchCreatePartition",
      "glue:GetPartition",
      "glue:GetPartitions"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "glue_access" {
  name   = "${var.lambda_name}-glue-access"
  policy = data.aws_iam_policy_document.glue_access.json
}

resource "aws_iam_role_policy_attachment" "glue_access_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.glue_access.arn
}

# (Opcional) Log Group gerenciado
resource "aws_cloudwatch_log_group" "lg" {
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

  memory_size   = var.memory_mb
  timeout       = var.timeout_seconds
  architectures = ["x86_64"]

  depends_on = [
    aws_iam_role_policy_attachment.basic_logs,
    aws_iam_role_policy_attachment.s3_rw_attach,
    aws_iam_role_policy_attachment.glue_access_attach,
    aws_cloudwatch_log_group.lg
  ]
}
