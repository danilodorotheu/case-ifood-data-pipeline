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