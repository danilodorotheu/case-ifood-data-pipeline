variable "bucket_name" {
  description = "Nome do bucket S3"
  type        = string
}

variable "force_destroy" {
  description = "Permitir destruir o bucket mesmo com objetos"
  type        = bool
  default     = false
}

variable "versioning" {
  description = "Ativar versionamento"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags do bucket"
  type        = map(string)
  default     = {}
}
