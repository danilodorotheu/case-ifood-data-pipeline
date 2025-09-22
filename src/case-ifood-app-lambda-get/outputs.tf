output "lambda_name" {
  value = aws_lambda_function.this.function_name
}

output "lambda_arn" {
  value = aws_lambda_function.this.arn
}

output "invoke_cli_example" {
  value = <<EOT
aws lambda invoke \
  --function-name ${aws_lambda_function.this.function_name} \
  --payload '{"url":"https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2023-01.parquet"}' \
  --cli-binary-format raw-in-base64-out \
  out.json
EOT
}
