terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "~> 1.0"
    }
  }
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "atlas_project_id" {
  type    = string
}

locals {
  name                          = "formance-stack-${var.environment}"
  vpc_cidr                      = "192.168.0.0/16"
  region                        = "eu-west-1"
  ledger_postgresql_conn_string = "postgresql://${module.rds.cluster_master_username}:${module.rds.cluster_master_password}@${module.rds.cluster_endpoint}/${module.rds.cluster_database_name}"
  mongodb_atlas_url = trimprefix(mongodbatlas_advanced_cluster.main.connection_strings.0.private_srv, "mongodb+srv://")
  mongodb_uri = "mongodb+srv://formance:${random_password.atlas.result}@${local.mongodb_atlas_url}"
}