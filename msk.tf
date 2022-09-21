resource "aws_security_group" "sg" {
  vpc_id = module.vpc.vpc_id

  ingress {
    description = "Kafka"
    from_port   = 9098
    to_port     = 9098
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
  ingress {
    description = "Kafka"
    from_port   = 9096
    to_port     = 9096
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
}

resource "random_password" "master_password" {
  length  = 12
  special = false
}

resource "aws_kms_key" "kms" {
  description = "kafka-key"
}

resource "aws_cloudwatch_log_group" "log" {
  name = "${local.name}-kafka"
}

resource "aws_msk_configuration" "kafka3" {
  kafka_versions = ["3.2.0"]
  name           = "${local.name}-kafka3"

  server_properties = <<PROPERTIES
auto.create.topics.enable = true
delete.topic.enable = true
PROPERTIES
}

resource "aws_msk_cluster" "kafka" {
  cluster_name           = "${local.name}-kafka"
  kafka_version          = "3.2.0"
  number_of_broker_nodes = 3

  broker_node_group_info {
    instance_type   = "kafka.m5.large"
    client_subnets  = module.vpc.database_subnets
    security_groups = [aws_security_group.sg.id]
    storage_info {
      ebs_storage_info {
        volume_size = 100
      }
    }
  }

  configuration_info {
    arn      = aws_msk_configuration.kafka3.arn
    revision = aws_msk_configuration.kafka3.latest_revision
  }

  encryption_info {
    encryption_at_rest_kms_key_arn = aws_kms_key.kms.arn
    encryption_in_transit {
      in_cluster    = true
      client_broker = "TLS"
    }
  }

  open_monitoring {
    prometheus {
      jmx_exporter {
        enabled_in_broker = true
      }
      node_exporter {
        enabled_in_broker = true
      }
    }
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.log.name
      }
    }
  }

  client_authentication {
    sasl {
      iam   = true
      scram = true
    }
  }
}


resource "aws_msk_scram_secret_association" "this" {
  cluster_arn     = aws_msk_cluster.kafka.arn
  secret_arn_list = [aws_secretsmanager_secret.this.arn]

  depends_on = [aws_secretsmanager_secret_version.example]
}

resource "aws_secretsmanager_secret" "this" {
  name       = "AmazonMSK_${local.name}"
  kms_key_id = aws_kms_key.this.key_id
}

resource "aws_kms_key" "this" {
  description = "Key for MSK Cluster Scram Secret Association"
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = jsonencode({
    username = "formance",
    password = random_password.master_password.result
  })
}

resource "aws_secretsmanager_secret_policy" "example" {
  secret_arn = aws_secretsmanager_secret.this.arn
  policy     = <<POLICY
{
  "Version" : "2012-10-17",
  "Statement" : [ {
    "Sid": "AWSKafkaResourcePolicy",
    "Effect" : "Allow",
    "Principal" : {
      "Service" : "kafka.amazonaws.com"
    },
    "Action" : "secretsmanager:getSecretValue",
    "Resource" : "${aws_secretsmanager_secret.this.arn}"
  } ]
}
POLICY
}