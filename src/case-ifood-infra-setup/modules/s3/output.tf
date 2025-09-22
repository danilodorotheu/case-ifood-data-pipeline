output "bucket" {
  description = "Nome do bucket"
  value       = aws_s3_bucket.this.bucket
}

output "arn" {
  description = "ARN do bucket"
  value       = aws_s3_bucket.this.arn
}
