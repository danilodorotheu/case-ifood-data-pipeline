output "eventbridge_rule_name" {
  description = "Nome do EventBridge Rule criado."
  value       = aws_cloudwatch_event_rule.on_partition_created.name
}

output "eventbridge_target_id" {
  description = "ID do target do EventBridge."
  value       = aws_cloudwatch_event_target.start_glue_job.target_id
}

output "eventbridge_to_glue_role_arn" {
  description = "ARN da role usada pelo EventBridge para iniciar o Glue Job."
  value       = aws_iam_role.eventbridge_to_glue.arn
}
