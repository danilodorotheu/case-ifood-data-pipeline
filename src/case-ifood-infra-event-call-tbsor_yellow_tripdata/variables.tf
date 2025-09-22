variable "project" {
  description = "Nome do projeto (prefixo de recursos)."
  type        = string
  default     = "ifood-case"
}

variable "aws_region" {
  description = "Região AWS."
  type        = string
  default     = "us-east-2"
}

variable "account_id" {
    description = "Numero da conta AWS"
    type        = string
    default     = "370581281916"
}

variable "landing_bucket" {
  type        = string
  description = "Bucket de landing"
  default     = "ifood-case-370581281916-landing"
}

variable "prefix_filter" {
  type        = string
  description = "Prefixo no bucket que dispara o evento"
  default     = "yellow_tripdata/"
}

variable "target_lambda_arn" {
  type        = string
  description = "ARN da Lambda de ingestão que receberá o evento"
  default     = "arn:aws:lambda:us-east-2:370581281916:function:ifood-case-app-lambda-ingest"
}

variable "dest_db" {
  type        = string
  description = "Database de destino no Glue"
  default     = "ifood-case-sor"
}

variable "dest_table" {
  type        = string
  description = "Tabela de destino no Glue"
  default     = "tbsor_yellow_tripdata"
}

variable "partition_col" {
  type        = string
  description = "Nome da coluna de partição no Glue"
  default     = "dtref"
}
