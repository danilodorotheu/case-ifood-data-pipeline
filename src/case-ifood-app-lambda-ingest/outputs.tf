output "lambda_name" {
  value = aws_lambda_function.this.function_name
}

output "lambda_arn" {
  value = aws_lambda_function.this.arn
}

output "invoke_example" {
  value = <<EOT
aws lambda invoke \
  --function-name ${aws_lambda_function.this.function_name} \
  --payload '{
    "src_bucket":"ifood-case-370581281916-landing",
    "src_prefix":"yellow",
    "src_filename":"yellow_tripdata_2023-01.parquet",
    "dest_db":"ifood-case-sor",
    "dest_table":"tbsor_yellow_tripdata",
    "partition_col":"dtref"
  }' \
  --cli-binary-format raw-in-base64-out \
  out.json && cat out.json
EOT
}
