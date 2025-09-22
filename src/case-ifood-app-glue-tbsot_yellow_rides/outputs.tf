output "glue_job_name" {
  value = aws_glue_job.yellow_etl.name
}

output "run_cli_example" {
  value = <<EOT
aws glue start-job-run \
  --job-name ${aws_glue_job.yellow_etl.name} \
  --arguments '{
    "--source_db":"${var.source_db}",
    "--source_table":"${var.source_table}",
    "--dest_db":"${var.dest_db}",
    "--dest_table":"${var.dest_table}"
  }'
EOT
}
