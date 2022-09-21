resource "aws_ecs_service" "gateway" {
  name            = "gateway"
  cluster         = module.ecs.cluster_name
  task_definition = aws_ecs_task_definition.gateway.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_alb_target_group.gateway.arn
    container_name   = "gateway"
    container_port   = 80
  }
  load_balancer {
    target_group_arn = aws_alb_target_group.gateway2.arn
    container_name   = "gateway"
    container_port   = 8080
  }

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [aws_security_group.gateway_ecs.id]
    assign_public_ip = true
  }
}

resource "aws_ecs_service" "ledger" {
  name            = "ledger"
  cluster         = module.ecs.cluster_name
  task_definition = aws_ecs_task_definition.ledger.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [aws_security_group.whoami.id]
    assign_public_ip = true
  }
}

resource "aws_ecs_service" "control" {
  name            = "control"
  cluster         = module.ecs.cluster_name
  task_definition = aws_ecs_task_definition.control.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [aws_security_group.whoami.id]
    assign_public_ip = true
  }
}

resource "aws_ecs_service" "search" {
  name            = "search"
  cluster         = module.ecs.cluster_name
  task_definition = aws_ecs_task_definition.search.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [aws_security_group.whoami.id]
    assign_public_ip = true
  }
}

resource "aws_ecs_service" "search-ingester" {
  name            = "search-ingester"
  cluster         = module.ecs.cluster_name
  task_definition = aws_ecs_task_definition.search-ingester.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [aws_security_group.whoami.id]
    assign_public_ip = true
  }
}

resource "aws_ecs_service" "payments" {
  name            = "payments"
  cluster         = module.ecs.cluster_name
  task_definition = aws_ecs_task_definition.payments.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [aws_security_group.whoami.id]
    assign_public_ip = true
  }
}
