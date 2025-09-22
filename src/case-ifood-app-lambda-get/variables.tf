# PROVIDERS ================================================
variable "project" {
  description = "Nome do projeto (prefixo de recursos)."
  type        = string
  default     = "ifood-case-app-lambda-get"
}

variable "aws_region" {
  type        = string
  description = "Região AWS para deploy"
  default     = "us-east-2"
}

# LAMBDA ===================================================
variable "lambda_name" {
  type        = string
  description = "Nome da função Lambda"
  default     = "ifood-case-app-lambda-get"
}

variable "target_bucket" {
  type        = string
  description = "Bucket de destino no S3"
  default     = "ifood-case-370581281916-landing"
}

variable "lambda_memory_mb" {
  type        = number
  default     = 1024
}

variable "lambda_timeout_seconds" {
  type        = number
  default     = 900 # 15 min para downloads grandes
}

