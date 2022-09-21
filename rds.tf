resource "aws_security_group" "rds" {
  name        = "${local.name}-ledger-rds"
  description = "${local.name}-ledger-rds"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

module "rds" {
  source = "terraform-aws-modules/rds-aurora/aws"

  name = "${local.name}-ledger"

  allow_major_version_upgrade = true
  engine                      = "aurora-postgresql"
  engine_version              = "14"
  engine_mode                 = "provisioned"
  storage_encrypted           = true

  database_name   = "ledger"
  master_username = "ledger"
  port            = 5432

  vpc_id                 = module.vpc.vpc_id
  subnets                = module.vpc.database_subnets
  vpc_security_group_ids = [aws_security_group.rds.id]
  create_security_group  = false

  preferred_maintenance_window = "Mon:00:00-Mon:03:00"
  preferred_backup_window      = "03:00-06:00"
  backup_retention_period      = 30

  serverlessv2_scaling_configuration = {
    min_capacity = 1
    max_capacity = 20
  }

  instance_class = "db.serverless"
  instances = {
    one = {}
  }

}