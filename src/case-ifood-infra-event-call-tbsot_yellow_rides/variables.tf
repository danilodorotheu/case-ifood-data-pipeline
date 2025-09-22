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

variable "glue_database" {
  description = "Nome do database no Glue Catalog onde está a tabela."
  type        = string
  default     = "ifood-case-sor"
}

variable "glue_table" {
  description = "Nome da tabela no Glue Catalog a ser observada."
  type        = string
  default     = "tbsor_yellow_tripdata"
}

variable "partition_column" {
  description = "Nome da coluna de partição da tabela."
  type        = string
  default     = "dtref"
}

variable "glue_job_name" {
  description = "Nome do Glue Job que será acionado."
  type        = string
  default     = "glue-yellow-etl"
}

variable "glue_job_arn" {
  description = "ARN do Glue Job que será acionado."
  type        = string
  default     = "arn:aws:glue:us-east-2:370581281916:job/glue-yellow-etl"
}

variable "workflow_arn" {
  description = "ARN do Workflow do Glue Job que será acionado."
  type        = string
  default     = "arn:aws:glue:us-east-1:370581281916:workflow/wf-yellow"
}

# Opcional: id único para o alvo do rule (facilita import/debug)
variable "event_target_id" {
  description = "ID do target do EventBridge (livre para nomear)."
  type        = string
  default     = "start-glue-yellow-etl"
}
