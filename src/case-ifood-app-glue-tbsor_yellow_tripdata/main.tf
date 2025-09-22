# Publica o script no S3
resource "aws_s3_object" "glue_script" {
  bucket = var.glue_scripts_bucket
  key    = "${var.glue_scripts_prefix}/glue_job_yellow.py"
  source = "${path.module}/scripts/glue_job_yellow.py"
  etag   = filemd5("${path.module}/scripts/glue_job_yellow.py")
  content_type = "text/x-python"
}

# Role do Glue
data "aws_iam_policy_document" "assume_glue" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "glue_role" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_glue.json
}

# Políticas: acesso ao catálogo Glue, CloudWatch Logs, e S3 amplo (ajuste em produção)
resource "aws_iam_role_policy_attachment" "glue_service_role" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "s3_full" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Glue Job
resource "aws_glue_job" "yellow_etl" {
  name     = var.job_name
  role_arn = aws_iam_role.glue_role.arn

  glue_version = "4.0"      # Spark 3.3 / Python 3.10
  number_of_workers = 2
  worker_type       = "G.1X"

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_object.glue_script.bucket}/${aws_s3_object.glue_script.key}"
    python_version  = "3"
  }

  default_arguments = {
    "--enable-metrics"  = "true"
    "--job-language"    = "python"
    "--source_db"       = var.source_db
    "--source_table"    = var.source_table
    "--dest_db"         = var.dest_db
    "--dest_table"      = var.dest_table
    "--partition_value" = ""
    # Opcional: catálogo como Hive
    "--enable-glue-datacatalog" = "true"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  depends_on = [aws_s3_object.glue_script]
}

# Workflow
resource "aws_glue_workflow" "yellow" {
  name        = var.workflow_name
  description = "Workflow que orquestra o job ${var.job_name}"
}

# Trigger ON_DEMAND que dispara o Job dentro do workflow
resource "aws_glue_trigger" "start_job" {
  name          = "${var.workflow_name}-start-job"
  type          = "ON_DEMAND"
  workflow_name = aws_glue_workflow.yellow.name

  actions {
    job_name = aws_glue_job.yellow_etl.name
    # Se quiser passar argumentos fixos ao job, use "arguments" aqui.
    # arguments = { "--algum_arg" = "valor" }
  }

  depends_on = [aws_glue_workflow.yellow, aws_glue_job.yellow_etl]
}
