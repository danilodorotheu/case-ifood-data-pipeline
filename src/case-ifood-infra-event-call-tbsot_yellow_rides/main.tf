data "aws_iam_policy_document" "events_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eventbridge_to_glue" {
  name               = "eventbridge-to-glue-startjobrun"
  assume_role_policy = data.aws_iam_policy_document.events_assume_role.json
}

data "aws_iam_policy_document" "events_can_start_glue" {
  statement {
    sid    = "AllowStartGlueJobRun"
    effect = "Allow"
    actions = [
      "glue:StartJobRun"
    ]
    resources = [
      var.glue_job_arn
    ]
  }
}

resource "aws_iam_policy" "events_can_start_glue" {
  name   = "eventbridge-start-glue-jobrun"
  policy = data.aws_iam_policy_document.events_can_start_glue.json
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.eventbridge_to_glue.name
  policy_arn = aws_iam_policy.events_can_start_glue.arn
}

resource "aws_cloudwatch_event_rule" "on_partition_created" {
  name        = "on-glue-partition-created-${var.glue_table}"
  description = "Dispara o Glue Job ${var.glue_job_name} quando novas partições são criadas em ${var.glue_database}.${var.glue_table}"

  event_pattern = jsonencode({
    "source"      : ["aws.glue"],
    "detail-type" : ["Glue Data Catalog Table State Change"],
    "detail" : {
      "databaseName" : [var.glue_database],
      "tableName"    : [var.glue_table],
      "typeOfChange" : ["CreatePartition", "BatchCreatePartition"]
    }
  })
}

resource "aws_cloudwatch_event_target" "start_glue_job" {
  rule      = aws_cloudwatch_event_rule.on_partition_created.name
  target_id = var.event_target_id
  arn       = var.workflow_arn
  role_arn  = aws_iam_role.eventbridge_to_glue.arn

  input_transformer {
    # Extrai a primeira partição informada no evento (ex: "202301")
    input_paths = {
      partition_value = "$.detail.changedPartitions[0]"
    }

    # Monta payload esperado pelo target "Glue job" (StartJobRun).
    # Para Glue Job como target, o EventBridge usa StartJobRun com 'Arguments'.
    input_template = <<EOT
{
  "Arguments": {
    "--partition_value": <partition_value>
  }
}
EOT
  }
}
