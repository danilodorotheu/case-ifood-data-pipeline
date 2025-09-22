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

variable "account_id" {
    description = "Numero da conta AWS"
    type        = string
    default     = "370581281916"
}

# GLUE ================================================
variable "job_name" {
  type        = string
  default     = "glue-yellow-etl"
}

variable "glue_scripts_bucket" {
  type        = string
  description = "Bucket S3 para armazenar o script do Glue"
  default     = "ifood-case-370581281916-scripts"
}

variable "glue_scripts_prefix" {
  type        = string
  default     = "glue/scripts"
}

variable "source_db" {
  type        = string
  default     = "ifood-case-sor"
}

variable "source_table" {
  type        = string
  default     = "tbsor_yellow_tripdata"
}

variable "dest_db" {
  type        = string
  default     = "ifood-case-sot"
}

variable "dest_table" {
  type        = string
  default     = "tbsot_yellow_rides"
}

variable "role_name" {
  type        = string
  default     = "glue-yellow-etl-role"
}

variable "workflow_name" {
  type = string
  default = "wf-yellow"
}

variable "rule_name" {
  type = string
  default = "on-glue-partition-created-tbsor_yellow_tripdata"
}

