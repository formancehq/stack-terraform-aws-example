resource "aws_security_group" "gateway" {
  name        = "gateway-front"
  description = "Allow http and https traffic from Internet"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Non secured"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Non secured"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "gateway_ecs" {
  name        = "gateway-ecs"
  description = "Allow http and https traffic from ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Non secured"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.gateway.id]
  }

  ingress {
    description     = "Non secured"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.gateway.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "whoami" {
  name        = "whoami"
  description = "Allow traffic from Traefik"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Non secured"
    from_port         = 0
    to_port           = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.gateway_ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}