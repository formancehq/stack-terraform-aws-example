data "aws_caller_identity" "this" {}
################################################################################
# VPC Resources
################################################################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = local.name
  cidr = local.vpc_cidr

  azs              = ["${local.region}a", "${local.region}b", "${local.region}c"]
  private_subnets  = [cidrsubnet(local.vpc_cidr, 6, 2), cidrsubnet(local.vpc_cidr, 6, 3), cidrsubnet(local.vpc_cidr, 6, 4)]
  public_subnets   = [cidrsubnet(local.vpc_cidr, 8, 1), cidrsubnet(local.vpc_cidr, 8, 2), cidrsubnet(local.vpc_cidr, 8, 3)]
  database_subnets = [cidrsubnet(local.vpc_cidr, 8, 4), cidrsubnet(local.vpc_cidr, 8, 5), cidrsubnet(local.vpc_cidr, 8, 6)]

  enable_nat_gateway = true
  single_nat_gateway = true

  manage_default_route_table = true
  default_route_table_tags   = { DefaultRouteTable = true }

  enable_dns_hostnames = true
  enable_dns_support   = true

  manage_default_security_group  = true
  default_security_group_ingress = []
  default_security_group_egress  = []

  # VPC Flow Logs (Cloudwatch log group and IAM role will be created)
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60
}