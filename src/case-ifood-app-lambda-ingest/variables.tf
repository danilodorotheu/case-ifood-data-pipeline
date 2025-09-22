# PROVIDERS ================================================
variable "project" {
  description = "Nome do projeto (prefixo de recursos)."
  type        = string
  default     = "ifood-case-app-lambda-ingest"
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
  default     = "ifood-case-app-lambda-ingest"
}

variable "memory_mb" {
  type        = number
  default     = 512
}

variable "timeout_seconds" {
  type        = number
  default     = 300
}

/*
  ⚠️ Segurança:
  Para simplificar, a policy abaixo permite leitura em QUALQUER bucket de origem
  e escrita em QUALQUER bucket de destino (derivado do location da tabela).
  Em produção, restrinja aos buckets específicos do seu caso.
*/
