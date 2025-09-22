terraform {
  required_version = ">= 1.9.5"
  required_providers {
    aws     = { source = "hashicorp/aws", version = ">= 5.0" }
    random  = { source = "hashicorp/random", version = ">= 3.5" }
    archive = { source = "hashicorp/archive", version = ">= 2.4" }
  }
}
provider "aws" {
  region  = var.aws_region
  profile = "ifood-case"
  default_tags {
    tags = { 
      Project = var.project, 
      ManagedBy = "Terraform" 
    }
  }
}
