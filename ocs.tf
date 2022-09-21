resource "aws_security_group" "opensearch" {
  name        = "${local.name}-opensearch"
  description = "Allow access to OpenSearch"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_elasticsearch_domain" "opensearch" {
  domain_name           = local.name
  elasticsearch_version = "OpenSearch_1.3"

  cluster_config {
    instance_type  = "t3.small.elasticsearch"
    instance_count = 3

    dedicated_master_enabled = false
    warm_enabled             = false

    zone_awareness_enabled = true
    zone_awareness_config {
      availability_zone_count = 3
    }
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  node_to_node_encryption {
    enabled = true
  }

  encrypt_at_rest {
    enabled = true
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp2"
    volume_size = 20
    iops        = 0
  }

  vpc_options {
    security_group_ids = [aws_security_group.opensearch.id]
    subnet_ids         = module.vpc.database_subnets
  }

  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "es:*"
        ]
        Principal = {
          AWS = "*"
        }
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}