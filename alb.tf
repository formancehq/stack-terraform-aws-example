resource "aws_lb" "main" {
  name               = "${local.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.gateway.id]
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = false
}

resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_lb.main.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.gateway.id
    type             = "forward"
  }
}
resource "aws_alb_listener" "http2" {
  load_balancer_arn = aws_lb.main.id
  port              = 8080
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.gateway2.id
    type             = "forward"
  }
}

resource "aws_alb_target_group" "gateway" {
  name        = "${local.name}-gateway"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    path    = "/"
    matcher = "200-202,404"
  }
}

resource "aws_alb_target_group" "gateway2" {
  name        = "${local.name}-gateway2"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    path    = "/dashboard/"
    matcher = "200-202,404"
  }
}

